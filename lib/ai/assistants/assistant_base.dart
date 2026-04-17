/// Base architecture for per-tab AI assistants.
library;

import 'package:flutter/material.dart';

/// Configuration for a tab-specific AI assistant.
class AssistantConfig {
  /// Unique identifier for the assistant.
  final String id;

  /// Display name of the assistant.
  final String name;

  /// Short role title shown in profile-style UI.
  final String title;

  /// Assistant description for the current workflow context.
  final String description;

  /// Local avatar asset for profile-style UI.
  final String avatarAsset;

  /// Icon to represent the assistant.
  final IconData icon;

  /// Theme color for the assistant's UI elements.
  final Color themeColor;

  /// System prompt that defines the assistant's persona and behavior.
  final String systemPrompt;

  /// Quick action suggestions relevant to this assistant.
  final List<String> quickActions;

  /// Welcome message shown when the assistant chat is first opened.
  final String welcomeMessage;

  /// FAB label text (short).
  final String fabLabel;

  const AssistantConfig({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.avatarAsset,
    required this.icon,
    required this.themeColor,
    required this.systemPrompt,
    required this.quickActions,
    required this.welcomeMessage,
    required this.fabLabel,
  });
}

/// Result of an assistant AI generation.
class AssistantResult {
  final String content;
  final bool usedLocalAI;
  final DateTime timestamp;

  const AssistantResult({
    required this.content,
    required this.usedLocalAI,
    required this.timestamp,
  });
}

/// Modes for assistant AI selection.
enum AssistantMode {
  /// Use local AI only
  local,

  /// Use cloud AI only
  cloud,

  /// Auto - try local first, fallback to cloud
  auto,
}
