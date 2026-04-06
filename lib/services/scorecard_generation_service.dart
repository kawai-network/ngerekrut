library;

import '../models/hiring_models.dart';
import '../skills/hiring_service.dart';
import 'hybrid_ai_service.dart';

class GeneratedScorecard {
  final InterviewScorecard scorecard;
  final AIMode usedMode;

  const GeneratedScorecard({
    required this.scorecard,
    required this.usedMode,
  });
}

class ScorecardGenerationService {
  final HiringService _hiringService;

  ScorecardGenerationService({
    required HybridAIService aiService,
  }) : _hiringService = HiringService(aiService: aiService);

  Future<GeneratedScorecard> generateScorecard({
    required String role,
    required String candidateName,
    required InterviewType interviewType,
    String interviewer = 'NgeRekrut AI',
  }) async {
    final result = await _hiringService.createScorecard(
      role: role,
      candidate: candidateName,
      interviewer: interviewer,
      interviewType: interviewType,
    );
    final scorecard = result.asScorecard;
    if (scorecard == null) {
      throw Exception('AI tidak menghasilkan scorecard yang valid.');
    }
    return GeneratedScorecard(
      scorecard: scorecard,
      usedMode: result.usedMode,
    );
  }
}
