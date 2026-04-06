/// Hybrid AI service that combines local and cloud AI.
library;

import 'package:flutter/foundation.dart';
import '../langchain_gemma/langchain_gemma.dart';
import 'job_posting_generator.dart';
import 'tools/job_posting_tool.dart';
import '../models/job_posting.dart';

/// AI mode selection
enum AIMode {
  /// Use local AI (flutter_gemma)
  local,

  /// Use cloud AI (OpenAI)
  cloud,

  /// Auto - try local first, fallback to cloud
  auto,
}

/// Result of AI generation with metadata
class GenerationResult {
  final JobPosting jobPosting;
  final AIMode usedMode;
  final String? rawResponse;

  const GenerationResult({
    required this.jobPosting,
    required this.usedMode,
    this.rawResponse,
  });
}

/// Hybrid AI service that intelligently routes between local and cloud AI.
class HybridAIService {
  final LocalAIClient _localAI;
  final JobPostingGenerator? _cloudAI;

  AIMode _currentMode = AIMode.auto;
  AIMode _lastUsedMode = AIMode.local;

  HybridAIService({
    String? cloudApiKey,
    LocalAIClient? localAI,
  }) : _localAI = localAI ?? GemmaLocalAIClient(),
       _cloudAI = cloudApiKey != null && cloudApiKey.isNotEmpty
           ? JobPostingGenerator(apiKey: cloudApiKey)
           : null;

  AIMode get currentMode => _currentMode;
  AIMode get lastUsedMode => _lastUsedMode;
  bool get hasCloudAI => _cloudAI != null;

  /// Set the preferred AI mode.
  void setMode(AIMode mode) {
    _currentMode = mode;
    debugPrint('[HybridAIService] Mode set to: $mode');
  }

  /// Initialize the service.
  ///
  /// Returns true if local AI is ready, false if it failed or is downloading.
  Future<bool> initialize({
    void Function(double progress)? onDownloadProgress,
  }) async {
    try {
      await _localAI.initialize(
        onProgress: onDownloadProgress,
      );
      return true;
    } catch (e) {
      debugPrint('[HybridAIService] Local AI init failed: $e');
      debugPrint('[HybridAIService] Will use cloud AI as fallback');
      return false;
    }
  }

  /// Generate job posting using hybrid approach.
  ///
  /// Strategy:
  /// - If mode is [AIMode.local]: use local AI only
  /// - If mode is [AIMode.cloud]: use cloud AI only
  /// - If mode is [AIMode.auto]: try local first, fallback to cloud on error
  Future<GenerationResult> generateJobPosting(String position) async {
    final shouldTryLocal = _currentMode == AIMode.local ||
        !hasCloudAI ||
        (_currentMode == AIMode.auto && _localAI.isReady);

    if (shouldTryLocal) {
      try {
        debugPrint('[HybridAIService] Using Local AI for: $position');
        final result = await _generateWithLocal(position);
        _lastUsedMode = AIMode.local;
        return result;
      } catch (e) {
        if (_currentMode == AIMode.local) {
          // If explicitly set to local, don't fallback
          rethrow;
        }
        debugPrint('[HybridAIService] Local AI failed, falling back to cloud: $e');
      }
    }

    // Fallback to cloud AI
    final cloudAI = _cloudAI;
    if (cloudAI == null) {
      throw LocalAIException(
        'Cloud AI is not configured and local AI is unavailable.',
      );
    }
    debugPrint('[HybridAIService] Using Cloud AI for: $position');
    final jobPosting = await cloudAI.generate(position);
    _lastUsedMode = AIMode.cloud;
    return GenerationResult(
      jobPosting: jobPosting,
      usedMode: AIMode.cloud,
    );
  }

  /// Refine existing job posting.
  Future<GenerationResult> refineJobPosting(
    JobPosting current,
    String userRequest,
  ) async {
    final shouldTryLocal = _currentMode == AIMode.local ||
        !hasCloudAI ||
        (_currentMode == AIMode.auto && _localAI.isReady);

    if (shouldTryLocal) {
      try {
        debugPrint('[HybridAIService] Refining with Local AI');
        final result = await _refineWithLocal(current, userRequest);
        _lastUsedMode = AIMode.local;
        return result;
      } catch (e) {
        if (_currentMode == AIMode.local) {
          rethrow;
        }
        debugPrint('[HybridAIService] Local refine failed, fallback to cloud');
      }
    }

    final cloudAI = _cloudAI;
    if (cloudAI == null) {
      throw LocalAIException(
        'Cloud AI is not configured and local AI is unavailable.',
      );
    }
    debugPrint('[HybridAIService] Refining with Cloud AI');
    final refined = await cloudAI.refine(current, userRequest);
    _lastUsedMode = AIMode.cloud;
    return GenerationResult(
      jobPosting: refined,
      usedMode: AIMode.cloud,
    );
  }

