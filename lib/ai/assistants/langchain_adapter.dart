/// LangChain adapter for HybridAIService.
///
/// Wraps the existing HybridAIService as a LangChain-compatible BaseChatModel
/// so it can be used with LLMChain, ConversationBufferMemory, and PromptTemplate.
library;

import 'package:flutter/foundation.dart';

import '../../langchain/chat_models/chat_models.dart';
import '../../langchain/language_models/language_models.dart';
import '../../langchain/exceptions/exceptions.dart';
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
    List<dynamic>? tools,
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
        case AIChatMessage(:final content):
          // AI messages are part of history, skip for now
          break;
        default:
          break;
      }
    }

    // Build the prompt
    final fullPrompt = humanMessages.join('\n');
    final effectiveSystemPrompt =
        systemPrompt ?? defaultSystemPrompt ?? 'You are a helpful assistant.';

    try {
      final response = await service.generateLocalResponse(
        prompt: fullPrompt,
        systemPrompt: effectiveSystemPrompt,
      );

      return ChatResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        output: AIChatMessage(content: response),
        finishReason: FinishReason.stop,
        metadata: {
          'mode': service.lastUsedMode.name,
          'usedLocalAI': service.isLocalAIReady,
        },
        usage: const LanguageModelUsage(
          promptTokens: 0,
          completionTokens: 0,
          totalTokens: 0,
        ),
      );
    } catch (e) {
      throw LangChainException(message: 'Failed to generate response: $e');
    }
  }

  @override
  HybridChatModelOptions get defaultOptions => const HybridChatModelOptions();
}
