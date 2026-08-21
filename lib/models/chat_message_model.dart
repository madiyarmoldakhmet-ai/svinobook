import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String? imageUrl;
  final String? url;
  final DateTime timestamp;
  final bool isRead;
  final bool isGroup;
  final String chatRoomId;
  final String type;
  final String? alertType;
  final String? alertStatus;
  final String? alertDetails;
  final String? alertSource;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.imageUrl,
    this.url,
    required this.timestamp,
    this.isRead = false,
    required this.isGroup,
    required this.chatRoomId,
    required this.type,
    this.alertType,
    this.alertStatus,
    this.alertDetails,
    this.alertSource,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> data, String documentId) {
    final img = data['imageUrl'] as String?;
    final url = data['url'] as String? ?? img;
    return ChatMessageModel(
      id: documentId,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      text: data['text'] ?? '',
      imageUrl: img,
      url: url,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      isGroup: data['isGroup'] ?? false,
      chatRoomId: data['chatRoomId'] ?? '',
      type: data['type'] ?? (img != null && img.isNotEmpty ? 'image' : 'text'),
      alertType: data['alertType'] as String?,
      alertStatus: data['alertStatus'] as String?,
      alertDetails: data['alertDetails'] as String?,
      alertSource: data['alertSource'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'imageUrl': imageUrl,
      'url': url ?? imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'isGroup': isGroup,
      'chatRoomId': chatRoomId,
      'type': type,
      'alertType': alertType,
      'alertStatus': alertStatus,
      'alertDetails': alertDetails,
      'alertSource': alertSource,
    };
  }
}
