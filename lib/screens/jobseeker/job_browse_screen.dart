/// Job Browse screen - shows available jobs from libsql_dart
/// Uses libsql_dart repository for shared data (synced from recruiter)
library;

import 'package:flutter/material.dart';
import '../../models/application_status.dart';
import '../../models/candidate.dart';
import '../../models/job_application.dart';
import '../../models/recruiter_job.dart';
import '../../repositories/candidate_repository.dart';
import '../../repositories/job_application_repository.dart';
import '../../repositories/job_posting_repository.dart';
import '../../repositories/saved_job_repository.dart';
import '../../services/job_matching_service.dart';
import '../../services/shared_identity_service.dart';
import 'interview_prep_screen.dart';

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
  final JobMatchingService _matchingService = JobMatchingService();

  bool _isLoading = true;
  List<RecruiterJob> _jobs = [];
  Set<String> _savedJobIds = {};
  String _searchQuery = '';
  String _departmentFilter = 'all';

  // Recommended jobs state
  bool _isLoadingRecommendations = true;
  List<JobMatchResult> _recommendedJobs = [];
  bool _hasCV = false;

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

      // Load recommendations after base data (fire and forget)
      // ignore: unawaited_futures
      _loadRecommendations();
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

  Future<void> _loadRecommendations() async {
    setState(() => _isLoadingRecommendations = true);
    try {
      final recommendations = await _matchingService.getRecommendedJobs(
        userId: SharedIdentityService.jobseekerUserId,
        minScore: 30, // Show jobs with at least 30% match
        limit: 5,
      );

      if (mounted) {
        setState(() {
          _recommendedJobs = recommendations;
          _hasCV = recommendations.isNotEmpty || _hasCandidateCV();
          _isLoadingRecommendations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRecommendations = false);
      }
    }
  }

  /// Check if candidate has CV data
  bool _hasCandidateCV() {
    // This is a simple check - actual implementation would query
    // For now, we'll determine this based on recommendation results
    return true; // Will be checked during recommendation load
  }

  Future<void> _toggleSave(RecruiterJob job) async {
    try {
      final isSaved = await _savedRepo.toggle(
        job.id,
        title: job.title,
        unitLabel: job.department,
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
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recommended Section
                        if (!_isLoadingRecommendations)
                          _RecommendedSection(
                            recommendations: _recommendedJobs,
                            hasCV: _hasCV,
                            isSaved: (job) => _savedJobIds.contains(job.id),
                            onSave: (job) => _toggleSave(job),
                            onTap: (job) => _showJobDetail(job),
                          )
                        else
                          const _RecommendedSectionLoading(),

                        // All Jobs Section
                        _AllJobsSection(
                          isLoading: _isLoading,
                          jobs: _filteredJobs,
                          savedJobIds: _savedJobIds,
                          onSave: _toggleSave,
                          onTap: _showJobDetail,
                          onRefresh: _loadData,
                        ),
                      ],
                    ),
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

/// Recommended jobs section
class _RecommendedSection extends StatelessWidget {
  const _RecommendedSection({
    required this.recommendations,
    required this.hasCV,
    required this.isSaved,
    required this.onSave,
    required this.onTap,
  });

  final List<JobMatchResult> recommendations;
  final bool hasCV;
  final bool Function(RecruiterJob) isSaved;
  final void Function(RecruiterJob) onSave;
  final void Function(RecruiterJob) onTap;

  @override
  Widget build(BuildContext context) {
    if (!hasCV) {
      return _NoCVRecommendationCard();
    }

    if (recommendations.isEmpty) {
      return const _NoMatchRecommendationCard();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommended for You',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Berdasarkan skill & pengalaman kamu',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final match = recommendations[index];
              return _RecommendedJobCard(
                match: match,
                isSaved: isSaved(match.job),
                onSave: () => onSave(match.job),
                onTap: () => onTap(match.job),
              );
            },
          ),
        ),
        const Divider(height: 32),
      ],
    );
  }
}

/// Loading state for recommendations
class _RecommendedSectionLoading extends StatelessWidget {
  const _RecommendedSectionLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommended for You',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Memuat rekomendasi...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Card when user has no CV
class _NoCVRecommendationCard extends StatelessWidget {
  const _NoCVRecommendationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.upload_file,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload CV untuk Rekomendasi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Dapatkan rekomendasi job yang cocok dengan skill kamu',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card when no jobs match
class _NoMatchRecommendationCard extends StatelessWidget {
  const _NoMatchRecommendationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.search_off,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Belum ada lowongan yang cocok',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Coba tambah skill di CV atau eksplor semua lowongan',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Recommended job card (horizontal scroll item)
class _RecommendedJobCard extends StatelessWidget {
  const _RecommendedJobCard({
    required this.match,
    required this.isSaved,
    required this.onSave,
    required this.onTap,
  });

  final JobMatchResult match;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onTap;

