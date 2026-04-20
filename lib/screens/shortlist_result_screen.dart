import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/hiring_models.dart';
import '../models/recruiter_job.dart';
import '../models/recruiter_shortlist.dart';
import '../repositories/hiring_repository.dart';
import '../repositories/local_interview_guide_repository.dart';
import '../repositories/local_scorecard_repository.dart';
import '../repositories/local_shortlist_repository.dart';
import '../services/interview_guide_generation_service.dart';
import '../services/scorecard_generation_service.dart';

class ShortlistResultScreen extends StatefulWidget {
  final HiringRepository repository;
  final LocalInterviewGuideRepository localInterviewGuideRepository;
  final LocalShortlistRepository localShortlistRepository;
  final LocalScorecardRepository localScorecardRepository;
  final InterviewGuideGenerationService interviewGuideGenerationService;
  final ScorecardGenerationService scorecardGenerationService;
  final RecruiterJob job;
  final RecruiterShortlistResult? initialResult;

  const ShortlistResultScreen({
    super.key,
    required this.repository,
    required this.localInterviewGuideRepository,
    required this.localShortlistRepository,
    required this.localScorecardRepository,
    required this.interviewGuideGenerationService,
    required this.scorecardGenerationService,
    required this.job,
    this.initialResult,
  });

  @override
  State<ShortlistResultScreen> createState() => _ShortlistResultScreenState();
}

class _ShortlistResultScreenState extends State<ShortlistResultScreen> {
  bool _isLoading = true;
  String? _error;
  RecruiterShortlistResult? _result;
  Map<String, List<StoredInterviewGuide>> _guidesByCandidate = const {};
  Map<String, List<StoredInterviewScorecard>> _scorecardsByCandidate = const {};
  String? _generatingCandidateId;
  String? _generatingGuideCandidateId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result =
          widget.initialResult ??
          await widget.localShortlistRepository.getLatestForJob(
            widget.job.id,
          ) ??
          await widget.repository.fetchLatestShortlist(widget.job.id);
      final storedScorecards = await widget.localScorecardRepository.listForJob(
        widget.job.id,
      );
      final storedGuides = await widget.localInterviewGuideRepository
          .listForJob(widget.job.id);

      final groupedScorecards = <String, List<StoredInterviewScorecard>>{};
      for (final stored in storedScorecards) {
        groupedScorecards.putIfAbsent(stored.candidateId, () => []).add(stored);
      }

      final groupedGuides = <String, List<StoredInterviewGuide>>{};
      for (final stored in storedGuides) {
        groupedGuides.putIfAbsent(stored.candidateId, () => []).add(stored);
      }

