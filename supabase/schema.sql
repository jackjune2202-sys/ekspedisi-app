-- ============================================================
-- SCHEMA SUPABASE - APLIKASI BUKU EKSPEDISI
-- Jalankan di Supabase > SQL Editor
-- ============================================================

-- EXTENSION
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- TABLE: lokasi (cabang/pabrik)
-- ============================================================
CREATE TABLE lokasi (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nama TEXT NOT NULL,
  alamat TEXT,
  kode TEXT UNIQUE NOT NULL,
  aktif BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- TABLE: users (extends Supabase auth.users)
-- ============================================================
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nama_lengkap TEXT NOT NULL,
  email TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin', 'receptionist', 'security', 'penerima')),
  lokasi_id UUID REFERENCES lokasi(id),
  departemen TEXT,
  no_hp TEXT,
  foto_url TEXT,
  aktif BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- TABLE: kategori_barang
-- ============================================================
CREATE TABLE kategori_barang (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nama TEXT NOT NULL,
  icon TEXT,
  warna TEXT DEFAULT '#2196F3',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed data kategori
INSERT INTO kategori_barang (nama, icon, warna) VALUES
('Dokumen/Surat', 'document', '#2196F3'),
('Sample Kain', 'fabric', '#9C27B0'),
('Obat/Kimia', 'medical', '#F44336'),
('Paket/Barang', 'package', '#FF9800'),
('Makanan/Minuman', 'food', '#4CAF50'),
('Elektronik', 'electronics', '#607D8B'),
('Lainnya', 'other', '#795548');

-- ============================================================
-- TABLE: ekspedisi (data penerimaan barang)
-- ============================================================
CREATE TABLE ekspedisi (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nomor_ekspedisi TEXT UNIQUE NOT NULL, -- auto-generated: EXP-YYYYMMDD-XXXX
  
  -- Lokasi
  lokasi_id UUID NOT NULL REFERENCES lokasi(id),
  
  -- Pengirim
  nama_pengirim TEXT NOT NULL,
  perusahaan_pengirim TEXT,
  no_telepon_pengirim TEXT,
  
  -- Barang
  kategori_id UUID REFERENCES kategori_barang(id),
  deskripsi_barang TEXT NOT NULL,
  qty INTEGER NOT NULL DEFAULT 1,
  satuan TEXT DEFAULT 'pcs',
  keterangan TEXT,
  
  -- Tujuan
  penerima_id UUID REFERENCES profiles(id), -- profile internal
  nama_penerima_manual TEXT, -- jika tidak ada di sistem
  departemen_tujuan TEXT NOT NULL,
  
  -- Status
  status TEXT NOT NULL DEFAULT 'menunggu' CHECK (
    status IN ('menunggu', 'diambil_security', 'dalam_pengiriman', 'diterima', 'dikembalikan')
  ),
  
  -- Foto
  foto_barang_urls TEXT[], -- array URL foto dari receptionist
  foto_pengiriman_urls TEXT[], -- array URL foto dari security
  foto_bukti_terima_urls TEXT[], -- foto saat diterima
  
  -- Timestamps & Users
  diterima_oleh_id UUID REFERENCES profiles(id), -- receptionist
  diterima_pada TIMESTAMPTZ DEFAULT NOW(),
  
  diambil_security_id UUID REFERENCES profiles(id),
  diambil_pada TIMESTAMPTZ,
  
  dikirim_pada TIMESTAMPTZ,
  
  selesai_pada TIMESTAMPTZ,
  catatan_security TEXT,
  catatan_penerima TEXT,
  
  -- Tanda tangan digital (base64 or URL)
  tanda_tangan_penerima TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- TABLE: log_status (history perubahan status)
-- ============================================================
CREATE TABLE log_status_ekspedisi (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ekspedisi_id UUID NOT NULL REFERENCES ekspedisi(id) ON DELETE CASCADE,
  status_lama TEXT,
  status_baru TEXT NOT NULL,
  catatan TEXT,
  foto_urls TEXT[],
  user_id UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- FUNCTION: auto-generate nomor ekspedisi
-- ============================================================
CREATE OR REPLACE FUNCTION generate_nomor_ekspedisi()
RETURNS TRIGGER AS $$
DECLARE
  tanggal TEXT;
  urutan INTEGER;
  nomor TEXT;
BEGIN
  tanggal := TO_CHAR(NOW(), 'YYYYMMDD');
  
  SELECT COUNT(*) + 1 INTO urutan
  FROM ekspedisi
  WHERE DATE(created_at) = CURRENT_DATE;
  
  nomor := 'EXP-' || tanggal || '-' || LPAD(urutan::TEXT, 4, '0');
  NEW.nomor_ekspedisi := nomor;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_nomor_ekspedisi
BEFORE INSERT ON ekspedisi
FOR EACH ROW
WHEN (NEW.nomor_ekspedisi IS NULL OR NEW.nomor_ekspedisi = '')
EXECUTE FUNCTION generate_nomor_ekspedisi();

-- ============================================================
-- FUNCTION: auto-update updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_ekspedisi
BEFORE UPDATE ON ekspedisi
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trigger_update_profiles
BEFORE UPDATE ON profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- FUNCTION: log status change otomatis
-- ============================================================
CREATE OR REPLACE FUNCTION log_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO log_status_ekspedisi (
      ekspedisi_id, status_lama, status_baru, user_id
    ) VALUES (
      NEW.id, OLD.status, NEW.status, NEW.diambil_security_id
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_status
AFTER UPDATE ON ekspedisi
FOR EACH ROW EXECUTE FUNCTION log_status_change();

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE ekspedisi ENABLE ROW LEVEL SECURITY;
ALTER TABLE log_status_ekspedisi ENABLE ROW LEVEL SECURITY;
ALTER TABLE lokasi ENABLE ROW LEVEL SECURITY;
ALTER TABLE kategori_barang ENABLE ROW LEVEL SECURITY;

-- Semua authenticated user bisa baca profiles, lokasi, kategori
CREATE POLICY "read_profiles" ON profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "update_own_profile" ON profiles FOR UPDATE TO authenticated USING (auth.uid() = id);

CREATE POLICY "read_lokasi" ON lokasi FOR SELECT TO authenticated USING (true);
CREATE POLICY "read_kategori" ON kategori_barang FOR SELECT TO authenticated USING (true);

-- Ekspedisi: semua bisa baca, tapi write dibatasi role
CREATE POLICY "read_ekspedisi" ON ekspedisi FOR SELECT TO authenticated USING (true);

CREATE POLICY "insert_ekspedisi" ON ekspedisi FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role IN ('receptionist', 'admin')
  )
);

CREATE POLICY "update_ekspedisi" ON ekspedisi FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role IN ('receptionist', 'security', 'admin')
  )
);

CREATE POLICY "read_log" ON log_status_ekspedisi FOR SELECT TO authenticated USING (true);

-- ============================================================
-- STORAGE BUCKETS
-- Buat manual di Supabase Dashboard > Storage:
-- 1. "ekspedisi-foto" (public)
-- ============================================================

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX idx_ekspedisi_status ON ekspedisi(status);
CREATE INDEX idx_ekspedisi_lokasi ON ekspedisi(lokasi_id);
CREATE INDEX idx_ekspedisi_tanggal ON ekspedisi(created_at);
CREATE INDEX idx_ekspedisi_penerima ON ekspedisi(penerima_id);
CREATE INDEX idx_log_ekspedisi ON log_status_ekspedisi(ekspedisi_id);

-- ============================================================
-- SEED DATA (contoh)
-- ============================================================
INSERT INTO lokasi (nama, alamat, kode) VALUES
('Pabrik Utama Bandung', 'Jl. Industri No. 1, Bandung', 'BDG-01'),
('Pabrik Cimahi', 'Jl. Raya Cimahi No. 5, Cimahi', 'CMH-01'),
('Kantor Pusat Jakarta', 'Jl. Sudirman No. 100, Jakarta', 'JKT-01');
