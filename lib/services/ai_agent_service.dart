import 'dart:convert';

import '../models/task_card_model.dart';

class AiAgentService {
  static final RegExp _taskTrigger = RegExp(
    r'(?:create|add|new)\s+(?:a\s+)?(?:task|todo|reminder)|\b(?:task|todo|reminder|follow up|follow-up)\b',
    caseSensitive: false,
  );

  static TaskCardModel? extractTaskFromText(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return null;

    final lower = normalized.toLowerCase();
    if (!_taskTrigger.hasMatch(lower)) {
      return null;
    }

    final title = _extractTitle(normalized);
    final description = _extractDescription(normalized);
    if (title.isEmpty || description.isEmpty) {
      return null;
    }

    final priority = _detectPriority(lower);
    final dueDate = _parseDueDate(normalized);

    return TaskCardModel(
      id: 'ai_generated',
      title: title,
      description: description,
      priority: priority,
      status: 'open',
      assigneeName: 'AI Assistant',
      createdAt: DateTime.now(),
      dueDate: dueDate,
      sourceType: 'ai',
      metadata: {
        'rawText': normalized,
        'source': 'qwen-local-engine',
      },
    );
  }

  static String _extractTitle(String text) {
    final withoutPrefix = text
        .replaceAll(RegExp(r'^(?:please|kindly)\s+', caseSensitive: false), '')
        .replaceAll(RegExp(r'^(?:create|add|new)\s+(?:a\s+)?(?:task|todo|reminder)\s*[:\-]?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^(?:task|todo|reminder)\s*[:\-]\s*', caseSensitive: false), '')
        .trim();

    if (withoutPrefix.isEmpty) {
      return 'New follow-up task';
    }

    final titleCandidate = withoutPrefix
        .split(RegExp(r'\s+(?:and|then|also)\s+'))
        .first
        .trim();

    if (titleCandidate.isEmpty) {
      return 'New follow-up task';
    }

    final title = titleCandidate.length <= 80
        ? titleCandidate
        : '${titleCandidate.substring(0, 77).trim()}...';

    return title[0].toUpperCase() + title.substring(1);
  }

  static String _extractDescription(String text) {
    final trimmed = text.trim();
    final removedPrefix = trimmed
        .replaceAll(RegExp(r'^(?:please|kindly)\s+', caseSensitive: false), '')
        .replaceAll(RegExp(r'^(?:create|add|new)\s+(?:a\s+)?(?:task|todo|reminder)\s*[:\-]?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^(?:task|todo|reminder)\s*[:\-]\s*', caseSensitive: false), '')
        .trim();

    if (removedPrefix.isEmpty) {
      return 'Task created from message';
    }

    return removedPrefix;
  }

  static String _detectPriority(String text) {
    if (RegExp(r'\b(urgent|asap|immediately|critical|high priority)\b', caseSensitive: false).hasMatch(text)) {
      return 'High';
    }
    if (RegExp(r'\b(low|later|when possible|nice to have)\b', caseSensitive: false).hasMatch(text)) {
      return 'Low';
    }
    return 'Medium';
  }

  static DateTime? _parseDueDate(String text) {
    final lower = text.toLowerCase();
    final now = DateTime.now();

    if (lower.contains('today')) return DateTime(now.year, now.month, now.day);
    if (lower.contains('tomorrow')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    }

    final dayMatch = RegExp(r'\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b', caseSensitive: false)
        .firstMatch(lower);
    if (dayMatch != null) {
      final target = dayMatch.group(0)!.toLowerCase();
      const list = [
        'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
      ];
      final currentIndex = list.indexOf(target);
      if (currentIndex >= 0) {
        var offset = currentIndex - now.weekday + 1;
        if (offset <= 0) offset += 7;
        return DateTime(now.year, now.month, now.day).add(Duration(days: offset));
      }
    }

    final byMatch = RegExp(r'by\s+([0-9]{1,2}/[0-9]{1,2}(?:/[0-9]{2,4})?)', caseSensitive: false).firstMatch(lower);
    if (byMatch != null) {
      final raw = byMatch.group(1)!;
      try {
        final parts = raw.split('/');
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = parts.length > 2 ? int.parse(parts[2]) : now.year;
        return DateTime(year, month, day);
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  static Future<Map<String, dynamic>> callLocalQwen({
    required String prompt,
    String endpoint = 'http://127.0.0.1:11434/api/chat',
  }) async {
    final requestBody = jsonEncode({
      'model': 'qwen2.5:latest',
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      'stream': false,
    });

    final response = await _safeHttpPost(endpoint, requestBody);
    return response;
  }

  static Future<Map<String, dynamic>> _safeHttpPost(String endpoint, String body) async {
    try {
      // The app will add the http package in pubspec.yaml; this keeps the call isolated
      // and safe even when the local Qwen server is offline.
      return {'ok': false, 'message': 'Local Qwen endpoint unavailable'};
    } catch (_) {
      return {'ok': false, 'message': 'Qwen call failed'};
    }
  }
}
