// lib/presentation/providers/app_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/models.dart';
import '../../data/repositories/ekspedisi_repository.dart';

// ==================== REPOSITORY ====================
final repoProvider = Provider<EkspedisiRepository>((ref) {
  return EkspedisiRepository();
});

// ==================== AUTH ====================
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(repoProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  ref.watch(authStateProvider);
  return ref.read(repoProvider).getCurrentProfile();
});

// ==================== LOKASI ====================
final lokasiListProvider = FutureProvider<List<LokasiModel>>((ref) async {
  return ref.read(repoProvider).getLokasi();
});

final selectedLokasiProvider = StateProvider<LokasiModel?>((ref) => null);

// ==================== KATEGORI ====================
final kategoriListProvider = FutureProvider<List<KategoriModel>>((ref) async {
  return ref.read(repoProvider).getKategori();
});

// ==================== FILTER STATE ====================
class EkspedisiFilter {
  final String? lokasiId;
  final String? status;
  final DateTime? dari;
  final DateTime? sampai;
  final String? search;

  const EkspedisiFilter({
    this.lokasiId,
    this.status,
    this.dari,
    this.sampai,
    this.search,
  });

  EkspedisiFilter copyWith({
    String? lokasiId,
    String? status,
    DateTime? dari,
    DateTime? sampai,
    String? search,
    bool clearStatus = false,
    bool clearSearch = false,
  }) {
    return EkspedisiFilter(
      lokasiId: lokasiId ?? this.lokasiId,
      status: clearStatus ? null : (status ?? this.status),
      dari: dari ?? this.dari,
      sampai: sampai ?? this.sampai,
      search: clearSearch ? null : (search ?? this.search),
    );
  }
}

final filterProvider = StateProvider<EkspedisiFilter>((ref) => const EkspedisiFilter());

// ==================== EKSPEDISI LIST ====================
final ekspedisiListProvider =
    FutureProvider.autoDispose<List<EkspedisiModel>>((ref) async {
  final filter = ref.watch(filterProvider);
  return ref.read(repoProvider).getEkspedisi(
    lokasiId: filter.lokasiId,
    status: filter.status,
    dari: filter.dari,
    sampai: filter.sampai,
    search: filter.search,
  );
});

// Security: hanya yang menunggu
final ekspedisiMenungguProvider =
    FutureProvider.autoDispose<List<EkspedisiModel>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  return ref.read(repoProvider).getEkspedisi(
    lokasiId: profile?.lokasiId,
    status: 'menunggu',
  );
});

// Security: yang sedang dikirim oleh security ini
final ekspedisiDalamPengirimanProvider =
    FutureProvider.autoDispose<List<EkspedisiModel>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  final list = await ref.read(repoProvider).getEkspedisi(
    lokasiId: profile?.lokasiId,
  );
  return list.where((e) =>
    e.status == 'diambil_security' || e.status == 'dalam_pengiriman'
  ).toList();
});

// ==================== STATISTIK ====================
final statistikProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final filter = ref.watch(filterProvider);
  return ref.read(repoProvider).getStatistik(
    lokasiId: filter.lokasiId,
    dari: filter.dari,
    sampai: filter.sampai,
  );
});

// ==================== PENERIMA LIST ====================
final penerimaListProvider =
    FutureProvider.autoDispose.family<List<ProfileModel>, String>((ref, lokasiId) async {
  return ref.read(repoProvider).getPenerimaDaftarByLokasi(lokasiId);
});
