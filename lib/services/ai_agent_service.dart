import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/task_card_model.dart';

class AiAgentService {
  static const localModels = [
    'qwen2.5:14b',
    'gpt-oss:20b',
    'llava',
    'llama3.2',
  ];
  static final RegExp _taskTrigger = RegExp(
    r'(?:create|add|new)\s+(?:a\s+)?(?:task|todo|reminder)|\b(?:task|todo|reminder|follow up|follow-up)\b',
    caseSensitive: false,
  );

  static Future<TaskCardModel?> parseTaskFromTextAsync(String text) async {
    final aiResult = await callLocalQwen(
      prompt: text,
    );

    if (aiResult['ok'] == true && aiResult['task'] is TaskCardModel) {
      return aiResult['task'] as TaskCardModel;
    }

    return extractTaskFromText(text);
  }

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
    String endpoint = 'http://localhost:11434/api/generate',
  }) async {
    final endpoints = [
      endpoint,
      'http://localhost:8080/v1/chat/completions',
      'http://127.0.0.1:11434/api/generate',
    ];

    for (final candidate in endpoints.toSet().toList()) {
      try {
        final response = await _postJson(candidate, prompt);
        if (response['ok'] == true) {
          final parsedTask = _taskFromAiText(response['text']?.toString() ?? '');
          if (parsedTask != null) {
            return {
              'ok': true,
              'text': response['text'],
              'task': parsedTask,
            };
          }
          return response;
        }
      } catch (_) {
        continue;
      }
    }

    return {
      'ok': false,
      'fallback': true,
      'message': 'Local AI endpoint unavailable; using regex fallback.',
      'task': extractTaskFromText(prompt),
    };
  }

  static Future<String> chatWithLocalModel({
    required String prompt,
    required String model,
    String endpoint = 'http://localhost:11434/api/generate',
  }) async {
    final response = await http
        .post(
          Uri.parse(endpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'model': model,
            'prompt': prompt,
            'stream': false,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Ollama returned HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final text = (decoded['response'] ?? decoded['content'] ?? '').toString().trim();
    if (text.isEmpty) throw Exception('Ollama returned an empty response');
    return text;
  }

  static TaskCardModel? _taskFromAiText(String text) {
    final task = extractTaskFromText(text);
    if (task != null) {
      return task;
    }
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return null;

    final title = cleaned.length > 80 ? '${cleaned.substring(0, 77).trim()}...' : cleaned;
    return TaskCardModel(
      id: 'ai_generated',
      title: title,
      description: cleaned,
      priority: 'Medium',
      status: 'open',
      assigneeName: 'AI Assistant',
      createdAt: DateTime.now(),
      sourceType: 'ai',
      metadata: {'rawText': cleaned, 'source': 'qwen-local-engine'},
    );
  }

  static Future<Map<String, dynamic>> _postJson(String endpoint, String prompt) async {
    final body = endpoint.contains('/v1/chat/completions')
        ? jsonEncode({
            'model': 'local-model',
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.2,
          })
        : jsonEncode({
            'model': 'qwen2.5:latest',
            'prompt': prompt,
            'stream': false,
          });

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return {'ok': false, 'message': 'Bad response'};
    }

    final decoded = jsonDecode(response.body);
    if (endpoint.contains('/v1/chat/completions')) {
      final text = decoded['choices'] is List && decoded['choices'].isNotEmpty
          ? decoded['choices'][0]['message']['content'] ?? ''
          : '';
      return {
        'ok': text.toString().trim().isNotEmpty,
        'text': text,
      };
    }

    final text = decoded['response'] ?? decoded['content'] ?? '';
    return {
      'ok': text.toString().trim().isNotEmpty,
      'text': text,
    };
  }
}
