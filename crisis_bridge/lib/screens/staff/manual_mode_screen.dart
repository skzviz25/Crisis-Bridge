// lib/screens/staff/manual_mode_screen.dart
import 'dart:async';
import 'package:crisis_bridge/core/constants.dart';
import 'package:crisis_bridge/models/floor_area_model.dart';
import 'package:crisis_bridge/providers/auth_provider.dart';
import 'package:crisis_bridge/screens/staff/map_finish_screen.dart';
import 'package:crisis_bridge/services/map_builder_service.dart';
import 'package:crisis_bridge/widgets/builder_map_canvas.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class ManualModeScreen extends StatefulWidget {
  const ManualModeScreen({super.key});

  @override
  State<ManualModeScreen> createState() => _ManualModeScreenState();
}

class _ManualModeScreenState extends State<ManualModeScreen> {
  final _service = MapBuilderService();
  final _nameCtrl = TextEditingController();
  final _xCtrl = TextEditingController();
  final _yCtrl = TextEditingController();

  String? _mapId;
  String _selectedType = AppConstants.typeRoom;
  bool _isInitializing = true;
  bool _isSaving = false;

  bool _connectMode = false;
  bool _selectMode = false;
  bool _manualXY = false;

  List<FloorAreaModel> _areas = [];
  StreamSubscription<List<FloorAreaModel>>? _areasSub;

