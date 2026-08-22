import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:svinobook/models/security_alert_model.dart';
import 'package:svinobook/models/task_card_model.dart';

void main() {
  test('TaskCardModel round-trips Firestore values', () {
    final createdAt = DateTime(2026, 8, 22, 10);
    final dueDate = DateTime(2026, 8, 23, 10);
    final model = TaskCardModel.fromMap({
      'title': 'Review release',
      'description': 'Check the web build',
      'priority': 'High',
      'status': 'open',
      'assigneeId': 'user-1',
      'assigneeName': 'Alex',
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': Timestamp.fromDate(dueDate),
      'sourceMessageId': 'message-1',
      'sourceType': 'ai',
      'metadata': {'origin': 'chat'},
    }, 'task-1');
    final values = model.toMap();

    expect(model.id, 'task-1');
    expect(model.createdAt, createdAt);
    expect(model.dueDate, dueDate);
    expect(values['title'], 'Review release');
    expect(values['metadata'], {'origin': 'chat'});
  });

  test('TaskCardModel supplies defaults for incomplete data', () {
    final model = TaskCardModel.fromMap({}, 'task-2');

    expect(model.title, 'Untitled Task');
    expect(model.description, isEmpty);
    expect(model.priority, 'Medium');
    expect(model.status, 'open');
    expect(model.assigneeName, 'Unassigned');
    expect(model.metadata, isEmpty);
  });

  test('SecurityAlertModel parses and serializes DateTime values', () {
    final createdAt = DateTime(2026, 8, 22, 12);
    final model = SecurityAlertModel.fromJson({
      'title': 'Port scan',
      'description': 'A scan was detected',
      'severity': 'high',
      'source': 'Kali-Node',
      'type': 'Port_Scan',
      'createdAt': createdAt,
    });

    expect(model.title, 'Port scan');
    expect(model.createdAt, createdAt);
    expect(model.toJson()['createdAt'], createdAt.toIso8601String());
  });

  test('SecurityAlertModel applies payload defaults', () {
    final model = SecurityAlertModel.fromJson({});

    expect(model.title, 'Security Alert');
    expect(model.description, isEmpty);
    expect(model.severity, 'medium');
    expect(model.source, 'External');
    expect(model.type, 'port_scan_detected');
  });
}
