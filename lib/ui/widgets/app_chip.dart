import 'package:flutter/material.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_border_radius.dart';
import '../design_system/app_colors.dart';

/// Consistent chip/tag component that enforces the design system
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.onDeleted,
    this.selected = false,
    this.variant = AppChipVariant.default_,
    this.size = AppChipSize.medium,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final bool selected;
  final AppChipVariant variant;
  final AppChipSize size;

  @override
  Widget build(BuildContext context) {
    final chip = switch (variant) {
      AppChipVariant.default_ => _buildDefaultChip(context),
      AppChipVariant.filter => _buildFilterChip(context),
      AppChipVariant.suggestion => _buildSuggestionChip(context),
      AppChipVariant.action => _buildActionChip(context),
    };

    return chip;
  }

  Widget _buildDefaultChip(BuildContext context) {
    return Chip(
      label: Text(label),
      avatar: icon != null ? Icon(icon, size: _getIconSize()) : null,
      onDeleted: onDeleted,
      deleteIconColor: AppColors.textSecondary,
      backgroundColor: _getBackgroundColor(),
      padding: _getPadding(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.chipRadius),
      ),
      labelStyle: _getLabelStyle(context),
    );
  }

  Widget _buildFilterChip(BuildContext context) {
    return FilterChip(
      label: Text(label),
      avatar: icon != null ? Icon(icon, size: _getIconSize()) : null,
      onSelected: (value) => onTap?.call(),
      selected: selected,
      checkmarkColor: AppColors.primary,
      backgroundColor: _getBackgroundColor(),
      selectedColor: AppColors.primaryLight,
      padding: _getPadding(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.chipRadius),
        side: selected
            ? const BorderSide(color: AppColors.primary)
            : BorderSide.none,
      ),
      labelStyle: _getLabelStyle(context),
      showCheckmark: false,
    );
  }

  Widget _buildSuggestionChip(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: icon != null ? Icon(icon, size: _getIconSize()) : null,
      onPressed: onTap,
      backgroundColor: _getBackgroundColor(),
      padding: _getPadding(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.chipRadius),
      ),
      labelStyle: _getLabelStyle(context),
    );
  }

  Widget _buildActionChip(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: icon != null ? Icon(icon, size: _getIconSize()) : null,
      onPressed: onTap,
      backgroundColor: _getBackgroundColor(),
      padding: _getPadding(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.chipRadius),
      ),
      labelStyle: _getLabelStyle(context),
    );
  }

  Color _getBackgroundColor() {
    return switch (variant) {
      AppChipVariant.default_ => AppColors.neutral100,
      AppChipVariant.filter => selected
          ? AppColors.primaryLight
          : AppColors.neutral100,
      AppChipVariant.suggestion => AppColors.neutral100,
      AppChipVariant.action => AppColors.neutral100,
    };
  }

  EdgeInsets _getPadding() {
    return switch (size) {
      AppChipSize.small => const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      AppChipSize.medium => const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      };
  }

  double _getIconSize() {
    return switch (size) {
      AppChipSize.small => 14,
      AppChipSize.medium => 16,
    };
  }

  TextStyle _getLabelStyle(BuildContext context) {
    final fontSize = switch (size) {
      AppChipSize.small => 11.0,
      AppChipSize.medium => 12.0,
    };
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: selected ? AppColors.primary : AppColors.textPrimary,
    );
  }
}

enum AppChipVariant { default_, filter, suggestion, action }
enum AppChipSize { small, medium }

/// A pill-shaped status indicator
class AppStatusPill extends StatelessWidget {
  const AppStatusPill({
    super.key,
    required this.label,
    this.status = AppStatusPillStatus.neutral,
    this.icon,
  });

  final String label;
  final AppStatusPillStatus status;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppBorderRadius.statusPillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: colors.foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: TextStyle(
              color: colors.foreground,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  _StatusPillColors _getColors() {
    return switch (status) {
      AppStatusPillStatus.active => _StatusPillColors(
          background: AppColors.statusPublished,
          foreground: AppColors.statusPublishedText,
        ),
      AppStatusPillStatus.success => _StatusPillColors(
          background: AppColors.successLight,
          foreground: AppColors.success,
        ),
      AppStatusPillStatus.warning => _StatusPillColors(
          background: AppColors.warningLight,
          foreground: AppColors.warning,
        ),
      AppStatusPillStatus.error => _StatusPillColors(
          background: AppColors.errorLight,
          foreground: AppColors.error,
        ),
      AppStatusPillStatus.neutral => _StatusPillColors(
          background: AppColors.neutral100,
          foreground: AppColors.neutral700,
        ),
    };
  }
}

enum AppStatusPillStatus { active, success, warning, error, neutral }

class _StatusPillColors {
  final Color background;
  final Color foreground;

  _StatusPillColors({required this.background, required this.foreground});
}
