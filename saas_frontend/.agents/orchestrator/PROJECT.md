# Project: SaaS Frontend Refactoring

## Architecture
- Flutter cross-platform mobile & desktop application.
- UI Screens located in `lib/screens/`.
- State Management: Provider.
- Entrypoint: `lib/main.dart` with class `SaasApp`.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Baseline Test & Compilation Fix | Fix test compilation in test/widget_test.dart and ensure `flutter test` compiles. | None | PLANNED |
| 2 | R1: Global Cross-Platform Responsiveness | Refactor UI screens in lib/screens/ to remove fixed width overflows and implement responsive layouts, scroll views, and mobile navigation shell. | M1 | PLANNED |
| 3 | R2: Universal Keyboard UX Navigation | Implement FocusNode, TextInputAction, and Enter key submit hooks across login and dialog forms. | M1 | PLANNED |
| 4 | R3: Global App Branding & Icon | Run launcher icons generator and display branding logo in UI. | M1 | PLANNED |
| 5 | E2E Testing & Verification | Validate all changes with E2E unit tests and Forensic Audit. | M2, M3, M4 | PLANNED |

## Interface Contracts
- Standard widgets and API interfaces in screens are preserved.
- No changes to existing provider or business logic state.
