// lib/screens/staff/walk_mode_screen.dart
import 'dart:async';
import 'package:crisis_bridge/core/constants.dart';
import 'package:crisis_bridge/models/floor_area_model.dart';
import 'package:crisis_bridge/providers/auth_provider.dart';
import 'package:crisis_bridge/screens/staff/map_finish_screen.dart';
import 'package:crisis_bridge/services/map_builder_service.dart';
import 'package:crisis_bridge/services/location_service.dart';
import 'package:crisis_bridge/widgets/builder_map_canvas.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
 
class WalkModeScreen extends StatefulWidget {
  const WalkModeScreen({super.key});
 
  @override
  State<WalkModeScreen> createState() => _WalkModeScreenState();
}
 
class _WalkModeScreenState extends State<WalkModeScreen> {
  final _service = MapBuilderService();
  final _locationService = LocationService();
  final _nameCtrl = TextEditingController();
 
  String? _mapId;
  String _selectedType = AppConstants.typeRoom;
  bool _isInitializing = true;
  bool _isSaving = false;
  bool _isTracking = false;
 
  List<FloorAreaModel> _areas = [];
  StreamSubscription<List<FloorAreaModel>>? _areasSub;
  StreamSubscription<Position>? _positionSub;
 
  // GPS bounding box for canvas normalisation
  double? _minLat, _maxLat, _minLng, _maxLng;
  Position? _currentPosition;
  FloorAreaModel? _lastMarkedArea;
 
  // Raw GPS stored per area so we can re-normalise when bounds expand
  final Map<String, (double, double)> _rawGps = {};
 
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
 
    await _startGps();
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
 
