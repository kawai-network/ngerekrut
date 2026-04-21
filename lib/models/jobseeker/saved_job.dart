/// Saved/bookmarked job model for jobseeker
library;

import 'package:json_annotation/json_annotation.dart';

part 'saved_job.g.dart';

@JsonSerializable()
class SavedJob {
  /// Job ID from the job posting
  final String jobId;

  /// Title of the job (cached for offline display)
  final String title;

  /// Legacy storage field mapped to department/unit in active UI flows.
  @JsonKey(name: 'unit_label')
  final String? unitLabel;

  /// Location (cached)
  final String? location;

  /// When this job was saved by the user
  @JsonKey(name: 'saved_at')
  final DateTime savedAt;

  /// Optional notes from the user
  final String? notes;

  /// Whether this job is still active/open
  final bool isActive;

  const SavedJob({
    required this.jobId,
    required this.title,
    this.unitLabel,
    this.location,
    required this.savedAt,
    this.notes,
    this.isActive = true,
  });

  factory SavedJob.fromJson(Map<String, dynamic> json) =>
      _$SavedJobFromJson(json);

  Map<String, dynamic> toJson() => _$SavedJobToJson(this);

  SavedJob copyWith({
    String? jobId,
    String? title,
    String? unitLabel,
    String? location,
    DateTime? savedAt,
    String? notes,
    bool? isActive,
  }) {
    return SavedJob(
      jobId: jobId ?? this.jobId,
      title: title ?? this.title,
      unitLabel: unitLabel ?? this.unitLabel,
      location: location ?? this.location,
      savedAt: savedAt ?? this.savedAt,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Create from a JobPosting (when user saves a job)
  factory SavedJob.fromJobPosting({
    required String jobId,
    required String title,
    String? unitLabel,
    String? location,
    String? notes,
  }) {
    return SavedJob(
      jobId: jobId,
      title: title,
      unitLabel: unitLabel,
      location: location,
      savedAt: DateTime.now(),
      notes: notes,
      isActive: true,
    );
  }
}
