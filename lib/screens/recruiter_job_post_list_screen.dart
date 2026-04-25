library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/application_status.dart';
import '../models/candidate.dart';
import '../models/job_application.dart';
import '../models/recruiter_job.dart';
import '../models/recruiter_shortlist.dart';
import '../repositories/candidate_repository.dart';
import '../repositories/interview_guide_artifact_repository.dart';
import '../repositories/job_application_repository.dart';
import '../repositories/job_posting_repository.dart';
import '../repositories/scorecard_artifact_repository.dart';
import '../repositories/shortlist_artifact_repository.dart';
import '../super_cupertino_navigation_bar/super_cupertino_navigation_bar.dart';

class RecruiterJobPostListScreen extends StatefulWidget {
  const RecruiterJobPostListScreen({
    super.key,
    required this.jobPostRepository,
    required this.shortlistRepository,
    required this.scorecardRepository,
    required this.interviewGuideRepository,
    this.onCreateJobPosting,
    this.onActionSelected,
    this.onSeedMockData,
    this.enableSeedMockData = false,
    this.enableGemmaProof = false,
    this.enableLegacyChat = false,
    this.canImportCandidates = false,
  });

  final JobPostingRepository jobPostRepository;
  final ShortlistArtifactRepository shortlistRepository;
  final ScorecardArtifactRepository scorecardRepository;
  final InterviewGuideArtifactRepository interviewGuideRepository;
  final Future<void> Function()? onCreateJobPosting;
  final Future<void> Function(String action)? onActionSelected;
  final Future<void> Function()? onSeedMockData;
  final bool enableSeedMockData;
  final bool enableGemmaProof;
  final bool enableLegacyChat;
  final bool canImportCandidates;

  @override
  State<RecruiterJobPostListScreen> createState() =>
      _RecruiterJobPostListScreenState();
}

