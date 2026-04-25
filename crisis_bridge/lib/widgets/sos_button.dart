import 'package:crisis_bridge/models/floor_area_model.dart';
import 'package:crisis_bridge/providers/sos_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SosButton extends StatelessWidget {
  final String mapId;
  final String propertyId;
  final int floor;
  final List<FloorAreaModel> areas;

  const SosButton({
    super.key,
    required this.mapId,
    required this.propertyId,
    required this.floor,
    required this.areas,
  });

  @override
  Widget build(BuildContext context) {
    final sos = context.watch<SosProvider>();

    return FloatingActionButton.extended(
      heroTag: 'sos_fab',
      backgroundColor: const Color(0xFFFF2222),
      foregroundColor: Colors.white,
      onPressed: () => _confirmSos(context),
      icon: sos.sending
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
          : const Icon(Icons.sos),
      label: const Text(
        'SOS',
        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
      ),
    );
  }

  Future<void> _confirmSos(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111811),
        title: const Text(
          '⚠ SEND SOS?',
          style: TextStyle(color: Color(0xFFFF4444), letterSpacing: 2),
        ),
        content: const Text(
          'This will alert all staff immediately.\nUse only in genuine emergencies.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2222)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CONFIRM SOS'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _sendSos(context);
    }
  }

  Future<void> _sendSos(BuildContext context) async {
    // Pick the first non-danger area as the user's inferred location
    final area = areas.firstWhere(
      (a) => !a.isDanger,
      orElse: () => areas.isNotEmpty
          ? areas.first
          : FloorAreaModel(
              id: 'unknown',
              mapId: mapId,
              name: 'Unknown Area',
              type: 'room',
              x: 0,
              y: 0,
              updatedAt: DateTime.now(),
            ),
    );

    await context.read<SosProvider>().sendSos(
          mapId: mapId,
          propertyId: propertyId,
          floor: floor,
          areaId: area.id,
          areaName: area.name,
          userId: 'guest',
        );

    if (!context.mounted) return;

    // ✅ FIX: const SnackBar content widget
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ SOS SENT — Help is on the way'),
        backgroundColor: Color(0xFFFF2222),
        duration: Duration(seconds: 4),
      ),
    );
  }
}