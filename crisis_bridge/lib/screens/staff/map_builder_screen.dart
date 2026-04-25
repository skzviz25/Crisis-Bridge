import 'package:crisis_bridge/core/utils.dart';
import 'package:crisis_bridge/models/floor_map_model.dart';
import 'package:crisis_bridge/providers/auth_provider.dart';
import 'package:crisis_bridge/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
// ✅ FIX: uuid import removed — not needed here (mapId comes from Firestore)

class MapBuilderScreen extends StatefulWidget {
  const MapBuilderScreen({super.key});

  @override
  State<MapBuilderScreen> createState() => _MapBuilderScreenState();
}

class _MapBuilderScreenState extends State<MapBuilderScreen> {
  final _propertyNameCtrl = TextEditingController();
  final _floorCtrl = TextEditingController(text: '1');
  bool _saving = false;

  @override
  void dispose() {
    _propertyNameCtrl.dispose();
    _floorCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final propertyName = _propertyNameCtrl.text.trim();
    final floor = int.tryParse(_floorCtrl.text.trim()) ?? 1;
    if (propertyName.isEmpty) return;

    setState(() => _saving = true);

    final auth = context.read<AuthProvider>();
    final fs = FirestoreService();

    // propertyId comes from the logged-in responder's profile
    final propertyId = auth.responder?.propertyId ?? 'unknown-property';

    // Firestore will assign the real doc ID; build QR payload with a temp
    // placeholder then update after we have the real ID
    final tempPayload = AppUtils.buildQrPayload(
      mapId: 'PENDING',
      propertyId: propertyId,
      floor: floor,
    );

    final map = FloorMapModel(
      id: '',
      propertyId: propertyId,
      propertyName: propertyName,
      floor: floor,
      createdBy: auth.user?.uid ?? '',
      qrPayload: tempPayload,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final mapId = await fs.createMap(map);

    // Now update the qrPayload with the real mapId
    final realPayload = AppUtils.buildQrPayload(
      mapId: mapId,
      propertyId: propertyId,
      floor: floor,
    );
    await fs.updateMapQrPayload(mapId, realPayload);

    if (!mounted) return;
    setState(() => _saving = false);
    context.go('/staff/map-update/$mapId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('◆ NEW MAP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _propertyNameCtrl,
              decoration:
                  const InputDecoration(labelText: 'PROPERTY NAME'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _floorCtrl,
              decoration:
                  const InputDecoration(labelText: 'FLOOR NUMBER'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _create,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('CREATE & EDIT MAP'),
            ),
          ],
        ),
      ),
    );
  }
}