/// Hybrid database service supporting local (LibsqlClient.local) and remote (LibsqlClient.remote)
library;

import 'package:flutter/foundation.dart';
import 'package:libsql_dart/libsql_dart.dart';
import 'package:path_provider/path_provider.dart';
import '../app/runtime_config.dart';

enum DatabaseMode {
  /// Local SQLite file only (offline, no sync)
  localOnly,

  /// Remote LibSQL/Turso only (requires internet)
  remoteOnly,

  /// Embedded replica: local + auto-sync to remote
  replica,
}

class HybridDatabaseService {
  LibsqlClient? _client;
  DatabaseMode _mode = DatabaseMode.localOnly;
  bool _isConnected = false;

  /// Get current database mode
  DatabaseMode get mode => _mode;

  /// Check if connected
  bool get isConnected => _isConnected;

  /// Get the underlying client
  LibsqlClient? get client => _client;

  /// Initialize with local mode (SQLite file)
  Future<void> initLocal() async {
    if (_isConnected) {
      await disconnect();
    }

    final dir = await getApplicationCacheDirectory();
    final path = '${dir.path}/ngerekrut_local.db';

    _client = LibsqlClient.local(path);
    await _client!.connect();
    _mode = DatabaseMode.localOnly;
    _isConnected = true;

    await _createTables();
  }

  /// Initialize with remote mode (Turso/LibSQL)
  ///
  /// Uses LIBSQL_URL and LIBSQL_URL_TOKEN from environment
  Future<void> initRemote() async {
    if (_isConnected) {
      await disconnect();
    }

    final url = readConfig('LIBSQL_URL');
    final token = readConfig('LIBSQL_URL_TOKEN');

    if (url.isEmpty) {
      throw Exception('LIBSQL_URL not configured in environment');
    }
    if (token.isEmpty) {
      throw Exception('LIBSQL_URL_TOKEN not configured in environment');
    }

    _client = LibsqlClient.remote(url, authToken: token);
    await _client!.connect();
    _mode = DatabaseMode.remoteOnly;
    _isConnected = true;

    await _createTables();
  }

  /// Initialize with replica mode (local + auto-sync to remote)
  ///
  /// Uses LIBSQL_URL and LIBSQL_URL_TOKEN from environment
  Future<void> initReplica({int syncIntervalSeconds = 5}) async {
    if (_isConnected) {
      await disconnect();
    }

    final url = readConfig('LIBSQL_URL');
    final token = readConfig('LIBSQL_URL_TOKEN');

    if (url.isEmpty) {
      throw Exception('LIBSQL_URL not configured in environment');
    }
    if (token.isEmpty) {
      throw Exception('LIBSQL_URL_TOKEN not configured in environment');
    }

    final dir = await getApplicationCacheDirectory();
    final path = '${dir.path}/ngerekrut_replica.db';

    _client = LibsqlClient.replica(
      path,
      syncUrl: url,
      authToken: token,
      syncIntervalSeconds: syncIntervalSeconds,
      readYourWrites: true,
    );
    await _client!.connect();
    _mode = DatabaseMode.replica;
    _isConnected = true;

    await _createTables();
  }

  /// Auto-initialize based on environment and platform
  ///
  /// - Remote only for web (no local file access)
  /// - Replica mode if LIBSQL_URL is configured
  /// - Local only as fallback
  Future<void> autoInit({int syncIntervalSeconds = 5}) async {
    final url = readConfig('LIBSQL_URL');
    final token = readConfig('LIBSQL_URL_TOKEN');

    if (kIsWeb) {
      // Web doesn't support local file storage
      if (url.isNotEmpty && token.isNotEmpty) {
        await initRemote();
      } else {
        throw Exception('Web requires LIBSQL_URL and LIBSQL_URL_TOKEN');
      }
    } else {
      // Mobile/Desktop: prefer replica if configured
      if (url.isNotEmpty && token.isNotEmpty) {
        await initReplica(syncIntervalSeconds: syncIntervalSeconds);
      } else {
        await initLocal();
      }
    }
  }

  /// Manually trigger sync (only for replica mode)
  Future<void> sync() async {
    if (_mode != DatabaseMode.replica) {
      debugPrint('Sync only available in replica mode');
      return;
    }
    await _client?.sync();
  }

  /// Disconnect from database
  Future<void> disconnect() async {
    await _client?.close();
    _client = null;
    _isConnected = false;
  }

  // ==================== Schema Management ====================

