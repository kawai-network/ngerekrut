class RecruiterResume {
  final String id;
  final String fileName;

  const RecruiterResume({
    required this.id,
    required this.fileName,
  });

  factory RecruiterResume.fromJson(Map<String, dynamic> json) {
    return RecruiterResume(
      id: json['id'] as String,
      fileName: json['file_name'] as String? ?? 'resume.pdf',
    );
  }
}

class RecruiterCandidateProfile {
  final List<String> skills;
  final String summary;

  const RecruiterCandidateProfile({
    this.skills = const [],
    required this.summary,
  });

  factory RecruiterCandidateProfile.fromJson(Map<String, dynamic> json) {
    return RecruiterCandidateProfile(
      skills: (json['skills'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      summary: json['summary'] as String? ?? '',
    );
  }
}

class RecruiterCandidate {
  final String id;
  final String name;
  final String? headline;
  final int? yearsOfExperience;
  final String stage;
  final RecruiterResume? resume;
  final RecruiterCandidateProfile? profile;

  const RecruiterCandidate({
    required this.id,
    required this.name,
    this.headline,
    this.yearsOfExperience,
    required this.stage,
    this.resume,
    this.profile,
  });

  factory RecruiterCandidate.fromJson(Map<String, dynamic> json) {
    final resume = json['resume'];
    final profile = json['profile'];

    return RecruiterCandidate(
      id: json['id'] as String,
      name: json['name'] as String,
      headline: json['headline'] as String?,
      yearsOfExperience: (json['years_of_experience'] as num?)?.toInt(),
      stage: json['stage'] as String? ?? 'applied',
      resume: resume is Map<String, dynamic>
          ? RecruiterResume.fromJson(resume)
          : null,
      profile: profile is Map<String, dynamic>
          ? RecruiterCandidateProfile.fromJson(profile)
          : null,
    );
  }
}
