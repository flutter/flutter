---
name: embedder-flag-and-integration-verifier
description: >-
  Verifies that when the Android Embedder API feature flag is set to true, the
  engine is strictly initialized via the public C Embedder API
  (FlutterEngineInitialize / FlutterEngineRunInitialized) with ZERO
  flutter::Shell::Create or AndroidShellHolder invocations on the Android
  embedder path. Executes real integration tests (dev/integration_tests) and
  DeviceLab tasks (dev/devicelab) on a connected Android device while capturing
  Perfetto traces and adb logcat proof markers, and enforces a monotonic
  integration test failure ratchet across the stacked PR branch chain.
  When to use:
  - Whenever modifying engine initialization, JNI dispatch, or feature flag routing in shell/platform/android/.
  - On every branch in android-embedder-migration-v10/* to verify on-device integration and DeviceLab tests with the feature flag set to true.
  - To prove via Perfetto traces and logcat that no flutter::Shell exists in the Android embedder when the flag is flipped.
---

# Embedder Feature Flag & On-Device Integration Ratchet Verifier

In previous migration attempts, flipping the feature flag failed to guarantee that the public C Embedder API was actually driving the engine—either because the flag did not propagate during integration tests, or because `AndroidShellHolder` / `flutter::Shell::Create` was still invoked as a fallback or companion object on the Android embedder path.

This skill and its executable tool (`.agents/skills/embedder-flag-and-integration-verifier/scripts/verify_embedder_flag_and_ratchet.dart`) enforce **ADR-0011**.

---

## 1. Non-Negotiable Feature-Flag-True Invariants

When the feature flag (`--enable-android-embedder-api` / `io.flutter.embedding.android.EnableAndroidEmbedderApi=true`) is active:

1. **Zero `Shell::Create` / Zero `AndroidShellHolder` on the Android Embedder Path**:
   - The Android Embedder ([BUILD.gn](../../../engine/src/flutter/shell/platform/android/BUILD.gn)) MUST NOT include, reference, or instantiate `flutter::Shell` or `AndroidShellHolder` when `use_embedder_api == true`.
   - `AndroidShellHolder::AndroidShellHolder` MUST guard against accidental invocation with a fatal runtime check:
     ```cpp
     FML_CHECK(!use_embedder_api)
         << "FATAL: AndroidShellHolder / Shell::Create invoked when Embedder API feature flag is true!";
     ```
   - `FlutterEmbedderNative` MUST initialize the engine strictly through `embedder_api_.Initialize(...)` (`FlutterEngineInitialize`) and `embedder_api_.RunInitialized(...)` (`FlutterEngineRunInitialized`), or `embedder_api_.Spawn(...)`.

2. **Mandatory Perfetto & Logcat Telemetry Markers**:
   - In `FlutterEmbedderNative::Initialize` (C-API path):
     ```cpp
     TRACE_EVENT0("flutter", "FlutterEmbedderNative::Initialize[C-API]");
     FML_LOG(IMPORTANT) << "[EMBEDDER_API_PROOF] path=C_EMBEDDER_API proc_table=FlutterEngineInitialize shell_holder=NONE";
     ```
   - In `AndroidShellHolder::AndroidShellHolder` (Legacy path):
     ```cpp
     TRACE_EVENT0("flutter", "AndroidShellHolder::Initialize[LEGACY-SHELL]");
     FML_LOG(IMPORTANT) << "[EMBEDDER_API_PROOF] path=LEGACY_SHELL shell_create=ACTIVE";
     ```

---

## 2. On-Device Verification (`dev/integration_tests` & `dev/devicelab`)

Host C++ unit tests (`flutter_embedder_native_unittests`) are necessary for TDD, **but they do NOT substitute for real end-to-end integration tests on a connected Android device**.

You MUST run the real integration tests in `dev/integration_tests/` and `dev/devicelab/` on a connected Android device (`adb devices`) with the feature flag set to `true`:

```bash
# 1. Check current integration test ratchet status and target expectations
dart .agents/skills/embedder-flag-and-integration-verifier/scripts/verify_embedder_flag_and_ratchet.dart status

# 2. Run static code audit for Shell::Create / AndroidShellHolder isolation and proof markers
dart .agents/skills/embedder-flag-and-integration-verifier/scripts/verify_embedder_flag_and_ratchet.dart verify-static

# 3. Run the dev/integration_tests & dev/devicelab suite on the connected device with Perfetto + logcat proof capture
dart .agents/skills/embedder-flag-and-integration-verifier/scripts/verify_embedder_flag_and_ratchet.dart run-suite \
  --local-engine=android_debug_unopt_arm64 \
  --local-engine-host=host_debug_unopt

# 4. Verify monotonic ratchet compliance across the branch chain (also run automatically by pre-commit hook)
dart .agents/skills/embedder-flag-and-integration-verifier/scripts/verify_embedder_flag_and_ratchet.dart verify-ratchet
```

---

## 3. How the Monotonic Integration Test Failure Ratchet Works

During intermediate branches of the migration (`2.1` &rarr; `2.6`), some integration tests in `dev/integration_tests` or `dev/devicelab` will fail when the feature flag is `true` (for example, `dev/integration_tests/external_textures` will fail on branch `2.2` before `AHardwareBuffer` textures are wired in branch `2.5`).

**This is expected and permitted, subject to three strict rules enforced by `verify_embedder_flag_and_ratchet.dart`:**

1. **C-API Proof Must Pass Even on Failing Tests**:
   - For *every* test run (both passing and failing), the captured Perfetto trace (`/tmp/perfetto_embedder_verify_<test>.pftrace`) and `adb logcat` dump MUST contain `FlutterEmbedderNative::Initialize[C-API]` and `[EMBEDDER_API_PROOF] path=C_EMBEDDER_API`, and MUST contain **ZERO** occurrences of `AndroidShellHolder` or `Shell::Create`.
   - If a test fails *without* emitting `[EMBEDDER_API_PROOF] path=C_EMBEDDER_API`—or if it emits `path=LEGACY_SHELL`—the verifier rejects the run as a **Feature Flag Bypass**.
2. **Monotonic Decrease of Failing Tests Across the Chain**:
   - The count of failing tests (`current_failing_test_count` in `.agents/embedder_migration/integration_test_ratchet.json`) MUST monotonically decrease across stacked branches:
     $$\text{failing\_test\_count}(\text{branch}_i) \le \text{failing\_test\_count}(\text{branch}_{i-1})$$
3. **Locked Passing Tests Never Regress**:
   - Once a `dev/integration_tests` or `dev/devicelab` target passes with the feature flag `true`, its ID is added to `passing_locked_tests` in `integration_test_ratchet.json`. No downstream branch may ever remove a locked test or allow it to fail.
