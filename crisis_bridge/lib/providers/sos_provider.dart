import 'package:crisis_bridge/models/sos_report.dart';
import 'package:crisis_bridge/services/firestore_service.dart';
import 'package:crisis_bridge/services/location_service.dart';
import 'package:flutter/foundation.dart';

class SosProvider extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService();
  final LocationService _loc = LocationService();

  bool _sending = false;
  String? _lastSosId;
  String? _error;

  bool get sending => _sending;
  String? get lastSosId => _lastSosId;
  String? get error => _error;

  Future<bool> sendSos({
    required String mapId,
    required String propertyId,
    required int floor,
    required String areaId,
    required String areaName,
    required String userId,
  }) async {
    _sending = true;
    _error = null;
    notifyListeners();

    try {
      final pos = await _loc.getCurrentPosition();
      final report = SosReport(
        id: '',
        mapId: mapId,
        propertyId: propertyId,
        floor: floor,
        areaId: areaId,
        areaName: areaName,
        latitude: pos?.latitude,
        longitude: pos?.longitude,
        reportedBy: userId,
        status: SosStatus.active,
        createdAt: DateTime.now(),
      );
      _lastSosId = await _fs.sendSos(report);
      _sending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _sending = false;
      notifyListeners();
      return false;
    }
  }
}