class _RecruiterJobPostListScreenState
    extends State<RecruiterJobPostListScreen> {
  final JobApplicationRepository _jobApplicationRepository =
      JobApplicationRepository();
  bool _isLoading = true;
  String? _updatingJobId;
  List<_LocalJobPostSummary> _items = const [];
  String _statusFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final jobs = await widget.jobPostRepository.getAll();
    final summaries = <_LocalJobPostSummary>[];

    for (final job in jobs) {
      final applications = await _jobApplicationRepository.getByJobId(job.id);
      final shortlist = await widget.shortlistRepository.getLatestForJob(
        job.id,
      );
      final scorecards = await widget.scorecardRepository.listForJob(job.id);
      final guides = await widget.interviewGuideRepository.listForJob(job.id);

      final reviewCount = shortlist == null
          ? 0
          : shortlist.rankedCandidates.length - shortlist.topCandidates.length;

      summaries.add(
        _LocalJobPostSummary(
          job: job,
          shortlist: shortlist,
          applicantCount: applications.length,
          candidateCount: shortlist?.rankedCandidates.length ?? 0,
          readyInterviewCount: shortlist?.topCandidates.length ?? 0,
          reviewCount: reviewCount < 0 ? 0 : reviewCount,
          scorecardCount: scorecards.length,
          guideCount: guides.length,
          latestScreeningSummary: shortlist?.summary,
        ),
      );
    }

    summaries.sort((a, b) {
      final aUrgency = a.reviewCount + a.readyInterviewCount;
      final bUrgency = b.reviewCount + b.readyInterviewCount;
      return bUrgency.compareTo(aUrgency);
    });

    if (!mounted) return;
    setState(() {
      _items = summaries;
      _isLoading = false;
    });
  }

  List<_LocalJobPostSummary> get _filteredItems {
    return _items.where((item) {
      if (_statusFilter != 'all') {
        final normalized = JobPostingRepository.normalizeStatus(
          item.job.status,
        );
        if (normalized != _statusFilter) return false;
      }

      if (_searchQuery.isEmpty) return true;
      final haystack = [
        item.job.title,
        item.job.unitLabel,
        item.job.location,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  int _countForStatus(String status) {
    if (status == 'all') return _items.length;
    return _items.where((item) {
      final normalized = JobPostingRepository.normalizeStatus(item.job.status);
      return normalized == status;
    }).length;
  }

  int get _activeJobsCount =>
      _countForStatus(JobPostingRepository.statusPublished);

  int get _draftJobsCount => _countForStatus(JobPostingRepository.statusDraft);

  int get _totalReviewCount =>
      _items.fold(0, (total, item) => total + item.reviewCount);

  Future<void> _handleCreateJobPosting() async {
    final callback = widget.onCreateJobPosting;
    if (callback == null) return;
    await callback();
    if (!mounted) return;
    await _load();
  }

  Future<void> _handleActionSelected(String action) async {
    final callback = widget.onActionSelected;
    if (callback == null) return;
    await callback(action);
    if (!mounted) return;
    await _load();
  }

  Future<void> _changeJobStatus(
    _LocalJobPostSummary item,
    String nextStatus,
  ) async {
    final currentStatus = JobPostingRepository.normalizeStatus(item.job.status);
    if (currentStatus == JobPostingRepository.normalizeStatus(nextStatus)) {
      return;
    }
    if (nextStatus == 'closed') {
      final applications = await _jobApplicationRepository.getByJobId(
        item.job.id,
      );
      final activeApplications = applications
          .where((application) => application.status.isActive)
          .length;
      final shouldContinue = await _confirmCloseJob(
        jobTitle: item.job.title,
        activeApplications: activeApplications,
      );
      if (shouldContinue != true) return;
    }

    setState(() => _updatingJobId = item.job.id);
    try {
      switch (nextStatus) {
        case 'published':
          await widget.jobPostRepository.publish(item.job.id);
          break;
        case 'closed':
          await widget.jobPostRepository.close(item.job.id);
          break;
        case 'draft':
          await widget.jobPostRepository.updateStatus(
            item.job.id,
            JobPostingRepository.statusDraft,
          );
          break;
        default:
          await widget.jobPostRepository.updateStatus(item.job.id, nextStatus);
      }
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status lowongan ${item.job.title} diperbarui ke ${_jobStatusLabel(nextStatus)}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status lowongan: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingJobId = null);
      }
    }
  }

  String _jobStatusLabel(String status) {
    switch (JobPostingRepository.normalizeStatus(status)) {
      case JobPostingRepository.statusPublished:
        return 'Aktif';
      case JobPostingRepository.statusClosed:
        return 'Ditutup';
      case JobPostingRepository.statusDraft:
        return 'Draft';
      default:
        return status;
    }
  }

  Future<bool?> _confirmCloseJob({
    required String jobTitle,
    required int activeApplications,
  }) async {
    if (activeApplications == 0) return true;
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tutup lowongan?'),
          content: Text(
            '$jobTitle masih punya $activeApplications kandidat aktif. Tutup lowongan hanya jika Anda yakin pipeline ini harus dihentikan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tutup Lowongan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: SuperScaffold(
        stretch: true,
        appBar: SuperAppBar(
          backgroundColor: const Color(0xFFF8FAFC),
          automaticallyImplyLeading: false,
          title: Text(
            'Lowongan',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                tooltip: 'Aksi',
                onSelected: (value) {
                  _handleActionSelected(value);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'job_posting',
                    child: Text('Buat Lowongan'),
                  ),
                  PopupMenuItem<String>(
                    value: 'candidate_screening',
                    enabled: widget.canImportCandidates,
                    child: const Text('Tarik Kandidat dari API'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'hiring_assistant',
                    child: Text('Template Hiring'),
                  ),
                  if (widget.enableGemmaProof)
                    const PopupMenuItem<String>(
                      value: 'gemma_proof',
                      child: Text('Cek Gemma Lokal'),
                    ),
                  if (widget.enableSeedMockData)
                    const PopupMenuItem<String>(
                      value: 'seed_mock_data',
                      child: Text('Seed Mock Data'),
                    ),
                  if (widget.enableLegacyChat)
                    const PopupMenuItem<String>(
                      value: 'legacy_chat',
                      child: Text('Buka Legacy Chat'),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'sign_out',
                    child: Text('Keluar'),
                  ),
                ],
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    CupertinoIcons.ellipsis_circle,
                    color: Color(0xFF0F172A),
                    size: 24,
                  ),
                ),
              ),
              if (widget.onCreateJobPosting != null)
                GestureDetector(
                  onTap: () {
                    _handleCreateJobPosting();
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF18CD5B),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      CupertinoIcons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              const SizedBox(width: 16),
            ],
          ),
          searchBar: SuperSearchBar(
            searchController: _searchController,
            searchFocusNode: _searchFocusNode,
            backgroundColor: Colors.white,
            resultColor: const Color(0xFFF8FAFC),
            placeholderText: 'Cari judul lowongan, divisi, atau lokasi',
            scrollBehavior: SearchBarScrollBehavior.pinned,
            resultBehavior: SearchBarResultBehavior.neverVisible,
            onChanged: (value) => setState(() => _searchQuery = value),
            onSubmitted: (value) => setState(() => _searchQuery = value),
          ),
          largeTitle: SuperLargeTitle(
            largeTitle: 'Lowongan',
            textStyle: TextStyle(
              inherit: false,
              fontFamily: '.SF Pro Display',
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.41,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          bottom: SuperAppBarBottom(
            enabled: true,
            height: 44,
            child: _FilterBar(
              statusFilter: _statusFilter,
              allCount: _countForStatus('all'),
              activeCount: _countForStatus(
                JobPostingRepository.statusPublished,
              ),
              draftCount: _countForStatus(JobPostingRepository.statusDraft),
              closedCount: _countForStatus('closed'),
              onSelected: (value) => setState(() => _statusFilter = value),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              if (_isLoading) ...[
                const LinearProgressIndicator(minHeight: 3),
                const SizedBox(height: 16),
              ],
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_filteredItems.isEmpty)
                _EmptyState(
                  title: _items.isEmpty
                      ? 'Belum ada lowongan'
                      : 'Tidak ada lowongan yang cocok',
                  description: _items.isEmpty
                      ? 'Buat lowongan baru agar pipeline kandidat bisa mulai berjalan.'
                      : 'Coba ubah kata kunci pencarian atau filter status.',
                  primaryActionLabel: _items.isEmpty ? 'Buat Lowongan' : null,
                  onPrimaryAction: _items.isEmpty
                      ? _handleCreateJobPosting
                      : null,
                  secondaryActionLabel:
                      _items.isEmpty && widget.enableSeedMockData
                      ? 'Gunakan Data Contoh'
                      : null,
                  onSecondaryAction:
                      _items.isEmpty && widget.onSeedMockData != null
                      ? () async {
                          await widget.onSeedMockData!();
                          await _load();
                        }
                      : null,
                )
              else ...[
                _OverviewHero(
                  activeJobs: _activeJobsCount,
                  draftJobs: _draftJobsCount,
                  reviewCount: _totalReviewCount,
                ),
                const SizedBox(height: 20),
                Text(
                  'Daftar lowongan',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Urutan lowongan disusun dari yang paling membutuhkan tindak lanjut.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                ..._filteredItems.map((item) => _buildJobCard(context, item)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, _LocalJobPostSummary item) {
    final job = item.job;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _LocalJobPostDetailScreen(
                item: item,
                jobPostRepository: widget.jobPostRepository,
              ),
            ),
          ).then((_) => _load());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                          job.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if ((job.unitLabel ?? '').isNotEmpty ||
                            (job.location ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            [
                              if ((job.unitLabel ?? '').isNotEmpty)
                                job.unitLabel!,
                              if ((job.location ?? '').isNotEmpty)
                                job.location!,
                            ].join(' • '),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey.shade700),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StatusChip(status: job.status),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        enabled: _updatingJobId != job.id,
                        tooltip: 'Kelola status lowongan',
                        onSelected: (status) => _changeJobStatus(item, status),
                        itemBuilder: (context) {
                          final actions = <PopupMenuEntry<String>>[];
                          final normalized =
                              JobPostingRepository.normalizeStatus(job.status);
                          if (normalized !=
                              JobPostingRepository.statusPublished) {
                            actions.add(
                              const PopupMenuItem<String>(
                                value: 'published',
                                child: Text('Publish lowongan'),
                              ),
                            );
                          }
                          if (normalized != JobPostingRepository.statusDraft) {
                            actions.add(
                              const PopupMenuItem<String>(
                                value: 'draft',
                                child: Text('Pindah ke draft'),
                              ),
                            );
                          }
                          if (normalized != JobPostingRepository.statusClosed) {
                            actions.add(
                              const PopupMenuItem<String>(
                                value: 'closed',
                                child: Text('Tutup lowongan'),
                              ),
                            );
                          }
                          return actions;
                        },
                        icon: _updatingJobId == job.id
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.more_horiz),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _ListMetaItem(
                    icon: Icons.people_alt_outlined,
                    label: 'Pelamar ${item.applicantCount}',
                  ),
                  _ListMetaItem(
                    icon: Icons.fact_check_outlined,
                    label: 'Review ${item.reviewCount}',
                  ),
                  _ListMetaItem(
                    icon: Icons.record_voice_over_outlined,
                    label: 'Interview ${item.readyInterviewCount}',
                  ),
                ],
              ),
              if ((item.latestScreeningSummary ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  item.latestScreeningSummary!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewHero extends StatelessWidget {
  const _OverviewHero({
    required this.activeJobs,
    required this.draftJobs,
    required this.reviewCount,
  });

  final int activeJobs;
  final int draftJobs;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF0FDF4)],
        ),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prioritas lowongan hari ini',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Pantau posisi aktif, draft yang belum dipublikasikan, dan kandidat yang masih menunggu review.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF475569)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Aktif',
                  value: '$activeJobs',
                  color: const Color(0xFF166534),
                  background: const Color(0xFFDCFCE7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'Draft',
                  value: '$draftJobs',
                  color: const Color(0xFF9A3412),
                  background: const Color(0xFFFFEDD5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'Review',
                  value: '$reviewCount',
                  color: const Color(0xFF1D4ED8),
                  background: const Color(0xFFDBEAFE),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  final String label;
  final String value;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.statusFilter,
    required this.allCount,
    required this.activeCount,
    required this.draftCount,
    required this.closedCount,
    required this.onSelected,
  });

  final String statusFilter;
  final int allCount;
  final int activeCount;
  final int draftCount;
  final int closedCount;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _FilterPill(
          label: 'Semua',
          count: allCount,
          selected: statusFilter == 'all',
          onTap: () => onSelected('all'),
        ),
        _FilterPill(
          label: 'Aktif',
          count: activeCount,
          selected: statusFilter == JobPostingRepository.statusPublished,
          onTap: () => onSelected(JobPostingRepository.statusPublished),
        ),
        _FilterPill(
          label: 'Draft',
          count: draftCount,
          selected: statusFilter == 'draft',
          onTap: () => onSelected('draft'),
        ),
        _FilterPill(
          label: 'Ditutup',
          count: closedCount,
          selected: statusFilter == 'closed',
          onTap: () => onSelected('closed'),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFDCFCE7) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? const Color(0xFF86EFAC)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            '$label ($count)',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected
                  ? const Color(0xFF166534)
                  : const Color(0xFF0F172A),
            ),
          ),
        ),
      ),
    );
  }
}

