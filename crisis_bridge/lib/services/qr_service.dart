import 'dart:typed_data';
import 'package:flutter_zxing/flutter_zxing.dart';

class QrService {
  /// Encode [content] to a QR PNG and return raw bytes.
  /// Returns null if encoding fails.
  // ✅ FIX: encodeBarcode is NOT async — remove await, call synchronously
  Future<Uint8List?> encodeQr(String content) async {
    try {
      // ✅ No 'await' — zx.encodeBarcode returns Encode directly, not Future
      final Encode result = zx.encodeBarcode(
        contents: content,
        params: EncodeParams(
          format: Format.qrCode,
          width: 400,
          height: 400,
          margin: 10,
        ),
      );
      return result.data; // Uint8List? PNG bytes
    } catch (e) {
      return null;
    }
  }
}