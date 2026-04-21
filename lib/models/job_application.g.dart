// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_application.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JobApplication _$JobApplicationFromJson(Map<String, dynamic> json) =>
    JobApplication(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      candidateId: json['candidate_id'] as String?,
      jobTitle: json['job_title'] as String,
      unitLabel: json['unit_label'] as String?,
      location: json['location'] as String?,
      status: $enumDecode(_$ApplicationStatusEnumMap, json['status']),
      appliedAt: DateTime.parse(json['applied_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      expectedSalary: json['expected_salary'] as String?,
      coverLetter: json['cover_letter'] as String?,
      resumeId: json['resume_id'] as String?,
      interviewDates: (json['interview_dates'] as List<dynamic>?)
          ?.map((e) => DateTime.parse(e as String))
          .toList(),
      calendarEventId: json['calendar_event_id'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      recruiterNotes: json['recruiter_notes'] as String?,
      internalRating: (json['internal_rating'] as num?)?.toInt(),
      source: json['source'] as String?,
    );

Map<String, dynamic> _$JobApplicationToJson(JobApplication instance) =>
    <String, dynamic>{
      'id': instance.id,
      'job_id': instance.jobId,
      'candidate_id': ?instance.candidateId,
      'job_title': instance.jobTitle,
      'unit_label': ?instance.unitLabel,
      'location': ?instance.location,
      'status': _$ApplicationStatusEnumMap[instance.status]!,
      'applied_at': instance.appliedAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'expected_salary': ?instance.expectedSalary,
      'cover_letter': ?instance.coverLetter,
      'resume_id': ?instance.resumeId,
      'interview_dates': ?instance.interviewDates
          ?.map((e) => e.toIso8601String())
          .toList(),
      'calendar_event_id': ?instance.calendarEventId,
      'rejection_reason': ?instance.rejectionReason,
      'recruiter_notes': ?instance.recruiterNotes,
      'internal_rating': ?instance.internalRating,
      'source': ?instance.source,
    };

const _$ApplicationStatusEnumMap = {
  ApplicationStatus.applied: 'applied',
  ApplicationStatus.screening: 'screening',
  ApplicationStatus.interview: 'interview',
  ApplicationStatus.underReview: 'underReview',
  ApplicationStatus.offered: 'offered',
  ApplicationStatus.rejected: 'rejected',
  ApplicationStatus.withdrawn: 'withdrawn',
  ApplicationStatus.archived: 'archived',
};