class _ListMetaItem extends StatelessWidget {
  const _ListMetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = JobPostingRepository.normalizeStatus(status);
    final config = switch (normalized) {
      JobPostingRepository.statusPublished => (
        background: const Color(0xFFDCFCE7),
        foreground: const Color(0xFF166534),
        icon: Icons.radio_button_checked,
        label: 'Aktif',
      ),
      JobPostingRepository.statusDraft => (
        background: const Color(0xFFFEF3C7),
        foreground: const Color(0xFFB45309),
        icon: Icons.edit_note,
        label: 'Draft',
      ),
      JobPostingRepository.statusClosed => (
        background: const Color(0xFFF3F4F6),
        foreground: const Color(0xFF4B5563),
        icon: Icons.lock_outline,
        label: 'Ditutup',
      ),
      _ => (
        background: const Color(0xFFE2E8F0),
        foreground: const Color(0xFF334155),
        icon: Icons.info_outline,
        label: status,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.foreground),
          const SizedBox(width: 6),
          Text(
            config.label,
            style: TextStyle(
              color: config.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.description,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final String description;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final Future<void> Function()? onSecondaryAction;

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
          if (primaryActionLabel != null || secondaryActionLabel != null) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (primaryActionLabel != null)
                  FilledButton.icon(
                    onPressed: onPrimaryAction,
                    icon: const Icon(Icons.add),
                    label: Text(primaryActionLabel!),
                  ),
                if (secondaryActionLabel != null)
                  OutlinedButton.icon(
                    onPressed: onSecondaryAction == null
                        ? null
                        : () async {
                            await onSecondaryAction!();
                          },
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(secondaryActionLabel!),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LocalJobPostDetailScreen extends StatefulWidget {
  const _LocalJobPostDetailScreen({
    required this.item,
    required this.jobPostRepository,
  });

  final _LocalJobPostSummary item;
  final JobPostingRepository jobPostRepository;

  @override
  State<_LocalJobPostDetailScreen> createState() =>
      _LocalJobPostDetailScreenState();
}

class _LocalJobPostDetailScreenState extends State<_LocalJobPostDetailScreen> {
  final CandidateRepository _candidateRepository = CandidateRepository();
  final JobApplicationRepository _jobApplicationRepository =
      JobApplicationRepository();
  late RecruiterJob _job = widget.item.job;
  bool _isLoadingApplications = true;
  bool _isUpdatingJobStatus = false;
  String? _updatingApplicationId;
  List<JobApplication> _applications = const [];
  Map<String, RecruiterCandidate> _candidatesById = const {};

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    try {
      final applications = await _jobApplicationRepository.getByJobId(
        widget.item.job.id,
      );
      final candidateIds = applications
          .map((application) => application.candidateId)
          .whereType<String>()
          .toSet()
          .toList();
      final candidates = await Future.wait(
        candidateIds.map(_candidateRepository.getById),
      );
      final candidatesById = <String, RecruiterCandidate>{
        for (final candidate in candidates.whereType<RecruiterCandidate>())
          candidate.id: candidate,
      };
      if (!mounted) return;
      setState(() {
        _applications = applications;
        _candidatesById = candidatesById;
        _isLoadingApplications = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingApplications = false);
    }
  }

  Future<void> _changeJobStatus(String nextStatus) async {
    final currentStatus = JobPostingRepository.normalizeStatus(_job.status);
    if (currentStatus == JobPostingRepository.normalizeStatus(nextStatus)) {
      return;
    }
    if (nextStatus == 'closed') {
      final activeApplications = _applications
          .where((application) => application.status.isActive)
          .length;
      final shouldContinue = await _confirmCloseJob(
        jobTitle: _job.title,
        activeApplications: activeApplications,
      );
      if (shouldContinue != true) return;
    }

    setState(() => _isUpdatingJobStatus = true);
    try {
      switch (nextStatus) {
        case 'published':
          await widget.jobPostRepository.publish(_job.id);
          break;
        case 'closed':
          await widget.jobPostRepository.close(_job.id);
          break;
        case 'draft':
          await widget.jobPostRepository.updateStatus(
            _job.id,
            JobPostingRepository.statusDraft,
          );
          break;
        default:
          await widget.jobPostRepository.updateStatus(_job.id, nextStatus);
      }
      final updatedJob =
          await widget.jobPostRepository.getById(_job.id) ??
          await widget.jobPostRepository.getByJobId(_job.id);
      if (!mounted) return;
      setState(() {
        _job = updatedJob ?? _job;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status lowongan diperbarui ke ${_jobStatusLabel(nextStatus)}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status lowongan: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingJobStatus = false);
      }
    }
  }

  String _jobStatusLabel(String status) {
    switch (JobPostingRepository.normalizeStatus(status)) {
      case JobPostingRepository.statusPublished:
        return 'Aktif';
      case JobPostingRepository.statusClosed:
        return 'Ditutup';
      case JobPostingRepository.statusDraft:
        return 'Draft';
      default:
        return status;
    }
  }

  Future<bool?> _confirmCloseJob({
    required String jobTitle,
    required int activeApplications,
  }) async {
    if (activeApplications == 0) return true;
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tutup lowongan?'),
          content: Text(
            '$jobTitle masih punya $activeApplications kandidat aktif. Tutup lowongan hanya jika Anda yakin pipeline ini harus dihentikan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tutup Lowongan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateApplicationStatus(
    JobApplication application,
    ApplicationStatus nextStatus,
  ) async {
    String? rejectionReason;
    if (nextStatus == ApplicationStatus.rejected) {
      rejectionReason = await _askRejectionReason();
      if (rejectionReason == null) return;
    }

    setState(() => _updatingApplicationId = application.id);
    try {
      await _jobApplicationRepository.updateStatus(
        application.id,
        nextStatus,
        rejectionReason: rejectionReason,
      );
      await _loadApplications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status lamaran ${application.candidateId ?? application.id} diperbarui ke ${nextStatus.displayName}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memperbarui status: $e')));
    } finally {
      if (mounted) {
        setState(() => _updatingApplicationId = null);
      }
    }
  }

  Future<String?> _askRejectionReason() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Alasan penolakan'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Tulis alasan singkat untuk kandidat',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (reason == null) return null;
    return reason.isEmpty ? 'Tidak melanjutkan ke tahap berikutnya.' : reason;
  }

  Future<void> _saveRecruiterNotes(JobApplication application) async {
    final controller = TextEditingController(text: application.recruiterNotes);
    final notes = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Recruiter Notes'),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Tulis catatan internal untuk lamaran ini',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (notes == null) return;

    setState(() => _updatingApplicationId = application.id);
    try {
      await _jobApplicationRepository.updateRecruiterNotes(
        application.id,
        notes,
      );
      await _loadApplications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recruiter notes diperbarui.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan notes: $e')));
    } finally {
      if (mounted) {
        setState(() => _updatingApplicationId = null);
      }
    }
  }

  Future<void> _setInternalRating(JobApplication application) async {
    final rating = await showDialog<int>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Internal Rating'),
          children: List.generate(5, (index) {
            final value = index + 1;
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, value),
              child: Row(
                children: [
                  Text('$value'),
                  const SizedBox(width: 12),
                  ...List.generate(
                    value,
                    (_) => const Icon(
                      Icons.star,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
    if (rating == null) return;

    setState(() => _updatingApplicationId = application.id);
    try {
      await _jobApplicationRepository.setInternalRating(application.id, rating);
      await _loadApplications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rating internal diset ke $rating.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan rating: $e')));
    } finally {
      if (mounted) {
        setState(() => _updatingApplicationId = null);
      }
    }
  }

  Future<void> _addInterviewSchedule(JobApplication application) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null || !mounted) return;

    final schedule = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final details = await _askInterviewDetails(application);
    if (details == null || !mounted) return;

    setState(() => _updatingApplicationId = application.id);
    try {
      await _jobApplicationRepository.addInterviewDate(
        application.id,
        schedule,
      );
      await _jobApplicationRepository.updateInterviewDetails(
        application.id,
        durationMinutes: details.durationMinutes,
        notes: details.notes,
      );
      if (application.status != ApplicationStatus.interview) {
        await _jobApplicationRepository.updateStatus(
          application.id,
          ApplicationStatus.interview,
        );
      }
      await _loadApplications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal interview ditambahkan.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambah jadwal interview: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingApplicationId = null);
      }
    }
  }

  Future<void> _rescheduleInterview(JobApplication application) async {
    final current = application.interviewDates?.isNotEmpty == true
        ? application.interviewDates!.last
        : null;
    if (current == null) {
      await _addInterviewSchedule(application);
      return;
    }

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: current.isAfter(DateTime.now()) ? current : DateTime.now(),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (time == null || !mounted) return;

    final nextSchedule = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final details = await _askInterviewDetails(application);
    if (details == null || !mounted) return;

    setState(() => _updatingApplicationId = application.id);
    try {
      await _jobApplicationRepository.rescheduleLatestInterviewDate(
        application.id,
        nextSchedule,
      );
      await _jobApplicationRepository.updateInterviewDetails(
        application.id,
        durationMinutes: details.durationMinutes,
        notes: details.notes,
      );
      await _loadApplications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal interview berhasil diubah.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah jadwal interview: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingApplicationId = null);
      }
    }
  }

  Future<void> _cancelInterview(JobApplication application) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Batalkan interview?'),
          content: const Text(
            'Jadwal, link meeting, dan detail interview akan dihapus dari lamaran ini.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Batalkan Interview'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    setState(() => _updatingApplicationId = application.id);
    try {
      await _jobApplicationRepository.clearInterviewSchedule(application.id);
      if (application.status == ApplicationStatus.interview) {
        await _jobApplicationRepository.updateStatus(
          application.id,
          ApplicationStatus.screening,
        );
      }
      await _loadApplications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Interview dibatalkan dari lamaran ini.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membatalkan interview: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingApplicationId = null);
      }
    }
  }

  Future<void> _openMeetingLink(JobApplication application) async {
    final meetingUrl = application.meetingUrl;
    if (meetingUrl == null || meetingUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link meeting belum tersedia.')),
      );
      return;
    }

    final uri = Uri.tryParse(meetingUrl);
    if (uri == null || !await canLaunchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link meeting tidak valid.')),
      );
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<_InterviewDetailsDraft?> _askInterviewDetails(
    JobApplication application,
  ) async {
    final durationController = TextEditingController(
      text: '${application.interviewDurationMinutes ?? 60}',
    );
    final notesController = TextEditingController(
      text: application.interviewNotes ?? '',
    );

    final result = await showDialog<_InterviewDetailsDraft>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Detail interview'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Durasi (menit)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Catatan interview',
                  hintText: 'Agenda, persiapan, atau instruksi singkat',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final parsedDuration =
                    int.tryParse(durationController.text.trim()) ?? 60;
                Navigator.pop(
                  context,
                  _InterviewDetailsDraft(
                    durationMinutes: parsedDuration <= 0 ? 60 : parsedDuration,
                    notes: notesController.text.trim(),
                  ),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    durationController.dispose();
    notesController.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final job = _job;

    return Scaffold(
      appBar: AppBar(
        title: Text(job.title),
        actions: [
          PopupMenuButton<String>(
            enabled: !_isUpdatingJobStatus,
            onSelected: _changeJobStatus,
            itemBuilder: (context) {
              final actions = <PopupMenuEntry<String>>[];
              final normalized = JobPostingRepository.normalizeStatus(
                job.status,
              );
              if (normalized != JobPostingRepository.statusPublished) {
                actions.add(
                  const PopupMenuItem<String>(
                    value: 'published',
                    child: Text('Publish lowongan'),
                  ),
                );
              }
              if (normalized != JobPostingRepository.statusDraft) {
                actions.add(
                  const PopupMenuItem<String>(
                    value: 'draft',
                    child: Text('Pindah ke draft'),
                  ),
                );
              }
              if (normalized != JobPostingRepository.statusClosed) {
                actions.add(
                  const PopupMenuItem<String>(
                    value: 'closed',
                    child: Text('Tutup lowongan'),
                  ),
                );
              }
              return actions;
            },
            icon: _isUpdatingJobStatus
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.more_horiz),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            job.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
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
          const SizedBox(height: 20),
          _DetailSection(
            title: 'Ringkasan lowongan',
            child: Text(
              job.description ?? 'Belum ada deskripsi lowongan.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          _DetailSection(
            title: 'Status pipeline',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ArtifactCard(
                  label: 'Pelamar',
                  value: '${item.applicantCount}',
                ),
                _ArtifactCard(
                  label: 'Shortlist',
                  value: '${item.candidateCount}',
                ),
                _ArtifactCard(
                  label: 'Perlu review',
                  value: '${item.reviewCount}',
                ),
                _ArtifactCard(
                  label: 'Siap interview',
                  value: '${item.readyInterviewCount}',
                ),
                _ArtifactCard(
                  label: 'Scorecard',
                  value: '${item.scorecardCount}',
                ),
                _ArtifactCard(label: 'Guide', value: '${item.guideCount}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DetailSection(
            title: 'Lamaran masuk',
            child: _isLoadingApplications
                ? const Center(child: CircularProgressIndicator())
                : _applications.isEmpty
                ? const Text('Belum ada lamaran untuk lowongan ini.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _applications.map((application) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ApplicationPreviewCard(
                          application: application,
                          candidate: application.candidateId != null
                              ? _candidatesById[application.candidateId!]
                              : null,
                          isUpdating: _updatingApplicationId == application.id,
                          onStatusSelected: (status) =>
                              _updateApplicationStatus(application, status),
                          onEditNotes: () => _saveRecruiterNotes(application),
                          onSetRating: () => _setInternalRating(application),
                          onAddInterviewDate: () =>
                              _addInterviewSchedule(application),
                          onRescheduleInterview: () =>
                              _rescheduleInterview(application),
                          onCancelInterview: () =>
                              _cancelInterview(application),
                          onOpenMeeting: () => _openMeetingLink(application),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),
          _DetailSection(
            title: 'Kualifikasi',
            child: job.requirements.isEmpty
                ? const Text('Belum ada kualifikasi tersimpan.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: job.requirements
                        .map(
                          (requirement) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('• $requirement'),
                          ),
                        )
                        .toList(),
                  ),
          ),
          if (item.shortlist?.rankedCandidates.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            _DetailSection(
              title: 'Kandidat prioritas',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.shortlist!.rankedCandidates.take(3).map((
                  candidate,
                ) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '#${candidate.rank}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                candidate.candidateName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(candidate.totalScore.toStringAsFixed(0)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(candidate.rationale),
                        if (candidate.strengths.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Kekuatan utama: ${candidate.strengths.join(', ')}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade700),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          if ((item.latestScreeningSummary ?? '').isNotEmpty) ...[
            const SizedBox(height: 16),
            _DetailSection(
              title: 'Catatan screening terakhir',
              child: Text(
                item.latestScreeningSummary!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ArtifactCard extends StatelessWidget {
  const _ArtifactCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ApplicationPreviewCard extends StatelessWidget {
  const _ApplicationPreviewCard({
    required this.application,
    required this.candidate,
    required this.isUpdating,
    required this.onStatusSelected,
    required this.onEditNotes,
    required this.onSetRating,
    required this.onAddInterviewDate,
    required this.onRescheduleInterview,
    required this.onCancelInterview,
    required this.onOpenMeeting,
  });

  final JobApplication application;
  final RecruiterCandidate? candidate;
  final bool isUpdating;
  final ValueChanged<ApplicationStatus> onStatusSelected;
  final VoidCallback onEditNotes;
  final VoidCallback onSetRating;
  final VoidCallback onAddInterviewDate;
  final VoidCallback onRescheduleInterview;
  final VoidCallback onCancelInterview;
  final VoidCallback onOpenMeeting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final candidateName =
        candidate?.name ?? application.candidateId ?? 'Kandidat tanpa ID';
    final candidateMeta = [
      if ((candidate?.headline ?? '').isNotEmpty) candidate!.headline!,
      if (candidate?.yearsOfExperience != null)
        '${candidate!.yearsOfExperience} tahun pengalaman',
    ].join(' • ');
    final topSkills = candidate?.profile?.skills.take(3).toList() ?? const [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  candidateName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ApplicationStatusPill(status: application.status),
              const SizedBox(width: 8),
              PopupMenuButton<ApplicationStatus>(
                enabled: !isUpdating,
                tooltip: 'Ubah status lamaran',
                onSelected: onStatusSelected,
                itemBuilder: (context) {
                  return ApplicationStatus.values
                      .where((status) => status != application.status)
                      .map((status) {
                        return PopupMenuItem<ApplicationStatus>(
                          value: status,
                          child: Text(status.displayName),
                        );
                      })
                      .toList();
                },
                icon: isUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.more_horiz),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Dilamar ${_formatDate(application.appliedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          if (candidateMeta.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              candidateMeta,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (topSkills.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: topSkills
                  .map(
                    (skill) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        skill,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if ((application.expectedSalary ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Ekspektasi gaji: ${application.expectedSalary!}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if (application.internalRating != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Rating internal: '),
                ...List.generate(
                  application.internalRating!,
                  (_) => const Icon(
                    Icons.star,
                    size: 16,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ],
          if ((application.recruiterNotes ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Notes: ${application.recruiterNotes!}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ],
          if (application.interviewDates?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              'Interview berikutnya: ${_formatScheduleDate(application.interviewDates!.last)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF4338CA),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if ((application.interviewDurationMinutes ?? 0) > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Durasi interview: ${application.interviewDurationMinutes} menit',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ],
          if (application.isSyncedToCalendar) ...[
            const SizedBox(height: 8),
            Text(
              'Google Calendar tersinkron',
              style: TextStyle(
                color: Color(0xFF166534),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if ((application.meetingUrl ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Google Meet siap digunakan',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF4338CA),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if ((application.coverLetter ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              application.coverLetter!,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
          if ((application.interviewNotes ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Catatan interview: ${application.interviewNotes!}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF475569),
                height: 1.45,
              ),
            ),
          ],
          if (application.candidateId != null && candidate == null) ...[
            const SizedBox(height: 8),
            Text(
              'ID kandidat: ${application.candidateId!}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: isUpdating ? null : onEditNotes,
                icon: const Icon(Icons.note_alt_outlined),
                label: const Text('Notes'),
              ),
              OutlinedButton.icon(
                onPressed: isUpdating ? null : onSetRating,
                icon: const Icon(Icons.star_outline),
                label: const Text('Rating'),
              ),
              OutlinedButton.icon(
                onPressed: isUpdating ? null : onAddInterviewDate,
                icon: const Icon(Icons.event_available),
                label: const Text('Jadwal'),
              ),
              if (application.interviewDates?.isNotEmpty == true)
                OutlinedButton.icon(
                  onPressed: isUpdating ? null : onRescheduleInterview,
                  icon: const Icon(Icons.edit_calendar_outlined),
                  label: const Text('Reschedule'),
                ),
              if (application.interviewDates?.isNotEmpty == true)
                OutlinedButton.icon(
                  onPressed: isUpdating ? null : onCancelInterview,
                  icon: const Icon(Icons.event_busy_outlined),
                  label: const Text('Batalkan'),
                ),
              if ((application.meetingUrl ?? '').isNotEmpty)
                OutlinedButton.icon(
                  onPressed: isUpdating ? null : onOpenMeeting,
                  icon: const Icon(Icons.video_camera_front_outlined),
                  label: const Text('Buka Meet'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) return 'hari ini';
    if (difference.inDays == 1) return 'kemarin';
    if (difference.inDays < 7) return '${difference.inDays} hari lalu';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatScheduleDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(date.year, date.month, date.day);
    final dayDifference = targetDay.difference(today).inDays;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final timeLabel = '$hour:$minute';

    if (dayDifference == 0) return 'hari ini • $timeLabel';
    if (dayDifference == 1) return 'besok • $timeLabel';
    if (dayDifference > 1 && dayDifference < 7) {
      return '$dayDifference hari lagi • $timeLabel';
    }

    return '${date.day}/${date.month}/${date.year} • $timeLabel';
  }
}

class _ApplicationStatusPill extends StatelessWidget {
  const _ApplicationStatusPill({required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final background = switch (status) {
      ApplicationStatus.applied => const Color(0xFFDBEAFE),
      ApplicationStatus.screening => const Color(0xFFFEF3C7),
      ApplicationStatus.interview => const Color(0xFFE0E7FF),
      ApplicationStatus.underReview => const Color(0xFFF3E8FF),
      ApplicationStatus.offered => const Color(0xFFDCFCE7),
      ApplicationStatus.rejected ||
      ApplicationStatus.withdrawn ||
      ApplicationStatus.archived => const Color(0xFFF3F4F6),
    };
    final foreground = switch (status) {
      ApplicationStatus.applied => const Color(0xFF1D4ED8),
      ApplicationStatus.screening => const Color(0xFFB45309),
      ApplicationStatus.interview => const Color(0xFF4338CA),
      ApplicationStatus.underReview => const Color(0xFF6D28D9),
      ApplicationStatus.offered => const Color(0xFF166534),
      ApplicationStatus.rejected ||
      ApplicationStatus.withdrawn ||
      ApplicationStatus.archived => const Color(0xFF4B5563),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _LocalJobPostSummary {
  const _LocalJobPostSummary({
    required this.job,
    required this.shortlist,
    required this.applicantCount,
    required this.candidateCount,
    required this.readyInterviewCount,
    required this.reviewCount,
    required this.scorecardCount,
    required this.guideCount,
    this.latestScreeningSummary,
  });

  final RecruiterJob job;
  final RecruiterShortlistResult? shortlist;
  final int applicantCount;
  final int candidateCount;
  final int readyInterviewCount;
  final int reviewCount;
  final int scorecardCount;
  final int guideCount;
  final String? latestScreeningSummary;

  bool get isActive {
    final normalized = job.status.toLowerCase();
    return normalized == JobPostingRepository.statusPublished;
  }
}

class _InterviewDetailsDraft {
  const _InterviewDetailsDraft({
    required this.durationMinutes,
    required this.notes,
  });

  final int durationMinutes;
  final String notes;
}
