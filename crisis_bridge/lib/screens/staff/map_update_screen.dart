import 'package:crisis_bridge/core/constants.dart';
import 'package:crisis_bridge/models/floor_area_model.dart';
import 'package:crisis_bridge/providers/map_provider.dart';
import 'package:crisis_bridge/services/firestore_service.dart';
import 'package:crisis_bridge/widgets/map_canvas.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ✅ FIX: uuid import removed (unused)
// ✅ FIX: auth_provider kept but only used for uid

class MapUpdateScreen extends StatefulWidget {
  final String mapId;
  const MapUpdateScreen({super.key, required this.mapId});

  @override
  State<MapUpdateScreen> createState() => _MapUpdateScreenState();
}

class _MapUpdateScreenState extends State<MapUpdateScreen> {
  String _selectedType = AppConstants.typeRoom;
  final _nameCtrl = TextEditingController();
  final _fs = FirestoreService();

  static const _types = [
    AppConstants.typeRoom,
    AppConstants.typeHall,
    AppConstants.typeStair,
    AppConstants.typeExit,
    AppConstants.typeDanger,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapProvider>().loadMap(widget.mapId);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _addArea(double x, double y) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter area name first')),
      );
      return;
    }
    final area = FloorAreaModel(
      id: '',
      mapId: widget.mapId,
      name: name,
      type: _selectedType,
      x: x,
      y: y,
      isDanger: _selectedType == AppConstants.typeDanger,
      updatedAt: DateTime.now(),
    );
    await _fs.upsertArea(area);
    if (!mounted) return;
    _nameCtrl.clear();
  }

  Future<void> _toggleDanger(FloorAreaModel area) async {
    // ✅ FIX: removed unused 'auth' variable
    final updated = area.copyWith(isDanger: !area.isDanger);
    await _fs.upsertArea(updated);
  }

  @override
  Widget build(BuildContext context) {
    final mapProv = context.watch<MapProvider>();
    final shortId = widget.mapId.length >= 6
        ? widget.mapId.substring(0, 6)
        : widget.mapId;

    return Scaffold(
      appBar: AppBar(title: Text('◆ MAP EDITOR [$shortId]')),
      body: Column(
        children: [
          // Toolbar
          Container(
            color: const Color(0xFF0D150D),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'AREA NAME',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedType,
                  dropdownColor: const Color(0xFF111811),
                  items: _types
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace')),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedType = v ?? _selectedType),
                ),
              ],
            ),
          ),
          // Map canvas
          Expanded(
            child: mapProv.loading
                ? const Center(child: CircularProgressIndicator())
                : MapCanvas(
                    areas: mapProv.areas,
                    dangerAreaIds: mapProv.dangerAreaIds,
                    route: const [],
                    onTap: _addArea,
                    onAreaLongPress: _toggleDanger,
                  ),
          ),
          // Legend
          Container(
            color: const Color(0xFF0D150D),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Row(
              children: [
                _LegendDot(color: Color(0xFF00FF88), label: 'Room'),
                SizedBox(width: 12),
                _LegendDot(color: Color(0xFF0088FF), label: 'Hall'),
                SizedBox(width: 12),
                _LegendDot(color: Color(0xFFFFAA00), label: 'Stair'),
                SizedBox(width: 12),
                _LegendDot(color: Color(0xFF00FFFF), label: 'Exit'),
                SizedBox(width: 12),
                _LegendDot(color: Color(0xFFFF4444), label: 'Danger'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style:
                const TextStyle(fontSize: 10, fontFamily: 'monospace')),
      ],
    );
  }
}