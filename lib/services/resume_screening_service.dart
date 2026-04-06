library;

import 'dart:math';

import '../langchain_gemma/langchain_gemma.dart';
import '../models/recruiter_candidate.dart';
import '../models/recruiter_job.dart';
import '../models/recruiter_shortlist.dart';
import 'hybrid_ai_service.dart';

class ResumeScreeningService {
  final HybridAIService _aiService;

  const ResumeScreeningService({
    required HybridAIService aiService,
  }) : _aiService = aiService;

  Future<RecruiterShortlistResult> screenCandidates({
    required RecruiterJob job,
    required List<RecruiterCandidate> candidates,
    int topN = 3,
  }) async {
    if (candidates.isEmpty) {
      throw const LocalAIException('Tidak ada kandidat untuk disaring.');
    }

    final result = await _aiService.executeLocalToolCall<Map<String, dynamic>>(
      prompt: _buildPrompt(job: job, candidates: candidates, topN: topN),
      tools: [_screeningTool],
      systemPrompt: _systemPrompt,
      parser: (response) => LocalToolCallParser.parse(
        response,
        (json) => json,
      ),
      errorBuilder: (_) => 'Gagal parse hasil resume screening dari AI',
    );

    final normalized = _normalizeResult(
      raw: result.data,
      job: job,
      topN: topN,
    );
    return RecruiterShortlistResult.fromJson(normalized);
  }

