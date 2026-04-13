import 'package:objectbox/objectbox.dart';

@Entity()
class JobPostRecord {
  JobPostRecord({
    this.id = 0,
    required this.jobId,
    required this.title,
    this.department,
    this.location,
    this.description,
    required this.requirementsJson,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  int id;
  String jobId;
  String title;
  String? department;
  String? location;
  String? description;
  String requirementsJson;
  String status;
  int createdAt;
  int updatedAt;
}
