/// Saved Job repository using libsql_dart
/// Source of truth for shared saved-job data (sync across devices)
library;

import '../models/saved_job_record.dart';
import '../services/hybrid_database_service.dart';
import '../services/shared_identity_service.dart';

class SavedJob {
  final String id;
  final String userId;
  final String jobId;
  final String title;
  final String? unitLabel;
  final String? location;
  final DateTime savedAt;
  final String? notes;
  final bool isActive;
  final String? jobStatus;

  const SavedJob({
    required this.id,
    required this.userId,
    required this.jobId,
    required this.title,
    this.unitLabel,
    this.location,
    required this.savedAt,
    this.notes,
    this.isActive = true,
    this.jobStatus,
  });

  factory SavedJob.fromRecord(SavedJobRecord record) {
    return SavedJob(
      id: record.id.toString(),
      userId: SharedIdentityService.jobseekerUserId,
      jobId: record.jobId,
      title: record.title,
      unitLabel: record.unitLabel,
      location: record.location,
      savedAt: DateTime.fromMillisecondsSinceEpoch(record.savedAt),
      notes: record.notes,
      isActive: record.isActive,
      jobStatus: null,
    );
  }

  SavedJobRecord toRecord() {
    return SavedJobRecord(
      id: int.tryParse(id) ?? 0,
      jobId: jobId,
      title: title,
      unitLabel: unitLabel,
      location: location,
      savedAt: savedAt.millisecondsSinceEpoch,
      notes: notes,
      isActive: isActive,
    );
  }
}

class SavedJobRepository {
  final HybridDatabaseService _db;
  final String _userId;

  SavedJobRepository({HybridDatabaseService? db, String? userId})
    : _db = db ?? hybridDatabase,
      _userId = userId ?? SharedIdentityService.jobseekerUserId;

  /// Save a job (bookmark)
  Future<void> save(SavedJob job) async {
    await _db.insertSavedJob({
      'id': job.id,
      'user_id': job.userId,
      'job_id': job.jobId,
      'title': job.title,
      'unit_label': job.unitLabel,
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
    String? unitLabel,
    String? location,
    String? notes,
  }) async {
    final id = 'saved_${DateTime.now().millisecondsSinceEpoch}_$jobId';
    await save(
      SavedJob(
        id: id,
        userId: _userId,
        jobId: jobId,
        title: title,
        unitLabel: unitLabel,
        location: location,
        savedAt: DateTime.now(),
        notes: notes,
      ),
    );
  }

  /// Get all saved jobs
  Future<List<SavedJob>> getAll({bool onlyActive = true}) async {
    final rows = await _db.rawQuery(
      '''
      SELECT
        s.*,
        p.status AS job_status
      FROM saved_jobs s
      LEFT JOIN job_postings p ON p.job_id = s.job_id
      WHERE s.user_id = ?
      ${onlyActive ? 'AND s.is_active = 1' : ''}
      ORDER BY s.saved_at DESC
      ''',
      positional: [_userId],
    );
    return rows.map(_fromMap).toList();
  }

  /// Get saved job by job ID
  Future<SavedJob?> getByJobId(String jobId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT
        s.*,
        p.status AS job_status
      FROM saved_jobs s
      LEFT JOIN job_postings p ON p.job_id = s.job_id
      WHERE s.user_id = ? AND s.job_id = ? AND s.is_active = 1
      ''',
      positional: [_userId, jobId],
    );
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
    await _db.removeSavedJob(_userId, jobId);
  }

  /// Toggle save status
  Future<bool> toggle(
    String jobId, {
    required String title,
    String? unitLabel,
    String? location,
  }) async {
    final existing = await getByJobId(jobId);
    if (existing != null) {
      await remove(jobId);
      return false;
    } else {
      await saveJob(
        jobId: jobId,
        title: title,
        unitLabel: unitLabel,
        location: location,
      );
      return true;
    }
  }

  /// Update notes for a saved job
  Future<void> updateNotes(String jobId, String notes) async {
    final existing = await getByJobId(jobId);
    if (existing == null) return;

    await _db.rawQuery(
      '''
      UPDATE saved_jobs
      SET notes = ?
      WHERE user_id = ? AND job_id = ?
    ''',
      positional: [notes, _userId, jobId],
    );
  }

  /// Get saved jobs count
  Future<int> count() async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM saved_jobs WHERE user_id = ? AND is_active = 1',
      positional: [_userId],
    );
    return rows.first['count'] as int? ?? 0;
  }

  // ==================== Helpers ====================

  SavedJob _fromMap(Map<String, dynamic> map) {
    return SavedJob(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? _userId,
      jobId: map['job_id'] as String,
      title: map['title'] as String,
      unitLabel: map['unit_label'] as String?,
      location: map['location'] as String?,
      savedAt: DateTime.fromMillisecondsSinceEpoch(map['saved_at'] as int),
      notes: map['notes'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      jobStatus: map['job_status'] as String?,
    );
  }
}
