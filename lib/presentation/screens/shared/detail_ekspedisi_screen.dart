// lib/presentation/screens/shared/detail_ekspedisi_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../providers/app_providers.dart';

class DetailEkspedisiScreen extends ConsumerWidget {
  final String ekspedisiId;
  const DetailEkspedisiScreen({super.key, required this.ekspedisiId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = FutureProvider.autoDispose<EkspedisiModel>(
      (ref) => ref.read(repoProvider).getEkspedisiById(ekspedisiId),
    );

    return Consumer(
      builder: (ctx, ref2, _) {
        final data = ref2.watch(detailAsync);
        return Scaffold(
          appBar: AppBar(
            title: Text(data.maybeWhen(
                data: (d) => d.nomorEkspedisi, orElse: () => 'Detail')),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref2.invalidate(detailAsync),
              ),
            ],
          ),
          body: data.when(
            data: (item) => _DetailBody(item: item),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        );
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  final EkspedisiModel item;
  const _DetailBody({required this.item});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          _StatusBanner(status: item.status),
          const SizedBox(height: 16),

          // Info umum
          _Section(
            title: 'Informasi Barang',
            icon: Icons.inventory_2_outlined,
            child: Column(children: [
              _DetailRow('No. Ekspedisi', item.nomorEkspedisi, bold: true),
              _DetailRow('Kategori', item.kategoriNama ?? '-'),
              _DetailRow('Deskripsi', item.deskripsiBarang),
              _DetailRow('Qty', '${item.qty} ${item.satuan}'),
              if (item.keterangan != null)
                _DetailRow('Keterangan', item.keterangan!),
            ]),
          ),
          const SizedBox(height: 12),

          _Section(
            title: 'Data Pengirim',
            icon: Icons.person_outline,
            child: Column(children: [
              _DetailRow('Nama', item.namaPengirim),
              if (item.perusahaanPengirim != null)
                _DetailRow('Perusahaan', item.perusahaanPengirim!),
              if (item.noTeleponPengirim != null)
                _DetailRow('No. Telepon', item.noTeleponPengirim!),
            ]),
          ),
          const SizedBox(height: 12),

          _Section(
            title: 'Tujuan Penerimaan',
            icon: Icons.apartment_outlined,
            child: Column(children: [
              _DetailRow('Departemen', item.departemenTujuan),
              if (item.namaPenerimaManual != null)
                _DetailRow('Penerima', item.namaPenerimaManual!),
              _DetailRow('Lokasi', item.lokasiNama ?? '-'),
            ]),
          ),
          const SizedBox(height: 12),

          // Foto barang
          if (item.fotoBarangUrls.isNotEmpty) ...[
            _FotoGallery(
              title: 'Foto Barang (Receptionist)',
              urls: item.fotoBarangUrls,
            ),
            const SizedBox(height: 12),
          ],

          // Foto security
          if (item.fotoPengirimanUrls.isNotEmpty) ...[
            _FotoGallery(
              title: 'Foto Pengambilan (Security)',
              urls: item.fotoPengirimanUrls,
            ),
            const SizedBox(height: 12),
          ],

          // Foto bukti terima
          if (item.fotoBuktiTerimaUrls.isNotEmpty) ...[
            _FotoGallery(
              title: 'Foto Bukti Diterima',
              urls: item.fotoBuktiTerimaUrls,
            ),
            const SizedBox(height: 12),
          ],

          // Timeline
          _TimelineSection(item: item),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status);
    final label = AppTheme.statusLabel(status);

    final icons = {
      'menunggu': Icons.hourglass_empty_rounded,
      'diambil_security': Icons.security_rounded,
      'dalam_pengiriman': Icons.local_shipping_rounded,
      'diterima': Icons.check_circle_rounded,
      'dikembalikan': Icons.keyboard_return_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icons[status] ?? Icons.info_outline, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status Terkini',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Text(
                label,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Section({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary)),
              ],
            ),
            const Divider(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _DetailRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ),
          const Text(': ',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FotoGallery extends StatelessWidget {
  final String title;
  final List<String> urls;
  const _FotoGallery({required this.title, required this.urls});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_library_outlined,
                    size: 18, color: AppTheme.accent),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: urls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) => GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      child: InteractiveViewer(
                        child: Image.network(urls[i], fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      urls[i],
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      loadingBuilder: (ctx, child, progress) => progress == null
                          ? child
                          : Container(
                              width: 90,
                              height: 90,
                              color: AppTheme.background,
                              child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                      errorBuilder: (_, __, ___) => Container(
                        width: 90,
                        height: 90,
                        color: AppTheme.background,
                        child: const Icon(Icons.broken_image_outlined,
                            color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  final EkspedisiModel item;
  const _TimelineSection({required this.item});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

    final steps = <_TimelineStep>[
      _TimelineStep(
        icon: Icons.inbox_rounded,
        color: AppTheme.primary,
        title: 'Barang Diterima Receptionist',
        subtitle: item.diterimaOlehNama != null
            ? 'Oleh: ${item.diterimaOlehNama}'
            : null,
        time: fmt.format(item.createdAt.toLocal()),
        done: true,
      ),
      _TimelineStep(
        icon: Icons.security_rounded,
        color: AppTheme.statusDiambil,
        title: 'Diambil Security',
        subtitle: item.diambilSecurityNama != null
            ? 'Oleh: ${item.diambilSecurityNama}'
            : null,
        time: item.diambilPada != null
            ? fmt.format(item.diambilPada!.toLocal())
            : null,
        done: item.diambilPada != null,
      ),
      _TimelineStep(
        icon: Icons.local_shipping_rounded,
        color: AppTheme.statusPengiriman,
        title: 'Dalam Pengiriman ke Tujuan',
        subtitle: 'Departemen: ${item.departemenTujuan}',
        time: item.dikirimPada != null
            ? fmt.format(item.dikirimPada!.toLocal())
            : null,
        done: item.dikirimPada != null,
      ),
      _TimelineStep(
        icon: Icons.check_circle_rounded,
        color: AppTheme.success,
        title: 'Barang Diterima',
        subtitle: item.catatanPenerima,
        time: item.selesaiPada != null
            ? fmt.format(item.selesaiPada!.toLocal())
            : null,
        done: item.selesaiPada != null,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.timeline_rounded, size: 18, color: AppTheme.primary),
                SizedBox(width: 8),
                Text('Timeline Perjalanan',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary)),
              ],
            ),
            const Divider(height: 16),
            ...List.generate(steps.length, (i) => _TimelineTile(
              step: steps[i],
              isLast: i == steps.length - 1,
            )),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final String? time;
  final bool done;
  const _TimelineStep({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.time,
    required this.done,
  });
}

class _TimelineTile extends StatelessWidget {
  final _TimelineStep step;
  final bool isLast;
  const _TimelineTile({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Icon + line
          SizedBox(
            width: 40,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: step.done
                      ? step.color.withOpacity(0.15)
                      : AppTheme.background,
                  child: Icon(
                    step.icon,
                    size: 18,
                    color: step.done ? step.color : AppTheme.divider,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: step.done ? step.color.withOpacity(0.3) : AppTheme.divider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Right: content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: step.done ? AppTheme.textPrimary : AppTheme.textSecondary,
                    ),
                  ),
                  if (step.subtitle != null)
                    Text(step.subtitle!,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  if (step.time != null)
                    Text(step.time!,
                        style: TextStyle(
                            fontSize: 11,
                            color: step.color,
                            fontWeight: FontWeight.w500))
                  else
                    const Text('Belum',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(height: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