  Color _getMatchColor(BuildContext context) {
    switch (match.category) {
      case MatchCategory.veryHigh:
        return const Color(0xFF10B981);
      case MatchCategory.high:
        return const Color(0xFF3B82F6);
      case MatchCategory.medium:
        return const Color(0xFFF59E0B);
      case MatchCategory.low:
        return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchColor = _getMatchColor(context);

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: matchColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.psychology, size: 14, color: matchColor),
                          const SizedBox(width: 4),
                          Text(
                            '${match.matchScore}%',
                            style: TextStyle(
                              color: matchColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved
                            ? const Color(0xFF6366F1)
                            : Colors.grey.shade600,
                      ),
                      onPressed: onSave,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  match.job.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (match.job.department != null)
                  Text(
                    match.job.department!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                if (match.job.location != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          match.job.location!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF6B7280)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const Spacer(),
                if (match.matchingSkills.isNotEmpty) ...[
                  Text(
                    'Matching skills:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: match.matchingSkills.take(3).map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          skill,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// All jobs section wrapper
class _AllJobsSection extends StatelessWidget {
  const _AllJobsSection({
    required this.isLoading,
    required this.jobs,
    required this.savedJobIds,
    required this.onSave,
    required this.onTap,
    required this.onRefresh,
  });

  final bool isLoading;
  final List<RecruiterJob> jobs;
  final Set<String> savedJobIds;
  final void Function(RecruiterJob) onSave;
  final void Function(RecruiterJob) onTap;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (jobs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: _EmptyState(onRefresh: onRefresh),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Semua Lowongan',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            return _JobCard(
              job: jobs[index],
              isSaved: savedJobIds.contains(jobs[index].id),
              onSave: () => onSave(jobs[index]),
              onTap: () => onTap(jobs[index]),
            );
          },
        ),
      ],
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

class _JobDetailScreen extends StatefulWidget {
  const _JobDetailScreen({
    required this.job,
    required this.isSaved,
    required this.onSave,
  });

  final RecruiterJob job;
  final bool isSaved;
  final VoidCallback onSave;

  @override
  State<_JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<_JobDetailScreen> {
  final JobApplicationRepository _applicationRepo = JobApplicationRepository();
  bool _isCheckingApplication = true;
  bool _hasApplied = false;

  bool get _canApply {
    final normalized = widget.job.status.toLowerCase();
    return normalized == 'published' || normalized == 'active';
  }

  String get _applyButtonLabel {
    if (_isCheckingApplication) return 'Memeriksa status...';
    if (_hasApplied) return 'Sudah Dilamar';
    if (!_canApply) {
      final normalized = widget.job.status.toLowerCase();
      if (normalized == 'closed' || normalized == 'ditutup') {
        return 'Lowongan Ditutup';
      }
      if (normalized == 'draft') return 'Belum Dibuka';
      return 'Tidak Tersedia';
    }
    return 'Lamar Sekarang';
  }

  @override
  void initState() {
    super.initState();
    _loadApplicationState();
  }

  Future<void> _loadApplicationState() async {
    try {
      final existing = await _applicationRepo.getByCandidateAndJob(
        _applicationRepo.candidateId,
        widget.job.id,
      );
      if (!mounted) return;
      setState(() {
        _hasApplied = existing != null;
        _isCheckingApplication = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCheckingApplication = false);
    }
  }

  Future<void> _apply() async {
    final created = await showModalBottomSheet<JobApplication>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ApplyJobSheet(job: widget.job),
    );

    if (created == null || !mounted) return;
    setState(() => _hasApplied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Lamaran berhasil dikirim. Pantau statusnya di Lamaran Saya.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.job.title),
        actions: [
          IconButton(
            icon: Icon(widget.isSaved ? Icons.bookmark : Icons.bookmark_border),
            color: widget.isSaved ? const Color(0xFF6366F1) : null,
            onPressed: widget.onSave,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_canApply) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFB45309)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _buildAvailabilityMessage(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF92400E),
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (widget.job.department != null)
            _InfoRow(icon: Icons.business, label: widget.job.department!),
          if (widget.job.location != null)
            _InfoRow(icon: Icons.location_on, label: widget.job.location!),
          const SizedBox(height: 24),
          Text(
            'Deskripsi',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            widget.job.description ?? 'Tidak ada deskripsi.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          if (widget.job.requirements.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Kualifikasi',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...widget.job.requirements.map(
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
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InterviewPrepScreen(job: widget.job),
                ),
              );
            },
            icon: const Icon(Icons.school),
            label: const Text('Persiapan Wawancara'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCheckingApplication || _hasApplied || !_canApply
                  ? null
                  : _apply,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(_applyButtonLabel),
            ),
          ),
        ],
      ),
    );
  }

