class RecruiterJob {
  final String id;
  final String title;
  final String? department;
  final String? location;
  final String? description;
  final List<String> requirements;
  final String status;

  const RecruiterJob({
    required this.id,
    required this.title,
    this.department,
    this.location,
    this.description,
    this.requirements = const [],
    required this.status,
  });

  factory RecruiterJob.fromJson(Map<String, dynamic> json) {
    return RecruiterJob(
      id: json['id'] as String,
      title: json['title'] as String,
      department: json['department'] as String?,
      location: json['location'] as String?,
      description: json['description'] as String?,
      requirements: (json['requirements'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      status: json['status'] as String? ?? 'draft',
    );
  }
}
