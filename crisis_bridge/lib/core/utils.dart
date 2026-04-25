import 'dart:convert';
import 'package:crisis_bridge/core/constants.dart';

class AppUtils {
  /// Build QR JSON payload for a map
  static String buildQrPayload({
    required String mapId,
    required String propertyId,
    required int floor,
  }) {
    final payload = {
      AppConstants.qrVersion: '1',
      AppConstants.qrMapKey: mapId,
      AppConstants.qrPropertyKey: propertyId,
      AppConstants.qrFloorKey: floor,
    };
    return jsonEncode(payload);
  }

  /// Parse QR payload back to map
  static Map<String, dynamic>? parseQrPayload(String raw) {
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (decoded.containsKey(AppConstants.qrMapKey)) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }
}