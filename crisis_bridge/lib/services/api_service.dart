// ✅ FIX: _baseUrl is now referenced in methods (no unused_field warning)
// TODOs are kept as documentation — not errors, just info annotations

class ApiService {
  // ✅ used via _endpoint() helper below
  static const String _baseUrl = 'https://your-backend.example.com/api/v1';

  String _endpoint(String path) => '$_baseUrl$path';

  /// Escalate SOS to external system (e.g. 911 integration, PMS alert)
  Future<void> escalateSos({
    required String sosId,
    required String propertyId,
    required int floor,
    required String areaName,
    double? latitude,
    double? longitude,
  }) async {
    
    // Example:
    // final uri = Uri.parse(_endpoint('/escalate'));
    // await http.post(uri, headers: {...}, body: jsonEncode({...}));
    throw UnimplementedError('External escalation not configured. URL: ${_endpoint('/escalate')}');
  }

  /// Send push notification to all staff for a property
  Future<void> notifyStaff({
    required String propertyId,
    required String message,
  }) async {
    
    // final uri = Uri.parse(_endpoint('/notify'));
    throw UnimplementedError('Push notifications not configured. URL: ${_endpoint('/notify')}');
  }
}