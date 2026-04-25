import 'package:crisis_bridge/models/floor_area_model.dart';
import 'package:crisis_bridge/providers/map_provider.dart';
import 'package:crisis_bridge/services/pathfinding_service.dart';
import 'package:crisis_bridge/widgets/map_canvas.dart';
import 'package:crisis_bridge/widgets/sos_button.dart';
import 'package:crisis_bridge/widgets/nav_status_panel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ✅ FIX: sos_provider import removed (unused)

class RouteScreen extends StatefulWidget {
  final String mapId;
  const RouteScreen({super.key, required this.mapId});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final _pathfinder = PathfindingService();
  FloorAreaModel? _selectedStart;
  List<FloorAreaModel> _route = [];

  void _computeRoute(List<FloorAreaModel> areas) {
    if (_selectedStart == null || areas.isEmpty) return;
    final route = _pathfinder.findSafestRoute(
      startId: _selectedStart!.id,
      areas: areas,
    );
    setState(() => _route = route);
  }

  @override
  Widget build(BuildContext context) {
    final mapProv = context.watch<MapProvider>();
    final map = mapProv.currentMap;

    return Scaffold(
      appBar: AppBar(
        title: Text(map != null ? '◆ FLOOR ${map.floor} ROUTE' : '◆ ROUTE'),
      ),
      body: Column(
        children: [
          if (map != null)
            NavStatusPanel(
              mapId: map.id,
              areas: mapProv.areas,
              dangers: mapProv.dangers,
            ),
          if (mapProv.areas.isNotEmpty)
            Container(
              color: const Color(0xFF0D150D),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text('START:',
                      style: TextStyle(
                          fontFamily: 'monospace', fontSize: 12)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<FloorAreaModel>(
                      isExpanded: true,
                      value: _selectedStart,
                      hint: const Text('Select your area'),
                      dropdownColor: const Color(0xFF111811),
                      items: mapProv.areas
                          .map((a) => DropdownMenuItem(
                                value: a,
                                child: Text(a.name,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'monospace')),
                              ))
                          .toList(),
                      onChanged: (a) {
                        setState(() => _selectedStart = a);
                        _computeRoute(mapProv.areas);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _computeRoute(mapProv.areas),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 36),
                      textStyle: const TextStyle(fontSize: 11),
                    ),
                    child: const Text('ROUTE'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: MapCanvas(
              areas: mapProv.areas,
              dangerAreaIds: mapProv.dangerAreaIds,
              route: _route,
              onTap: null,
              onAreaLongPress: null,
            ),
          ),
          if (_route.isNotEmpty)
            Container(
              color: const Color(0xFF0D150D),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ROUTE:',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Color(0xFF00FF88))),
                  const SizedBox(height: 4),
                  Text(
                    _route.map((a) => a.name).join(' → '),
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: map != null
          ? SosButton(
              mapId: map.id,
              propertyId: map.propertyId,
              floor: map.floor,
              areas: mapProv.areas,
            )
          : null,
    );
  }
}