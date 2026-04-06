/// Service untuk generate job posting menggunakan AI.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../langchain/chat_models/chat_models.dart';
import '../langchain/prompts/prompts.dart';
import '../langchain_openai/chat_models/chat_openai.dart';
import '../langchain_openai/chat_models/types.dart';
import '../models/job_posting.dart';
import '../prompts/job_posting_prompt.dart';

/// Service untuk generate job posting via AI.
class JobPostingGenerator {
  final ChatOpenAI _chatModel;

  JobPostingGenerator({required String apiKey})
    : _chatModel = ChatOpenAI(
        apiKey: apiKey,
        defaultOptions: const ChatOpenAIOptions(
          model: 'gpt-4o-mini',
          temperature: 0.7,
          maxTokens: 1000,
        ),
      );

  /// Generate job posting dari posisi.
  ///
  /// Returns [JobPosting] atau throw [JobPostingGenerationException].
  Future<JobPosting> generate(String position) async {
    try {
      final messages = [
        ChatMessage.system(jobPostingSystemPrompt),
        ChatMessage.humanText(jobPostingUserPrompt(position)),
      ];

      final prompt = PromptValue.chat(messages);
      final result = await _chatModel.invoke(prompt);
      final responseText = result.outputAsString;

      debugPrint('[JobPostingGenerator] Raw AI response:\n$responseText');

      return _parseResponse(responseText);
    } catch (e) {
      throw JobPostingGenerationException('Gagal generate job posting: $e');
    }
  }

  /// Refine job posting yang sudah ada.
  Future<JobPosting> refine(JobPosting current, String userRequest) async {
    try {
      final currentJson = jsonEncode(current.toJson());
      final messages = [
        ChatMessage.system(jobPostingSystemPrompt),
        ChatMessage.humanText(
          jobPostingRefinePrompt(currentJson, userRequest),
        ),
      ];

      final prompt = PromptValue.chat(messages);
      final result = await _chatModel.invoke(prompt);
      final responseText = result.outputAsString;

      debugPrint('[JobPostingGenerator] Refined AI response:\n$responseText');

      return _parseResponse(responseText);
    } catch (e) {
      throw JobPostingGenerationException('Gagal refine job posting: $e');
    }
  }

  /// Parse JSON response dari AI menjadi [JobPosting].
  JobPosting _parseResponse(String response) {
    // Clean response text - remove markdown code blocks if any
    var cleaned = response.trim();

    // Remove ```json ... ``` or ``` ... ``` wrapper
    final jsonRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final match = jsonRegex.firstMatch(cleaned);
    if (match != null) {
      cleaned = match.group(1)!;
    }

    // Try to find JSON object in response
    final jsonStart = cleaned.indexOf('{');
    final jsonEnd = cleaned.lastIndexOf('}');

    if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
      throw const FormatException(
        'Response tidak mengandung JSON object',
      );
    }

    final jsonString = cleaned.substring(jsonStart, jsonEnd + 1);

    try {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return JobPosting.fromJson(jsonMap);
    } catch (e) {
      throw FormatException('Gagal parse JSON: $e\nJSON: $jsonString');
    }
  }
}

/// Exception untuk error saat generate job posting.
class JobPostingGenerationException implements Exception {
  final String message;
  const JobPostingGenerationException(this.message);

  @override
  String toString() => 'JobPostingGenerationException: $message';
}
