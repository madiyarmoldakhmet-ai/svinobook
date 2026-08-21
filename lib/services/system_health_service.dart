import 'dart:async';

import '../services/firestore_service.dart';

class ServiceHealthCheck {
  final String name;
  final Future<bool> Function() check;

  const ServiceHealthCheck({required this.name, required this.check});
}

class SystemHealthService {
  final FirestoreService _firestore;
  Timer? _timer;

  SystemHealthService(this._firestore);

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => runChecks());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> runChecks() async {
    final checks = [
      ServiceHealthCheck(
        name: 'Qwen local engine',
        check: () async => true,
      ),
      ServiceHealthCheck(
        name: 'Firebase auth',
        check: () async => true,
      ),
      ServiceHealthCheck(
        name: 'Messaging sync',
        check: () async => true,
      ),
    ];

    final failing = <String>[];
    for (final check in checks) {
      try {
        final healthy = await check.check();
        if (!healthy) {
          failing.add(check.name);
        }
      } catch (_) {
        failing.add(check.name);
      }
    }

    if (failing.isNotEmpty) {
      await _firestore.sendGlobalMessage(
        'system_monitor',
        'System Monitor',
        '🚨 Health alert: ${failing.join(', ')} reported offline or degraded.',
      );
    }
  }
}
