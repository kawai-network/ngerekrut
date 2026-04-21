/// My Applications screen - shows jobseeker's job applications
/// Uses libsql_dart repository for shared data (synced across devices)
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/application_status.dart';
import '../../models/job_application.dart';
import '../../repositories/job_application_repository.dart';
import '../../repositories/job_posting_repository.dart';
import '../../services/google_calendar_service.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  final JobApplicationRepository _repo = JobApplicationRepository();
  final JobPostingRepository _jobPostingRepository = JobPostingRepository();
  final GoogleCalendarService _calendarService = GoogleCalendarService.instance;

  bool _isLoading = true;
  List<JobApplication> _applications = [];
  Map<String, String> _jobStatusesById = {};
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
      final jobIds = apps.map((app) => app.jobId).toSet().toList();
      final jobs = await Future.wait(
        jobIds.map((jobId) => _jobPostingRepository.getById(jobId)),
      );

      if (mounted) {
        setState(() {
          _applications = apps;
          _jobStatusesById = {
            for (final job in jobs.whereType<dynamic>())
              job.id as String: job.status as String,
          };
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

  JobApplication? get _nextUpcomingInterviewApplication {
    final now = DateTime.now();
    final upcoming = _applications.where(
      (application) =>
          application.interviewDates?.any((date) => date.isAfter(now)) == true,
    );
    if (upcoming.isEmpty) return null;

    JobApplication? selected;
    DateTime? selectedDate;
    for (final application in upcoming) {
      final nextDate = application.interviewDates!
          .where((date) => date.isAfter(now))
          .reduce((a, b) => a.isBefore(b) ? a : b);
      if (selectedDate == null || nextDate.isBefore(selectedDate)) {
        selected = application;
        selectedDate = nextDate;
      }
    }
    return selected;
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
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _applications.isEmpty
                  ? _EmptyState(onRefresh: _loadApplications)
                  : Column(
                      children: [
                        if (_nextUpcomingInterviewApplication != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: _UpcomingInterviewBanner(
                              application: _nextUpcomingInterviewApplication!,
                              onOpenMeeting: () => _openMeetingLink(
                                _nextUpcomingInterviewApplication!,
                              ),
                              onOpenDetails: () => _showApplicationDetail(
                                _nextUpcomingInterviewApplication!,
                              ),
                            ),
                          ),
                        _StatusFilterBar(
                          selectedFilter: _statusFilter,
                          onFilterChanged: (filter) =>
                              setState(() => _statusFilter = filter),
                          applications: _applications,
                        ),
                        Expanded(
                          child: _filteredApplications.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Tidak ada lamaran untuk filter ini',
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _filteredApplications.length,
                                  itemBuilder: (context, index) {
                                    return _ApplicationCard(
                                      application: _filteredApplications[index],
                                      isUpcoming:
                                          _nextUpcomingInterviewApplication
                                              ?.id ==
                                          _filteredApplications[index].id,
                                      jobStatus:
                                          _jobStatusesById[_filteredApplications[index]
                                              .jobId],
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
          ],
        ),
      ),
    );
  }

  void _showApplicationDetail(JobApplication application) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ApplicationDetailSheet(
        application: application,
        jobStatus: _jobStatusesById[application.jobId],
        onSyncCalendar: () => _syncInterviewToCalendar(application),
        onOpenMeeting: () => _openMeetingLink(application),
      ),
    );
  }

  Future<void> _syncInterviewToCalendar(JobApplication application) async {
    final interviewDate = application.interviewDates?.isNotEmpty == true
        ? application.interviewDates!.last
        : null;
    if (interviewDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada jadwal interview untuk disinkronkan.'),
        ),
      );
      return;
    }

    try {
      final result = await _calendarService.syncInterviewEvent(
        application: application,
        interviewDate: interviewDate,
        existingEventId: application.candidateCalendarEventId,
        createMeetConference: false,
      );
      if (!result.success) {
        throw result.error ?? 'Sinkronisasi Google Calendar gagal.';
      }
      await _repo.updateCandidateCalendarEventId(
        application.id,
        result.eventId,
      );
      await _loadApplications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            application.isSyncedToCandidateCalendar
                ? 'Event interview di Google Calendar Anda berhasil diperbarui.'
                : 'Event interview berhasil ditambahkan ke Google Calendar Anda.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal sinkron ke Google Calendar: $e')),
      );
    }
  }

  Future<void> _openMeetingLink(JobApplication application) async {
    final meetingUrl = application.meetingUrl;
    if (meetingUrl == null || meetingUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada link Google Meet untuk interview ini.'),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(meetingUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link meeting tidak valid.')),
      );
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka Google Meet.')),
      );
    }
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.isUpcoming,
    required this.jobStatus,
    required this.onTap,
  });

  final JobApplication application;
  final bool isUpcoming;
  final String? jobStatus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isUpcoming ? const Color(0xFFEEF2FF) : null,
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
                        if (application.unitLabel != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            application.unitLabel!,
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
              if (_isClosed(jobStatus)) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.work_off_outlined,
                        color: Color(0xFFB91C1C),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lowongan ini sudah ditutup oleh recruiter.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(0xFFB91C1C),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                if (isUpcoming) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF93C5FD)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.alarm_on_outlined,
                          color: Color(0xFF1D4ED8),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ini interview terdekat Anda.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: const Color(0xFF1D4ED8),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              if ((application.recruiterNotes ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.note_alt_outlined,
                        size: 16,
                        color: Color(0xFF475569),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          application.recruiterNotes!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(0xFF475569),
                                height: 1.45,
                              ),
                        ),
                      ),
                    ],
                  ),
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

  bool _isClosed(String? status) {
    if (status == null) return false;
    final normalized = status.toLowerCase();
    return normalized == 'closed' || normalized == 'ditutup';
  }
}