  Map<String, dynamic> _normalizeResult({
    required Map<String, dynamic> raw,
    required RecruiterJob job,
    required int topN,
  }) {
    final rawRanked = (raw['ranked_candidates'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();

    final ranked = rawRanked
        .map((entry) => _normalizeEntry(entry))
        .toList()
      ..sort((a, b) {
        final scoreCompare = ((b['total_score'] as num?)?.toDouble() ?? 0)
            .compareTo(((a['total_score'] as num?)?.toDouble() ?? 0));
        if (scoreCompare != 0) return scoreCompare;
        return ((b['score_breakdown'] as Map<String, dynamic>?)?['relevant_experience']
                    as num? ??
                0)
            .compareTo(
              ((a['score_breakdown'] as Map<String, dynamic>?)?['relevant_experience']
                      as num? ??
                  0),
            );
      });

    final reranked = ranked.asMap().entries.map((entry) {
      return {
        ...entry.value,
        'rank': entry.key + 1,
      };
    }).toList();

    return {
      'screening_id':
          raw['screening_id'] as String? ??
          'local_${DateTime.now().millisecondsSinceEpoch}',
      'job_id': raw['job_id'] as String? ?? job.id,
      'status': raw['status'] as String? ?? 'completed',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'used_mode': _aiService.lastUsedMode.name,
      'summary':
          raw['summary'] as String? ??
          'Top ${min(topN, reranked.length)} kandidat disaring oleh AI di aplikasi.',
      'ranked_candidates': reranked,
      'top_candidates': reranked.take(topN).toList(),
    };
  }

  Map<String, dynamic> _normalizeEntry(Map<String, dynamic> raw) {
    final scoreBreakdown =
        raw['score_breakdown'] as Map<String, dynamic>? ?? const {};

    double readScore(String key) => (scoreBreakdown[key] as num?)?.toDouble() ?? 0;

    final normalizedScoreBreakdown = {
      'skill_match': readScore('skill_match'),
      'relevant_experience': readScore('relevant_experience'),
      'domain_fit': readScore('domain_fit'),
      'communication_clarity': readScore('communication_clarity'),
      'growth_potential': readScore('growth_potential'),
      'penalty': readScore('penalty'),
    };

    return {
      'candidate_id': raw['candidate_id'] as String,
      'candidate_name': raw['candidate_name'] as String,
      'rank': (raw['rank'] as num?)?.toInt() ?? 0,
      'total_score': (raw['total_score'] as num?)?.toDouble() ?? 0,
      'score_breakdown': normalizedScoreBreakdown,
      'strengths': (raw['strengths'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      'gaps': (raw['gaps'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      'red_flags': (raw['red_flags'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      'recommendation': raw['recommendation'] as String? ?? 'review',
      'rationale': raw['rationale'] as String? ?? '',
    };
  }

  String _buildPrompt({
    required RecruiterJob job,
    required List<RecruiterCandidate> candidates,
    required int topN,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Lakukan resume screening untuk lowongan berikut.');
    buffer.writeln('Job ID: ${job.id}');
    buffer.writeln('Role: ${job.title}');
    if (job.department != null) buffer.writeln('Department: ${job.department}');
    if (job.location != null) buffer.writeln('Location: ${job.location}');
    if (job.description != null) {
      buffer.writeln('Description: ${job.description}');
    }
    if (job.requirements.isNotEmpty) {
      buffer.writeln('Requirements:');
      for (final requirement in job.requirements) {
        buffer.writeln('- $requirement');
      }
    }

    buffer.writeln('\nPilih dan ranking semua kandidat, lalu siapkan Top $topN.');
    buffer.writeln('Kandidat:');
    for (final candidate in candidates) {
      buffer.writeln('\nCandidate ID: ${candidate.id}');
      buffer.writeln('Name: ${candidate.name}');
      if (candidate.headline != null) {
        buffer.writeln('Headline: ${candidate.headline}');
      }
      if (candidate.yearsOfExperience != null) {
        buffer.writeln(
          'Years of experience: ${candidate.yearsOfExperience}',
        );
      }
      if (candidate.profile?.skills.isNotEmpty ?? false) {
        buffer.writeln('Skills: ${candidate.profile!.skills.join(', ')}');
      }
      if ((candidate.profile?.summary ?? '').isNotEmpty) {
        buffer.writeln('Profile summary: ${candidate.profile!.summary}');
      }
    }

    buffer.writeln(
      '\nGunakan function screen_candidates_for_role dan berikan ranked_candidates lengkap.',
    );
    return buffer.toString();
  }

  static const Map<String, dynamic> _screeningTool = {
    'name': 'screen_candidates_for_role',
    'description':
        'Rank multiple candidates for a role and return shortlist-ready screening results',
    'parameters': {
      'type': 'object',
      'properties': {
        'screening_id': {'type': 'string'},
        'job_id': {'type': 'string'},
        'status': {'type': 'string'},
        'summary': {'type': 'string'},
        'ranked_candidates': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'candidate_id': {'type': 'string'},
              'candidate_name': {'type': 'string'},
              'rank': {'type': 'number'},
              'total_score': {'type': 'number'},
              'score_breakdown': {
                'type': 'object',
                'properties': {
                  'skill_match': {'type': 'number'},
                  'relevant_experience': {'type': 'number'},
                  'domain_fit': {'type': 'number'},
                  'communication_clarity': {'type': 'number'},
                  'growth_potential': {'type': 'number'},
                  'penalty': {'type': 'number'},
                },
                'required': [
                  'skill_match',
                  'relevant_experience',
                  'domain_fit',
                  'communication_clarity',
                  'growth_potential',
                  'penalty',
                ],
              },
              'strengths': {
                'type': 'array',
                'items': {'type': 'string'},
              },
              'gaps': {
                'type': 'array',
                'items': {'type': 'string'},
              },
              'red_flags': {
                'type': 'array',
                'items': {'type': 'string'},
              },
              'recommendation': {'type': 'string'},
              'rationale': {'type': 'string'},
            },
            'required': [
              'candidate_id',
              'candidate_name',
              'total_score',
              'score_breakdown',
              'strengths',
              'gaps',
              'red_flags',
              'recommendation',
              'rationale',
            ],
          },
        },
      },
      'required': ['summary', 'ranked_candidates'],
    },
  };

  static const String _systemPrompt = '''
You are an expert recruiter screening resumes for engineering and product roles.

Evaluate each candidate objectively using this rubric:
- skill_match: 0-35
- relevant_experience: 0-25
- domain_fit: 0-15
- communication_clarity: 0-10
- growth_potential: 0-10
- penalty: 0 to -15 for major concerns or missing requirements

Rules:
- Score every candidate against the same bar.
- Base the result only on the provided candidate profile and job context.
- Be concise and recruiter-friendly.
- ranked_candidates must contain all provided candidates.
- recommendation should be one of: shortlist, consider, reject.

Always respond with a function call to screen_candidates_for_role.
''';
}
