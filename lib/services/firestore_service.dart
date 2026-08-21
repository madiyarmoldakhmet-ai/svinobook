import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';
import '../models/security_alert_model.dart';
import '../models/task_card_model.dart';
import '../services/ai_agent_service.dart';
import 'storage_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final StorageService _storage = StorageService();

  // --- Profile / Users ---
  Future<void> updateProfile({
    required String name,
    Uint8List? avatarBytes,
    String? chatBackgroundUrl,
    String? status,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    String? photoUrl;
    if (avatarBytes != null) {
      final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      photoUrl = await _storage.uploadImage(
        fileBytes: avatarBytes,
        folder: 'avatars',
        fileName: fileName,
      );
    }

    final Map<String, dynamic> updateData = {
      'name': name,
    };
    if (photoUrl != null) {
      updateData['photoUrl'] = photoUrl;
    }
    if (chatBackgroundUrl != null) {
      updateData['chatBackgroundUrl'] = chatBackgroundUrl;
    }
    if (status != null) {
      updateData['status'] = status;
    }

    await _db.collection('users').doc(user.uid).update(updateData);
  }

  // --- Posts ---
  Stream<List<PostModel>> getPostsStream() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // New media-compatible createPost
  Future<void> createPost({required String text, Uint8List? postImageBytes}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Fetch user details from Firestore
    final userDoc = await _db.collection('users').doc(user.uid).get();
    String userName = user.email?.split('@')[0] ?? 'User';
    String? userPhotoUrl;
    if (userDoc.exists) {
      final userData = userDoc.data();
      if (userData != null) {
        userName = userData['name'] ?? userData['username'] ?? userName;
        userPhotoUrl = userData['photoUrl'];
      }
    }

    String? imageUrl;
    if (postImageBytes != null) {
      final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      imageUrl = await _storage.uploadImage(
        fileBytes: postImageBytes,
        folder: 'posts',
        fileName: fileName,
      );
    }

    final postRef = _db.collection('posts').doc();
    final newPost = PostModel(
      id: postRef.id,
      userId: user.uid,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      text: text,
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
    );

    // Write to set the new document
    final data = newPost.toMap();
    data['createdAt'] = FieldValue.serverTimestamp(); // For backward compatibility with queries
    await postRef.set(data);
  }

  // Legacy createPost method (with 3 arguments) for backward compatibility
  Future<void> legacyCreatePost(String authorId, String authorName, String content) async {
    await _db.collection('posts').add({
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'likes': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- Global Chat ---
  Stream<List<ChatMessageModel>> getGlobalChatStream() {
    return _db
        .collection('global_chat')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> sendGlobalMessage(String senderId, String senderName, String text, [Uint8List? chatImageBytes]) async {
    String? imageUrl;
    if (chatImageBytes != null) {
      final fileName = '${senderId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      imageUrl = await _storage.uploadImage(
        fileBytes: chatImageBytes,
        folder: 'chats',
        fileName: fileName,
      );
    }

    final messageRef = await _db.collection('global_chat').add({
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'type': imageUrl != null ? 'image' : 'text',
      'alertType': null,
      'alertStatus': null,
    });

    final task = await AiAgentService.parseTaskFromTextAsync(text);
    if (task != null) {
      final taskRef = _db.collection('tasks').doc();
      await taskRef.set({
        ...task.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'sourceMessageId': messageRef.id,
        'sourceType': 'ai',
      });
    }
  }

  Future<void> sendSecurityAlert(SecurityAlertModel alert) async {
    await _db.collection('global_chat').add({
      'senderId': 'security_agent',
      'senderName': 'Security Agent',
      'text': '${alert.type} • ${alert.status}\n${alert.details}',
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'security_alert',
      'alertType': alert.type,
      'alertStatus': alert.status,
      'alertDetails': alert.details,
      'alertSource': alert.source,
    });
  }

  // --- Direct & Group Messages ---
  Stream<List<ChatSessionModel>> getChatSessionsStream(String currentUserId) {
    return _db
        .collection('chats')
        .where('participantIds', arrayContains: currentUserId)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatSessionModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<ChatMessageModel>> getDirectMessagesStream(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }



  // Determine deterministic chat room ID for 1:1 chats
  String getChatRoomId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Send a message (direct or group) with optional image
  Future<void> sendMessage({
    required String chatRoomId,
    required String text,
    Uint8List? chatImageBytes,
    required bool isGroup,
    required String senderId,
    required String senderName,
  }) async {
    // Determine the other participant's ID for direct chats
    String? otherUserId;
    if (!isGroup) {
      final parts = chatRoomId.split('_');
      if (parts.length == 2) {
        otherUserId = parts[0] == senderId ? parts[1] : parts[0];
      }
    }
    String? imageUrl;
    if (chatImageBytes != null) {
      final timestampStr = DateTime.now().millisecondsSinceEpoch.toString();
      imageUrl = await _storage.uploadImage(
        fileBytes: chatImageBytes,
        folder: 'chat_images/$chatRoomId/$timestampStr',
        fileName: 'image.jpg',
      );
    }

    final chatRef = _db.collection(isGroup ? 'group_chats' : 'chats').doc(chatRoomId);
    final messageRef = chatRef.collection('messages').doc();
    final batch = _db.batch();
    batch.set(messageRef, {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': imageUrl != null ? 'image' : 'text',
    });
    // Increment unread count for recipient in direct chats
    if (!isGroup && otherUserId != null) {
      batch.set(chatRef, {
        'unreadCounts': {
          otherUserId: FieldValue.increment(1),
        },
      }, SetOptions(merge: true));
    }
    // Update last message metadata
    batch.set(chatRef, {
      'lastMessage': text,
      'lastUpdated': FieldValue.serverTimestamp(),
      'participantIds': FieldValue.arrayUnion([senderId]),
      'participantNames': FieldValue.arrayUnion([senderName]),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  // Reset unread count for a user in a chat
  Future<void> resetUnreadCount(String chatId, String currentUserId) async {
    await _db.collection('chats').doc(chatId).set({
      'unreadCounts': {
        currentUserId: 0,
      },
    }, SetOptions(merge: true));
  }

  // --- Task cards ---
  Stream<List<TaskCardModel>> getTasksStream() {
    return _db
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskCardModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> createTaskFromText(String rawText, {String assigneeName = 'AI Assistant'}) async {
    final task = AiAgentService.extractTaskFromText(rawText);
    if (task == null) return;

    final sanitizedTask = TaskCardModel(
      id: _db.collection('tasks').doc().id,
      title: task.title,
      description: task.description,
      priority: task.priority,
      status: task.status,
      assigneeName: assigneeName,
      createdAt: task.createdAt,
      dueDate: task.dueDate,
      sourceType: 'ai',
      metadata: task.metadata,
    );

    await _db.collection('tasks').doc(sanitizedTask.id).set({
      ...sanitizedTask.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleTaskStatus(String taskId, bool done) async {
    await _db.collection('tasks').doc(taskId).update({
      'status': done ? 'done' : 'open',
    });
  }

}
