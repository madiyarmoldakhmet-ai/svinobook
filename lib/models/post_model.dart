import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String text;
  final String? imageUrl;
  final DateTime timestamp;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.text,
    this.imageUrl,
    required this.timestamp,
  });

  // Backwards compatibility getters
  String get authorId => userId;
  String get authorName => userName;
  String get content => text;
  DateTime get createdAt => timestamp;
  int get likes => 0;

  factory PostModel.fromMap(Map<String, dynamic> data, String documentId) {
    return PostModel(
      id: documentId,
      userId: data['userId'] ?? data['authorId'] ?? '',
      userName: data['userName'] ?? data['authorName'] ?? 'Unknown',
      userPhotoUrl: data['userPhotoUrl'],
      text: data['text'] ?? data['content'] ?? '',
      imageUrl: data['imageUrl'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? 
                 (data['createdAt'] as Timestamp?)?.toDate() ?? 
                 DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
