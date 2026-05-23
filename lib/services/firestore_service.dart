import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  Future<void> createPost(String authorId, String authorName, String content) async {
    await _db.collection('posts').add({
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'likes': 0,
      'createdAt': FieldValue.serverTimestamp(),
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

  Future<void> sendGlobalMessage(String senderId, String senderName, String text) async {
    await _db.collection('global_chat').add({
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- Direct Messages ---
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

  Future<void> sendDirectMessage(String chatId, String senderId, String senderName, String text) async {
    final batch = _db.batch();
    final chatRef = _db.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();

    batch.set(messageRef, {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    batch.update(chatRef, {
      'lastMessage': text,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
