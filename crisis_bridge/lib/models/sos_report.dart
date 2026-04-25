import 'package:cloud_firestore/cloud_firestore.dart';

enum SosStatus { active, acknowledged, resolved }

class SosReport {
  final String id;
  final String mapId;
  final String propertyId;
  final int floor;
  final String areaId;
  final String areaName;
  final double? latitude;
  final double? longitude;
  final String reportedBy; // uid or 'anonymous'
  final SosStatus status;
  final DateTime createdAt;

  const SosReport({
    required this.id,
    required this.mapId,
    required this.propertyId,
    required this.floor,
    required this.areaId,
    required this.areaName,
    this.latitude,
    this.longitude,
    required this.reportedBy,
    this.status = SosStatus.active,
    required this.createdAt,
  });

  factory SosReport.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SosReport(
      id: doc.id,
      mapId: d['mapId'] as String? ?? '',
      propertyId: d['propertyId'] as String? ?? '',
      floor: d['floor'] as int? ?? 1,
      areaId: d['areaId'] as String? ?? '',
      areaName: d['areaName'] as String? ?? '',
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
      reportedBy: d['reportedBy'] as String? ?? 'anonymous',
      status: SosStatus.values.firstWhere(
        (e) => e.name == (d['status'] as String? ?? 'active'),
        orElse: () => SosStatus.active,
      ),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'mapId': mapId,
        'propertyId': propertyId,
        'floor': floor,
        'areaId': areaId,
        'areaName': areaName,
        'latitude': latitude,
        'longitude': longitude,
        'reportedBy': reportedBy,
        'status': status.name,
        'createdAt': FieldValue.serverTimestamp(),
      };
}