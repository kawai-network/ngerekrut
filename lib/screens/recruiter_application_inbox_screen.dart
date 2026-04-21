library;

import 'package:flutter/material.dart';

import '../models/application_status.dart';
import '../models/candidate.dart';
import '../models/job_application.dart';
import '../repositories/candidate_repository.dart';
import '../repositories/job_application_repository.dart';

class RecruiterApplicationInboxScreen extends StatefulWidget {
  const RecruiterApplicationInboxScreen({super.key});

  @override
  State<RecruiterApplicationInboxScreen> createState() =>
      _RecruiterApplicationInboxScreenState();
}

class _RecruiterApplicationInboxScreenState
    extends State<RecruiterApplicationInboxScreen> {
  final JobApplicationRepository _applicationRepository =
      JobApplicationRepository();
  final CandidateRepository _candidateRepository = CandidateRepository();

  bool _isLoading = true;
  String _statusFilter = 'all';
  String _searchQuery = '';
  String? _updatingApplicationId;
  List<JobApplication> _applications = const [];
  Map<String, RecruiterCandidate> _candidatesById = const {};

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    try {
      final applications = await _applicationRepository.getAll();
      final candidateIds = applications
          .map((application) => application.candidateId)
          .whereType<String>()
          .toSet()
          .toList();
      final candidates = await Future.wait(
        candidateIds.map(_candidateRepository.getById),
      );

      if (!mounted) return;
      setState(() {
        _applications = applications;
        _candidatesById = {
          for (final candidate in candidates.whereType<RecruiterCandidate>())
            candidate.id: candidate,
        };
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat inbox lamaran: $e')));
    }
  }

  Future<void> _updateApplicationStatus(
    JobApplication application,
    ApplicationStatus nextStatus,
  ) async {
    String? rejectionReason;
    if (nextStatus == ApplicationStatus.rejected) {
      rejectionReason = await _askRejectionReason();
      if (rejectionReason == null) return;
    }

    setState(() => _updatingApplicationId = application.id);
    try {
      await _applicationRepository.updateStatus(
        application.id,
        nextStatus,
        rejectionReason: rejectionReason,
      );
      await _loadApplications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status ${_candidateLabel(application)} diperbarui ke ${nextStatus.displayName}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memperbarui status: $e')));
    } finally {
      if (mounted) {
        setState(() => _updatingApplicationId = null);
      }
    }
  }

  Future<String?> _askRejectionReason() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Alasan penolakan'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Tulis alasan singkat untuk kandidat',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (reason == null) return null;
    return reason.isEmpty ? 'Tidak melanjutkan ke tahap berikutnya.' : reason;
  }

  Future<void> _saveRecruiterNotes(JobApplication application) async {
    final controller = TextEditingController(text: application.recruiterNotes);
    final notes = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Recruiter Notes'),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Tulis catatan internal untuk lamaran ini',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (notes == null) return;

    setState(() => _updatingApplicationId = application.id);
    try {
      await _applicationRepository.updateRecruiterNotes(application.id, notes);
      await _loadApplications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recruiter notes diperbarui.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan notes: $e')));
    } finally {
      if (mounted) {
        setState(() => _updatingApplicationId = null);
      }
    }
  }

  Future<void> _setInternalRating(JobApplication application) async {
    final rating = await showDialog<int>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Internal Rating'),
          children: List.generate(5, (index) {
            final value = index + 1;
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, value),
              child: Row(
                children: [
                  Text('$value'),
                  const SizedBox(width: 12),
                  ...List.generate(
                    value,
                    (_) => const Icon(
                      Icons.star,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
    if (rating == null) return;

    setState(() => _updatingApplicationId = application.id);
    try {
      await _applicationRepository.setInternalRating(application.id, rating);
      await _loadApplications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rating internal diset ke $rating.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan rating: $e')));
    } finally {
      if (mounted) {
        setState(() => _updatingApplicationId = null);
      }
    }
  }

  Future<void> _addInterviewSchedule(JobApplication application) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null || !mounted) return;

    final schedule = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() => _updatingApplicationId = application.id);
    try {
      await _applicationRepository.addInterviewDate(application.id, schedule);
      if (application.status != ApplicationStatus.interview) {
        await _applicationRepository.updateStatus(
          application.id,
          ApplicationStatus.interview,
        );
      }
      await _loadApplications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal interview ditambahkan.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambah jadwal interview: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingApplicationId = null);
      }
    }
  }

  List<JobApplication> get _filteredApplications {
    return _applications.where((application) {
      if (_statusFilter != 'all' && application.status.name != _statusFilter) {
        return false;
      }

      if (_searchQuery.isEmpty) return true;
      final candidate = application.candidateId != null
          ? _candidatesById[application.candidateId!]
          : null;
      final haystack = [
        application.jobTitle,
        application.company,
        application.candidateId,
        candidate?.name,
        candidate?.headline,
      ].whereType<String>().join(' ').toLowerCase();

      return haystack.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  int _countForStatus(String status) {
    if (status == 'all') return _applications.length;
    return _applications.where((app) => app.status.name == status).length;
  }

  String _candidateLabel(JobApplication application) {
    final candidate = application.candidateId != null
        ? _candidatesById[application.candidateId!]
        : null;
    return candidate?.name ?? application.candidateId ?? application.id;
  }

  @override
  Widget build(BuildContext context) {
    final activeApplications = _applications
        .where((application) => application.status.isActive)
        .length;
    final interviewApplications = _applications
        .where(
          (application) => application.status == ApplicationStatus.interview,
        )
        .length;

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF111827), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inbox lamaran lintas lowongan',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pantau semua lamaran masuk dari satu tempat, lalu prioritaskan kandidat yang perlu tindakan berikutnya.',
                  style: TextStyle(color: Colors.white70, height: 1.45),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const LinearProgressIndicator(
                    minHeight: 4,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _InboxMetric(
                        label: 'Total lamaran',
                        value: '${_applications.length}',
                      ),
                      _InboxMetric(
                        label: 'Masih aktif',
                        value: '$activeApplications',
                      ),
                      _InboxMetric(
                        label: 'Tahap interview',
                        value: '$interviewApplications',
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Cari kandidat atau lowongan',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('all', 'Semua'),
              _buildFilterChip(ApplicationStatus.applied.name, 'Applied'),
              _buildFilterChip(ApplicationStatus.screening.name, 'Screening'),
              _buildFilterChip(ApplicationStatus.interview.name, 'Interview'),
              _buildFilterChip(
                ApplicationStatus.underReview.name,
                'Under Review',
              ),
              _buildFilterChip(ApplicationStatus.offered.name, 'Offered'),
              _buildFilterChip(ApplicationStatus.rejected.name, 'Rejected'),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_applications.isEmpty)
            const _InboxEmptyState(
              title: 'Belum ada lamaran',
              description:
                  'Lamaran dari jobseeker akan muncul di sini setelah posisi mulai dilamar.',
            )
          else if (_filteredApplications.isEmpty)
            const _InboxEmptyState(
              title: 'Tidak ada hasil',
              description:
                  'Coba ubah filter atau kata kunci pencarian untuk melihat lamaran lain.',
            )
          else
            ..._filteredApplications.map((application) {
              final candidate = application.candidateId != null
                  ? _candidatesById[application.candidateId!]
                  : null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _InboxApplicationCard(
                  application: application,
                  candidate: candidate,
                  isUpdating: _updatingApplicationId == application.id,
                  onStatusSelected: (status) =>
                      _updateApplicationStatus(application, status),
                  onEditNotes: () => _saveRecruiterNotes(application),
                  onSetRating: () => _setInternalRating(application),
                  onAddInterviewDate: () => _addInterviewSchedule(application),
                  onTap: () => _showDetails(application, candidate),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showDetails(JobApplication application, RecruiterCandidate? candidate) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _InboxApplicationDetailSheet(
          application: application,
          candidate: candidate,
        );
      },
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _statusFilter == value;
    final count = _countForStatus(value);
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      label: Text('$label $count'),
      selectedColor: const Color(0xFFDBEAFE),
      side: BorderSide(
        color: isSelected ? const Color(0xFF93C5FD) : const Color(0xFFE5E7EB),
      ),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: isSelected ? const Color(0xFF1D4ED8) : null,
      ),
      onSelected: (_) => setState(() => _statusFilter = value),
    );
  }
}

class _InboxMetric extends StatelessWidget {
  const _InboxMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
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

class _InboxApplicationCard extends StatelessWidget {
  const _InboxApplicationCard({
    required this.application,
    required this.candidate,
    required this.isUpdating,
    required this.onStatusSelected,
    required this.onEditNotes,
    required this.onSetRating,
    required this.onAddInterviewDate,
    required this.onTap,
  });

  final JobApplication application;
  final RecruiterCandidate? candidate;
  final bool isUpdating;
  final ValueChanged<ApplicationStatus> onStatusSelected;
  final VoidCallback onEditNotes;
  final VoidCallback onSetRating;
  final VoidCallback onAddInterviewDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final candidateName =
        candidate?.name ?? application.candidateId ?? 'Kandidat tanpa ID';
    final subtitle = [
      if ((candidate?.headline ?? '').isNotEmpty) candidate!.headline!,
      if ((application.company ?? '').isNotEmpty) application.company!,
    ].join(' • ');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                          candidateName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          application.jobTitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _InboxStatusPill(status: application.status),
                  const SizedBox(width: 4),
                  PopupMenuButton<ApplicationStatus>(
                    enabled: !isUpdating,
                    tooltip: 'Ubah status lamaran',
                    onSelected: onStatusSelected,
                    itemBuilder: (context) {
                      return ApplicationStatus.values
                          .where((status) => status != application.status)
                          .map((status) {
                            return PopupMenuItem<ApplicationStatus>(
                              value: status,
                              child: Text(status.displayName),
                            );
                          })
                          .toList();
                    },
                    icon: isUpdating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.more_horiz),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _InboxMetaText(
                    icon: Icons.calendar_today_outlined,
                    label:
                        'Dilamar ${_formatRelativeDate(application.appliedAt)}',
                  ),
                  if ((application.expectedSalary ?? '').isNotEmpty)
                    _InboxMetaText(
                      icon: Icons.payments_outlined,
                      label: application.expectedSalary!,
                    ),
                  if (application.interviewDates?.isNotEmpty == true)
                    _InboxMetaText(
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: isUpdating ? null : onEditNotes,
                    icon: const Icon(Icons.note_alt_outlined),
                    label: const Text('Notes'),
                  ),
                  OutlinedButton.icon(
                    onPressed: isUpdating ? null : onSetRating,
                    icon: const Icon(Icons.star_outline),
                    label: const Text('Rating'),
                  ),
                  OutlinedButton.icon(
                    onPressed: isUpdating ? null : onAddInterviewDate,
                    icon: const Icon(Icons.event_available),
                    label: const Text('Jadwal'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InboxMetaText extends StatelessWidget {
  const _InboxMetaText({required this.icon, required this.label});

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

class _InboxApplicationDetailSheet extends StatelessWidget {
  const _InboxApplicationDetailSheet({
    required this.application,
    required this.candidate,
  });

  final JobApplication application;
  final RecruiterCandidate? candidate;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                candidate?.name ?? application.candidateId ?? 'Kandidat',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                application.jobTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _InboxStatusPill(status: application.status),
              if ((candidate?.headline ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  candidate!.headline!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
              if (candidate?.profile?.skills.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: candidate!.profile!.skills
                      .map(
                        (skill) => Chip(
                          label: Text(skill),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
              if ((candidate?.profile?.summary ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  candidate!.profile!.summary,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
              const SizedBox(height: 16),
              if ((application.coverLetter ?? '').isNotEmpty) ...[
                Text(
                  'Cover letter',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  application.coverLetter!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 16),
              ],
              if ((application.recruiterNotes ?? '').isNotEmpty) ...[
                Text(
                  'Recruiter notes',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(application.recruiterNotes!),
                const SizedBox(height: 16),
              ],
              if (application.interviewDates?.isNotEmpty == true) ...[
                Text(
                  'Jadwal interview',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ...application.interviewDates!.map(
                  (date) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(_formatScheduleDate(date)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Metadata lamaran',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              _DetailRow(
                label: 'Dilamar',
                value: _formatFullDate(application.appliedAt),
              ),
              if ((application.expectedSalary ?? '').isNotEmpty)
                _DetailRow(
                  label: 'Ekspektasi gaji',
                  value: application.expectedSalary!,
                ),
              if ((application.company ?? '').isNotEmpty)
                _DetailRow(label: 'Unit', value: application.company!),
              if (application.internalRating != null)
                _DetailRow(
                  label: 'Internal rating',
                  value: '${application.internalRating}/5',
                ),
              if ((application.rejectionReason ?? '').isNotEmpty)
                _DetailRow(
                  label: 'Alasan reject',
                  value: application.rejectionReason!,
                ),
            ],
          ),
        ),
      ),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

class _InboxEmptyState extends StatelessWidget {
  const _InboxEmptyState({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxStatusPill extends StatelessWidget {
  const _InboxStatusPill({required this.status});

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

String _formatFullDate(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day}/${date.month}/${date.year} • $hour:$minute';
}
