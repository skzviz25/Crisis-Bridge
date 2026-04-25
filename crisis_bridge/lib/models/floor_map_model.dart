import 'package:cloud_firestore/cloud_firestore.dart';

class FloorMapModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final int floor;
  final String createdBy; // uid
  final String qrPayload;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FloorMapModel({
    required this.id,
    required this.propertyId,
    required this.propertyName,
    required this.floor,
    required this.createdBy,
    required this.qrPayload,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FloorMapModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FloorMapModel(
      id: doc.id,
      propertyId: d['propertyId'] as String? ?? '',
      propertyName: d['propertyName'] as String? ?? '',
      floor: d['floor'] as int? ?? 1,
      createdBy: d['createdBy'] as String? ?? '',
      qrPayload: d['qrPayload'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'propertyId': propertyId,
        'propertyName': propertyName,
        'floor': floor,
        'createdBy': createdBy,
        'qrPayload': qrPayload,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}