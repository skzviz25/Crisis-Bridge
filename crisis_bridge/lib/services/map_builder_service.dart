// lib/services/map_builder_service.dart
// ✅ FIX: Removed unused dart:convert and constants.dart imports
import 'package:crisis_bridge/core/utils.dart';
import 'package:crisis_bridge/models/floor_area_model.dart';
import 'package:crisis_bridge/models/floor_map_model.dart';
import 'package:crisis_bridge/services/firestore_service.dart';

class MapBuilderService {
  final FirestoreService _fs = FirestoreService();

  Future<String> createEmptyMap({
    required String propertyId,
    required String propertyName,
    required int floor,
    required String createdBy,
  }) async {
    final tempPayload = AppUtils.buildQrPayload(
      mapId: 'PENDING',
      propertyId: propertyId,
      floor: floor,
    );
    final map = FloorMapModel(
      id: '',
      propertyId: propertyId,
      propertyName: propertyName,
      floor: floor,
      createdBy: createdBy,
      qrPayload: tempPayload,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final mapId = await _fs.createMap(map);
    final realPayload = AppUtils.buildQrPayload(
      mapId: mapId,
      propertyId: propertyId,
      floor: floor,
    );
    await _fs.updateMapQrPayload(mapId, realPayload);
    return mapId;
  }

  Future<String> saveArea(FloorAreaModel area) async {
    return _fs.upsertArea(area);
  }

  Future<void> connectAreas(FloorAreaModel a, FloorAreaModel b) async {
    final aConns = List<String>.from(a.connectedAreaIds);
    final bConns = List<String>.from(b.connectedAreaIds);
    if (!aConns.contains(b.id)) aConns.add(b.id);
    if (!bConns.contains(a.id)) bConns.add(a.id);
    await _fs.upsertArea(a.copyWith(connectedAreaIds: aConns));
    await _fs.upsertArea(b.copyWith(connectedAreaIds: bConns));
  }

  Future<void> disconnectAreas(FloorAreaModel a, FloorAreaModel b) async {
    final aConns = List<String>.from(a.connectedAreaIds)..remove(b.id);
    final bConns = List<String>.from(b.connectedAreaIds)..remove(a.id);
    await _fs.upsertArea(a.copyWith(connectedAreaIds: aConns));
    await _fs.upsertArea(b.copyWith(connectedAreaIds: bConns));
  }

  Future<void> deleteArea(
      String mapId, FloorAreaModel area, List<FloorAreaModel> allAreas) async {
    await _fs.deleteArea(mapId, area.id);
    for (final other in allAreas) {
      if (other.connectedAreaIds.contains(area.id)) {
        await _fs.upsertArea(other.copyWith(
          connectedAreaIds:
              List<String>.from(other.connectedAreaIds)..remove(area.id),
        ));
      }
    }
  }

  Future<String> finishMap(String mapId) async {
    final map = await _fs.getMap(mapId);
    return map?.qrPayload ?? '';
  }

  Stream<List<FloorAreaModel>> areasStream(String mapId) {
    return _fs.areasStream(mapId);
  }
}