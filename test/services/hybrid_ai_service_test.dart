import 'package:flutter_test/flutter_test.dart';
import 'package:ngerekrut/langchain_gemma/langchain_gemma.dart';
import 'package:ngerekrut/services/hybrid_ai_service.dart';

class _FakeLocalAIClient implements LocalAIClient {
  _FakeLocalAIClient({
    this.toolResponse = '{}',
    this.textResponse = 'ok',
    this.shouldThrowOnInitialize = false,
  });

  final String toolResponse;
  final String textResponse;
  final bool shouldThrowOnInitialize;

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
  }) async => textResponse;

  @override
  Future<String> generateWithTools({
    required String prompt,
    required List<Map<String, dynamic>> tools,
    String? systemPrompt,
  }) async => toolResponse;

  @override
  Future<LocalAIStatus> initialize({
    void Function(double progress)? onProgress,
  }) async {
    if (shouldThrowOnInitialize) {
      throw Exception('init failed');
    }
    onProgress?.call(1.0);
    return LocalAIStatus.ready;
  }
}

void main() {
  group('HybridAIService', () {
    test('initialize returns true when local AI initializes', () async {
      final service = HybridAIService(
        cloudApiKey: 'test-key',
        localAI: _FakeLocalAIClient(),
      );

      final result = await service.initialize();

      expect(result, isTrue);
    });

    test('initialize returns false when local AI initialization fails', () async {
      final service = HybridAIService(
        cloudApiKey: 'test-key',
        localAI: _FakeLocalAIClient(shouldThrowOnInitialize: true),
      );

      final result = await service.initialize();

      expect(result, isFalse);
    });

    test('generateLocalResponse uses local provider and updates lastUsedMode', () async {
      final service = HybridAIService(
        cloudApiKey: 'test-key',
        localAI: _FakeLocalAIClient(textResponse: 'halo'),
      );

      final result = await service.generateLocalResponse(prompt: 'ping');

      expect(result, 'halo');
      expect(service.lastUsedMode, AIMode.local);
    });

    test('generateJobPosting uses local tool response when available', () async {
      final service = HybridAIService(
        cloudApiKey: 'test-key',
        localAI: _FakeLocalAIClient(
          toolResponse:
              '{"title":"Kasir","location":"Jakarta","description":"Jaga toko","requirements":["Teliti"],"responsibilities":["Layani pelanggan"],"salary_range":"5-6 juta","employment_type":"Full Time"}',
        ),
      );

      final result = await service.generateJobPosting('Kasir');

      expect(result.usedMode, AIMode.local);
      expect(result.jobPosting.title, 'Kasir');
      expect(result.jobPosting.salaryRange, '5-6 juta');
    });

    test('generateJobPosting works without cloud API key by using local AI', () async {
      final service = HybridAIService(
        localAI: _FakeLocalAIClient(
          toolResponse:
              '{"title":"Admin Gudang","location":"Depok","description":"Kelola stok barang","requirements":["Rapi"],"responsibilities":["Catat inventaris"],"salary_range":"4-5 juta","employment_type":"Full Time"}',
        ),
      );

      final result = await service.generateJobPosting('Admin Gudang');

      expect(service.hasCloudAI, isFalse);
      expect(result.usedMode, AIMode.local);
      expect(result.jobPosting.title, 'Admin Gudang');
    });
  });
}
