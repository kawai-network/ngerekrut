import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_border_radius.dart';
import '../design_system/app_text_styles.dart';
import 'app_button.dart';

/// Consistent empty state component with optional action
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.illustration,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  final String title;
  final String? description;
  final IconData? icon;
  final Widget? illustration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (illustration != null)
              illustration!
            else if (icon != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: AppColors.neutral500,
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                description!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: AppButtonVariant.primary,
              ),
            ],
            if (secondaryActionLabel != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: secondaryActionLabel!,
                onPressed: onSecondaryAction,
                variant: AppButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Specialized empty state for job listings
class JobEmptyState extends StatelessWidget {
  const JobEmptyState({
    super.key,
    this.onRefresh,
    this.onCreateJob,
  });

  final VoidCallback? onRefresh;
  final VoidCallback? onCreateJob;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.work_outline,
      title: 'Tidak ada lowongan ditemukan',
      description: 'Coba kata kunci atau filter lainnya.',
      actionLabel: 'Refresh',
      onAction: onRefresh,
    );
  }
}

/// Specialized empty state for candidate listings
class CandidateEmptyState extends StatelessWidget {
  const CandidateEmptyState({
    super.key,
    this.onImport,
    this.onCreate,
  });

  final VoidCallback? onImport;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.people_outline,
      title: 'Belum ada kandidat',
      description: 'Mulai dengan menarik data kandidat atau membuat kandidat baru.',
      actionLabel: 'Tarik Kandidat',
      onAction: onImport,
      secondaryActionLabel: 'Buat Manual',
      onSecondaryAction: onCreate,
    );
  }
}

/// Specialized empty state for applications
class ApplicationEmptyState extends StatelessWidget {
  const ApplicationEmptyState({
    super.key,
    this.onBrowseJobs,
  });

  final VoidCallback? onBrowseJobs;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.description_outlined,
      title: 'Belum ada lamaran',
      description: 'Cari lowongan yang sesuai dan mulai melamar sekarang.',
      actionLabel: 'Cari Lowongan',
      onAction: onBrowseJobs,
    );
  }
}

/// Specialized empty state for saved jobs
class SavedJobsEmptyState extends StatelessWidget {
  const SavedJobsEmptyState({
    super.key,
    this.onBrowseJobs,
  });

  final VoidCallback? onBrowseJobs;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.bookmark_border,
      title: 'Belum ada lowongan tersimpan',
      description: 'Simpan lowongan yang menarik agar mudah ditemukan lagi.',
      actionLabel: 'Cari Lowongan',
      onAction: onBrowseJobs,
    );
  }
}
