/// Job Posting repository using libsql_dart
/// Uses RecruiterJob model for compatibility with existing code
library;

import '../models/recruiter_job.dart';
import '../services/hybrid_database_service.dart';

class JobPostingRepository {
  final HybridDatabaseService _db;

  JobPostingRepository({HybridDatabaseService? db}) : _db = db ?? hybridDatabase;

  /// Create a new job posting
  Future<void> create(RecruiterJob posting) async {
    await _db.insertJobPosting({
      'id': posting.id,
      'job_id': posting.id,
      'title': posting.title,
      'department': posting.department,
      'location': posting.location,
      'description': posting.description,
      'requirements_json': posting.requirements.toString(),
      'status': posting.status,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Get job posting by job ID
  Future<RecruiterJob?> getByJobId(String jobId) async {
    final rows = await _db.rawQuery('SELECT * FROM job_postings WHERE job_id = ?', positional: [jobId]);
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  /// Get job posting by ID
  Future<RecruiterJob?> getById(String id) async {
    final rows = await _db.rawQuery('SELECT * FROM job_postings WHERE id = ?', positional: [id]);
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  /// Get all job postings
  Future<List<RecruiterJob>> getAll({String? status}) async {
    final rows = await _db.getJobPostings(status: status);
    return rows.map(_fromMap).toList();
  }

  /// Get active/published job postings (for jobseekers)
  Future<List<RecruiterJob>> getActive() async {
    return await getAll(status: 'published');
  }

  /// Get draft job postings (for recruiters)
  Future<List<RecruiterJob>> getDrafts() async {
    return await getAll(status: 'draft');
  }

  /// Get closed job postings
  Future<List<RecruiterJob>> getClosed() async {
    return await getAll(status: 'closed');
  }

  /// Update job posting status
  Future<void> updateStatus(String jobId, String status) async {
    await _db.updateJobPostingStatus(jobId, status);
  }

  /// Publish a job posting
  Future<void> publish(String jobId) async {
    await updateStatus(jobId, 'published');
  }

  /// Close a job posting
  Future<void> close(String jobId) async {
    await updateStatus(jobId, 'closed');
  }

  /// Update job posting content
  Future<void> update(RecruiterJob posting) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.rawQuery('''
      UPDATE job_postings
      SET title = ?, department = ?, location = ?, description = ?,
          requirements_json = ?, status = ?, updated_at = ?
      WHERE job_id = ?
    ''', positional: [
      posting.title,
      posting.department,
      posting.location,
      posting.description,
      posting.requirements.toString(),
      posting.status,
      now,
      posting.id,
    ]);
  }

  /// Delete a job posting
  Future<void> delete(String jobId) async {
    await _db.rawQuery('DELETE FROM job_postings WHERE job_id = ?', positional: [jobId]);
  }

  /// Get job postings by department
  Future<List<RecruiterJob>> getByDepartment(String department) async {
    final rows = await _db.rawQuery(
        'SELECT * FROM job_postings WHERE department = ? ORDER BY created_at DESC',
        positional: [department]);
    return rows.map(_fromMap).toList();
  }

  /// Get job postings by location
  Future<List<RecruiterJob>> getByLocation(String location) async {
    final rows = await _db.rawQuery(
        'SELECT * FROM job_postings WHERE location = ? ORDER BY created_at DESC',
        positional: [location]);
    return rows.map(_fromMap).toList();
  }

  /// Search job postings by title or description
  Future<List<RecruiterJob>> search(String query) async {
    final rows = await _db.rawQuery('''
      SELECT * FROM job_postings
      WHERE status = 'published'
        AND (title LIKE ? OR description LIKE ?)
      ORDER BY created_at DESC
    ''', positional: ['%$query%', '%$query%']);
    return rows.map(_fromMap).toList();
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
          final clean = req.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
          if (clean.isEmpty) return [];
          return clean.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        } catch (_) {
          return [];
        }
      }
      return [];
    }

    return RecruiterJob(
      id: map['id'] as String,
      title: map['title'] as String,
      department: map['department'] as String?,
      location: map['location'] as String?,
      description: map['description'] as String?,
      requirements: parseRequirements(map['requirements_json']),
      status: map['status'] as String? ?? 'draft',
    );
  }
}
