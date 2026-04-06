class RecruiterScoreBreakdown {
  final double skillMatch;
  final double relevantExperience;
  final double domainFit;
  final double communicationClarity;
  final double growthPotential;
  final double penalty;

  const RecruiterScoreBreakdown({
    required this.skillMatch,
    required this.relevantExperience,
    required this.domainFit,
    required this.communicationClarity,
    required this.growthPotential,
    required this.penalty,
  });

  factory RecruiterScoreBreakdown.fromJson(Map<String, dynamic> json) {
    double read(String key) => (json[key] as num?)?.toDouble() ?? 0;

    return RecruiterScoreBreakdown(
      skillMatch: read('skill_match'),
      relevantExperience: read('relevant_experience'),
      domainFit: read('domain_fit'),
      communicationClarity: read('communication_clarity'),
      growthPotential: read('growth_potential'),
      penalty: read('penalty'),
    );
  }
}

class RecruiterShortlistEntry {
  final String candidateId;
  final String candidateName;
  final int rank;
  final double totalScore;
  final RecruiterScoreBreakdown scoreBreakdown;
  final List<String> strengths;
  final List<String> gaps;
  final List<String> redFlags;
  final String recommendation;
  final String rationale;

  const RecruiterShortlistEntry({
    required this.candidateId,
    required this.candidateName,
    required this.rank,
    required this.totalScore,
    required this.scoreBreakdown,
    this.strengths = const [],
    this.gaps = const [],
    this.redFlags = const [],
    required this.recommendation,
    required this.rationale,
  });

  factory RecruiterShortlistEntry.fromJson(Map<String, dynamic> json) {
    return RecruiterShortlistEntry(
      candidateId: json['candidate_id'] as String,
      candidateName: json['candidate_name'] as String,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      totalScore: (json['total_score'] as num?)?.toDouble() ?? 0,
      scoreBreakdown: RecruiterScoreBreakdown.fromJson(
        json['score_breakdown'] as Map<String, dynamic>? ?? const {},
      ),
      strengths: (json['strengths'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      gaps: (json['gaps'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      redFlags: (json['red_flags'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      recommendation: json['recommendation'] as String? ?? 'review',
      rationale: json['rationale'] as String? ?? '',
    );
  }
}

class RecruiterShortlistResult {
  final String screeningId;
  final String jobId;
  final String status;
  final String summary;
  final int? createdAt;
  final String? usedMode;
  final List<RecruiterShortlistEntry> rankedCandidates;
  final List<RecruiterShortlistEntry> topCandidates;

  const RecruiterShortlistResult({
    required this.screeningId,
    required this.jobId,
    required this.status,
    required this.summary,
    this.createdAt,
    this.usedMode,
    this.rankedCandidates = const [],
    this.topCandidates = const [],
  });

  factory RecruiterShortlistResult.fromJson(Map<String, dynamic> json) {
    final ranked = (json['ranked_candidates'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RecruiterShortlistEntry.fromJson)
        .toList();
    final top = (json['top_candidates'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RecruiterShortlistEntry.fromJson)
        .toList();

    return RecruiterShortlistResult(
      screeningId: json['screening_id'] as String,
      jobId: json['job_id'] as String,
      status: json['status'] as String? ?? 'pending',
      summary: json['summary'] as String? ?? '',
      createdAt: (json['created_at'] as num?)?.toInt(),
      usedMode: json['used_mode'] as String?,
      rankedCandidates: ranked,
      topCandidates: top.isNotEmpty ? top : ranked.take(3).toList(),
    );
  }
}

class ScreeningRun {
  final String id;
  final String status;

  const ScreeningRun({
    required this.id,
    required this.status,
  });

  factory ScreeningRun.fromJson(Map<String, dynamic> json) {
    return ScreeningRun(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'pending',
    );
  }
}
