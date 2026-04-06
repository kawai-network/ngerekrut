/// Local AI service using flutter_gemma for on-device inference.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

/// Status of local AI initialization
enum LocalAIStatus {
  /// Not initialized
  notInitialized,

  /// Model downloading
  downloading,

  /// Ready to use
  ready,

  /// Error occurred
  error,
}

/// Service for local AI inference using Gemma models.
class LocalAIService {
  InferenceModel? _model;
  LocalAIStatus _status = LocalAIStatus.notInitialized;
  String? _errorMessage;

  LocalAIStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isReady => _status == LocalAIStatus.ready && _model != null;

  /// Initialize the service with Gemma 4 E4B model.
  ///
  /// Returns [LocalAIStatus.ready] when successful.
  Future<LocalAIStatus> initialize({
    void Function(double progress)? onProgress,
  }) async {
    try {
      _setStatus(LocalAIStatus.downloading);

      // Check if model is already installed
      // Using a unique model ID for Gemma 4 E4B
      const modelId = 'gemma-4-4b-it-gpu-int4';
      final isInstalled = await FlutterGemma.isModelInstalled(modelId);

      if (!isInstalled) {
        debugPrint('[LocalAIService] Installing Gemma 4 E4B model...');

        // Install Gemma 4 E4B model using gemmaIt type
        await FlutterGemma.installModel(
          modelType: ModelType.gemmaIt,
        ).fromNetwork(
          'https://huggingface.co/google/gemma-4-4b-it-gpu-int4/resolve/main/model.task',
        ).withProgress((progress) {
          // progress is int from 0-100
          final percentage = progress / 100.0;
          debugPrint('[LocalAIService] Download: $progress%');
          onProgress?.call(percentage);
        }).install();

        debugPrint('[LocalAIService] Model installed successfully');
      }

      // Create model instance with GPU backend
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 4096,
        preferredBackend: PreferredBackend.gpu,
        supportImage: false, // Text-only for job posting
      );

      _setStatus(LocalAIStatus.ready);
      debugPrint('[LocalAIService] Ready for inference');

      return LocalAIStatus.ready;
    } catch (e) {
      _errorMessage = 'Failed to initialize: $e';
      _setStatus(LocalAIStatus.error);
      debugPrint('[LocalAIService] Error: $e');
      rethrow;
    }
  }

  /// Generate a response using local AI.
  ///
  /// [prompt] - The user prompt
  /// [systemPrompt] - Optional system prompt for context
  Future<String> generateResponse({
    required String prompt,
    String? systemPrompt,
  }) async {
    if (_model == null) {
      throw StateError('Model not initialized. Call initialize() first.');
    }

    final session = await _model!.createSession();

    try {
      // Add system prompt if provided
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        await session.addQueryChunk(Message(
          text: systemPrompt,
          isUser: false,
        ));
      }

      // Add user prompt
      await session.addQueryChunk(Message(
        text: prompt,
        isUser: true, // CRITICAL: must be true for user messages
      ));

      // Get response
      final response = await session.getResponse();
      return response;
    } finally {
      await session.close();
    }
  }

  /// Generate response with function calling support.
  ///
  /// [prompt] - User prompt
  /// [tools] - Available functions the model can call
  /// Returns the raw response that may include function calls
  Future<String> generateWithTools({
    required String prompt,
    required List<Map<String, dynamic>> tools,
    String? systemPrompt,
  }) async {
    if (_model == null) {
      throw StateError('Model not initialized. Call initialize() first.');
    }

    final session = await _model!.createSession();

    try {
      // Build prompt with tools
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
    buffer.writeln('\nWhen you need to use a function, respond with a JSON object containing:');
    buffer.writeln('{"function": "function_name", "arguments": {...}}');
    return buffer.toString();
  }

  /// Release resources.
  Future<void> dispose() async {
    await _model?.close();
    _model = null;
    _setStatus(LocalAIStatus.notInitialized);
  }

  void _setStatus(LocalAIStatus status) {
    _status = status;
    // Notify listeners if needed (can add ChangeNotifier later)
  }
}

/// Error thrown when local AI operation fails.
class LocalAIException implements Exception {
  final String message;
  final Object? cause;

  const LocalAIException(this.message, [this.cause]);

  @override
  String toString() => 'LocalAIException: $message${cause != null ? ' (caused by $cause)' : ''}';
}
