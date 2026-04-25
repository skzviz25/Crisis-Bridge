import 'package:cloud_firestore/cloud_firestore.dart';

class DangerState {
  final String id;
  final String mapId;
  final String areaId;
  final String areaName;
  final bool active;
  final String setBy; // uid
  final DateTime updatedAt;

  const DangerState({
    required this.id,
    required this.mapId,
    required this.areaId,
    required this.areaName,
    required this.active,
    required this.setBy,
    required this.updatedAt,
  });

  factory DangerState.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DangerState(
      id: doc.id,
      mapId: d['mapId'] as String? ?? '',
      areaId: d['areaId'] as String? ?? '',
      areaName: d['areaName'] as String? ?? '',
      active: d['active'] as bool? ?? false,
      setBy: d['setBy'] as String? ?? '',
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'mapId': mapId,
        'areaId': areaId,
        'areaName': areaName,
        'active': active,
        'setBy': setBy,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}