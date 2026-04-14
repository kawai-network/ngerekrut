/// LangChain adapter for HybridAIService.
///
/// Wraps the existing HybridAIService as a LangChain-compatible BaseChatModel
/// so it can be used with LLMChain, ConversationBufferMemory, and PromptTemplate.
library;

import 'dart:async';

import '../../langchain/chat_models/chat_models.dart';
import '../../langchain/language_models/language_models.dart';
import '../../langchain/prompts/types.dart';
import '../../langchain/exceptions/exceptions.dart';
import '../../langchain/tools/base.dart';
import '../../services/hybrid_ai_service.dart';

/// LangChain-compatible chat model options.
class HybridChatModelOptions extends ChatModelOptions {
  const HybridChatModelOptions({
    super.model,
    super.tools,
    super.toolChoice,
    super.concurrencyLimit,
  });

  @override
  ChatModelOptions copyWith({
    String? model,
    List<ToolSpec>? tools,
    ChatToolChoice? toolChoice,
    int? concurrencyLimit,
  }) {
    return HybridChatModelOptions(
      model: model ?? this.model,
      tools: tools ?? this.tools,
      toolChoice: toolChoice ?? this.toolChoice,
      concurrencyLimit: concurrencyLimit ?? this.concurrencyLimit,
    );
  }
}

/// LangChain adapter for HybridAIService.
///
/// Adapts the existing HybridAIService to work as a LangChain BaseChatModel,
/// enabling use with LLMChain, memory, and prompt templates.
class HybridChatModel extends BaseChatModel<HybridChatModelOptions> {
  /// The underlying AI service.
  final HybridAIService service;

  /// Optional system prompt to prepend.
  final String? defaultSystemPrompt;

  const HybridChatModel({
    required this.service,
    this.defaultSystemPrompt,
    HybridChatModelOptions options = const HybridChatModelOptions(),
  }) : super(defaultOptions: options);

  @override
  Future<ChatResult> invoke(
    PromptValue input, {
    HybridChatModelOptions? options,
  }) async {
    final messages = input.toChatMessages();

    // Extract system prompt and user messages
    String? systemPrompt;
    final humanMessages = <String>[];

    for (final msg in messages) {
      switch (msg) {
        case SystemChatMessage(:final content):
          systemPrompt = content;
        case HumanChatMessage(content: ChatMessageContentText(:final text)):
          humanMessages.add(text);
        case AIChatMessage():
          break;
        default:
          break;
      }
    }

    final fullPrompt = humanMessages.join('\n');
    final effectiveSystemPrompt =
        systemPrompt ?? defaultSystemPrompt ?? 'You are a helpful assistant.';

    try {
      // Use hybrid response with cloud fallback
      final response = await service.generateHybridResponse(
        prompt: fullPrompt,
        systemPrompt: effectiveSystemPrompt,
      );

      return ChatResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        output: AIChatMessage(content: response),
        finishReason: FinishReason.stop,
        metadata: {
          'mode': service.lastUsedMode.name,
          'usedLocalAI': service.lastUsedMode == AIMode.local,
        },
        usage: const LanguageModelUsage(
          promptTokens: 0,
          responseTokens: 0,
          totalTokens: 0,
        ),
      );
    } catch (e) {
      throw LangChainException(message: 'Failed to generate response: $e');
    }
  }

  /// Generate response with streaming simulation.
  ///
  /// Uses hybrid AI (local first, cloud fallback) and simulates streaming
  /// by polling the future and emitting chunks.
  Stream<String> invokeWithStreaming({
    required String prompt,
    String? systemPrompt,
  }) {
    final effectiveSystemPrompt =
        systemPrompt ?? defaultSystemPrompt ?? 'You are a helpful assistant.';

    final controller = StreamController<String>();

    // Start the AI request using hybrid (local + cloud fallback)
    final responseFuture = service.generateHybridResponse(
      prompt: prompt,
      systemPrompt: effectiveSystemPrompt,
    );

    // Poll and emit chunks
    _pollAndStream(responseFuture, controller);

    return controller.stream;
  }

  Future<void> _pollAndStream(
    Future<String> responseFuture,
    StreamController<String> controller,
  ) async {
    String? finalResponse;

    // Poll the future until it completes
    while (finalResponse == null) {
      try {
        finalResponse = await responseFuture.timeout(
          const Duration(milliseconds: 50),
        );
      } on TimeoutException {
        // Not ready yet, wait a bit and try again
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        controller.addError(e);
        await controller.close();
        return;
      }
    }

    // Emit the full response in chunks to simulate streaming
    final chunks = _splitIntoChunks(finalResponse, chunkSize: 5);
    for (final chunk in chunks) {
      controller.add(chunk);
      await Future.delayed(const Duration(milliseconds: 20));
    }

    await controller.close();
  }

  List<String> _splitIntoChunks(String text, {int chunkSize = 5}) {
    final chunks = <String>[];
    for (var i = 0; i < text.length; i += chunkSize) {
      chunks.add(text.substring(i, (i + chunkSize).clamp(0, text.length)));
    }
    return chunks;
  }

  @override
  String get modelType => 'hybrid';

  @override
  Future<List<int>> tokenize(
    final PromptValue promptValue, {
    final HybridChatModelOptions? options,
  }) async {
    // Simple tokenization by splitting on whitespace and counting words
    // This is a rough estimate since we don't have access to the actual tokenizer
    final text = promptValue.toString();
    return text.split(RegExp(r'\s+')).map((word) => word.hashCode).toList();
  }

  @override
  HybridChatModelOptions get defaultOptions => const HybridChatModelOptions();
}
