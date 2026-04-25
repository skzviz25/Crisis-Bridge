import 'package:crisis_bridge/models/floor_area_model.dart';
import 'package:crisis_bridge/models/floor_map_model.dart';
import 'package:crisis_bridge/models/danger_state.dart';
import 'package:crisis_bridge/services/firestore_service.dart';

/// SyncService wraps FirestoreService and exposes combined stream helpers
/// for screens that need map + areas + dangers together.
class SyncService {
  final FirestoreService _fs;

  SyncService(this._fs);

  Stream<List<FloorMapModel>> propertyMapsStream(String propertyId) {
    return _fs.mapsStream(propertyId);
  }

  Stream<List<FloorAreaModel>> mapAreasStream(String mapId) {
    return _fs.areasStream(mapId);
  }

  Stream<List<DangerState>> mapDangerStream(String mapId) {
    return _fs.dangerStream(mapId);
  }
}