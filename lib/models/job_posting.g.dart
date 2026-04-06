// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_posting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JobPosting _$JobPostingFromJson(Map<String, dynamic> json) => JobPosting(
  title: json['title'] as String,
  location: json['location'] as String,
  description: json['description'] as String,
  requirements: (json['requirements'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  responsibilities: (json['responsibilities'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  salaryRange: json['salaryRange'] as String,
  employmentType: json['employment_type'] as String? ?? 'Full Time',
);

Map<String, dynamic> _$JobPostingToJson(JobPosting instance) =>
    <String, dynamic>{
      'title': instance.title,
      'location': instance.location,
      'description': instance.description,
      'requirements': instance.requirements,
      'responsibilities': instance.responsibilities,
      'salaryRange': instance.salaryRange,
      'employment_type': instance.employmentType,
    };
