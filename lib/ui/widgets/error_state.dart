import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_border_radius.dart';
import '../design_system/app_text_styles.dart';
import 'app_button.dart';

/// Consistent error state component with retry functionality
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.title,
    this.description,
    this.error,
    this.retryLabel = 'Coba Lagi',
    this.onRetry,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.showDebugInfo = false,
  });

  final String title;
  final String? description;
  final dynamic error;
  final String retryLabel;
  final VoidCallback? onRetry;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool showDebugInfo;

  @override
  Widget build(BuildContext context) {
    final errorMessage = _getErrorMessage();

    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
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
            if (description != null || errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                description ?? errorMessage!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (showDebugInfo && error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(AppBorderRadius.small),
                ),
                child: Text(
                  error.toString(),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: retryLabel,
                onPressed: onRetry,
                variant: AppButtonVariant.primary,
              ),
            ],
            if (onSecondaryAction != null) ...[
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

  String? _getErrorMessage() {
    if (error == null) return null;

    // Parse common error types and return user-friendly messages
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection')) {
      return 'Koneksi internet terputus. Periksa WiFi/data Anda.';
    }
    if (errorString.contains('timeout')) {
      return 'Waktu habis. Server terlalu lama merespons.';
    }
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Sesi Anda telah berakhir. Silakan login kembali.';
    }
    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'Anda tidak memiliki izin untuk aksi ini.';
    }
    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'Data tidak ditemukan. Mungkin sudah dihapus.';
    }
    if (errorString.contains('500') || errorString.contains('server')) {
      return 'Server sedang bermasalah. Coba lagi nanti.';
    }

    return null; // Use the description instead
  }
}

/// Network-specific error state
class NetworkErrorState extends StatelessWidget {
  const NetworkErrorState({
    super.key,
    this.onRetry,
    this.onSettings,
  });

  final VoidCallback? onRetry;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    return AppErrorState(
      title: 'Koneksi Bermasalah',
      description: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      retryLabel: 'Coba Lagi',
      onRetry: onRetry,
      secondaryActionLabel: 'Pengaturan',
      onSecondaryAction: onSettings,
    );
  }
}

/// Inline error card for use within forms or cards
class AppInlineError extends StatelessWidget {
  const AppInlineError({
    super.key,
    required this.message,
    this.onDismiss,
  });

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(
                Icons.close,
                color: AppColors.error,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}

/// Validation error for form fields
class AppValidationError extends StatelessWidget {
  const AppValidationError({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.md, top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error,
            color: AppColors.error,
            size: 12,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
