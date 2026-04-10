import 'package:flutter_test/flutter_test.dart';
import 'package:ngerekrut/langchain_gemma/langchain_gemma.dart';
import 'package:ngerekrut/models/hiring_models.dart';
import 'package:ngerekrut/services/hybrid_ai_service.dart';
import 'package:ngerekrut/skills/hiring_service.dart';

class _FakeLocalAIClient implements LocalAIClient {
  _FakeLocalAIClient(this.toolResponse);

  final String toolResponse;

  @override
  String? get errorMessage => null;

  @override
  bool get isReady => true;

  @override
  LocalAIStatus get status => LocalAIStatus.ready;

  @override
  Future<void> dispose() async {}

  @override
  Future<String> generateResponse({
    required String prompt,
    String? systemPrompt,
  }) async => toolResponse;

  @override
  Future<String> generateWithTools({
    required String prompt,
    required List<Map<String, dynamic>> tools,
    String? systemPrompt,
  }) async => toolResponse;

  @override
  Future<LocalAIStatus> initialize({
    void Function(double progress)? onProgress,
  }) async => LocalAIStatus.ready;
}

void main() {
  group('HiringService', () {
    test('generateMetrics parses structured local response', () async {
      final hybrid = HybridAIService(
        cloudApiKey: 'test-key',
        localAI: _FakeLocalAIClient(
          '{"funnel_metrics":{"screenToInterview":0.4},"time_metrics":{"timeToHire":"14 days"},"quality_metrics":{"offerAcceptance":0.8},"targets":{"timeToHire":"10 days"},"red_flags":["low pipeline"]}',
        ),
      );
      final service = HiringService(aiService: hybrid);

      final result = await service.generateMetrics(
        role: 'Backend Engineer',
        urgency: Urgency.high,
      );

      expect(result.skill, 'generate_hiring_metrics');
      expect(result.usedMode, AIMode.local);
      expect(result.asMetrics, isNotNull);
      expect(result.asMetrics!.funnelMetrics['screenToInterview'], 0.4);
      expect(result.asMetrics!.redFlags, contains('low pipeline'));
    });

    test('createScorecard parses competencies from local response', () async {
      final hybrid = HybridAIService(
        cloudApiKey: 'test-key',
        localAI: _FakeLocalAIClient(
          '{"candidate":"Candidate Name","role":"Backend Engineer","interviewer":"Interviewer Name","date":"2026-04-06T00:00:00.000","interview_type":"technical","competencies":[{"competency":"technicalSkills","weight":50,"strong_signals":["clean design"],"concerns":["slow debugging"]}]}',
        ),
      );
      final service = HiringService(aiService: hybrid);

      final result = await service.createScorecard(
        role: 'Backend Engineer',
        interviewType: InterviewType.technical,
      );

      expect(result.asScorecard, isNotNull);
      expect(result.asScorecard!.competencies, hasLength(1));
      expect(
        result.asScorecard!.competencies.first.competency,
        Competency.technicalSkills,
      );
    });

    test('generateJobDescription parses snake_case response fields', () async {
      final hybrid = HybridAIService(
        cloudApiKey: 'test-key',
        localAI: _FakeLocalAIClient(
          '{"role_title":"Backend Engineer","team":"Platform","about_role":"Build internal platform systems.","responsibilities":["Build APIs"],"must_have":["Dart"],"nice_to_have":["Go"],"interview_steps":["Recruiter screen","Tech interview"],"expected_timeline":"2 weeks","benefits":["Remote"],"compensation_range":"20-25 juta"}',
        ),
      );
      final service = HiringService(aiService: hybrid);

      final result = await service.generateJobDescription(
        roleTitle: 'Backend Engineer',
        team: 'Platform',
        roleLevel: RoleLevel.senior,
      );

      expect(result.asJobDescription, isNotNull);
      expect(result.asJobDescription!.roleTitle, 'Backend Engineer');
      expect(result.asJobDescription!.interviewSteps, hasLength(2));
      expect(result.asJobDescription!.compensationRange, '20-25 juta');
    });

    test('generateStarQuestions parses nested snake_case question fields', () async {
      final hybrid = HybridAIService(
        cloudApiKey: 'test-key',
        localAI: _FakeLocalAIClient(
          '{"role":"Backend Engineer","questions":[{"competency":"problem solving","question":"Ceritakan masalah produksi tersulit yang pernah Anda tangani.","look_for":["ownership","structured debugging"]}],"scoring_guide":"Nilai detail tindakan, dampak, dan pembelajaran."}',
        ),
      );
      final service = HiringService(aiService: hybrid);

      final result = await service.generateStarQuestions(
        role: 'Backend Engineer',
      );

      expect(result.asStarGuide, isNotNull);
      expect(result.asStarGuide!.role, 'Backend Engineer');
      expect(result.asStarGuide!.questions, hasLength(1));
      expect(
        result.asStarGuide!.questions.first.lookFor,
        contains('structured debugging'),
      );
      expect(
        result.asStarGuide!.scoringGuide,
        contains('pembelajaran'),
      );
    });

    test('analyzeCandidate preserves candidate-analysis payload', () async {
      final hybrid = HybridAIService(
        cloudApiKey: 'test-key',
        localAI: _FakeLocalAIClient(
          '{"candidate_name":"Rina","role":"Backend Engineer","experience_summary":"5 tahun membangun API dan sistem antrian.","key_strengths":["API design","mentoring"],"concerns":["depth in distributed systems"],"interview_feedback":"Komunikasi jelas dan terstruktur."}',
        ),
      );
      final service = HiringService(aiService: hybrid);

      final result = await service.analyzeCandidate(
        candidateName: 'Rina',
        role: 'Backend Engineer',
        experienceSummary: '5 tahun membangun API dan sistem antrian.',
      );

      expect(result.skill, 'analyze_candidate_fit');
      expect(result.data['candidate_name'], 'Rina');
      expect(result.data['key_strengths'], contains('API design'));
      expect(
        result.data['interview_feedback'],
        contains('terstruktur'),
      );
    });

    test('executeSkill normalizes generic metrics payload', () async {
      final hybrid = HybridAIService(
        cloudApiKey: 'test-key',
        localAI: _FakeLocalAIClient(
          '{"funnel_metrics":{"onsiteToOffer":0.5},"time_metrics":{"timeToOffer":"7 days"},"quality_metrics":{"offerAcceptance":0.9},"targets":{"timeToOffer":"5 days"},"red_flags":["narrow funnel"]}',
        ),
      );
      final service = HiringService(aiService: hybrid);

      final result = await service.executeSkill(
        skillName: 'generate_hiring_metrics',
        parameters: {
          'role': 'Backend Engineer',
          'urgency': 'high',
        },
      );

      expect(result.skill, 'generate_hiring_metrics');
      expect(result.asMetrics, isNotNull);
      expect(result.asMetrics!.funnelMetrics['onsiteToOffer'], 0.5);
      expect(result.asMetrics!.redFlags, contains('narrow funnel'));
    });
  });
}
