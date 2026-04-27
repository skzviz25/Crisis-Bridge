import 'package:crisis_bridge/core/constants.dart';
import 'package:crisis_bridge/models/floor_area_model.dart';
import 'package:crisis_bridge/providers/map_provider.dart';
import 'package:crisis_bridge/services/firestore_service.dart';
import 'package:crisis_bridge/widgets/map_canvas.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum MapEditMode {
  addNode,    // tap canvas to place a node
  connect,    // tap two nodes to connect them
  select,     // tap a node to select / edit / delete
  manual,     // enter x,y manually
}

class MapUpdateScreen extends StatefulWidget {
  final String mapId;
  const MapUpdateScreen({super.key, required this.mapId});

  @override
  State<MapUpdateScreen> createState() => _MapUpdateScreenState();
}

class _MapUpdateScreenState extends State<MapUpdateScreen> {
  String _selectedType = AppConstants.typeRoom;
  final _nameCtrl = TextEditingController();
  final _xCtrl = TextEditingController();
  final _yCtrl = TextEditingController();
  final _fs = FirestoreService();

  MapEditMode _mode = MapEditMode.addNode;
  FloorAreaModel? _selectedArea;       // selected in 'select' mode
  FloorAreaModel? _connectFirstNode;   // first node picked in 'connect' mode

  static const _types = [
    AppConstants.typeRoom,
    AppConstants.typeHall,
    AppConstants.typeStair,
    AppConstants.typeExit,
    AppConstants.typeDanger,
  ];

