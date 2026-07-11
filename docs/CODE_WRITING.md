# Namida Sync Code Writing Approach

This document describes the code writing, commenting, and organization standards for the Namida Sync project. All contributors should follow these guidelines to ensure code quality, maintainability, and a consistent developer experience.

## 1. **File and Folder Organization**

- **Feature-first structure:** Code is organized by feature/module (e.g., `screens/`, `widgets/`, `providers/`, `services/`).
- **Separation of concerns:** UI, business logic, data, and utilities are kept in their respective folders.
- **Subfolders:** Used for grouping related files (e.g., `screens/dashboard/google_drive/`).
- **Naming:** Use descriptive, lowercase, and underscore-separated filenames (e.g., `music_library_folders_card.dart`).

## 2. **Widget and Function Commenting**

- **Hierarchical Numbered Comments:**
  - Major widgets and functions are annotated with numbered comments reflecting their hierarchy.
  - Example:
    ```dart
    // [1] Main Card
    // [1.1] Header Section
    // [1.1.1] Title
    // [1.2] Body Section
    ```
  - Only actual widgets or logic blocks are numbered (not spacing/layout elements).
  - Children widgets use dot notation (e.g., `[2.1]`, `[2.2]`).
- **Purposeful Comments:**
  - Each major widget/function has a comment describing its purpose and role in the UI or logic.
  - Comments are clear, professional, and concise.

## 3. **Debug Output**

- **Use of `debugPrint`:**
  - Key lifecycle methods (`initState`, `dispose`, `build`) and important user actions include `debugPrint()` statements.
  - Debug output includes context, such as widget name and key properties (e.g., `[CustomCard] Building card: title="..."`).
  - Debug output is not excessive—only where it aids in tracing app flow or diagnosing issues.
- **Print for Utilities:**
  - In utility files (e.g., `storage_utils.dart`), `debugPrint` or `print` is used to log important actions (e.g., finding latest backup file).

## 4. **Code Cleanliness and Optimization**

- **Remove Unnecessary Code:**
  - Unused imports, variables, and dead code are removed.
  - Redundant or duplicate logic is eliminated.
- **Consistent Formatting:**
  - Indentation, spacing, and line breaks follow Dart/Flutter best practices.
  - Group related functions and classes together.
- **Descriptive Naming:**
  - Variables, functions, and classes use clear, descriptive names.
  - Avoid abbreviations unless they are standard.

## 5. **Best Practices for Flutter/Dart**

- **Stateless vs Stateful:**
  - Use `StatelessWidget` unless state is required.
  - Use `StatefulWidget` for dynamic UI or user interaction.
- **Provider/State Management:**
  - Use `Provider` for app-wide state, with clear separation of providers and business logic.
- **UI Consistency:**
  - Use shared constants and themes from `utils/` for spacing, colors, and text styles.
- **Error Handling:**
  - Use try/catch for async operations and show user-friendly error messages.
- **Accessibility:**
  - Use tooltips, semantic labels, and accessible color contrast where possible.

## 6. **How to Contribute Code**

- **Follow the structure and commenting style described above.**
- **Add hierarchical numbered comments to all new widgets and major logic blocks.**
- **Add debugPrint statements for new lifecycle methods or user actions.**
- **Remove any unnecessary code or imports in your changes.**
- **Test your code and check debug output for clarity.**
- **Document any new patterns or conventions in this file if needed.**

## 7. **Example: Widget Commenting**

```dart
Widget build(BuildContext context) {
  return Column(
    children: [
      // [1] Main Card
      CustomCard(
        title: 'Example',
        body: Column(
          children: [
            // [1.1] Header
            Text('Header'),
            // [1.2] Content
            Text('Content'),
          ],
        ),
      ),
      // [2] Action Button
      ElevatedButton(
        onPressed: () {},
        child: Text('Action'),
      ),
    ],
  );
}
```

> **Note:** I have used a custom `ndkVersion` in the project, but developers should always use `flutter.ndkVersion` for consistency and compatibility with Flutter tooling.

## 8. **Summary**

This approach ensures that the codebase is:
- Easy to read and navigate
- Debuggable and maintainable
- Consistent for all contributors

**Please follow these guidelines for all code contributions to Namida Sync!** 