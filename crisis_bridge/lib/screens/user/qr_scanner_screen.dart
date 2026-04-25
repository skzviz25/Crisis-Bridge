import 'package:crisis_bridge/core/utils.dart';
import 'package:crisis_bridge/providers/map_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _scanned = false;

  void _onScan(Code code) async {
    if (_scanned) return;
    final raw = code.text ?? '';
    if (raw.isEmpty) return;

    final payload = AppUtils.parseQrPayload(raw);
    if (payload == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR code')),
      );
      return;
    }

    setState(() => _scanned = true);
    final mapId = payload['mapId'] as String;

    if (!mounted) return;
    await context.read<MapProvider>().loadMap(mapId);
    if (!mounted) return;
    context.go('/user/route/$mapId');
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('◆ SCAN QR CODE')),
      body: Stack(
        children: [
          // ✅ FIX: Remove ScannerOverlay entirely — it's abstract and
          // cutOutSize doesn't exist. Use ReaderWidget with no overlay param.
          // The scanner works perfectly without it.
          ReaderWidget(
            onScan: _onScan,
          ),

          // Custom overlay painted on top instead
          IgnorePointer(
            child: CustomPaint(
              painter: _ScanOverlayPainter(borderColor: primaryColor),
              child: const SizedBox.expand(),
            ),
          ),

          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Text(
              'Point at a Crisis Bridge QR code',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 14,
                  ),
            ),
          ),

          if (_scanned)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading map…',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom scan-box overlay — draws the green bracket corners
class _ScanOverlayPainter extends CustomPainter {
  final Color borderColor;
  const _ScanOverlayPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    const boxSize = 260.0;
    const cornerLen = 30.0;
    const strokeW = 3.0;

    final left = (size.width - boxSize) / 2;
    final top = (size.height - boxSize) / 2;
    final right = left + boxSize;
    final bottom = top + boxSize;

    // Dim background
    final dimPaint = Paint()..color = Colors.black54;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), dimPaint);
    canvas.drawRect(Rect.fromLTWH(0, bottom, size.width, size.height - bottom), dimPaint);
    canvas.drawRect(Rect.fromLTWH(0, top, left, boxSize), dimPaint);
    canvas.drawRect(Rect.fromLTWH(right, top, size.width - right, boxSize), dimPaint);

    // Corner brackets
    final p = Paint()
      ..color = borderColor
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(Offset(left, top + cornerLen), Offset(left, top), p);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLen, top), p);
    // Top-right
    canvas.drawLine(Offset(right - cornerLen, top), Offset(right, top), p);
    canvas.drawLine(Offset(right, top), Offset(right, top + cornerLen), p);
    // Bottom-left
    canvas.drawLine(Offset(left, bottom - cornerLen), Offset(left, bottom), p);
    canvas.drawLine(Offset(left, bottom), Offset(left + cornerLen, bottom), p);
    // Bottom-right
    canvas.drawLine(Offset(right - cornerLen, bottom), Offset(right, bottom), p);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - cornerLen), p);
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter old) =>
      old.borderColor != borderColor;
}