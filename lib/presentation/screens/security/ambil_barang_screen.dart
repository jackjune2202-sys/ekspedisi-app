// lib/presentation/screens/security/ambil_barang_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../providers/app_providers.dart';

class AmbilBarangScreen extends ConsumerStatefulWidget {
  final String ekspedisiId;
  const AmbilBarangScreen({super.key, required this.ekspedisiId});

  @override
  ConsumerState<AmbilBarangScreen> createState() => _AmbilBarangScreenState();
}

class _AmbilBarangScreenState extends ConsumerState<AmbilBarangScreen> {
  final _catatanCtrl = TextEditingController();
  final _catatanTerimaCtrl = TextEditingController();
  final _picker = ImagePicker();
  List<File> _fotoFiles = [];
  bool _loading = false;
  String? _error;

  // Untuk konfirmasi terima
  List<File> _fotoBuktiFiles = [];

  @override
  void dispose() {
    _catatanCtrl.dispose();
    _catatanTerimaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, bool isBukti) async {
    final status = source == ImageSource.camera
        ? await Permission.camera.request()
        : await Permission.photos.request();

    if (!status.isGranted) return;

    final image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (image != null) {
      setState(() {
        if (isBukti) {
          _fotoBuktiFiles.add(File(image.path));
        } else {
          _fotoFiles.add(File(image.path));
        }
      });
    }
  }