      if (!mounted) return;
      setState(() {
        _result = result;
        _guidesByCandidate = groupedGuides;
        _scorecardsByCandidate = groupedScorecards;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _generateInterviewKit(RecruiterShortlistEntry entry) async {
    if (_generatingGuideCandidateId != null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _generatingGuideCandidateId = entry.candidateId);
    try {
      final generated = await widget.interviewGuideGenerationService
          .generateGuide(
            role: widget.job.title,
            competencyFocus: entry.gaps.isNotEmpty
                ? entry.gaps.take(2).toList()
                : null,
          );
      await widget.localInterviewGuideRepository.save(
        jobId: widget.job.id,
        candidateId: entry.candidateId,
        candidateName: entry.candidateName,
        guide: generated.guide,
        usedMode: generated.usedMode.name,
      );
      final updated = await widget.localInterviewGuideRepository
          .listForCandidate(
            jobId: widget.job.id,
            candidateId: entry.candidateId,
          );
      if (!mounted) return;
      setState(() {
        _guidesByCandidate = {
          ..._guidesByCandidate,
          entry.candidateId: updated,
        };
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Interview kit untuk ${entry.candidateName} tersimpan.',
          ),
        ),
      );
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _InterviewGuideSheet(guide: generated.guide),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal membuat interview kit: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _generatingGuideCandidateId = null);
      }
    }
  }

  Future<void> _generateScorecard(RecruiterShortlistEntry entry) async {
    if (_generatingCandidateId != null) return;
    final interviewType = await _pickInterviewType();
    if (!mounted || interviewType == null) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _generatingCandidateId = entry.candidateId);
    try {
      final generated = await widget.scorecardGenerationService
          .generateScorecard(
            role: widget.job.title,
            candidateName: entry.candidateName,
            interviewType: interviewType,
          );
      await widget.localScorecardRepository.save(
        jobId: widget.job.id,
        candidateId: entry.candidateId,
        candidateName: entry.candidateName,
        scorecard: generated.scorecard,
        usedMode: generated.usedMode.name,
      );
      final updated = await widget.localScorecardRepository.listForCandidate(
        jobId: widget.job.id,
        candidateId: entry.candidateId,
      );
      if (!mounted) return;
      setState(() {
        _scorecardsByCandidate = {
          ..._scorecardsByCandidate,
          entry.candidateId: updated,
        };
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text('Scorecard untuk ${entry.candidateName} tersimpan.'),
        ),
      );
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _ScorecardSheet(scorecard: generated.scorecard),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal membuat scorecard: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _generatingCandidateId = null);
      }
    }
  }

  Future<InterviewType?> _pickInterviewType() async {
    return showModalBottomSheet<InterviewType>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Pilih Jenis Scorecard')),
            for (final type in InterviewType.values)
              ListTile(
                leading: const Icon(Icons.checklist_rtl),
                title: Text(_interviewTypeLabel(type)),
                onTap: () => Navigator.of(context).pop(type),
              ),
          ],
        ),
      ),
    );
  }

  String _interviewTypeLabel(InterviewType type) {
    switch (type) {
      case InterviewType.technical:
        return 'Technical';
      case InterviewType.design:
        return 'System Design';
      case InterviewType.behavioral:
        return 'Behavioral';
      case InterviewType.finalRound:
        return 'Final Round';
      case InterviewType.recruiter:
        return 'Recruiter Screen';
    }
  }

  _CandidateReadiness _candidateReadiness(RecruiterShortlistEntry entry) {
    final guides = _guidesByCandidate[entry.candidateId] ?? const [];
    final scorecards = _scorecardsByCandidate[entry.candidateId] ?? const [];
    final hasGuide = guides.isNotEmpty;
    final hasScorecard = scorecards.isNotEmpty;

    if (hasGuide && hasScorecard) {
      return const _CandidateReadiness(
        label: 'Siap interview',
        color: Color(0xFF166534),
        backgroundColor: Color(0xFFDCFCE7),
      );
    }
    if (hasGuide || hasScorecard) {
      return const _CandidateReadiness(
        label: 'Dokumen belum lengkap',
        color: Color(0xFFB45309),
        backgroundColor: Color(0xFFFEF3C7),
      );
    }
    return const _CandidateReadiness(
      label: 'Perlu persiapan',
      color: Color(0xFF1D4ED8),
      backgroundColor: Color(0xFFDBEAFE),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final topCandidates =
        result?.topCandidates ?? const <RecruiterShortlistEntry>[];
    final otherCandidates =
        (result?.rankedCandidates ?? const <RecruiterShortlistEntry>[])
            .where((entry) => entry.rank > 3)
            .toList();
    final readyCount = topCandidates
        .where((entry) => _candidateReadiness(entry).label == 'Siap interview')
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Shortlist')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0F172A), Color(0xFF0F766E)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kandidat terbaik untuk ${widget.job.title}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        result?.summary ?? 'Belum ada ringkasan shortlist.',
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _HeroMetric(
                            label: 'Kandidat dinilai',
                            value: '${result?.rankedCandidates.length ?? 0}',
                          ),
                          _HeroMetric(
                            label: 'Top kandidat',
                            value: '${topCandidates.length}',
                          ),
                          _HeroMetric(
                            label: 'Siap interview',
                            value: '$readyCount',
                          ),
                        ],
                      ),
                      if (result?.createdAt != null ||
                          result?.usedMode != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          [
                            if (result?.createdAt != null)
                              DateFormat('dd MMM yyyy HH:mm').format(
                                DateTime.fromMillisecondsSinceEpoch(
                                  result!.createdAt!,
                                ),
                              ),
                            if ((result?.usedMode ?? '').isNotEmpty)
                              'mode ${result!.usedMode}',
                          ].join(' • '),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Kandidat prioritas',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fokus ke tiga kandidat terbaik, lalu lengkapi dokumen interview bila belum tersedia.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                for (final entry in topCandidates)
                  _ShortlistCandidateCard(
                    entry: entry,
                    readiness: _candidateReadiness(entry),
                    isGeneratingScorecard:
                        _generatingCandidateId == entry.candidateId,
                    isGeneratingGuide:
                        _generatingGuideCandidateId == entry.candidateId,
                    guides: _guidesByCandidate[entry.candidateId] ?? const [],
                    scorecards:
                        _scorecardsByCandidate[entry.candidateId] ?? const [],
                    onGenerateScorecard: () => _generateScorecard(entry),
                    onGenerateGuide: () => _generateInterviewKit(entry),
                  ),
                if (otherCandidates.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Kandidat cadangan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Daftar ini berguna jika kandidat utama tidak lanjut ke tahap berikutnya.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...otherCandidates.map(
                    (entry) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        leading: CircleAvatar(child: Text('${entry.rank}')),
                        title: Text(
                          entry.candidateName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          'Score ${entry.totalScore.toStringAsFixed(0)} • ${entry.recommendation}',
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortlistCandidateCard extends StatelessWidget {
  const _ShortlistCandidateCard({
    required this.entry,
    required this.readiness,
    required this.isGeneratingScorecard,
    required this.isGeneratingGuide,
    required this.guides,
    required this.scorecards,
    required this.onGenerateScorecard,
    required this.onGenerateGuide,
  });

  final RecruiterShortlistEntry entry;
  final _CandidateReadiness readiness;
  final bool isGeneratingScorecard;
  final bool isGeneratingGuide;
  final List<StoredInterviewGuide> guides;
  final List<StoredInterviewScorecard> scorecards;
  final VoidCallback onGenerateScorecard;
  final VoidCallback onGenerateGuide;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(child: Text('${entry.rank}')),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.candidateName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Score ${entry.totalScore.toStringAsFixed(0)} • ${entry.recommendation}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                _ReadinessChip(readiness: readiness),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              entry.rationale,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  label: guides.isNotEmpty
                      ? 'Guide ${guides.length}'
                      : 'Guide belum ada',
                  color: guides.isNotEmpty
                      ? const Color(0xFF166534)
                      : const Color(0xFFB45309),
                  backgroundColor: guides.isNotEmpty
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                ),
                _StatusChip(
                  label: scorecards.isNotEmpty
                      ? 'Scorecard ${scorecards.length}'
                      : 'Scorecard belum ada',
                  color: scorecards.isNotEmpty
                      ? const Color(0xFF166534)
                      : const Color(0xFFB45309),
                  backgroundColor: scorecards.isNotEmpty
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: isGeneratingScorecard ? null : onGenerateScorecard,
                  icon: isGeneratingScorecard
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.fact_check),
                  label: const Text('Buat Scorecard'),
                ),
                OutlinedButton.icon(
                  onPressed: isGeneratingGuide ? null : onGenerateGuide,
                  icon: isGeneratingGuide
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.quiz_outlined),
                  label: const Text('Buat Interview Kit'),
                ),
              ],
            ),
            if (guides.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Interview kit tersimpan',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...guides.map(
                (stored) => _StoredArtifactTile(
                  icon: Icons.quiz_outlined,
                  title: 'STAR Guide • ${stored.usedMode ?? 'unknown'}',
                  subtitle: DateFormat('dd MMM yyyy HH:mm').format(
                    DateTime.fromMillisecondsSinceEpoch(stored.createdAt),
                  ),
                  onTap: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) =>
                          _InterviewGuideSheet(guide: stored.guide),
                    );
                  },
                ),
              ),
            ],
            if (scorecards.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Scorecard tersimpan',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...scorecards.map(
                (stored) => _StoredArtifactTile(
                  icon: Icons.description_outlined,
                  title:
                      '${stored.scorecard.interviewType.name} • ${stored.usedMode ?? 'unknown'}',
                  subtitle: DateFormat('dd MMM yyyy HH:mm').format(
                    DateTime.fromMillisecondsSinceEpoch(stored.createdAt),
                  ),
                  onTap: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) =>
                          _ScorecardSheet(scorecard: stored.scorecard),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            _BreakdownCard(entry: entry),
            if (entry.strengths.isNotEmpty ||
                entry.gaps.isNotEmpty ||
                entry.redFlags.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in entry.strengths)
                    Chip(
                      backgroundColor: Colors.green.withValues(alpha: 0.12),
                      label: Text('Kekuatan: $item'),
                    ),
                  for (final item in entry.gaps)
                    Chip(
                      backgroundColor: Colors.orange.withValues(alpha: 0.12),
                      label: Text('Gap: $item'),
                    ),
                  for (final item in entry.redFlags)
                    Chip(
                      backgroundColor: Colors.red.withValues(alpha: 0.12),
                      label: Text('Risiko: $item'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StoredArtifactTile extends StatelessWidget {
  const _StoredArtifactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}

class _ReadinessChip extends StatelessWidget {
  const _ReadinessChip({required this.readiness});

  final _CandidateReadiness readiness;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: readiness.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        readiness.label,
        style: TextStyle(color: readiness.color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.entry});

  final RecruiterShortlistEntry entry;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, double)>[
      ('Skill match', entry.scoreBreakdown.skillMatch),
      ('Relevant experience', entry.scoreBreakdown.relevantExperience),
      ('Domain fit', entry.scoreBreakdown.domainFit),
      ('Communication clarity', entry.scoreBreakdown.communicationClarity),
      ('Growth potential', entry.scoreBreakdown.growthPotential),
      ('Penalty', entry.scoreBreakdown.penalty),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Breakdown penilaian',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(row.$1)),
                  Text(
                    row.$2.toStringAsFixed(0),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateReadiness {
  final String label;
  final Color color;
  final Color backgroundColor;

  const _CandidateReadiness({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });
}

class _InterviewGuideSheet extends StatelessWidget {
  final STARInterviewGuide guide;

  const _InterviewGuideSheet({required this.guide});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Material(
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Text(guide.role, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(
              'STAR Questions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < guide.questions.length; i++)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${i + 1}. ${guide.questions[i].competency}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(guide.questions[i].question),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: guide.questions[i].lookFor
                            .map((item) => Chip(label: Text('Look for: $item')))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'Scoring Guide',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(guide.scoringGuide),
          ],
        ),
      ),
    );
  }
}

class _ScorecardSheet extends StatelessWidget {
  final InterviewScorecard scorecard;

  const _ScorecardSheet({required this.scorecard});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Material(
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              scorecard.candidate,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('${scorecard.role} • ${scorecard.interviewType.name}'),
            const SizedBox(height: 8),
            if (scorecard.weightedScore != null)
              Text('Weighted score: ${scorecard.weightedScore}'),
            if (scorecard.recommendation != null)
              Text('Recommendation: ${scorecard.recommendation!.name}'),
            if ((scorecard.summary ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(scorecard.summary!),
            ],
            const SizedBox(height: 16),
            Text(
              'Competencies',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final competency in scorecard.competencies)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${competency.competency.name} • ${competency.weight}%',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (competency.score != null)
                        Text('Score: ${competency.score}'),
                      if ((competency.evidence ?? '').isNotEmpty)
                        Text('Evidence: ${competency.evidence}'),
                      if (competency.strongSignals.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: competency.strongSignals
                              .map((item) => Chip(label: Text('Strong: $item')))
                              .toList(),
                        ),
                      ],
                      if (competency.concerns.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: competency.concerns
                              .map(
                                (item) => Chip(label: Text('Concern: $item')),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if ((scorecard.nextSteps ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Next steps',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(scorecard.nextSteps!),
            ],
          ],
        ),
      ),
    );
  }
}
