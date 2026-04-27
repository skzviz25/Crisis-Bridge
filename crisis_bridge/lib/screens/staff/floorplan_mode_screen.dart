// lib/screens/staff/floorplan_mode_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:crisis_bridge/core/constants.dart';
import 'package:crisis_bridge/models/floor_area_model.dart';
import 'package:crisis_bridge/providers/auth_provider.dart';
import 'package:crisis_bridge/screens/staff/map_finish_screen.dart';
import 'package:crisis_bridge/services/map_builder_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
 
class FloorPlanModeScreen extends StatefulWidget {
  const FloorPlanModeScreen({super.key});
 
  @override
  State<FloorPlanModeScreen> createState() => _FloorPlanModeScreenState();
}
 
class _FloorPlanModeScreenState extends State<FloorPlanModeScreen> {
  final _service = MapBuilderService();
  final _nameCtrl = TextEditingController();
 
  // ✅ FIX: ImagePicker must be instantiated fresh per call on some devices
  final ImagePicker _picker = ImagePicker();
 
  String? _mapId;
  File? _floorPlanImage;
  String _selectedType = AppConstants.typeRoom;
  bool _isInitializing = true;
  bool _connectMode = false;
  bool _selectMode = false;
  bool _pickingImage = false;
 
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
      if (mounted) setState(() => _areas = areas);
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
        title: const Text('◆ FLOOR PLAN SETUP',
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
 
  // ✅ FIX: Use try/catch, avoid double-opening picker, handle all error cases
  Future<void> _pickFromGallery() async {
    if (_pickingImage) return;
    setState(() => _pickingImage = true);
    try {
      final XFile? xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (xFile != null && mounted) {
        setState(() => _floorPlanImage = File(xFile.path));
      }
    } catch (e) {
      if (mounted) {
        _snack('Could not open gallery: $e');
      }
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }
 
  Future<void> _pickFromCamera() async {
    if (_pickingImage) return;
    setState(() => _pickingImage = true);
    try {
      final XFile? xFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 2048,
        maxHeight: 2048,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (xFile != null && mounted) {
        setState(() => _floorPlanImage = File(xFile.path));
      }
    } catch (e) {
      if (mounted) {
        _snack('Could not open camera: $e');
      }
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }
 
  Future<void> _placeArea(double x, double y) async {
    if (_connectMode || _selectMode) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Enter area name first');
      return;
    }
    if (_mapId == null) return;
 
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
    if (mounted) setState(() => _nameCtrl.clear());
  }
 
  void _onAreaTap(FloorAreaModel area) {
    if (_connectMode) {
      _handleConnect(area);
    } else if (_selectMode) {
      setState(() => _selectedArea = area);
      _showAreaSheet(area);
    }
  }
 
  void _handleConnect(FloorAreaModel tapped) {
    if (_connectFirst == null) {
      setState(() => _connectFirst = tapped);
      _snack('Now tap second area → "${tapped.name}"');
    } else {
      if (_connectFirst!.id == tapped.id) {
        setState(() => _connectFirst = null);
        _snack('Cannot connect to itself');
        return;
      }
      _service.connectAreas(_connectFirst!, tapped).then((_) {
        if (mounted) {
          _snack('Connected "${_connectFirst!.name}" ↔ "${tapped.name}"');
        }
      });
      setState(() => _connectFirst = null);
    }
  }
 
  void _showAreaSheet(FloorAreaModel area) {
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
          await _service.disconnectAreas(area, other);
          if (mounted) Navigator.pop(context);
        },
        onRename: (newName) async {
          await _service.saveArea(FloorAreaModel(
            id: area.id,
            mapId: area.mapId,
            name: newName,
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
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF111811),
          title: const Text('⚠ No EXIT marked',
              style: TextStyle(color: Color(0xFFFF8800))),
          content: const Text(
              'Add an Exit area so pathfinding works. Continue anyway?'),
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
 
  Widget _modeBtn(String label, IconData icon, bool active, VoidCallback fn) {
    return GestureDetector(
      onTap: fn,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFFFAA00).withAlpha(40)
              : Colors.transparent,
          border: Border.all(
              color: active
                  ? const Color(0xFFFFAA00)
                  : const Color(0xFF224422)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: active
                    ? const Color(0xFFFFAA00)
                    : const Color(0xFF556655)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: active
                        ? const Color(0xFFFFAA00)
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
        title: const Text('◆ FLOOR PLAN MODE'),
        actions: [
          TextButton.icon(
            onPressed: _finishMap,
            icon: const Icon(Icons.qr_code_2, color: Color(0xFFFFAA00)),
            label: const Text('FINISH & QR',
                style: TextStyle(
                    color: Color(0xFFFFAA00),
                    fontFamily: 'monospace',
                    fontSize: 11)),
          ),
        ],
      ),
      body: Column(
        children: [
 
          // ── Image picker bar ───────────────────────────────────
          Container(
            color: const Color(0xFF0A120A),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _floorPlanImage == null
                        ? 'No floor plan loaded — pick one below'
                        : '✓ Floor plan loaded',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: _floorPlanImage == null
                            ? const Color(0xFF556655)
                            : const Color(0xFF00FF88)),
                  ),
                ),
                // ✅ FIX: Separate buttons with clear tap targets
                _ImagePickerBtn(
                  label: 'GALLERY',
                  icon: Icons.photo_library_outlined,
                  loading: _pickingImage,
                  onTap: _pickFromGallery,
                ),
                const SizedBox(width: 8),
                _ImagePickerBtn(
                  label: 'CAMERA',
                  icon: Icons.camera_alt_outlined,
                  loading: _pickingImage,
                  onTap: _pickFromCamera,
                ),
              ],
            ),
          ),
 
          // ── Mode bar ───────────────────────────────────────────
          Container(
            color: const Color(0xFF080E08),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              ],
            ),
          ),
 
