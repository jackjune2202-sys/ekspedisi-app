// lib/presentation/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final statsAsync = ref.watch(statistikProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Dashboard Ekspedisi'),
        actions: [
          profileAsync.when(
            data: (profile) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        profile?.namaLengkap ?? '',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        profile?.roleDisplay ?? '',
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white24,
                    child: Text(
                      profile?.namaLengkap.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'logout', child: Text('Keluar')),
            ],
            onSelected: (v) async {
              if (v == 'logout') {
                await ref.read(repoProvider).signOut();
                if (context.mounted) context.go('/login');
              }
            },
          ),
        ],
      ),
      drawer: const _AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(statistikProvider);
          ref.invalidate(currentProfileProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              profileAsync.when(
                data: (p) => _GreetingCard(nama: p?.namaLengkap ?? ''),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // Quick Actions
              _QuickActions(profile: profileAsync.value),
              const SizedBox(height: 20),

              // Stats Cards
              statsAsync.when(
                data: (stats) => _StatsSection(stats: stats),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 20),

              // Chart
              statsAsync.when(
                data: (stats) => _ChartSection(stats: stats),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final String nama;
  const _GreetingCard({required this.nama});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat Pagi';
    if (h < 15) return 'Selamat Siang';
    if (h < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting, ${nama.split(' ').first}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.local_shipping_rounded, size: 48, color: Colors.white30),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final dynamic profile;
  const _QuickActions({this.profile});

  @override
  Widget build(BuildContext context) {
    final role = profile?.role ?? '';
    final actions = <Map<String, dynamic>>[
      if (role == 'receptionist' || role == 'admin') ...[
        {'icon': Icons.add_box_rounded, 'label': 'Input Barang', 'route': '/input-barang', 'color': AppTheme.primary},
        {'icon': Icons.list_alt_rounded, 'label': 'Daftar Ekspedisi', 'route': '/daftar-ekspedisi', 'color': AppTheme.accent},
      ],
      if (role == 'security' || role == 'admin') ...[
        {'icon': Icons.security_rounded, 'label': 'Ambil Barang', 'route': '/security', 'color': AppTheme.warning},
      ],
      {'icon': Icons.bar_chart_rounded, 'label': 'Laporan', 'route': '/laporan', 'color': AppTheme.success},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Menu Cepat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: actions.length > 3 ? 4 : actions.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: actions.map((a) => _QuickActionItem(
            icon: a['icon'] as IconData,
            label: a['label'] as String,
            color: a['color'] as Color,
            onTap: () => context.push(a['route'] as String),
          )).toList(),
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem('Total', stats['total'] ?? 0, Icons.inbox_rounded, AppTheme.primary),
      _StatItem('Menunggu', stats['menunggu'] ?? 0, Icons.hourglass_empty_rounded, AppTheme.statusMenunggu),
      _StatItem('Proses', (stats['diambil_security'] ?? 0) + (stats['dalam_pengiriman'] ?? 0), Icons.local_shipping_rounded, AppTheme.statusPengiriman),
      _StatItem('Diterima', stats['diterima'] ?? 0, Icons.check_circle_rounded, AppTheme.statusDiterima),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Statistik Hari Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: items.map((s) => _StatCard(item: s)).toList(),
        ),
      ],
    );
  }
}

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  _StatItem(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${item.value}',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: item.color,
                ),
              ),
              Text(item.label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _ChartSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final perHari = stats['per_hari'] as Map<String, int>? ?? {};
    final keys = perHari.keys.toList();
    final values = perHari.values.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tren 7 Hari Terakhir',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: values.isEmpty ? 10 :
                      (values.reduce((a, b) => a > b ? a : b) + 2).toDouble(),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt()}',
                          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final idx = v.toInt();
                          if (idx >= 0 && idx < keys.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                keys[idx],
                                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: AppTheme.divider,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(values.length, (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: values[i].toDouble(),
                        color: AppTheme.primary,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: values.isEmpty ? 10 :
                              (values.reduce((a, b) => a > b ? a : b) + 2).toDouble(),
                          color: AppTheme.divider,
                        ),
                      ),
                    ],
                  )),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Drawer
class _AppDrawer extends ConsumerWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Drawer(
      child: Column(
        children: [
          profileAsync.when(
            data: (p) => UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.primary),
              accountName: Text(p?.namaLengkap ?? ''),
              accountEmail: Text(p?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  p?.namaLengkap.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              otherAccountsPictures: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    p?.roleDisplay ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
            loading: () => const DrawerHeader(child: CircularProgressIndicator()),
            error: (_, __) => const DrawerHeader(child: SizedBox.shrink()),
          ),

          _DrawerItem(Icons.dashboard_rounded, 'Dashboard', '/dashboard'),
          _DrawerItem(Icons.add_box_rounded, 'Input Barang Masuk', '/input-barang'),
          _DrawerItem(Icons.list_alt_rounded, 'Daftar Ekspedisi', '/daftar-ekspedisi'),
          _DrawerItem(Icons.security_rounded, 'Portal Security', '/security'),
          _DrawerItem(Icons.bar_chart_rounded, 'Laporan & Export', '/laporan'),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppTheme.error),
            title: const Text('Keluar', style: TextStyle(color: AppTheme.error)),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(repoProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  const _DrawerItem(this.icon, this.label, this.route);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
    );
  }
}
