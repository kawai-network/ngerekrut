import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_border_radius.dart';

/// Skeleton loader for job listing cards
class SkeletonJobCard extends StatelessWidget {
  const SkeletonJobCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.neutral100,
      highlightColor: AppColors.neutral300,
      period: const Duration(milliseconds: 1200),
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and bookmark icon
              Row(
                children: [
                  Expanded(
                    child: _buildSkeleton(width: 200, height: 18),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _buildCircularSkeleton(),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Subtitle
              _buildSkeleton(width: 150, height: 14),
              const SizedBox(height: AppSpacing.md),
              // Location icon and text
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.neutral400,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _buildSkeleton(width: 100, height: 12),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Description
              _buildSkeleton(width: double.infinity, height: 12),
              const SizedBox(height: AppSpacing.xs),
              _buildSkeleton(width: double.infinity, height: 12),
              const SizedBox(height: AppSpacing.sm),
              _buildSkeleton(width: 200, height: 12),
              const SizedBox(height: AppSpacing.md),
              // Chips
              Row(
                children: [
                  _buildChipSkeleton(),
                  const SizedBox(width: AppSpacing.sm),
                  _buildChipSkeleton(),
                  const SizedBox(width: AppSpacing.sm),
                  _buildChipSkeleton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
      ),
    );
  }

  Widget _buildCircularSkeleton() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildChipSkeleton() {
    return Container(
      width: 80,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.chipRadius),
      ),
    );
  }
}

/// Horizontal scrollable skeleton for job cards
class SkeletonJobList extends StatelessWidget {
  const SkeletonJobList({
    super.key,
    this.itemCount = 3,
    this.padding = AppSpacing.screenPadding,
  });

  final int itemCount;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) => const SkeletonJobCard(),
    );
  }
}

/// Horizontal skeleton for recommended jobs
class SkeletonRecommendedJobCard extends StatelessWidget {
  const SkeletonRecommendedJobCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.neutral100,
      highlightColor: AppColors.neutral300,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Match score chip
                Row(
                  children: [
                    _buildChipSkeleton(),
                    const Spacer(),
                    _buildCircularSkeleton(),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Title
                _buildSkeleton(width: double.infinity, height: 16),
                const SizedBox(height: AppSpacing.xs),
                // Subtitle
                _buildSkeleton(width: 120, height: 12),
                const SizedBox(height: AppSpacing.sm),
                // Location
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.neutral400,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _buildSkeleton(width: 80, height: 12),
                  ],
                ),
                const Spacer(),
                // Matching skills section
                _buildSkeleton(width: 100, height: 10),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    _buildSmallChipSkeleton(),
                    _buildSmallChipSkeleton(),
                    _buildSmallChipSkeleton(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
      ),
    );
  }

  Widget _buildCircularSkeleton() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildChipSkeleton() {
    return Container(
      width: 60,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.pill),
      ),
    );
  }

  Widget _buildSmallChipSkeleton() {
    return Container(
      width: 50,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
      ),
    );
  }
}
