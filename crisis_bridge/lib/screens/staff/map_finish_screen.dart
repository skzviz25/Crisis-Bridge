// lib/screens/staff/map_finish_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MapFinishScreen extends StatelessWidget {
  final String mapId;
  final String qrPayload;
  final int areaCount;

  const MapFinishScreen({
    super.key,
    required this.mapId,
    required this.qrPayload,
    required this.areaCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('◆ MAP COMPLETE'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Success banner ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00FF88)),
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF00FF88).withAlpha(15),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: Color(0xFF00FF88), size: 52),
                  const SizedBox(height: 10),
                  const Text(
                    'MAP CREATED SUCCESSFULLY',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFF00FF88),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$areaCount areas  ·  Map ID: ${mapId.length > 8 ? mapId.substring(0, 8) : mapId}…',
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFF88AA88),
                        fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'SCAN THIS QR CODE TO ACCESS THE MAP',
              style: TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFF00FF88),
                fontSize: 11,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),

            // ── QR code rendered by qr_flutter (pure Dart, no native) ──
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00FF88), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FF88).withAlpha(60),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: QrImageView(
                  data: qrPayload,
                  version: QrVersions.auto,
                  size: 240,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  // Shows error widget if something goes wrong
                  errorStateBuilder: (ctx, err) => SizedBox(
                    width: 240,
                    height: 240,
                    child: Center(
                      child: Text(
                        'QR error:\n$err',
                        style: const TextStyle(color: Colors.red, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Screenshot tip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF88).withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.screenshot_monitor,
                      color: Color(0xFF00FF88), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Take a screenshot of this screen to save the QR code',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF00FF88),
                          fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── IDs and payload ────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0D150D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF224422)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IdRow(
                    label: 'MAP ID',
                    value: mapId,
                    onCopy: () => _copied(context, 'Map ID copied'),
                    valueColor: const Color(0xFF00FF88),
                  ),
                  const Divider(color: Color(0xFF224422), height: 20),
                  _IdRow(
                    label: 'QR PAYLOAD',
                    value: qrPayload,
                    onCopy: () => _copied(context, 'Payload copied'),
                    valueColor: const Color(0xFF88AA88),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Next steps ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A120A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF224422)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('◆ NEXT STEPS',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF00FF88),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5)),
                  SizedBox(height: 12),
                  _Step('1', 'Screenshot this screen — the QR code is above'),
                  _Step('2', 'Print and display at each floor entrance'),
                  _Step('3', 'Guests scan QR → live map loads instantly'),
                  _Step('4', 'App calculates safest path to nearest exit'),
                  _Step('5', 'Mark danger zones — all devices update in real time'),
                ],
              ),
            ),

            const SizedBox(height: 28),

            ElevatedButton.icon(
              onPressed: () => context.go('/staff/home'),
              icon: const Icon(Icons.home_outlined),
              label: const Text('BACK TO STAFF HOME'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/staff/map-update/$mapId'),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('CONTINUE EDITING MAP'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _copied(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'monospace')),
      backgroundColor: const Color(0xFF1A2A1A),
      duration: const Duration(seconds: 1),
    ));
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _IdRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;
  final Color valueColor;

  const _IdRow({
    required this.label,
    required this.value,
    required this.onCopy,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('$label:',
                style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF556655),
                    fontSize: 10,
                    letterSpacing: 1)),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                onCopy();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF00FF88)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('COPY',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFF00FF88),
                        fontSize: 10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: TextStyle(
              fontFamily: 'monospace',
              color: valueColor,
              fontSize: 12),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final String num;
  final String text;
  const _Step(this.num, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(right: 10, top: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF88).withAlpha(30),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF00FF88)),
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFF00FF88),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFFAABBAA),
                    fontSize: 12,
                    height: 1.5)),
          ),
        ],
      ),
    );
  }
}