import 'package:crisis_bridge/providers/auth_provider.dart';
import 'package:crisis_bridge/services/firestore_service.dart';
import 'package:crisis_bridge/models/floor_map_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class StaffHomeScreen extends StatelessWidget {
  const StaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final propertyId = auth.responder?.propertyId ?? '';
    final fs = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('◆ STAFF HQ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded),
            tooltip: 'Incidents',
            onPressed: () => context.go('/staff/incidents'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/staff/map-builder'),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('NEW MAP'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.black,
      ),
      body: propertyId.isEmpty
          ? const Center(child: Text('No property assigned'))
          : StreamBuilder<List<FloorMapModel>>(
              stream: fs.mapsStream(propertyId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final maps = snapshot.data ?? [];
                if (maps.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.map_outlined, size: 64, color: Color(0xFF335544)),
                        const SizedBox(height: 16),
                        Text('No maps yet', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        const Text('Tap + to create your first floor map'),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: maps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final map = maps[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.layers_outlined),
                        title: Text('${map.propertyName} — Floor ${map.floor}'),
                        subtitle: Text(map.id, style: const TextStyle(fontSize: 10)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => context.go('/staff/map-update/${map.id}'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.qr_code_2),
                              onPressed: () => _showQr(context, map),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  void _showQr(BuildContext context, FloorMapModel map) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('QR — Floor ${map.floor}'),
        content: SizedBox(
          width: 250,
          height: 250,
          child: _QrPreview(payload: map.qrPayload),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
        ],
      ),
    );
  }
}

class _QrPreview extends StatefulWidget {
  final String payload;
  const _QrPreview({required this.payload});

  @override
  State<_QrPreview> createState() => _QrPreviewState();
}

class _QrPreviewState extends State<_QrPreview> {
  @override
  Widget build(BuildContext context) {
    // flutter_zxing encode widget
    return FutureBuilder(
      future: Future.value(widget.payload),
      builder: (context, snapshot) {
        return Center(
          child: Text(
            'QR: ${widget.payload}',
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
          // In production replace with:
          // ZxingWidget(data: widget.payload, format: Format.qrCode)
        );
      },
    );
  }
}