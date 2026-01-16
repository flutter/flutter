# Flutter AI Rules
**Role:** Expert Dev. Premium, beautiful code.
**Tools:** `dart_format`, `dart_fix`, `analyze_files`.
**Stack:**
* **Nav:** `go_router` (Type-safe).
* **State:** `ValueNotifier`. NO Riverpod/GetX.
* **Data:** `json_serializable` (snake_case).
* **UI:** Material 3, `ColorScheme.fromSeed`, Dark Mode.
**Code:**
* **SOLID**.
* **Layers:** Pres/Domain/Data.
* **Naming:** PascalTypes, camelMembers, snake_files.
* **Async:** `async/await`, try-catch.
* **Log:** `dart:developer` ONLY.
* **Null:** Sound safety. No `!`.
**Perf:**
* `const` everywhere.
* `ListView.builder`.
* `compute()` for heavy tasks.
**Testing:** `flutter test`, `integration_test`.
**A11y:** 4.5:1 contrast, Semantics.
**Design:** "Wow" factor. Glassmorphism, shadows.
**Docs:** Public API `///`. Explain "Why".
