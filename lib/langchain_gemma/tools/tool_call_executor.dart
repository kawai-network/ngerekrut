/// Helpers for executing structured tool calls against a local AI client.
library;

import '../llms/types.dart';

/// Result of executing a local tool call.
class LocalToolCallResult<T> {
  final T data;
  final String rawResponse;

  const LocalToolCallResult({
    required this.data,
    required this.rawResponse,
  });
}

/// Executes a tool call and parses the structured response.
class LocalToolCallExecutor {
  const LocalToolCallExecutor._();

  static Future<LocalToolCallResult<T>> execute<T>({
    required LocalAIClient client,
    required String prompt,
    required List<Map<String, dynamic>> tools,
    required T? Function(String response) parser,
    String? systemPrompt,
    String Function(String response)? errorBuilder,
  }) async {
    final response = await client.generateWithTools(
      prompt: prompt,
      tools: tools,
      systemPrompt: systemPrompt,
    );

    final data = parser(response);
    if (data == null) {
      throw LocalAIException(
        errorBuilder?.call(response) ?? 'Failed to parse tool-call response',
      );
    }

    return LocalToolCallResult<T>(
      data: data,
      rawResponse: response,
    );
  }
}
