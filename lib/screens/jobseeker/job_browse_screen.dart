/// Job Browse screen - shows available jobs from libsql_dart
/// Uses libsql_dart repository for shared data (synced from recruiter)
library;

import 'package:flutter/material.dart';
import '../../models/recruiter_job.dart';
import '../../repositories/job_posting_repository.dart';
import '../../repositories/saved_job_repository.dart';

// Re-export SavedJob class for use in this screen
export '../../repositories/saved_job_repository.dart' show SavedJob;

class JobBrowseScreen extends StatefulWidget {
  const JobBrowseScreen({super.key});

  @override
  State<JobBrowseScreen> createState() => _JobBrowseScreenState();
}

class _JobBrowseScreenState extends State<JobBrowseScreen> {
  final JobPostingRepository _jobRepo = JobPostingRepository();
  final SavedJobRepository _savedRepo = SavedJobRepository();

  bool _isLoading = true;
  List<RecruiterJob> _jobs = [];
  Set<String> _savedJobIds = {};
  String _searchQuery = '';
  String _departmentFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final jobs = await _jobRepo.getActive();
      final saved = await _savedRepo.getAll();

      if (mounted) {
        setState(() {
          _jobs = jobs;
          _savedJobIds = saved.map((j) => j.jobId).toSet();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error loading jobs: $e')));
        }
      }
    }
  }

  Future<void> _toggleSave(RecruiterJob job) async {
    try {
      final isSaved = await _savedRepo.toggle(
        job.id,
        title: job.title,
        company: job.department,
        location: job.location,
      );
      setState(() {
        if (isSaved) {
          _savedJobIds.add(job.id);
        } else {
          _savedJobIds.remove(job.id);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSaved ? 'Disimpan!' : 'Dihapus dari saved'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  List<RecruiterJob> get _filteredJobs {
    var jobs = _jobs;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      jobs = jobs.where((job) {
        return job.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (job.description?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false);
      }).toList();
    }

    // Filter by department
    if (_departmentFilter != 'all') {
      jobs = jobs.where((job) => job.department == _departmentFilter).toList();
    }

    return jobs;
  }

  List<String> get _departments {
    final depts =
        _jobs.map((j) => j.department).whereType<String>().toSet().toList()
          ..sort();
    return ['all', ...depts];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Pekerjaan'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(
            query: _searchQuery,
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          _DepartmentFilter(
            departments: _departments,
            selected: _departmentFilter,
            onSelected: (value) => setState(() => _departmentFilter = value),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredJobs.isEmpty
                ? _EmptyState(onRefresh: _loadData)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredJobs.length,
                    itemBuilder: (context, index) {
                      return _JobCard(
                        job: _filteredJobs[index],
                        isSaved: _savedJobIds.contains(_filteredJobs[index].id),
                        onSave: () => _toggleSave(_filteredJobs[index]),
                        onTap: () => _showJobDetail(_filteredJobs[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showJobDetail(RecruiterJob job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _JobDetailScreen(
          job: job,
          isSaved: _savedJobIds.contains(job.id),
          onSave: () => _toggleSave(job),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.isSaved,
    required this.onSave,
    required this.onTap,
  });

  final RecruiterJob job;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
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
                        const SizedBox(height: 4),
                        if (job.department != null)
                          Text(
                            job.department!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey.shade700),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved
                          ? const Color(0xFF6366F1)
                          : Colors.grey.shade600,
                    ),
                    onPressed: onSave,
                    tooltip: isSaved ? 'Hapus dari saved' : 'Simpan',
                  ),
                ],
              ),
              if (job.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      job.location!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
              if (job.description != null) ...[
                const SizedBox(height: 12),
                Text(
                  job.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (job.department != null) _Chip(label: job.department!),
                  if (job.location != null) _Chip(label: job.location!),
                  if (job.requirements.isNotEmpty)
                    ...job.requirements.take(2).map((req) => _Chip(label: req)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.query, required this.onChanged});

  final String query;
  final Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari posisi atau perusahaan...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => onChanged(''),
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _DepartmentFilter extends StatelessWidget {
  const _DepartmentFilter({
    required this.departments,
    required this.selected,
    required this.onSelected,
  });

  final List<String> departments;
  final String selected;
  final Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: departments.length,
        itemBuilder: (context, index) {
          final dept = departments[index];
          final isSelected = selected == dept;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              label: Text(dept == 'all' ? 'Semua' : dept),
              selectedColor: const Color(0xFFDCFCE7),
              backgroundColor: Colors.grey.shade100,
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF86EFAC)
                    : Colors.transparent,
              ),
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF166534)
                    : Colors.grey.shade700,
                fontSize: 12,
              ),
              onSelected: (_) => onSelected(dept),
            ),
          );
        },
      ),
    );
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
                Icons.work_outline,
                size: 48,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tidak ada lowongan ditemukan',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci atau filter lainnya.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
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

class _JobDetailScreen extends StatelessWidget {
  const _JobDetailScreen({
    required this.job,
    required this.isSaved,
    required this.onSave,
  });

  final RecruiterJob job;
  final bool isSaved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(job.title),
        actions: [
          IconButton(
            icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
            color: isSaved ? const Color(0xFF6366F1) : null,
            onPressed: onSave,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (job.department != null)
            _InfoRow(icon: Icons.business, label: job.department!),
          if (job.location != null)
            _InfoRow(icon: Icons.location_on, label: job.location!),
          const SizedBox(height: 24),
          Text(
            'Deskripsi',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            job.description ?? 'Tidak ada deskripsi.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          if (job.requirements.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Kualifikasi',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...job.requirements.map(
              (req) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(req)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur apply coming soon!')),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Lamar Sekarang'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
