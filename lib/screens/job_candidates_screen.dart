import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/recruiter_candidate.dart';
import '../models/recruiter_job.dart';
import '../models/recruiter_shortlist.dart';
import '../repositories/hiring_repository.dart';
import '../repositories/local_interview_guide_repository.dart';
import '../repositories/local_scorecard_repository.dart';
import '../repositories/local_shortlist_repository.dart';
import '../services/resume_screening_service.dart';
import '../services/scorecard_generation_service.dart';
import '../services/interview_guide_generation_service.dart';
import 'shortlist_result_screen.dart';

class JobCandidatesScreen extends StatefulWidget {
  final HiringRepository repository;
  final LocalInterviewGuideRepository localInterviewGuideRepository;
  final LocalShortlistRepository localShortlistRepository;
  final LocalScorecardRepository localScorecardRepository;
  final InterviewGuideGenerationService interviewGuideGenerationService;
  final ResumeScreeningService screeningService;
  final ScorecardGenerationService scorecardGenerationService;

  const JobCandidatesScreen({
    super.key,
    required this.repository,
    required this.localInterviewGuideRepository,
    required this.localShortlistRepository,
    required this.localScorecardRepository,
    required this.interviewGuideGenerationService,
    required this.screeningService,
    required this.scorecardGenerationService,
  });

  @override
  State<JobCandidatesScreen> createState() => _JobCandidatesScreenState();
}

class _JobCandidatesScreenState extends State<JobCandidatesScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  RecruiterJob? _job;
  List<RecruiterCandidate> _candidates = const [];
  List<RecruiterShortlistResult> _localShortlists = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final jobs = await widget.repository.fetchJobs();
      if (jobs.isEmpty) {
        throw Exception('Belum ada lowongan dari API.');
      }

      final data = await widget.repository.fetchCandidates(jobs.first.id);
      final shortlists = await widget.localShortlistRepository.listForJob(
        data.job.id,
      );
      if (!mounted) return;
      setState(() {
        _job = data.job;
        _candidates = data.candidates;
        _localShortlists = shortlists;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _runScreening() async {
    final job = _job;
    if (job == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final shortlist = await widget.screeningService.screenCandidates(
        job: job,
        candidates: _candidates,
        topN: 3,
      );
      await widget.localShortlistRepository.save(shortlist);
      final shortlists = await widget.localShortlistRepository.listForJob(job.id);
      if (!mounted) return;
      setState(() => _localShortlists = shortlists);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShortlistResultScreen(
            repository: widget.repository,
            localInterviewGuideRepository: widget.localInterviewGuideRepository,
            localShortlistRepository: widget.localShortlistRepository,
            localScorecardRepository: widget.localScorecardRepository,
            interviewGuideGenerationService:
                widget.interviewGuideGenerationService,
            scorecardGenerationService: widget.scorecardGenerationService,
            job: job,
            initialResult: shortlist,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menjalankan screening: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Color _stageColor(String stage) {
    switch (stage) {
      case 'screening':
        return Colors.orange;
      case 'shortlisted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kandidat Per Lowongan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_job != null) _JobCard(job: _job!),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Pelamar (${_candidates.length})',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: _isSubmitting ? null : _runScreening,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome),
                            label: Text(
                              _isSubmitting
                                  ? 'Memuat...'
                                  : 'Run AI Screening',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _job == null
                            ? null
                            : () async {
                                final navigator = Navigator.of(context);
                                final messenger = ScaffoldMessenger.of(context);
                                final saved = await widget
                                    .localShortlistRepository
                                    .getLatestForJob(_job!.id);
                                if (!mounted) return;
                                if (saved == null) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Belum ada shortlist lokal tersimpan.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                await navigator.push(
                                  MaterialPageRoute(
                                    builder: (context) => ShortlistResultScreen(
                                      repository: widget.repository,
                                      localInterviewGuideRepository:
                                          widget.localInterviewGuideRepository,
                                      localShortlistRepository:
                                          widget.localShortlistRepository,
                                      localScorecardRepository:
                                          widget.localScorecardRepository,
                                      interviewGuideGenerationService:
                                          widget.interviewGuideGenerationService,
                                      scorecardGenerationService:
                                          widget.scorecardGenerationService,
                                      job: _job!,
                                      initialResult: saved,
                                    ),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.history),
                        label: const Text('Open Saved Shortlist'),
                      ),
                      if (_localShortlists.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Riwayat Shortlist Lokal',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        for (final shortlist in _localShortlists.take(5))
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.history),
                              title: Text(
                                shortlist.usedMode == null
                                    ? shortlist.status
                                    : '${shortlist.status} • ${shortlist.usedMode}',
                              ),
                              subtitle: Text(
                                shortlist.createdAt == null
                                    ? shortlist.summary
                                    : '${DateFormat('dd MMM yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(shortlist.createdAt!))}\n${shortlist.summary}',
                              ),
                              isThreeLine: true,
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ShortlistResultScreen(
                                      repository: widget.repository,
                                      localInterviewGuideRepository:
                                          widget.localInterviewGuideRepository,
                                      localShortlistRepository:
                                          widget.localShortlistRepository,
                                      localScorecardRepository:
                                          widget.localScorecardRepository,
                                      interviewGuideGenerationService:
                                          widget.interviewGuideGenerationService,
                                      scorecardGenerationService:
                                          widget.scorecardGenerationService,
                                      job: _job!,
                                      initialResult: shortlist,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                      const SizedBox(height: 12),
                      for (final candidate in _candidates)
                        Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(candidate.name),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (candidate.headline != null)
                                    Text(candidate.headline!),
                                  const SizedBox(height: 6),
                                  Text(
                                    candidate.profile?.summary ??
                                        'Belum ada ringkasan profil.',
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Chip(
                                        label: Text(
                                          '${candidate.yearsOfExperience ?? 0} tahun',
                                        ),
                                      ),
                                      Chip(
                                        backgroundColor: _stageColor(
                                          candidate.stage,
                                        ).withValues(alpha: 0.12),
                                        label: Text(candidate.stage),
                                      ),
                                      for (final skill
                                          in candidate.profile?.skills
                                                  .take(3) ??
                                              const <String>[])
                                        Chip(label: Text(skill)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final RecruiterJob job;

  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '${job.department ?? '-'} • ${job.location ?? '-'} • ${job.status}',
            ),
            if (job.description != null) ...[
              const SizedBox(height: 12),
              Text(job.description!),
            ],
            if (job.requirements.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: job.requirements.map((item) => Chip(label: Text(item))).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
