// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hiring_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JobDescription _$JobDescriptionFromJson(Map<String, dynamic> json) =>
    _JobDescription(
      roleTitle: json['role_title'] as String,
      team: json['team'] as String,
      aboutRole: json['about_role'] as String,
      responsibilities: (json['responsibilities'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      mustHave: (json['must_have'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      niceToHave: (json['nice_to_have'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      interviewSteps: (json['interviewSteps'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      expectedTimeline: json['expectedTimeline'] as String,
      benefits: (json['benefits'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      compensationRange: json['compensation_range'] as String?,
    );

Map<String, dynamic> _$JobDescriptionToJson(_JobDescription instance) =>
    <String, dynamic>{
      'role_title': instance.roleTitle,
      'team': instance.team,
      'about_role': instance.aboutRole,
      'responsibilities': instance.responsibilities,
      'must_have': instance.mustHave,
      'nice_to_have': instance.niceToHave,
      'interviewSteps': instance.interviewSteps,
      'expectedTimeline': instance.expectedTimeline,
      'benefits': instance.benefits,
      'compensation_range': ?instance.compensationRange,
    };

_ScorecardEntry _$ScorecardEntryFromJson(Map<String, dynamic> json) =>
    _ScorecardEntry(
      competency: $enumDecode(_$CompetencyEnumMap, json['competency']),
      weight: (json['weight'] as num).toInt(),
      score: (json['score'] as num?)?.toInt(),
      evidence: json['evidence'] as String?,
      strongSignals: (json['strongSignals'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      concerns: (json['concerns'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ScorecardEntryToJson(_ScorecardEntry instance) =>
    <String, dynamic>{
      'competency': _$CompetencyEnumMap[instance.competency]!,
      'weight': instance.weight,
      'score': ?instance.score,
      'evidence': ?instance.evidence,
      'strongSignals': instance.strongSignals,
      'concerns': instance.concerns,
    };

const _$CompetencyEnumMap = {
  Competency.technicalSkills: 'technicalSkills',
  Competency.problemSolving: 'problemSolving',
  Competency.communication: 'communication',
  Competency.collaboration: 'collaboration',
  Competency.growthMindset: 'growthMindset',
  Competency.leadership: 'leadership',
};

_InterviewScorecard _$InterviewScorecardFromJson(Map<String, dynamic> json) =>
    _InterviewScorecard(
      candidate: json['candidate'] as String,
      role: json['role'] as String,
      interviewer: json['interviewer'] as String,
      date: DateTime.parse(json['date'] as String),
      interviewType: $enumDecode(
        _$InterviewTypeEnumMap,
        json['interview_type'],
      ),
      competencies: (json['competencies'] as List<dynamic>)
          .map((e) => ScorecardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      weightedScore: (json['weightedScore'] as num?)?.toDouble(),
      recommendation: $enumDecodeNullable(
        _$HiringRecommendationEnumMap,
        json['recommendation'],
      ),
      summary: json['summary'] as String?,
      nextSteps: json['nextSteps'] as String?,
    );

Map<String, dynamic> _$InterviewScorecardToJson(_InterviewScorecard instance) =>
    <String, dynamic>{
      'candidate': instance.candidate,
      'role': instance.role,
      'interviewer': instance.interviewer,
      'date': instance.date.toIso8601String(),
      'interview_type': _$InterviewTypeEnumMap[instance.interviewType]!,
      'competencies': instance.competencies.map((e) => e.toJson()).toList(),
      'weightedScore': ?instance.weightedScore,
      'recommendation': ?_$HiringRecommendationEnumMap[instance.recommendation],
      'summary': ?instance.summary,
      'nextSteps': ?instance.nextSteps,
    };

const _$InterviewTypeEnumMap = {
  InterviewType.technical: 'technical',
  InterviewType.design: 'design',
  InterviewType.behavioral: 'behavioral',
  InterviewType.finalRound: 'finalRound',
  InterviewType.recruiter: 'recruiter',
};

const _$HiringRecommendationEnumMap = {
  HiringRecommendation.strongNoHire: 'strongNoHire',
  HiringRecommendation.noHire: 'noHire',
  HiringRecommendation.hire: 'hire',
  HiringRecommendation.strongHire: 'strongHire',
};

_STARQuestion _$STARQuestionFromJson(Map<String, dynamic> json) =>
    _STARQuestion(
      competency: json['competency'] as String,
      question: json['question'] as String,
      lookFor: (json['lookFor'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$STARQuestionToJson(_STARQuestion instance) =>
    <String, dynamic>{
      'competency': instance.competency,
      'question': instance.question,
      'lookFor': instance.lookFor,
    };

_STARInterviewGuide _$STARInterviewGuideFromJson(Map<String, dynamic> json) =>
    _STARInterviewGuide(
      role: json['role'] as String,
      questions: (json['questions'] as List<dynamic>)
          .map((e) => STARQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      scoringGuide: json['scoring_guide'] as String,
    );

Map<String, dynamic> _$STARInterviewGuideToJson(_STARInterviewGuide instance) =>
    <String, dynamic>{
      'role': instance.role,
      'questions': instance.questions.map((e) => e.toJson()).toList(),
      'scoring_guide': instance.scoringGuide,
    };

_HiringMetrics _$HiringMetricsFromJson(Map<String, dynamic> json) =>
    _HiringMetrics(
      funnelMetrics: (json['funnelMetrics'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      timeMetrics: Map<String, String>.from(json['timeMetrics'] as Map),
      qualityMetrics: (json['qualityMetrics'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      targets: Map<String, String>.from(json['targets'] as Map),
      redFlags: (json['redFlags'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$HiringMetricsToJson(_HiringMetrics instance) =>
    <String, dynamic>{
      'funnelMetrics': instance.funnelMetrics,
      'timeMetrics': instance.timeMetrics,
      'qualityMetrics': instance.qualityMetrics,
      'targets': instance.targets,
      'redFlags': instance.redFlags,
    };

_HiringPipeline _$HiringPipelineFromJson(Map<String, dynamic> json) =>
    _HiringPipeline(
      role: json['role'] as String,
      roleLevel: $enumDecode(_$RoleLevelEnumMap, json['role_level']),
      urgency: $enumDecode(_$UrgencyEnumMap, json['urgency']),
      postedDate: DateTime.parse(json['posted_date'] as String),
      applicantsCount: (json['applicants_count'] as num?)?.toInt(),
      screenedCount: (json['screened_count'] as num?)?.toInt(),
      interviewCount: (json['interview_count'] as num?)?.toInt(),
      offerCount: (json['offer_count'] as num?)?.toInt(),
      hiredCount: (json['hired_count'] as num?)?.toInt(),
      metrics: json['metrics'] == null
          ? null
          : HiringMetrics.fromJson(json['metrics'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$HiringPipelineToJson(_HiringPipeline instance) =>
    <String, dynamic>{
      'role': instance.role,
      'role_level': _$RoleLevelEnumMap[instance.roleLevel]!,
      'urgency': _$UrgencyEnumMap[instance.urgency]!,
      'posted_date': instance.postedDate.toIso8601String(),
      'applicants_count': ?instance.applicantsCount,
      'screened_count': ?instance.screenedCount,
      'interview_count': ?instance.interviewCount,
      'offer_count': ?instance.offerCount,
      'hired_count': ?instance.hiredCount,
      'metrics': ?instance.metrics?.toJson(),
    };

const _$RoleLevelEnumMap = {
  RoleLevel.junior: 'junior',
  RoleLevel.mid: 'mid',
  RoleLevel.senior: 'senior',
  RoleLevel.staff: 'staff',
  RoleLevel.principal: 'principal',
  RoleLevel.manager: 'manager',
  RoleLevel.director: 'director',
};

const _$UrgencyEnumMap = {
  Urgency.low: 'low',
  Urgency.medium: 'medium',
  Urgency.high: 'high',
  Urgency.critical: 'critical',
};

_HiringSkillRequest _$HiringSkillRequestFromJson(Map<String, dynamic> json) =>
    _HiringSkillRequest(
      skill: json['skill'] as String,
      parameters: json['parameters'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$HiringSkillRequestToJson(_HiringSkillRequest instance) =>
    <String, dynamic>{
      'skill': instance.skill,
      'parameters': instance.parameters,
    };

_HiringSkillResponse _$HiringSkillResponseFromJson(Map<String, dynamic> json) =>
    _HiringSkillResponse(
      skill: json['skill'] as String,
      data: json['data'] as Map<String, dynamic>,
      textResponse: json['textResponse'] as String?,
    );

Map<String, dynamic> _$HiringSkillResponseToJson(
  _HiringSkillResponse instance,
) => <String, dynamic>{
  'skill': instance.skill,
  'data': instance.data,
  'textResponse': ?instance.textResponse,
};
