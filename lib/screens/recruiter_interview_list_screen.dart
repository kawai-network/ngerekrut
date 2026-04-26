library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/recruiter_job.dart';
import '../models/recruiter_shortlist.dart';
import '../repositories/interview_guide_artifact_repository.dart';
import '../repositories/job_posting_repository.dart';
import '../repositories/scorecard_artifact_repository.dart';
import '../repositories/shortlist_artifact_repository.dart';
import '../super_cupertino_navigation_bar/super_cupertino_navigation_bar.dart';

class RecruiterInterviewListScreen extends StatefulWidget {
  const RecruiterInterviewListScreen({
    super.key,
    required this.jobPostRepository,
    required this.shortlistRepository,
    required this.scorecardRepository,
    required this.interviewGuideRepository,
  });

  final JobPostingRepository jobPostRepository;
  final ShortlistArtifactRepository shortlistRepository;
  final ScorecardArtifactRepository scorecardRepository;
  final InterviewGuideArtifactRepository interviewGuideRepository;

  @override
  State<RecruiterInterviewListScreen> createState() =>
      _RecruiterInterviewListScreenState();
}

class _RecruiterInterviewListScreenState
    extends State<RecruiterInterviewListScreen> {
  bool _isLoading = true;
  String _selectedFilter = 'all';
  String _searchQuery = '';
  List<_InterviewItem> _items = const [];
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
    final items = <_InterviewItem>[];

    for (final job in jobs) {
      final shortlist = await widget.shortlistRepository.getLatestForJob(
        job.id,
      );
      final scorecards = await widget.scorecardRepository.listForJob(job.id);
      final guides = await widget.interviewGuideRepository.listForJob(job.id);

      final topCandidates =
          shortlist?.topCandidates ?? const <RecruiterShortlistEntry>[];
      if (topCandidates.isEmpty && scorecards.isEmpty && guides.isEmpty) {
        continue;
      }

      final guideCountByCandidate = <String, int>{};
      for (final guide in guides) {
        guideCountByCandidate.update(
          guide.candidateId,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }

      final scorecardCountByCandidate = <String, int>{};
      for (final scorecard in scorecards) {
        scorecardCountByCandidate.update(
          scorecard.candidateId,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }

      final candidates = <_InterviewCandidateItem>[];
      final seenCandidateIds = <String>{};

      for (final candidate in topCandidates) {
        seenCandidateIds.add(candidate.candidateId);
        candidates.add(
          _InterviewCandidateItem(
            candidateId: candidate.candidateId,
            candidateName: candidate.candidateName,
            rank: candidate.rank,
            score: candidate.totalScore,
            recommendation: candidate.recommendation,
            guideCount: guideCountByCandidate[candidate.candidateId] ?? 0,
            scorecardCount:
                scorecardCountByCandidate[candidate.candidateId] ?? 0,
            needsPreparation:
                (guideCountByCandidate[candidate.candidateId] ?? 0) == 0 ||
                (scorecardCountByCandidate[candidate.candidateId] ?? 0) == 0,
          ),
        );
      }

      for (final guide in guides) {
        if (seenCandidateIds.add(guide.candidateId)) {
          candidates.add(
            _InterviewCandidateItem(
              candidateId: guide.candidateId,
              candidateName: guide.candidateName,
              rank: null,
              score: null,
              recommendation: 'Panduan tersedia',
              guideCount: guideCountByCandidate[guide.candidateId] ?? 0,
              scorecardCount: scorecardCountByCandidate[guide.candidateId] ?? 0,
              needsPreparation:
                  (scorecardCountByCandidate[guide.candidateId] ?? 0) == 0,
            ),
          );
        }
      }

      for (final scorecard in scorecards) {
        if (seenCandidateIds.add(scorecard.candidateId)) {
          candidates.add(
            _InterviewCandidateItem(
              candidateId: scorecard.candidateId,
              candidateName: scorecard.candidateName,
              rank: null,
              score: scorecard.scorecard.weightedScore,
              recommendation: 'Penilaian tersedia',
              guideCount: guideCountByCandidate[scorecard.candidateId] ?? 0,
              scorecardCount:
                  scorecardCountByCandidate[scorecard.candidateId] ?? 0,
              needsPreparation:
                  (guideCountByCandidate[scorecard.candidateId] ?? 0) == 0,
            ),
          );
        }
      }

      candidates.sort((a, b) {
        final prepCompare = b.needsPreparation == a.needsPreparation
            ? 0
            : (b.needsPreparation ? 1 : -1);
        if (prepCompare != 0) return prepCompare;
        final rankA = a.rank ?? 999;
        final rankB = b.rank ?? 999;
        return rankA.compareTo(rankB);
      });

      items.add(
        _InterviewItem(
          job: job,
          shortlist: shortlist,
          candidateCount: candidates.length,
          guideCount: guides.length,
          scorecardCount: scorecards.length,
          candidates: candidates,
        ),
      );
    }

    items.sort((a, b) {
      final aUrgency = a.needsPreparationCount + a.readyCount;
      final bUrgency = b.needsPreparationCount + b.readyCount;
      return bUrgency.compareTo(aUrgency);
    });

    if (!mounted) return;
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  List<_InterviewItem> get _filteredItems {
    final baseItems = switch (_selectedFilter) {
      'prep' => _items.where((item) => item.needsPreparationCount > 0),
      'ready' => _items.where((item) => item.readyCount > 0),
      _ => _items,
    };

    if (_searchQuery.trim().isEmpty) {
      return baseItems.toList();
    }

    final query = _searchQuery.toLowerCase();
    return baseItems.where((item) {
      final haystack = [
        item.job.title,
        item.job.unitLabel,
        item.job.location,
        item.job.status,
        item.shortlist?.summary,
        ...item.candidates.map((candidate) => candidate.candidateName),
        ...item.candidates.map((candidate) => candidate.recommendation),
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
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
            'Interview',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  CupertinoIcons.recordingtape,
                  color: Color(0xFF0F172A),
                  size: 22,
                ),
              ),
            ],
          ),
          searchBar: SuperSearchBar(
            searchController: _searchController,
            searchFocusNode: _searchFocusNode,
            backgroundColor: Colors.white,
            resultColor: const Color(0xFFF8FAFC),
            placeholderText: 'Cari kandidat, lowongan, atau status interview',
            scrollBehavior: SearchBarScrollBehavior.pinned,
            resultBehavior: SearchBarResultBehavior.neverVisible,
            onChanged: (value) => setState(() => _searchQuery = value),
            onSubmitted: (value) => setState(() => _searchQuery = value),
          ),
          largeTitle: SuperLargeTitle(
            largeTitle: 'Interview',
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
            child: _InterviewFilterBar(
              selectedFilter: _selectedFilter,
              allCount: _items.length,
              prepCount: _items
                  .where((item) => item.needsPreparationCount > 0)
                  .length,
              readyCount: _items.where((item) => item.readyCount > 0).length,
              onSelected: (value) => setState(() => _selectedFilter = value),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_items.isEmpty)
                const _EmptyState(
                  title: 'Belum ada kandidat siap interview',
                  description:
                      'Buat panduan interview atau penilaian dari hasil kandidat unggulan agar operasional interview muncul di sini.',
                )
              else ...[
                Text(
                  'Lowongan aktif di interview',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Setiap kartu menunjukkan kandidat unggulan, kelengkapan panduan, dan status penilaian.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                if (_filteredItems.isEmpty)
                  const _EmptyState(
                    title: 'Tidak ada interview untuk filter ini',
                    description:
                        'Ubah filter atau kata kunci untuk melihat lowongan interview lain.',
                  )
                else
                  ..._filteredItems.map(
                    (item) => _InterviewJobCard(item: item),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InterviewFilterBar extends StatelessWidget {
  const _InterviewFilterBar({
    required this.selectedFilter,
    required this.allCount,
    required this.prepCount,
    required this.readyCount,
    required this.onSelected,
  });

  final String selectedFilter;
  final int allCount;
  final int prepCount;
  final int readyCount;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _InterviewFilterPill(
          label: 'Semua',
          count: allCount,
          selected: selectedFilter == 'all',
          onTap: () => onSelected('all'),
        ),
        _InterviewFilterPill(
          label: 'Perlu prep',
          count: prepCount,
          selected: selectedFilter == 'prep',
          onTap: () => onSelected('prep'),
        ),
        _InterviewFilterPill(
          label: 'Siap',
          count: readyCount,
          selected: selectedFilter == 'ready',
          onTap: () => onSelected('ready'),
        ),
      ],
    );
  }
}

class _InterviewFilterPill extends StatelessWidget {
  const _InterviewFilterPill({
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

class _InterviewJobCard extends StatelessWidget {
  const _InterviewJobCard({required this.item});

  final _InterviewItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
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
                      item.job.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if ((item.job.unitLabel ?? '').isNotEmpty)
                          item.job.unitLabel!,
                        if ((item.job.location ?? '').isNotEmpty)
                          item.job.location!,
                        item.job.status,
                      ].join(' • '),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(
                label: item.needsPreparationCount > 0
                    ? 'Perlu persiapan'
                    : 'Siap interview',
                color: item.needsPreparationCount > 0
                    ? const Color(0xFFB45309)
                    : const Color(0xFF166534),
                backgroundColor: item.needsPreparationCount > 0
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFDCFCE7),
              ),
            ],
          ),
          if ((item.shortlist?.summary ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              item.shortlist!.summary,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: 'Kandidat ${item.candidateCount}'),
              _InfoChip(label: 'Panduan ${item.guideCount}'),
              _InfoChip(label: 'Penilaian ${item.scorecardCount}'),
              _InfoChip(label: 'Siap ${item.readyCount}'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Kandidat interview',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...item.candidates
              .take(3)
              .map((candidate) => _InterviewCandidateRow(candidate: candidate)),
        ],
      ),
    );
  }
}

class _InterviewCandidateRow extends StatelessWidget {
  const _InterviewCandidateRow({required this.candidate});

  final _InterviewCandidateItem candidate;

  @override
  Widget build(BuildContext context) {
    final accentColor = candidate.needsPreparation
        ? const Color(0xFFB45309)
        : const Color(0xFF166534);
    final accentBackground = candidate.needsPreparation
        ? const Color(0xFFFEF3C7)
        : const Color(0xFFDCFCE7);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: accentBackground,
                    child: Text(
                      _initials(candidate.candidateName),
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (candidate.rank != null)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          '#${candidate.rank}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.candidateName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      candidate.recommendation,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (candidate.score != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    candidate.score!.toStringAsFixed(0),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(
                label: candidate.guideCount > 0
                    ? 'Panduan siap'
                    : 'Panduan belum ada',
                color: candidate.guideCount > 0
                    ? const Color(0xFF166534)
                    : const Color(0xFFB45309),
                backgroundColor: candidate.guideCount > 0
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEF3C7),
              ),
              _StatusChip(
                label: candidate.scorecardCount > 0
                    ? 'Penilaian siap'
                    : 'Penilaian belum ada',
                color: candidate.scorecardCount > 0
                    ? const Color(0xFF166534)
                    : const Color(0xFFB45309),
                backgroundColor: candidate.scorecardCount > 0
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEF3C7),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.map((part) => part[0].toUpperCase()).join();
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.description});

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

class _InterviewItem {
  const _InterviewItem({
    required this.job,
    required this.shortlist,
    required this.candidateCount,
    required this.guideCount,
    required this.scorecardCount,
    required this.candidates,
  });

  final RecruiterJob job;
  final RecruiterShortlistResult? shortlist;
  final int candidateCount;
  final int guideCount;
  final int scorecardCount;
  final List<_InterviewCandidateItem> candidates;

  int get readyCount =>
      candidates.where((candidate) => !candidate.needsPreparation).length;

  int get needsPreparationCount =>
      candidates.where((candidate) => candidate.needsPreparation).length;
}

class _InterviewCandidateItem {
  const _InterviewCandidateItem({
    required this.candidateId,
    required this.candidateName,
    required this.rank,
    required this.score,
    required this.recommendation,
    required this.guideCount,
    required this.scorecardCount,
    required this.needsPreparation,
  });

  final String candidateId;
  final String candidateName;
  final int? rank;
  final double? score;
  final String recommendation;
  final int guideCount;
  final int scorecardCount;
  final bool needsPreparation;
}
