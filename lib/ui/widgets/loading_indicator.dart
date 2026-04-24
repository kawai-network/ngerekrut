import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_text_styles.dart';

/// Unified loading indicator component
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.size = AppLoadingIndicatorSize.medium,
    this.message,
    this.centered = true,
  });

  final AppLoadingIndicatorSize size;
  final String? message;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final indicator = _buildIndicator();

    if (message != null) {
      final child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      );

      return centered
          ? Center(child: child)
          : child;
    }

    return centered
        ? Center(child: indicator)
        : indicator;
  }

  Widget _buildIndicator() {
    final dimens = _getDimensions();

    return SizedBox(
      width: dimens.size,
      height: dimens.size,
      child: CircularProgressIndicator(
        strokeWidth: dimens.strokeWidth,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  _LoadingIndicatorDimensions _getDimensions() {
    return switch (size) {
      AppLoadingIndicatorSize.small => _LoadingIndicatorDimensions(
          size: 24,
          strokeWidth: 2,
        ),
      AppLoadingIndicatorSize.medium => _LoadingIndicatorDimensions(
          size: 36,
          strokeWidth: 3,
        ),
      AppLoadingIndicatorSize.large => _LoadingIndicatorDimensions(
          size: 48,
          strokeWidth: 4,
        ),
    };
  }
}

enum AppLoadingIndicatorSize { small, medium, large }

class _LoadingIndicatorDimensions {
  final double size;
  final double strokeWidth;

  _LoadingIndicatorDimensions({required this.size, required this.strokeWidth});
}

/// A full-page loading overlay
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    super.key,
    this.message = 'Memuat...',
    this.backgroundColor = Colors.white,
  });

  final String message;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small inline loading indicator
class AppSmallLoadingIndicator extends StatelessWidget {
  const AppSmallLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }
}
