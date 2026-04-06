/// Hiring Service - Orchestrates hiring skills with Gemma AI
library;

import '../services/hybrid_ai_service.dart';
import '../models/hiring_models.dart';
import 'hiring_skill.dart';

/// Result of hiring skill execution
class HiringSkillResult {
  final String skill;
  final Map<String, dynamic> data;
  final String? textResponse;
  final AIMode usedMode;

  const HiringSkillResult({
    required this.skill,
    required this.data,
    this.textResponse,
    required this.usedMode,
  });

  /// Get as JobDescription
  JobDescription? get asJobDescription => data.containsKey('roleTitle')
      ? JobDescription.fromJson(data)
      : null;

  /// Get as InterviewScorecard
  InterviewScorecard? get asScorecard => data.containsKey('candidate')
      ? InterviewScorecard.fromJson(data)
      : null;

  /// Get as STARInterviewGuide
  STARInterviewGuide? get asStarGuide => data.containsKey('questions')
      ? STARInterviewGuide.fromJson(data)
      : null;

  /// Get as HiringMetrics
  HiringMetrics? get asMetrics => data.containsKey('funnelMetrics')
      ? HiringMetrics.fromJson(data)
      : null;
}

/// Service for executing hiring skills with AI
class HiringService {
  final HybridAIService _aiService;

  HiringService({required HybridAIService aiService})
      : _aiService = aiService;

  // ==================== Job Description ====================

  /// Generate job description for a role
  Future<HiringSkillResult> generateJobDescription({
    required String roleTitle,
    required String team,
    required RoleLevel roleLevel,
    String? aboutRole,
    List<String>? responsibilities,
    List<String>? mustHave,
    List<String>? niceToHave,
    List<String>? benefits,
    String? compensationRange,
  }) async {
    final systemPrompt = HiringSkill.jobDescriptionPrompt;

    final userPrompt = _buildJobDescriptionPrompt(
      roleTitle: roleTitle,
      team: team,
      roleLevel: roleLevel,
      aboutRole: aboutRole,
    );

    final response = await _aiService.localAI.generateWithTools(
      prompt: userPrompt,
      tools: [HiringSkill.jobDescriptionTool],
      systemPrompt: systemPrompt,
    );

    // Parse function call result
    final functionData = HiringSkill.parseFunctionCall(
      response,
      (json) => json,
    );

    if (functionData != null) {
      return HiringSkillResult(
        skill: 'generate_job_description',
        data: functionData,
        textResponse: response,
        usedMode: AIMode.local,
      );
    }

    throw Exception('Failed to parse job description from AI response');
  }