  /// Generate text with the configured local provider.
  Future<String> generateLocalResponse({
    required String prompt,
    String? systemPrompt,
  }) async {
    final response = await _localAI.generateResponse(
      prompt: prompt,
      systemPrompt: systemPrompt,
    );
    _lastUsedMode = AIMode.local;
    return response;
  }

  /// Generate tool-call output with the configured local provider.
  Future<String> generateLocalWithTools({
    required String prompt,
    required List<Map<String, dynamic>> tools,
    String? systemPrompt,
  }) async {
    final response = await _localAI.generateWithTools(
      prompt: prompt,
      tools: tools,
      systemPrompt: systemPrompt,
    );
    _lastUsedMode = AIMode.local;
    return response;
  }

  /// Execute a structured local tool call and parse its response.
  Future<LocalToolCallResult<T>> executeLocalToolCall<T>({
    required String prompt,
    required List<Map<String, dynamic>> tools,
    required T? Function(String response) parser,
    String? systemPrompt,
    String Function(String response)? errorBuilder,
  }) async {
    final result = await LocalToolCallExecutor.execute<T>(
      client: _localAI,
      prompt: prompt,
      tools: tools,
      parser: parser,
      systemPrompt: systemPrompt,
      errorBuilder: errorBuilder,
    );
    _lastUsedMode = AIMode.local;
    return result;
  }

  /// Generate using local AI with function calling.
  Future<GenerationResult> _generateWithLocal(String position) async {
    final systemPrompt = _buildSystemPrompt();
    final userPrompt = _buildGeneratePrompt(position);

    final response = await generateLocalWithTools(
      prompt: userPrompt,
      tools: [JobPostingTool.schema],
      systemPrompt: systemPrompt,
    );

    // Parse function call result
    final functionData = JobPostingTool.parseFunctionCall(response);
    if (functionData != null) {
      return GenerationResult(
        jobPosting: JobPosting.fromJson(functionData),
        usedMode: AIMode.local,
        rawResponse: response,
      );
    }

    // Fallback: try to extract JSON from response
    throw LocalAIException('Failed to parse function call from local AI');
  }

  /// Refine using local AI.
  Future<GenerationResult> _refineWithLocal(
    JobPosting current,
    String userRequest,
  ) async {
    final systemPrompt = _buildSystemPrompt();
    final userPrompt = _buildRefinePrompt(current, userRequest);

    final response = await generateLocalWithTools(
      prompt: userPrompt,
      tools: [JobPostingTool.schema],
      systemPrompt: systemPrompt,
    );

    final functionData = JobPostingTool.parseFunctionCall(response);
    if (functionData != null) {
      return GenerationResult(
        jobPosting: JobPosting.fromJson(functionData),
        usedMode: AIMode.local,
        rawResponse: response,
      );
    }

    throw LocalAIException('Failed to parse function call from local AI');
  }

  String _buildSystemPrompt() {
    return '''You are an expert HR assistant specializing in creating job postings for the Indonesian market.

Your task is to generate professional, attractive job postings that:
- Are written in clear, professional Indonesian
- Include realistic salary ranges for the Indonesian market
- Have practical requirements suitable for the position level
- Are comprehensive yet concise

Always respond with a function call to generate_job_posting with all required fields.''';
  }

  String _buildGeneratePrompt(String position) {
    return 'Buat lowongan kerja untuk posisi: $position\n\nPastikan sertakan:\n- Judul yang jelas\n- Lokasi (default: Jakarta jika tidak disebutkan)\n- Tipe employment\n- Deskripsi menarik\n- Requirements yang realistis\n- Responsibilities yang jelas\n- Range gaji yang wajar untuk Indonesia';
  }

  String _buildRefinePrompt(JobPosting current, String userRequest) {
    return '''Job posting saat ini:
${current.toJson()}

User request: $userRequest

Silakan generate_job_posting dengan data yang sudah diupdate sesuai request.''';
  }

  /// Check if local AI is ready.
  bool get isLocalAIReady => _localAI.isReady;

  /// Get local AI status.
  LocalAIStatus get localAIStatus => _localAI.status;

  /// Release resources.
  Future<void> dispose() async {
    await _localAI.dispose();
  }
}
