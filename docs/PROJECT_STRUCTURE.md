# Project Structure for Namida Sync

Namida Sync uses a modular, maintainable project structure for scalability, clarity, and ease of development. Shared code is centralized for reuse, and all changes are reflected in this documentation and in the README.

## Why Modular & Feature-Centric?
- **Scalability:** Each layer is self-contained, making it easy to add, update, or remove features.
- **Maintainability:** Clear separation of concerns (models, providers, services, screens, widgets, utils) keeps code organized and easy to understand.
- **Testability:** Isolated modules simplify unit and integration testing.
- **Collaboration:** Developers can work on different features or layers independently.

## Structure Overview

```
lib/
|   firebase_options.dart
|   main.dart
|   
+---models
|       models.dart
|       folder_info.dart
|       local_network_models.dart
|       sync_manifest.dart
|       transfer_manifest.dart
|       transfer_session.dart
|       
+---providers
|       providers.dart
|       folder_provider.dart
|       google_auth_provider.dart
|       google_drive_provider.dart
|       local_network_provider.dart
|       theme_provider.dart
|       
+---screens
|   +---about
|   |       about_screen.dart
|   |       
|   \---dashboard
|       |   backup_folder_card.dart
|       |   dashboard_screen.dart
|       |   music_library_folders_card.dart
|       |   
|       +---google_drive
|       |       google_drive_page.dart
|       |       backup_card.dart
|       |       google_account.dart
|       |       restore_card.dart
|       |
|       \---local_transfer
|               local_transfer_page.dart
|               local_recieve_backup_card.dart
|               local_send_backup_card.dart
|               local_setup_card.dart
|
+---services
|       services.dart
|       folder_service.dart
|       google_auth_service.dart
|       google_drive_service.dart
|       local_network_service.dart
|
+---utils
|       utils.dart
|       app_theme.dart
|       credentials.dart
|       google_drive_utils.dart
|       helper_methods.dart
|       permissions_utils.dart
|       storage_utils.dart
|       ui_constants.dart
|
\---widgets
        widgets.dart
        custom_card.dart
        icon_label_button.dart
```

## Folder Descriptions
- **models/**: Data models used throughout the app (e.g., `sync_manifest.dart`, `folder_info.dart`).
- **providers/**: State management using Provider (e.g., `folder_provider.dart`, `google_drive_provider.dart`, `theme_provider.dart`, `google_auth_provider.dart`).
- **services/**: Service classes for file operations, Google Drive, authentication, etc. (`google_drive_service.dart`, `folder_service.dart`, `google_auth_service.dart`).
- **screens/**: App screens (UI pages), including dashboard and about/help. Dashboard contains modular cards and Google Drive UI.
- **widgets/**: Reusable widgets, including custom cards for folder selection, permissions, and status UI (`custom_card.dart`, `folder_card.dart`, `permission_card.dart`).
- **utils/**: Utility/helper functions and theming (`app_theme.dart`, `permissions_utils.dart`, `storage_utils.dart`).
- **test/**: Unit and widget tests, mirroring the lib/ structure.
- **docs/**: Project documentation, including:
  - `PROJECT_STRUCTURE.md` (this file)
  - `BACKUP_LOGIC.md` (detailed folder/manifest logic)
  - `NAMIDA_ABOUT_PAGE_UI.md` (UI/UX and theming reference)
  - `GOOGLE_DRIVE_INTEGRATION.md` (Drive integration details)
- **assets/**: Images, fonts, etc.

## Notes
- Firebase initialization is handled in `lib/main.dart` using the generated `firebase_options.dart`.
- Authentication and cloud sync features rely on Firebase and Google Sign-In.
- Theming and UI are managed via `app_theme.dart` and `ThemeProvider`.
- All documentation is in the `docs/` folder, with an index in `docs/README.md`.

## Best Practices
- Keep each layer or feature self-contained.
- Use meaningful comments and documentation throughout the codebase.
- Update markdown files (`README.md`, docs/) with every significant change or improvement.
- Use Provider for state management.
- Write tests for all business logic and UI components.
