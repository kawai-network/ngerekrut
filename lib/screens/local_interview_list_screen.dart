library;

import 'package:flutter/material.dart';

import '../models/recruiter_job.dart';
import '../repositories/local_interview_guide_repository.dart';
import '../repositories/local_job_post_repository.dart';
import '../repositories/local_scorecard_repository.dart';

class LocalInterviewListScreen extends StatefulWidget {
  const LocalInterviewListScreen({
    super.key,
    required this.jobPostRepository,
    required this.scorecardRepository,
    required this.interviewGuideRepository,
  });

  final LocalJobPostRepository jobPostRepository;
  final LocalScorecardRepository scorecardRepository;
  final LocalInterviewGuideRepository interviewGuideRepository;

  @override
  State<LocalInterviewListScreen> createState() =>
      _LocalInterviewListScreenState();
}

class _LocalInterviewListScreenState extends State<LocalInterviewListScreen> {
  bool _isLoading = true;
  List<_InterviewItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final jobs = await widget.jobPostRepository.list();
    final items = <_InterviewItem>[];
    for (final job in jobs) {
      final scorecards = await widget.scorecardRepository.listForJob(job.id);
      final guides = await widget.interviewGuideRepository.listForJob(job.id);
      if (scorecards.isNotEmpty || guides.isNotEmpty) {
        items.add(
          _InterviewItem(
            job: job,
            scorecardCount: scorecards.length,
            guideCount: guides.length,
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
            'Interview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Guide dan scorecard interview yang tersimpan secara lokal.',
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
            _empty(context, 'Belum ada artefak interview lokal')
          else
            ..._items.map((item) => _buildCard(context, item)),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, _InterviewItem item) {
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
          '${item.guideCount} guide • ${item.scorecardCount} scorecard',
        ),
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

class _InterviewItem {
  const _InterviewItem({
    required this.job,
    required this.scorecardCount,
    required this.guideCount,
  });

  final RecruiterJob job;
  final int scorecardCount;
  final int guideCount;
}
