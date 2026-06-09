// lib/data/models/ekspedisi_model.dart
class EkspedisiModel {
  final String id;
  final String nomorEkspedisi;
  final String lokasiId;
  final String? lokasiNama;

  // Pengirim
  final String namaPengirim;
  final String? perusahaanPengirim;
  final String? noTeleponPengirim;

  // Barang
  final String? kategoriId;
  final String? kategoriNama;
  final String deskripsiBarang;
  final int qty;
  final String satuan;
  final String? keterangan;

  // Tujuan
  final String? penerimaId;
  final String? namaPenerimaManual;
  final String departemenTujuan;

  // Status
  final String status;

  // Foto
  final List<String> fotoBarangUrls;
  final List<String> fotoPengirimanUrls;
  final List<String> fotoBuktiTerimaUrls;

  // Users
  final String? diterimaOlehId;
  final String? diterimaOlehNama;
  final DateTime? diterimaPada;
  final String? diambilSecurityId;
  final String? diambilSecurityNama;
  final DateTime? diambilPada;
  final DateTime? dikirimPada;
  final DateTime? selesaiPada;
  final String? catatanSecurity;
  final String? catatanPenerima;

  final DateTime createdAt;
  final DateTime updatedAt;

  EkspedisiModel({
    required this.id,
    required this.nomorEkspedisi,
    required this.lokasiId,
    this.lokasiNama,
    required this.namaPengirim,
    this.perusahaanPengirim,
    this.noTeleponPengirim,
    this.kategoriId,
    this.kategoriNama,
    required this.deskripsiBarang,
    required this.qty,
    this.satuan = 'pcs',
    this.keterangan,
    this.penerimaId,
    this.namaPenerimaManual,
    required this.departemenTujuan,
    required this.status,
    this.fotoBarangUrls = const [],
    this.fotoPengirimanUrls = const [],
    this.fotoBuktiTerimaUrls = const [],
    this.diterimaOlehId,
    this.diterimaOlehNama,
    this.diterimaPada,
    this.diambilSecurityId,
    this.diambilSecurityNama,
    this.diambilPada,
    this.dikirimPada,
    this.selesaiPada,
    this.catatanSecurity,
    this.catatanPenerima,
    required this.createdAt,
    required this.updatedAt,
  });

  String get namaPenerimaDisplay =>
      namaPenerimaManual ?? diterimaOlehNama ?? '-';

  factory EkspedisiModel.fromMap(Map<String, dynamic> map) {
    return EkspedisiModel(
      id: map['id'] ?? '',
      nomorEkspedisi: map['nomor_ekspedisi'] ?? '',
      lokasiId: map['lokasi_id'] ?? '',
      lokasiNama: map['lokasi']?['nama'],
      namaPengirim: map['nama_pengirim'] ?? '',
      perusahaanPengirim: map['perusahaan_pengirim'],
      noTeleponPengirim: map['no_telepon_pengirim'],
      kategoriId: map['kategori_id'],
      kategoriNama: map['kategori_barang']?['nama'],
      deskripsiBarang: map['deskripsi_barang'] ?? '',
      qty: map['qty'] ?? 1,
      satuan: map['satuan'] ?? 'pcs',
      keterangan: map['keterangan'],
      penerimaId: map['penerima_id'],
      namaPenerimaManual: map['nama_penerima_manual'],
      departemenTujuan: map['departemen_tujuan'] ?? '',
      status: map['status'] ?? 'menunggu',
      fotoBarangUrls: _parseList(map['foto_barang_urls']),
      fotoPengirimanUrls: _parseList(map['foto_pengiriman_urls']),
      fotoBuktiTerimaUrls: _parseList(map['foto_bukti_terima_urls']),
      diterimaOlehId: map['diterima_oleh_id'],
      diterimaOlehNama: map['diterima_oleh']?['nama_lengkap'],
      diterimaPada: map['diterima_pada'] != null
          ? DateTime.parse(map['diterima_pada'])
          : null,
      diambilSecurityId: map['diambil_security_id'],
      diambilSecurityNama: map['diambil_security']?['nama_lengkap'],
      diambilPada: map['diambil_pada'] != null
          ? DateTime.parse(map['diambil_pada'])
          : null,
      dikirimPada: map['dikirim_pada'] != null
          ? DateTime.parse(map['dikirim_pada'])
          : null,
      selesaiPada: map['selesai_pada'] != null
          ? DateTime.parse(map['selesai_pada'])
          : null,
      catatanSecurity: map['catatan_security'],
      catatanPenerima: map['catatan_penerima'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at'] ?? map['created_at']),
    );
  }

  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.cast<String>();
    return [];
  }

