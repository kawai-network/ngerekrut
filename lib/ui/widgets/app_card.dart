import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_border_radius.dart';

/// Consistent card component that enforces the design system
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.child,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.footer,
    this.actions,
    this.backgroundColor,
    this.elevation = 1,
    this.padding = AppSpacing.cardPadding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
  });

  final Widget? child;
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? footer;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final double elevation;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius =
        borderRadius ?? AppBorderRadius.cardRadius;

    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null || subtitle != null || leading != null || trailing != null)
          _buildHeader(),
        if (child != null) ...[
          if (title != null || subtitle != null) const SizedBox(height: AppSpacing.md),
          child!,
        ],
        if (footer != null) ...[
          if (child != null) const SizedBox(height: AppSpacing.md),
          footer!,
        ],
        if (actions != null && actions!.isNotEmpty) ...[
          if (child != null || footer != null) const SizedBox(height: AppSpacing.md),
          _buildActions(),
        ],
      ],
    );

    final card = Card(
      elevation: elevation,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
      ),
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: padding,
        child: cardContent,
      ),
    );

    if (onTap != null || onLongPress != null) {
      return InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        child: card,
      );
    }

    return card;
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Text(
                  title!,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: actions!
          .map(
            (action) => Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: action,
            ),
          )
          .toList(),
    );
  }
}

/// A metric card for displaying statistics
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.helper,
    this.icon,
    this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final String? helper;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Icon(
              icon,
              color: color ?? AppColors.primary,
              size: 24,
            ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (helper != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              helper!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
