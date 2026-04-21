/// Saved Job repository using libsql_dart
/// Replaces local_saved_job_repository.dart for shared data (sync across devices)
library;

import '../models/saved_job_record.dart';
import '../services/hybrid_database_service.dart';

class SavedJob {
  final String id;
  final String jobId;
  final String title;
  final String? company;
  final String? location;
  final DateTime savedAt;
  final String? notes;
  final bool isActive;

  const SavedJob({
    required this.id,
    required this.jobId,
    required this.title,
    this.company,
    this.location,
    required this.savedAt,
    this.notes,
    this.isActive = true,
  });

  factory SavedJob.fromRecord(SavedJobRecord record) {
    return SavedJob(
      id: record.id.toString(),
      jobId: record.jobId,
      title: record.title,
      company: record.company,
      location: record.location,
      savedAt: DateTime.fromMillisecondsSinceEpoch(record.savedAt),
      notes: record.notes,
      isActive: record.isActive,
    );
  }

  SavedJobRecord toRecord() {
    return SavedJobRecord(
      id: int.tryParse(id) ?? 0,
      jobId: jobId,
      title: title,
      company: company,
      location: location,
      savedAt: savedAt.millisecondsSinceEpoch,
      notes: notes,
      isActive: isActive,
    );
  }
}

class SavedJobRepository {
  final HybridDatabaseService _db;

  SavedJobRepository({HybridDatabaseService? db}) : _db = db ?? hybridDatabase;

  /// Save a job (bookmark)
  Future<void> save(SavedJob job) async {
    await _db.insertSavedJob({
      'id': job.id,
      'job_id': job.jobId,
      'title': job.title,
      'company': job.company,
      'location': job.location,
      'saved_at': job.savedAt.millisecondsSinceEpoch,
      'notes': job.notes,
      'is_active': job.isActive ? 1 : 0,
    });
  }

  /// Save a job by job details
  Future<void> saveJob({
    required String jobId,
    required String title,
    String? company,
    String? location,
    String? notes,
  }) async {
    final id = 'saved_${DateTime.now().millisecondsSinceEpoch}_$jobId';
    await save(SavedJob(
      id: id,
      jobId: jobId,
      title: title,
      company: company,
      location: location,
      savedAt: DateTime.now(),
      notes: notes,
    ));
  }

  /// Get all saved jobs
  Future<List<SavedJob>> getAll({bool onlyActive = true}) async {
    final rows = await _db.getSavedJobs(onlyActive: onlyActive);
    return rows.map(_fromMap).toList();
  }

  /// Get saved job by job ID
  Future<SavedJob?> getByJobId(String jobId) async {
    final rows = await _db.rawQuery('SELECT * FROM saved_jobs WHERE job_id = ? AND is_active = 1',
        positional: [jobId]);
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  /// Check if a job is saved
  Future<bool> isSaved(String jobId) async {
    final saved = await getByJobId(jobId);
    return saved != null;
  }

  /// Unsave/remove a job
  Future<void> remove(String jobId) async {
    await _db.removeSavedJob(jobId);
  }

  /// Toggle save status
  Future<bool> toggle(String jobId, {required String title, String? company, String? location}) async {
    final existing = await getByJobId(jobId);
    if (existing != null) {
      await remove(jobId);
      return false;
    } else {
      await saveJob(jobId: jobId, title: title, company: company, location: location);
      return true;
    }
  }

  /// Update notes for a saved job
  Future<void> updateNotes(String jobId, String notes) async {
    final existing = await getByJobId(jobId);
    if (existing == null) return;

    await _db.rawQuery('''
      UPDATE saved_jobs
      SET notes = ?
      WHERE job_id = ?
    ''', positional: [notes, jobId]);
  }

  /// Get saved jobs count
  Future<int> count() async {
    final rows = await _db.rawQuery('SELECT COUNT(*) as count FROM saved_jobs WHERE is_active = 1');
    return rows.first['count'] as int? ?? 0;
  }

  // ==================== Helpers ====================

  SavedJob _fromMap(Map<String, dynamic> map) {
    return SavedJob(
      id: map['id'] as String,
      jobId: map['job_id'] as String,
      title: map['title'] as String,
      company: map['company'] as String?,
      location: map['location'] as String?,
      savedAt: DateTime.fromMillisecondsSinceEpoch(map['saved_at'] as int),
      notes: map['notes'] as String?,
      isActive: (map['is_active'] as int?) == 1,
    );
  }
}
