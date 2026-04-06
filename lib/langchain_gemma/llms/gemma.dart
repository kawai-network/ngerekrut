/// Gemma-backed local inference client.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import 'types.dart';

/// Default local AI client powered by `flutter_gemma`.
class GemmaLocalAIClient implements LocalAIClient {
  InferenceModel? _model;
  LocalAIStatus _status = LocalAIStatus.notInitialized;
  String? _errorMessage;

  @override
  LocalAIStatus get status => _status;

  @override
  String? get errorMessage => _errorMessage;

  @override
  bool get isReady => _status == LocalAIStatus.ready && _model != null;

  @override
  Future<LocalAIStatus> initialize({
    void Function(double progress)? onProgress,
  }) async {
    try {
      _setStatus(LocalAIStatus.downloading);

      const modelId = 'gemma-4-4b-it-gpu-int4';
      final isInstalled = await FlutterGemma.isModelInstalled(modelId);

      if (!isInstalled) {
        debugPrint('[GemmaLocalAIClient] Installing Gemma 4 E4B model...');

        await FlutterGemma.installModel(
          modelType: ModelType.gemmaIt,
        ).fromNetwork(
          'https://huggingface.co/google/gemma-4-4b-it-gpu-int4/resolve/main/model.task',
        ).withProgress((progress) {
          final percentage = progress / 100.0;
          debugPrint('[GemmaLocalAIClient] Download: $progress%');
          onProgress?.call(percentage);
        }).install();

        debugPrint('[GemmaLocalAIClient] Model installed successfully');
      }

      _model = await FlutterGemma.getActiveModel(
        maxTokens: 4096,
        preferredBackend: PreferredBackend.gpu,
        supportImage: false,
      );

      _setStatus(LocalAIStatus.ready);
      debugPrint('[GemmaLocalAIClient] Ready for inference');

      return LocalAIStatus.ready;
    } catch (e) {
      _errorMessage = 'Failed to initialize: $e';
      _setStatus(LocalAIStatus.error);
      debugPrint('[GemmaLocalAIClient] Error: $e');
      rethrow;
    }
  }

  @override
  Future<String> generateResponse({
    required String prompt,
    String? systemPrompt,
  }) async {
    final model = _model;
    if (model == null) {
      throw StateError('Model not initialized. Call initialize() first.');
    }

    final session = await model.createSession();

    try {
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        await session.addQueryChunk(Message(
          text: systemPrompt,
          isUser: false,
        ));
      }

      await session.addQueryChunk(Message(
        text: prompt,
        isUser: true,
      ));

      return await session.getResponse();
    } finally {
      await session.close();
    }
  }

  @override
  Future<String> generateWithTools({
    required String prompt,
    required List<Map<String, dynamic>> tools,
    String? systemPrompt,
  }) async {
    final model = _model;
    if (model == null) {
      throw StateError('Model not initialized. Call initialize() first.');
    }

    final session = await model.createSession();

    try {
      final toolsPrompt = _buildToolsPrompt(tools);
      final fullPrompt = systemPrompt != null
          ? '$systemPrompt\n\n$toolsPrompt\n\nUser: $prompt'
          : '$toolsPrompt\n\nUser: $prompt';

      await session.addQueryChunk(Message(
        text: fullPrompt,
        isUser: true,
      ));

      return await session.getResponse();
    } finally {
      await session.close();
    }
  }

  String _buildToolsPrompt(List<Map<String, dynamic>> tools) {
    final buffer = StringBuffer();
    buffer.writeln('Available functions:');
    for (final tool in tools) {
      buffer.writeln('- ${tool['name']}: ${tool['description']}');
      if (tool['parameters'] != null) {
        buffer.writeln('  Parameters: ${tool['parameters']}');
      }
    }
    buffer.writeln(
      '\nWhen you need to use a function, respond with a JSON object containing:',
    );
    buffer.writeln('{"function": "function_name", "arguments": {...}}');
    return buffer.toString();
  }

  @override
  Future<void> dispose() async {
    await _model?.close();
    _model = null;
    _setStatus(LocalAIStatus.notInitialized);
  }

  void _setStatus(LocalAIStatus status) {
    _status = status;
  }
}
