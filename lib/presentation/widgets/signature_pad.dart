// Tambahkan package ini di pubspec.yaml:
// signature: ^5.4.0

// lib/presentation/screens/security/ambil_barang_screen.dart
// Ganti bagian _KonfirmasiTerimaSection dengan versi baru yang ada signature pad

// =============================================
// FILE BARU: lib/presentation/widgets/signature_pad.dart
// =============================================

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SignaturePad extends StatefulWidget {
  final Function(Uint8List?) onSigned;
  final double height;
  
  const SignaturePad({
    super.key,
    required this.onSigned,
    this.height = 200,
  });

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  final GlobalKey _repaintKey = GlobalKey();
  bool _hasSigned = false;

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
      _hasSigned = false;
    });
    widget.onSigned(null);
  }

  Future<void> _captureSignature() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        widget.onSigned(byteData.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint('Error capturing signature: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: RepaintBoundary(
              key: _repaintKey,
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _currentStroke = [details.localPosition];
                    _hasSigned = true;
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _currentStroke.add(details.localPosition);
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    _strokes.add(List.from(_currentStroke));
                    _currentStroke = [];
                  });
                  _captureSignature();
                },
                child: CustomPaint(
                  painter: _SignaturePainter(
                    strokes: _strokes,
                    currentStroke: _currentStroke,
                  ),
                  child: _hasSigned
                      ? const SizedBox.expand()
                      : const Center(
                          child: Text(
                            'Tanda tangan di sini',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _hasSigned ? '✓ Tanda tangan sudah dibuat' : 'Belum ada tanda tangan',
              style: TextStyle(
                fontSize: 12,
                color: _hasSigned ? Colors.green : Colors.grey,
              ),
            ),
            TextButton.icon(
              onPressed: _clear,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Ulangi', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  _SignaturePainter({required this.strokes, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Gambar semua stroke yang sudah selesai
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path();
      path.moveTo(stroke[0].dx, stroke[0].dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Gambar stroke yang sedang berjalan
    if (currentStroke.length >= 2) {
      final path = Path();
      path.moveTo(currentStroke[0].dx, currentStroke[0].dy);
      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) => true;
}
