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
          await widget.localShortlistRepository.getLatestForJob(widget.job.id) ??
          await widget.repository.fetchLatestShortlist(widget.job.id);
      final storedScorecards = await widget.localScorecardRepository.listForJob(
        widget.job.id,
      );
      final storedGuides = await widget.localInterviewGuideRepository.listForJob(
        widget.job.id,
      );
      final grouped = <String, List<StoredInterviewScorecard>>{};
      for (final stored in storedScorecards) {
        grouped.putIfAbsent(stored.candidateId, () => []).add(stored);
      }
      final groupedGuides = <String, List<StoredInterviewGuide>>{};
      for (final stored in storedGuides) {
        groupedGuides.putIfAbsent(stored.candidateId, () => []).add(stored);
      }
      if (!mounted) return;
      setState(() {
        _result = result;
        _guidesByCandidate = groupedGuides;
        _scorecardsByCandidate = grouped;
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
      final generated = await widget.interviewGuideGenerationService.generateGuide(
        role: widget.job.title,
        competencyFocus: entry.gaps.isNotEmpty ? entry.gaps.take(2).toList() : null,
      );
      await widget.localInterviewGuideRepository.save(
        jobId: widget.job.id,
        candidateId: entry.candidateId,
        candidateName: entry.candidateName,
        guide: generated.guide,
        usedMode: generated.usedMode.name,
      );
      final updated = await widget.localInterviewGuideRepository.listForCandidate(
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
        SnackBar(content: Text('Interview kit untuk ${entry.candidateName} tersimpan.')),
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
    if (!mounted) return;
    if (interviewType == null) return;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _generatingCandidateId = entry.candidateId);
    try {
      final generated = await widget.scorecardGenerationService.generateScorecard(
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
        SnackBar(content: Text('Scorecard untuk ${entry.candidateName} tersimpan.')),
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
            const ListTile(
              title: Text('Pilih Jenis Scorecard'),
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Shortlist')),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Memuat shortlist dari Cloudflare KV...'),
                ],
              ),
            )
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      widget.job.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    if (_result?.createdAt != null || _result?.usedMode != null)
                      Text(
                        [
                          if (_result?.createdAt != null)
                            DateFormat('dd MMM yyyy HH:mm').format(
                              DateTime.fromMillisecondsSinceEpoch(
                                _result!.createdAt!,
                              ),
                            ),
                          if ((_result?.usedMode ?? '').isNotEmpty)
                            'mode: ${_result!.usedMode}',
                        ].join(' • '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (_result?.createdAt != null || _result?.usedMode != null)
                      const SizedBox(height: 8),
                    Text(_result?.summary ?? ''),
                    const SizedBox(height: 20),
                    Text(
                      'Top 3 Kandidat',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    for (final entry in _result?.topCandidates ??
                        const <RecruiterShortlistEntry>[])
                      Card(
                        child: ExpansionTile(
                          leading: CircleAvatar(child: Text('${entry.rank}')),
                          title: Text(entry.candidateName),
                          subtitle: Text(
                            'Score ${entry.totalScore.toStringAsFixed(0)} • ${entry.recommendation}',
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  FilledButton.tonalIcon(
                                    onPressed: _generatingCandidateId == entry.candidateId
                                        ? null
                                        : () => _generateScorecard(entry),
                                    icon: _generatingCandidateId == entry.candidateId
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.fact_check),
                                    label: const Text('Generate Scorecard'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed:
                                        _generatingGuideCandidateId == entry.candidateId
                                            ? null
                                            : () => _generateInterviewKit(entry),
                                    icon: _generatingGuideCandidateId == entry.candidateId
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.quiz_outlined),
                                    label: const Text('Generate Interview Kit'),
                                  ),
                                ],
                              ),
                            ),
                            if ((_guidesByCandidate[entry.candidateId] ?? const [])
                                .isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Saved Interview Kits',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              const SizedBox(height: 8),
                              for (final stored
                                  in _guidesByCandidate[entry.candidateId]!)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.quiz_outlined),
                                  title: Text(
                                    'STAR Guide • ${stored.usedMode ?? 'unknown'}',
                                  ),
                                  subtitle: Text(
                                    DateFormat('dd MMM yyyy HH:mm').format(
                                      DateTime.fromMillisecondsSinceEpoch(
                                        stored.createdAt,
                                      ),
                                    ),
                                  ),
                                  onTap: () async {
                                    await showModalBottomSheet<void>(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (context) => _InterviewGuideSheet(
                                        guide: stored.guide,
                                      ),
                                    );
                                  },
                                ),
                            ],
                            if ((_scorecardsByCandidate[entry.candidateId] ?? const [])
                                .isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Saved Scorecards',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              const SizedBox(height: 8),
                              for (final stored
                                  in _scorecardsByCandidate[entry.candidateId]!)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.description_outlined),
                                  title: Text(
                                    '${stored.scorecard.interviewType.name} • ${stored.usedMode ?? 'unknown'}',
                                  ),
                                  subtitle: Text(
                                    DateFormat('dd MMM yyyy HH:mm').format(
                                      DateTime.fromMillisecondsSinceEpoch(
                                        stored.createdAt,
                                      ),
                                    ),
                                  ),
                                  onTap: () async {
                                    await showModalBottomSheet<void>(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (context) => _ScorecardSheet(
                                        scorecard: stored.scorecard,
                                      ),
                                    );
                                  },
                                ),
                            ],
                            const SizedBox(height: 8),
                            _BreakdownTable(entry: entry),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(entry.rationale),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final item in entry.strengths)
                                  Chip(
                                    backgroundColor: Colors.green.withValues(
                                      alpha: 0.12,
                                    ),
                                    label: Text('Strength: $item'),
                                  ),
                                for (final item in entry.gaps)
                                  Chip(
                                    backgroundColor: Colors.orange.withValues(
                                      alpha: 0.12,
                                    ),
                                    label: Text('Gap: $item'),
                                  ),
                                for (final item in entry.redFlags)
                                  Chip(
                                    backgroundColor: Colors.red.withValues(
                                      alpha: 0.12,
                                    ),
                                    label: Text('Risk: $item'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if ((_result?.rankedCandidates.length ?? 0) > 3) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Kandidat Lainnya',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      for (final entry in (_result?.rankedCandidates ?? const [])
                          .where((entry) => entry.rank > 3))
                        ListTile(
                          leading: CircleAvatar(child: Text('${entry.rank}')),
                          title: Text(entry.candidateName),
                          subtitle: Text(
                            'Score ${entry.totalScore.toStringAsFixed(0)} • ${entry.recommendation}',
                          ),
                        ),
                    ],
                  ],
                ),
    );
  }
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
            Text(
              guide.role,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
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
                              .map((item) => Chip(label: Text('Concern: $item')))
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

class _BreakdownTable extends StatelessWidget {
  final RecruiterShortlistEntry entry;

  const _BreakdownTable({required this.entry});

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

    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(row.$1)),
                  Text(row.$2.toStringAsFixed(0)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
