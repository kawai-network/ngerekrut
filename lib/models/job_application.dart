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

  /// Hiring unit/department label shown to recruiter and jobseeker.
  @JsonKey(name: 'unit_label')
  final String? unitLabel;

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

  /// Google Calendar event ID (if synced)
  @JsonKey(name: 'calendar_event_id')
  final String? calendarEventId;

  /// Jobseeker-side Google Calendar event ID (if synced).
  @JsonKey(name: 'candidate_calendar_event_id')
  final String? candidateCalendarEventId;

  /// Shared meeting URL for this interview, usually a Google Meet link.
  @JsonKey(name: 'meeting_url')
  final String? meetingUrl;

  /// Interview duration in minutes.
  @JsonKey(name: 'interview_duration_minutes')
  final int? interviewDurationMinutes;

  /// Shared interview notes shown to both recruiter and jobseeker.
  @JsonKey(name: 'interview_notes')
  final String? interviewNotes;

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
    this.unitLabel,
    this.location,
    required this.status,
    required this.appliedAt,
    required this.updatedAt,
    this.expectedSalary,
    this.coverLetter,
    this.resumeId,
    this.interviewDates,
    this.calendarEventId,
    this.candidateCalendarEventId,
    this.meetingUrl,
    this.interviewDurationMinutes,
    this.interviewNotes,
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
    String? unitLabel,
    String? location,
    ApplicationStatus? status,
    DateTime? appliedAt,
    DateTime? updatedAt,
    String? expectedSalary,
    String? coverLetter,
    String? resumeId,
    List<DateTime>? interviewDates,
    String? calendarEventId,
    String? candidateCalendarEventId,
    String? meetingUrl,
    int? interviewDurationMinutes,
    String? interviewNotes,
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
      unitLabel: unitLabel ?? this.unitLabel,
      location: location ?? this.location,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expectedSalary: expectedSalary ?? this.expectedSalary,
      coverLetter: coverLetter ?? this.coverLetter,
      resumeId: resumeId ?? this.resumeId,
      interviewDates: interviewDates ?? this.interviewDates,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      candidateCalendarEventId:
          candidateCalendarEventId ?? this.candidateCalendarEventId,
      meetingUrl: meetingUrl ?? this.meetingUrl,
      interviewDurationMinutes:
          interviewDurationMinutes ?? this.interviewDurationMinutes,
      interviewNotes: interviewNotes ?? this.interviewNotes,
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
    String? unitLabel,
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
      unitLabel: unitLabel,
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
      unitLabel: unitLabel,
      location: location,
      status: newStatus,
      appliedAt: appliedAt,
      updatedAt: DateTime.now(),
      expectedSalary: expectedSalary,
      coverLetter: coverLetter,
      resumeId: resumeId,
      interviewDates: interviewDates,
      calendarEventId: calendarEventId,
      candidateCalendarEventId: candidateCalendarEventId,
      meetingUrl: meetingUrl,
      interviewDurationMinutes: interviewDurationMinutes,
      interviewNotes: interviewNotes,
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
      unitLabel: unitLabel,
      location: location,
      status: status,
      appliedAt: appliedAt,
      updatedAt: DateTime.now(),
      expectedSalary: expectedSalary,
      coverLetter: coverLetter,
      resumeId: resumeId,
      interviewDates: dates,
      calendarEventId: calendarEventId,
      candidateCalendarEventId: candidateCalendarEventId,
      meetingUrl: meetingUrl,
      interviewDurationMinutes: interviewDurationMinutes,
      interviewNotes: interviewNotes,
      rejectionReason: rejectionReason,
      recruiterNotes: recruiterNotes,
      internalRating: internalRating,
      source: source,
    );
  }

  /// Update calendar event ID (when synced to Google Calendar)
  JobApplication withCalendarEventId(String? eventId) {
    return JobApplication(
      id: id,
      jobId: jobId,
      candidateId: candidateId,
      jobTitle: jobTitle,
      unitLabel: unitLabel,
      location: location,
      status: status,
      appliedAt: appliedAt,
      updatedAt: updatedAt,
      expectedSalary: expectedSalary,
      coverLetter: coverLetter,
      resumeId: resumeId,
      interviewDates: interviewDates,
      calendarEventId: eventId,
      candidateCalendarEventId: candidateCalendarEventId,
      meetingUrl: meetingUrl,
      interviewDurationMinutes: interviewDurationMinutes,
      interviewNotes: interviewNotes,
      rejectionReason: rejectionReason,
      recruiterNotes: recruiterNotes,
      internalRating: internalRating,
      source: source,
    );
  }

  /// Check if interview is synced to calendar
  bool get isSyncedToCalendar =>
      calendarEventId != null && calendarEventId!.isNotEmpty;

  bool get isSyncedToCandidateCalendar =>
      candidateCalendarEventId != null && candidateCalendarEventId!.isNotEmpty;

  /// Get days since application
  int get daysSinceApplied {
    return DateTime.now().difference(appliedAt).inDays;
  }

  /// Get days since last update
  int get daysSinceUpdate {
    return DateTime.now().difference(updatedAt).inDays;
  }
}
