import 'package:objectbox/objectbox.dart';

@Entity()
class CandidateScorecardRecord {
  CandidateScorecardRecord({
    this.id = 0,
    required this.jobId,
    required this.candidateId,
    required this.candidateName,
    required this.interviewType,
    required this.scorecardJson,
    this.usedMode,
    required this.createdAt,
  });

  int id;
  String jobId;
  String candidateId;
  String candidateName;
  String interviewType;
  String scorecardJson;
  String? usedMode;
  int createdAt;
}
