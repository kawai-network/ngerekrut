library;

import 'package:flutter/material.dart';

import '../models/recruiter_job.dart';
import '../models/recruiter_shortlist.dart';
import '../repositories/local_job_post_repository.dart';
import '../repositories/local_shortlist_repository.dart';

class LocalScreeningListScreen extends StatefulWidget {
  const LocalScreeningListScreen({
    super.key,
    required this.jobPostRepository,
    required this.shortlistRepository,
  });

  final LocalJobPostRepository jobPostRepository;
  final LocalShortlistRepository shortlistRepository;

  @override
  State<LocalScreeningListScreen> createState() =>
      _LocalScreeningListScreenState();
}

class _LocalScreeningListScreenState extends State<LocalScreeningListScreen> {
  bool _isLoading = true;
  String _selectedFilter = 'all';
  List<_ScreeningItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final jobs = await widget.jobPostRepository.list();
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
        return items;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1F2937), Color(0xFF0F766E)],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kandidat yang perlu keputusan',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Lihat kandidat unggulan, tandai yang butuh review manual, lalu lanjutkan ke tahap interview.',
                  style: TextStyle(color: Colors.white70, height: 1.45),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const LinearProgressIndicator(
                    minHeight: 4,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _HeroStat(label: 'Lowongan', value: '${_items.length}'),
                      _HeroStat(
                        label: 'Perlu review',
                        value:
                            '${_items.fold<int>(0, (sum, item) => sum + _decisionCount(item.shortlist))}',
                      ),
                      _HeroStat(
                        label: 'Siap interview',
                        value:
                            '${_items.fold<int>(0, (sum, item) => sum + item.shortlist.topCandidates.length)}',
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
              'Filter keputusan',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip('all', 'Semua kandidat'),
                _buildFilterChip('attention', 'Perlu cek manual'),
                _buildFilterChip('interview', 'Siap interview'),
              ],
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
              _selectedFilter == 'all'
                  ? 'Urutan kandidat disusun dari yang paling butuh keputusan dan kandidat terbaik.'
                  : 'Filter membantu Anda fokus pada kandidat yang paling perlu tindakan.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (_candidateItems.isEmpty)
              const _EmptyState(
                icon: Icons.filter_alt_off_outlined,
                title: 'Tidak ada kandidat untuk filter ini',
                description:
                    'Coba ganti filter untuk melihat kandidat lain yang perlu diputuskan.',
              )
            else
              ..._candidateItems
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
            ..._items.map((item) => _JobDecisionCard(item: item)),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) {
        setState(() => _selectedFilter = value);
      },
      showCheckmark: false,
      selectedColor: const Color(0xFFDCFCE7),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: isSelected ? const Color(0xFF166534) : null,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF86EFAC) : const Color(0xFFE5E7EB),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

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
                CircleAvatar(
                  backgroundColor: accentBackground,
                  child: Text(
                    '${candidate.rank}',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.candidateName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.job.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  candidate.totalScore.toStringAsFixed(0),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
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
                if (candidate.recommendation.trim().isNotEmpty)
                  _DecisionBadge(
                    label: candidate.recommendation,
                    backgroundColor: const Color(0xFFF3F4F6),
                    foregroundColor: const Color(0xFF374151),
                  ),
              ],
            ),
            if (candidate.strengths.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Kekuatan utama',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                candidate.strengths.take(3).join(', '),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              ),
            ],
            if (candidate.redFlags.isNotEmpty || candidate.gaps.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Perlu dicek manual',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                [
                  ...candidate.redFlags.take(2),
                  ...candidate.gaps.take(2),
                ].join(', '),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.red.shade700),
              ),
            ],
          ],
        ),
      ),
    );
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
              children: [
                Expanded(
                  child: Text(
                    item.job.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _DecisionBadge(
                  label: item.shortlist.status,
                  backgroundColor: const Color(0xFFF3F4F6),
                  foregroundColor: const Color(0xFF374151),
                ),
              ],
            ),
            const SizedBox(height: 6),
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
              const SizedBox(height: 14),
              Text(
                'Kandidat teratas',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...item.shortlist.topCandidates
                  .take(2)
                  .map(
                    (candidate) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${candidate.candidateName} • score ${candidate.totalScore.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            candidate.recommendation,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
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
