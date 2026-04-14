/// Gemma-backed local inference client.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import 'types.dart';

/// Default local AI client powered by `flutter_gemma`.
class GemmaLocalAIClient implements LocalAIClient {
  static const _modelId = 'gemma-4-E2B-it.litertlm';
  static const _modelUrl =
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm';
  static const _modelLoadTimeout = Duration(minutes: 2);

  InferenceModel? _model;
  LocalAIStatus _status = LocalAIStatus.notInitialized;
  String? _errorMessage;
  PreferredBackend _backend = PreferredBackend.gpu;
  Future<LocalAIStatus>? _initializeFuture;

  @override
  LocalAIStatus get status => _status;

  @override
  String? get errorMessage => _errorMessage;

  @override
  bool get isReady => _status == LocalAIStatus.ready && _model != null;

  @override
  Future<LocalAIStatus> initialize({
    void Function(double progress)? onProgress,
  }) {
    if (isReady) {
      return Future.value(LocalAIStatus.ready);
    }

    final inFlight = _initializeFuture;
    if (inFlight != null) {
      return inFlight;
    }

    final future = _initializeInternal(
      onProgress: onProgress,
    );
    _initializeFuture = future;
    return future.whenComplete(() {
      _initializeFuture = null;
    });
  }

  Future<LocalAIStatus> _initializeInternal({
    void Function(double progress)? onProgress,
  }) async {
    try {
      _errorMessage = null;
      _setStatus(LocalAIStatus.checking);

      final isInstalled = await FlutterGemma.isModelInstalled(_modelId);

      if (!isInstalled) {
        _setStatus(LocalAIStatus.downloading);
        debugPrint('[GemmaLocalAIClient] Installing Gemma 4 E2B LiteRT-LM model...');

        await FlutterGemma.installModel(
          modelType: ModelType.gemmaIt,
        ).fromNetwork(
          _modelUrl,
        ).withProgress((progress) {
          final percentage = progress / 100.0;
          debugPrint('[GemmaLocalAIClient] Download: $progress%');
          onProgress?.call(percentage);
        }).install();

        debugPrint('[GemmaLocalAIClient] Model installed successfully');
      }

      _setStatus(LocalAIStatus.initializing);
      await _loadModel(
        preferredBackend: _backend,
      ).timeout(_modelLoadTimeout);

      _setStatus(LocalAIStatus.ready);
      debugPrint('[GemmaLocalAIClient] Ready for inference using $_backend');

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
    return _withBackendRecovery(() async {
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
    });
  }

  @override
  Future<String> generateWithTools({
    required String prompt,
    required List<Map<String, dynamic>> tools,
    String? systemPrompt,
  }) async {
    return _withBackendRecovery(() async {
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
    });
  }

  Future<void> _loadModel({
    required PreferredBackend preferredBackend,
  }) async {
    await _model?.close();
    try {
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 4096,
        preferredBackend: preferredBackend,
        supportImage: false,
      );
      _backend = preferredBackend;
    } catch (e) {
      _model = null;
      rethrow;
    }
  }

  Future<String> _withBackendRecovery(
    Future<String> Function() action,
  ) async {
    try {
      return await action();
    } catch (e) {
      if (_shouldFallbackToCpu(e)) {
        debugPrint('[GemmaLocalAIClient] GPU backend unavailable, retrying with CPU');
        await _loadModel(preferredBackend: PreferredBackend.cpu);
        return action();
      }
      rethrow;
    }
  }

  bool _shouldFallbackToCpu(Object error) {
    final message = error.toString().toLowerCase();
    return _backend != PreferredBackend.cpu &&
        (message.contains('opencl') || message.contains('gpu'));
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
