library;

import 'package:flutter/material.dart';

import '../models/recruiter_job.dart';
import '../models/recruiter_shortlist.dart';
import '../repositories/local_interview_guide_repository.dart';
import '../repositories/local_job_post_repository.dart';
import '../repositories/local_scorecard_repository.dart';
import '../repositories/local_shortlist_repository.dart';

class LocalJobPostListScreen extends StatefulWidget {
  const LocalJobPostListScreen({
    super.key,
    required this.jobPostRepository,
    required this.shortlistRepository,
    required this.scorecardRepository,
    required this.interviewGuideRepository,
  });

  final LocalJobPostRepository jobPostRepository;
  final LocalShortlistRepository shortlistRepository;
  final LocalScorecardRepository scorecardRepository;
  final LocalInterviewGuideRepository interviewGuideRepository;

  @override
  State<LocalJobPostListScreen> createState() => _LocalJobPostListScreenState();
}

class _LocalJobPostListScreenState extends State<LocalJobPostListScreen> {
  bool _isLoading = true;
  List<_LocalJobPostSummary> _items = const [];
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final jobs = await widget.jobPostRepository.list();
    final summaries = <_LocalJobPostSummary>[];

    for (final job in jobs) {
      final shortlist = await widget.shortlistRepository.getLatestForJob(job.id);
      final scorecards = await widget.scorecardRepository.listForJob(job.id);
      final guides = await widget.interviewGuideRepository.listForJob(job.id);

      summaries.add(
        _LocalJobPostSummary(
          job: job,
          shortlist: shortlist,
          shortlistCount: shortlist?.rankedCandidates.length ?? 0,
          topCandidateCount: shortlist?.topCandidates.length ?? 0,
          scorecardCount: scorecards.length,
          guideCount: guides.length,
          latestScreeningSummary: shortlist?.summary,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _items = summaries;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lowongan Lokal'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Daftar lowongan dari ObjectBox',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Screen ini membaca lowongan lokal beserta artefak screening dan interview yang sudah tersimpan.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip('all', 'Semua'),
                _buildFilterChip('active', 'Aktif'),
                _buildFilterChip('draft', 'Draft'),
                _buildFilterChip('closed', 'Ditutup'),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_filteredItems.isEmpty)
              _buildEmptyState(context)
            else
              ..._filteredItems.map((item) => _buildJobCard(context, item)),
          ],
        ),
      ),
    );
  }

  List<_LocalJobPostSummary> get _filteredItems {
    if (_statusFilter == 'all') return _items;
    return _items
        .where((item) => item.job.status.toLowerCase() == _statusFilter)
        .toList();
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.work_outline, size: 32),
          const SizedBox(height: 12),
          Text(
            'Belum ada lowongan lokal',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Isi ObjectBox dengan mock data atau simpan lowongan lokal lebih dulu.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, _LocalJobPostSummary item) {
    final job = item.job;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _LocalJobPostDetailScreen(item: item),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  _buildStatusPill(job.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                [
                  if ((job.department ?? '').isNotEmpty) job.department!,
                  if ((job.location ?? '').isNotEmpty) job.location!,
                ].join(' • '),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
              ),
              if ((job.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  job.description!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                      ),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildMetricChip('Shortlist', '${item.shortlistCount}'),
                  _buildMetricChip('Top', '${item.topCandidateCount}'),
                  _buildMetricChip('Scorecard', '${item.scorecardCount}'),
                  _buildMetricChip('Guide', '${item.guideCount}'),
                ],
              ),
              if (item.shortlist?.topCandidates.isNotEmpty == true) ...[
                const SizedBox(height: 14),
                Text(
                  'Top Kandidat',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                ...item.shortlist!.topCandidates.take(2).map(
                  (candidate) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFFE2E8F0),
                          child: Text(
                            candidate.rank.toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            candidate.candidateName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          candidate.totalScore.toStringAsFixed(0),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if ((item.latestScreeningSummary ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
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

  Widget _buildMetricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text('$label $value'),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    return ChoiceChip(
      selected: _statusFilter == value,
      label: Text(label),
      onSelected: (_) => setState(() => _statusFilter = value),
    );
  }

  Widget _buildStatusPill(String status) {
    final normalized = status.toLowerCase();
    final color = switch (normalized) {
      'active' => const Color(0xFF16A34A),
      'draft' => const Color(0xFF2563EB),
      'closed' => const Color(0xFF64748B),
      _ => const Color(0xFF475569),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LocalJobPostDetailScreen extends StatelessWidget {
  const _LocalJobPostDetailScreen({required this.item});

  final _LocalJobPostSummary item;

  @override
  Widget build(BuildContext context) {
    final job = item.job;
    return Scaffold(
      appBar: AppBar(
        title: Text(job.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            job.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            [
              if ((job.department ?? '').isNotEmpty) job.department!,
              if ((job.location ?? '').isNotEmpty) job.location!,
              job.status,
            ].join(' • '),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: 20),
          _buildSection(
            context,
            title: 'Ringkasan',
            child: Text(
              job.description ?? 'Belum ada deskripsi.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            title: 'Requirements',
            child: job.requirements.isEmpty
                ? const Text('Belum ada requirement.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: job.requirements
                        .map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text('• $item'),
                            ))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            title: 'Artefak Lokal',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildArtifactCard('Shortlist', '${item.shortlistCount}'),
                _buildArtifactCard('Top Kandidat', '${item.topCandidateCount}'),
                _buildArtifactCard('Scorecard', '${item.scorecardCount}'),
                _buildArtifactCard('Interview Guide', '${item.guideCount}'),
              ],
            ),
          ),
          if (item.shortlist?.rankedCandidates.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            _buildSection(
              context,
              title: 'Kandidat Teratas',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.shortlist!.rankedCandidates.take(3).map(
                  (candidate) {
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
                              'Kekuatan: ${candidate.strengths.join(', ')}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey.shade700),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ).toList(),
              ),
            ),
          ],
          if ((item.latestScreeningSummary ?? '').isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSection(
              context,
              title: 'Screening Terakhir',
              child: Text(
                item.latestScreeningSummary!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildArtifactCard(String label, String value) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalJobPostSummary {
  const _LocalJobPostSummary({
    required this.job,
    required this.shortlist,
    required this.shortlistCount,
    required this.topCandidateCount,
    required this.scorecardCount,
    required this.guideCount,
    this.latestScreeningSummary,
  });

  final RecruiterJob job;
  final RecruiterShortlistResult? shortlist;
  final int shortlistCount;
  final int topCandidateCount;
  final int scorecardCount;
  final int guideCount;
  final String? latestScreeningSummary;
}
