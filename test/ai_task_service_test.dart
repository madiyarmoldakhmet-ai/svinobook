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
  });
}
