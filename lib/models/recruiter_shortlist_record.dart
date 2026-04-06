import 'package:objectbox/objectbox.dart';

@Entity()
class RecruiterShortlistRecord {
  RecruiterShortlistRecord({
    this.id = 0,
    required this.screeningId,
    required this.jobId,
    required this.status,
    required this.summary,
    this.usedMode,
    required this.rankedCandidatesJson,
    required this.topCandidatesJson,
    required this.createdAt,
  });

  int id;
  String screeningId;
  String jobId;
  String status;
  String summary;
  String? usedMode;
  String rankedCandidatesJson;
  String topCandidatesJson;
  int createdAt;
}
