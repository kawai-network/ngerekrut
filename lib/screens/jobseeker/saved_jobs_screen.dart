/// Saved Jobs screen - shows jobseeker's bookmarked jobs
/// Uses libsql_dart repository for shared data (synced across devices)
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../repositories/saved_job_repository.dart';

// Re-export SavedJob class for use in this screen
export '../../repositories/saved_job_repository.dart' show SavedJob;

class SavedJobsScreen extends StatefulWidget {
  const SavedJobsScreen({super.key});

  @override
  State<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends State<SavedJobsScreen> {
  final SavedJobRepository _repo = SavedJobRepository();

  bool _isLoading = true;
  List<SavedJob> _savedJobs = [];
  final Set<String> _expandedNotes = {};

  @override
  void initState() {
    super.initState();
    _loadSavedJobs();
  }

  Future<void> _loadSavedJobs() async {
    setState(() => _isLoading = true);
    try {
      final jobs = await _repo.getAll();
      if (mounted) {
        setState(() {
          _savedJobs = jobs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading saved jobs: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleSave(
    String jobId,
    String title,
    String? company,
    String? location,
  ) async {
    try {
      final isSaved = await _repo.toggle(
        jobId,
        title: title,
        company: company,
        location: location,
      );
      if (!isSaved) {
        setState(() {
          _savedJobs.removeWhere((job) => job.jobId == jobId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dihapus dari saved jobs')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _updateNotes(String jobId, String notes) async {
    try {
      await _repo.updateNotes(jobId, notes);
      if (mounted) {
        setState(() {
          final index = _savedJobs.indexWhere((job) => job.jobId == jobId);
          if (index >= 0) {
            _savedJobs[index] = SavedJob(
              id: _savedJobs[index].id,
              userId: _savedJobs[index].userId,
              jobId: _savedJobs[index].jobId,
              title: _savedJobs[index].title,
              company: _savedJobs[index].company,
              location: _savedJobs[index].location,
              savedAt: _savedJobs[index].savedAt,
              notes: notes,
              isActive: _savedJobs[index].isActive,
              jobStatus: _savedJobs[index].jobStatus,
            );
          }
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Catatan disimpan')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving notes: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pekerjaan Disimpan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSavedJobs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedJobs.isEmpty
          ? _EmptyState(onRefresh: _loadSavedJobs)
          : RefreshIndicator(
              onRefresh: _loadSavedJobs,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _savedJobs.length,
                itemBuilder: (context, index) {
                  return _SavedJobCard(
                    job: _savedJobs[index],
                    isNotesExpanded: _expandedNotes.contains(
                      _savedJobs[index].jobId,
                    ),
                    onToggleSave: () => _toggleSave(
                      _savedJobs[index].jobId,
                      _savedJobs[index].title,
                      _savedJobs[index].company,
                      _savedJobs[index].location,
                    ),
                    onToggleNotes: () {
                      setState(() {
                        final jobId = _savedJobs[index].jobId;
                        if (_expandedNotes.contains(jobId)) {
                          _expandedNotes.remove(jobId);
                        } else {
                          _expandedNotes.add(jobId);
                        }
                      });
                    },
                    onSaveNotes: (notes) =>
                        _updateNotes(_savedJobs[index].jobId, notes),
                  );
                },
              ),
            ),
    );
  }
}

class _SavedJobCard extends StatelessWidget {
  const _SavedJobCard({
    required this.job,
    required this.isNotesExpanded,
    required this.onToggleSave,
    required this.onToggleNotes,
    required this.onSaveNotes,
  });

  final SavedJob job;
  final bool isNotesExpanded;
  final VoidCallback onToggleSave;
  final VoidCallback onToggleNotes;
  final Function(String) onSaveNotes;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (job.company != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          job.company!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey.shade700),
                        ),
                      ],
                      if (job.location != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          job.location!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_isClosed(job.jobStatus)) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Closed',
                      style: TextStyle(
                        color: Color(0xFFB91C1C),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: const Icon(Icons.bookmark, color: Color(0xFF6366F1)),
                  onPressed: onToggleSave,
                  tooltip: 'Hapus dari saved',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Disimpan ${DateFormat('d MMM yyyy').format(job.savedAt)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onToggleNotes,
                  icon: Icon(
                    isNotesExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  label: const Text('Catatan'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
            if (isNotesExpanded) ...[
              const Divider(height: 24),
              TextField(
                controller: TextEditingController(text: job.notes ?? ''),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tambahkan catatan...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                onSubmitted: onSaveNotes,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    onSaveNotes(job.notes ?? '');
                  },
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Simpan'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isClosed(String? status) {
    if (status == null) return false;
    final normalized = status.toLowerCase();
    return normalized == 'closed' || normalized == 'ditutup';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_border,
                size: 48,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum ada pekerjaan disimpan',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Simpan pekerjaan yang menarik untuk melamar nanti.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
