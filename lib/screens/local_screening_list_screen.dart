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
      final shortlist = await widget.shortlistRepository.getLatestForJob(job.id);
      if (shortlist != null) {
        items.add(_ScreeningItem(job: job, shortlist: shortlist));
      }
    }
    if (!mounted) return;
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Screening per lowongan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ringkasan shortlist kandidat lokal untuk tiap lowongan.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_items.isEmpty)
            _emptyState(
              context,
              icon: Icons.fact_check_outlined,
              title: 'Belum ada screening lokal',
            )
          else
            ..._items.map((item) => _buildCard(context, item)),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, _ScreeningItem item) {
    final shortlist = item.shortlist;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.job.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              shortlist.summary,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Ranked', '${shortlist.rankedCandidates.length}'),
                _chip('Top', '${shortlist.topCandidates.length}'),
                _chip('Status', shortlist.status),
              ],
            ),
            if (shortlist.rankedCandidates.isNotEmpty) ...[
              const SizedBox(height: 14),
              ...shortlist.rankedCandidates.take(3).map(
                (candidate) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                          const SizedBox(width: 10),
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
                      Text(
                        candidate.recommendation,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                      ),
                      if (candidate.strengths.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Kekuatan: ${candidate.strengths.join(', ')}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade700,
                                  ),
                        ),
                      ],
                      if (candidate.redFlags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Red flags: ${candidate.redFlags.join(', ')}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.red.shade700,
                                  ),
                        ),
                      ],
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

  Widget _chip(String label, String value) {
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

  Widget _emptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
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
          Icon(icon, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _ScreeningItem {
  const _ScreeningItem({
    required this.job,
    required this.shortlist,
  });

  final RecruiterJob job;
  final RecruiterShortlistResult shortlist;
}
