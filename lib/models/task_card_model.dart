import 'package:cloud_firestore/cloud_firestore.dart';

class TaskCardModel {
  final String id;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String? assigneeId;
  final String assigneeName;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String? sourceMessageId;
  final String sourceType;
  final Map<String, dynamic> metadata;

  TaskCardModel({
    required this.id,
    required this.title,
    required this.description,
    this.priority = 'Medium',
    this.status = 'open',
    this.assigneeId,
    this.assigneeName = 'Unassigned',
    required this.createdAt,
    this.dueDate,
    this.sourceMessageId,
    this.sourceType = 'manual',
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? const {};

  factory TaskCardModel.fromMap(Map<String, dynamic> data, String documentId) {
    final rawMetadata = data['metadata'];
    return TaskCardModel(
      id: documentId,
      title: data['title'] ?? 'Untitled Task',
      description: data['description'] ?? '',
      priority: data['priority'] ?? 'Medium',
      status: data['status'] ?? 'open',
      assigneeId: data['assigneeId'] as String?,
      assigneeName: data['assigneeName'] ?? 'Unassigned',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      sourceMessageId: data['sourceMessageId'] as String?,
      sourceType: data['sourceType'] ?? 'manual',
      metadata: rawMetadata is Map ? Map<String, dynamic>.from(rawMetadata) : const {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'sourceMessageId': sourceMessageId,
      'sourceType': sourceType,
      'metadata': metadata,
    };
  }
}
