// lib/screens/staff/map_mode_selector_screen.dart
import 'package:crisis_bridge/screens/staff/walk_mode_screen.dart';
import 'package:crisis_bridge/screens/staff/manual_mode_screen.dart';
import 'package:crisis_bridge/screens/staff/floorplan_mode_screen.dart';
import 'package:flutter/material.dart';

class MapModeSelectorScreen extends StatelessWidget {
  const MapModeSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('◆ CREATE MAP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'CHOOSE MAP BUILDING MODE',
              style: TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFF00FF88),
                fontSize: 13,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            _ModeCard(
              icon: Icons.directions_walk,
              title: 'WALK MODE',
              subtitle:
                  'Walk through the building. Press "Mark Area" at each spot to stamp your GPS location. Connections auto-draw as you walk.',
              color: const Color(0xFF00FF88),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const WalkModeScreen())),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              icon: Icons.keyboard,
              title: 'MANUAL MODE',
              subtitle:
                  'Type area names and tap the canvas to place them. Draw connections between areas by tapping two nodes.',
              color: const Color(0xFF0088FF),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ManualModeScreen())),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              icon: Icons.map_outlined,
              title: 'FLOOR PLAN MODE',
              subtitle:
                  'Upload a floor plan image. Tap on it to place area markers. Draw paths between them.',
              color: const Color(0xFFFFAA00),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FloorPlanModeScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: color.withAlpha(80)),
          borderRadius: BorderRadius.circular(12),
          color: color.withAlpha(15),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withAlpha(100)),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontFamily: 'monospace',
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF88AA88),
                          fontSize: 12,
                          height: 1.5)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: color.withAlpha(120), size: 16),
          ],
        ),
      ),
    );
  }
}