import 'package:flutter_test/flutter_test.dart';
import 'package:svinobook/services/ai_agent_service.dart';

void main() {
  group('AiAgentService task extraction', () {
    test('extracts a task from a plain-language message', () async {
      final result = AiAgentService.extractTaskFromText(
        'Please create a task: Review Qwen integration and send a summary by Friday.',
      );

      expect(result, isNotNull);
      expect(result!.title, contains('Qwen'));
      expect(result.description, contains('Review'));
      expect(result.priority, isNotEmpty);
    });

    test('returns null for non-task text', () {
      final result = AiAgentService.extractTaskFromText('Hello everyone, nice to meet you!');
      expect(result, isNull);
    });

    test('detects urgent priority and today due date', () {
      final result = AiAgentService.extractTaskFromText(
        'Create a task: Rotate credentials urgent today',
      );

      expect(result?.priority, 'High');
      expect(result?.dueDate, DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
    });

    test('detects low priority and tomorrow due date', () {
      final result = AiAgentService.extractTaskFromText(
        'Add a reminder: Update screenshots later tomorrow',
      );

      expect(result?.priority, 'Low');
      expect(result?.dueDate, DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 1));
    });

    test('parses an explicit due date', () {
      final result = AiAgentService.extractTaskFromText('New task: Publish notes by 12/31/2026');

      expect(result?.dueDate, DateTime(2026, 12, 31));
    });

    test('uses a follow-up title for a bare trigger', () {
      final result = AiAgentService.extractTaskFromText('task:');

      expect(result, isNotNull);
      expect(result?.title, 'New follow-up task');
    });

    test('truncates oversized titles', () {
      final longTitle = List.filled(100, 'release').join(' ');
      final result = AiAgentService.extractTaskFromText('Create task: $longTitle');

      expect(result, isNotNull);
      expect(result!.title.length, 80);
      expect(result.title.endsWith('...'), isTrue);
    });

    test('parses weekday due dates', () {
      final result = AiAgentService.extractTaskFromText('Create task: Review metrics on Monday');

      expect(result?.dueDate, isNotNull);
      expect(result!.dueDate!.weekday, DateTime.monday);
    });

    test('supports task aliases and default priority', () {
      final result = AiAgentService.extractTaskFromText('Follow up with the design team');

      expect(result?.priority, 'Medium');
      expect(result?.sourceType, 'ai');
      expect(result?.metadata['source'], 'qwen-local-engine');
    });
  });
}