  FloorAreaModel? _selectedArea;
  FloorAreaModel? _connectFirst;

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
    _initialize();
  }

  Future<void> _initialize() async {
    final auth = context.read<AuthProvider>();
    final result = await _showSetupDialog();
    if (result == null || !mounted) return;

    final mapId = await _service.createEmptyMap(
      propertyId: auth.responder?.propertyId ?? 'unknown',
      propertyName: result['name']!,
      floor: int.tryParse(result['floor']!) ?? 1,
      createdBy: auth.user?.uid ?? '',
    );

    setState(() {
      _mapId = mapId;
      _isInitializing = false;
    });

    _areasSub = _service.areasStream(mapId).listen((areas) {
      setState(() => _areas = areas);
    });
  }

  Future<Map<String, String>?> _showSetupDialog() async {
    final nameCtrl = TextEditingController(text: 'My Property');
    final floorCtrl = TextEditingController(text: '1');
    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111811),
        title: const Text('◆ MAP SETUP',
            style: TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFF00FF88),
                fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'PROPERTY NAME')),
            const SizedBox(height: 12),
            TextField(
                controller: floorCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'FLOOR NUMBER')),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'name': nameCtrl.text.trim().isEmpty
                  ? 'My Property'
                  : nameCtrl.text.trim(),
              'floor': floorCtrl.text.trim().isEmpty
                  ? '1'
                  : floorCtrl.text.trim(),
            }),
            child: const Text('START'),
          ),
        ],
      ),
    );
  }

  Future<void> _placeAreaAt(double x, double y) async {
    if (_connectMode || _selectMode) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Enter area name first');
      return;
    }
    await _saveNewArea(name, x, y);
  }

  Future<void> _placeAreaManually() async {
    final name = _nameCtrl.text.trim();
    final x = double.tryParse(_xCtrl.text.trim());
    final y = double.tryParse(_yCtrl.text.trim());
    if (name.isEmpty) { _snack('Enter area name'); return; }
    if (x == null || y == null || x < 0 || x > 1 || y < 0 || y > 1) {
      _snack('X and Y must be 0.0 to 1.0');
      return;
    }
    await _saveNewArea(name, x, y);
    _xCtrl.clear();
    _yCtrl.clear();
  }

  Future<void> _saveNewArea(String name, double x, double y) async {
    if (_mapId == null) return;
    setState(() => _isSaving = true);
    final area = FloorAreaModel(
      id: '',
      mapId: _mapId!,
      name: name,
      type: _selectedType,
      x: x,
      y: y,
      isDanger: _selectedType == AppConstants.typeDanger,
      connectedAreaIds: const [],
      updatedAt: DateTime.now(),
    );
    await _service.saveArea(area);
    if (mounted) {
      setState(() {
        _isSaving = false;
        _nameCtrl.clear();
      });
    }
  }

  void _onAreaTap(FloorAreaModel area) {
    if (_connectMode) {
      _handleConnect(area);
    } else if (_selectMode) {
      setState(() => _selectedArea = area);
      _showAreaOptions(area);
    }
  }

  void _handleConnect(FloorAreaModel tapped) {
    if (_connectFirst == null) {
      setState(() => _connectFirst = tapped);
      _snack('Now tap second area to connect → "${tapped.name}"');
    } else {
      if (_connectFirst!.id == tapped.id) {
        _snack('Cannot connect area to itself');
        setState(() => _connectFirst = null);
        return;
      }
      _doConnect(_connectFirst!, tapped);
      setState(() => _connectFirst = null);
    }
  }

  Future<void> _doConnect(FloorAreaModel a, FloorAreaModel b) async {
    await _service.connectAreas(a, b);
    _snack('Connected "${a.name}" ↔ "${b.name}"');
  }

  Future<void> _doDisconnect(FloorAreaModel a, FloorAreaModel b) async {
    await _service.disconnectAreas(a, b);
    _snack('Disconnected "${a.name}" and "${b.name}"');
  }

  void _showAreaOptions(FloorAreaModel area) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111811),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _AreaSheet(
        area: area,
        allAreas: _areas,
        onToggleDanger: () async {
          await _service.saveArea(FloorAreaModel(
            id: area.id,
            mapId: area.mapId,
            name: area.name,
            type: area.type,
            x: area.x,
            y: area.y,
            isDanger: !area.isDanger,
            connectedAreaIds: area.connectedAreaIds,
            updatedAt: DateTime.now(),
          ));
          if (mounted) Navigator.pop(context);
        },
        onDelete: () async {
          await _service.deleteArea(_mapId!, area, _areas);
          if (mounted) {
            Navigator.pop(context);
            setState(() => _selectedArea = null);
          }
        },
        onDisconnect: (other) async {
          await _doDisconnect(area, other);
          if (mounted) Navigator.pop(context);
        },
        onRename: (name) async {
          await _service.saveArea(FloorAreaModel(
            id: area.id,
            mapId: area.mapId,
            name: name,
            type: area.type,
            x: area.x,
            y: area.y,
            isDanger: area.isDanger,
            connectedAreaIds: area.connectedAreaIds,
            updatedAt: DateTime.now(),
          ));
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _finishMap() async {
    if (_mapId == null) return;
    final exits =
        _areas.where((a) => a.type == AppConstants.typeExit).length;
    if (exits == 0) {
      final ok = await _confirmNoExit();
      if (ok != true) return;
    }
    final qr = await _service.finishMap(_mapId!);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MapFinishScreen(
          mapId: _mapId!,
          qrPayload: qr,
          areaCount: _areas.length,
        ),
      ),
    );
  }

  Future<bool?> _confirmNoExit() => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF111811),
          title: const Text('⚠ No EXIT marked',
              style: TextStyle(color: Color(0xFFFF8800))),
          content: const Text(
              'Add an Exit area for pathfinding to work. Continue anyway?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('FINISH ANYWAY')),
          ],
        ),
      );

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'monospace')),
      backgroundColor: const Color(0xFF1A2A1A),
      duration: const Duration(seconds: 2),
    ));
  }

  Color _typeColor(String t) {
    switch (t) {
      case AppConstants.typeExit:   return const Color(0xFF00FFFF);
      case AppConstants.typeStair:  return const Color(0xFFFFAA00);
      case AppConstants.typeHall:   return const Color(0xFF0088FF);
      case AppConstants.typeDanger: return const Color(0xFFFF4444);
      default:                      return const Color(0xFF00FF88);
    }
  }

  Widget _modeBtn(
      String label, IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF00FF88).withAlpha(40)
              : Colors.transparent,
          border: Border.all(
              color: active
                  ? const Color(0xFF00FF88)
                  : const Color(0xFF224422)),
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
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: active
                        ? const Color(0xFF00FF88)
                        : const Color(0xFF556655))),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _areasSub?.cancel();
    _nameCtrl.dispose();
    _xCtrl.dispose();
    _yCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final isAddMode = !_connectMode && !_selectMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('◆ MANUAL MODE'),
        actions: [
          TextButton.icon(
            onPressed: _finishMap,
            icon: const Icon(Icons.qr_code_2, color: Color(0xFF00FF88)),
            label: const Text('FINISH & QR',
                style: TextStyle(
                    color: Color(0xFF00FF88),
                    fontFamily: 'monospace',
                    fontSize: 11)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF0A120A),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                _modeBtn('ADD', Icons.add_location_alt, isAddMode, () {
                  setState(() {
                    _connectMode = false;
                    _selectMode = false;
                    _connectFirst = null;
                  });
                }),
                const SizedBox(width: 6),
                _modeBtn('CONNECT', Icons.share, _connectMode, () {
                  setState(() {
                    _connectMode = true;
                    _selectMode = false;
                    _connectFirst = null;
                  });
                }),
                const SizedBox(width: 6),
                _modeBtn('SELECT', Icons.touch_app, _selectMode, () {
                  setState(() {
                    _connectMode = false;
                    _selectMode = true;
                    _connectFirst = null;
                  });
                }),
                const SizedBox(width: 6),
                _modeBtn('X/Y', Icons.keyboard, _manualXY, () {
                  setState(() => _manualXY = !_manualXY);
                }),
              ],
            ),
          ),

          if (isAddMode)
            Container(
              color: const Color(0xFF0D150D),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                          width: 8,
                                          height: 8,
                                          margin:
                                              const EdgeInsets.only(right: 6),
                                          decoration: BoxDecoration(
                                              color: _typeColor(t),
                                              shape: BoxShape.circle)),
                                      Text(t.toUpperCase(),
                                          style: const TextStyle(
                                              fontSize: 10,
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
                  if (_manualXY) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _xCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'X  (0.0–1.0)',
                              hintText: '0.25',
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
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Y  (0.0–1.0)',
                              hintText: '0.50',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _placeAreaManually,
                          style: ElevatedButton.styleFrom(
                              minimumSize: const Size(60, 36)),
                          child: const Text('ADD',
                              style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'X: left=0.0  right=1.0    Y: top=0.0  bottom=1.0',
                      style: TextStyle(
                          fontSize: 9,
                          fontFamily: 'monospace',
                          color: Color(0xFF556655)),
                    ),
                  ],
                ],
              ),
            ),

          if (_connectMode)
            _hintBar(
              icon: _connectFirst == null
                  ? Icons.looks_one_outlined
                  : Icons.looks_two_outlined,
              text: _connectFirst == null
                  ? 'Tap first area'
                  : 'Tap second area  ←  "${_connectFirst!.name}"',
            ),
          if (_selectMode)
            _hintBar(
              icon: Icons.touch_app,
              text: 'Tap any node to edit / delete / disconnect',
            ),

          Expanded(
            child: BuilderMapCanvas(
              areas: _areas,
              dangerAreaIds:
                  _areas.where((a) => a.isDanger).map((a) => a.id).toSet(),
              selectedAreaId: _selectedArea?.id,
              connectingAreaId: _connectFirst?.id,
              showCurrentPosition: false,
              currentPosX: null,
              currentPosY: null,
              onCanvasTap: isAddMode ? _placeAreaAt : null,
              onAreaTap:
                  (_connectMode || _selectMode) ? _onAreaTap : null,
            ),
          ),

          _statsBar(),
        ],
      ),
    );
  }

  Widget _hintBar({required IconData icon, required String text}) {
    return Container(
      color: const Color(0xFF0D150D),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00FF88), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Color(0xFF00FF88))),
          ),
        ],
      ),
    );
  }

  Widget _statsBar() {
    final conns = _areas.fold<int>(
            0, (s, a) => s + a.connectedAreaIds.length) ~/
        2;
    return Container(
      color: const Color(0xFF060E06),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'NODES: ${_areas.length}  ·  LINKS: $conns  ·  '
            'EXITS: ${_areas.where((a) => a.type == AppConstants.typeExit).length}',
            style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Color(0xFF448844)),
          ),
          GestureDetector(
            onTap: _showHelp,
            child: const Text('? HELP',
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: Color(0xFF006644))),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111811),
        title: const Text('◆ MANUAL MODE GUIDE',
            style: TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFF00FF88),
                fontSize: 13)),
        content: const SingleChildScrollView(
          child: Text(
            'ADD mode:\n'
            '  • Type area name, choose type\n'
            '  • Tap canvas to place node there\n'
            '  • Or enable X/Y to type coordinates\n\n'
            'CONNECT mode:\n'
            '  • Tap first node, then second\n'
            '  • A path is drawn between them\n\n'
            'SELECT mode:\n'
            '  • Tap any node to rename,\n'
            '    delete, or remove a connection\n\n'
            'Coordinates:\n'
            '  X=0.0 left  X=1.0 right\n'
            '  Y=0.0 top   Y=1.0 bottom',
            style: TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFFAABBAA),
                fontSize: 12,
                height: 1.6),
          ),
        ),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('GOT IT')),
        ],
      ),
    );
  }
}

