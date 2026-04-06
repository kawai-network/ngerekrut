import 'package:flutter_test/flutter_test.dart';
import 'package:ngerekrut/langchain_gemma/langchain_gemma.dart';

class _FakeLocalAIClient implements LocalAIClient {
  _FakeLocalAIClient(this.response);

  final String response;

  @override
  String? get errorMessage => null;

  @override
  bool get isReady => true;

  @override
  LocalAIStatus get status => LocalAIStatus.ready;

  @override
  Future<void> dispose() async {}

  @override
  Future<String> generateResponse({
    required String prompt,
    String? systemPrompt,
  }) async => response;

  @override
  Future<String> generateWithTools({
    required String prompt,
    required List<Map<String, dynamic>> tools,
    String? systemPrompt,
  }) async => response;

  @override
  Future<LocalAIStatus> initialize({
    void Function(double progress)? onProgress,
  }) async => LocalAIStatus.ready;
}

void main() {
  group('LocalToolCallExecutor', () {
    test('returns parsed tool-call result', () async {
      final client = _FakeLocalAIClient(
        '{"function":"demo","arguments":{"value":42}}',
      );

      final result = await LocalToolCallExecutor.execute<Map<String, dynamic>>(
        client: client,
        prompt: 'run demo',
        tools: const [
          {'name': 'demo'}
        ],
        parser: (response) => LocalToolCallParser.parseArguments(
          response,
          expectedFunction: 'demo',
        ),
      );

      expect(result.data['value'], 42);
      expect(result.rawResponse, '{"function":"demo","arguments":{"value":42}}');
    });

    test('throws when parsing fails', () async {
      final client = _FakeLocalAIClient('not json');

      expect(
        () => LocalToolCallExecutor.execute<Map<String, dynamic>>(
          client: client,
          prompt: 'run demo',
          tools: const [
            {'name': 'demo'}
          ],
          parser: (response) => LocalToolCallParser.parseArguments(
            response,
            expectedFunction: 'demo',
          ),
          errorBuilder: (_) => 'parse failed',
        ),
        throwsA(
          isA<LocalAIException>().having(
            (e) => e.message,
            'message',
            'parse failed',
          ),
        ),
      );
    });
  });
}
