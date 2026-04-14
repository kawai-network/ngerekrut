import 'dart:convert';

import '../models/hiring_models.dart';
import '../models/interview_guide_record.dart';
import '../objectbox.g.dart';
import '../objectbox_store_provider.dart';

class StoredInterviewGuide {
  final String candidateId;
  final String candidateName;
  final STARInterviewGuide guide;
  final String? usedMode;
  final int createdAt;

  const StoredInterviewGuide({
    required this.candidateId,
    required this.candidateName,
    required this.guide,
    this.usedMode,
    required this.createdAt,
  });
}

class LocalInterviewGuideRepository {
  Future<void> save({
    required String jobId,
    required String candidateId,
    required String candidateName,
    required STARInterviewGuide guide,
    String? usedMode,
  }) async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<InterviewGuideRecord>();
    box.put(
      InterviewGuideRecord(
        jobId: jobId,
        candidateId: candidateId,
        candidateName: candidateName,
        guideJson: jsonEncode(guide.toJson()),
        usedMode: usedMode,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<List<StoredInterviewGuide>> listForCandidate({
    required String jobId,
    required String candidateId,
  }) async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<InterviewGuideRecord>();
    final records = box
        .query(
          InterviewGuideRecord_.jobId
              .equals(jobId)
              .and(InterviewGuideRecord_.candidateId.equals(candidateId)),
        )
        .order(InterviewGuideRecord_.createdAt, flags: Order.descending)
        .build()
        .find();

    return records.map(_toStoredGuide).toList();
  }

  Future<List<StoredInterviewGuide>> listForJob(String jobId) async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<InterviewGuideRecord>();
    final records = box
        .query(InterviewGuideRecord_.jobId.equals(jobId))
        .order(InterviewGuideRecord_.createdAt, flags: Order.descending)
        .build()
        .find();

    return records.map(_toStoredGuide).toList();
  }

  Future<List<StoredInterviewGuide>> listAll() async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<InterviewGuideRecord>();
    final records = box
        .query()
        .order(InterviewGuideRecord_.createdAt, flags: Order.descending)
        .build()
        .find();

    return records.map(_toStoredGuide).toList();
  }

  StoredInterviewGuide _toStoredGuide(InterviewGuideRecord record) {
    final json = jsonDecode(record.guideJson) as Map<String, dynamic>;
    return StoredInterviewGuide(
      candidateId: record.candidateId,
      candidateName: record.candidateName,
      guide: STARInterviewGuide.fromJson(json),
      usedMode: record.usedMode,
      createdAt: record.createdAt,
    );
  }
}
