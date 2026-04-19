/// Manager for per-tab AI assistants.
///
/// Provides easy access to the correct assistant config based on the
/// currently selected tab index.
library;

import 'assistant_base.dart';
import 'raka_job_assistant.dart';
import 'aria_screening_assistant.dart';
import 'bima_interview_assistant.dart';

/// Maps tab index to the corresponding assistant config.
class AssistantManager {
  /// Tab indices mapping:
  /// 0 = Dashboard (no assistant)
  /// 1 = Lowongan (Raka)
  /// 2 = Kandidat (Aria)
  /// 3 = Interview (Bima)
  static const _assistantMap = {
    1: RakaAssistant.config,
    2: AriaAssistant.config,
    3: BimaAssistant.config,
  };

  /// Get the assistant config for a given tab index.
  ///
  /// Returns `null` if the index is out of range.
  static AssistantConfig? getAssistantForTab(int tabIndex) {
    return _assistantMap[tabIndex];
  }

  /// Get all registered assistant configs.
  static List<AssistantConfig> getAllAssistants() {
    return _assistantMap.values.toList();
  }

  /// Get assistant by ID (useful for cross-tab calls).
  static AssistantConfig? getAssistantById(String id) {
    for (final assistant in _assistantMap.values) {
      if (assistant.id == id) return assistant;
    }
    return null;
  }

  /// Get the default tab index for a given assistant ID.
  static int? getTabForAssistant(String id) {
    for (final entry in _assistantMap.entries) {
      if (entry.value.id == id) return entry.key;
    }
    return null;
  }
}
