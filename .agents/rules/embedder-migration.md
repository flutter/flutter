---
trigger: always_on
description: Mandatory invariants, TDD workflow, and C-API guardrails for the Android Embedder migration (RFC 410.0000).
---

# Android Embedder C-API Migration Rules (RFC 410.0000)

When operating within the `android-embedder-migration-v10/*` branch slug or modifying `engine/src/flutter/shell/platform/android/`:

## 1. State-as-Code & ADR Consultation
- Before planning or implementing any code changes, read `.agents/embedder_migration/session_state.json` and `.agents/embedder_migration/INVARIANTS.md`.
- Ensure all technical decisions conform to the governing ADR in `.agents/embedder_migration/adrs/`.
- Never use time, effort, or implementation difficulty as a metric. Always prioritize the **most correct** decision.

## 2. Test-Driven Development (TDD First)
- Never assume you know the answer from looking at code. Follow the scientific loop: Explore -> Hypothesize -> Test -> Evaluate.
- When creating, refactoring, or decoupling components, write or run a characterization host unit test **first** in `flutter_embedder_native_unittests` using mock JNI providers (`FlutterJniProvider`, `SurfaceControlProvider`, etc.).
- Verify the test fails or proves the existing invariant before implementing the production adapter shim.

## 3. Dynamic Proc Table & GN Firewall
- Code in `:flutter_embedder_native_src` must compile under `defines = [ "FLUTTER_ENGINE_NO_PROTOTYPES" ]` with `check_includes = true`.
- Never invoke global C Embedder API functions directly (e.g. `FlutterEngineRunInitialized(...)`). All C-API calls must dispatch through the `FlutterEngineProcTable` pointer table (`embedder_api_.RunInitialized(...)`).
- Never add `#include` directives to private engine headers (`flutter/shell/common/*`, `flutter/flow/*`, `flutter/runtime/*`, `flutter/impeller/*`).

## 4. Resource Lifecycle & Concurrency Invariants
- **JNIEnv Safety**: Never store or pass a `JNIEnv*` across task runner threads. Acquire locally via `fml::jni::AttachCurrentThread()` and check exceptions immediately with `fml::jni::CheckException(env)`.
- **Sync Fence Ownership**: The embedder owns `FlutterBackingStorePresentInfo.synchronization_fence_fd`. It must be transferred to `SurfaceControl.Transaction.setBuffer` or closed via `::close(fd)` on every code path. Once closed, set `fence_fd = -1`.
- **Multi-View Concurrency**: Frame state (`FlutterLayer` slices, mutator stacks) must be captured **by value** in the `present_view_callback` closure before posting to the platform task runner. Never store transient frame state as mutable member variables on shared controllers.
- **Synchronous Surface Destruction**: When Android calls `surfaceDestroyed()`, `FlutterEngineNotifyDestroyed` must complete synchronously before the callback returns to the OS.
- **Perfetto Tracing**: Every native JNI entrypoint, task runner trampoline, vsync callback, and surface transition must have a `TRACE_EVENT("flutter", ...)` slice.

## 5. PR Chain & Git Discipline
- All branches must strictly follow the slug: `android-embedder-migration-v10/<version>-<name>`.
- Before staging commits, verify topological chain alignment by running:
  `dart .agents/skills/pr-chain-manager/scripts/pr_chain.dart verify`
- When upstream changes occur, cascade rebases downstream using:
  `dart .agents/skills/pr-chain-manager/scripts/pr_chain.dart rebase`
- Push using `--force-with-lease`.

## 6. Pre-Commit Linting, Formatting & Static Analysis
Every `git commit` is gated by `.agents/skills/pr-chain-manager/scripts/pre_commit_linter.dart` (via both `.git/hooks/pre-commit` and the Jetski `PreToolUse` hook). Before committing, ensure all applicable checks pass:
- **Dart Files (`.dart`)**: Must pass `dart format --output=none --set-exit-if-changed` and `dart analyze --fatal-infos`.
- **Engine Formatting (`engine/src/flutter/*`)**: Must pass `et format --dry-run` (covers `clang-format` for C++/ObjC/Shaders, C++ `#ifndef` header guards & license headers, `gn format` for `.gn`/`.gni`, `google-java-format` for `.java`, `yapf` for `.py`, and trailing whitespace). Run `et format` to auto-fix.
- **C/C++ Static Analysis (`.cc`, `.h`, `.cpp`, `.mm`)**: Must pass `clang-tidy` via `engine/src/flutter/tools/clang_tidy/bin/main.dart` across both `android_debug_unopt` and `host_debug_unopt` compilation databases.
- **GN Build Graph & Header Firewall (`.gn`, `.gni`, `.cc`, `.h`)**: Must pass `gn check` on `out/android_debug_unopt` and `out/host_debug_unopt` (`check_includes = true`).
- **Android SDK Lint (`.java`, `.kt`)**: Must pass `engine/src/flutter/tools/android_lint/bin/main.dart`.
- **Perfetto Trace**: Pre-commit worker timings are recorded to `/tmp/flutter_pre_commit_trace.json`.

