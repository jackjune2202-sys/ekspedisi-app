// lib/presentation/screens/receptionist/daftar_ekspedisi_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../providers/app_providers.dart';

class DaftarEkspedisiScreen extends ConsumerStatefulWidget {
  const DaftarEkspedisiScreen({super.key});

  @override
  ConsumerState<DaftarEkspedisiScreen> createState() =>
      _DaftarEkspedisiScreenState();
}

class _DaftarEkspedisiScreenState
    extends ConsumerState<DaftarEkspedisiScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ekspedisiAsync = ref.watch(ekspedisiListProvider);
    final filter = ref.watch(filterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Ekspedisi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterSheet(context, ref),
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(ekspedisiListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/input-barang'),
        icon: const Icon(Icons.add),
        label: const Text('Input Baru'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari nomor, pengirim, barang...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(filterProvider.notifier).update(
                            (s) => s.copyWith(clearSearch: true),
                          );
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) {
                ref.read(filterProvider.notifier).update(
                  (s) => s.copyWith(search: v.isEmpty ? null : v),
                );
              },
            ),
          ),

          // Active filter chips
          if (filter.status != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  const Text('Filter: ', style: TextStyle(fontSize: 12)),
                  Chip(
                    label: Text(AppTheme.statusLabel(filter.status!)),
                    backgroundColor:
                        AppTheme.statusColor(filter.status!).withOpacity(0.1),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => ref.read(filterProvider.notifier).update(
                      (s) => s.copyWith(clearStatus: true),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

          // List
          Expanded(
            child: ekspedisiAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return _EmptyState(
                    onAdd: () => context.push('/input-barang'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(ekspedisiListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) => _EkspedisiCard(
                      item: list[i],
                      onTap: () => context.push('/detail/${list[i].id}'),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                    const SizedBox(height: 12),
                    Text('Error: $e'),
                    TextButton(
                      onPressed: () => ref.invalidate(ekspedisiListProvider),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.read(filterProvider);
    String? tempStatus = currentFilter.status;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      ref.read(filterProvider.notifier).update(
                        (_) => const EkspedisiFilter(),
                      );
                      Navigator.pop(ctx);
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Status',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  null,
                  'menunggu',
                  'diambil_security',
                  'dalam_pengiriman',
                  'diterima',
                  'dikembalikan',
                ].map((s) => ChoiceChip(
                  label: Text(s == null ? 'Semua' : AppTheme.statusLabel(s)),
                  selected: tempStatus == s,
                  onSelected: (_) => setStateModal(() => tempStatus = s),
                  selectedColor:
                      s == null ? AppTheme.primary.withOpacity(0.2) :
                      AppTheme.statusColor(s).withOpacity(0.2),
                )).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(filterProvider.notifier).update(
                      (s) => s.copyWith(
                        status: tempStatus,
                        clearStatus: tempStatus == null,
                      ),
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Terapkan Filter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EkspedisiCard extends StatelessWidget {
  final EkspedisiModel item;
  final VoidCallback onTap;
  const _EkspedisiCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.statusColor(item.status);
    final fmt = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.nomorEkspedisi,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  _StatusBadge(status: item.status, color: statusColor),
                ],
              ),
              const SizedBox(height: 8),

              // Barang
              Row(
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 15, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${item.deskripsiBarang} (${item.qty} ${item.satuan})',
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Pengirim
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 15, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.namaPengirim +
                          (item.perusahaanPengirim != null
                              ? ' • ${item.perusahaanPengirim}'
                              : ''),
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Tujuan
              Row(
                children: [
                  const Icon(Icons.apartment_outlined,
                      size: 15, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    item.departemenTujuan,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Footer
              Row(
                children: [
                  if (item.fotoBarangUrls.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.photo_outlined,
                            size: 14, color: AppTheme.accent),
                        const SizedBox(width: 4),
                        Text(
                          '${item.fotoBarangUrls.length} foto',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.accent),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  const Icon(Icons.access_time,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    fmt.format(item.createdAt.toLocal()),
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppTheme.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        AppTheme.statusLabel(status),
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Belum ada data ekspedisi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const Text('Mulai dengan input barang masuk',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Input Barang'),
          ),
        ],
      ),
    );
  }
}
