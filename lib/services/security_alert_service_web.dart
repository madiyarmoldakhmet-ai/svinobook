import '../models/security_alert_model.dart';

class SecurityAlertService {
  static bool get isListening => false;

  Future<void> startAlertListener({int port = 8080}) async {}

  Future<void> stopServer() async {}

  SecurityAlertModel? fromPayload(Map<String, dynamic> payload) {
    return null;
  }
}