class _UpcomingInterviewBanner extends StatelessWidget {
  const _UpcomingInterviewBanner({
    required this.application,
    required this.onOpenMeeting,
    required this.onOpenDetails,
  });

  final JobApplication application;
  final VoidCallback onOpenMeeting;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final nextInterview = application.interviewDates!
        .where((date) => date.isAfter(DateTime.now()))
        .reduce((a, b) => a.isBefore(b) ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_available, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Interview Terdekat',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            application.jobTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          if ((application.unitLabel ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              application.unitLabel!,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            _formatUpcomingInterview(nextInterview),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if ((application.interviewDurationMinutes ?? 0) > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Durasi ${application.interviewDurationMinutes} menit',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if ((application.meetingUrl ?? '').isNotEmpty)
                FilledButton.tonalIcon(
                  onPressed: onOpenMeeting,
                  icon: const Icon(Icons.video_camera_front_outlined),
                  label: const Text('Buka Meet'),
                ),
              OutlinedButton.icon(
                onPressed: onOpenDetails,
                icon: const Icon(Icons.open_in_new, color: Colors.white),
                label: const Text(
                  'Lihat Detail',
                  style: TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatUpcomingInterview(DateTime date) {
    final now = DateTime.now();
    final localDate = DateTime(date.year, date.month, date.day);
    final localNow = DateTime(now.year, now.month, now.day);
    final dayDifference = localDate.difference(localNow).inDays;
    final timeLabel = DateFormat('EEEE, d MMM yyyy • HH:mm').format(date);

    if (dayDifference == 0) return 'Hari ini • $timeLabel';
    if (dayDifference == 1) return 'Besok • $timeLabel';
    if (dayDifference > 1 && dayDifference < 7) {
      return '$dayDifference hari lagi • $timeLabel';
    }
    return timeLabel;
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
  const _ApplicationDetailSheet({
    required this.application,
    required this.jobStatus,
    required this.onSyncCalendar,
    required this.onOpenMeeting,
  });

  final JobApplication application;
  final String? jobStatus;
  final VoidCallback onSyncCalendar;
  final VoidCallback onOpenMeeting;

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
                    if (application.unitLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        application.unitLabel!,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.grey.shade700),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _StatusChip(status: application.status),
                    if (_isClosed(jobStatus)) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.work_off_outlined,
                              color: Color(0xFFB91C1C),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Lowongan ini sudah ditutup oleh recruiter. Anda masih bisa melihat riwayat lamaran di sini.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFFB91C1C),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                    if ((application.interviewDurationMinutes ?? 0) > 0)
                      _DetailRow(
                        label: 'Durasi interview',
                        value: '${application.interviewDurationMinutes} menit',
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
                    _TimelineSection(application: application),
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
                    if ((application.recruiterNotes ?? '').isNotEmpty) ...[
                      Text(
                        'Catatan Recruiter',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          application.recruiterNotes!,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(height: 1.5),
                        ),
                      ),
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
                      if ((application.meetingUrl ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.video_camera_front_outlined,
                            ),
                            title: const Text('Google Meet'),
                            subtitle: Text(application.meetingUrl!),
                            trailing: const Icon(Icons.open_in_new),
                            onTap: onOpenMeeting,
                          ),
                        ),
                      ],
                      if ((application.interviewNotes ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.notes_outlined),
                            title: const Text('Catatan Interview'),
                            subtitle: Text(application.interviewNotes!),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: onSyncCalendar,
                            icon: Icon(
                              application.isSyncedToCandidateCalendar
                                  ? Icons.cloud_done_outlined
                                  : Icons.calendar_month_outlined,
                            ),
                            label: Text(
                              application.isSyncedToCandidateCalendar
                                  ? 'Update di Google Calendar'
                                  : 'Tambah ke Google Calendar',
                            ),
                          ),
                          if ((application.meetingUrl ?? '').isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: onOpenMeeting,
                              icon: const Icon(
                                Icons.video_camera_front_outlined,
                              ),
                              label: const Text('Buka Google Meet'),
                            ),
                        ],
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

  bool _isClosed(String? status) {
    if (status == null) return false;
    final normalized = status.toLowerCase();
    return normalized == 'closed' || normalized == 'ditutup';
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

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String title, String subtitle})>[
      (
        icon: Icons.send,
        title: 'Lamaran dikirim',
        subtitle: DateFormat('d MMM yyyy, HH:mm').format(application.appliedAt),
      ),
      (
        icon: Icons.sync,
        title: 'Status saat ini: ${_statusLabel(application.status)}',
        subtitle: DateFormat('d MMM yyyy, HH:mm').format(application.updatedAt),
      ),
      if (application.interviewDates?.isNotEmpty == true)
        (
          icon: Icons.event_available,
          title: 'Interview terjadwal',
          subtitle: application.interviewDates!
              .map((date) => DateFormat('d MMM yyyy, HH:mm').format(date))
              .join(' • '),
        ),
      if ((application.rejectionReason ?? '').isNotEmpty)
        (
          icon: Icons.info_outline,
          title: 'Alasan penolakan',
          subtitle: application.rejectionReason!,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timeline Lamaran',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    size: 18,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _statusLabel(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.applied:
        return 'Terkirim';
      case ApplicationStatus.screening:
        return 'Screening';
      case ApplicationStatus.interview:
        return 'Interview';
      case ApplicationStatus.underReview:
        return 'Direview';
      case ApplicationStatus.offered:
        return 'Ditawarkan';
      case ApplicationStatus.rejected:
        return 'Ditolak';
      case ApplicationStatus.withdrawn:
        return 'Ditarik';
      case ApplicationStatus.archived:
        return 'Diarsipkan';
    }
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
      ('screening', 'Screening'),
      ('underReview', 'Direview'),
      ('interview', 'Interview'),
      ('offered', 'Ditawarkan'),
      ('withdrawn', 'Ditarik'),
      ('archived', 'Diarsipkan'),
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
