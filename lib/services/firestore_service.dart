import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';
import 'storage_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final StorageService _storage = StorageService();

  // --- Profile / Users ---
  Future<void> updateProfile({required String name, Uint8List? avatarBytes}) async {
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

    await _db.collection('global_chat').add({
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
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



  // Legacy sendDirectMessage for compatibility
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
