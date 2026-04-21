import 'dart:convert';

import '../models/candidate_scorecard_record.dart';
import '../models/hiring_models.dart';
import '../objectbox.g.dart';
import '../objectbox_store_provider.dart';

class StoredInterviewScorecard {
  final String candidateId;
  final String candidateName;
  final InterviewScorecard scorecard;
  final String? usedMode;
  final int createdAt;

  const StoredInterviewScorecard({
    required this.candidateId,
    required this.candidateName,
    required this.scorecard,
    this.usedMode,
    required this.createdAt,
  });
}

class ScorecardArtifactRepository {
  Future<void> save({
    required String jobId,
    required String candidateId,
    required String candidateName,
    required InterviewScorecard scorecard,
    String? usedMode,
  }) async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<CandidateScorecardRecord>();
    box.put(
      CandidateScorecardRecord(
        jobId: jobId,
        candidateId: candidateId,
        candidateName: candidateName,
        interviewType: scorecard.interviewType.name,
        scorecardJson: jsonEncode(scorecard.toJson()),
        usedMode: usedMode,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<List<StoredInterviewScorecard>> listForJob(String jobId) async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<CandidateScorecardRecord>();
    final records = box
        .query(CandidateScorecardRecord_.jobId.equals(jobId))
        .order(CandidateScorecardRecord_.createdAt, flags: Order.descending)
        .build()
        .find();

    return records.map(_toStoredScorecard).toList();
  }

  Future<List<StoredInterviewScorecard>> listForCandidate({
    required String jobId,
    required String candidateId,
  }) async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<CandidateScorecardRecord>();
    final records = box
        .query(
          CandidateScorecardRecord_.jobId
              .equals(jobId)
              .and(CandidateScorecardRecord_.candidateId.equals(candidateId)),
        )
        .order(CandidateScorecardRecord_.createdAt, flags: Order.descending)
        .build()
        .find();

    return records.map(_toStoredScorecard).toList();
  }

  Future<List<StoredInterviewScorecard>> listAll() async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<CandidateScorecardRecord>();
    final records = box
        .query()
        .order(CandidateScorecardRecord_.createdAt, flags: Order.descending)
        .build()
        .find();

    return records.map(_toStoredScorecard).toList();
  }

  StoredInterviewScorecard _toStoredScorecard(CandidateScorecardRecord record) {
    final json = jsonDecode(record.scorecardJson) as Map<String, dynamic>;
    return StoredInterviewScorecard(
      candidateId: record.candidateId,
      candidateName: record.candidateName,
      scorecard: InterviewScorecard.fromJson(json),
      usedMode: record.usedMode,
      createdAt: record.createdAt,
    );
  }
}
