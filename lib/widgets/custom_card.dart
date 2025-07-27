import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

// [1] A customizable card widget with header, body, footer, and status sections.
class CustomCard extends StatelessWidget {
  final IconData leadingIcon;
  final Color? iconColor;
  final double? iconSize;
  final String title;
  final TextStyle? titleStyle;
  final List<Widget>? headerActions;
  final Widget? body;
  final Widget? footer;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? cardColor;
  final double elevation;
  final BorderRadiusGeometry borderRadius;

  // Status indicator (optional)
  final IconData? statusIcon;
  final Color? statusColor;
  final String? statusLabel;
  final String? statusExplanation;
  final Widget? statusWidget;

  // Footer actions (optional)
  final List<Widget>? footerActions;

  const CustomCard({
    super.key,
    required this.leadingIcon,
    required this.title,
    this.iconColor,
    this.iconSize,
    this.titleStyle,
    this.headerActions,
    this.body,
    this.footer,
    this.margin,
    this.padding,
    this.cardColor,
    this.elevation = 2,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.statusIcon,
    this.statusColor,
    this.statusLabel,
    this.statusExplanation,
    this.statusWidget,
    this.footerActions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Print debug info when the card is built
    // debugPrint('[CustomCard] Building card: title="$title", statusLabel="$statusLabel"');

    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      margin: margin ?? const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      color: (cardColor ?? theme.cardColor).withAlpha(153), // ~0.6 alpha for Namida style
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            clipBehavior: Clip.antiAlias,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: (cardColor ?? theme.cardColor).withAlpha(153),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withAlpha(60),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Leading Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? colorScheme.primary).withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(leadingIcon, color: iconColor ?? colorScheme.primary, size: iconSize ?? 20),
                ),
                const SizedBox(width: 16),
                // Title
                Expanded(
                  child: Text(
                    title,
                    style:
                        titleStyle ??
                        theme.textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          fontSize: 16.0,
                        ),
                  ),
                ),
                // Header Actions and Status
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (headerActions != null) ...headerActions!,
                    if (statusWidget != null) ...[
                      // const SizedBox(width: 10),
                      statusWidget!,
                      const SizedBox(width: 12),
                    ] else if (statusIcon != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: (statusColor ?? colorScheme.secondary).withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(statusIcon, color: statusColor ?? colorScheme.secondary, size: 20),
                      ),
                      if (statusExplanation != null) ...[
                        const SizedBox(width: 4),
                        Tooltip(
                          message: statusExplanation!,
                          child: Icon(Iconsax.info_circle, color: colorScheme.primary, size: 20),
                        ),
                      ],
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Body Section
          if (body != null) body!,
          // Footer Section
          if (footer != null) footer!,
          // Footer Actions Section
          if (footerActions != null || statusLabel != null)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surface.withAlpha(80),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  if (footerActions != null) ...footerActions!,
                  const Spacer(),
                  if (statusLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (statusColor ?? colorScheme.secondary).withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: statusColor ?? colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
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
