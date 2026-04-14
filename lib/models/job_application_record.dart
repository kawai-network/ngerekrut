import 'package:objectbox/objectbox.dart';

@Entity()
class JobApplicationRecord {
  JobApplicationRecord({
    this.id = 0,
    required this.applicationId,
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
    this.interviewDatesJson,
    this.rejectionReason,
    this.recruiterNotes,
    this.internalRating,
    this.source,
  });

  int id;

  @Unique()
  String applicationId;

  String jobId;
  String? candidateId;
  String jobTitle;
  String? company;
  String? location;

  /// Stored as string (ApplicationStatus enum value)
  String status;

  int appliedAt;
  int updatedAt;
  String? expectedSalary;
  String? coverLetter;
  String? resumeId;

  /// JSON encoded List<DateTime> as milliseconds
  String? interviewDatesJson;

  String? rejectionReason;
  String? recruiterNotes;
  int? internalRating;
  String? source;
}
