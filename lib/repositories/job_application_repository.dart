/// Job Application repository using libsql_dart
/// Source of truth for shared job application data
library;

import 'dart:convert';

import '../models/application_status.dart';
import '../models/job_application.dart';
import '../services/hybrid_database_service.dart';
import '../services/shared_identity_service.dart';

class JobApplicationRepository {
  final HybridDatabaseService _db;
  final String _candidateId;
  final String _recruiterUserId;

  String get candidateId => _candidateId;

  JobApplicationRepository({
    HybridDatabaseService? db,
    String? candidateId,
    String? recruiterUserId,
  }) : _db = db ?? hybridDatabase,
       _candidateId = candidateId ?? SharedIdentityService.currentUid,
       _recruiterUserId = recruiterUserId ?? SharedIdentityService.currentUid;

  /// Create a new job application
  Future<void> create(JobApplication application) async {
    final scopedApplication = application.candidateId == null
        ? application.copyWith(candidateId: _candidateId)
        : application;
    await _db.insertJobApplication(_toMap(scopedApplication));
  }

  /// Get all applications for a specific job (recruiter view)
  Future<List<JobApplication>> getByJobId(String jobId) async {
    final rows = await _db.getJobApplicationsByJob(jobId);
    return rows.map(_fromMap).toList();
  }

  /// Get all applications across jobs (recruiter inbox view)
  Future<List<JobApplication>> getAllForOwnedJobs() async {
    final rows = await _db.rawQuery(
      '''
      SELECT a.*
      FROM job_applications a
      INNER JOIN job_postings p ON p.job_id = a.job_id
      WHERE p.recruiter_user_id = ?
      ORDER BY a.applied_at DESC
      ''',
      positional: [_recruiterUserId],
    );
    return rows.map(_fromMap).toList();
  }

  /// Get all applications for a candidate (jobseeker view)
  Future<List<JobApplication>> getByCandidateId(String candidateId) async {
    final rows = await _db.getJobApplicationsByCandidate(candidateId);
    return rows.map(_fromMap).toList();
  }

  /// Get a single application by ID
  Future<JobApplication?> getById(String id) async {
    final rows = await _db.rawQuery(
      'SELECT * FROM job_applications WHERE id = ?',
      positional: [id],
    );
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  /// Get a single application for a candidate and job pair
  Future<JobApplication?> getByCandidateAndJob(
    String candidateId,
    String jobId,
  ) async {
    final rows = await _db.rawQuery(
      '''
      SELECT * FROM job_applications
      WHERE candidate_id = ? AND job_id = ?
      ORDER BY applied_at DESC
      LIMIT 1
      ''',
      positional: [candidateId, jobId],
    );
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  /// Update application status
  Future<void> updateStatus(
    String id,
    ApplicationStatus status, {
    String? rejectionReason,
  }) async {
    await _db.updateJobApplicationStatus(
      id,
      status.name,
      rejectionReason: rejectionReason,
    );
  }

  /// Add an interview date to application
  Future<void> addInterviewDate(String id, DateTime interviewDate) async {
    final app = await getById(id);
    if (app == null) return;

    final dates = List<DateTime>.from(app.interviewDates ?? [])
      ..add(interviewDate);
    dates.sort();

    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.rawQuery(
      '''
      UPDATE job_applications
      SET interview_dates = ?, updated_at = ?
      WHERE id = ?
    ''',
      positional: [_encodeDates(dates), now, id],
    );
  }

  /// Persist calendar event linkage for an interview application.
  Future<void> updateCalendarEventId(String id, String? eventId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.rawQuery(
      '''
      UPDATE job_applications
      SET calendar_event_id = ?, updated_at = ?
      WHERE id = ?
      ''',
      positional: [eventId, now, id],
    );
  }

  /// Update recruiter notes
  Future<void> updateRecruiterNotes(String id, String notes) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.rawQuery(
      '''
      UPDATE job_applications
      SET recruiter_notes = ?, updated_at = ?
      WHERE id = ?
    ''',
      positional: [notes, now, id],
    );
  }

  /// Set internal rating (1-5)
  Future<void> setInternalRating(String id, int rating) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.rawQuery(
      '''
      UPDATE job_applications
      SET internal_rating = ?, updated_at = ?
      WHERE id = ?
    ''',
      positional: [rating, now, id],
    );
  }

  /// Archive application from recruiter cleanup flow and append a short audit note.
  Future<void> archiveFromCleanup(String id, {String? note}) async {
    final app = await getById(id);
    if (app == null) return;

    final now = DateTime.now();
    final timestamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final auditLine =
        note ??
        '[Cleanup] Auto-archived on $timestamp because the job is closed.';
    final existingNotes = (app.recruiterNotes ?? '').trim();
    final mergedNotes = existingNotes.isEmpty
        ? auditLine
        : '$existingNotes\n$auditLine';

    final epochNow = now.millisecondsSinceEpoch;
    await _db.rawQuery(
      '''
      UPDATE job_applications
      SET status = ?, recruiter_notes = ?, updated_at = ?
      WHERE id = ?
      ''',
      positional: [ApplicationStatus.archived.name, mergedNotes, epochNow, id],
    );
  }

