// lib/presentation/screens/report/laporan_screen.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../providers/app_providers.dart';

class LaporanScreen extends ConsumerStatefulWidget {
  const LaporanScreen({super.key});

  @override
  ConsumerState<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends ConsumerState<LaporanScreen> {
  DateTime _dari = DateTime.now().subtract(const Duration(days: 30));
  DateTime _sampai = DateTime.now();
  String? _filterStatus;
  bool _generatingPdf = false;
  List<EkspedisiModel> _data = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(repoProvider);
      final result = await repo.getEkspedisi(
        dari: DateTime(_dari.year, _dari.month, _dari.day),
        sampai: DateTime(_sampai.year, _sampai.month, _sampai.day, 23, 59, 59),
        status: _filterStatus,
        limit: 500,
      );
      if (mounted) {
        setState(() {
          _data = result;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Ekspedisi'),
        actions: [
          if (_generatingPdf)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              tooltip: 'Export PDF',
              onPressed: _data.isEmpty ? null : () => _exportPdf(_data),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _DateButton(
                        label: 'Dari',
                        date: fmt.format(_dari),
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _dari,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (d != null) {
                            setState(() => _dari = d);
                            _fetchData();
                          }
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 18, color: AppTheme.textSecondary),
                    ),
                    Expanded(
                      child: _DateButton(
                        label: 'Sampai',
                        date: fmt.format(_sampai),
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _sampai,
                            firstDate: DateTime(2020),
                            lastDate:
                                DateTime.now().add(const Duration(days: 1)),
                          );
                          if (d != null) {
                            setState(() => _sampai = d);
                            _fetchData();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Status: ',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary)),
                      const SizedBox(width: 4),
                      ...[
                        '',
                        'menunggu',
                        'diambil_security',
                        'dalam_pengiriman',
                        'diterima',
                        'dikembalikan'
                      ].map((s) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(
                                  s.isEmpty
                                      ? 'Semua'
                                      : AppTheme.statusLabel(s),
                                  style: const TextStyle(fontSize: 12)),
                              selected:
                                  _filterStatus == (s.isEmpty ? null : s),
                              onSelected: (_) {
                                setState(() => _filterStatus =
                                    s.isEmpty ? null : s);
                                _fetchData();
                              },
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: AppTheme.error),
                            const SizedBox(height: 12),
                            Text('Error: $_error'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _fetchData,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          _SummaryRow(list: _data),
                          const Divider(height: 1),
                          Expanded(
                            child: _data.isEmpty
                                ? const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.search_off_rounded,
                                            size: 64,
                                            color: Colors.grey),
                                        SizedBox(height: 12),
                                        Text(
                                            'Tidak ada data di periode ini'),
                                      ],
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _fetchData,
                                    child: ListView.separated(
                                      padding: const EdgeInsets.all(12),
                                      itemCount: _data.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 6),
                                      itemBuilder: (ctx, i) =>
                                          _LaporanRow(item: _data[i]),
                                    ),
                                  ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            _generatingPdf || _loading || _data.isEmpty
                ? null
                : () => _exportPdf(_data),
        icon: const Icon(Icons.download_rounded),
        label: const Text('Export PDF'),
        backgroundColor:
            _generatingPdf || _loading || _data.isEmpty
                ? Colors.grey
                : AppTheme.primary,
      ),
    );
  }

  Future<void> _exportPdf(List<EkspedisiModel> list) async {
    setState(() => _generatingPdf = true);
    try {
      final pdfBytes = await _generatePdf(list);

      Directory dir;
      if (Platform.isAndroid) {
        final dlDir = Directory('/storage/emulated/0/Download');
        if (await dlDir.exists()) {
          dir = dlDir;
        } else {
          dir = await getApplicationDocumentsDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final now = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final file = File('${dir.path}/laporan_ekspedisi_$now.pdf');
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('PDF disimpan di folder Downloads')),
            ]),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Buka',
              textColor: Colors.white,
              onPressed: () => OpenFile.open(file.path),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export PDF: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  Future<List<int>> _generatePdf(List<EkspedisiModel> list) async {
    final pdf = pw.Document();
    final fmt = DateFormat('dd MMM yyyy', 'id_ID');
    final fmtFull = DateFormat('dd MMM yyyy HH:mm', 'id_ID');

    final int total = list.length;
    final int diterima = list.where((e) => e.status == 'diterima').length;
    final int menunggu = list.where((e) => e.status == 'menunggu').length;
    final int proses = list
        .where((e) =>
            e.status == 'diambil_security' ||
            e.status == 'dalam_pengiriman')
        .length;

    // Build rows — satu row per ekspedisi, baris tambahan untuk foto/ttd
    final List<pw.Widget> contentWidgets = [];

    // Header tabel
    contentWidgets.add(
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        columnWidths: {
          0: const pw.FixedColumnWidth(55),  // No Exp
          1: const pw.FixedColumnWidth(45),  // Tanggal
          2: const pw.FlexColumnWidth(2),    // Deskripsi
          3: const pw.FlexColumnWidth(1.5),  // Pengirim
          4: const pw.FlexColumnWidth(1.5),  // Tujuan
          5: const pw.FlexColumnWidth(1.5),  // Penerima
          6: const pw.FixedColumnWidth(40),  // Status
          7: const pw.FixedColumnWidth(45),  // Tgl Terima
        },
        children: [
          // Header row
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColor.fromHex('#1565C0')),
            children: [
              'No. Ekspedisi',
              'Tanggal',
              'Deskripsi Barang',
              'Pengirim',
              'Tujuan / Dept.',
              'Nama Penerima',
              'Status',
              'Tgl. Diterima',
            ]
                .map((h) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 4, vertical: 5),
                      child: pw.Text(h,
                          style: pw.TextStyle(
                              fontSize: 7,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                    ))
                .toList(),
          ),

          // Data rows
          ...list.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final bg =
                i.isEven ? PdfColors.white : PdfColor.fromHex('#F5F7FA');

            final namaPenerima = e.namaPenerimaManual ??
                e.diterimaOlehNama ??
                '-';

            final tglTerima = e.selesaiPada != null
                ? fmt.format(e.selesaiPada!.toLocal())
                : (e.status == 'diterima' ? 'Sudah diterima' : '-');

            return pw.TableRow(
              decoration: pw.BoxDecoration(color: bg),
              children: [
                e.nomorEkspedisi,
                fmt.format(e.createdAt.toLocal()),
                '${e.deskripsiBarang}\n${e.qty} ${e.satuan}' +
                    (e.kategoriNama != null ? ' (${e.kategoriNama})' : ''),
                e.namaPengirim +
                    (e.perusahaanPengirim != null
                        ? '\n${e.perusahaanPengirim}'
                        : ''),
                e.departemenTujuan,
                namaPenerima,
                AppTheme.statusLabel(e.status),
                tglTerima,
              ]
                  .map((text) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        child: pw.Text(text,
                            style: const pw.TextStyle(fontSize: 7)),
                      ))
                  .toList(),
            );
          }),
        ],
      ),
    );

    // Bukti per item (foto atau tanda tangan)
    contentWidgets.add(pw.SizedBox(height: 16));
    contentWidgets.add(
      pw.Text('BUKTI PENERIMAAN',
          style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1565C0'))),
    );
    contentWidgets.add(pw.Divider(color: PdfColor.fromHex('#1565C0')));
    contentWidgets.add(pw.SizedBox(height: 8));

    // Grid bukti - 2 per baris
    final diterimaList = list.where((e) => e.status == 'diterima').toList();

    if (diterimaList.isEmpty) {
      contentWidgets.add(
        pw.Text('Belum ada barang yang diterima di periode ini.',
            style: const pw.TextStyle(
                fontSize: 9, color: PdfColors.grey600)),
      );
    } else {
      for (int i = 0; i < diterimaList.length; i += 2) {
        final rowItems = diterimaList.sublist(
            i, i + 2 > diterimaList.length ? diterimaList.length : i + 2);

        contentWidgets.add(
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: rowItems.map((e) {
              final namaPenerima =
                  e.namaPenerimaManual ?? e.diterimaOlehNama ?? '-';
              final tglTerima = e.selesaiPada != null
                  ? fmtFull.format(e.selesaiPada!.toLocal())
                  : '-';

              // Coba decode tanda tangan
              pw.Widget? buktiWidget;

              if (e.tandaTanganPenerima != null &&
                  e.tandaTanganPenerima!.isNotEmpty) {
                try {
                  final bytes = base64Decode(e.tandaTanganPenerima!);
                  final img = pw.MemoryImage(bytes);
                  buktiWidget = pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Tanda Tangan:',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey700)),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        width: 120,
                        height: 60,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                              color: PdfColors.grey400, width: 0.5),
                        ),
                        child: pw.Image(img, fit: pw.BoxFit.contain),
                      ),
                    ],
                  );
                } catch (_) {
                  buktiWidget = pw.Text('Tanda tangan tersimpan',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey600));
                }
              } else if (e.fotoBuktiTerimaUrls.isNotEmpty) {
                buktiWidget = pw.Text(
                    'Foto bukti: ${e.fotoBuktiTerimaUrls.length} foto\n(lihat di aplikasi)',
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey600));
              } else {
                buktiWidget = pw.Text('Tidak ada bukti',
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey400));
              }

              return pw.Expanded(
                child: pw.Container(
                  margin: const pw.EdgeInsets.only(right: 8, bottom: 12),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                        color: PdfColors.grey300, width: 0.5),
                    borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(e.nomorEkspedisi,
                          style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#1565C0'))),
                      pw.SizedBox(height: 2),
                      pw.Text(e.deskripsiBarang,
                          style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Penerima: $namaPenerima',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey700)),
                      pw.Text('Diterima: $tglTerima',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey700)),
                      pw.SizedBox(height: 6),
                      buktiWidget,
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('LAPORAN BUKU EKSPEDISI',
                        style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#1565C0'))),
                    pw.Text(
                        'Periode: ${fmt.format(_dari)} s/d ${fmt.format(_sampai)}',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                        'Dicetak: ${fmtFull.format(DateTime.now())}',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _pdfStatBox('Total', '$total', PdfColors.blue700),
                    pw.SizedBox(height: 4),
                    _pdfStatBox('Diterima', '$diterima', PdfColors.green700),
                  ],
                ),
              ],
            ),
            pw.Divider(
                color: PdfColor.fromHex('#1565C0'), thickness: 1.5),
            pw.SizedBox(height: 4),
          ],
        ),
        build: (context) => contentWidgets,
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Buku Ekspedisi — Laporan Resmi',
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.grey600)),
            pw.Text(
                'Halaman ${context.pageNumber} / ${context.pagesCount}',
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfStatBox(String label, String value, PdfColor color) {
    return pw.Row(
      children: [
        pw.Text('$label: ',
            style: const pw.TextStyle(
                fontSize: 9, color: PdfColors.grey700)),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: color)),
      ],
    );
  }
}