  Future<void> _startGps() async {
    final pos = await _locationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() {
        _currentPosition = pos;
        _isTracking = true;
      });
    }
    // ✅ FIX: distanceFilter = 0 so position updates fire even for tiny movements
    // This is critical for indoor mapping where you may only move a few metres
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0, // ← update on ANY movement
      ),
    ).listen((pos) {
      if (mounted) setState(() => _currentPosition = pos);
    });
  }
 
  // GPS lat/lng → normalised canvas 0..1
  (double, double) _gpsToCanvas(double lat, double lng) {
    _minLat ??= lat;
    _maxLat ??= lat;
    _minLng ??= lng;
    _maxLng ??= lng;
 
    _minLat = _minLat! < lat ? _minLat! : lat;
    _maxLat = _maxLat! > lat ? _maxLat! : lat;
    _minLng = _minLng! < lng ? _minLng! : lng;
    _maxLng = _maxLng! > lng ? _maxLng! : lng;
 
    final latRange = (_maxLat! - _minLat!).abs();
    final lngRange = (_maxLng! - _minLng!).abs();
 
    // Single point → place at centre
    if (latRange < 0.000001 && lngRange < 0.000001) return (0.5, 0.5);
 
    final x = lngRange < 0.000001
        ? 0.5
        : 0.1 + (lng - _minLng!) / lngRange * 0.8;
    // Invert Y: north (higher lat) = top of canvas
    final y = latRange < 0.000001
        ? 0.5
        : 0.1 + (_maxLat! - lat) / latRange * 0.8;
 
    return (x.clamp(0.05, 0.95), y.clamp(0.05, 0.95));
  }
 
  // Re-save existing areas with updated positions when bounding box grows
  Future<void> _renormalizeExistingAreas() async {
    if (_mapId == null || _rawGps.isEmpty) return;
    for (final area in List.from(_areas)) {
      final gps = _rawGps[area.id];
      if (gps == null) continue;
      final (nx, ny) = _gpsToCanvas(gps.$1, gps.$2);
      if ((nx - area.x).abs() > 0.01 || (ny - area.y).abs() > 0.01) {
        await _service.saveArea(FloorAreaModel(
          id: area.id,
          mapId: area.mapId,
          name: area.name,
          type: area.type,
          x: nx,
          y: ny,
          isDanger: area.isDanger,
          connectedAreaIds: area.connectedAreaIds,
          updatedAt: DateTime.now(),
        ));
      }
    }
  }
 
  Future<void> _markCurrentArea() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Enter area name first');
      return;
    }
    if (_currentPosition == null) {
      _snack('Waiting for GPS signal…');
      return;
    }
    if (_mapId == null) return;
 
    setState(() => _isSaving = true);
 
    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;
 
    // Check if bounds will expand; re-normalise if so
    final willExpand = _areas.isNotEmpty &&
        (lat < (_minLat ?? double.infinity) ||
            lat > (_maxLat ?? double.negativeInfinity) ||
            lng < (_minLng ?? double.infinity) ||
            lng > (_maxLng ?? double.negativeInfinity));
 
    final (x, y) = _gpsToCanvas(lat, lng);
 
    if (willExpand) await _renormalizeExistingAreas();
 
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
 
    final savedId = await _service.saveArea(area);
    _rawGps[savedId] = (lat, lng);
 
    // Give Firestore stream a moment to return the saved doc
    await Future.delayed(const Duration(milliseconds: 500));
 
    final savedArea = _areas.firstWhere(
      (a) => a.id == savedId,
      orElse: () => FloorAreaModel(
        id: savedId,
        mapId: _mapId!,
        name: name,
        type: _selectedType,
        x: x,
        y: y,
        isDanger: _selectedType == AppConstants.typeDanger,
        connectedAreaIds: const [],
        updatedAt: DateTime.now(),
      ),
    );
 
    // Auto-connect to previous area
    if (_lastMarkedArea != null) {
      final prev = _areas.firstWhere(
        (a) => a.id == _lastMarkedArea!.id,
        orElse: () => _lastMarkedArea!,
      );
      await _service.connectAreas(prev, savedArea);
    }
 
    if (mounted) {
      setState(() {
        _lastMarkedArea = savedArea;
        _isSaving = false;
      });
      _nameCtrl.clear();
      _snack('✓ Marked "$name" — walk to next area');
    }
  }
 
  Future<void> _finishMap() async {
    if (_mapId == null) return;
    final exits =
        _areas.where((a) => a.type == AppConstants.typeExit).length;
    if (exits == 0) {
      final confirm = await _showNoExitWarning();
      if (confirm != true) return;
    }
    final qrPayload = await _service.finishMap(_mapId!);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MapFinishScreen(
          mapId: _mapId!,
          qrPayload: qrPayload,
          areaCount: _areas.length,
        ),
      ),
    );
  }
 
  Future<bool?> _showNoExitWarning() => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF111811),
          title: const Text('⚠ No exit marked',
              style: TextStyle(color: Color(0xFFFF8800))),
          content: const Text(
              'No Exit area marked. Users cannot find safe routes.\n\nContinue anyway?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('ADD EXIT')),
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
 
  @override
  void dispose() {
    _areasSub?.cancel();
    _positionSub?.cancel();
    _nameCtrl.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
 
    // Current position projected onto canvas
    double? curX, curY;
    if (_currentPosition != null) {
      final (cx, cy) = _gpsToCanvas(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      curX = cx;
      curY = cy;
    }
 
    return Scaffold(
      appBar: AppBar(
        title: const Text('◆ WALK MODE'),
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
 
          // ── GPS status bar ─────────────────────────────────────
          Container(
            color: const Color(0xFF0A120A),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  _isTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
                  color: _isTracking
                      ? const Color(0xFF00FF88)
                      : const Color(0xFFFF4444),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentPosition == null
                        ? 'Acquiring GPS…'
                        : '${_currentPosition!.latitude.toStringAsFixed(5)}, '
                          '${_currentPosition!.longitude.toStringAsFixed(5)}  '
                          '±${_currentPosition!.accuracy.toStringAsFixed(0)}m',
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Color(0xFF88AA88)),
                  ),
                ),
                Text('AREAS: ${_areas.length}',
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Color(0xFF00FF88))),
              ],
            ),
          ),
 
          // ── Last marked indicator ──────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            color: const Color(0xFF060E06),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Icon(
                  _lastMarkedArea != null
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: _lastMarkedArea != null
                      ? const Color(0xFF00AA66)
                      : const Color(0xFF335533),
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _lastMarkedArea == null
                        ? 'Mark your first area below'
                        : 'Last: "${_lastMarkedArea!.name}" → walk to next spot',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: _lastMarkedArea != null
                            ? const Color(0xFF00AA66)
                            : const Color(0xFF335533)),
                  ),
                ),
                // Break chain button — inline, small, no row overflow
                if (_lastMarkedArea != null)
                  GestureDetector(
                    onTap: () => setState(() => _lastMarkedArea = null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF444444)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('BREAK CHAIN',
                          style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9,
                              color: Color(0xFF888888))),
                    ),
                  ),
              ],
            ),
          ),
 
          // ── Name input + type ──────────────────────────────────
          Container(
            color: const Color(0xFF0D150D),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'AREA NAME',
                      hintText: 'e.g. Room 101, Hall A, Stairwell',
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
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                      color: _typeColor(t),
                                      shape: BoxShape.circle),
                                ),
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
 
          // ── Map canvas ─────────────────────────────────────────
          Expanded(
            child: BuilderMapCanvas(
              areas: _areas,
              dangerAreaIds: _areas
                  .where((a) => a.isDanger)
                  .map((a) => a.id)
                  .toSet(),
              selectedAreaId: _lastMarkedArea?.id,
              connectingAreaId: null,
              showCurrentPosition: _currentPosition != null,
              currentPosX: curX,
              currentPosY: curY,
              onCanvasTap: null, // walk mode: no tap-to-place
              onAreaTap: (area) {
                setState(() => _lastMarkedArea = area);
                _snack('Selected "${area.name}" — next mark connects here');
              },
            ),
          ),
 
          // ── MARK AREA button — always full width, always visible ─
          // ✅ FIX: Removed the Row with BREAK CHAIN that was pushing button
          //         off screen. BREAK CHAIN is now in the status bar above.
          Container(
            color: const Color(0xFF0A0F0A),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _markCurrentArea,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.add_location_alt, size: 22),
              label: Text(
                _isSaving ? 'SAVING…' : 'MARK AREA HERE',
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 2),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF88),
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
 
          // ── Stats bar ──────────────────────────────────────────
          Container(
            color: const Color(0xFF060E06),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NODES: ${_areas.length}  '
                  'EXITS: ${_areas.where((a) => a.type == AppConstants.typeExit).length}  '
                  'DANGERS: ${_areas.where((a) => a.isDanger).length}',
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
        title: const Text('◆ WALK MODE GUIDE',
            style: TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFF00FF88),
                fontSize: 13)),
        content: const SingleChildScrollView(
          child: Text(
            'HOW TO MAP YOUR BUILDING:\n\n'
            '1. Stand in the first area (e.g. Reception)\n'
            '2. Type its name, select the type\n'
            '3. Press MARK AREA HERE\n\n'
            '4. Walk a few steps to the next area\n'
            '   (can be as close as 1-2 metres)\n'
            '5. Type its name and press MARK AREA HERE\n'
            '   ↳ A connection is auto-drawn between them\n\n'
            'BREAK CHAIN — tap to stop auto-connecting.\n'
            'Use this to start a new branch of the map.\n\n'
            'TAP any existing node on the canvas to\n'
            're-select it as the starting point for\n'
            'the next connection.\n\n'
            'TIPS:\n'
            '• You can mark areas even 1m apart\n'
            '• Mark at least one EXIT area\n'
            '• Mark fire/flood areas as Danger type\n'
            '• GPS accuracy shown in top bar\n'
            '  (lower = better; < 5m is ideal indoors)',
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