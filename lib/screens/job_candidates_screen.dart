import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/candidate.dart';
import '../models/recruiter_job.dart';
import '../models/recruiter_shortlist.dart';
import '../repositories/hiring_repository.dart';
import '../repositories/interview_guide_artifact_repository.dart';
import '../repositories/scorecard_artifact_repository.dart';
import '../repositories/shortlist_artifact_repository.dart';
import '../services/interview_guide_generation_service.dart';
import '../services/resume_screening_service.dart';
import '../services/scorecard_generation_service.dart';
import 'shortlist_result_screen.dart';

class JobCandidatesScreen extends StatefulWidget {
  final HiringRepository repository;
  final InterviewGuideArtifactRepository interviewGuideArtifactRepository;
  final ShortlistArtifactRepository shortlistArtifactRepository;
  final ScorecardArtifactRepository scorecardArtifactRepository;
  final InterviewGuideGenerationService interviewGuideGenerationService;
  final ResumeScreeningService screeningService;
  final ScorecardGenerationService scorecardGenerationService;

  const JobCandidatesScreen({
    super.key,
    required this.repository,
    required this.interviewGuideArtifactRepository,
    required this.shortlistArtifactRepository,
    required this.scorecardArtifactRepository,
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
  String _candidateFilter = 'all';
  List<RecruiterJob> _jobs = const [];
  RecruiterJob? _selectedJob;
  List<RecruiterCandidate> _candidates = const [];
  List<RecruiterShortlistResult> _localShortlists = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? selectedJobId}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final jobs = await widget.repository.fetchJobs();
      if (jobs.isEmpty) {
        throw Exception('Belum ada lowongan dari API.');
      }

      final targetJob = _resolveSelectedJob(jobs, selectedJobId);
      final data = await widget.repository.fetchCandidates(targetJob.id);
      final shortlists = await widget.shortlistArtifactRepository.listForJob(
        data.job.id,
      );

      if (!mounted) return;
      setState(() {
        _jobs = jobs;
        _selectedJob = data.job;
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

  RecruiterJob _resolveSelectedJob(
    List<RecruiterJob> jobs,
    String? selectedJobId,
  ) {
    final existingId = selectedJobId ?? _selectedJob?.id;
    if (existingId == null) return jobs.first;
    for (final job in jobs) {
      if (job.id == existingId) return job;
    }
    return jobs.first;
  }

  Future<void> _changeSelectedJob(String jobId) async {
    if (_selectedJob?.id == jobId || _isLoading) return;
    await _load(selectedJobId: jobId);
  }

  Future<void> _runScreening() async {
    final job = _selectedJob;
    if (job == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final shortlist = await widget.screeningService.screenCandidates(
        job: job,
        candidates: _candidates,
        topN: 3,
      );
      await widget.shortlistArtifactRepository.save(shortlist);
      final shortlists = await widget.shortlistArtifactRepository.listForJob(
        job.id,
      );
      if (!mounted) return;
      setState(() => _localShortlists = shortlists);
      await _openShortlist(shortlist);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menjalankan penilaian kandidat: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _openSavedShortlist() async {
    final job = _selectedJob;
    if (job == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final saved = await widget.shortlistArtifactRepository.getLatestForJob(
      job.id,
    );
    if (!mounted) return;
    if (saved == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Belum ada hasil penilaian tersimpan untuk lowongan ini.',
          ),
        ),
      );
      return;
    }
    await _openShortlist(saved);
  }

  Future<void> _openShortlist(RecruiterShortlistResult shortlist) async {
    final job = _selectedJob;
    if (job == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShortlistResultScreen(
          repository: widget.repository,
          interviewGuideArtifactRepository:
              widget.interviewGuideArtifactRepository,
          shortlistArtifactRepository: widget.shortlistArtifactRepository,
          scorecardArtifactRepository: widget.scorecardArtifactRepository,
          interviewGuideGenerationService:
              widget.interviewGuideGenerationService,
          scorecardGenerationService: widget.scorecardGenerationService,
          job: job,
          initialResult: shortlist,
        ),
      ),
    );
  }

  List<RecruiterCandidate> get _filteredCandidates {
    switch (_candidateFilter) {
      case 'screening':
        return _candidates
            .where((candidate) => candidate.stage == 'screening')
            .toList();
      case 'shortlisted':
        return _candidates
            .where((candidate) => candidate.stage == 'shortlisted')
            .toList();
      case 'rejected':
        return _candidates
            .where((candidate) => candidate.stage == 'rejected')
            .toList();
      default:
        return _candidates;
    }
  }

  Color _stageColor(String stage) {
    switch (stage) {
      case 'screening':
        return const Color(0xFFB45309);
      case 'shortlisted':
        return const Color(0xFF166534);
      case 'rejected':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFF1D4ED8);
    }
  }

  String _stageLabel(String stage) {
    switch (stage) {
      case 'screening':
        return 'Sedang direview';
      case 'shortlisted':
        return 'Kandidat unggulan';
      case 'rejected':
        return 'Tidak lanjut';
      case 'applied':
        return 'Baru masuk';
      default:
        return stage;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Kandidat')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _JobPicker(
                    jobs: _jobs,
                    selectedJobId: _selectedJob?.id,
                    onSelected: _changeSelectedJob,
                  ),
                  const SizedBox(height: 20),
                  if (_selectedJob != null) _JobOverview(job: _selectedJob!),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'Tindakan cepat',
                    action: FilledButton.icon(
                      onPressed: _selectedJob == null || _isSubmitting
                          ? null
                          : _runScreening,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        _isSubmitting
                            ? 'Menilai kandidat...'
                            : 'Nilai Kandidat',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _QuickActionRow(
                    selectedJob: _selectedJob,
                    shortlistCount: _localShortlists.length,
                    onOpenSavedShortlist: _openSavedShortlist,
                  ),
                  if (_localShortlists.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionHeader(
                      title: 'Riwayat hasil kandidat',
                      subtitle: 'Hasil penilaian terakhir untuk lowongan ini.',
                    ),
                    const SizedBox(height: 12),
                    ..._localShortlists
                        .take(5)
                        .map(
                          (shortlist) => _ShortlistHistoryCard(
                            shortlist: shortlist,
                            onTap: () => _openShortlist(shortlist),
                          ),
                        ),
                  ],
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Daftar kandidat',
                    subtitle:
                        '${_filteredCandidates.length} kandidat ditampilkan untuk lowongan ini.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('all', 'Semua'),
                      _buildFilterChip('screening', 'Sedang direview'),
                      _buildFilterChip('shortlisted', 'Unggulan'),
                      _buildFilterChip('rejected', 'Tidak lanjut'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_filteredCandidates.isEmpty)
                    const _EmptyListState(
                      title: 'Tidak ada kandidat untuk filter ini',
                      description:
                          'Ganti filter atau pilih lowongan lain untuk melihat kandidat yang tersedia.',
                    )
                  else
                    ..._filteredCandidates.map(
                      (candidate) => _CandidateCard(
                        candidate: candidate,
                        stageColor: _stageColor(candidate.stage),
                        stageLabel: _stageLabel(candidate.stage),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _candidateFilter == value;
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      label: Text(label),
      selectedColor: const Color(0xFFDCFCE7),
      side: BorderSide(
        color: isSelected ? const Color(0xFF86EFAC) : const Color(0xFFE5E7EB),
      ),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: isSelected ? const Color(0xFF166534) : null,
      ),
      onSelected: (_) {
        setState(() => _candidateFilter = value);
      },
    );
  }
}

class _JobPicker extends StatelessWidget {
  const _JobPicker({
    required this.jobs,
    required this.selectedJobId,
    required this.onSelected,
  });

  final List<RecruiterJob> jobs;
  final String? selectedJobId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih lowongan',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Ganti lowongan untuk melihat kandidat dan riwayat hasil yang relevan.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedJobId,
              isExpanded: true,
              hint: const Text('Pilih lowongan'),
              items: jobs
                  .map(
                    (job) => DropdownMenuItem<String>(
                      value: job.id,
                      child: Text(job.title),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onSelected(value);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _JobOverview extends StatelessWidget {
  const _JobOverview({required this.job});

  final RecruiterJob job;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              [
                if ((job.unitLabel ?? '').isNotEmpty) job.unitLabel!,
                if ((job.location ?? '').isNotEmpty) job.location!,
                job.status,
              ].join(' • '),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
            ),
            if ((job.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                job.description!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
            ],
            if (job.requirements.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: job.requirements
                    .take(6)
                    .map((item) => Chip(label: Text(item)))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle, this.action});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                ),
              ],
            ],
          ),
        ),
        action ?? const SizedBox.shrink(),
      ],
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({
    required this.selectedJob,
    required this.shortlistCount,
    required this.onOpenSavedShortlist,
  });

  final RecruiterJob? selectedJob;
  final int shortlistCount;
  final VoidCallback onOpenSavedShortlist;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.history,
            title: 'Hasil tersimpan',
            subtitle: '$shortlistCount hasil tersedia',
            onTap: selectedJob == null ? null : onOpenSavedShortlist,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.checklist_rtl,
            title: 'Status lowongan',
            subtitle: selectedJob?.status ?? 'Belum dipilih',
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortlistHistoryCard extends StatelessWidget {
  const _ShortlistHistoryCard({required this.shortlist, required this.onTap});

  final RecruiterShortlistResult shortlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
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
        leading: const Icon(Icons.history),
        title: Text(
          shortlist.usedMode == null
              ? shortlist.status
              : '${shortlist.status} • ${shortlist.usedMode}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          shortlist.createdAt == null
              ? shortlist.summary
              : '${DateFormat('dd MMM yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(shortlist.createdAt!))}\n${shortlist.summary}',
        ),
        isThreeLine: true,
        onTap: onTap,
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.candidate,
    required this.stageColor,
    required this.stageLabel,
  });

  final RecruiterCandidate candidate;
  final Color stageColor;
  final String stageLabel;

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if ((candidate.headline ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          candidate.headline!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey.shade700),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: stageColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    stageLabel,
                    style: TextStyle(
                      color: stageColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              candidate.profile?.summary.isNotEmpty == true
                  ? candidate.profile!.summary
                  : 'Belum ada ringkasan profil.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  label: '${candidate.yearsOfExperience ?? 0} tahun pengalaman',
                ),
                if (candidate.resume != null)
                  _InfoChip(label: candidate.resume!.fileName),
                for (final skill
                    in candidate.profile?.skills.take(4) ?? const <String>[])
                  _InfoChip(label: skill),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyListState extends StatelessWidget {
  const _EmptyListState({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 32),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                onRetry();
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
