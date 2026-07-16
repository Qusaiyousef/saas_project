# Original User Request

## 2026-07-07T20:31:03Z

# Teamwork Project Prompt — Draft

> Status: Launched
> Goal: Teamwork agents are executing the prompt.

As an autonomous agent with full access to the saas_frontend workspace, your objective is a project-wide UI/UX and responsiveness refactoring. Do not limit your scope to a single screen.

Working directory: `/home/kali/Downloads/saas_project/saas_frontend`
Integrity mode: development

## Requirements

### R1. Global Cross-Platform Responsiveness
Scan all files inside `lib/screens/`. Refactor every screen to ensure perfect responsiveness across Windows, Web, and Android. Replace any hardcoded dimensions that cause overflow errors with robust responsive widgets (LayoutBuilder, Expanded, Wrap, etc.). Ensure sidebars, grids, and lists adapt gracefully to mobile viewports. Maintain all existing business logic, state management (Providers), and routing.

### R2. Universal Keyboard UX Navigation
Identify every screen containing input forms (e.g., Login, Customers, Finance, Settings). Implement seamless keyboard navigation across all of them. Use `FocusNode` and `TextInputAction.next` to move between fields using the 'Enter' key, and `TextInputAction.done` to trigger the final save/submit action seamlessly.

### R3. Global App Branding & Icon
Completely replace the default Flutter app icon for the entire project. Configure and run `flutter_launcher_icons` (or manipulate the native directories directly for Android, Web, macOS, and Windows) to set a new global branding icon. Additionally, update the UI in relevant screens (like the Login screen or Dashboard headers) to display this new branding elegantly.

## Acceptance Criteria

### UI/UX & Responsiveness
- [ ] The `saas_frontend` project compiles successfully for Web and Android.
- [ ] No layout overflow exceptions occur on any screen in `lib/screens/` when resizing the window down to a mobile viewport or up to a desktop viewport.
- [ ] Existing business logic and routing remain fully functional.

### Keyboard Navigation
- [ ] On all forms across the app, pressing the 'Enter' key on a text field (except the last one) moves the focus to the next logical input field.
- [ ] Pressing the 'Enter' key on the final text field of any form executes its corresponding submit/save action.

### App Branding & Icon
- [ ] The default Flutter app icon is completely removed from the project configurations (Web, Android, Windows, macOS).
- [ ] `flutter_launcher_icons` (or native file replacement) has been successfully executed with the new icon asset.
- [ ] At least one screen (e.g., Login or Dashboard) prominently displays the newly configured app icon using an `Image` widget.
