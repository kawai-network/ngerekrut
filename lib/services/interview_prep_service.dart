/// Interview Prep Service - Generate interview questions for jobseekers
library;

import '../models/hiring_models.dart';
import '../skills/hiring_service.dart';
import 'hybrid_ai_service.dart';

/// Result of interview guide generation for jobseekers
class InterviewPrepResult {
  final STARInterviewGuide guide;
  final String jobTitle;
  final AIMode usedMode;

  const InterviewPrepResult({
    required this.guide,
    required this.jobTitle,
    required this.usedMode,
  });
}

/// Service for generating interview preparation materials for jobseekers
class InterviewPrepService {
  final HiringService _hiringService;

  InterviewPrepService({required HybridAIService aiService})
      : _hiringService = HiringService(aiService: aiService);

  /// Generate interview questions based on job posting
  Future<InterviewPrepResult> generateForJob({
    required String jobTitle,
    List<String>? requirements,
    String? description,
    List<String>? competencyFocus,
    int questionCount = 5,
  }) async {
    // Build role description with context
    final roleContext = _buildRoleContext(
      jobTitle: jobTitle,
      requirements: requirements,
      description: description,
    );

    // Generate STAR questions
    final result = await _hiringService.generateStarQuestions(
      role: roleContext,
      competencyFocus: competencyFocus,
      questionCount: questionCount,
    );

    final guide = result.asStarGuide;
    if (guide == null) {
      throw Exception('AI tidak menghasilkan interview guide yang valid.');
    }

    return InterviewPrepResult(
      guide: guide,
      jobTitle: jobTitle,
      usedMode: result.usedMode,
    );
  }

  /// Generate interview questions with default competencies
  Future<InterviewPrepResult> generateWithDefaultCompetencies({
    required String jobTitle,
    List<String>? requirements,
    String? description,
    int questionCount = 5,
  }) async {
    // Default competencies for tech roles
    final defaultCompetencies = [
      'problemSolving',
      'communication',
      'collaboration',
      'growthMindset',
      'technicalSkills',
    ];

    return generateForJob(
      jobTitle: jobTitle,
      requirements: requirements,
      description: description,
      competencyFocus: defaultCompetencies,
      questionCount: questionCount,
    );
  }

  /// Build rich role context from job data
  String _buildRoleContext({
    required String jobTitle,
    List<String>? requirements,
    String? description,
  }) {
    final buffer = StringBuffer();
    buffer.write(jobTitle);

    if (description != null && description.isNotEmpty) {
      buffer.write(' - ');
      // Truncate description if too long
      final truncated = description.length > 100
          ? '${description.substring(0, 100)}...'
          : description;
      buffer.write(truncated);
    }

    if (requirements != null && requirements.isNotEmpty) {
      buffer.write('\nRequirements: ');
      buffer.write(requirements.take(5).join(', '));
    }

    return buffer.toString();
  }

  /// Get suggested competencies based on job title
  List<String> getSuggestedCompetencies(String jobTitle) {
    final lowerTitle = jobTitle.toLowerCase();

    // Tech roles focus
    if (lowerTitle.contains('developer') ||
        lowerTitle.contains('engineer') ||
        lowerTitle.contains('programmer')) {
      return [
        'technicalSkills',
        'problemSolving',
        'communication',
        'collaboration',
        'growthMindset',
      ];
    }

    // Leadership roles
    if (lowerTitle.contains('lead') ||
        lowerTitle.contains('manager') ||
        lowerTitle.contains('head')) {
      return [
        'leadership',
        'communication',
        'problemSolving',
        'collaboration',
        'growthMindset',
      ];
    }

    // Design roles
    if (lowerTitle.contains('design') ||
        lowerTitle.contains('ux') ||
        lowerTitle.contains('ui')) {
      return [
        'problemSolving',
        'communication',
        'collaboration',
        'growthMindset',
        'technicalSkills',
      ];
    }

    // Default competencies
    return [
      'problemSolving',
      'communication',
      'collaboration',
      'growthMindset',
      'technicalSkills',
    ];
  }
}
