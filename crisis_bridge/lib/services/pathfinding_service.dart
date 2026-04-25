import 'package:collection/collection.dart';
import 'package:crisis_bridge/core/constants.dart';
import 'package:crisis_bridge/models/floor_area_model.dart';

class PathfindingService {
  /// Dijkstra's algorithm over the area graph.
  /// Danger areas have a very high cost so routes avoid them.
  List<FloorAreaModel> findSafestRoute({
    required String startId,
    required List<FloorAreaModel> areas,
    String? targetType, // defaults to 'exit'
  }) {
    final target = targetType ?? AppConstants.typeExit;

    // Build node map
    final Map<String, FloorAreaModel> nodeMap = {for (final a in areas) a.id: a};

    // Cost to reach each node
    final Map<String, double> dist = {for (final a in areas) a.id: double.infinity};
    dist[startId] = 0;

    // Previous node in optimal path
    final Map<String, String?> prev = {for (final a in areas) a.id: null};

    // Priority queue: (cost, areaId)
    final pq = PriorityQueue<_PQEntry>((a, b) => a.cost.compareTo(b.cost));
    pq.add(_PQEntry(startId, 0));

    final visited = <String>{};

    while (pq.isNotEmpty) {
      final current = pq.removeFirst();
      if (visited.contains(current.id)) continue;
      visited.add(current.id);

      final node = nodeMap[current.id];
      if (node == null) continue;

      for (final neighborId in node.connectedAreaIds) {
        final neighbor = nodeMap[neighborId];
        if (neighbor == null) continue;

        // Danger areas cost 1000x more
        final edgeCost = neighbor.isDanger ? 1000.0 : 1.0;
        final newDist = (dist[current.id] ?? double.infinity) + edgeCost;

        if (newDist < (dist[neighborId] ?? double.infinity)) {
          dist[neighborId] = newDist;
          prev[neighborId] = current.id;
          pq.add(_PQEntry(neighborId, newDist));
        }
      }
    }

    // Find nearest exit
    final exits = areas.where((a) => a.type == target).toList();
    if (exits.isEmpty) return [];

    exits.sort((a, b) => (dist[a.id] ?? double.infinity).compareTo(dist[b.id] ?? double.infinity));
    final best = exits.first;

    if (dist[best.id] == double.infinity) return [];

    // Reconstruct path
    final path = <FloorAreaModel>[];
    String? current = best.id;
    while (current != null) {
      final node = nodeMap[current];
      if (node != null) path.insert(0, node);
      current = prev[current];
    }
    return path;
  }
}

class _PQEntry {
  final String id;
  final double cost;
  const _PQEntry(this.id, this.cost);
}