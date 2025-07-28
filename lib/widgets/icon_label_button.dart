import 'package:flutter/material.dart';

// [1] Reusable IconLabelButton for sync method selection
class IconLabelButton extends StatelessWidget {

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double? minWidth;
  final double? maxWidth;

  const IconLabelButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.minWidth,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bgColor = selected ? colorScheme.primary.withValues(alpha: 0.12) : colorScheme.surface;
    final borderColor = selected ? colorScheme.primary : colorScheme.outlineVariant;
    final textColor = selected ? colorScheme.primary : colorScheme.onSurface;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // debugPrint('[IconLabelButton] $label tapped');
          onTap();
        },
        // [2] Icon Label Button with proper constraints
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minWidth ?? 120,
            maxWidth: maxWidth ?? 200,
            minHeight: 44, // Ensure minimum touch target
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // maybe the icon doesn't look good, i'll decide later
                Icon(icon, color: textColor, size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 