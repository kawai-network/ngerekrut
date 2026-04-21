/// Job Matching Service - Match jobs with user's CV skills and experience
library;

import '../models/recruiter_job.dart';
import '../repositories/candidate_repository.dart';
import '../repositories/job_posting_repository.dart';

/// Result of job matching with score
class JobMatchResult {
  final RecruiterJob job;
  final int matchScore;
  final List<String> matchingSkills;
  final List<String> missingSkills;
  final String experienceLabel;

  const JobMatchResult({
    required this.job,
    required this.matchScore,
    required this.matchingSkills,
    required this.missingSkills,
    required this.experienceLabel,
  });

  /// Get match category for styling
  MatchCategory get category {
    if (matchScore >= 80) return MatchCategory.veryHigh;
    if (matchScore >= 60) return MatchCategory.high;
    if (matchScore >= 40) return MatchCategory.medium;
    return MatchCategory.low;
  }
}

/// Match category for UI styling
enum MatchCategory {
  veryHigh, // 80-100%
  high,     // 60-79%
  medium,   // 40-59%
  low,      // 0-39%
}

/// Service for matching jobs with user's CV
class JobMatchingService {
  final CandidateRepository _candidateRepo;
  final JobPostingRepository _jobRepo;

  // Common tech skills for matching
  static const _techSkills = {
    // Languages
    'flutter', 'dart', 'javascript', 'typescript', 'python', 'java', 'go',
    'golang', 'rust', 'c++', 'c#', 'c', 'php', 'ruby', 'swift', 'kotlin',
    // Frontend
    'react', 'vue', 'angular', 'svelte', 'next.js', 'nuxt', 'jquery',
    // Backend
    'express', 'fastapi', 'django', 'flask', 'spring', 'laravel', 'nest',
    // Mobile
    'react native', 'swiftui', 'android', 'ios',
    // Database
    'postgresql', 'mysql', 'mongodb', 'sqlite', 'firebase', 'supabase',
    // Cloud
    'aws', 'gcp', 'azure', 'vercel', 'netlify', 'heroku', 'digitalocean',
    // Tools
    'docker', 'kubernetes', 'k8s', 'git', 'ci/cd', 'jenkins', 'github',
    'gitlab', 'bitbucket', 'jira', 'confluence',
    // Other
    'rest', 'graphql', 'grpc', 'microservices', 'agile', 'scrum',
  };

  JobMatchingService({
    CandidateRepository? candidateRepo,
    JobPostingRepository? jobRepo,
  })  : _candidateRepo = candidateRepo ?? CandidateRepository(),
      _jobRepo = jobRepo ?? JobPostingRepository();

  /// Get recommended jobs for the user based on their CV
  Future<List<JobMatchResult>> getRecommendedJobs({
    String? userId,
    int? minScore,
    int limit = 20,
  }) async {
    // Get user CV data
    final candidate = userId != null
        ? await _candidateRepo.getById(userId)
        : await _candidateRepo.getById(
            // Import from shared_identity_service if needed
            'jobseeker_123', // Fallback
          );

    if (candidate == null || candidate.profile == null) {
      return [];
    }

    final userSkills = candidate.profile!.skills.map((s) => s.toLowerCase()).toSet();
    final userExp = candidate.yearsOfExperience ?? 0;

    // Get all active jobs
    final jobs = await _jobRepo.getActive();

    // Calculate match scores
    final results = <JobMatchResult>[];
    for (final job in jobs) {
      final matchScore = _calculateMatchScore(
        job: job,
        userSkills: userSkills,
        userExp: userExp,
      );

      if (matchScore.matchScore >= (minScore ?? 0)) {
        results.add(matchScore);
      }
    }

    // Sort by match score descending
    results.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    // Limit results
    return results.take(limit).toList();
  }