  Future<void> _createTables() async {
    if (_client == null) return;

    // Job Applications table (shared between recruiter & jobseeker)
    await _client!.execute('''
      CREATE TABLE IF NOT EXISTS job_applications (
        id TEXT PRIMARY KEY,
        job_id TEXT NOT NULL,
        candidate_id TEXT,
        job_title TEXT NOT NULL,
        company TEXT,
        location TEXT,
        status TEXT NOT NULL,
        applied_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        expected_salary TEXT,
        cover_letter TEXT,
        resume_id TEXT,
        interview_dates TEXT, -- JSON array
        rejection_reason TEXT,
        recruiter_notes TEXT,
        internal_rating INTEGER,
        source TEXT
      )
    ''');

    // Saved Jobs table (jobseeker bookmarks)
    await _client!.execute('''
      CREATE TABLE IF NOT EXISTS saved_jobs (
        id TEXT PRIMARY KEY,
        job_id TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        company TEXT,
        location TEXT,
        saved_at INTEGER NOT NULL,
        notes TEXT,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Job Postings table (recruiter created jobs)
    await _client!.execute('''
      CREATE TABLE IF NOT EXISTS job_postings (
        id TEXT PRIMARY KEY,
        job_id TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        department TEXT,
        location TEXT,
        description TEXT,
        requirements_json TEXT, -- JSON
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Candidates table (shared profiles)
    await _client!.execute('''
      CREATE TABLE IF NOT EXISTS candidates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        headline TEXT,
        years_of_experience INTEGER,
        stage TEXT,
        skills_json TEXT, -- JSON array
        summary TEXT,
        resume_id TEXT,
        resume_file_name TEXT,
        resume_file_url TEXT
      )
    ''');

    // Create indexes for better query performance
    await _client!.execute('CREATE INDEX IF NOT EXISTS idx_applications_job_id ON job_applications(job_id)');
    await _client!.execute('CREATE INDEX IF NOT EXISTS idx_applications_candidate_id ON job_applications(candidate_id)');
    await _client!.execute('CREATE INDEX IF NOT EXISTS idx_applications_status ON job_applications(status)');
    await _client!.execute('CREATE INDEX IF NOT EXISTS idx_saved_jobs_job_id ON saved_jobs(job_id)');
    await _client!.execute('CREATE INDEX IF NOT EXISTS idx_candidates_stage ON candidates(stage)');
  }

  // ==================== Job Applications ====================

  Future<void> insertJobApplication(Map<String, dynamic> data) async {
    final client = _ensureConnected();
    await client.query('''
      INSERT INTO job_applications (
        id, job_id, candidate_id, job_title, company, location, status,
        applied_at, updated_at, expected_salary, cover_letter, resume_id,
        interview_dates, rejection_reason, recruiter_notes, internal_rating, source
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', positional: [
      data['id'],
      data['job_id'],
      data['candidate_id'],
      data['job_title'],
      data['company'],
      data['location'],
      data['status'],
      data['applied_at'],
      data['updated_at'],
      data['expected_salary'],
      data['cover_letter'],
      data['resume_id'],
      data['interview_dates'],
      data['rejection_reason'],
      data['recruiter_notes'],
      data['internal_rating'],
      data['source'],
    ]);
  }

  Future<List<Map<String, dynamic>>> getJobApplicationsByJob(String jobId) async {
    final client = _ensureConnected();
    final result = await client.query(
      'SELECT * FROM job_applications WHERE job_id = ? ORDER BY applied_at DESC',
      positional: [jobId],
    );
    return _parseResult(result);
  }

  Future<List<Map<String, dynamic>>> getJobApplicationsByCandidate(String candidateId) async {
    final client = _ensureConnected();
    final result = await client.query(
      'SELECT * FROM job_applications WHERE candidate_id = ? ORDER BY applied_at DESC',
      positional: [candidateId],
    );
    return _parseResult(result);
  }

  Future<void> updateJobApplicationStatus(String id, String status, {String? rejectionReason}) async {
    final client = _ensureConnected();
    final now = DateTime.now().millisecondsSinceEpoch;
    await client.query('''
      UPDATE job_applications
      SET status = ?, updated_at = ?, rejection_reason = ?
      WHERE id = ?
    ''', positional: [status, now, rejectionReason, id]);
  }

  // ==================== Saved Jobs ====================

  Future<void> insertSavedJob(Map<String, dynamic> data) async {
    final client = _ensureConnected();
    await client.query('''
      INSERT OR REPLACE INTO saved_jobs (id, job_id, title, company, location, saved_at, notes, is_active)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', positional: [
      data['id'],
      data['job_id'],
      data['title'],
      data['company'],
      data['location'],
      data['saved_at'],
      data['notes'],
      data['is_active'] ?? 1,
    ]);
  }

  Future<List<Map<String, dynamic>>> getSavedJobs({bool onlyActive = true}) async {
    final client = _ensureConnected();
    final query = onlyActive
        ? 'SELECT * FROM saved_jobs WHERE is_active = 1 ORDER BY saved_at DESC'
        : 'SELECT * FROM saved_jobs ORDER BY saved_at DESC';
    final result = await client.query(query);
    return _parseResult(result);
  }

  Future<void> removeSavedJob(String jobId) async {
    final client = _ensureConnected();
    await client.query('UPDATE saved_jobs SET is_active = 0 WHERE job_id = ?', positional: [jobId]);
  }

  // ==================== Job Postings ====================

  Future<void> insertJobPosting(Map<String, dynamic> data) async {
    final client = _ensureConnected();
    await client.query('''
      INSERT OR REPLACE INTO job_postings (
        id, job_id, title, department, location, description, requirements_json,
        status, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', positional: [
      data['id'],
      data['job_id'],
      data['title'],
      data['department'],
      data['location'],
      data['description'],
      data['requirements_json'],
      data['status'],
      data['created_at'],
      data['updated_at'],
    ]);
  }

  Future<List<Map<String, dynamic>>> getJobPostings({String? status}) async {
    final client = _ensureConnected();
    final result = status != null
        ? await client.query('SELECT * FROM job_postings WHERE status = ? ORDER BY created_at DESC', positional: [status])
        : await client.query('SELECT * FROM job_postings ORDER BY created_at DESC');
    return _parseResult(result);
  }

  Future<void> updateJobPostingStatus(String jobId, String status) async {
    final client = _ensureConnected();
    final now = DateTime.now().millisecondsSinceEpoch;
    await client.query('UPDATE job_postings SET status = ?, updated_at = ? WHERE job_id = ?',
        positional: [status, now, jobId]);
  }

  // ==================== Candidates ====================

  Future<void> insertCandidate(Map<String, dynamic> data) async {
    final client = _ensureConnected();
    await client.query('''
      INSERT OR REPLACE INTO candidates (
        id, name, headline, years_of_experience, stage, skills_json, summary,
        resume_id, resume_file_name, resume_file_url
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', positional: [
      data['id'],
      data['name'],
      data['headline'],
      data['years_of_experience'],
      data['stage'],
      data['skills_json'],
      data['summary'],
      data['resume_id'],
      data['resume_file_name'],
      data['resume_file_url'],
    ]);
  }

  Future<List<Map<String, dynamic>>> getCandidates({String? stage}) async {
    final client = _ensureConnected();
    final result = stage != null
        ? await client.query('SELECT * FROM candidates WHERE stage = ? ORDER BY name ASC', positional: [stage])
        : await client.query('SELECT * FROM candidates ORDER BY name ASC');
    return _parseResult(result);
  }

  Future<Map<String, dynamic>?> getCandidate(String id) async {
    final client = _ensureConnected();
    final result = await client.query('SELECT * FROM candidates WHERE id = ?', positional: [id]);
    final rows = _parseResult(result);
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<void> updateCandidateStage(String id, String stage) async {
    final client = _ensureConnected();
    await client.query('UPDATE candidates SET stage = ? WHERE id = ?', positional: [stage, id]);
  }

  // ==================== Raw Query Helpers ====================

  /// Execute raw query (for custom operations)
  Future<List<Map<String, dynamic>>> rawQuery(String sql, {List<Object?> positional = const []}) async {
    final client = _ensureConnected();
    final result = await client.query(sql, positional: positional);
    return _parseResult(result);
  }

  /// Execute raw SQL (INSERT, UPDATE, DELETE, DDL)
  Future<void> execute(String sql) async {
    final client = _ensureConnected();
    await client.execute(sql);
  }

  /// Begin transaction
  Future<LibsqlTransaction> beginTransaction() async {
    final client = _ensureConnected();
    return await client.transaction();
  }

  // ==================== Private Helpers ====================

  LibsqlClient _ensureConnected() {
    if (_client == null || !_isConnected) {
      throw Exception('Database not connected. Call autoInit(), initLocal(), initRemote(), or initReplica() first.');
    }
    return _client!;
  }

  List<Map<String, dynamic>> _parseResult(dynamic result) {
    // libsql_dart returns different result types based on query
    // This is a basic parser - adjust based on actual response format
    if (result == null) return [];

    if (result is List) {
      return result.map((row) {
        if (row is Map) {
          return Map<String, dynamic>.from(row);
        }
        return <String, dynamic>{};
      }).toList();
    }

    if (result is Map) {
      // Single row result
      return [Map<String, dynamic>.from(result)];
    }

    return [];
  }
}

// Singleton instance
final hybridDatabase = HybridDatabaseService();
