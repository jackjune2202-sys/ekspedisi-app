// lib/presentation/screens/report/laporan_screen.dart
import 'dart:io';
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

  @override
  Widget build(BuildContext context) {
    final ekspedisiAsync = ref.watch(
      FutureProvider.autoDispose<List<EkspedisiModel>>((ref) {
        return ref.read(repoProvider).getEkspedisi(
          dari: DateTime(_dari.year, _dari.month, _dari.day),
          sampai: DateTime(_sampai.year, _sampai.month, _sampai.day, 23, 59),
          status: _filterStatus,
          limit: 500,
        );
      }),
    );

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
              onPressed: () => ekspedisiAsync.whenData(
                (list) => _exportPdf(list),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Date range
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
                          if (d != null) setState(() => _dari = d);
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
                            lastDate: DateTime.now().add(const Duration(days: 1)),
                          );
                          if (d != null) setState(() => _sampai = d);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Status filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Status: ',
                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      const SizedBox(width: 4),
                      ...['', 'menunggu', 'diambil_security', 'dalam_pengiriman', 'diterima', 'dikembalikan']
                          .map((s) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(s.isEmpty ? 'Semua' : AppTheme.statusLabel(s),
                                      style: const TextStyle(fontSize: 12)),
                                  selected: _filterStatus == (s.isEmpty ? null : s),
                                  onSelected: (_) => setState(() =>
                                      _filterStatus = s.isEmpty ? null : s),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: ekspedisiAsync.when(
              data: (list) => Column(
                children: [
                  // Summary row
                  _SummaryRow(list: list),
                  const Divider(height: 1),

                  // List
                  Expanded(
                    child: list.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off_rounded,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('Tidak ada data di periode ini'),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (ctx, i) => _LaporanRow(item: list[i]),
                          ),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generatingPdf
            ? null
            : () => ekspedisiAsync.whenData((list) => _exportPdf(list)),
        icon: const Icon(Icons.download_rounded),
        label: const Text('Export PDF'),
        backgroundColor: _generatingPdf ? Colors.grey : AppTheme.primary,
      ),
    );
  }

  Future<void> _exportPdf(List<EkspedisiModel> list) async {
    setState(() => _generatingPdf = true);
    try {
      final pdfBytes = await _generatePdf(list);
      final dir = await getApplicationDocumentsDirectory();
      final now = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final file = File('${dir.path}/laporan_ekspedisi_$now.pdf');
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('PDF tersimpan: ${file.path}')),
            ]),
            backgroundColor: AppTheme.success,
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
    final fmtFull = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

    // Count per status
    int total = list.length;
    int diterima = list.where((e) => e.status == 'diterima').length;
    int menunggu = list.where((e) => e.status == 'menunggu').length;
    int proses = list.where((e) =>
        e.status == 'diambil_security' || e.status == 'dalam_pengiriman').length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
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
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#1565C0'))),
                    pw.Text(
                        'Periode: ${fmt.format(_dari)} s/d ${fmt.format(_sampai)}',
                        style: const pw.TextStyle(fontSize: 11)),
                    pw.Text(
                        'Dicetak: ${fmtFull.format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
            pw.Divider(color: PdfColor.fromHex('#1565C0'), thickness: 1.5),
            pw.SizedBox(height: 8),

            // Summary
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _pdfStat('Total', '$total', PdfColors.blue700),
                _pdfStat('Diterima', '$diterima', PdfColors.green700),
                _pdfStat('Dalam Proses', '$proses', PdfColors.orange700),
                _pdfStat('Menunggu', '$menunggu', PdfColors.amber700),
              ],
            ),
            pw.SizedBox(height: 12),
          ],
        ),
        build: (context) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.5),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(3),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(2),
              5: const pw.FlexColumnWidth(2),
            },
            children: [
              // Header
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColor.fromHex('#1565C0')),
                children: [
                  'No. Ekspedisi', 'Tanggal', 'Deskripsi Barang',
                  'Pengirim', 'Tujuan', 'Status',
                ].map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: pw.Text(h,
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white)),
                )).toList(),
              ),

              // Data rows
              ...list.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                final bg = i.isEven ? PdfColors.white : PdfColor.fromHex('#F5F7FA');
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bg),
                  children: [
                    e.nomorEkspedisi,
                    fmt.format(e.createdAt.toLocal()),
                    '${e.deskripsiBarang} (${e.qty} ${e.satuan})',
                    e.namaPengirim + (e.perusahaanPengirim != null ? '\n${e.perusahaanPengirim}' : ''),
                    e.departemenTujuan,
                    AppTheme.statusLabel(e.status),
                  ].map((text) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: pw.Text(text,
                        style: const pw.TextStyle(fontSize: 8)),
                  )).toList(),
                );
              }),
            ],
          ),
        ],
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Buku Ekspedisi — Laporan Resmi',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.Text('Halaman ${context.pageNumber} / ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfStat(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      ],
    );
  }
}

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        fontSize: 10, color: AppTheme.textSecondary)),
                Text(date,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MiniStat('Total', '${list.length}', AppTheme.primary),
          _MiniStat('Diterima', '${counts['diterima'] ?? 0}', AppTheme.success),
          _MiniStat('Proses', '${(counts['diambil_security'] ?? 0) + (counts['dalam_pengiriman'] ?? 0)}', AppTheme.statusPengiriman),
          _MiniStat('Menunggu', '${counts['menunggu'] ?? 0}', AppTheme.statusMenunggu),
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
    final statusColor = AppTheme.statusColor(item.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(item.nomorEkspedisi,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
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
                const SizedBox(height: 3),
                Text(
                  '${item.deskripsiBarang} • ${item.qty} ${item.satuan}',
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(item.namaPengirim,
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary)),
                    const Text(' → ',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary)),
                    Text(item.departemenTujuan,
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary)),
                    const Spacer(),
                    Text(fmt.format(item.createdAt.toLocal()),
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
