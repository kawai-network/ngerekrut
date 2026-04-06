import 'package:objectbox/objectbox.dart';

@Entity()
class InterviewGuideRecord {
  InterviewGuideRecord({
    this.id = 0,
    required this.jobId,
    required this.candidateId,
    required this.candidateName,
    required this.guideJson,
    this.usedMode,
    required this.createdAt,
  });

  int id;
  String jobId;
  String candidateId;
  String candidateName;
  String guideJson;
  String? usedMode;
  int createdAt;
}
