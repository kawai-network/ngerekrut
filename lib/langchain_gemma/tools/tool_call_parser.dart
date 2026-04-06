/// Generic helpers for parsing structured tool-call responses.
library;

import 'dart:convert';

/// Parses JSON-like responses returned by local tool-calling prompts.
class LocalToolCallParser {
  const LocalToolCallParser._();

  /// Extracts the first JSON object found in a model response.
  static Map<String, dynamic>? extractJson(String response) {
    var cleaned = response.trim();

    final codeBlockRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final codeMatch = codeBlockRegex.firstMatch(cleaned);
    if (codeMatch != null) {
      cleaned = codeMatch.group(1)!;
    }

    final jsonStart = cleaned.indexOf('{');
    final jsonEnd = cleaned.lastIndexOf('}');

    if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
      return null;
    }

    final jsonString = cleaned.substring(jsonStart, jsonEnd + 1);

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Parses a function-style response into typed output.
  static T? parse<T>(
    String response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final json = extractJson(response);
    if (json == null) {
      return null;
    }

    try {
      return fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Extracts the `arguments` payload from a named function call, or falls back
  /// to returning the raw JSON object when it already matches the expected shape.
  static Map<String, dynamic>? parseArguments(
    String response, {
    String? expectedFunction,
    bool Function(Map<String, dynamic> json)? directValidator,
  }) {
    final json = extractJson(response);
    if (json == null) {
      return null;
    }

    if (json.containsKey('function')) {
      final functionName = json['function'] as String?;
      if (expectedFunction == null || functionName == expectedFunction) {
        final arguments = json['arguments'];
        if (arguments is Map<String, dynamic>) {
          return arguments;
        }
      }
    }

    if (directValidator == null || directValidator(json)) {
      return json;
    }

    return null;
  }
}