// ==================== WIDGETS ====================

class _DateButton extends StatelessWidget {
  final String label;
  final String date;
  final VoidCallback onTap;
  const _DateButton(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.divider),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: AppTheme.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary)),
                Text(date,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final List<EkspedisiModel> list;
  const _SummaryRow({required this.list});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final e in list) {
      counts[e.status] = (counts[e.status] ?? 0) + 1;
    }
    return Container(
      color: Colors.white,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MiniStat('Total', '${list.length}', AppTheme.primary),
          _MiniStat('Diterima', '${counts['diterima'] ?? 0}',
              AppTheme.success),
          _MiniStat(
              'Proses',
              '${(counts['diambil_security'] ?? 0) + (counts['dalam_pengiriman'] ?? 0)}',
              AppTheme.statusPengiriman),
          _MiniStat('Menunggu', '${counts['menunggu'] ?? 0}',
              AppTheme.statusMenunggu),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _LaporanRow extends StatelessWidget {
  final EkspedisiModel item;
  const _LaporanRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yy HH:mm', 'id_ID');
    final fmtDate = DateFormat('dd/MM/yy', 'id_ID');
    final statusColor = AppTheme.statusColor(item.status);
    final namaPenerima =
        item.namaPenerimaManual ?? item.diterimaOlehNama ?? '-';

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: nomor + status
          Row(
            children: [
              Expanded(
                child: Text(item.nomorEkspedisi,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(AppTheme.statusLabel(item.status),
                    style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 2: detail
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kiri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoItem(Icons.inventory_2_outlined,
                        '${item.deskripsiBarang} (${item.qty} ${item.satuan})'),
                    _InfoItem(Icons.person_outline, item.namaPengirim +
                        (item.perusahaanPengirim != null
                            ? ' — ${item.perusahaanPengirim}'
                            : '')),
                    _InfoItem(Icons.apartment_outlined,
                        item.departemenTujuan),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Kanan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoItem(Icons.how_to_reg_outlined,
                        'Penerima: $namaPenerima'),
                    _InfoItem(Icons.access_time,
                        'Input: ${fmt.format(item.createdAt.toLocal())}'),
                    if (item.selesaiPada != null)
                      _InfoItem(Icons.check_circle_outline,
                          'Diterima: ${fmtDate.format(item.selesaiPada!.toLocal())}',
                          color: AppTheme.success),
                    // Indikator bukti
                    Row(
                      children: [
                        if (item.tandaTanganPenerima != null)
                          _BuktiChip(Icons.draw_rounded, 'TTD', Colors.purple),
                        if (item.fotoBuktiTerimaUrls.isNotEmpty)
                          _BuktiChip(Icons.photo_camera_rounded,
                              '${item.fotoBuktiTerimaUrls.length} foto',
                              Colors.teal),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _InfoItem(this.icon, this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 13,
              color: color ?? AppTheme.textSecondary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12,
                    color: color ?? AppTheme.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _BuktiChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _BuktiChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
