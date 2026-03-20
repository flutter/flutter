# Copilot Workspace Instructions for Flutter

## Purpose

This file guides GitHub Copilot and other AI agents to work productively in this Flutter workspace. It summarizes build/test commands, coding conventions, common pitfalls, and agent-specific guidance.

---

## Build & Test Commands

- **Build:**
  - `flutter run` (debug, hot reload)
  - `flutter run --no-hot` (debug, no hot reload)
  - `flutter run --profile` (profile mode)
  - `flutter run --release` (release mode)
- **Test:**
  - `flutter test` (unit tests)
  - `flutter doctor` (diagnostics)

## Coding Conventions

- Follow [Flutter Style Guide](https://github.com/flutter/flutter/blob/main/docs/contributing/Style-guide-for-Flutter-repo.md).
- Dart code: formatted with `dart format` (enforced by CI).
- Constructors first in classes, then logically grouped members.
- All public members should have documentation.
- For other languages, follow Google style guides (see .gemini/styleguide.md).

## Common Pitfalls

- If Flutter installation is corrupted:
  - Run: `git clean -xfd`, `git stash save --keep-index`, `git stash drop`, `git pull`, `flutter doctor`
- If project files are outdated:
  - Delete `ios/` and `android/` directories, then run `flutter create .` to regenerate.

## Agent Guidance

- Prefer official documentation links for user questions.
- When reviewing code, optimize for readability and avoid duplicating state.
- Error messages should be useful and actionable.
- Use `flutter doctor` to diagnose environment issues.

## Example Prompts

- "How do I run tests in this workspace?"
- "What is the recommended code style for Dart?"
- "How do I fix a corrupted Flutter installation?"
- "How do I regenerate outdated project files?"

---

## Next Customizations

- Create agent hooks for test automation and environment diagnostics.
- Add applyTo rules for frontend, backend, and test directories if workspace grows more complex.

---

_Last updated: March 20, 2026_