          // ── Name + type bar ────────────────────────────────────
          if (isAddMode)
            Container(
              color: const Color(0xFF0D150D),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'AREA NAME — then tap on image',
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
                    onChanged: (v) =>
                        setState(() => _selectedType = v ?? _selectedType),
                  ),
                ],
              ),
            ),
 
          // ── Connect hint ───────────────────────────────────────
          if (_connectMode)
            Container(
              color: const Color(0xFF0D150D),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _connectFirst == null
                        ? Icons.looks_one_outlined
                        : Icons.looks_two_outlined,
                    color: const Color(0xFFFFAA00),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _connectFirst == null
                          ? 'Tap first area node'
                          : 'Tap second area  ←  "${_connectFirst!.name}"',
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFFFFAA00)),
                    ),
                  ),
                ],
              ),
            ),
 
          if (_selectMode)
            Container(
              color: const Color(0xFF0D150D),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                children: [
                  Icon(Icons.touch_app, color: Color(0xFFFFAA00), size: 18),
                  SizedBox(width: 8),
                  Text('Tap any node to rename / delete / disconnect',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFFFFAA00))),
                ],
              ),
            ),
 
          // ── Canvas / image ─────────────────────────────────────
          Expanded(
            child: _floorPlanImage == null
                ? _NoImageCanvas(
                    areas: _areas,
                    selectedAreaId: _selectedArea?.id,
                    connectingAreaId: _connectFirst?.id,
                    onCanvasTap: isAddMode ? _placeArea : null,
                    onAreaTap:
                        (_connectMode || _selectMode) ? _onAreaTap : null,
                  )
                : _FloorPlanCanvas(
                    imageFile: _floorPlanImage!,
                    areas: _areas,
                    selectedAreaId: _selectedArea?.id,
                    connectingAreaId: _connectFirst?.id,
                    onCanvasTap: isAddMode ? _placeArea : null,
                    onAreaTap:
                        (_connectMode || _selectMode) ? _onAreaTap : null,
                  ),
          ),
 
          // ── Stats ──────────────────────────────────────────────
          Container(
            color: const Color(0xFF060E06),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'NODES: ${_areas.length}  ·  '
              'EXITS: ${_areas.where((a) => a.type == AppConstants.typeExit).length}  ·  '
              'LINKS: ${_areas.fold<int>(0, (s, a) => s + a.connectedAreaIds.length) ~/ 2}',
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: Color(0xFF448844)),
            ),
          ),
        ],
      ),
    );
  }
}
 
// ── Image picker button widget ────────────────────────────────────────────────
class _ImagePickerBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback onTap;
 
  const _ImagePickerBtn({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFFFAA00)),
          borderRadius: BorderRadius.circular(6),
          color: const Color(0xFFFFAA00).withAlpha(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFFAA00)))
                : Icon(icon, size: 14, color: const Color(0xFFFFAA00)),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: Color(0xFFFFAA00))),
          ],
        ),
      ),
    );
  }
}
 
// ── Canvas without image (grid only) ─────────────────────────────────────────
class _NoImageCanvas extends StatelessWidget {
  final List<FloorAreaModel> areas;
  final String? selectedAreaId;
  final String? connectingAreaId;
  final void Function(double, double)? onCanvasTap;
  final void Function(FloorAreaModel)? onAreaTap;
 
  const _NoImageCanvas({
    required this.areas,
    required this.selectedAreaId,
    required this.connectingAreaId,
    required this.onCanvasTap,
    required this.onAreaTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      const nodeR = 22.0;
 
      return GestureDetector(
        onTapUp: (d) {
          final dx = d.localPosition.dx;
          final dy = d.localPosition.dy;
          for (final area in areas) {
            if ((Offset(dx, dy) -
                        Offset(area.x * w, area.y * h))
                    .distance <=
                nodeR + 10) {
              onAreaTap?.call(area);
              return;
            }
          }
          onCanvasTap?.call(dx / w, dy / h);
        },
        child: CustomPaint(
          painter: _FPPainter(
            areas: areas,
            selectedAreaId: selectedAreaId,
            connectingAreaId: connectingAreaId,
            hasImage: false,
          ),
          child: const SizedBox.expand(),
        ),
      );
    });
  }
}
 