  /// Get applications by status
  Future<List<JobApplication>> getByStatus(ApplicationStatus status) async {
    final rows = await _db.rawQuery(
      'SELECT * FROM job_applications WHERE status = ? ORDER BY applied_at DESC',
      positional: [status.name],
    );
    return rows.map(_fromMap).toList();
  }

  /// Get recent applications (last N days)
  Future<List<JobApplication>> getRecent({
    int days = 30,
    String? candidateId,
  }) async {
    final cutoff = DateTime.now()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;
    final rows = candidateId != null
        ? await _db.rawQuery(
            'SELECT * FROM job_applications WHERE candidate_id = ? AND applied_at >= ? ORDER BY applied_at DESC',
            positional: [candidateId, cutoff],
          )
        : await _db.rawQuery(
            'SELECT * FROM job_applications WHERE applied_at >= ? ORDER BY applied_at DESC',
            positional: [cutoff],
          );
    return rows.map(_fromMap).toList();
  }

  /// Get application statistics by status
  Future<Map<ApplicationStatus, int>> getStatsByJob(String jobId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT status, COUNT(*) as count
      FROM job_applications
      WHERE job_id = ?
      GROUP BY status
    ''',
      positional: [jobId],
    );

    final stats = <ApplicationStatus, int>{};
    for (final row in rows) {
      final statusStr = row['status'] as String;
      final count = row['count'] as int;
      final status = ApplicationStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => ApplicationStatus.applied,
      );
      stats[status] = count;
    }
    return stats;
  }

  // ==================== Helpers ====================

  Map<String, dynamic> _toMap(JobApplication app) {
    return {
      'id': app.id,
      'job_id': app.jobId,
      'candidate_id': app.candidateId ?? _candidateId,
      'job_title': app.jobTitle,
      'unit_label': app.unitLabel,
      'location': app.location,
      'status': app.status.name,
      'applied_at': app.appliedAt.millisecondsSinceEpoch,
      'updated_at': app.updatedAt.millisecondsSinceEpoch,
      'expected_salary': app.expectedSalary,
      'cover_letter': app.coverLetter,
      'resume_id': app.resumeId,
      'interview_dates': _encodeDates(app.interviewDates),
      'calendar_event_id': app.calendarEventId,
      'rejection_reason': app.rejectionReason,
      'recruiter_notes': app.recruiterNotes,
      'internal_rating': app.internalRating,
      'source': app.source,
    };
  }

  JobApplication _fromMap(Map<String, dynamic> map) {
    return JobApplication(
      id: map['id'] as String,
      jobId: map['job_id'] as String,
      candidateId: map['candidate_id'] as String?,
      jobTitle: map['job_title'] as String,
      unitLabel: map['unit_label'] as String?,
      location: map['location'] as String?,
      status: _parseStatus(map['status'] as String?),
      appliedAt: DateTime.fromMillisecondsSinceEpoch(map['applied_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      expectedSalary: map['expected_salary'] as String?,
      coverLetter: map['cover_letter'] as String?,
      resumeId: map['resume_id'] as String?,
      interviewDates: _decodeDates(map['interview_dates'] as String?),
      calendarEventId: map['calendar_event_id'] as String?,
      rejectionReason: map['rejection_reason'] as String?,
      recruiterNotes: map['recruiter_notes'] as String?,
      internalRating: map['internal_rating'] as int?,
      source: map['source'] as String?,
    );
  }

  ApplicationStatus _parseStatus(String? statusStr) {
    if (statusStr == null) return ApplicationStatus.applied;
    return ApplicationStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => ApplicationStatus.applied,
    );
  }

  String _encodeDates(List<DateTime>? dates) {
    if (dates == null || dates.isEmpty) return '[]';
    return jsonEncode(dates.map((d) => d.millisecondsSinceEpoch).toList());
  }

  List<DateTime>? _decodeDates(String? encoded) {
    if (encoded == null || encoded.isEmpty || encoded == '[]') return null;
    try {
      final decoded = jsonDecode(encoded);
      final timestamps = decoded is List
          ? decoded
                .map(
                  (item) =>
                      item is num ? item.toInt() : int.parse(item.toString()),
                )
                .toList()
          : <int>[];
      return timestamps.map(DateTime.fromMillisecondsSinceEpoch).toList();
    } catch (_) {
      return null;
    }
  }
}
