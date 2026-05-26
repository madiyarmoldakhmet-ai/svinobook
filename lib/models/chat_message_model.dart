import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isRead;
  final bool isGroup;
  final String chatRoomId;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.imageUrl,
    required this.timestamp,
    this.isRead = false,
    required this.isGroup,
    required this.chatRoomId,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ChatMessageModel(
      id: documentId,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      isGroup: data['isGroup'] ?? false,
      chatRoomId: data['chatRoomId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'isGroup': isGroup,
      'chatRoomId': chatRoomId,
    };
  }
}
