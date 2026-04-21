/// Job Posting repository using libsql_dart
/// Uses RecruiterJob model for compatibility with existing code
library;

import 'dart:convert';

import '../models/recruiter_job.dart';
import '../services/hybrid_database_service.dart';
import '../services/shared_identity_service.dart';

class JobPostingRepository {
  final HybridDatabaseService _db;
  final String _recruiterUserId;

  JobPostingRepository({HybridDatabaseService? db, String? recruiterUserId})
    : _db = db ?? hybridDatabase,
      _recruiterUserId = recruiterUserId ?? SharedIdentityService.currentUid;

  static const String statusDraft = 'draft';
  static const String statusPublished = 'published';
  static const String statusClosed = 'closed';

  static String normalizeStatus(String? status) {
    switch ((status ?? '').trim().toLowerCase()) {
      case 'published':
      case 'active':
      case 'aktif':
      case 'open':
        return statusPublished;
      case 'closed':
      case 'ditutup':
        return statusClosed;
      case 'draft':
      default:
        return statusDraft;
    }
  }

  static bool isPublishedStatus(String? status) =>
      normalizeStatus(status) == statusPublished;

  static bool isClosedStatus(String? status) =>
      normalizeStatus(status) == statusClosed;

  /// Create a new job posting
  Future<void> create(RecruiterJob posting) async {
    await _db.insertJobPosting({
      'id': posting.id,
      'job_id': posting.id,
      'recruiter_user_id': _recruiterUserId,
      'title': posting.title,
      'department': posting.unitLabel,
      'location': posting.location,
      'description': posting.description,
      'requirements_json': jsonEncode(posting.requirements),
      'status': normalizeStatus(posting.status),
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Get job posting by job ID
  Future<RecruiterJob?> getByJobId(String jobId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT * FROM job_postings
      WHERE job_id = ? AND recruiter_user_id = ?
      ''',
      positional: [jobId, _recruiterUserId],
    );
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  /// Get job posting by ID
  Future<RecruiterJob?> getById(String id) async {
    final rows = await _db.rawQuery(
      '''
      SELECT * FROM job_postings
      WHERE id = ? AND recruiter_user_id = ?
      ''',
      positional: [id, _recruiterUserId],
    );
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  /// Get all job postings
  Future<List<RecruiterJob>> getAll({String? status}) async {
    final normalizedStatus = status == null ? null : normalizeStatus(status);
    final rows = normalizedStatus == null
        ? await _db.rawQuery(
            '''
            SELECT * FROM job_postings
            WHERE recruiter_user_id = ?
            ORDER BY created_at DESC
            ''',
            positional: [_recruiterUserId],
          )
        : await _db.rawQuery(
            '''
            SELECT * FROM job_postings
            WHERE recruiter_user_id = ? AND status = ?
            ORDER BY created_at DESC
            ''',
            positional: [_recruiterUserId, normalizedStatus],
          );
    return rows.map(_fromMap).toList();
  }

  /// Get active/published job postings (for jobseekers)
  Future<List<RecruiterJob>> getActive() async {
    return await getAll(status: 'published');
  }

  /// Get draft job postings (for recruiters)
  Future<List<RecruiterJob>> getDrafts() async {
    return await getAll(status: statusDraft);
  }

  /// Get closed job postings
  Future<List<RecruiterJob>> getClosed() async {
    return await getAll(status: statusClosed);
  }

  /// Update job posting status
  Future<void> updateStatus(String jobId, String status) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.rawQuery(
      '''
      UPDATE job_postings
      SET status = ?, updated_at = ?
      WHERE job_id = ? AND recruiter_user_id = ?
      ''',
      positional: [normalizeStatus(status), now, jobId, _recruiterUserId],
    );
  }

  /// Publish a job posting
  Future<void> publish(String jobId) async {
    await updateStatus(jobId, statusPublished);
  }

  /// Close a job posting
  Future<void> close(String jobId) async {
    await updateStatus(jobId, statusClosed);
  }

  /// Update job posting content
  Future<void> update(RecruiterJob posting) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.rawQuery(
      '''
      UPDATE job_postings
      SET title = ?, department = ?, location = ?, description = ?,
          requirements_json = ?, status = ?, updated_at = ?
      WHERE job_id = ?
    ''',
      positional: [
        posting.title,
        posting.unitLabel,
        posting.location,
        posting.description,
        jsonEncode(posting.requirements),
        normalizeStatus(posting.status),
        now,
        posting.id,
      ],
    );
  }

  /// Delete a job posting
  Future<void> delete(String jobId) async {
    await _db.rawQuery(
      'DELETE FROM job_postings WHERE job_id = ? AND recruiter_user_id = ?',
      positional: [jobId, _recruiterUserId],
    );
  }

  /// Get job postings by unit label (stored as `department` in the table).
  Future<List<RecruiterJob>> getByUnitLabel(String unitLabel) async {
    final rows = await _db.rawQuery(
      '''
      SELECT * FROM job_postings
      WHERE recruiter_user_id = ? AND department = ?
      ORDER BY created_at DESC
      ''',
      positional: [_recruiterUserId, unitLabel],
    );
    return rows.map(_fromMap).toList();
  }

  /// Get job postings by location
  Future<List<RecruiterJob>> getByLocation(String location) async {
    final rows = await _db.rawQuery(
      '''
      SELECT * FROM job_postings
      WHERE recruiter_user_id = ? AND location = ?
      ORDER BY created_at DESC
      ''',
      positional: [_recruiterUserId, location],
    );
    return rows.map(_fromMap).toList();
  }

  /// Search job postings by title or description
  Future<List<RecruiterJob>> search(String query) async {
    final rows = await _db.rawQuery(
      '''
      SELECT * FROM job_postings
      WHERE status = 'published'
        AND (title LIKE ? OR description LIKE ?)
      ORDER BY created_at DESC
    ''',
      positional: ['%$query%', '%$query%'],
    );
    return rows.map(_fromMap).toList();
  }

  Future<void> clearOwnedSharedData() async {
    await _db.rawQuery(
      'DELETE FROM job_postings WHERE recruiter_user_id = ?',
      positional: [_recruiterUserId],
    );
  }

  // ==================== Helpers ====================

  RecruiterJob _fromMap(Map<String, dynamic> map) {
    // Parse requirements from JSON string if stored as string
    List<String> parseRequirements(dynamic req) {
      if (req == null) return [];
      if (req is List) return req.map((e) => e.toString()).toList();
      if (req is String) {
        try {
          // Remove brackets and split by comma
          final decoded = jsonDecode(req);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {
          final clean = req
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('"', '');
          if (clean.isEmpty) return [];
          return clean
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }
      return [];
    }

    return RecruiterJob(
      id: map['id'] as String,
      title: map['title'] as String,
      unitLabel: map['department'] as String?,
      location: map['location'] as String?,
      description: map['description'] as String?,
      requirements: parseRequirements(map['requirements_json']),
      status: normalizeStatus(map['status'] as String?),
    );
  }
}
