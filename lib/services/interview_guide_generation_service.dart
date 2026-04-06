library;

import '../models/hiring_models.dart';
import '../skills/hiring_service.dart';
import 'hybrid_ai_service.dart';

class GeneratedInterviewGuide {
  final STARInterviewGuide guide;
  final AIMode usedMode;

  const GeneratedInterviewGuide({
    required this.guide,
    required this.usedMode,
  });
}

class InterviewGuideGenerationService {
  final HiringService _hiringService;

  InterviewGuideGenerationService({
    required HybridAIService aiService,
  }) : _hiringService = HiringService(aiService: aiService);

  Future<GeneratedInterviewGuide> generateGuide({
    required String role,
    List<String>? competencyFocus,
    int questionCount = 5,
  }) async {
    final result = await _hiringService.generateStarQuestions(
      role: role,
      competencyFocus: competencyFocus,
      questionCount: questionCount,
    );
    final guide = result.asStarGuide;
    if (guide == null) {
      throw Exception('AI tidak menghasilkan interview guide yang valid.');
    }
    return GeneratedInterviewGuide(
      guide: guide,
      usedMode: result.usedMode,
    );
  }
}