  void _showImageSheet(bool isBukti) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isBukti ? 'Foto Bukti Terima' : 'Foto Barang Diambil',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primary,
                child: Icon(Icons.camera_alt_rounded, color: Colors.white),
              ),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera, isBukti);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.accent,
                child: Icon(Icons.photo_library_rounded, color: Colors.white),
              ),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery, isBukti);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ambilBarang(EkspedisiModel item) async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = ref.read(repoProvider);
      List<String> fotoUrls = [];
      if (_fotoFiles.isNotEmpty) {
        fotoUrls = await repo.uploadMultipleFoto(_fotoFiles, folder: 'security');
      }
      await repo.ambilBarang(
        ekspedisiId: item.id,
        fotoUrls: fotoUrls,
        catatan: _catatanCtrl.text.trim().isEmpty ? null : _catatanCtrl.text.trim(),
      );
      _invalidateAll();
      if (mounted) {
        _showSuccessSnack('Barang berhasil diambil!');
        context.pop();
      }
    } catch (e) {
      setState(() => _error = 'Gagal: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _kirimBarang(EkspedisiModel item) async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = ref.read(repoProvider);
      await repo.kirimBarang(ekspedisiId: item.id);
      _invalidateAll();
      if (mounted) {
        _showSuccessSnack('Status diperbarui: Dalam Pengiriman');
        context.pop();
      }
    } catch (e) {
      setState(() => _error = 'Gagal: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _konfirmasiTerima(EkspedisiModel item) async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = ref.read(repoProvider);
      List<String> fotoBuktiUrls = [];
      if (_fotoBuktiFiles.isNotEmpty) {
        fotoBuktiUrls = await repo.uploadMultipleFoto(_fotoBuktiFiles, folder: 'bukti');
      }
      await repo.konfirmasiDiterima(
        ekspedisiId: item.id,
        fotoBukti: fotoBuktiUrls,
        catatan: _catatanTerimaCtrl.text.trim().isEmpty
            ? null
            : _catatanTerimaCtrl.text.trim(),
      );
      _invalidateAll();
      if (mounted) {
        _showSuccessSnack('✅ Barang berhasil diterima!');
        context.pop();
      }
    } catch (e) {
      setState(() => _error = 'Gagal: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _invalidateAll() {
    ref.invalidate(ekspedisiMenungguProvider);
    ref.invalidate(ekspedisiDalamPengirimanProvider);
    ref.invalidate(ekspedisiListProvider);
    ref.invalidate(statistikProvider);
  }

  void _showSuccessSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Text(msg),
        ]),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ekspedisiAsync = FutureProvider.autoDispose<EkspedisiModel>((ref) =>
        ref.read(repoProvider).getEkspedisiById(widget.ekspedisiId));

    return Consumer(
      builder: (ctx, ref2, _) {
        final dataAsync = ref2.watch(ekspedisiAsync);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Proses Barang'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: dataAsync.when(
            data: (item) => _buildBody(item),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        );
      },
    );
  }

  Widget _buildBody(EkspedisiModel item) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error
          if (_error != null) ...[
            _ErrorBanner(message: _error!),
            const SizedBox(height: 12),
          ],

          // Info Card
          _InfoCard(item: item),
          const SizedBox(height: 16),

          // Foto dari receptionist
          if (item.fotoBarangUrls.isNotEmpty) ...[
            _FotoSection(
              title: '📷 Foto dari Receptionist',
              urls: item.fotoBarangUrls,
            ),
            const SizedBox(height: 16),
          ],

          // Action berdasarkan status
          if (item.status == 'menunggu') ...[
            _AmbilSection(
              fotoFiles: _fotoFiles,
              catatanCtrl: _catatanCtrl,
              onAddFoto: () => _showImageSheet(false),
              onRemoveFoto: (i) => setState(() => _fotoFiles.removeAt(i)),
              onAmbil: _loading ? null : () => _ambilBarang(item),
              loading: _loading,
            ),
          ] else if (item.status == 'diambil_security') ...[
            _KirimSection(
              item: item,
              onKirim: _loading ? null : () => _kirimBarang(item),
              loading: _loading,
            ),
          ] else if (item.status == 'dalam_pengiriman') ...[
            _KonfirmasiTerimaSection(
              fotoBuktiFiles: _fotoBuktiFiles,
              catatanCtrl: _catatanTerimaCtrl,
              onAddFoto: () => _showImageSheet(true),
              onRemoveFoto: (i) => setState(() => _fotoBuktiFiles.removeAt(i)),
              onKonfirmasi: _loading ? null : () => _konfirmasiTerima(item),
              loading: _loading,
            ),
          ] else ...[
            _SelesaiCard(item: item),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ==================== WIDGETS ====================

class _InfoCard extends StatelessWidget {
  final EkspedisiModel item;
  const _InfoCard({required this.item});

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
                Expanded(
                  child: Text(
                    item.nomorEkspedisi,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                _StatusPill(status: item.status),
              ],
            ),
            const Divider(height: 20),
            _Row(Icons.inventory_2_outlined, 'Barang',
                '${item.deskripsiBarang}\n${item.qty} ${item.satuan}' +
                    (item.kategoriNama != null ? ' • ${item.kategoriNama}' : '')),
            const SizedBox(height: 8),
            _Row(Icons.person_outline, 'Pengirim',
                item.namaPengirim +
                    (item.perusahaanPengirim != null
                        ? '\n${item.perusahaanPengirim}'
                        : '')),
            const SizedBox(height: 8),
            _Row(Icons.apartment_outlined, 'Tujuan', item.departemenTujuan),
            if (item.keterangan != null) ...[
              const SizedBox(height: 8),
              _Row(Icons.notes_outlined, 'Ket.', item.keterangan!),
            ],
            const SizedBox(height: 8),
            _Row(
              Icons.access_time,
              'Diterima',
              DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                  .format(item.createdAt.toLocal()),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
        ),
        const Text(': ',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        AppTheme.statusLabel(status),
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

class _FotoSection extends StatelessWidget {
  final String title;
  final List<String> urls;
  const _FotoSection({required this.title, required this.urls});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary)),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: urls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) => GestureDetector(
                  onTap: () => _showFullImage(ctx, urls[i]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      urls[i],
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
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

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _FotoGridLocal extends StatelessWidget {
  final List<File> files;
  final void Function(int) onRemove;
  final VoidCallback onAdd;
  const _FotoGridLocal({
    required this.files,
    required this.onRemove,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (files.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: files.length,
            itemBuilder: (ctx, i) => Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(files[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => onRemove(i),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(files.isEmpty
              ? 'Ambil Foto'
              : 'Tambah (${files.length} foto)'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
          ),
        ),
      ],
    );
  }
}

class _AmbilSection extends StatelessWidget {
  final List<File> fotoFiles;
  final TextEditingController catatanCtrl;
  final VoidCallback onAddFoto;
  final void Function(int) onRemoveFoto;
  final VoidCallback? onAmbil;
  final bool loading;
  const _AmbilSection({
    required this.fotoFiles,
    required this.catatanCtrl,
    required this.onAddFoto,
    required this.onRemoveFoto,
    required this.onAmbil,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🛡️ Ambil Barang',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary)),
            const SizedBox(height: 4),
            const Text(
              'Foto barang sebelum dibawa, lalu tekan Ambil Barang untuk memperbarui status.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            _FotoGridLocal(
                files: fotoFiles, onRemove: onRemoveFoto, onAdd: onAddFoto),
            const SizedBox(height: 14),
            TextField(
              controller: catatanCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan Security (opsional)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAmbil,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.shopping_bag_outlined),
                label: Text(loading ? 'Memproses...' : 'Ambil Barang'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KirimSection extends StatelessWidget {
  final EkspedisiModel item;
  final VoidCallback? onKirim;
  final bool loading;
  const _KirimSection({
    required this.item,
    required this.onKirim,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🚶 Antar ke Tujuan',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warning)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      color: AppTheme.warning, size: 22),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Antar ke:',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                      Text(
                        item.departemenTujuan,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (item.namaPenerimaManual != null)
                        Text('u.p. ${item.namaPenerimaManual}',
                            style: const TextStyle(
                                fontSize: 13, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onKirim,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.local_shipping_rounded),
                label: Text(loading ? 'Memproses...' : 'Tandai Sedang Diantar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppTheme.warning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KonfirmasiTerimaSection extends StatelessWidget {
  final List<File> fotoBuktiFiles;
  final TextEditingController catatanCtrl;
  final VoidCallback onAddFoto;
  final void Function(int) onRemoveFoto;
  final VoidCallback? onKonfirmasi;
  final bool loading;
  const _KonfirmasiTerimaSection({
    required this.fotoBuktiFiles,
    required this.catatanCtrl,
    required this.onAddFoto,
    required this.onRemoveFoto,
    required this.onKonfirmasi,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('✅ Konfirmasi Diterima',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.success)),
            const SizedBox(height: 4),
            const Text(
              'Foto bukti penyerahan barang ke penerima, lalu konfirmasi.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            _FotoGridLocal(
                files: fotoBuktiFiles,
                onRemove: onRemoveFoto,
                onAdd: onAddFoto),
            const SizedBox(height: 14),
            TextField(
              controller: catatanCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan Penerima (opsional)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onKonfirmasi,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_rounded),
                label: Text(loading ? 'Menyimpan...' : 'Konfirmasi Sudah Diterima'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppTheme.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelesaiCard extends StatelessWidget {
  final EkspedisiModel item;
  const _SelesaiCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final selesai = item.selesaiPada != null
        ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
            .format(item.selesaiPada!.toLocal())
        : '-';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppTheme.success, size: 56),
            const SizedBox(height: 12),
            const Text('Barang Sudah Diterima',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.success)),
            const SizedBox(height: 4),
            Text('Pada: $selesai',
                style: const TextStyle(color: AppTheme.textSecondary)),
            if (item.catatanPenerima != null) ...[
              const SizedBox(height: 8),
              Text('Catatan: ${item.catatanPenerima}',
                  style: const TextStyle(fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: const TextStyle(color: AppTheme.error))),
        ],
      ),
    );
  }
}
