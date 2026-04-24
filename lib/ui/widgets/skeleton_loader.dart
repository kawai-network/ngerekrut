import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_border_radius.dart';

/// Generic skeleton card for loading states
class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.neutral100,
      highlightColor: AppColors.neutral300,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: width,
        height: height ?? 16,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            borderRadius ?? AppBorderRadius.small,
          ),
        ),
      ),
    );
  }
}

/// Skeleton card component
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    this.hasHeader = true,
    this.hasSubtitle = true,
    this.hasBody = true,
    this.linesCount = 3,
  });

  final bool hasHeader;
  final bool hasSubtitle;
  final bool hasBody;
  final int linesCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasHeader)
              SkeletonLoader(
                width: double.infinity,
                height: 20,
              ),
            if (hasSubtitle) ...[
              const SizedBox(height: AppSpacing.sm),
              SkeletonLoader(
                width: 150,
                height: 14,
              ),
            ],
            if (hasBody) ...[
              const SizedBox(height: AppSpacing.md),
              ...List.generate(
                linesCount,
                (index) => Padding(
                  padding: EdgeInsets.only(
                    bottom: index < linesCount - 1 ? AppSpacing.sm : 0,
                  ),
                  child: SkeletonLoader(
                    width: index == linesCount - 1
                        ? double.infinity
                        : index % 2 == 0
                            ? double.infinity
                            : 200,
                    height: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
