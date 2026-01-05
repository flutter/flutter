# Scholesa Flutter Setup (Current Focus)

## 1) Firebase configuration
- Run `flutterfire configure` from `scholesa_app/` to generate `lib/firebase_options.dart` with real values.
- Add platform files:
  - Android: `android/app/google-services.json`
  - iOS: `ios/Runner/GoogleService-Info.plist`
- If web is needed later: include web config in `firebase_options.dart`.

## 2) Dependencies (pending)
- Add `firebase_core`, `firebase_auth`, `cloud_firestore`, and optionally `connectivity_plus` for offline detection to `pubspec.yaml` (app-level). Do **not** modify the Flutter engine workspace; ensure you are inside the app package.

## 3) Auth wiring
- Replace the stub in `lib/features/auth/auth_service.dart` with Firebase Auth calls.
- On login/register success, fetch user profile/role from Firestore and set `AppState.role` before navigating.

## 4) Dashboards
- Populate dashboards in `lib/features/dashboards/role_dashboards.dart` with role-specific widgets and Firestore queries.
- Keep role selection in `role_selector_page.dart` but redirect automatically when a stored role is present.

## 5) Offline strategy
- Replace the placeholder `OfflineService` with real connectivity monitoring and caching (e.g., SQLite/hive + background sync).

## 6) Testing
- Add widget tests for auth flow and role routing; use Firebase emulator configs if available.
