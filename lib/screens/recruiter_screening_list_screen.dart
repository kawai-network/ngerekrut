library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/recruiter_job.dart';
import '../models/recruiter_shortlist.dart';
import '../repositories/job_posting_repository.dart';
import '../repositories/shortlist_artifact_repository.dart';
import '../super_cupertino_navigation_bar/super_cupertino_navigation_bar.dart';

class RecruiterScreeningListScreen extends StatefulWidget {
  const RecruiterScreeningListScreen({
    super.key,
    required this.jobPostRepository,
    required this.shortlistRepository,
  });

  final JobPostingRepository jobPostRepository;
  final ShortlistArtifactRepository shortlistRepository;

  @override
  State<RecruiterScreeningListScreen> createState() =>
      _RecruiterScreeningListScreenState();
}

class _RecruiterScreeningListScreenState
    extends State<RecruiterScreeningListScreen> {
  bool _isLoading = true;
  String _selectedFilter = 'all';
  String _searchQuery = '';
  List<_ScreeningItem> _items = const [];
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
    final items = <_ScreeningItem>[];

    for (final job in jobs) {
      final shortlist = await widget.shortlistRepository.getLatestForJob(
        job.id,
      );
      if (shortlist != null) {
        items.add(_ScreeningItem(job: job, shortlist: shortlist));
      }
    }

    items.sort((a, b) {
      final aUrgency =
          _decisionCount(a.shortlist) + a.shortlist.topCandidates.length;
      final bUrgency =
          _decisionCount(b.shortlist) + b.shortlist.topCandidates.length;
      return bUrgency.compareTo(aUrgency);
    });

    if (!mounted) return;
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  int _decisionCount(RecruiterShortlistResult shortlist) {
    final pending =
        shortlist.rankedCandidates.length - shortlist.topCandidates.length;
    return pending < 0 ? 0 : pending;
  }

  List<_CandidateDecisionItem> get _candidateItems {
    final items = <_CandidateDecisionItem>[];

    for (final item in _items) {
      for (final candidate in item.shortlist.rankedCandidates) {
        final isTopCandidate = item.shortlist.topCandidates.any(
          (entry) => entry.candidateId == candidate.candidateId,
        );
        items.add(
          _CandidateDecisionItem(
            job: item.job,
            candidate: candidate,
            isTopCandidate: isTopCandidate,
          ),
        );
      }
    }

    items.sort((a, b) {
      final urgencyCompare = b.needsAttention == a.needsAttention
          ? 0
          : (b.needsAttention ? 1 : -1);
      if (urgencyCompare != 0) return urgencyCompare;
      final topCompare = b.isTopCandidate == a.isTopCandidate
          ? 0
          : (b.isTopCandidate ? 1 : -1);
      if (topCompare != 0) return topCompare;
      return b.candidate.totalScore.compareTo(a.candidate.totalScore);
    });

    switch (_selectedFilter) {
      case 'attention':
        return items.where((item) => item.needsAttention).toList();
      case 'interview':
        return items.where((item) => item.isTopCandidate).toList();
      default:
        return items.where(_matchesSearch).toList();
    }
  }

  List<_CandidateDecisionItem> get _filteredCandidateItems {
    final filtered = switch (_selectedFilter) {
      'attention' => _candidateItems.where((item) => item.needsAttention),
      'interview' => _candidateItems.where((item) => item.isTopCandidate),
      _ => _candidateItems,
    };
    return filtered.where(_matchesSearch).toList();
  }

  List<_ScreeningItem> get _filteredJobItems {
    if (_searchQuery.trim().isEmpty) return _items;
    return _items.where((item) {
      final haystack = [
        item.job.title,
        item.job.unitLabel,
        item.job.location,
        item.shortlist.summary,
        ...item.shortlist.rankedCandidates.map(
          (candidate) => candidate.candidateName,
        ),
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  bool _matchesSearch(_CandidateDecisionItem item) {
    if (_searchQuery.trim().isEmpty) return true;
    final haystack = [
      item.job.title,
      item.job.unitLabel,
      item.job.location,
      item.candidate.candidateName,
      item.candidate.recommendation,
      ...item.candidate.strengths,
      ...item.candidate.redFlags,
      ...item.candidate.gaps,
    ].whereType<String>().join(' ').toLowerCase();
    return haystack.contains(_searchQuery.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: SuperScaffold(
        stretch: true,
        appBar: SuperAppBar(
          backgroundColor: const Color(0xFFF8FAFC),
          automaticallyImplyLeading: false,
          title: Text(
            'Kandidat',
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
                  CupertinoIcons.person_2_fill,
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
            placeholderText: 'Cari kandidat, lowongan, atau catatan review',
            scrollBehavior: SearchBarScrollBehavior.pinned,
            resultBehavior: SearchBarResultBehavior.neverVisible,
            onChanged: (value) => setState(() => _searchQuery = value),
            onSubmitted: (value) => setState(() => _searchQuery = value),
          ),
          largeTitle: SuperLargeTitle(
            largeTitle: 'Kandidat',
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
            child: _CandidateFilterBar(
              selectedFilter: _selectedFilter,
              allCount: _candidateItems.length,
              attentionCount: _candidateItems
                  .where((item) => item.needsAttention)
                  .length,
              interviewCount: _candidateItems
                  .where((item) => item.isTopCandidate)
                  .length,
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
                _EmptyState(
                  icon: Icons.fact_check_outlined,
                  title: 'Belum ada kandidat terscreening',
                  description:
                      'Jalankan screening kandidat dari flow lowongan agar daftar keputusan muncul di sini.',
                )
              else ...[
                Text(
                  'Kandidat prioritas',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedFilter == 'all'
                      ? 'Urutan kandidat disusun dari yang paling butuh keputusan dan kandidat terbaik.'
                      : 'Filter membantu Anda fokus pada kandidat yang paling perlu tindakan.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                if (_filteredCandidateItems.isEmpty)
                  const _EmptyState(
                    icon: Icons.filter_alt_off_outlined,
                    title: 'Tidak ada kandidat untuk filter ini',
                    description:
                        'Coba ganti filter atau kata kunci untuk melihat kandidat lain yang perlu diputuskan.',
                  )
                else
                  ..._filteredCandidateItems
                      .take(6)
                      .map((item) => _CandidateDecisionCard(item: item)),
                const SizedBox(height: 24),
                Text(
                  'Per lowongan',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ringkasan tiap lowongan untuk melihat pipeline kandidat secara cepat.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                if (_filteredJobItems.isEmpty)
                  const _EmptyState(
                    icon: Icons.search_off_outlined,
                    title: 'Tidak ada lowongan yang cocok',
                    description:
                        'Ubah kata kunci pencarian untuk melihat ringkasan kandidat pada lowongan lain.',
                  )
                else
                  ..._filteredJobItems.map(
                    (item) => _JobDecisionCard(item: item),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CandidateFilterBar extends StatelessWidget {
  const _CandidateFilterBar({
    required this.selectedFilter,
    required this.allCount,
    required this.attentionCount,
    required this.interviewCount,
    required this.onSelected,
  });

  final String selectedFilter;
  final int allCount;
  final int attentionCount;
  final int interviewCount;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _CandidateFilterPill(
          label: 'Semua',
          count: allCount,
          selected: selectedFilter == 'all',
          onTap: () => onSelected('all'),
        ),
        _CandidateFilterPill(
          label: 'Cek manual',
          count: attentionCount,
          selected: selectedFilter == 'attention',
          onTap: () => onSelected('attention'),
        ),
        _CandidateFilterPill(
          label: 'Interview',
          count: interviewCount,
          selected: selectedFilter == 'interview',
          onTap: () => onSelected('interview'),
        ),
      ],
    );
  }
}

class _CandidateFilterPill extends StatelessWidget {
  const _CandidateFilterPill({
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

class _CandidateDecisionCard extends StatelessWidget {
  const _CandidateDecisionCard({required this.item});

  final _CandidateDecisionItem item;

  @override
  Widget build(BuildContext context) {
    final candidate = item.candidate;
    final accentColor = item.needsAttention
        ? const Color(0xFFB45309)
        : item.isTopCandidate
        ? const Color(0xFF166534)
        : const Color(0xFF1D4ED8);
    final accentBackground = item.needsAttention
        ? const Color(0xFFFEF3C7)
        : item.isTopCandidate
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFE0F2FE);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: accentBackground,
                    child: Text(
                      _initials(candidate.candidateName),
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
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
                          fontSize: 11,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            candidate.candidateName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            'Score ${candidate.totalScore.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.job.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (candidate.recommendation.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        candidate.recommendation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DecisionBadge(
                label: item.statusLabel,
                backgroundColor: accentBackground,
                foregroundColor: accentColor,
              ),
              if (candidate.strengths.isNotEmpty)
                _DecisionBadge(
                  label: candidate.strengths.take(2).join(' • '),
                  backgroundColor: const Color(0xFFF8FAFC),
                  foregroundColor: const Color(0xFF334155),
                ),
            ],
          ),
          if (candidate.redFlags.isNotEmpty || candidate.gaps.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                [
                  ...candidate.redFlags.take(2),
                  ...candidate.gaps.take(2),
                ].join(', '),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFB91C1C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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

class _DecisionBadge extends StatelessWidget {
  const _DecisionBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

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
        style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _JobDecisionCard extends StatelessWidget {
  const _JobDecisionCard({required this.item});

  final _ScreeningItem item;

  int get _decisionCount {
    final count =
        item.shortlist.rankedCandidates.length -
        item.shortlist.topCandidates.length;
    return count < 0 ? 0 : count;
  }

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
                    if ((item.job.unitLabel ?? '').isNotEmpty ||
                        (item.job.location ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          if ((item.job.unitLabel ?? '').isNotEmpty)
                            item.job.unitLabel!,
                          if ((item.job.location ?? '').isNotEmpty)
                            item.job.location!,
                        ].join(' • '),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _DecisionBadge(
                label: item.shortlist.status,
                backgroundColor: const Color(0xFFF3F4F6),
                foregroundColor: const Color(0xFF374151),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.shortlist.summary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryChip(
                label: 'Kandidat',
                value: '${item.shortlist.rankedCandidates.length}',
              ),
              _SummaryChip(label: 'Perlu review', value: '$_decisionCount'),
              _SummaryChip(
                label: 'Siap interview',
                value: '${item.shortlist.topCandidates.length}',
              ),
            ],
          ),
          if (item.shortlist.topCandidates.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Kandidat teratas',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...item.shortlist.topCandidates
                .take(2)
                .map((candidate) => _TopCandidateRow(candidate: candidate)),
          ],
        ],
      ),
    );
  }
}

class _TopCandidateRow extends StatelessWidget {
  const _TopCandidateRow({required this.candidate});

  final RecruiterShortlistEntry candidate;

  @override
  Widget build(BuildContext context) {
    final initials = candidate.candidateName
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFDBEAFE),
            child: Text(
              initials.isEmpty ? '?' : initials,
              style: const TextStyle(
                color: Color(0xFF1D4ED8),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.candidateName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  candidate.recommendation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              candidate.totalScore.toStringAsFixed(0),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
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
          Icon(icon, size: 32),
          const SizedBox(height: 12),
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

class _CandidateDecisionItem {
  const _CandidateDecisionItem({
    required this.job,
    required this.candidate,
    required this.isTopCandidate,
  });

  final RecruiterJob job;
  final RecruiterShortlistEntry candidate;
  final bool isTopCandidate;

  bool get needsAttention =>
      candidate.redFlags.isNotEmpty || candidate.gaps.isNotEmpty;

  String get statusLabel {
    if (needsAttention) return 'Perlu cek manual';
    if (isTopCandidate) return 'Siap interview';
    return 'Perlu keputusan';
  }
}

class _ScreeningItem {
  const _ScreeningItem({required this.job, required this.shortlist});

  final RecruiterJob job;
  final RecruiterShortlistResult shortlist;
}
