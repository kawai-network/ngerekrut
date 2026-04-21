/// Job application tracking model (shared: recruiter & jobseeker)
library;

import 'package:json_annotation/json_annotation.dart';
import 'application_status.dart';

part 'job_application.g.dart';

@JsonSerializable()
class JobApplication {
  /// Unique ID for this application
  final String id;

  /// Job ID from the job posting
  @JsonKey(name: 'job_id')
  final String jobId;

  /// Candidate ID (for recruiter to track who applied)
  @JsonKey(name: 'candidate_id')
  final String? candidateId;

  /// Job title (cached for offline display)
  @JsonKey(name: 'job_title')
  final String jobTitle;

  /// Company/organization name
  final String? company;

  /// Location of the job
  final String? location;

  /// Current status of the application
  final ApplicationStatus status;

  /// When the application was submitted
  @JsonKey(name: 'applied_at')
  final DateTime appliedAt;

  /// When the status was last updated
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  /// Expected salary (optional)
  @JsonKey(name: 'expected_salary')
  final String? expectedSalary;

  /// Cover letter or notes
  @JsonKey(name: 'cover_letter')
  final String? coverLetter;

  /// Resume/CV ID used for this application
  @JsonKey(name: 'resume_id')
  final String? resumeId;

  /// Interview dates (if any)
  @JsonKey(name: 'interview_dates')
  final List<DateTime>? interviewDates;

  /// Rejection reason (if rejected)
  @JsonKey(name: 'rejection_reason')
  final String? rejectionReason;

  /// Recruiter's internal notes about this application
  @JsonKey(name: 'recruiter_notes')
  final String? recruiterNotes;

  /// Internal rating from recruiter (1-5)
  @JsonKey(name: 'internal_rating')
  final int? internalRating;

  /// Application source (LinkedIn, referral, website, etc.)
  final String? source;

  const JobApplication({
    required this.id,
    required this.jobId,
    this.candidateId,
    required this.jobTitle,
    this.company,
    this.location,
    required this.status,
    required this.appliedAt,
    required this.updatedAt,
    this.expectedSalary,
    this.coverLetter,
    this.resumeId,
    this.interviewDates,
    this.rejectionReason,
    this.recruiterNotes,
    this.internalRating,
    this.source,
  });

  factory JobApplication.fromJson(Map<String, dynamic> json) =>
      _$JobApplicationFromJson(json);

  Map<String, dynamic> toJson() => _$JobApplicationToJson(this);

  JobApplication copyWith({
    String? id,
    String? jobId,
    String? candidateId,
    String? jobTitle,
    String? company,
    String? location,
    ApplicationStatus? status,
    DateTime? appliedAt,
    DateTime? updatedAt,
    String? expectedSalary,
    String? coverLetter,
    String? resumeId,
    List<DateTime>? interviewDates,
    String? rejectionReason,
    String? recruiterNotes,
    int? internalRating,
    String? source,
  }) {
    return JobApplication(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      candidateId: candidateId ?? this.candidateId,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      location: location ?? this.location,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expectedSalary: expectedSalary ?? this.expectedSalary,
      coverLetter: coverLetter ?? this.coverLetter,
      resumeId: resumeId ?? this.resumeId,
      interviewDates: interviewDates ?? this.interviewDates,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      recruiterNotes: recruiterNotes ?? this.recruiterNotes,
      internalRating: internalRating ?? this.internalRating,
      source: source ?? this.source,
    );
  }

  /// Create a new application (when user applies to a job)
  factory JobApplication.create({
    required String jobId,
    required String jobTitle,
    String? candidateId,
    String? company,
    String? location,
    String? expectedSalary,
    String? coverLetter,
    String? resumeId,
  }) {
    final now = DateTime.now();
    return JobApplication(
      id: 'app_${now.millisecondsSinceEpoch}$jobId',
      jobId: jobId,
      candidateId: candidateId,
      jobTitle: jobTitle,
      company: company,
      location: location,
      status: ApplicationStatus.applied,
      appliedAt: now,
      updatedAt: now,
      expectedSalary: expectedSalary,
      coverLetter: coverLetter,
      resumeId: resumeId,
    );
  }

  /// Update the application status
  JobApplication updateStatus(
    ApplicationStatus newStatus, {
    String? rejectionReason,
  }) {
    return JobApplication(
      id: id,
      jobId: jobId,
      candidateId: candidateId,
      jobTitle: jobTitle,
      company: company,
      location: location,
      status: newStatus,
      appliedAt: appliedAt,
      updatedAt: DateTime.now(),
      expectedSalary: expectedSalary,
      coverLetter: coverLetter,
      resumeId: resumeId,
      interviewDates: interviewDates,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      recruiterNotes: recruiterNotes,
      internalRating: internalRating,
      source: source,
    );
  }

  /// Add an interview date
  JobApplication addInterviewDate(DateTime interviewDate) {
    final dates = List<DateTime>.from(interviewDates ?? [])..add(interviewDate);
    dates.sort();
    return JobApplication(
      id: id,
      jobId: jobId,
      candidateId: candidateId,
      jobTitle: jobTitle,
      company: company,
      location: location,
      status: status,
      appliedAt: appliedAt,
      updatedAt: DateTime.now(),
      expectedSalary: expectedSalary,
      coverLetter: coverLetter,
      resumeId: resumeId,
      interviewDates: dates,
      rejectionReason: rejectionReason,
      recruiterNotes: recruiterNotes,
      internalRating: internalRating,
      source: source,
    );
  }

  /// Get days since application
  int get daysSinceApplied {
    return DateTime.now().difference(appliedAt).inDays;
  }

  /// Get days since last update
  int get daysSinceUpdate {
    return DateTime.now().difference(updatedAt).inDays;
  }
}