class _AreaSheet extends StatelessWidget {
  final FloorAreaModel area;
  final List<FloorAreaModel> allAreas;
  final VoidCallback onToggleDanger;
  final VoidCallback onDelete;
  final void Function(FloorAreaModel) onDisconnect;
  final void Function(String) onRename;

  const _AreaSheet({
    required this.area,
    required this.allAreas,
    required this.onToggleDanger,
    required this.onDelete,
    required this.onDisconnect,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final connected =
        allAreas.where((a) => area.connectedAreaIds.contains(a.id)).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(area.name.toUpperCase(),
              style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF00FF88),
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Text(
              '${area.type}  x=${area.x.toStringAsFixed(2)}  y=${area.y.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF556655),
                  fontSize: 11)),
          const Divider(color: Color(0xFF224422)),
          ListTile(
            dense: true,
            leading: const Icon(Icons.edit_outlined,
                color: Color(0xFF00FF88), size: 20),
            title: const Text('Rename',
                style: TextStyle(
                    fontFamily: 'monospace', color: Color(0xFFCCFFCC))),
            onTap: () {
              Navigator.pop(context);
              final ctrl = TextEditingController(text: area.name);
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF111811),
                  title: const Text('Rename',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF00FF88))),
                  content: TextField(
                      controller: ctrl,
                      autofocus: true,
                      decoration:
                          const InputDecoration(labelText: 'NEW NAME')),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL')),
                    ElevatedButton(
                        onPressed: () {
                          if (ctrl.text.trim().isNotEmpty) {
                            onRename(ctrl.text.trim());
                          }
                          Navigator.pop(context);
                        },
                        child: const Text('SAVE')),
                  ],
                ),
              );
            },
          ),
          ListTile(
            dense: true,
            leading: Icon(
              area.isDanger
                  ? Icons.check_circle_outline
                  : Icons.local_fire_department_outlined,
              color: area.isDanger
                  ? const Color(0xFF00FF88)
                  : const Color(0xFFFF4444),
              size: 20,
            ),
            title: Text(
              area.isDanger ? 'Clear danger zone' : 'Mark as danger',
              style: const TextStyle(
                  fontFamily: 'monospace', color: Color(0xFFCCFFCC)),
            ),
            onTap: onToggleDanger,
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.delete_outline,
                color: Color(0xFFFF4444), size: 20),
            title: const Text('Delete',
                style: TextStyle(
                    fontFamily: 'monospace', color: Color(0xFFFF8888))),
            onTap: onDelete,
          ),
          if (connected.isNotEmpty) ...[
            const Divider(color: Color(0xFF224422)),
            const Text('CONNECTIONS (tap to remove):',
                style: TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF556655),
                    fontSize: 11)),
            ...connected.map((o) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.link_off,
                      color: Color(0xFF556655), size: 18),
                  title: Text(o.name,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFFAABBAA))),
                  onTap: () => onDisconnect(o),
                )),
          ],
        ],
      ),
    );
  }
}