  // Color per type
  Color _typeColor(String type) {
    switch (type) {
      case AppConstants.typeExit:   return const Color(0xFF00FFFF);
      case AppConstants.typeStair:  return const Color(0xFFFFAA00);
      case AppConstants.typeHall:   return const Color(0xFF0088FF);
      case AppConstants.typeDanger: return const Color(0xFFFF4444);
      default:                      return const Color(0xFF00FF88);
    }
  }

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
    _xCtrl.dispose();
    _yCtrl.dispose();
    super.dispose();
  }

  // ── Add node by canvas tap ──────────────────────────────────────
  Future<void> _addAreaAtPosition(double x, double y) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showSnack('Enter an area name first');
      return;
    }
    await _saveArea(name, x, y);
  }

  // ── Add node manually ───────────────────────────────────────────
  Future<void> _addAreaManually() async {
    final name = _nameCtrl.text.trim();
    final x = double.tryParse(_xCtrl.text.trim());
    final y = double.tryParse(_yCtrl.text.trim());

    if (name.isEmpty) { _showSnack('Enter area name'); return; }
    if (x == null || y == null || x < 0 || x > 1 || y < 0 || y > 1) {
      _showSnack('X and Y must be between 0.0 and 1.0');
      return;
    }
    await _saveArea(name, x, y);
  }

  Future<void> _saveArea(String name, double x, double y) async {
    final area = FloorAreaModel(
      id: '',
      mapId: widget.mapId,
      name: name,
      type: _selectedType,
      x: x,
      y: y,
      isDanger: _selectedType == AppConstants.typeDanger,
      connectedAreaIds: const [],
      updatedAt: DateTime.now(),
    );
    await _fs.upsertArea(area);
    if (!mounted) return;
    _nameCtrl.clear();
    _xCtrl.clear();
    _yCtrl.clear();
    _showSnack('Added "${area.name}"');
  }

  // ── Handle canvas tap depending on mode ──────────────────────────
  void _onCanvasTap(double x, double y) {
    if (_mode == MapEditMode.addNode) {
      _addAreaAtPosition(x, y);
    }
  }

  // ── Handle area tap depending on mode ────────────────────────────
  void _onAreaTap(FloorAreaModel area) {
    if (_mode == MapEditMode.select) {
      setState(() => _selectedArea = area);
      _showAreaOptions(area);
    } else if (_mode == MapEditMode.connect) {
      _handleConnect(area);
    }
  }

  void _handleConnect(FloorAreaModel tapped) {
    if (_connectFirstNode == null) {
      setState(() => _connectFirstNode = tapped);
      _showSnack('Now tap the second area to connect to "${tapped.name}"');
    } else {
      if (_connectFirstNode!.id == tapped.id) {
        _showSnack('Cannot connect an area to itself');
        setState(() => _connectFirstNode = null);
        return;
      }
      _connectTwoAreas(_connectFirstNode!, tapped);
      setState(() => _connectFirstNode = null);
    }
  }

  Future<void> _connectTwoAreas(
      FloorAreaModel a, FloorAreaModel b) async {
    // Add b to a's connections and a to b's connections (bidirectional)
    final aConns = List<String>.from(a.connectedAreaIds);
    final bConns = List<String>.from(b.connectedAreaIds);

    if (!aConns.contains(b.id)) aConns.add(b.id);
    if (!bConns.contains(a.id)) bConns.add(a.id);

    await _fs.upsertArea(a.copyWith(connectedAreaIds: aConns));
    await _fs.upsertArea(b.copyWith(connectedAreaIds: bConns));

    if (!mounted) return;
    _showSnack('Connected "${a.name}" ↔ "${b.name}"');
  }

  Future<void> _disconnectTwoAreas(
      FloorAreaModel a, FloorAreaModel b) async {
    final aConns = List<String>.from(a.connectedAreaIds)..remove(b.id);
    final bConns = List<String>.from(b.connectedAreaIds)..remove(a.id);
    await _fs.upsertArea(a.copyWith(connectedAreaIds: aConns));
    await _fs.upsertArea(b.copyWith(connectedAreaIds: bConns));
    if (!mounted) return;
    _showSnack('Disconnected "${a.name}" and "${b.name}"');
  }

  // ── Area options bottom sheet ────────────────────────────────────
  void _showAreaOptions(FloorAreaModel area) {
    final mapProv = context.read<MapProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111811),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AreaOptionsSheet(
        area: area,
        allAreas: mapProv.areas,
        onToggleDanger: () async {
          final updated = area.copyWith(isDanger: !area.isDanger);
          await _fs.upsertArea(updated);
          if (!mounted) return;
          Navigator.pop(context);
        },
        onDelete: () async {
          await _fs.deleteArea(widget.mapId, area.id);
          // Remove this area from all others' connection lists
          for (final other in mapProv.areas) {
            if (other.connectedAreaIds.contains(area.id)) {
              final updated = other.copyWith(
                connectedAreaIds: List<String>.from(other.connectedAreaIds)
                  ..remove(area.id),
              );
              await _fs.upsertArea(updated);
            }
          }
          if (!mounted) return;
          Navigator.pop(context);
          setState(() => _selectedArea = null);
        },
        onDisconnect: (other) async {
          await _disconnectTwoAreas(area, other);
          if (!mounted) return;
          Navigator.pop(context);
        },
        onRename: (newName) async {
          await _fs.upsertArea(area.copyWith(name: newName));
          if (!mounted) return;
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'monospace')),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1A2A1A),
      ),
    );
  }

  // ── Mode button ──────────────────────────────────────────────────
  Widget _modeBtn(MapEditMode mode, IconData icon, String label) {
    final active = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() {
        _mode = mode;
        _connectFirstNode = null;
        _selectedArea = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF00FF88).withAlpha(40)
              : Colors.transparent,
          border: Border.all(
            color: active
                ? const Color(0xFF00FF88)
                : const Color(0xFF224422),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: active
                    ? const Color(0xFF00FF88)
                    : const Color(0xFF556655)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: active
                    ? const Color(0xFF00FF88)
                    : const Color(0xFF556655),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapProv = context.watch<MapProvider>();
    final shortId = widget.mapId.length >= 6
        ? widget.mapId.substring(0, 6)
        : widget.mapId;

    return Scaffold(
      appBar: AppBar(
        title: Text('◆ MAP EDITOR [$shortId]'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
            tooltip: 'Help',
          ),
        ],
      ),
      body: Column(
        children: [

          // ── Mode selector ────────────────────────────────────────
          Container(
            color: const Color(0xFF0A120A),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                _modeBtn(MapEditMode.addNode, Icons.add_location_alt, 'ADD'),
                const SizedBox(width: 6),
                _modeBtn(MapEditMode.connect, Icons.share, 'CONNECT'),
                const SizedBox(width: 6),
                _modeBtn(MapEditMode.select, Icons.touch_app, 'SELECT'),
                const SizedBox(width: 6),
                _modeBtn(MapEditMode.manual, Icons.keyboard, 'MANUAL'),
              ],
            ),
          ),

          // ── ADD / MANUAL input bar ───────────────────────────────
          if (_mode == MapEditMode.addNode ||
              _mode == MapEditMode.manual) ...[
            Container(
              color: const Color(0xFF0D150D),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'AREA NAME',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
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
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: BoxDecoration(
                                          color: _typeColor(t),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Text(t.toUpperCase(),
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontFamily: 'monospace')),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(
                            () => _selectedType = v ?? _selectedType),
                      ),
                    ],
                  ),

                  // Manual X/Y fields
                  if (_mode == MapEditMode.manual) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _xCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'X (0.0 – 1.0)',
                              hintText: 'e.g. 0.25',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _yCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Y (0.0 – 1.0)',
                              hintText: 'e.g. 0.50',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addAreaManually,
                          style: ElevatedButton.styleFrom(
                              minimumSize: const Size(60, 36)),
                          child: const Text('ADD',
                              style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'X=0 is left edge, X=1 is right. Y=0 is top, Y=1 is bottom.',
                      style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: Color(0xFF556655)),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // ── CONNECT mode hint ───────────────────────────────────
          if (_mode == MapEditMode.connect)
            Container(
              color: const Color(0xFF0D150D),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    _connectFirstNode == null
                        ? Icons.looks_one_outlined
                        : Icons.looks_two_outlined,
                    color: const Color(0xFF00FF88),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _connectFirstNode == null
                        ? 'Tap first area to connect'
                        : 'Now tap second area  ←  "${_connectFirstNode!.name}"',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFF00FF88),
                    ),
                  ),
                ],
              ),
            ),

          // ── SELECT mode hint ────────────────────────────────────
          if (_mode == MapEditMode.select)
            Container(
              color: const Color(0xFF0D150D),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: const Row(
                children: [
                  Icon(Icons.touch_app,
                      color: Color(0xFF00FF88), size: 18),
                  SizedBox(width: 8),
                  Text('Tap any area node to edit, delete, or disconnect',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF00FF88))),
                ],
              ),
            ),

          // ── Map canvas ──────────────────────────────────────────
          Expanded(
            child: mapProv.loading
                ? const Center(child: CircularProgressIndicator())
                : MapCanvasInteractive(
                    areas: mapProv.areas,
                    dangerAreaIds: mapProv.dangerAreaIds,
                    selectedAreaId: _selectedArea?.id,
                    connectingAreaId: _connectFirstNode?.id,
                    mode: _mode,
                    onCanvasTap: _onCanvasTap,
                    onAreaTap: _onAreaTap,
                  ),
          ),

          // ── Legend ─────────────────────────────────────────────
          Container(
            color: const Color(0xFF0A120A),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legendDot(const Color(0xFF00FF88), 'Room'),
                _legendDot(const Color(0xFF0088FF), 'Hall'),
                _legendDot(const Color(0xFFFFAA00), 'Stair'),
                _legendDot(const Color(0xFF00FFFF), 'Exit'),
                _legendDot(const Color(0xFFFF4444), 'Danger'),
              ],
            ),
          ),

          // ── Stats bar ──────────────────────────────────────────
          Container(
            color: const Color(0xFF060E06),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Text(
                  'NODES: ${mapProv.areas.length}  ·  '
                  'CONNECTIONS: ${_totalConnections(mapProv.areas)}  ·  '
                  'EXITS: ${mapProv.areas.where((a) => a.type == AppConstants.typeExit).length}',
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: Color(0xFF448844)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _totalConnections(List<FloorAreaModel> areas) {
    final total =
        areas.fold<int>(0, (sum, a) => sum + a.connectedAreaIds.length);
    return total ~/ 2; // bidirectional counted once
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10, fontFamily: 'monospace',
                color: Color(0xFF88AA88))),
      ],
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111811),
        title: const Text('◆ MAP BUILDER GUIDE',
            style: TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFF00FF88),
                fontSize: 14)),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HelpRow('ADD mode',
                  'Tap any empty spot on the canvas to place a node there. Enter name + type first.'),
              SizedBox(height: 12),
              _HelpRow('MANUAL mode',
                  'Enter X and Y values (0.0–1.0) precisely. X=0 is left, X=1 is right. Y=0 is top, Y=1 is bottom.\n\nExample floor layout:\n  Reception  X=0.1  Y=0.5\n  Hall A     X=0.3  Y=0.5\n  Room 101   X=0.5  Y=0.3\n  Stairwell  X=0.7  Y=0.5\n  Exit       X=0.9  Y=0.5'),
              SizedBox(height: 12),
              _HelpRow('CONNECT mode',
                  'Tap the first area, then tap the second. A line appears between them. Pathfinding uses these connections — areas not connected cannot be routed through.'),
              SizedBox(height: 12),
              _HelpRow('SELECT mode',
                  'Tap any node to open options: rename, delete, toggle danger, or disconnect from another node.'),
              SizedBox(height: 12),
              _HelpRow('Tips',
                  '• Always connect every room to at least one hall\n• Connect halls to stairs and exits\n• Mark fire/flood areas as Danger type\n• You need at least one Exit node for pathfinding to work'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  final String title;
  final String body;
  const _HelpRow(this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('[$title]',
            style: const TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFF00FF88),
                fontSize: 12,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(body,
            style: const TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFFAABBAA),
                fontSize: 12)),
      ],
    );
  }

  
}

