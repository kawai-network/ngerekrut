/// Candidate data models (shared between recruiter & jobseeker apps)
library;

/// Reusable: resume/CV data
class CandidateResume {
  final String id;
  final String fileName;
  final String? fileUrl;

  const CandidateResume({
    required this.id,
    required this.fileName,
    this.fileUrl,
  });

  factory CandidateResume.fromJson(Map<String, dynamic> json) {
    return CandidateResume(
      id: json['id'] as String,
      fileName: json['file_name'] as String? ?? 'resume.pdf',
      fileUrl: json['file_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'file_name': fileName,
    if (fileUrl != null) 'file_url': fileUrl,
  };
}

/// Reusable: candidate profile data (skills, summary)
class CandidateProfile {
  final List<String> skills;
  final String summary;

  const CandidateProfile({
    this.skills = const [],
    required this.summary,
  });

  factory CandidateProfile.fromJson(Map<String, dynamic> json) {
    return CandidateProfile(
      skills: (json['skills'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      summary: json['summary'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'skills': skills,
    'summary': summary,
  };

  CandidateProfile copyWith({
    List<String>? skills,
    String? summary,
  }) {
    return CandidateProfile(
      skills: skills ?? this.skills,
      summary: summary ?? this.summary,
    );
  }
}

/// Recruiter-only: internal candidate tracking
class RecruiterCandidate {
  final String id;
  final String name;
  final String? headline;
  final int? yearsOfExperience;
  final String stage;
  final CandidateResume? resume;
  final CandidateProfile? profile;

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
          ? CandidateResume.fromJson(resume)
          : null,
      profile: profile is Map<String, dynamic>
          ? CandidateProfile.fromJson(profile)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (headline != null) 'headline': headline,
    if (yearsOfExperience != null) 'years_of_experience': yearsOfExperience,
    'stage': stage,
    if (resume != null) 'resume': resume!.toJson(),
    if (profile != null) 'profile': profile!.toJson(),
  };
}
