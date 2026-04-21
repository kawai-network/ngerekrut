library;

import 'package:flutter/material.dart';

import '../models/application_status.dart';
import '../models/candidate.dart';
import '../models/job_application.dart';
import '../repositories/job_application_repository.dart';

class RecruiterCandidateProfileScreen extends StatelessWidget {
  const RecruiterCandidateProfileScreen({super.key, required this.candidate});

  final RecruiterCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final applicationRepository = JobApplicationRepository();
    return Scaffold(
      appBar: AppBar(title: Text(candidate.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if ((candidate.headline ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    candidate.headline!,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _CandidateProfileMetric(
                      label: 'Stage',
                      value: candidate.stage,
                    ),
                    _CandidateProfileMetric(
                      label: 'Pengalaman',
                      value: '${candidate.yearsOfExperience ?? 0} tahun',
                    ),
                    if (candidate.resume != null)
                      _CandidateProfileMetric(
                        label: 'Resume',
                        value: candidate.resume!.fileName,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CandidateProfileSection(
            title: 'Ringkasan',
            child: Text(
              candidate.profile?.summary.isNotEmpty == true
                  ? candidate.profile!.summary
                  : 'Belum ada ringkasan profil kandidat.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          _CandidateProfileSection(
            title: 'Skill utama',
            child: candidate.profile?.skills.isNotEmpty == true
                ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: candidate.profile!.skills
                        .map((skill) => Chip(label: Text(skill)))
                        .toList(),
                  )
                : const Text('Belum ada skill yang tersimpan.'),
          ),
          const SizedBox(height: 16),
          _CandidateProfileSection(
            title: 'Metadata',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CandidateProfileRow(label: 'ID kandidat', value: candidate.id),
                _CandidateProfileRow(label: 'Stage', value: candidate.stage),
                _CandidateProfileRow(
                  label: 'Pengalaman',
                  value: '${candidate.yearsOfExperience ?? 0} tahun',
                ),
                if (candidate.resume != null)
                  _CandidateProfileRow(
                    label: 'Resume',
                    value: candidate.resume!.fileName,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CandidateProfileSection(
            title: 'Riwayat Lamaran',
            child: FutureBuilder<List<JobApplication>>(
              future: applicationRepository.getByCandidateId(candidate.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final applications = snapshot.data ?? const <JobApplication>[];
                if (applications.isEmpty) {
                  return const Text(
                    'Belum ada riwayat lamaran yang tersimpan untuk kandidat ini.',
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: applications
                      .map(
                        (application) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CandidateApplicationHistoryCard(
                            application: application,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateApplicationHistoryCard extends StatelessWidget {
  const _CandidateApplicationHistoryCard({required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.jobTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if ((application.unitLabel ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        application.unitLabel!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _ApplicationStatusPill(status: application.status),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _ApplicationMetaText(
                icon: Icons.calendar_today_outlined,
                label: 'Dilamar ${_formatRelativeDate(application.appliedAt)}',
              ),
              if (application.interviewDates?.isNotEmpty == true)
                _ApplicationMetaText(
                  icon: Icons.event_available,
                  label:
                      'Interview ${_formatScheduleDate(application.interviewDates!.last)}',
                ),
            ],
          ),
          if ((application.recruiterNotes ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              application.recruiterNotes!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CandidateProfileMetric extends StatelessWidget {
  const _CandidateProfileMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateProfileSection extends StatelessWidget {
  const _CandidateProfileSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CandidateProfileRow extends StatelessWidget {
  const _CandidateProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ApplicationStatusPill extends StatelessWidget {
  const _ApplicationStatusPill({required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final background = switch (status) {
      ApplicationStatus.applied => const Color(0xFFDBEAFE),
      ApplicationStatus.screening => const Color(0xFFFEF3C7),
      ApplicationStatus.interview => const Color(0xFFE0E7FF),
      ApplicationStatus.underReview => const Color(0xFFF3E8FF),
      ApplicationStatus.offered => const Color(0xFFDCFCE7),
      ApplicationStatus.rejected ||
      ApplicationStatus.withdrawn ||
      ApplicationStatus.archived => const Color(0xFFF3F4F6),
    };
    final foreground = switch (status) {
      ApplicationStatus.applied => const Color(0xFF1D4ED8),
      ApplicationStatus.screening => const Color(0xFFB45309),
      ApplicationStatus.interview => const Color(0xFF4338CA),
      ApplicationStatus.underReview => const Color(0xFF6D28D9),
      ApplicationStatus.offered => const Color(0xFF166534),
      ApplicationStatus.rejected ||
      ApplicationStatus.withdrawn ||
      ApplicationStatus.archived => const Color(0xFF4B5563),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ApplicationMetaText extends StatelessWidget {
  const _ApplicationMetaText({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

String _formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);
  if (difference.inDays == 0) return 'hari ini';
  if (difference.inDays == 1) return 'kemarin';
  if (difference.inDays < 7) return '${difference.inDays} hari lalu';
  return '${date.day}/${date.month}/${date.year}';
}

String _formatScheduleDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final targetDay = DateTime(date.year, date.month, date.day);
  final dayDifference = targetDay.difference(today).inDays;
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  final timeLabel = '$hour:$minute';

  if (dayDifference == 0) return 'hari ini • $timeLabel';
  if (dayDifference == 1) return 'besok • $timeLabel';
  if (dayDifference > 1 && dayDifference < 7) {
    return '$dayDifference hari lagi • $timeLabel';
  }

  return '${date.day}/${date.month}/${date.year} • $timeLabel';
}
