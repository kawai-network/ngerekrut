/// My Applications screen - shows jobseeker's job applications
/// Uses libsql_dart repository for shared data (synced across devices)
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/application_status.dart';
import '../../models/job_application.dart';
import '../../repositories/job_application_repository.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  final JobApplicationRepository _repo = JobApplicationRepository();

  bool _isLoading = true;
  List<JobApplication> _applications = [];
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    try {
      final apps = await _repo.getByCandidateId(_repo.candidateId);
      if (mounted) {
        setState(() {
          _applications = apps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading applications: $e')),
          );
        }
      }
    }
  }

  List<JobApplication> get _filteredApplications {
    if (_statusFilter == 'all') return _applications;
    return _applications
        .where((app) => app.status.name == _statusFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lamaran Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadApplications,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _applications.isEmpty
            ? _EmptyState(onRefresh: _loadApplications)
            : Column(
                children: [
                  _StatusFilterBar(
                    selectedFilter: _statusFilter,
                    onFilterChanged: (filter) =>
                        setState(() => _statusFilter = filter),
                    applications: _applications,
                  ),
                  Expanded(
                    child: _filteredApplications.isEmpty
                        ? const Center(
                            child: Text('Tidak ada lamaran untuk filter ini'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredApplications.length,
                            itemBuilder: (context, index) {
                              return _ApplicationCard(
                                application: _filteredApplications[index],
                                onTap: () => _showApplicationDetail(
                                  _filteredApplications[index],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showApplicationDetail(JobApplication application) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ApplicationDetailSheet(application: application),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application, required this.onTap});

  final JobApplication application;
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
                          application.jobTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (application.company != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            application.company!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey.shade700),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _StatusChip(status: application.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Dilamar ${_formatDate(application.appliedAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  if (application.daysSinceUpdate > 0)
                    Text(
                      '${application.daysSinceUpdate} hari yang lalu',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
              if (application.interviewDates?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: application.interviewDates!.take(2).map((date) {
                    return Chip(
                      label: Text(
                        'Interview: ${DateFormat('d MMM').format(date)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      avatar: const Icon(Icons.event, size: 16),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) return 'hari ini';
    if (difference.inDays == 1) return 'kemarin';
    if (difference.inDays < 7) return '${difference.inDays} hari lalu';
    return DateFormat('d MMM yyyy').format(date);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.foreground),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              color: config.foreground,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.applied:
        return _StatusConfig(
          label: 'Terkirim',
          background: const Color(0xFFDBEAFE),
          foreground: const Color(0xFF1D4ED8),
          icon: Icons.send,
        );
      case ApplicationStatus.screening:
        return _StatusConfig(
          label: 'Screening',
          background: const Color(0xFFF3E8FF),
          foreground: const Color(0xFF6D28D9),
          icon: Icons.filter_list,
        );
      case ApplicationStatus.underReview:
        return _StatusConfig(
          label: 'Direview',
          background: const Color(0xFFFEF3C7),
          foreground: const Color(0xFFB45309),
          icon: Icons.visibility,
        );
      case ApplicationStatus.interview:
        return _StatusConfig(
          label: 'Interview',
          background: const Color(0xFFE0E7FF),
          foreground: const Color(0xFF4338CA),
          icon: Icons.calendar_month,
        );
      case ApplicationStatus.offered:
        return _StatusConfig(
          label: 'Ditawarkan',
          background: const Color(0xFFDCFCE7),
          foreground: const Color(0xFF166534),
          icon: Icons.card_giftcard,
        );
      case ApplicationStatus.rejected:
        return _StatusConfig(
          label: 'Ditolak',
          background: const Color(0xFFFEE2E2),
          foreground: const Color(0xFFDC2626),
          icon: Icons.cancel,
        );
      case ApplicationStatus.withdrawn:
        return _StatusConfig(
          label: 'Ditarik',
          background: const Color(0xFFF3F4F6),
          foreground: const Color(0xFF4B5563),
          icon: Icons.arrow_back,
        );
      case ApplicationStatus.archived:
        return _StatusConfig(
          label: 'Diarsipkan',
          background: const Color(0xFFF3F4F6),
          foreground: const Color(0xFF4B5563),
          icon: Icons.archive,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;

  const _StatusConfig({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
  });
}

class _ApplicationDetailSheet extends StatelessWidget {
  const _ApplicationDetailSheet({required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      application.jobTitle,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (application.company != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        application.company!,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.grey.shade700),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _StatusChip(status: application.status),
                    const SizedBox(height: 24),
                    _DetailRow(
                      label: 'Tanggal melamar',
                      value: DateFormat(
                        'd MMMM yyyy',
                      ).format(application.appliedAt),
                    ),
                    _DetailRow(
                      label: 'Update terakhir',
                      value: DateFormat(
                        'd MMMM yyyy',
                      ).format(application.updatedAt),
                    ),
                    if (application.location != null)
                      _DetailRow(label: 'Lokasi', value: application.location!),
                    if (application.expectedSalary != null)
                      _DetailRow(
                        label: 'Gaji yang diharapkan',
                        value: application.expectedSalary!,
                      ),
                    if (application.source != null)
                      _DetailRow(label: 'Sumber', value: application.source!),
                    const SizedBox(height: 24),
                    if (application.coverLetter != null) ...[
                      Text(
                        'Cover Letter',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(application.coverLetter!),
                      const SizedBox(height: 16),
                    ],
                    if (application.interviewDates?.isNotEmpty == true) ...[
                      Text(
                        'Jadwal Interview',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...application.interviewDates!.map(
                        (date) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: Text(
                              DateFormat('d MMMM yyyy, HH:mm').format(date),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (application.rejectionReason != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Color(0xFFDC2626),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Alasan Penolakan',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        color: const Color(0xFFDC2626),
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(application.rejectionReason!),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.applications,
  });

  final String selectedFilter;
  final Function(String) onFilterChanged;
  final List<JobApplication> applications;

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('all', 'Semua'),
      ('applied', 'Terkirim'),
      ('underReview', 'Direview'),
      ('interview', 'Interview'),
      ('offered', 'Ditawarkan'),
      ('hired', 'Diterima'),
      ('rejected', 'Ditolak'),
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final (value, label) = filters[index];
          final count = value == 'all'
              ? applications.length
              : applications.where((app) => app.status.name == value).length;
          final isSelected = selectedFilter == value;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              label: Text('$label ($count)'),
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
              onSelected: (_) => onFilterChanged(value),
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
                Icons.description_outlined,
                size: 48,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum ada lamaran',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Mulai melamar pekerjaan dan lacak statusnya di sini.',
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
