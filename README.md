# 📦 Buku Ekspedisi — Aplikasi Flutter

Aplikasi manajemen penerimaan barang berbasis Flutter + Supabase untuk pabrik/perusahaan multi-lokasi.

---

## 🗂️ Struktur Proyek

```
ekspedisi_app/
├── lib/
│   ├── main.dart                          # Entry point
│   ├── core/
│   │   ├── constants/app_constants.dart   # Config & konstanta
│   │   ├── theme/app_theme.dart           # Warna & tema UI
│   │   └── router/app_router.dart         # Navigasi (GoRouter)
│   ├── data/
│   │   ├── models/models.dart             # Model data (Ekspedisi, Profil, dll)
│   │   └── repositories/
│   │       └── ekspedisi_repository.dart  # Semua operasi ke Supabase
│   └── presentation/
│       ├── providers/app_providers.dart   # State management (Riverpod)
│       └── screens/
│           ├── auth/login_screen.dart
│           ├── dashboard/dashboard_screen.dart
│           ├── receptionist/
│           │   ├── input_barang_screen.dart
│           │   └── daftar_ekspedisi_screen.dart
│           ├── security/
│           │   ├── security_home_screen.dart
│           │   └── ambil_barang_screen.dart
│           ├── shared/detail_ekspedisi_screen.dart
│           └── report/laporan_screen.dart
├── supabase/
│   └── schema.sql                         # Script SQL Supabase
└── pubspec.yaml
```

---

## 🚀 Setup Step-by-Step

### STEP 1 — Buat Proyek Supabase

1. Buka [https://supabase.com](https://supabase.com) → **New Project**
2. Isi nama proyek, password database, pilih region terdekat (Singapore)
3. Tunggu sampai proyek aktif (~2 menit)

### STEP 2 — Jalankan SQL Schema

1. Di Supabase Dashboard → **SQL Editor** → **New Query**
2. Copy seluruh isi file `supabase/schema.sql`
3. Paste ke editor → klik **Run**
4. Pastikan tidak ada error merah

### STEP 3 — Buat Storage Bucket

1. Di Supabase Dashboard → **Storage** → **New Bucket**
2. Nama bucket: `ekspedisi-foto`
3. Centang **Public bucket** → **Save**
4. Di Policies tab bucket → tambahkan policy:
   - **SELECT**: `authenticated` users → allow
   - **INSERT**: `authenticated` users → allow

### STEP 4 — Ambil API Keys

1. Di Supabase → **Settings** → **API**
2. Copy:
   - **Project URL** (contoh: `https://abcxyz.supabase.co`)
   - **anon public** key

### STEP 5 — Update Konfigurasi Aplikasi

Buka `lib/core/constants/app_constants.dart`:

```dart
static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
// Ganti dengan URL Anda ↑

static const String supabaseAnonKey = 'YOUR_ANON_KEY';
// Ganti dengan anon key Anda ↑
```

### STEP 6 — Buat User Pertama (Admin)

1. Di Supabase → **Authentication** → **Users** → **Add User**
2. Isi email & password → **Create User**
3. Copy User ID yang muncul
4. Di **SQL Editor**, jalankan:

```sql
INSERT INTO profiles (id, nama_lengkap, email, role, lokasi_id)
VALUES (
  'USER_ID_DISINI',           -- paste User ID
  'Admin Utama',
  'admin@perusahaan.com',
  'admin',
  (SELECT id FROM lokasi LIMIT 1)  -- lokasi pertama
);
```

### STEP 7 — Install Flutter Dependencies

```bash
cd ekspedisi_app
flutter pub get
```

### STEP 8 — Jalankan Aplikasi

```bash
# Android
flutter run

# iOS
flutter run -d ios

# Web (untuk testing)
flutter run -d chrome
```

---

## 👥 Role Pengguna

| Role | Akses |
|------|-------|
| `admin` | Semua fitur |
| `receptionist` | Input barang, lihat daftar, laporan |
| `security` | Ambil & antar barang, foto bukti |
| `penerima` | Lihat barang yang ditujukan ke mereka |

### Cara Tambah User Baru

1. Supabase → **Authentication** → **Add User**
2. Masukkan email & password
3. Copy User ID
4. Jalankan SQL:

```sql
INSERT INTO profiles (id, nama_lengkap, email, role, lokasi_id, departemen)
VALUES (
  'USER_ID',
  'Nama Lengkap',
  'email@perusahaan.com',
  'receptionist',  -- atau: security, penerima, admin
  (SELECT id FROM lokasi WHERE kode = 'BDG-01'),
  'Departemen HRD'
);
```

---

## 📱 Alur Kerja Aplikasi

```
Barang Datang
     │
     ▼
[RECEPTIONIST] Input Barang
  - Pilih lokasi
  - Data pengirim (nama, perusahaan, no HP)
  - Kategori barang (Dokumen/Surat, Sample Kain, Obat, dll)
  - Deskripsi + Qty + Satuan
  - Tujuan: departemen & penerima
  - Foto barang (kamera/galeri, bisa multiple)
  - Keterangan tambahan
     │
     ▼ Status: MENUNGGU
     │
[SECURITY] Portal Security → Tab "Menunggu"
  - Lihat daftar barang yang belum diambil
  - Klik → Foto barang sebelum diambil
  - Tekan "Ambil Barang"
     │
     ▼ Status: DIAMBIL SECURITY
     │
[SECURITY] Tekan "Tandai Sedang Diantar"
     │
     ▼ Status: DALAM PENGIRIMAN
     │
[SECURITY] Sampai di tujuan → Foto bukti serah terima
  - Tekan "Konfirmasi Sudah Diterima"
     │
     ▼ Status: DITERIMA ✅
     │
[LAPORAN] Export PDF / lihat statistik
```

---

## 🗃️ Database Tables

| Tabel | Fungsi |
|-------|--------|
| `lokasi` | Master data cabang/pabrik |
| `profiles` | Data user (extend auth.users) |
| `kategori_barang` | Kategori: dokumen, kain, obat, dll |
| `ekspedisi` | Data utama penerimaan barang |
| `log_status_ekspedisi` | History perubahan status |

---

## 📄 Fitur Export PDF

Laporan PDF berisi:
- Header dengan nama perusahaan & periode
- Ringkasan statistik (total, diterima, proses, menunggu)
- Tabel detail semua ekspedisi (no, tanggal, barang, pengirim, tujuan, status)
- Nomor halaman
- Footer

---

## 🔧 Troubleshooting

**Q: Foto tidak terupload?**
A: Pastikan bucket `ekspedisi-foto` sudah dibuat dan policynya sudah benar (public + authenticated insert)

**Q: Login gagal terus?**
A: Cek kembali `supabaseUrl` dan `supabaseAnonKey` di `app_constants.dart`

**Q: Data tidak muncul?**
A: Pastikan kolom `lokasi_id` di profile user sudah diisi dengan lokasi yang valid

**Q: Error "permission denied"?**
A: Jalankan ulang bagian RLS policy di schema.sql

---

## 📞 Dependensi Utama

| Package | Fungsi |
|---------|--------|
| `supabase_flutter` | Backend & auth |
| `flutter_riverpod` | State management |
| `go_router` | Navigasi |
| `image_picker` | Kamera & galeri |
| `pdf` + `printing` | Generate & buka PDF |
| `fl_chart` | Grafik dashboard |
| `permission_handler` | Izin kamera/storage |
| `intl` | Format tanggal Indonesia |

---

*Dibuat untuk kebutuhan operasional pabrik — versi 1.0.0*
