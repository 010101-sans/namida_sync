# Namida About Page UI & App Theming Reference - Light Theme

This document describes my study on the UI structure, styling, and theming principles used in namida_sync, inspired by the Namida About page and implemented throughout the app's dashboard and settings.

## 1. Layout Structure & Card-Based UI

- **AppBar**
  - Title, optional icons (help, theme switch)
- **Card-Based Sections**
  - All major UI sections (folder selection, permissions, backup/restore, Google Drive) are presented as cards for clarity and consistency.
  - Cards use rounded corners, modern padding, and clear iconography.
  - See: [`lib/widgets/custom_card.dart`](../lib/widgets/custom_card.dart), [`lib/screens/dashboard/`](../lib/screens/dashboard/)
- **About Page**
  - The About page in the app is currently a placeholder, but the card-based UI and theming are used throughout the dashboard and settings.

## 2. Styling & Theme
### **General**
- Rounded corners on all cards/sections
- Consistent padding and spacing between sections
- Icons paired with text for all actionable items
- Font: Modern, sans-serif, medium weight for titles, regular for body
- Responsive layout for different device sizes

### **Dark Theme** (see [`lib/utils/app_theme.dart`](../lib/utils/app_theme.dart))
- Background: #18181C
- Card: #23232A
- Text: #FFFFFF, #B0B0B0
- Accent: #4E4C72 (purple)

### **Light Theme** (see [`lib/utils/app_theme.dart`](../lib/utils/app_theme.dart))
- Background: #F5F5FA
- Card: #FFFFFF
- Text: #18181C, #6A6A6A
- Accent: #9C99C1 (indigo)

### **Buttons & Actions**
- Outlined and filled buttons with rounded corners
- Color and style adapt to theme
- See: card actions in dashboard cards and [`custom_card.dart`](../lib/widgets/custom_card.dart)

### **Other Details**
- Section titles: Bold, slightly larger
- Section subtitles: Smaller, lighter color
- Status indicators: Color-coded icons and tooltips
- All icons are outlined and visually consistent

## 3. UI Components List

- AppBar (custom, with icons)
- CustomCard (reusable for each section, see [`custom_card.dart`](../lib/widgets/custom_card.dart))
- Folder selection/status cards (see dashboard)
- Google Drive sync/backup/restore cards
- Action buttons (outlined, filled)

## 4. Color Palette (from app_theme.dart)

- **Dark Theme:**
  - Background: #18181C
  - Card: #23232A
  - Text: #FFFFFF, #B0B0B0
  - Accent: #4E4C72 (purple)
- **Light Theme:**
  - Background: #F5F5FA
  - Card: #FFFFFF
  - Text: #18181C, #6A6A6A
  - Accent: #9C99C1 (indigo)

## 5. Reference Images
- Reference screenshots for the card-based UI and About page are available at :
  - `../assets/images/references/namida_screenshots/namida_light_mode_ui.jpg`
  - `../assets/images/references/namida_screenshots/namida_dark_mode_ui.jpg`

## 6. Implementation Notes
- The card-based UI and theming are implemented throughout the dashboard and settings, not just the About page.
- The About page itself is a placeholder, but the design principles are consistent across the app.
- All theming is managed via [`lib/utils/app_theme.dart`](../lib/utils/app_theme.dart) and can be toggled globally.
- For more, see the dashboard cards and widgets in [`lib/screens/dashboard/`](../lib/screens/dashboard/) and [`lib/widgets/`](../lib/widgets/).