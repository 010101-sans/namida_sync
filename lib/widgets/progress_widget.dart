import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../utils/utils.dart';

class ProgressWidget extends StatelessWidget {
  final double progress;
  final String? title;
  final String? subtitle;
  final String? statusText;
  final Color? progressColor;
  final Color? backgroundColor;
  final bool showPercentage;
  final bool showCancelButton;
  final VoidCallback? onCancel;
  final bool isIndeterminate;

  const ProgressWidget({
    super.key,
    required this.progress,
    this.title,
    this.subtitle,
    this.statusText,
    this.progressColor,
    this.backgroundColor,
    this.showPercentage = true,
    this.showCancelButton = false,
    this.onCancel,
    this.isIndeterminate = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveProgressColor = progressColor ?? colorScheme.primary;
    final effectiveBackgroundColor = backgroundColor ?? colorScheme.surface.withValues(alpha: 0.1);

    return Container(
      padding: UIConstants.paddingM,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: UIConstants.borderRadiusL,
        border: Border.all(
          color: effectiveProgressColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              if (title != null) ...[
                Expanded(
                  child: Text(
                    title!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (showCancelButton && onCancel != null) ...[
                  IconButton(
                    icon: Icon(Iconsax.close_circle, size: 20),
                    color: colorScheme.error,
                    onPressed: onCancel,
                    tooltip: 'Cancel',
                  ),
                ],
              ],
            ],
          ),

          // Subtitle
          if (subtitle != null) ...[
            const SizedBox(height: UIConstants.spacingS),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],

          // Progress Bar
          const SizedBox(height: UIConstants.spacingM),
          Stack(
            children: [
              // Background
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Progress
              AnimatedContainer(
                duration: UIConstants.animationNormal,
                height: 8,
                width: isIndeterminate 
                    ? null 
                    : MediaQuery.of(context).size.width * progress,
                decoration: BoxDecoration(
                  color: effectiveProgressColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),

          // Status Row
          const SizedBox(height: UIConstants.spacingS),
          Row(
            children: [
              if (showPercentage && !isIndeterminate) ...[
                Text(
                  '${(progress * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: effectiveProgressColor,
                  ),
                ),
              ],
              if (isIndeterminate) ...[
                Text(
                  'Processing...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: effectiveProgressColor,
                  ),
                ),
              ],
              const Spacer(),
              if (statusText != null)
                Text(
                  statusText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// Specialized progress widgets for common use cases
class FileProgressWidget extends StatelessWidget {
  final String fileName;
  final double progress;
  final String? statusText;
  final VoidCallback? onCancel;

  const FileProgressWidget({
    super.key,
    required this.fileName,
    required this.progress,
    this.statusText,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return ProgressWidget(
      progress: progress,
      title: fileName,
      subtitle: 'File transfer in progress',
      statusText: statusText,
      showCancelButton: onCancel != null,
      onCancel: onCancel,
    );
  }
}

class BackupProgressWidget extends StatelessWidget {
  final double progress;
  final String? statusText;
  final VoidCallback? onCancel;

  const BackupProgressWidget({
    super.key,
    required this.progress,
    this.statusText,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return ProgressWidget(
      progress: progress,
      title: 'Backup Progress',
      subtitle: 'Creating backup archive',
      statusText: statusText,
      progressColor: AppColors.successGreen,
      showCancelButton: onCancel != null,
      onCancel: onCancel,
    );
  }
} 