  /// Calculate match score for a job (0-100)
  JobMatchResult _calculateMatchScore({
    required RecruiterJob job,
    required Set<String> userSkills,
    required int userExp,
  }) {
    // 1. Extract skills from job requirements
    final jobSkills = _extractSkillsFromJob(job);

    // 2. Calculate skill match score (70%)
    final skillScore = _calculateSkillScore(userSkills, jobSkills);

    // 3. Calculate experience match score (30%)
    final expScore = _calculateExperienceScore(userExp, job.title, jobSkills);

    // 4. Total score
    final totalScore = (skillScore + expScore).round();

    // 5. Determine matching and missing skills
    final matchingSkills = userSkills.where((skill) => jobSkills.contains(skill)).toList();
    final missingSkills = jobSkills.where((skill) => !userSkills.contains(skill)).toList();

    // 6. Determine experience label
    final expLabel = _getExperienceLabel(userExp, job.title);

    return JobMatchResult(
      job: job,
      matchScore: totalScore,
      matchingSkills: matchingSkills.toList(),
      missingSkills: missingSkills.toList(),
      experienceLabel: expLabel,
    );
  }

  /// Calculate skill match score (0-70)
  int _calculateSkillScore(Set<String> userSkills, Set<String> jobSkills) {
    if (jobSkills.isEmpty) return 35; // Default mid score if no requirements

    final matchingCount = userSkills.where((skill) => jobSkills.contains(skill)).length;
    final ratio = jobSkills.isEmpty ? 0 : matchingCount / jobSkills.length;
    return (ratio * 70).round();
  }

  /// Calculate experience match score (0-30)
  int _calculateExperienceScore(int userExp, String jobTitle, Set<String> jobSkills) {
    final jobLevel = _detectJobLevel(jobTitle, jobSkills);

    if (jobLevel == JobLevel.junior) {
      if (userExp <= 2) return 30;
      if (userExp <= 5) return 10;
      return 0;
    } else if (jobLevel == JobLevel.mid) {
      if (userExp <= 2) return 10;
      if (userExp <= 5) return 30;
      if (userExp > 5) return 20;
      return 10;
    } else { // senior
      if (userExp <= 2) return 0;
      if (userExp <= 5) return 20;
      return 30;
    }
  }

  /// Detect job level from title and requirements
  JobLevel _detectJobLevel(String title, Set<String> jobSkills) {
    final lowerTitle = title.toLowerCase();

    // Senior indicators
    if (lowerTitle.contains('senior') ||
        lowerTitle.contains('lead') ||
        lowerTitle.contains('principal') ||
        lowerTitle.contains('staff') ||
        lowerTitle.contains('architect') ||
        jobSkills.contains('leadership') ||
        jobSkills.contains('architecture')) {
      return JobLevel.senior;
    }

    // Junior indicators
    if (lowerTitle.contains('junior') ||
        lowerTitle.contains('fresh graduate') ||
        lowerTitle.contains('entry level') ||
        lowerTitle.contains('magang') ||
        lowerTitle.contains('associate') ||
        lowerTitle.contains('assist')) {
      return JobLevel.junior;
    }

    // Default to mid
    return JobLevel.mid;
  }

  /// Extract skills from job requirements text
  Set<String> _extractSkillsFromJob(RecruiterJob job) {
    final skills = <String>{};

    // Add from requirements
    for (final req in job.requirements) {
      final lowerReq = req.toLowerCase();
      for (final skill in _techSkills) {
        if (lowerReq.contains(skill)) {
          skills.add(skill);
        }
      }
    }

    // Add from title (e.g., "Flutter Developer")
    final lowerTitle = job.title.toLowerCase();
    for (final skill in _techSkills) {
      if (lowerTitle.contains(skill)) {
        skills.add(skill);
      }
    }

    // Add from description if available
    if (job.description != null) {
      final lowerDesc = job.description!.toLowerCase();
      for (final skill in _techSkills) {
        if (lowerDesc.contains(skill)) {
          skills.add(skill);
        }
      }
    }

    return skills;
  }

  /// Get experience label for display
  String _getExperienceLabel(int userExp, String jobTitle) {
    final jobLevel = _detectJobLevel(jobTitle, {});

    if (jobLevel == JobLevel.junior) {
      if (userExp <= 2) return 'Pengalaman kamu cocok!';
      if (userExp <= 5) return 'Overqualified tapi bisa coba';
      return 'Terlalu senior untuk posisi ini';
    } else if (jobLevel == JobLevel.mid) {
      if (userExp <= 2) return 'Belum cukup pengalaman';
      if (userExp <= 5) return 'Pengalaman kamu pas!';
      return 'Pengalaman kamu lebih!';
    } else { // senior
      if (userExp <= 5) return 'Belum cukup pengalaman';
      return 'Pengalaman kamu cocok!';
    }
  }
}

enum JobLevel { junior, mid, senior }
