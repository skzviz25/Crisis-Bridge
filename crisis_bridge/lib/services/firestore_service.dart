import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crisis_bridge/core/constants.dart';
import 'package:crisis_bridge/models/danger_state.dart';
import 'package:crisis_bridge/models/floor_area_model.dart';
import 'package:crisis_bridge/models/floor_map_model.dart';
import 'package:crisis_bridge/models/responder.dart';
import 'package:crisis_bridge/models/sos_report.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Maps ──────────────────────────────────────────────────────────────────

  Future<String> createMap(FloorMapModel map) async {
    final ref =
        await _db.collection(AppConstants.mapsCollection).add(map.toJson());
    return ref.id;
  }

  Stream<List<FloorMapModel>> mapsStream(String propertyId) {
    return _db
        .collection(AppConstants.mapsCollection)
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('floor')
        .snapshots()
        .map((s) => s.docs.map(FloorMapModel.fromDoc).toList());
  }

  Future<FloorMapModel?> getMap(String mapId) async {
    final doc =
        await _db.collection(AppConstants.mapsCollection).doc(mapId).get();
    if (!doc.exists) return null;
    return FloorMapModel.fromDoc(doc);
  }

  // ── Areas ─────────────────────────────────────────────────────────────────

  Future<String> upsertArea(FloorAreaModel area) async {
    final col = _db
        .collection(AppConstants.mapsCollection)
        .doc(area.mapId)
        .collection(AppConstants.areasCollection);
    if (area.id.isEmpty) {
      final ref = await col.add(area.toJson());
      return ref.id;
    } else {
      await col.doc(area.id).set(area.toJson(), SetOptions(merge: true));
      return area.id;
    }
  }

  Future<void> deleteArea(String mapId, String areaId) async {
    await _db
        .collection(AppConstants.mapsCollection)
        .doc(mapId)
        .collection(AppConstants.areasCollection)
        .doc(areaId)
        .delete();
  }

  Stream<List<FloorAreaModel>> areasStream(String mapId) {
    return _db
        .collection(AppConstants.mapsCollection)
        .doc(mapId)
        .collection(AppConstants.areasCollection)
        .snapshots()
        .map((s) => s.docs.map(FloorAreaModel.fromDoc).toList());
  }

  // ── Danger States ─────────────────────────────────────────────────────────

  Future<void> setDanger(DangerState state) async {
    await _db
        .collection(AppConstants.dangerCollection)
        .doc('${state.mapId}_${state.areaId}')
        .set(state.toJson(), SetOptions(merge: true));
  }

  Stream<List<DangerState>> dangerStream(String mapId) {
    return _db
        .collection(AppConstants.dangerCollection)
        .where('mapId', isEqualTo: mapId)
        .where('active', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map(DangerState.fromDoc).toList());
  }

  // ── SOS ───────────────────────────────────────────────────────────────────

  Future<String> sendSos(SosReport report) async {
    final ref =
        await _db.collection(AppConstants.sosCollection).add(report.toJson());
    return ref.id;
  }

  Stream<List<SosReport>> activeSosStream(String propertyId) {
    return _db
        .collection(AppConstants.sosCollection)
        .where('propertyId', isEqualTo: propertyId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(SosReport.fromDoc).toList());
  }

  Future<void> updateSosStatus(String sosId, SosStatus status) async {
    await _db.collection(AppConstants.sosCollection).doc(sosId).update({
      'status': status.name,
    });
  }

  // ── Responders ────────────────────────────────────────────────────────────

  Future<void> saveResponder(Responder responder) async {
    await _db
        .collection(AppConstants.respondersCollection)
        .doc(responder.uid)
        .set(responder.toJson(), SetOptions(merge: true));
  }

  Future<Responder?> getResponder(String uid) async {
    final doc =
        await _db.collection(AppConstants.respondersCollection).doc(uid).get();
    if (!doc.exists) return null;
    return Responder.fromDoc(doc);
  }

  Future<void> updateMapQrPayload(String mapId, String qrPayload) async {
    await _db.collection(AppConstants.mapsCollection).doc(mapId).update({
      'qrPayload': qrPayload,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