  Map<String, dynamic> toMap() {
    return {
      'lokasi_id': lokasiId,
      'nama_pengirim': namaPengirim,
      'perusahaan_pengirim': perusahaanPengirim,
      'no_telepon_pengirim': noTeleponPengirim,
      'kategori_id': kategoriId,
      'deskripsi_barang': deskripsiBarang,
      'qty': qty,
      'satuan': satuan,
      'keterangan': keterangan,
      'penerima_id': penerimaId,
      'nama_penerima_manual': namaPenerimaManual,
      'departemen_tujuan': departemenTujuan,
      'status': status,
    };
  }

  EkspedisiModel copyWith({
    String? status,
    List<String>? fotoBarangUrls,
    List<String>? fotoPengirimanUrls,
    List<String>? fotoBuktiTerimaUrls,
    String? diambilSecurityId,
    DateTime? diambilPada,
    DateTime? dikirimPada,
    DateTime? selesaiPada,
    String? catatanSecurity,
    String? catatanPenerima,
  }) {
    return EkspedisiModel(
      id: id,
      nomorEkspedisi: nomorEkspedisi,
      lokasiId: lokasiId,
      lokasiNama: lokasiNama,
      namaPengirim: namaPengirim,
      perusahaanPengirim: perusahaanPengirim,
      noTeleponPengirim: noTeleponPengirim,
      kategoriId: kategoriId,
      kategoriNama: kategoriNama,
      deskripsiBarang: deskripsiBarang,
      qty: qty,
      satuan: satuan,
      keterangan: keterangan,
      penerimaId: penerimaId,
      namaPenerimaManual: namaPenerimaManual,
      departemenTujuan: departemenTujuan,
      status: status ?? this.status,
      fotoBarangUrls: fotoBarangUrls ?? this.fotoBarangUrls,
      fotoPengirimanUrls: fotoPengirimanUrls ?? this.fotoPengirimanUrls,
      fotoBuktiTerimaUrls: fotoBuktiTerimaUrls ?? this.fotoBuktiTerimaUrls,
      diterimaOlehId: diterimaOlehId,
      diterimaOlehNama: diterimaOlehNama,
      diterimaPada: diterimaPada,
      diambilSecurityId: diambilSecurityId ?? this.diambilSecurityId,
      diambilSecurityNama: diambilSecurityNama,
      diambilPada: diambilPada ?? this.diambilPada,
      dikirimPada: dikirimPada ?? this.dikirimPada,
      selesaiPada: selesaiPada ?? this.selesaiPada,
      catatanSecurity: catatanSecurity ?? this.catatanSecurity,
      catatanPenerima: catatanPenerima ?? this.catatanPenerima,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// lib/data/models/profile_model.dart
class ProfileModel {
  final String id;
  final String namaLengkap;
  final String email;
  final String role;
  final String? lokasiId;
  final String? lokasiNama;
  final String? departemen;
  final String? noHp;
  final String? fotoUrl;
  final bool aktif;

  ProfileModel({
    required this.id,
    required this.namaLengkap,
    required this.email,
    required this.role,
    this.lokasiId,
    this.lokasiNama,
    this.departemen,
    this.noHp,
    this.fotoUrl,
    this.aktif = true,
  });

  String get roleDisplay {
    switch (role) {
      case 'admin': return 'Admin';
      case 'receptionist': return 'Receptionist';
      case 'security': return 'Security';
      case 'penerima': return 'Penerima';
      default: return role;
    }
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] ?? '',
      namaLengkap: map['nama_lengkap'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'penerima',
      lokasiId: map['lokasi_id'],
      lokasiNama: map['lokasi']?['nama'],
      departemen: map['departemen'],
      noHp: map['no_hp'],
      fotoUrl: map['foto_url'],
      aktif: map['aktif'] ?? true,
    );
  }
}

// lib/data/models/lokasi_model.dart
class LokasiModel {
  final String id;
  final String nama;
  final String? alamat;
  final String kode;
  final bool aktif;

  LokasiModel({
    required this.id,
    required this.nama,
    this.alamat,
    required this.kode,
    this.aktif = true,
  });

  factory LokasiModel.fromMap(Map<String, dynamic> map) {
    return LokasiModel(
      id: map['id'] ?? '',
      nama: map['nama'] ?? '',
      alamat: map['alamat'],
      kode: map['kode'] ?? '',
      aktif: map['aktif'] ?? true,
    );
  }
}

// lib/data/models/kategori_model.dart
class KategoriModel {
  final String id;
  final String nama;
  final String? icon;
  final String warna;

  KategoriModel({
    required this.id,
    required this.nama,
    this.icon,
    this.warna = '#2196F3',
  });

  factory KategoriModel.fromMap(Map<String, dynamic> map) {
    return KategoriModel(
      id: map['id'] ?? '',
      nama: map['nama'] ?? '',
      icon: map['icon'],
      warna: map['warna'] ?? '#2196F3',
    );
  }
}
