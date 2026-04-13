library;

import 'package:flutter/material.dart';

import '../models/recruiter_job.dart';
import '../repositories/local_job_post_repository.dart';
import '../repositories/local_shortlist_repository.dart';

class LocalAssessmentListScreen extends StatefulWidget {
  const LocalAssessmentListScreen({
    super.key,
    required this.jobPostRepository,
    required this.shortlistRepository,
  });

  final LocalJobPostRepository jobPostRepository;
  final LocalShortlistRepository shortlistRepository;

  @override
  State<LocalAssessmentListScreen> createState() =>
      _LocalAssessmentListScreenState();
}

class _LocalAssessmentListScreenState extends State<LocalAssessmentListScreen> {
  bool _isLoading = true;
  List<_AssessmentItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final jobs = await widget.jobPostRepository.list();
    final items = <_AssessmentItem>[];
    for (final job in jobs) {
      final shortlist = await widget.shortlistRepository.getLatestForJob(job.id);
      if (shortlist != null) {
        items.add(
          _AssessmentItem(
            job: job,
            candidateCount: shortlist.topCandidates.length,
            status: shortlist.topCandidates.isEmpty ? 'draft' : 'ready',
          ),
        );
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
            'Tes skill',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Placeholder operasional untuk assessment per lowongan. Saat ini dihitung dari kandidat top shortlist.',
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
            _empty(context, 'Belum ada assessment lokal')
          else
            ..._items.map((item) => _buildCard(context, item)),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, _AssessmentItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        title: Text(
          item.job.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${item.candidateCount} kandidat siap masuk tes',
        ),
        trailing: Text(item.status),
      ),
    );
  }

  Widget _empty(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _AssessmentItem {
  const _AssessmentItem({
    required this.job,
    required this.candidateCount,
    required this.status,
  });

  final RecruiterJob job;
  final int candidateCount;
  final String status;
}
