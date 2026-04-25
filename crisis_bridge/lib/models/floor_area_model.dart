import 'package:cloud_firestore/cloud_firestore.dart';

class FloorAreaModel {
  final String id;
  final String mapId;
  final String name;
  final String type; // room | hall | stair | exit | danger
  final double x; // 0.0–1.0 normalized canvas position
  final double y;
  final bool isDanger;
  final List<String> connectedAreaIds; // adjacency list for pathfinding
  final DateTime updatedAt;

  const FloorAreaModel({
    required this.id,
    required this.mapId,
    required this.name,
    required this.type,
    required this.x,
    required this.y,
    this.isDanger = false,
    this.connectedAreaIds = const [],
    required this.updatedAt,
  });

  factory FloorAreaModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FloorAreaModel(
      id: doc.id,
      mapId: d['mapId'] as String? ?? '',
      name: d['name'] as String? ?? '',
      type: d['type'] as String? ?? 'room',
      x: (d['x'] as num?)?.toDouble() ?? 0.0,
      y: (d['y'] as num?)?.toDouble() ?? 0.0,
      isDanger: d['isDanger'] as bool? ?? false,
      connectedAreaIds: List<String>.from(d['connectedAreaIds'] as List? ?? []),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'mapId': mapId,
        'name': name,
        'type': type,
        'x': x,
        'y': y,
        'isDanger': isDanger,
        'connectedAreaIds': connectedAreaIds,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  FloorAreaModel copyWith({
    String? name,
    String? type,
    double? x,
    double? y,
    bool? isDanger,
    List<String>? connectedAreaIds,
  }) {
    return FloorAreaModel(
      id: id,
      mapId: mapId,
      name: name ?? this.name,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      isDanger: isDanger ?? this.isDanger,
      connectedAreaIds: connectedAreaIds ?? this.connectedAreaIds,
      updatedAt: DateTime.now(),
    );
  }
}