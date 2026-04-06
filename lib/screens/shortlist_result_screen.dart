import 'package:flutter/material.dart';

import '../models/recruiter_job.dart';
import '../models/recruiter_shortlist.dart';
import '../repositories/hiring_repository.dart';

class ShortlistResultScreen extends StatefulWidget {
  final HiringRepository repository;
  final RecruiterJob job;
  final RecruiterShortlistResult? initialResult;

  const ShortlistResultScreen({
    super.key,
    required this.repository,
    required this.job,
    this.initialResult,
  });

  @override
  State<ShortlistResultScreen> createState() => _ShortlistResultScreenState();
}

class _ShortlistResultScreenState extends State<ShortlistResultScreen> {
  bool _isLoading = true;
  String? _error;
  RecruiterShortlistResult? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result =
          widget.initialResult ??
          await widget.repository.fetchLatestShortlist(widget.job.id);
      if (!mounted) return;
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Shortlist')),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Memuat shortlist dari Cloudflare KV...'),
                ],
              ),
            )
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      widget.job.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(_result?.summary ?? ''),
                    const SizedBox(height: 20),
                    Text(
                      'Top 3 Kandidat',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    for (final entry in _result?.topCandidates ??
                        const <RecruiterShortlistEntry>[])
                      Card(
                        child: ExpansionTile(
                          leading: CircleAvatar(child: Text('${entry.rank}')),
                          title: Text(entry.candidateName),
                          subtitle: Text(
                            'Score ${entry.totalScore.toStringAsFixed(0)} • ${entry.recommendation}',
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          children: [
                            _BreakdownTable(entry: entry),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(entry.rationale),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final item in entry.strengths)
                                  Chip(
                                    backgroundColor: Colors.green.withValues(
                                      alpha: 0.12,
                                    ),
                                    label: Text('Strength: $item'),
                                  ),
                                for (final item in entry.gaps)
                                  Chip(
                                    backgroundColor: Colors.orange.withValues(
                                      alpha: 0.12,
                                    ),
                                    label: Text('Gap: $item'),
                                  ),
                                for (final item in entry.redFlags)
                                  Chip(
                                    backgroundColor: Colors.red.withValues(
                                      alpha: 0.12,
                                    ),
                                    label: Text('Risk: $item'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _BreakdownTable extends StatelessWidget {
  final RecruiterShortlistEntry entry;

  const _BreakdownTable({required this.entry});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, double)>[
      ('Skill match', entry.scoreBreakdown.skillMatch),
      ('Relevant experience', entry.scoreBreakdown.relevantExperience),
      ('Domain fit', entry.scoreBreakdown.domainFit),
      ('Communication clarity', entry.scoreBreakdown.communicationClarity),
      ('Growth potential', entry.scoreBreakdown.growthPotential),
      ('Penalty', entry.scoreBreakdown.penalty),
    ];

    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(row.$1)),
                  Text(row.$2.toStringAsFixed(0)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
