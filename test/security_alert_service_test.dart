import 'package:flutter_test/flutter_test.dart';
import 'package:svinobook/services/security_alert_service.dart';

void main() {
  group('SecurityAlertService', () {
    final service = SecurityAlertService();

    test('parses Kali security alert payload', () {
      final payload = {
        'source': 'Kali-Node',
        'type': 'DDoS_Check',
        'status': 'CRITICAL',
        'details': 'SYN flood detected on public gateway.',
      };

      final alert = service.fromPayload(payload);
      expect(alert, isNotNull);
      expect(alert!.source, 'Kali-Node');
      expect(alert.type, 'DDoS_Check');
      expect(alert.severity, 'critical');
      expect(alert.description, contains('SYN flood'));
    });

    test('returns null for invalid payload', () {
      final alert = service.fromPayload({
        'source': '',
        'type': 'Unknown',
      });
      expect(alert, isNull);
    });
  });
}
