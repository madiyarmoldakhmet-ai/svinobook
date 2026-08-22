import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:svinobook/models/security_alert_model.dart';
import 'package:svinobook/models/task_card_model.dart';
import 'package:svinobook/models/chat_message_model.dart';
import 'package:svinobook/models/chat_session_model.dart';
import 'package:svinobook/models/post_model.dart';
import 'package:svinobook/models/user_model.dart';

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

  test('ChatMessageModel parses media and serializes it', () {
    final timestamp = DateTime(2026, 8, 22);
    final model = ChatMessageModel.fromMap({
      'senderId': 'alice',
      'senderName': 'Alice',
      'text': 'Photo',
      'imageUrl': 'https://example.test/photo.jpg',
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': true,
      'isGroup': false,
      'chatRoomId': 'alice_bob',
      'type': 'image',
      'alertType': 'security_alert',
      'alertStatus': 'high',
      'alertDetails': 'Details',
      'alertSource': 'Monitor',
    }, 'message-1');

    expect(model.id, 'message-1');
    expect(model.url, 'https://example.test/photo.jpg');
    expect(model.toMap()['type'], 'image');
    expect(model.toMap()['isRead'], isTrue);
  });

  test('ChatMessageModel uses defaults for text messages', () {
    final model = ChatMessageModel.fromMap({}, 'message-2');

    expect(model.senderName, 'Unknown');
    expect(model.type, 'text');
    expect(model.isGroup, isFalse);
  });

  test('ChatSessionModel round-trips participants', () {
    final updated = DateTime(2026, 8, 22, 14);
    final model = ChatSessionModel.fromMap({
      'participantIds': ['alice', 'bob'],
      'participantNames': ['Alice', 'Bob'],
      'lastMessage': 'See you',
      'lastUpdated': Timestamp.fromDate(updated),
    }, 'chat-1');

    expect(model.participantIds, ['alice', 'bob']);
    expect(model.lastMessage, 'See you');
    expect(model.toMap()['participantNames'], ['Alice', 'Bob']);
  });

  test('PostModel supports legacy field names', () {
    final created = DateTime(2026, 8, 22);
    final model = PostModel.fromMap({
      'authorId': 'alice',
      'authorName': 'Alice',
      'content': 'Hello',
      'createdAt': Timestamp.fromDate(created),
    }, 'post-1');

    expect(model.authorId, 'alice');
    expect(model.authorName, 'Alice');
    expect(model.content, 'Hello');
    expect(model.createdAt, created);
    expect(model.likes, 0);
    expect(model.toMap()['text'], 'Hello');
  });

  test('UserModel supports legacy getters and serialization', () {
    final model = UserModel.fromMap({
      'username': 'Alice',
      'email': 'alice@example.test',
      'photoUrl': 'https://example.test/alice.jpg',
    }, 'alice');

    expect(model.uid, 'alice');
    expect(model.username, 'Alice');
    expect(model.email, 'alice@example.test');
    expect(model.toMap()['photoUrl'], contains('alice.jpg'));
  });
}
