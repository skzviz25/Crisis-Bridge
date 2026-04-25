import 'dart:async';
import 'package:crisis_bridge/models/danger_state.dart';
import 'package:crisis_bridge/models/floor_area_model.dart';
import 'package:crisis_bridge/models/floor_map_model.dart';
import 'package:crisis_bridge/services/firestore_service.dart';
import 'package:flutter/foundation.dart';

class MapProvider extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService();

  FloorMapModel? _currentMap;
  List<FloorAreaModel> _areas = [];
  List<DangerState> _dangers = [];
  bool _loading = false;

  StreamSubscription<List<FloorAreaModel>>? _areasSub;
  StreamSubscription<List<DangerState>>? _dangerSub;

  FloorMapModel? get currentMap => _currentMap;
  List<FloorAreaModel> get areas => _areas;
  List<DangerState> get dangers => _dangers;
  bool get loading => _loading;

  /// Load a map by ID and subscribe to realtime area + danger updates
  Future<void> loadMap(String mapId) async {
    _loading = true;
    notifyListeners();

    _currentMap = await _fs.getMap(mapId);

    await _areasSub?.cancel();
    await _dangerSub?.cancel();

    _areasSub = _fs.areasStream(mapId).listen((areas) {
      _areas = areas;
      notifyListeners();
    });

    _dangerSub = _fs.dangerStream(mapId).listen((dangers) {
      _dangers = dangers;
      notifyListeners();
    });

    _loading = false;
    notifyListeners();
  }

  Set<String> get dangerAreaIds => _dangers.map((d) => d.areaId).toSet();

  @override
  void dispose() {
    _areasSub?.cancel();
    _dangerSub?.cancel();
    super.dispose();
  }
}