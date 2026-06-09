// lib/data/repositories/ekspedisi_repository.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class EkspedisiRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // ==================== EKSPEDISI ====================

  /// Ambil semua ekspedisi dengan filter opsional
  Future<List<EkspedisiModel>> getEkspedisi({
    String? lokasiId,
    String? status,
    DateTime? dari,
    DateTime? sampai,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client
        .from('ekspedisi')
        .select('''
          *,
          lokasi:lokasi_id(nama),
          kategori_barang:kategori_id(nama),
          diterima_oleh:diterima_oleh_id(nama_lengkap),
          diambil_security:diambil_security_id(nama_lengkap)
        ''')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    if (lokasiId != null) {
      query = query.eq('lokasi_id', lokasiId) as dynamic;
    }
    if (status != null) {
      query = query.eq('status', status) as dynamic;
    }
    if (dari != null) {
      query = query.gte('created_at', dari.toIso8601String()) as dynamic;
    }
    if (sampai != null) {
      query = query.lte('created_at', sampai.toIso8601String()) as dynamic;
    }

    final response = await query;
    List<EkspedisiModel> list =
        (response as List).map((e) => EkspedisiModel.fromMap(e)).toList();

    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((e) =>
        e.nomorEkspedisi.toLowerCase().contains(q) ||
        e.namaPengirim.toLowerCase().contains(q) ||
        e.deskripsiBarang.toLowerCase().contains(q) ||
        (e.departemenTujuan.toLowerCase().contains(q)) ||
        (e.namaPenerimaManual?.toLowerCase().contains(q) ?? false)
      ).toList();
    }

    return list;
  }

  /// Ambil satu ekspedisi by ID
  Future<EkspedisiModel> getEkspedisiById(String id) async {
    final response = await _client
        .from('ekspedisi')
        .select('''
          *,
          lokasi:lokasi_id(nama),
          kategori_barang:kategori_id(nama),
          diterima_oleh:diterima_oleh_id(nama_lengkap),
          diambil_security:diambil_security_id(nama_lengkap)
        ''')
        .eq('id', id)
        .single();
    return EkspedisiModel.fromMap(response);
  }

  /// Buat ekspedisi baru (oleh receptionist)
  Future<EkspedisiModel> createEkspedisi({
    required String lokasiId,
    required String namaPengirim,
    String? perusahaanPengirim,
    String? noTeleponPengirim,
    String? kategoriId,
    required String deskripsiBarang,
    required int qty,
    String satuan = 'pcs',
    String? keterangan,
    String? penerimaId,
    String? namaPenerimaManual,
    required String departemenTujuan,
    List<String> fotoUrls = const [],
  }) async {
    final userId = _client.auth.currentUser!.id;

    final data = {
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
      'status': 'menunggu',
      'foto_barang_urls': fotoUrls,
      'diterima_oleh_id': userId,
      'diterima_pada': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('ekspedisi')
        .insert(data)
        .select()
        .single();

    return EkspedisiModel.fromMap(response);
  }

  /// Security ambil barang (update status + foto)
  Future<void> ambilBarang({
    required String ekspedisiId,
    required List<String> fotoUrls,
    String? catatan,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('ekspedisi').update({
      'status': 'diambil_security',
      'diambil_security_id': userId,
      'diambil_pada': DateTime.now().toIso8601String(),
      'foto_pengiriman_urls': fotoUrls,
      'catatan_security': catatan,
    }).eq('id', ekspedisiId);
  }

  /// Security kirim barang
  Future<void> kirimBarang({
    required String ekspedisiId,
    List<String>? fotoTambahan,
  }) async {
    final data = <String, dynamic>{
      'status': 'dalam_pengiriman',
      'dikirim_pada': DateTime.now().toIso8601String(),
    };
    if (fotoTambahan != null && fotoTambahan.isNotEmpty) {
      data['foto_pengiriman_urls'] = fotoTambahan;
    }
    await _client.from('ekspedisi').update(data).eq('id', ekspedisiId);
  }

  /// Konfirmasi diterima
  Future<void> konfirmasiDiterima({
    required String ekspedisiId,
    List<String>? fotoBukti,
    String? catatan,
    String? tandaTangan,
  }) async {
    await _client.from('ekspedisi').update({
      'status': 'diterima',
      'selesai_pada': DateTime.now().toIso8601String(),
      'foto_bukti_terima_urls': fotoBukti ?? [],
      'catatan_penerima': catatan,
      'tanda_tangan_penerima': tandaTangan,
    }).eq('id', ekspedisiId);
  }

  // ==================== FOTO UPLOAD ====================

  /// Upload foto ke Supabase Storage
  Future<String> uploadFoto(File file, {String folder = 'barang'}) async {
    final ext = file.path.split('.').last;
    final fileName = '${folder}/${const Uuid().v4()}.$ext';

    await _client.storage
        .from('ekspedisi-foto')
        .upload(fileName, file);

    return _client.storage
        .from('ekspedisi-foto')
        .getPublicUrl(fileName);
  }

  /// Upload multiple foto
  Future<List<String>> uploadMultipleFoto(
      List<File> files, {String folder = 'barang'}) async {
    final urls = <String>[];
    for (final file in files) {
      final url = await uploadFoto(file, folder: folder);
      urls.add(url);
    }
    return urls;
  }

  // ==================== STATISTIK ====================

  /// Statistik dashboard
  Future<Map<String, dynamic>> getStatistik({
    String? lokasiId,
    DateTime? dari,
    DateTime? sampai,
  }) async {
    var query = _client.from('ekspedisi').select('status, created_at');

    if (lokasiId != null) {
      query = query.eq('lokasi_id', lokasiId) as dynamic;
    }

    final response = await query as List;
    final data = response.map((e) => e as Map<String, dynamic>).toList();

    // Hitung per status
    final Map<String, int> perStatus = {};
    int total = 0;

    for (final item in data) {
      final status = item['status'] as String;
      perStatus[status] = (perStatus[status] ?? 0) + 1;
      total++;
    }

    // Hitung per hari (7 hari terakhir)
    final Map<String, int> perHari = {};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = '${date.day}/${date.month}';
      perHari[key] = 0;
    }

    for (final item in data) {
      final dt = DateTime.parse(item['created_at']);
      final daysAgo = now.difference(dt).inDays;
      if (daysAgo <= 6) {
        final key = '${dt.day}/${dt.month}';
        perHari[key] = (perHari[key] ?? 0) + 1;
      }
    }

    return {
      'total': total,
      'menunggu': perStatus['menunggu'] ?? 0,
      'diambil_security': perStatus['diambil_security'] ?? 0,
      'dalam_pengiriman': perStatus['dalam_pengiriman'] ?? 0,
      'diterima': perStatus['diterima'] ?? 0,
      'dikembalikan': perStatus['dikembalikan'] ?? 0,
      'per_hari': perHari,
    };
  }

  // ==================== PROFIL & LOKASI ====================

  Future<ProfileModel?> getCurrentProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('profiles')
        .select('*, lokasi:lokasi_id(nama)')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return ProfileModel.fromMap(response);
  }

  Future<List<ProfileModel>> getPenerimaDaftarByLokasi(String lokasiId) async {
    final response = await _client
        .from('profiles')
        .select('*, lokasi:lokasi_id(nama)')
        .eq('lokasi_id', lokasiId)
        .eq('aktif', true)
        .order('nama_lengkap');
    return (response as List).map((e) => ProfileModel.fromMap(e)).toList();
  }

  Future<List<LokasiModel>> getLokasi() async {
    final response = await _client
        .from('lokasi')
        .select()
        .eq('aktif', true)
        .order('nama');
    return (response as List).map((e) => LokasiModel.fromMap(e)).toList();
  }

  Future<List<KategoriModel>> getKategori() async {
    final response = await _client
        .from('kategori_barang')
        .select()
        .order('nama');
    return (response as List).map((e) => KategoriModel.fromMap(e)).toList();
  }

  // ==================== AUTH ====================

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ==================== REALTIME ====================

  Stream<List<Map<String, dynamic>>> watchEkspedisiMenunggu(String lokasiId) {
    return _client
        .from('ekspedisi')
        .stream(primaryKey: ['id'])
        .eq('lokasi_id', lokasiId)
        .order('created_at', ascending: false);
  }
}