  String _buildJobDescriptionPrompt({
    required String roleTitle,
    required String team,
    required RoleLevel roleLevel,
    String? aboutRole,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Buat job description lengkap untuk:');
    buffer.writeln('Posisi: $roleTitle');
    buffer.writeln('Team: $team');
    buffer.writeln('Level: ${roleLevel.name}');

    if (aboutRole != null) {
      buffer.writeln('Deskripsi: $aboutRole');
    }

    buffer.writeln('\nGunakan function generate_job_description dengan lengkap.');
    return buffer.toString();
  }

  // ==================== Interview Scorecard ====================

  /// Create interview scorecard
  Future<HiringSkillResult> createScorecard({
    required String role,
    required InterviewType interviewType,
    String candidate = 'Candidate Name',
    String interviewer = 'Interviewer Name',
    List<Map<String, dynamic>>? competencies,
  }) async {
    final systemPrompt = HiringSkill.scorecardPrompt;

    final userPrompt = _buildScorecardPrompt(
      role: role,
      interviewType: interviewType,
      competencies: competencies,
    );

    final response = await _aiService.localAI.generateWithTools(
      prompt: userPrompt,
      tools: [HiringSkill.scorecardTool],
      systemPrompt: systemPrompt,
    );

    final functionData = HiringSkill.parseFunctionCall(
      response,
      (json) => json,
    );

    if (functionData != null) {
      return HiringSkillResult(
        skill: 'create_interview_scorecard',
        data: functionData,
        textResponse: response,
        usedMode: AIMode.local,
      );
    }

    throw Exception('Failed to parse scorecard from AI response');
  }

  String _buildScorecardPrompt({
    required String role,
    required InterviewType interviewType,
    List<Map<String, dynamic>>? competencies,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Buat interview scorecard untuk:');
    buffer.writeln('Posisi: $role');
    buffer.writeln('Tipe interview: ${interviewType.name}');

    if (competencies != null && competencies.isNotEmpty) {
      buffer.writeln('\nKompetensi yang dinilai:');
      for (final comp in competencies) {
        buffer.writeln('- ${comp['competency']}: ${comp['weight']}%');
      }
    }

    buffer.writeln('\nGunakan function create_interview_scorecard.');
    return buffer.toString();
  }

  // ==================== STAR Questions ====================

  /// Generate STAR behavioral interview questions
  Future<HiringSkillResult> generateStarQuestions({
    required String role,
    List<String>? competencyFocus,
    int questionCount = 5,
  }) async {
    final systemPrompt = HiringSkill.starQuestionsPrompt;

    final userPrompt = _buildStarPrompt(
      role: role,
      competencyFocus: competencyFocus,
      questionCount: questionCount,
    );

    final response = await _aiService.localAI.generateWithTools(
      prompt: userPrompt,
      tools: [HiringSkill.starQuestionsTool],
      systemPrompt: systemPrompt,
    );

    final functionData = HiringSkill.parseFunctionCall(
      response,
      (json) => json,
    );

    if (functionData != null) {
      return HiringSkillResult(
        skill: 'generate_star_questions',
        data: functionData,
        textResponse: response,
        usedMode: AIMode.local,
      );
    }

    throw Exception('Failed to parse STAR questions from AI response');
  }

  String _buildStarPrompt({
    required String role,
    List<String>? competencyFocus,
    required int questionCount,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Buat $questionCount pertanyaan behavioral interview (STAR) untuk:');
    buffer.writeln('Posisi: $role');

    if (competencyFocus != null && competencyFocus.isNotEmpty) {
      buffer.writeln('Fokus kompetensi: ${competencyFocus.join(', ')}');
    }

    buffer.writeln('\nGunakan function generate_star_questions.');
    return buffer.toString();
  }

  // ==================== Hiring Metrics ====================

  /// Generate hiring pipeline metrics
  Future<HiringSkillResult> generateMetrics({
    required String role,
    int? teamSize,
    Urgency urgency = Urgency.medium,
  }) async {
    final systemPrompt = HiringSkill.metricsPrompt;

    final userPrompt = _buildMetricsPrompt(
      role: role,
      teamSize: teamSize,
      urgency: urgency,
    );

    final response = await _aiService.localAI.generateWithTools(
      prompt: userPrompt,
      tools: [HiringSkill.metricsTool],
      systemPrompt: systemPrompt,
    );

    final functionData = HiringSkill.parseFunctionCall(
      response,
      (json) => json,
    );

    if (functionData != null) {
      return HiringSkillResult(
        skill: 'generate_hiring_metrics',
        data: functionData,
        textResponse: response,
        usedMode: AIMode.local,
      );
    }

    throw Exception('Failed to parse hiring metrics from AI response');
  }

  String _buildMetricsPrompt({
    required String role,
    int? teamSize,
    required Urgency urgency,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Buat hiring metrics untuk:');
    buffer.writeln('Posisi: $role');
    buffer.writeln('Urgency: ${urgency.name}');

    if (teamSize != null) {
      buffer.writeln('Team size saat ini: $teamSize');
    }

    buffer.writeln('\nGunakan function generate_hiring_metrics.');
    return buffer.toString();
  }

  // ==================== Candidate Analysis ====================

  /// Analyze candidate fit for role
  Future<HiringSkillResult> analyzeCandidate({
    required String candidateName,
    required String role,
    required String experienceSummary,
    List<String>? keyStrengths,
    List<String>? concerns,
    String? interviewFeedback,
  }) async {
    final systemPrompt = HiringSkill.candidateAnalysisPrompt;

    final userPrompt = _buildCandidatePrompt(
      candidateName: candidateName,
      role: role,
      experienceSummary: experienceSummary,
      keyStrengths: keyStrengths,
      concerns: concerns,
      interviewFeedback: interviewFeedback,
    );

    final response = await _aiService.localAI.generateWithTools(
      prompt: userPrompt,
      tools: [HiringSkill.candidateAnalysisTool],
      systemPrompt: systemPrompt,
    );

    final functionData = HiringSkill.parseFunctionCall(
      response,
      (json) => json,
    );

    if (functionData != null) {
      return HiringSkillResult(
        skill: 'analyze_candidate_fit',
        data: functionData,
        textResponse: response,
        usedMode: AIMode.local,
      );
    }

    throw Exception('Failed to parse candidate analysis from AI response');
  }

  String _buildCandidatePrompt({
    required String candidateName,
    required String role,
    required String experienceSummary,
    List<String>? keyStrengths,
    List<String>? concerns,
    String? interviewFeedback,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Analisis kandidat untuk posisi $role:');
    buffer.writeln('Nama: $candidateName');
    buffer.writeln('Pengalaman: $experienceSummary');

    if (keyStrengths != null && keyStrengths.isNotEmpty) {
      buffer.writeln('\nKekuatan:');
      for (final strength in keyStrengths) {
        buffer.writeln('- $strength');
      }
    }

    if (concerns != null && concerns.isNotEmpty) {
      buffer.writeln('\nKekhawatiran:');
      for (final concern in concerns) {
        buffer.writeln('- $concern');
      }
    }

    if (interviewFeedback != null) {
      buffer.writeln('\nFeedback interview: $interviewFeedback');
    }

    buffer.writeln('\nGunakan function analyze_candidate_fit.');
    return buffer.toString();
  }

  // ==================== Generic Skill Execution ====================

  /// Execute any hiring skill with custom parameters
  Future<HiringSkillResult> executeSkill({
    required String skillName,
    required Map<String, dynamic> parameters,
  }) async {
    final tool = HiringSkill.getToolByName(skillName);
    if (tool == null) {
      throw ArgumentError('Unknown skill: $skillName');
    }

    final systemPrompt = HiringSkill.getSystemPrompt(skillName);

    final userPrompt = _buildGenericPrompt(skillName, parameters);

    final response = await _aiService.localAI.generateWithTools(
      prompt: userPrompt,
      tools: [tool],
      systemPrompt: systemPrompt,
    );

    final functionData = HiringSkill.parseFunctionCall(
      response,
      (json) => json,
    );

    if (functionData != null) {
      return HiringSkillResult(
        skill: skillName,
        data: functionData,
        textResponse: response,
        usedMode: AIMode.local,
      );
    }

    throw Exception('Failed to parse response from AI');
  }

  String _buildGenericPrompt(String skillName, Map<String, dynamic> parameters) {
    final buffer = StringBuffer();
    buffer.writeln('Execute skill: $skillName');

    if (parameters.isNotEmpty) {
      buffer.writeln('\nParameters:');
      parameters.forEach((key, value) {
        buffer.writeln('- $key: $value');
      });
    }

    buffer.writeln('\nGunakan function yang sesuai.');
    return buffer.toString();
  }

  /// Get all available skills
  List<Map<String, dynamic>> get availableSkills => HiringSkill.allTools;

  /// Get skill description
  String getSkillDescription(String skillName) {
    final tool = HiringSkill.getToolByName(skillName);
    return tool?['description'] ?? 'Unknown skill';
  }
}
