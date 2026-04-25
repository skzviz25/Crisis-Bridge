import 'package:crisis_bridge/models/danger_state.dart';
import 'package:crisis_bridge/models/floor_area_model.dart';
import 'package:flutter/material.dart';

class NavStatusPanel extends StatelessWidget {
  final String mapId;
  final List<FloorAreaModel> areas;
  final List<DangerState> dangers;

  const NavStatusPanel({
    super.key,
    required this.mapId,
    required this.areas,
    required this.dangers,
  });

  @override
  Widget build(BuildContext context) {
    final exits = areas.where((a) => a.type == 'exit').toList();
    final dangerCount = dangers.where((d) => d.active).length;

    return Container(
      color: const Color(0xFF0A120A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ FIX: Added const to constructor calls
              const _StatusRow(
                label: 'SERVER',
                value: 'CONNECTED',
                valueColor: Color(0xFF00FF88),
              ),
              _StatusRow(
                label: 'EXITS',
                value: exits.isEmpty
                    ? 'NONE'
                    : exits.map((e) => e.name).join(', '),
                valueColor: const Color(0xFF00FFFF),
              ),
              _StatusRow(
                label: 'NODES',
                value: '${areas.length}',
                valueColor: Colors.white,
              ),
            ],
          ),
          const Spacer(),
          if (dangerCount > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFF4444)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      color: Color(0xFFFF4444), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'HAZARDS: $dangerCount',
                    style: const TextStyle(
                      color: Color(0xFFFF4444),
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  // ✅ FIX: Constructor is const-capable
  const _StatusRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Color(0xFF88BBAA),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: valueColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}