// lib/presentation/screens/security/konfirmasi_terima_screen.dart
// Screen khusus konfirmasi terima dengan tanda tangan digital
// Dipanggil dari ambil_barang_screen.dart saat status 'dalam_pengiriman'

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../presentation/providers/app_providers.dart';
import '../../../presentation/widgets/signature_pad.dart';

class KonfirmasiTerimaSection extends ConsumerStatefulWidget {
  final EkspedisiModel item;
  final VoidCallback onSelesai;

  const KonfirmasiTerimaSection({
    super.key,
    required this.item,
    required this.onSelesai,
  });

  @override
  ConsumerState<KonfirmasiTerimaSection> createState() =>
      _KonfirmasiTerimaSectionState();
}

class _KonfirmasiTerimaSectionState
    extends ConsumerState<KonfirmasiTerimaSection> {
  final _catatanCtrl = TextEditingController();
  final _picker = ImagePicker();

  List<File> _fotoBuktiFiles = [];
  Uint8List? _signatureBytes;
  bool _loading = false;
  bool _pakaiTandaTangan = true; // toggle foto vs tanda tangan
  String? _error;

  @override
  void dispose() {
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
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
      setState(() => _fotoBuktiFiles.add(File(image.path)));
    }
  }

  void _showImageSheet() {
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
            const Text('Foto Bukti Terima',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primary,
                child: Icon(Icons.camera_alt_rounded, color: Colors.white),
              ),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.accent,
                child:
                    Icon(Icons.photo_library_rounded, color: Colors.white),
              ),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _konfirmasi() async {
    // Validasi
    if (_pakaiTandaTangan && _signatureBytes == null) {
      setState(() => _error = 'Tanda tangan wajib diisi');
      return;
    }
    if (!_pakaiTandaTangan && _fotoBuktiFiles.isEmpty) {
      setState(() => _error = 'Foto bukti wajib diambil');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(repoProvider);

      // Upload foto bukti jika ada
      List<String> fotoBuktiUrls = [];
      if (_fotoBuktiFiles.isNotEmpty) {
        fotoBuktiUrls = await repo.uploadMultipleFoto(
          _fotoBuktiFiles,
          folder: 'bukti',
        );
      }

      // Convert signature ke base64 string jika ada
      String? tandaTanganBase64;
      if (_signatureBytes != null) {
        tandaTanganBase64 = base64Encode(_signatureBytes!);
      }

      await repo.konfirmasiDiterima(
        ekspedisiId: widget.item.id,
        fotoBukti: fotoBuktiUrls,
        catatan: _catatanCtrl.text.trim().isEmpty
            ? null
            : _catatanCtrl.text.trim(),
        tandaTangan: tandaTanganBase64,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Barang berhasil dikonfirmasi diterima!'),
            ]),
            backgroundColor: AppTheme.success,
          ),
        );
        widget.onSelesai();
      }
    } catch (e) {
      setState(() => _error = 'Gagal: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '✅ Konfirmasi Diterima',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pilih cara validasi penerimaan barang.',
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),

            // Toggle foto vs tanda tangan
            Container(
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.divider),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _pakaiTandaTangan = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_pakaiTandaTangan
                              ? AppTheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_camera_rounded,
                              size: 16,
                              color: !_pakaiTandaTangan
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Foto Bukti',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: !_pakaiTandaTangan
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _pakaiTandaTangan = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _pakaiTandaTangan
                              ? AppTheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.draw_rounded,
                              size: 16,
                              color: _pakaiTandaTangan
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Tanda Tangan',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _pakaiTandaTangan
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Konten berdasarkan toggle
            if (_pakaiTandaTangan) ...[
              const Text(
                'Tanda Tangan Penerima',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              SignaturePad(
                height: 180,
                onSigned: (bytes) {
                  setState(() => _signatureBytes = bytes);
                },
              ),
            ] else ...[
              // Grid foto bukti
              if (_fotoBuktiFiles.isNotEmpty) ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _fotoBuktiFiles.length,
                  itemBuilder: (ctx, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _fotoBuktiFiles[i],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(
                              () => _fotoBuktiFiles.removeAt(i)),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              OutlinedButton.icon(
                onPressed: _showImageSheet,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(_fotoBuktiFiles.isEmpty
                    ? 'Ambil Foto Bukti'
                    : 'Tambah (${_fotoBuktiFiles.length} foto)'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Catatan
            TextField(
              controller: _catatanCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan Penerima (opsional)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),

            // Error
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style:
                              const TextStyle(color: AppTheme.error)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Tombol konfirmasi
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _konfirmasi,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_rounded),
                label: Text(
                    _loading ? 'Menyimpan...' : 'Konfirmasi Sudah Diterima'),
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
