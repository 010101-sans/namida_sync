import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../utils/utils.dart';

class StatusMessage extends StatelessWidget {
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final Color backgroundColor;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const StatusMessage({
    super.key,
    this.icon,
    this.title,
    this.subtitle,
    required this.backgroundColor,
    required this.iconColor,
    required this.titleColor,
    required this.subtitleColor,
    this.padding,
    this.borderRadius,
  });

  // Factory constructors for common message types
  
  factory StatusMessage.success({
    String? title,
    String? subtitle,
    IconData? icon,
  }) {
    return StatusMessage(
      icon: icon ?? Iconsax.tick_circle,
      title: title,
      subtitle: subtitle,
      backgroundColor: AppColors.successGreen.withValues(alpha: 0.1),
      iconColor: AppColors.successGreen,
      titleColor: AppColors.successGreen,
      subtitleColor: AppColors.successGreen,
    );
  }

  factory StatusMessage.error({
    String? title,
    String? subtitle,
    IconData? icon,
  }) {
    return StatusMessage(
      icon: icon ?? Iconsax.close_circle,
      title: title,
      subtitle: subtitle,
      backgroundColor: AppColors.errorRed.withValues(alpha: 0.1),
      iconColor: AppColors.errorRed,
      titleColor: AppColors.errorRed,
      subtitleColor: AppColors.errorRed,
    );
  }

  factory StatusMessage.warning({
    String? title,
    String? subtitle,
    IconData? icon,
  }) {
    return StatusMessage(
      icon: icon ?? Iconsax.warning_2,
      title: title,
      subtitle: subtitle,
      backgroundColor: AppColors.warningOrange.withValues(alpha: 0.1),
      iconColor: AppColors.warningOrange,
      titleColor: AppColors.warningOrange,
      subtitleColor: AppColors.warningOrange,
    );
  }

  factory StatusMessage.info({
    String? title,
    String? subtitle,
    IconData? icon,
    Color? primaryColor,
  }) {
    final color = primaryColor ?? AppColors.accentPurple;
    return StatusMessage(
      icon: icon ?? Iconsax.info_circle,
      title: title,
      subtitle: subtitle,
      backgroundColor: color.withValues(alpha: 0.05),
      iconColor: color,
      titleColor: color,
      subtitleColor: color,
    );
  }

  factory StatusMessage.loading({
    String? title,
    String? subtitle,
  }) {
    return StatusMessage(
      icon: Iconsax.refresh,
      title: title,
      subtitle: subtitle,
      backgroundColor: AppColors.accentPurple.withValues(alpha: 0.05),
      iconColor: AppColors.accentPurple,
      titleColor: AppColors.accentPurple,
      subtitleColor: AppColors.accentPurple,
    );
  }

  factory StatusMessage.neutral({
    String? title,
    String? subtitle,
    IconData? icon,
  }) {
    return StatusMessage(
      icon: icon ?? Iconsax.info_circle,
      title: title,
      subtitle: subtitle,
      backgroundColor: Colors.grey.withValues(alpha: 0.05),
      iconColor: Colors.grey,
      titleColor: Colors.grey,
      subtitleColor: Colors.grey,
    );
  }

  factory StatusMessage.folder({
    String? title,
    String? subtitle,
    bool isValid = true,
  }) {
    final color = isValid ? AppColors.successGreen : AppColors.errorRed;
    final icon = isValid ? Iconsax.folder_open : Iconsax.folder_cross;
    return StatusMessage(
      icon: icon,
      title: title,
      subtitle: subtitle,
      backgroundColor: color.withValues(alpha: 0.05),
      iconColor: color,
      titleColor: color,
      subtitleColor: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                if (title != null && subtitle != null)
                  const SizedBox(height: 4),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: subtitleColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 