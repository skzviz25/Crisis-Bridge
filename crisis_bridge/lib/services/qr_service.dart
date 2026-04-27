// lib/services/qr_service.dart
import 'dart:typed_data';
import 'package:flutter_zxing/flutter_zxing.dart';
 
class QrService {
  /// Encode [content] into a QR code PNG and return raw bytes.
  /// Returns null if encoding fails.
  Future<Uint8List?> encodeQr(String content) async {
    try {
      // flutter_zxing encodeBarcode is synchronous — no await needed
      final Encode result = zx.encodeBarcode(
        contents: content,
        params: EncodeParams(
          format: Format.qrCode,
          width: 512,
          height: 512,
          margin: 16,
        ),
      );
 
      // result.data is Uint8List? containing raw PNG bytes
      if (result.isValid && result.data != null && result.data!.isNotEmpty) {
        return result.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}