/// Data models for Hiring & Recruitment Skill
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'hiring_models.freezed.dart';
part 'hiring_models.g.dart';

/// Role level in engineering organization
enum RoleLevel {
  junior,
  mid,
  senior,
  staff,
  principal,
  manager,
  director,
}

/// Hiring urgency level
enum Urgency {
  low,
  medium,
  high,
  critical,
}

/// Interview type
enum InterviewType {
  technical,
  design,
  behavioral,
  finalRound,
  recruiter,
}

/// Hiring recommendation
enum HiringRecommendation {
  strongNoHire,
  noHire,
  hire,
  strongHire,
}

/// Competency areas for evaluation
enum Competency {
  technicalSkills,
  problemSolving,
  communication,
  collaboration,
  growthMindset,
  leadership,
}

// ==================== Job Description ====================

@freezed
abstract class JobDescription with _$JobDescription {
  const factory JobDescription({
    required String roleTitle,
    required String team,
    required String aboutRole,
    required List<String> responsibilities,
    required List<String> mustHave,
    required List<String> niceToHave,
    required List<String> interviewSteps,
    required String expectedTimeline,
    required List<String> benefits,
    String? compensationRange,
  }) = _JobDescription;

  factory JobDescription.fromJson(Map<String, dynamic> json) =>
      _$JobDescriptionFromJson(json);
}

// ==================== Interview Scorecard ====================

@freezed
abstract class ScorecardEntry with _$ScorecardEntry {
  const factory ScorecardEntry({
    required Competency competency,
    required int weight, // Percentage
    int? score, // 1-5
    String? evidence,
    required List<String> strongSignals,
    required List<String> concerns,
  }) = _ScorecardEntry;

  factory ScorecardEntry.fromJson(Map<String, dynamic> json) =>
      _$ScorecardEntryFromJson(json);
}

@freezed
abstract class InterviewScorecard with _$InterviewScorecard {
  const factory InterviewScorecard({
    required String candidate,
    required String role,
    required String interviewer,
    required DateTime date,
    required InterviewType interviewType,
    required List<ScorecardEntry> competencies,
    double? weightedScore,
    HiringRecommendation? recommendation,
    String? summary,
    String? nextSteps,
  }) = _InterviewScorecard;

  factory InterviewScorecard.fromJson(Map<String, dynamic> json) =>
      _$InterviewScorecardFromJson(json);
}

// ==================== STAR Interview Questions ====================

@freezed
abstract class STARQuestion with _$STARQuestion {
  const factory STARQuestion({
    required String competency,
    required String question,
    required List<String> lookFor,
  }) = _STARQuestion;

  factory STARQuestion.fromJson(Map<String, dynamic> json) =>
      _$STARQuestionFromJson(json);
}

@freezed
abstract class STARInterviewGuide with _$STARInterviewGuide {
  const factory STARInterviewGuide({
    required String role,
    required List<STARQuestion> questions,
    required String scoringGuide,
  }) = _STARInterviewGuide;

  factory STARInterviewGuide.fromJson(Map<String, dynamic> json) =>
      _$STARInterviewGuideFromJson(json);
}

// ==================== Hiring Metrics ====================

@freezed
abstract class HiringMetrics with _$HiringMetrics {
  const factory HiringMetrics({
    required Map<String, double> funnelMetrics,
    required Map<String, String> timeMetrics,
    required Map<String, double> qualityMetrics,
    required Map<String, String> targets,
    required List<String> redFlags,
  }) = _HiringMetrics;

  factory HiringMetrics.fromJson(Map<String, dynamic> json) =>
      _$HiringMetricsFromJson(json);
}

// ==================== Hiring Pipeline ====================

@freezed
abstract class HiringPipeline with _$HiringPipeline {
  const factory HiringPipeline({
    required String role,
    required RoleLevel roleLevel,
    required Urgency urgency,
    required DateTime postedDate,
    int? applicantsCount,
    int? screenedCount,
    int? interviewCount,
    int? offerCount,
    int? hiredCount,
    HiringMetrics? metrics,
  }) = _HiringPipeline;

  factory HiringPipeline.fromJson(Map<String, dynamic> json) =>
      _$HiringPipelineFromJson(json);
}

// ==================== Hiring Skill Request ====================

@freezed
abstract class HiringSkillRequest with _$HiringSkillRequest {
  const factory HiringSkillRequest({
    required String skill, // 'job_description', 'scorecard', 'star_questions', 'metrics'
    required Map<String, dynamic> parameters,
  }) = _HiringSkillRequest;

  factory HiringSkillRequest.fromJson(Map<String, dynamic> json) =>
      _$HiringSkillRequestFromJson(json);
}

// ==================== Hiring Skill Response ====================

@freezed
abstract class HiringSkillResponse with _$HiringSkillResponse {
  const factory HiringSkillResponse({
    required String skill,
    required Map<String, dynamic> data,
    String? textResponse,
  }) = _HiringSkillResponse;

  factory HiringSkillResponse.fromJson(Map<String, dynamic> json) =>
      _$HiringSkillResponseFromJson(json);
}
