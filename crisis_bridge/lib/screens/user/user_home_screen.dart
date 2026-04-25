import 'package:crisis_bridge/providers/map_provider.dart';
import 'package:crisis_bridge/widgets/nav_status_panel.dart';
import 'package:crisis_bridge/widgets/map_canvas.dart';
import 'package:crisis_bridge/widgets/sos_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mapProv = context.watch<MapProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('◆ CRISIS BRIDGE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan QR',
            onPressed: () => context.go('/user/scan'),
          ),
        ],
      ),
      body: mapProv.currentMap == null
          ? _NoMapView()
          : Column(
              children: [
                NavStatusPanel(
                  mapId: mapProv.currentMap!.id,
                  areas: mapProv.areas,
                  dangers: mapProv.dangers,
                ),
                Expanded(
                  child: MapCanvas(
                    areas: mapProv.areas,
                    dangerAreaIds: mapProv.dangerAreaIds,
                    route: const [],
                    onTap: null,
                    onAreaLongPress: null,
                  ),
                ),
              ],
            ),
      floatingActionButton: mapProv.currentMap != null
          ? SosButton(
              mapId: mapProv.currentMap!.id,
              propertyId: mapProv.currentMap!.propertyId,
              floor: mapProv.currentMap!.floor,
              areas: mapProv.areas,
            )
          : null,
    );
  }
}

class _NoMapView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code_scanner, size: 80, color: Color(0xFF335544)),
          const SizedBox(height: 24),
          Text(
            'SCAN A QR CODE\nTO LOAD YOUR MAP',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.go('/user/scan'),
            icon: const Icon(Icons.qr_code_2),
            label: const Text('SCAN NOW'),
          ),
        ],
      ),
    );
  }
}