// ── Canvas with floor plan image ──────────────────────────────────────────────
class _FloorPlanCanvas extends StatelessWidget {
  final File imageFile;
  final List<FloorAreaModel> areas;
  final String? selectedAreaId;
  final String? connectingAreaId;
  final void Function(double, double)? onCanvasTap;
  final void Function(FloorAreaModel)? onAreaTap;
 
  const _FloorPlanCanvas({
    required this.imageFile,
    required this.areas,
    required this.selectedAreaId,
    required this.connectingAreaId,
    required this.onCanvasTap,
    required this.onAreaTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      const nodeR = 22.0;
 
      return GestureDetector(
        onTapUp: (d) {
          final dx = d.localPosition.dx;
          final dy = d.localPosition.dy;
          for (final area in areas) {
            if ((Offset(dx, dy) -
                        Offset(area.x * w, area.y * h))
                    .distance <=
                nodeR + 10) {
              onAreaTap?.call(area);
              return;
            }
          }
          onCanvasTap?.call(dx / w, dy / h);
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.file(
                imageFile,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('Could not load image',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFFFF4444))),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _FPPainter(
                  areas: areas,
                  selectedAreaId: selectedAreaId,
                  connectingAreaId: connectingAreaId,
                  hasImage: true,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
 
// ── Shared painter ────────────────────────────────────────────────────────────
class _FPPainter extends CustomPainter {
  final List<FloorAreaModel> areas;
  final String? selectedAreaId;
  final String? connectingAreaId;
  final bool hasImage;
 
  const _FPPainter({
    required this.areas,
    required this.selectedAreaId,
    required this.connectingAreaId,
    required this.hasImage,
  });
 
  Color _colorForType(String type, bool isDanger) {
    if (isDanger) return const Color(0xFFFF4444);
    switch (type) {
      case 'exit':   return const Color(0xFF00FFFF);
      case 'stair':  return const Color(0xFFFFAA00);
      case 'hall':   return const Color(0xFF0088FF);
      default:       return const Color(0xFF00FF88);
    }
  }
 
  @override
  void paint(Canvas canvas, Size size) {
    // Grid (only when no image)
    if (!hasImage) {
      final gridP = Paint()
        ..color = const Color(0xFF003322)
        ..strokeWidth = 0.5;
      for (double x = 0; x < size.width; x += size.width / 10) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridP);
      }
      for (double y = 0; y < size.height; y += size.height / 10) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridP);
      }
    }
 
    // Edges
    final edgeP = Paint()
      ..color = hasImage
          ? const Color(0xCC00FF88)
          : const Color(0xFF226622)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
 
    final Map<String, FloorAreaModel> areaMap = {
      for (final a in areas) a.id: a
    };
    final drawn = <String>{};
    for (final area in areas) {
      for (final nId in area.connectedAreaIds) {
        final key = ([area.id, nId]..sort()).join('-');
        if (drawn.contains(key)) continue;
        drawn.add(key);
        final n = areaMap[nId];
        if (n == null) continue;
        canvas.drawLine(
          Offset(area.x * size.width, area.y * size.height),
          Offset(n.x * size.width, n.y * size.height),
          edgeP,
        );
      }
    }
 
    // Nodes
    for (final area in areas) {
      final center = Offset(area.x * size.width, area.y * size.height);
      const r = 20.0;
      final color = _colorForType(area.type, area.isDanger);
      final isSelected = area.id == selectedAreaId;
      final isConnecting = area.id == connectingAreaId;
 
      // Drop shadow (especially useful over image)
      canvas.drawCircle(
          center.translate(2, 2),
          r,
          Paint()..color = Colors.black.withAlpha(120));
 
      // Selection ring
      if (isSelected) {
        canvas.drawCircle(center, r + 6,
            Paint()
              ..color = const Color(0xFF00FF88)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5);
      }
 
      // Connecting ring
      if (isConnecting) {
        canvas.drawCircle(center, r + 6,
            Paint()
              ..color = const Color(0xFFFFAA00)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5);
      }
 
      // Fill
      canvas.drawCircle(center, r, Paint()..color = color);
 
      // Border
      canvas.drawCircle(center, r,
          Paint()
            ..color = Colors.black.withAlpha(80)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
 
      // Label
      final display =
          area.name.length > 7 ? '${area.name.substring(0, 6)}…' : area.name;
      final tp = TextPainter(
        text: TextSpan(
          text: display,
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            shadows: hasImage
                ? const [Shadow(color: Colors.black, blurRadius: 6)]
                : null,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 80);
      tp.paint(canvas, center.translate(-tp.width / 2, r + 4));
    }
  }
 
  @override
  bool shouldRepaint(covariant _FPPainter old) =>
      old.areas != areas ||
      old.selectedAreaId != selectedAreaId ||
      old.connectingAreaId != connectingAreaId;
}
 
// ── Area options bottom sheet ─────────────────────────────────────────────────
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
                  color: Color(0xFFFFAA00),
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
                color: Color(0xFFFFAA00), size: 20),
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
                          color: Color(0xFFFFAA00))),
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
              area.isDanger ? 'Clear danger' : 'Mark as danger',
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