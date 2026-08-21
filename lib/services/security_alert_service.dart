import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/security_alert_model.dart';

class SecurityAlertService {
  static const List<String> supportedTypes = ['DDoS_Check', 'Port_Scan'];
  static const List<String> supportedStatuses = ['WARNING', 'CRITICAL'];

  static SecurityAlertModel? fromPayload(Map<String, dynamic> payload) {
    final source = (payload['source'] ?? '').toString().trim();
    final type = (payload['type'] ?? '').toString().trim();
    final status = (payload['status'] ?? '').toString().trim();
    final details = (payload['details'] ?? '').toString().trim();

    if (source.isEmpty || details.isEmpty) return null;
    if (!supportedTypes.contains(type)) return null;
    if (!supportedStatuses.contains(status)) return null;

    return SecurityAlertModel(
      source: source,
      type: type,
      status: status,
      details: details,
      createdAt: DateTime.now(),
    );
  }

  static Future<SecurityAlertModel?> handleIncomingJson(String body) async {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return fromPayload(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<http.Response> createLocalListener({
    required int port,
    required Future<void> Function(SecurityAlertModel alert) onAlert,
  }) async {
    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      port,
      shared: true,
    );

    server.listen((request) async {
      if (request.method != 'POST') {
        request.response.statusCode = 405;
        request.response.write('Only POST is supported');
        await request.response.close();
        return;
      }

      try {
        final body = await utf8.decoder.bind(request).join();
        final alert = await handleIncomingJson(body);
        if (alert != null) {
          await onAlert(alert);
          request.response.statusCode = 200;
          request.response.write(jsonEncode({'status': 'accepted'}));
        } else {
          request.response.statusCode = 400;
          request.response.write(jsonEncode({'status': 'rejected', 'reason': 'invalid-payload'}));
        }
      } catch (_) {
        request.response.statusCode = 500;
        request.response.write(jsonEncode({'status': 'error'}));
      } finally {
        await request.response.close();
      }
    });

    return http.Response(
      'accepted',
      200,
      headers: {'Content-Type': 'application/json'},
    );
  }
}
