import 'package:flutter_test/flutter_test.dart';
import 'package:svinobook/services/security_alert_service.dart';

void main() {
  test('starts and stops the security alert listener', () async {
    final service = SecurityAlertService();
    final port = 18080 + DateTime.now().millisecond;

    await service.startAlertListener(port: port);
    expect(SecurityAlertService.isListening, isTrue);

    await service.stopServer();
    expect(SecurityAlertService.isListening, isFalse);
  });
}
