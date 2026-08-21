import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/security_alert_model.dart';

class SecurityAlertService {
  static const List<String> supportedTypes = [
    'DDoS_Check',
    'Port_Scan',
    'port_scan_detected',
    'unauthorized_port',
    'security_alert',
  ];
  static const List<String> supportedSeverities = [
    'low',
    'medium',
    'high',
    'critical',
    'warning',
  ];

  HttpServer? _server;
  static bool _isListening = false;

  static bool get isListening => _isListening;

  Future<void> startAlertListener({int port = 8080}) async {
    if (_server != null) return;

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port, shared: true);
      _isListening = true;
      print('Security alert listener started on port $port');
    } catch (_) {
      _isListening = false;
      print('Security alert listener could not bind to port $port');
      return;
    }

    _server!.listen((request) async {
      try {
        if (request.method != 'POST') {
          request.response.statusCode = HttpStatus.methodNotAllowed;
          request.response.write(jsonEncode({'status': 'error', 'message': 'Only POST is allowed'}));
          return;
        }

        final decoded = jsonDecode(await utf8.decodeStream(request));
        if (decoded is! Map<String, dynamic>) {
          request.response.statusCode = HttpStatus.badRequest;
          request.response.write(jsonEncode({'status': 'error', 'message': 'JSON object required'}));
          return;
        }

        final alert = fromPayload(decoded);
        if (alert == null) {
          request.response.statusCode = HttpStatus.badRequest;
          request.response.write(jsonEncode({'status': 'error', 'message': 'Invalid alert payload'}));
          return;
        }

        await FirebaseFirestore.instance.collection('security_alerts').add({
          'title': alert.title,
          'description': alert.description,
          'severity': alert.severity,
          'source': alert.source ?? 'External',
          'type': alert.type ?? 'port_scan_detected',
          'createdAt': FieldValue.serverTimestamp(),
          'rawPayload': decoded,
        });

        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({'status': 'accepted'}));
      } catch (_) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.write(jsonEncode({'status': 'error', 'message': 'Bad request'}));
      } finally {
        await request.response.close();
      }
    });
  }

  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
    _isListening = false;
  }

  SecurityAlertModel? fromPayload(Map<String, dynamic> payload) {
    final title = (payload['title'] ?? payload['source'] ?? 'Security Alert').toString().trim();
    final description = (payload['description'] ?? payload['details'] ?? '').toString().trim();
    final severity = (payload['severity'] ?? payload['status'] ?? 'medium').toString().trim().toLowerCase();
    final source = (payload['source'] ?? 'External').toString().trim();
    final type = (payload['type'] ?? 'port_scan_detected').toString().trim();

    if (title.isEmpty || description.isEmpty || !supportedSeverities.contains(severity)) {
      return null;
    }
    if (!supportedTypes.contains(type)) return null;

    return SecurityAlertModel(
      title: title,
      description: description,
      severity: severity,
      source: source,
      type: type,
      createdAt: DateTime.now(),
    );
  }
}
