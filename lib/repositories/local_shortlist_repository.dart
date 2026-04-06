import 'dart:convert';

import '../models/recruiter_shortlist.dart';
import '../models/recruiter_shortlist_record.dart';
import '../objectbox.g.dart';
import '../objectbox_store_provider.dart';

class LocalShortlistRepository {
  Future<void> save(RecruiterShortlistResult result) async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<RecruiterShortlistRecord>();
    final existing = box
        .query(RecruiterShortlistRecord_.jobId.equals(result.jobId))
        .order(RecruiterShortlistRecord_.createdAt, flags: Order.descending)
        .build()
        .findFirst();

    final record = existing ??
        RecruiterShortlistRecord(
          screeningId: result.screeningId,
          jobId: result.jobId,
          status: result.status,
          summary: result.summary,
          usedMode: result.usedMode,
          rankedCandidatesJson: '[]',
          topCandidatesJson: '[]',
          createdAt: result.createdAt ?? DateTime.now().millisecondsSinceEpoch,
        );

    record.screeningId = result.screeningId;
    record.jobId = result.jobId;
    record.status = result.status;
    record.summary = result.summary;
    record.usedMode = result.usedMode;
    record.rankedCandidatesJson = jsonEncode(
      result.rankedCandidates.map(_entryToJson).toList(),
    );
    record.topCandidatesJson = jsonEncode(
      result.topCandidates.map(_entryToJson).toList(),
    );
    record.createdAt = result.createdAt ?? DateTime.now().millisecondsSinceEpoch;

    box.put(record);
  }

  Future<RecruiterShortlistResult?> getLatestForJob(String jobId) async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<RecruiterShortlistRecord>();
    final record = box
        .query(RecruiterShortlistRecord_.jobId.equals(jobId))
        .order(RecruiterShortlistRecord_.createdAt, flags: Order.descending)
        .build()
        .findFirst();

    if (record == null) {
      return null;
    }

    final ranked = (jsonDecode(record.rankedCandidatesJson) as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(RecruiterShortlistEntry.fromJson)
        .toList();
    final top = (jsonDecode(record.topCandidatesJson) as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(RecruiterShortlistEntry.fromJson)
        .toList();

    return RecruiterShortlistResult(
      screeningId: record.screeningId,
      jobId: record.jobId,
      status: record.status,
      summary: record.summary,
      createdAt: record.createdAt,
      usedMode: record.usedMode,
      rankedCandidates: ranked,
      topCandidates: top,
    );
  }

  Future<List<RecruiterShortlistResult>> listForJob(String jobId) async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<RecruiterShortlistRecord>();
    final records = box
        .query(RecruiterShortlistRecord_.jobId.equals(jobId))
        .order(RecruiterShortlistRecord_.createdAt, flags: Order.descending)
        .build()
        .find();

    return records.map(_recordToResult).toList();
  }

  RecruiterShortlistResult _recordToResult(RecruiterShortlistRecord record) {
    final ranked = (jsonDecode(record.rankedCandidatesJson) as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(RecruiterShortlistEntry.fromJson)
        .toList();
    final top = (jsonDecode(record.topCandidatesJson) as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(RecruiterShortlistEntry.fromJson)
        .toList();

    return RecruiterShortlistResult(
      screeningId: record.screeningId,
      jobId: record.jobId,
      status: record.status,
      summary: record.summary,
      createdAt: record.createdAt,
      usedMode: record.usedMode,
      rankedCandidates: ranked,
      topCandidates: top,
    );
  }

  Map<String, dynamic> _entryToJson(RecruiterShortlistEntry entry) {
    return {
      'candidate_id': entry.candidateId,
      'candidate_name': entry.candidateName,
      'rank': entry.rank,
      'total_score': entry.totalScore,
      'score_breakdown': {
        'skill_match': entry.scoreBreakdown.skillMatch,
        'relevant_experience': entry.scoreBreakdown.relevantExperience,
        'domain_fit': entry.scoreBreakdown.domainFit,
        'communication_clarity': entry.scoreBreakdown.communicationClarity,
        'growth_potential': entry.scoreBreakdown.growthPotential,
        'penalty': entry.scoreBreakdown.penalty,
      },
      'strengths': entry.strengths,
      'gaps': entry.gaps,
      'red_flags': entry.redFlags,
      'recommendation': entry.recommendation,
      'rationale': entry.rationale,
    };
  }
}
