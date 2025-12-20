import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/midtrans_config.dart';

/// Lightweight Midtrans helper.
/// Usage pattern (recommended):
/// - Implement a small backend endpoint that holds the Server Key and
///   calls Midtrans to create a Snap token / charge.
/// - Mobile app calls your backend endpoint (authenticated) to get the
///   Snap token, then opens webview / Snap flow with the token.
///
/// This class includes a helper `createChargeWithServerKey` for local
/// development only. DO NOT USE the server key in production client builds.
class MidtransService {
  static final MidtransService _instance = MidtransService._internal();
  factory MidtransService() => _instance;
  MidtransService._internal();

  String get _base => MidtransConfig.apiBaseUrl;

  Map<String, String> _defaultHeaders({bool useServerKey = false}) {
    final key = useServerKey
        ? MidtransConfig.serverKey
        : MidtransConfig.clientKey;
    final auth = base64Encode(utf8.encode('$key:'));
    return {'Content-Type': 'application/json', 'Authorization': 'Basic $auth'};
  }

  /// Call your backend which returns a Snap token or redirect URL.
  /// Example backend path: POST /midtrans/create-transaction -> returns {"token":"..."}
  Future<String?> fetchSnapTokenFromBackend({
    required String backendUrl,
    required Map<String, dynamic> body,
  }) async {
    final url = Uri.parse(backendUrl);
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return json['token'] as String? ?? json['redirect_url'] as String?;
    }
    throw Exception('Backend error: ${res.statusCode} ${res.body}');
  }

  /// DEVELOPMENT ONLY: create a direct charge using Server Key from the client.
  /// This uses Midtrans `/charge` endpoint — NOT RECOMMENDED for production.
  Future<Map<String, dynamic>> createChargeWithServerKey(
    Map<String, dynamic> payload,
  ) async {
    // Intentionally avoid directly using server key in client builds.
    // Use the proper url when you fully understand the security implications.
    final properUrl = Uri.parse('$_base/charge');
    final res = await http.post(
      properUrl,
      headers: _defaultHeaders(useServerKey: true),
      body: jsonEncode(payload),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Midtrans error: ${res.statusCode} ${res.body}');
  }
}
