// ignore_for_file: deprecated_member_use

import 'package:crisis_bridge/core/constants.dart';
import 'package:flutter/material.dart';

class AreaChip extends StatelessWidget {
  final String type;
  final String label;
  final bool isDanger;

  const AreaChip({
    super.key,
    required this.type,
    required this.label,
    this.isDanger = false,
  });

  Color get _color {
    if (isDanger) return const Color(0xFFFF4444);
    switch (type) {
      case AppConstants.typeExit:
        return const Color(0xFF00FFFF);
      case AppConstants.typeStair:
        return const Color(0xFFFFAA00);
      case AppConstants.typeHall:
        return const Color(0xFF0088FF);
      default:
        return const Color(0xFF00FF88);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: .red/.green/.blue are deprecated
    // Use Color.fromARGB with explicit channel extraction via bit-shifting
    final c = _color;
    final bgColor = Color.fromARGB(
      26,                        // ~10% opacity (255 * 0.10 ≈ 26)
      (c.value >> 16) & 0xFF,   // red channel
      (c.value >> 8) & 0xFF,    // green channel
      c.value & 0xFF,            // blue channel
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: _color),
        borderRadius: BorderRadius.circular(4),
        color: bgColor,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDanger)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(
                Icons.local_fire_department,
                size: 12,
                color: Color(0xFFFF4444),
              ),
            ),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: _color,
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}