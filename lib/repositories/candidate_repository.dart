/// Candidate repository using libsql_dart
/// Shared candidate profiles (jobseeker → recruiter)
library;

import '../models/candidate.dart';
import '../services/hybrid_database_service.dart';

class CandidateRepository {
  final HybridDatabaseService _db;

  CandidateRepository({HybridDatabaseService? db}) : _db = db ?? hybridDatabase;

  /// Create or update a candidate profile
  Future<void> save(RecruiterCandidate candidate) async {
    await _db.insertCandidate({
      'id': candidate.id,
      'name': candidate.name,
      'headline': candidate.headline,
      'years_of_experience': candidate.yearsOfExperience,
      'stage': candidate.stage,
      'skills_json': candidate.profile != null ? _encodeSkills(candidate.profile!.skills) : null,
      'summary': candidate.profile?.summary,
      'resume_id': candidate.resume?.id,
      'resume_file_name': candidate.resume?.fileName,
      'resume_file_url': candidate.resume?.fileUrl,
    });
  }

  /// Get candidate by ID
  Future<RecruiterCandidate?> getById(String id) async {
    final candidate = await _db.getCandidate(id);
    return candidate != null ? _fromMap(candidate) : null;
  }

  /// Get all candidates
  Future<List<RecruiterCandidate>> getAll({String? stage}) async {
    final rows = await _db.getCandidates(stage: stage);
    return rows.map((row) => _fromMap(row)).toList();
  }

  /// Get candidates by stage
  Future<List<RecruiterCandidate>> getByStage(String stage) async {
    return await getAll(stage: stage);
  }

  /// Update candidate stage
  Future<void> updateStage(String id, String stage) async {
    await _db.updateCandidateStage(id, stage);
  }

  /// Get candidates for a specific job (with filtering)
  Future<List<RecruiterCandidate>> getForJob({
    String? stage,
    int? minYearsOfExperience,
    List<String>? requiredSkills,
  }) async {
    var query = 'SELECT * FROM candidates WHERE 1=1';
    final params = <Object?>[];

    if (stage != null) {
      query += ' AND stage = ?';
      params.add(stage);
    }
    if (minYearsOfExperience != null) {
      query += ' AND years_of_experience >= ?';
      params.add(minYearsOfExperience);
    }

    query += ' ORDER BY name ASC';

    final rows = await _db.rawQuery(query, positional: params);
    var candidates = rows.map((row) => _fromMap(row)).toList();

    // Filter by skills in code
    if (requiredSkills != null && requiredSkills.isNotEmpty) {
      candidates = candidates.where((c) {
        if (c.profile == null) return false;
        final skills = c.profile!.skills;
        return requiredSkills.every((required) => skills.contains(required));
      }).toList();
    }

    return candidates;
  }

  /// Search candidates by name or headline
  Future<List<RecruiterCandidate>> search(String query) async {
    final rows = await _db.rawQuery('''
      SELECT * FROM candidates
      WHERE name LIKE ? OR headline LIKE ?
      ORDER BY name ASC
    ''', positional: ['%$query%', '%$query%']);
    return rows.map((row) => _fromMap(row)).toList();
  }

  /// Delete a candidate
  Future<void> delete(String id) async {
    await _db.rawQuery('DELETE FROM candidates WHERE id = ?', positional: [id]);
  }

  // ==================== Helpers ====================

  RecruiterCandidate _fromMap(Map<String, dynamic> map) {
    return RecruiterCandidate(
      id: map['id'] as String,
      name: map['name'] as String,
      headline: map['headline'] as String?,
      yearsOfExperience: map['years_of_experience'] as int?,
      stage: map['stage'] as String? ?? 'applied',
      profile: (map['skills_json'] != null || map['summary'] != null)
          ? CandidateProfile(
              skills: _decodeSkills(map['skills_json'] as String?),
              summary: map['summary'] as String? ?? '',
            )
          : null,
      resume: (map['resume_id'] != null)
          ? CandidateResume(
              id: map['resume_id'] as String,
              fileName: map['resume_file_name'] as String? ?? 'resume.pdf',
              fileUrl: map['resume_file_url'] as String?,
            )
          : null,
    );
  }

  String _encodeSkills(List<String> skills) {
    return '[${skills.map((s) => '"$s"').join(',')}]';
  }

  List<String> _decodeSkills(String? encoded) {
    if (encoded == null || encoded.isEmpty || encoded == '[]') return [];
    try {
      final clean = encoded.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
      return clean.split(',').where((s) => s.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }
}
