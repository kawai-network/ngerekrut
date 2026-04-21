/// Context data passed to assistants for contextual awareness.
///
/// Contains tab-specific data that the AI can use to provide relevant responses.
library;

/// Represents a candidate in the context.
class AssistantCandidateContext {
  final String id;
  final String name;
  final String? title;
  final int? score;
  final String? recommendation;
  final List<String>? strengths;
  final List<String>? redFlags;
  final String? summary;

  const AssistantCandidateContext({
    required this.id,
    required this.name,
    this.title,
    this.score,
    this.recommendation,
    this.strengths,
    this.redFlags,
    this.summary,
  });

  String toSummary() {
    final buffer = StringBuffer();
    buffer.writeln('Kandidat: $name');
    if (title != null) buffer.writeln('Posisi: $title');
    if (score != null) buffer.writeln('Skor: $score/100');
    if (recommendation != null) buffer.writeln('Rekomendasi: $recommendation');
    if (strengths != null && strengths!.isNotEmpty) {
      buffer.writeln('Kekuatan: ${strengths!.join(", ")}');
    }
    if (redFlags != null && redFlags!.isNotEmpty) {
      buffer.writeln('Red Flags: ${redFlags!.join(", ")}');
    }
    if (summary != null) buffer.writeln('Ringkasan: $summary');
    return buffer.toString();
  }
}

/// Represents a job posting in the context.
class AssistantJobContext {
  final String id;
  final String title;
  final String? unitLabel;
  final String? location;
  final String? description;
  final List<String>? requirements;
  final String? status;
  final int? candidateCount;
  final int? shortlistCount;
  final int? scorecardCount;
  final int? interviewGuideCount;

  const AssistantJobContext({
    required this.id,
    required this.title,
    this.unitLabel,
    this.location,
    this.description,
    this.requirements,
    this.status,
    this.candidateCount,
    this.shortlistCount,
    this.scorecardCount,
    this.interviewGuideCount,
  });

  String toSummary() {
    final buffer = StringBuffer();
    buffer.writeln('Lowongan: $title');
    if (unitLabel != null) buffer.writeln('Unit: $unitLabel');
    if (location != null) buffer.writeln('Lokasi: $location');
    if (status != null) buffer.writeln('Status: $status');
    if (candidateCount != null) {
      buffer.writeln('Total Kandidat: $candidateCount');
    }
    if (shortlistCount != null) buffer.writeln('Shortlist: $shortlistCount');
    if (scorecardCount != null) buffer.writeln('Scorecard: $scorecardCount');
    if (interviewGuideCount != null) {
      buffer.writeln('Interview Guide: $interviewGuideCount');
    }
    if (description != null) {
      buffer.writeln(
        'Deskripsi: ${description!.length > 100 ? '${description!.substring(0, 100)}...' : description}',
      );
    }
    if (requirements != null && requirements!.isNotEmpty) {
      buffer.writeln('Requirements: ${requirements!.take(5).join(", ")}');
    }
    return buffer.toString();
  }
}

/// Context data for an assistant.
class AssistantContext {
  /// The currently selected job (if any).
  final AssistantJobContext? selectedJob;

  /// List of candidates relevant to the current view.
  final List<AssistantCandidateContext> candidates;

  /// Additional context data (screening results, assessment data, etc.)
  final Map<String, dynamic> extraData;

  const AssistantContext({
    this.selectedJob,
    this.candidates = const [],
    this.extraData = const {},
  });

  /// Build a context summary for the AI system prompt.
  String toSystemContext() {
    if (selectedJob == null && candidates.isEmpty) {
      return 'Belum ada data spesifik yang dipilih pengguna.';
    }

    final buffer = StringBuffer();
    buffer.writeln('\n--- KONTEKS SAAT INI ---');

    if (selectedJob != null) {
      buffer.writeln('\nLowongan Aktif:');
      buffer.writeln(selectedJob!.toSummary());
    }

    if (candidates.isNotEmpty) {
      buffer.writeln('\nKandidat Relevan (${candidates.length}):');
      for (final candidate in candidates.take(5)) {
        buffer.writeln('---');
        buffer.writeln(candidate.toSummary());
      }
    }

    if (extraData.isNotEmpty) {
      buffer.writeln('\nData Tambahan:');
      extraData.forEach((key, value) {
        buffer.writeln('$key: $value');
      });
    }

    buffer.writeln('--- END KONTEKS ---');
    return buffer.toString();
  }
}
