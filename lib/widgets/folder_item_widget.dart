import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../utils/utils.dart';

class FolderItemWidget extends StatelessWidget {
  final String name;
  final String path;
  final IconData? leadingIcon;
  final Color? iconColor;
  final VoidCallback? onRemove;
  final bool isLoading;
  final bool showRemoveButton;
  final bool isValid;
  final String? errorMessage;

  const FolderItemWidget({
    super.key,
    required this.name,
    required this.path,
    this.leadingIcon,
    this.iconColor,
    this.onRemove,
    this.isLoading = false,
    this.showRemoveButton = true,
    this.isValid = true,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Folder Icon
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? colorScheme.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                leadingIcon ?? (Platform.isAndroid ? Iconsax.mobile : Iconsax.monitor),
                color: iconColor ?? colorScheme.primary,
                size: UIConstants.iconSizeM,
              ),
            ),
          ),

          // Folder Info (Name & Path)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Folder Name
                  Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Folder Path (Platform-specific formatting)
                  Builder(
                    builder: (context) {
                      final normalizedPath = normalizePath(path);
                      final displayPath = Platform.isAndroid
                          ? normalizedPath.replaceFirst(
                              'internal memory/',
                              'Internal Memory/',
                            )
                          : normalizedPath;
                      return Text(
                        displayPath,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),

                  // Error Message (if any)
                  if (errorMessage != null && !isValid)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, size: 16, color: AppColors.errorRed),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.errorRed,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Remove Button
          if (showRemoveButton)
            IconButton(
              icon: Icon(Iconsax.minus_cirlce, size: 22),
              color: colorScheme.primary,
              tooltip: 'Remove',
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: isLoading ? null : onRemove,
            ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
} 