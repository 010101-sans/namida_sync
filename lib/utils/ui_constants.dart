import 'package:flutter/material.dart';
import 'app_theme.dart';

class UIConstants {
    
  // Spacing constants for consistent layout
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border radius values for rounded corners
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 24.0;

  // Icon sizes for consistent iconography
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 20.0;
  static const double iconSizeL = 24.0;
  static const double iconSizeXL = 32.0;

  // Animation durations for smooth transitions
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Card elevations for depth
  static const double elevationNone = 0.0;
  static const double elevationLow = 1.0;
  static const double elevationMedium = 2.0;
  static const double elevationHigh = 4.0;

  // Common padding values
  static const EdgeInsets paddingXS = EdgeInsets.all(spacingXS);
  static const EdgeInsets paddingS = EdgeInsets.all(spacingS);
  static const EdgeInsets paddingM = EdgeInsets.all(spacingM);
  static const EdgeInsets paddingL = EdgeInsets.all(spacingL);

  // Horizontal padding
  static const EdgeInsets paddingHorizontalS = EdgeInsets.symmetric(horizontal: spacingS);
  static const EdgeInsets paddingHorizontalM = EdgeInsets.symmetric(horizontal: spacingM);
  static const EdgeInsets paddingHorizontalL = EdgeInsets.symmetric(horizontal: spacingL);

  // Vertical padding
  static const EdgeInsets paddingVerticalS = EdgeInsets.symmetric(vertical: spacingS);
  static const EdgeInsets paddingVerticalM = EdgeInsets.symmetric(vertical: spacingM);
  static const EdgeInsets paddingVerticalL = EdgeInsets.symmetric(vertical: spacingL);

  // Common margin values
  static const EdgeInsets marginS = EdgeInsets.all(spacingS);
  static const EdgeInsets marginM = EdgeInsets.all(spacingM);
  static const EdgeInsets marginL = EdgeInsets.all(spacingL);

  // Common border radius values
  static const BorderRadius borderRadiusS = BorderRadius.all(Radius.circular(radiusS));
  static const BorderRadius borderRadiusM = BorderRadius.all(Radius.circular(radiusM));
  static const BorderRadius borderRadiusL = BorderRadius.all(Radius.circular(radiusL));
  static const BorderRadius borderRadiusXL = BorderRadius.all(Radius.circular(radiusXL));
}

class UIHelpers {
  // Returns a card-like BoxDecoration for containers
  static BoxDecoration getCardDecoration(BuildContext context, {double elevation = UIConstants.elevationMedium}) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: UIConstants.borderRadiusXL,
      boxShadow: [
        BoxShadow(
          color: theme.shadowColor.withValues(alpha: 0.05),
          blurRadius: elevation * 2,
          offset: Offset(0, elevation),
        ),
      ],
    );
  }

  // Returns a surface-like BoxDecoration for containers
  static BoxDecoration getSurfaceDecoration(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: color ?? theme.colorScheme.surface.withValues(alpha: 0.5),
      borderRadius: UIConstants.borderRadiusM,
      border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2), width: 1),
    );
  }

  // Returns a status-indicating BoxDecoration (e.g., for success, warning, error)
  static BoxDecoration getStatusDecoration(Color color) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: UIConstants.borderRadiusM,
      border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
    );
  }

  // Returns a title TextStyle for section headers
  static TextStyle? getTitleStyle(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface);
  }

  // Returns a body TextStyle for main content
  static TextStyle? getBodyStyle(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface);
  }

  // Returns a caption TextStyle for secondary content
  static TextStyle? getCaptionStyle(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7));
  }

  // Returns a primary button style for ElevatedButton
  static ButtonStyle getPrimaryButtonStyle(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: UIConstants.borderRadiusL),
      padding: UIConstants.paddingHorizontalM + UIConstants.paddingVerticalS,
      elevation: UIConstants.elevationNone,
    );
  }

  // Returns a secondary button style for OutlinedButton
  static ButtonStyle getSecondaryButtonStyle(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton.styleFrom(
      foregroundColor: theme.colorScheme.primary,
      side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: UIConstants.borderRadiusL),
      padding: UIConstants.paddingHorizontalM + UIConstants.paddingVerticalS,
    );
  }

  // Returns a text button style for TextButton
  static ButtonStyle getTextButtonStyle(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton.styleFrom(
      foregroundColor: theme.colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: UIConstants.borderRadiusL),
      padding: UIConstants.paddingHorizontalS + UIConstants.paddingVerticalS,
    );
  }

  // Returns a success SnackBar
  static SnackBar getSuccessSnackBar(BuildContext context, String message) {
    return SnackBar(
      content: Text(message),
      backgroundColor: AppColors.successGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: UIConstants.borderRadiusM),
      margin: UIConstants.marginM,
    );
  }

  // Returns an error SnackBar
  static SnackBar getErrorSnackBar(BuildContext context, String message) {
    return SnackBar(
      content: Text(message),
      backgroundColor: AppColors.errorRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: UIConstants.borderRadiusM),
      margin: UIConstants.marginM,
    );
  }

  // Returns an info SnackBar
  static SnackBar getInfoSnackBar(BuildContext context, String message) {
    final theme = Theme.of(context);
    return SnackBar(
      content: Text(message),
      backgroundColor: theme.colorScheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: UIConstants.borderRadiusM),
      margin: UIConstants.marginM,
    );
  }

  // Returns a loading widget with optional message
  static Widget getLoadingWidget(BuildContext context, {String? message}) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          if (message != null) ...[
            const SizedBox(height: UIConstants.spacingM),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ],
        ],
      ),
    );
  }

  // Returns an empty state widget for empty lists or screens
  static Widget getEmptyStateWidget(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onAction,
    String? actionText,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: UIConstants.paddingL,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: UIConstants.iconSizeXL, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(height: UIConstants.spacingM),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: UIConstants.spacingS),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionText != null) ...[
              const SizedBox(height: UIConstants.spacingL),
              ElevatedButton(onPressed: onAction, style: getPrimaryButtonStyle(context), child: Text(actionText)),
            ],
          ],
        ),
      ),
    );
  }
}
