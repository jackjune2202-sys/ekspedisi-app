// lib/presentation/screens/security/security_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../providers/app_providers.dart';

class SecurityHomeScreen extends ConsumerStatefulWidget {
  const SecurityHomeScreen({super.key});

  @override
  ConsumerState<SecurityHomeScreen> createState() => _SecurityHomeScreenState();
}

class _SecurityHomeScreenState extends ConsumerState<SecurityHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menungguAsync = ref.watch(ekspedisiMenungguProvider);
    final prosesAsync = ref.watch(ekspedisiDalamPengirimanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal Security'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hourglass_empty_rounded, size: 18),
                  const SizedBox(width: 6),
                  const Text('Menunggu'),
                  const SizedBox(width: 6),
                  menungguAsync.when(
                    data: (list) => _CountBadge(list.length, AppTheme.statusMenunggu),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_shipping_rounded, size: 18),
                  const SizedBox(width: 6),
                  const Text('Dalam Proses'),
                  const SizedBox(width: 6),
                  prosesAsync.when(
                    data: (list) => _CountBadge(list.length, AppTheme.statusPengiriman),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(ekspedisiMenungguProvider);
              ref.invalidate(ekspedisiDalamPengirimanProvider);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // Tab 1: Menunggu diambil
          menungguAsync.when(
            data: (list) => list.isEmpty
                ? const _EmptyTab(
                    icon: Icons.check_circle_outline_rounded,
                    message: 'Tidak ada barang menunggu',
                    sub: 'Semua barang sudah diambil 👍',
                  )
                : RefreshIndicator(
                    onRefresh: () async => ref.invalidate(ekspedisiMenungguProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) => _SecurityItemCard(
                        item: list[i],
                        mode: _CardMode.ambil,
                        onTap: () => context.push('/security/ambil/${list[i].id}'),
                      ),
                    ),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorWidget(message: '$e', onRetry: () => ref.invalidate(ekspedisiMenungguProvider)),
          ),

          // Tab 2: Dalam proses
          prosesAsync.when(
            data: (list) => list.isEmpty
                ? const _EmptyTab(
                    icon: Icons.inbox_rounded,
                    message: 'Tidak ada barang dalam proses',
                    sub: 'Ambil barang dari tab Menunggu',
                  )
                : RefreshIndicator(
                    onRefresh: () async => ref.invalidate(ekspedisiDalamPengirimanProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) => _SecurityItemCard(
                        item: list[i],
                        mode: _CardMode.kirim,
                        onTap: () => context.push('/security/ambil/${list[i].id}'),
                      ),
                    ),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorWidget(message: '$e', onRetry: () => ref.invalidate(ekspedisiDalamPengirimanProvider)),
          ),
        ],
      ),
    );
  }
}

enum _CardMode { ambil, kirim }

class _SecurityItemCard extends StatelessWidget {
  final EkspedisiModel item;
  final _CardMode mode;
  final VoidCallback onTap;
  const _SecurityItemCard({required this.item, required this.mode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM, HH:mm', 'id_ID');
    final statusColor = AppTheme.statusColor(item.status);

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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      AppTheme.statusLabel(item.status),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Barang info
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _InfoRow(Icons.inventory_2_outlined, 'Barang',
                        '${item.deskripsiBarang} (${item.qty} ${item.satuan})'),
                    const SizedBox(height: 6),
                    _InfoRow(Icons.person_outline, 'Dari', item.namaPengirim +
                        (item.perusahaanPengirim != null ? ' — ${item.perusahaanPengirim}' : '')),
                    const SizedBox(height: 6),
                    _InfoRow(Icons.apartment_outlined, 'Tujuan', item.departemenTujuan),
                    if (item.keterangan != null) ...[
                      const SizedBox(height: 6),
                      _InfoRow(Icons.notes_outlined, 'Ket.', item.keterangan!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(Icons.access_time, size: 13, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Diterima: ${fmt.format(item.createdAt.toLocal())}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: onTap,
                    icon: Icon(
                      mode == _CardMode.ambil
                          ? Icons.shopping_bag_outlined
                          : Icons.local_shipping_rounded,
                      size: 16,
                    ),
                    label: Text(mode == _CardMode.ambil ? 'Ambil' : 'Proses'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                      backgroundColor: mode == _CardMode.ambil
                          ? AppTheme.primary
                          : AppTheme.warning,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        SizedBox(
          width: 40,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ),
        const Text(': ', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;
  const _CountBadge(this.count, this.color);

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$count',
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  const _EmptyTab({required this.icon, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}