class _AreaOptionsSheet extends StatelessWidget {
  final FloorAreaModel area;
  final List<FloorAreaModel> allAreas;
  final VoidCallback onToggleDanger;
  final VoidCallback onDelete;
  final void Function(FloorAreaModel other) onDisconnect;
  final void Function(String newName) onRename;

  const _AreaOptionsSheet({
    required this.area,
    required this.allAreas,
    required this.onToggleDanger,
    required this.onDelete,
    required this.onDisconnect,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final connectedAreas = allAreas
        .where((a) => area.connectedAreaIds.contains(a.id))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _colorForType(area.type, area.isDanger),
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                area.name.toUpperCase(),
                style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF00FF88),
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                '[${area.type}]',
                style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF556655),
                    fontSize: 12),
              ),
            ],
          ),
          Text(
            'x=${area.x.toStringAsFixed(3)}  y=${area.y.toStringAsFixed(3)}',
            style: const TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFF446644),
                fontSize: 11),
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFF224422)),

          // Actions
          ListTile(
            dense: true,
            leading: const Icon(Icons.edit_outlined,
                color: Color(0xFF00FF88), size: 20),
            title: const Text('Rename',
                style: TextStyle(
                    fontFamily: 'monospace', color: Color(0xFFCCFFCC))),
            onTap: () {
              Navigator.pop(context);
              _showRenameDialog(context);
            },
          ),
          ListTile(
            dense: true,
            leading: Icon(
              area.isDanger
                  ? Icons.check_circle_outline
                  : Icons.local_fire_department_outlined,
              color:
                  area.isDanger ? const Color(0xFF00FF88) : const Color(0xFFFF4444),
              size: 20,
            ),
            title: Text(
              area.isDanger ? 'Clear danger zone' : 'Mark as danger zone',
              style: const TextStyle(
                  fontFamily: 'monospace', color: Color(0xFFCCFFCC)),
            ),
            onTap: onToggleDanger,
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.delete_outline,
                color: Color(0xFFFF4444), size: 20),
            title: const Text('Delete this area',
                style: TextStyle(
                    fontFamily: 'monospace', color: Color(0xFFFF8888))),
            onTap: onDelete,
          ),

          // Connected areas
          if (connectedAreas.isNotEmpty) ...[
            const Divider(color: Color(0xFF224422)),
            const Text('CONNECTIONS:',
                style: TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF556655),
                    fontSize: 11)),
            const SizedBox(height: 4),
            ...connectedAreas.map((other) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.link_off,
                      color: Color(0xFF556655), size: 18),
                  title: Text(other.name,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFFAABBAA),
                          fontSize: 13)),
                  trailing: const Text('tap to disconnect',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF556655),
                          fontSize: 10)),
                  onTap: () => onDisconnect(other),
                )),
          ] else ...[
            const Divider(color: Color(0xFF224422)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No connections yet. Use CONNECT mode to link areas.',
                style: TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF556655),
                    fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final ctrl = TextEditingController(text: area.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111811),
        title: const Text('Rename area',
            style: TextStyle(fontFamily: 'monospace',
                color: Color(0xFF00FF88))),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'NEW NAME'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                onRename(ctrl.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Color _colorForType(String type, bool isDanger) {
    if (isDanger) return const Color(0xFFFF4444);
    switch (type) {
      case 'exit':   return const Color(0xFF00FFFF);
      case 'stair':  return const Color(0xFFFFAA00);
      case 'hall':   return const Color(0xFF0088FF);
      default:       return const Color(0xFF00FF88);
    }
  }
}