  String _buildAvailabilityMessage() {
    final normalized = widget.job.status.toLowerCase();
    if (normalized == 'closed' || normalized == 'ditutup') {
      return 'Lowongan ini sudah ditutup oleh recruiter dan tidak menerima lamaran baru.';
    }
    if (normalized == 'draft') {
      return 'Lowongan ini masih draft dan belum dibuka untuk pelamar.';
    }
    return 'Lowongan ini belum tersedia untuk lamaran baru.';
  }
}

class _ApplyJobSheet extends StatefulWidget {
  const _ApplyJobSheet({required this.job});

  final RecruiterJob job;

  @override
  State<_ApplyJobSheet> createState() => _ApplyJobSheetState();
}

class _ApplyJobSheetState extends State<_ApplyJobSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _headlineController = TextEditingController();
  final _skillsController = TextEditingController();
  final _expectedSalaryController = TextEditingController();
  final _coverLetterController = TextEditingController();
  final _resumeIdController = TextEditingController();
  final JobApplicationRepository _repo = JobApplicationRepository();
  final CandidateRepository _candidateRepository = CandidateRepository();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _headlineController.dispose();
    _skillsController.dispose();
    _expectedSalaryController.dispose();
    _coverLetterController.dispose();
    _resumeIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    final status = widget.job.status.toLowerCase();
    if (status != 'published' && status != 'active') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lowongan ini tidak menerima lamaran baru.'),
        ),
      );
      Navigator.pop(context);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final existing = await _repo.getByCandidateAndJob(
        _repo.candidateId,
        widget.job.id,
      );
      if (existing != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda sudah pernah melamar lowongan ini.'),
          ),
        );
        Navigator.pop(context);
        return;
      }

      final application = JobApplication.create(
        jobId: widget.job.id,
        jobTitle: widget.job.title,
        candidateId: _repo.candidateId,
        unitLabel: widget.job.department,
        location: widget.job.location,
        expectedSalary: _expectedSalaryController.text.trim().isEmpty
            ? null
            : _expectedSalaryController.text.trim(),
        coverLetter: _coverLetterController.text.trim().isEmpty
            ? null
            : _coverLetterController.text.trim(),
        resumeId: _resumeIdController.text.trim().isEmpty
            ? null
            : _resumeIdController.text.trim(),
      );
      final candidateId = _repo.candidateId;
      final existingCandidate = await _candidateRepository.getById(candidateId);
      final parsedSkills = _skillsController.text
          .split(',')
          .map((skill) => skill.trim())
          .where((skill) => skill.isNotEmpty)
          .toList();
      final coverLetter = _coverLetterController.text.trim();
      final resumeId = _resumeIdController.text.trim();

      await _candidateRepository.save(
        RecruiterCandidate(
          id: candidateId,
          name: _nameController.text.trim(),
          headline: _headlineController.text.trim().isEmpty
              ? existingCandidate?.headline
              : _headlineController.text.trim(),
          yearsOfExperience: existingCandidate?.yearsOfExperience,
          stage: ApplicationStatus.applied.name,
          profile: CandidateProfile(
            skills: parsedSkills.isEmpty
                ? (existingCandidate?.profile?.skills ?? const [])
                : parsedSkills,
            summary: coverLetter.isEmpty
                ? (existingCandidate?.profile?.summary ?? '')
                : coverLetter,
          ),
          resume: resumeId.isEmpty
              ? existingCandidate?.resume
              : CandidateResume(id: resumeId, fileName: 'resume.pdf'),
        ),
      );
      await _repo.create(application);
      if (!mounted) return;
      Navigator.pop(context, application);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim lamaran: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lamar ${widget.job.title}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Isi data tambahan untuk mengirim lamaran Anda.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama lengkap',
                  hintText: 'Contoh: Budi Santoso',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama lengkap tidak boleh kosong.';
                  }
                  if (value.trim().length < 3) {
                    return 'Tulis minimal 3 karakter.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _headlineController,
                decoration: const InputDecoration(
                  labelText: 'Headline profesional',
                  hintText: 'Contoh: Flutter Developer',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _skillsController,
                decoration: const InputDecoration(
                  labelText: 'Skill utama',
                  hintText:
                      'Pisahkan dengan koma, mis. Flutter, Dart, Firebase',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _expectedSalaryController,
                decoration: const InputDecoration(
                  labelText: 'Ekspektasi gaji',
                  hintText: 'Contoh: Rp8.000.000 - Rp10.000.000',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _resumeIdController,
                decoration: const InputDecoration(
                  labelText: 'Resume ID',
                  hintText: 'Opsional, mis. resume_v1',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _coverLetterController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Cover letter',
                  hintText:
                      'Ceritakan singkat kenapa Anda cocok untuk lowongan ini.',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Cover letter tidak boleh kosong.';
                  }
                  if (value.trim().length < 20) {
                    return 'Tulis minimal 20 karakter.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: Text(_isSubmitting ? 'Mengirim...' : 'Kirim Lamaran'),
                ),
              ),
            ],
          ),
        ),
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
