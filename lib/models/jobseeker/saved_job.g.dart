// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SavedJob _$SavedJobFromJson(Map<String, dynamic> json) => SavedJob(
  jobId: json['jobId'] as String,
  title: json['title'] as String,
  unitLabel: json['unit_label'] as String?,
  location: json['location'] as String?,
  savedAt: DateTime.parse(json['saved_at'] as String),
  notes: json['notes'] as String?,
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$SavedJobToJson(SavedJob instance) => <String, dynamic>{
  'jobId': instance.jobId,
  'title': instance.title,
  'unit_label': ?instance.unitLabel,
  'location': ?instance.location,
  'saved_at': instance.savedAt.toIso8601String(),
  'notes': ?instance.notes,
  'isActive': instance.isActive,
};
