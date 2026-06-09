// lib/presentation/screens/receptionist/input_barang_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';
import '../../providers/app_providers.dart';

class InputBarangScreen extends ConsumerStatefulWidget {
  const InputBarangScreen({super.key});

  @override
  ConsumerState<InputBarangScreen> createState() => _InputBarangScreenState();
}

class _InputBarangScreenState extends ConsumerState<InputBarangScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Controllers
  final _pengirimCtrl = TextEditingController();
  final _perusahaanCtrl = TextEditingController();
  final _telponCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _keteranganCtrl = TextEditingController();
  final _penerimaManualCtrl = TextEditingController();
  final _departemenCtrl = TextEditingController();

  // State
  LokasiModel? _selectedLokasi;
  KategoriModel? _selectedKategori;
  ProfileModel? _selectedPenerima;
  String _selectedSatuan = 'pcs';
  bool _penerimaManual = false;
  List<File> _fotoFiles = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _pengirimCtrl.dispose();
    _perusahaanCtrl.dispose();
    _telponCtrl.dispose();
    _deskripsiCtrl.dispose();
    _qtyCtrl.dispose();
    _keteranganCtrl.dispose();
    _penerimaManualCtrl.dispose();
    _departemenCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final status = source == ImageSource.camera
        ? await Permission.camera.request()
        : await Permission.photos.request();

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin kamera/galeri diperlukan')),
      );
      return;
    }

    final image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (image != null) {
      setState(() => _fotoFiles.add(File(image.path)));
    }
  }

  void _showImageSourceDialog() {
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
            const Text('Ambil Foto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                child: Icon(Icons.photo_library_rounded, color: Colors.white),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLokasi == null) {
      setState(() => _error = 'Pilih lokasi terlebih dahulu');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final repo = ref.read(repoProvider);

      // Upload foto
      List<String> fotoUrls = [];
      if (_fotoFiles.isNotEmpty) {
        fotoUrls = await repo.uploadMultipleFoto(_fotoFiles, folder: 'barang');
      }

      await repo.createEkspedisi(
        lokasiId: _selectedLokasi!.id,
        namaPengirim: _pengirimCtrl.text.trim(),
        perusahaanPengirim: _perusahaanCtrl.text.trim().isEmpty
            ? null
            : _perusahaanCtrl.text.trim(),
        noTeleponPengirim: _telponCtrl.text.trim().isEmpty
            ? null
            : _telponCtrl.text.trim(),
        kategoriId: _selectedKategori?.id,
        deskripsiBarang: _deskripsiCtrl.text.trim(),
        qty: int.tryParse(_qtyCtrl.text) ?? 1,
        satuan: _selectedSatuan,
        keterangan: _keteranganCtrl.text.trim().isEmpty
            ? null
            : _keteranganCtrl.text.trim(),
        penerimaId: _penerimaManual ? null : _selectedPenerima?.id,
        namaPenerimaManual: _penerimaManual
            ? _penerimaManualCtrl.text.trim()
            : null,
        departemenTujuan: _departemenCtrl.text.trim(),
        fotoUrls: fotoUrls,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Barang berhasil dicatat!'),
              ],
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        ref.invalidate(ekspedisiListProvider);
        ref.invalidate(statistikProvider);
        context.pop();
      }
    } catch (e) {
      setState(() => _error = 'Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lokasiAsync = ref.watch(lokasiListProvider);
    final kategoriAsync = ref.watch(kategoriListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Barang Masuk'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error Banner
              if (_error != null) ...[
                _ErrorBanner(message: _error!),
                const SizedBox(height: 12),
              ],

              // === SECTION 1: LOKASI ===
              _SectionCard(
                title: '📍 Lokasi Penerimaan',
                child: lokasiAsync.when(
                  data: (lokasi) => DropdownButtonFormField<LokasiModel>(
                    value: _selectedLokasi,
                    decoration: const InputDecoration(labelText: 'Pilih Lokasi/Cabang'),
                    items: lokasi.map((l) => DropdownMenuItem(
                      value: l,
                      child: Text('${l.kode} - ${l.nama}'),
                    )).toList(),
                    onChanged: (v) => setState(() {
                      _selectedLokasi = v;
                      _selectedPenerima = null;
                    }),
                    validator: (v) => v == null ? 'Pilih lokasi' : null,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                ),
              ),
              const SizedBox(height: 12),

              // === SECTION 2: PENGIRIM ===
              _SectionCard(
                title: '👤 Data Pengirim',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _pengirimCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Pengirim *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Nama pengirim wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _perusahaanCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Perusahaan / Instansi',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _telponCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'No. Telepon',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // === SECTION 3: BARANG ===
              _SectionCard(
                title: '📦 Detail Barang',
                child: Column(
                  children: [
                    // Kategori
                    kategoriAsync.when(
                      data: (kat) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kategori Barang',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: kat.map((k) => GestureDetector(
                              onTap: () => setState(() =>
                                  _selectedKategori = _selectedKategori?.id == k.id ? null : k),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _selectedKategori?.id == k.id
                                      ? AppTheme.primary
                                      : AppTheme.background,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _selectedKategori?.id == k.id
                                        ? AppTheme.primary
                                        : AppTheme.divider,
                                  ),
                                ),
                                child: Text(
                                  k.nama,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _selectedKategori?.id == k.id
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                    fontWeight: _selectedKategori?.id == k.id
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            )).toList(),
                          ),
                        ],
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 16),

                    // Deskripsi
                    TextFormField(
                      controller: _deskripsiCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi Barang *',
                        prefixIcon: Icon(Icons.description_outlined),
                        hintText: 'Contoh: Surat penawaran, Sample kain, dll',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Deskripsi wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),

                    // Qty + Satuan
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Qty *',
                              prefixIcon: Icon(Icons.numbers),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Wajib diisi';
                              if (int.tryParse(v) == null || int.parse(v) < 1) {
                                return 'Qty tidak valid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: _selectedSatuan,
                            decoration: const InputDecoration(labelText: 'Satuan'),
                            items: AppConstants.satuanList
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedSatuan = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Keterangan
                    TextFormField(
                      controller: _keteranganCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Keterangan Tambahan',
                        prefixIcon: Icon(Icons.notes_outlined),
                        hintText: 'Catatan khusus, kondisi barang, dll',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // === SECTION 4: TUJUAN ===
              _SectionCard(
                title: '🎯 Tujuan / Penerima',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _departemenCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Departemen Tujuan *',
                        prefixIcon: Icon(Icons.apartment_outlined),
                        hintText: 'Contoh: HRD, Produksi, Marketing',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Departemen wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // Toggle penerima
                    Row(
                      children: [
                        const Text('Mode Penerima:',
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: const Text('Dari Sistem'),
                          selected: !_penerimaManual,
                          onSelected: (_) => setState(() => _penerimaManual = false),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Manual'),
                          selected: _penerimaManual,
                          onSelected: (_) => setState(() => _penerimaManual = true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_penerimaManual)
                      TextFormField(
                        controller: _penerimaManualCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nama Penerima',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      )
                    else if (_selectedLokasi != null)
                      Consumer(
                        builder: (ctx, ref, _) {
                          final penerimaAsync = ref.watch(
                            penerimaListProvider(_selectedLokasi!.id),
                          );
                          return penerimaAsync.when(
                            data: (list) => DropdownButtonFormField<ProfileModel>(
                              value: _selectedPenerima,
                              decoration: const InputDecoration(
                                labelText: 'Pilih Penerima',
                                prefixIcon: Icon(Icons.person_search_outlined),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('-- Tidak dipilih --',
                                      style: TextStyle(color: AppTheme.textSecondary)),
                                ),
                                ...list.map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(p.namaLengkap, style: const TextStyle(fontSize: 14)),
                                      Text(p.departemen ?? p.roleDisplay,
                                          style: const TextStyle(
                                              fontSize: 11, color: AppTheme.textSecondary)),
                                    ],
                                  ),
                                )),
                              ],
                              onChanged: (v) => setState(() => _selectedPenerima = v),
                            ),
                            loading: () => const LinearProgressIndicator(),
                            error: (e, _) => Text('Error: $e'),
                          );
                        },
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondary),
                            SizedBox(width: 8),
                            Text('Pilih lokasi terlebih dahulu',
                                style: TextStyle(
                                    fontSize: 13, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // === SECTION 5: FOTO ===
              _SectionCard(
                title: '📸 Foto Barang',
                child: Column(
                  children: [
                    // Grid foto
                    if (_fotoFiles.isNotEmpty) ...[
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _fotoFiles.length,
                        itemBuilder: (ctx, i) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _fotoFiles[i],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _fotoFiles.removeAt(i)),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Add button
                    OutlinedButton.icon(
                      onPressed: _showImageSourceDialog,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(_fotoFiles.isEmpty
                          ? 'Tambah Foto Barang'
                          : 'Tambah Foto Lagi (${_fotoFiles.length} foto)'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_loading ? 'Menyimpan...' : 'Simpan Data Barang'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            child,
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
          Expanded(child: Text(message, style: const TextStyle(color: AppTheme.error))),
        ],
      ),
    );
  }
}
