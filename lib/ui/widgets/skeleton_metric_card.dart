import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_border_radius.dart';

/// Skeleton loader for dashboard metric cards
class SkeletonMetricCard extends StatelessWidget {
  const SkeletonMetricCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.neutral100,
      highlightColor: AppColors.neutral300,
      period: const Duration(milliseconds: 1200),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          border: Border.all(color: AppColors.neutral300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon placeholder
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppBorderRadius.small),
              ),
            ),
            const Spacer(),
            // Value placeholder
            Container(
              width: 80,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppBorderRadius.small),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Label placeholder
            Container(
              width: 100,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppBorderRadius.small),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Helper placeholder
            Container(
              width: 120,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppBorderRadius.small),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid of skeleton metric cards
class SkeletonMetricGrid extends StatelessWidget {
  const SkeletonMetricGrid({
    super.key,
    this.crossAxisCount = 2,
    this.itemCount = 4,
  });

  final int crossAxisCount;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.4,
      children: List.generate(
        itemCount,
        (index) => const SkeletonMetricCard(),
      ),
    );
  }
}

/// Skeleton for priority cards
class SkeletonPriorityCard extends StatelessWidget {
  const SkeletonPriorityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.neutral100,
      highlightColor: AppColors.neutral300,
      period: const Duration(milliseconds: 1200),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.neutral50,
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon placeholder
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppBorderRadius.small),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title placeholder
                  Container(
                    width: 150,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppBorderRadius.small),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Description placeholder
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppBorderRadius.small),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    width: 200,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppBorderRadius.small),
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
}

/// Full dashboard skeleton
class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero section placeholder
          Container(
            height: 160,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppBorderRadius.large),
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.white.withValues(alpha: 0.2),
              highlightColor: Colors.white.withValues(alpha: 0.3),
              period: const Duration(milliseconds: 1200),
              child: Container(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Metrics grid
          const SkeletonMetricGrid(),
          const SizedBox(height: AppSpacing.xl),
          // Priority cards
          const SkeletonPriorityCard(),
          const SkeletonPriorityCard(),
          const SkeletonPriorityCard(),
        ],
      ),
    );
  }
}
