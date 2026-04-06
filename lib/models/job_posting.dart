/// Domain model untuk job posting yang di-generate AI.
library;

import 'package:json_annotation/json_annotation.dart';

part 'job_posting.g.dart';

/// Job posting hasil generate AI.
@JsonSerializable()
class JobPosting {
  final String title;
  final String location;
  final String description;
  final List<String> requirements;
  final List<String> responsibilities;
  final String salaryRange;
  @JsonKey(name: 'employment_type')
  final String employmentType;

  const JobPosting({
    required this.title,
    required this.location,
    required this.description,
    required this.requirements,
    required this.responsibilities,
    required this.salaryRange,
    @JsonKey(name: 'employment_type') this.employmentType = 'Full Time',
  });

  factory JobPosting.fromJson(Map<String, dynamic> json) =>
      _$JobPostingFromJson(json);

  Map<String, dynamic> toJson() => _$JobPostingToJson(this);

  JobPosting copyWith({
    String? title,
    String? location,
    String? description,
    List<String>? requirements,
    List<String>? responsibilities,
    String? salaryRange,
    String? employmentType,
  }) {
    return JobPosting(
      title: title ?? this.title,
      location: location ?? this.location,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      responsibilities: responsibilities ?? this.responsibilities,
      salaryRange: salaryRange ?? this.salaryRange,
      employmentType: employmentType ?? this.employmentType,
    );
  }

  /// Format job posting menjadi teks yang bisa ditampilkan.
  String toDisplayText() {
    final buffer = StringBuffer();
    buffer.writeln('📋 *$title*');
    buffer.writeln('📍 $location');
    buffer.writeln('💼 $employmentType');
    buffer.writeln('');
    buffer.writeln('📝 Deskripsi:');
    buffer.writeln(description);
    buffer.writeln('');
    buffer.writeln('✅ Kualifikasi:');
    for (var i = 0; i < requirements.length; i++) {
      buffer.writeln('${i + 1}. ${requirements[i]}');
    }
    buffer.writeln('');
    buffer.writeln('🎯 Tanggung Jawab:');
    for (var i = 0; i < responsibilities.length; i++) {
      buffer.writeln('${i + 1}. ${responsibilities[i]}');
    }
    buffer.writeln('');
    buffer.writeln('💰 Estimasi Gaji: $salaryRange');
    return buffer.toString();
  }

  /// Format job posting menjadi JSON string untuk API.
  String toJsonString() {
    return toJson().toString();
  }
}
