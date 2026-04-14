/// Shared types for Gemma local inference.
library;

/// Status of local AI initialization.
enum LocalAIStatus {
  /// Not initialized.
  notInitialized,

  /// Validating environment and local state before install/load.
  checking,

  /// Model downloading.
  downloading,

  /// Loading the model into the inference backend.
  initializing,

  /// Ready to use.
  ready,

  /// Error occurred.
  error,
}

/// Contract for local LLM providers used by the app.
abstract class LocalAIClient {
  LocalAIStatus get status;
  String? get errorMessage;
  bool get isReady;

  Future<LocalAIStatus> initialize({
    void Function(double progress)? onProgress,
  });

  Future<String> generateResponse({
    required String prompt,
    String? systemPrompt,
  });

  Future<String> generateWithTools({
    required String prompt,
    required List<Map<String, dynamic>> tools,
    String? systemPrompt,
  });

  Future<void> dispose();
}

/// Error thrown when local AI operation fails.
class LocalAIException implements Exception {
  final String message;
  final Object? cause;

  const LocalAIException(this.message, [this.cause]);

  @override
  String toString() =>
      'LocalAIException: $message${cause != null ? ' (caused by $cause)' : ''}';
}
