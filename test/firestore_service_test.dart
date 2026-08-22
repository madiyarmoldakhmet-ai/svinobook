import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:svinobook/models/security_alert_model.dart';
import 'package:svinobook/services/firestore_service.dart';
import 'package:svinobook/services/storage_service.dart';

class _StorageFake extends StorageService {
  @override
  Future<String?> uploadImage({
    required Uint8List fileBytes,
    required String folder,
    required String fileName,
  }) async => 'https://example.test/$folder/$fileName';
}

void main() {
  test('sendMessage writes message, chat metadata, and unread count', () async {
    final firestore = FakeFirebaseFirestore();
    final service = FirestoreService(firestore: firestore, storage: _StorageFake());

    await service.sendMessage(
      chatRoomId: 'alice_bob',
      text: 'Hello',
      isGroup: false,
      senderId: 'alice',
      senderName: 'Alice',
      mediaUrl: 'https://example.test/photo.jpg',
      mediaType: 'image',
    );

    final chat = await firestore.collection('chats').doc('alice_bob').get();
    final messages = await firestore.collection('chats').doc('alice_bob').collection('messages').get();
    final message = messages.docs.single.data();

    expect(messages.docs, hasLength(1));
    expect(message['text'], 'Hello');
    expect(message['type'], 'image');
    expect(message['url'], 'https://example.test/photo.jpg');
    expect(chat.data()?['lastMessage'], 'Hello');
    expect(chat.data()?['participantIds'], contains('alice'));
    expect((chat.data()?['unreadCounts'] as Map)['bob'], 1);
  });

  test('sendMessage uploads image bytes when URL is absent', () async {
    final firestore = FakeFirebaseFirestore();
    final service = FirestoreService(firestore: firestore, storage: _StorageFake());

    await service.sendMessage(
      chatRoomId: 'alice_bob',
      text: '',
      chatImageBytes: Uint8List.fromList([1, 2]),
      isGroup: false,
      senderId: 'alice',
      senderName: 'Alice',
    );

    final messages = await firestore.collection('chats').doc('alice_bob').collection('messages').get();
    final message = messages.docs.single.data();
    expect(message['type'], 'image');
    expect(message['imageUrl'], contains('chat_images/alice_bob/'));
  });

  test('getChatRoomId is deterministic', () {
    final service = FirestoreService(firestore: FakeFirebaseFirestore(), storage: _StorageFake());

    expect(service.getChatRoomId('bob', 'alice'), 'alice_bob');
  });

  test('direct message stream maps stored messages', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('chats').doc('alice_bob').collection('messages').add({
      'senderId': 'alice',
      'senderName': 'Alice',
      'text': 'Hello',
      'timestamp': Timestamp.fromDate(DateTime(2026, 8, 22)),
      'type': 'text',
    });
    final service = FirestoreService(firestore: firestore, storage: _StorageFake());

    final messages = await service.getDirectMessagesStream('alice_bob').first;

    expect(messages, hasLength(1));
    expect(messages.single.text, 'Hello');
  });

  test('chat session stream maps stored sessions', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('chats').doc('chat-1').set({
      'participantIds': ['alice', 'bob'],
      'participantNames': ['Alice', 'Bob'],
      'lastMessage': 'Hi',
      'lastUpdated': Timestamp.fromDate(DateTime(2026, 8, 22)),
    });
    final service = FirestoreService(firestore: firestore, storage: _StorageFake());

    final sessions = await service.getChatSessionsStream('alice').first;

    expect(sessions.single.id, 'chat-1');
    expect(sessions.single.lastMessage, 'Hi');
  });

  test('global chat and task streams map stored documents', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('global_chat').doc('message-1').set({
      'senderId': 'alice',
      'senderName': 'Alice',
      'text': 'Hello',
      'timestamp': Timestamp.fromDate(DateTime(2026, 8, 22)),
    });
    await firestore.collection('tasks').doc('task-1').set({
      'title': 'Review',
      'description': 'Build',
      'createdAt': Timestamp.fromDate(DateTime(2026, 8, 22)),
    });
    final service = FirestoreService(firestore: firestore, storage: _StorageFake());

    final messages = await service.getGlobalChatStream().first;
    final tasks = await service.getTasksStream().first;

    expect(messages.single.senderName, 'Alice');
    expect(tasks.single.title, 'Review');
  });

  test('security alerts and unread count are written', () async {
    final firestore = FakeFirebaseFirestore();
    final service = FirestoreService(firestore: firestore, storage: _StorageFake());
    final alert = SecurityAlertModel(
      title: 'Port scan',
      description: 'Detected',
      severity: 'high',
      source: 'Monitor',
      type: 'Port_Scan',
      createdAt: DateTime(2026, 8, 22),
    );

    await service.sendSecurityAlert(alert);
    await service.resetUnreadCount('alice_bob', 'bob');

    final alertData = (await firestore.collection('global_chat').get()).docs.single.data();
    final chatData = (await firestore.collection('chats').doc('alice_bob').get()).data();
    expect(alertData['type'], 'security_alert');
    expect(alertData['alertStatus'], 'high');
    expect((chatData?['unreadCounts'] as Map)['bob'], 0);
  });

  test('createTaskFromText ignores non-task text and creates valid tasks', () async {
    final firestore = FakeFirebaseFirestore();
    final service = FirestoreService(firestore: firestore, storage: _StorageFake());

    await service.createTaskFromText('Just a greeting');
    expect((await firestore.collection('tasks').get()).docs, isEmpty);

    await service.createTaskFromText('Create a task: Review release');
    final tasks = await firestore.collection('tasks').get();
    expect(tasks.docs, hasLength(1));
    expect(tasks.docs.single.data()['assigneeName'], 'AI Assistant');
  });
}