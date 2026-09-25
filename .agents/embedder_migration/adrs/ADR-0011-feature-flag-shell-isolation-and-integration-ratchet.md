# ADR-0011: Feature Flag Shell Isolation, Perfetto Proof, and Integration Test Ratchet

## Status
ACCEPTED

## RFC 410 Cross-Reference
- Section: *Dual-Delegate Coexistence & Feature Flag Cutover*
- Section: *Integration & DeviceLab Verification Strategy*

## Context & Problem Statement
In a prior migration attempt, flipping the Android Embedder API feature flag (`use_embedder_api = true`) failed to guarantee that the engine was actually initialized and driven exclusively through the public C Embedder API (`embedder.h`). Specifically:
1. **Silent Fallback / Dual Shell Creation**: Code paths under the feature flag inadvertently instantiated `AndroidShellHolder` or invoked `flutter::Shell::Create` alongside or instead of `FlutterEngineInitialize`, meaning a private `flutter::Shell` instance remained in the Android Embedder execution path.
2. **Insufficient Device Verification**: Relying solely on host unit tests or on-device C++ unit tests (`flutter_shell_native_unittests`) missed end-to-end JNI/Activity/FlutterEngine flag propagation in real Flutter Android apps (`dev/integration_tests/*` and `dev/devicelab/*`).
3. **Uncontrolled Integration Test Regressions**: Because subsystems (Platform Views, External Textures, Semantics, Deferred Components) are migrated across a stacked chain of PR branches (`1.0` &rarr; `2.x` &rarr; `3.0`), some `dev/integration_tests` and `dev/devicelab` tests will understandably fail when the feature flag is `true` on early branches before their respective subsystem is wired up. Without a monotonic ratchet, it was impossible to distinguish expected not-yet-migrated failures from actual regressions or silent flag bypasses.

## Non-Negotiable Invariants
1. **Strict Shell Exclusion When Flag is `true`**:
   - When the Android Embedder API feature flag is `true`, **ZERO** calls to `flutter::Shell::Create` and **ZERO** instantiations of `AndroidShellHolder` may occur in the Android Embedder path (`engine/src/flutter/shell/platform/android/`).
   - No `flutter::Shell*` or `std::unique_ptr<flutter::Shell>` may exist in `FlutterEmbedderNative` or any C-API delegate. The engine MUST be initialized exclusively via `embedder_api_.Initialize(...)` (`FlutterEngineInitialize`) and `embedder_api_.RunInitialized(...)` (`FlutterEngineRunInitialized`), or `embedder_api_.Spawn(...)` (`FlutterEngineSpawn`).
   - `AndroidShellHolder::AndroidShellHolder` MUST assert `FML_CHECK(!use_embedder_api) << "FATAL: AndroidShellHolder / Shell::Create invoked when Embedder API feature flag is true!";` to make silent fallback physically impossible.

2. **Perfetto Trace & Logcat Cryptographic Proof**:
   - Every engine initialization on the C-API path MUST emit:
     - **Perfetto Trace Slice**: `TRACE_EVENT0("flutter", "FlutterEmbedderNative::Initialize[C-API]")` (which nests `FlutterEngineInitialize` and `FlutterEngineRunInitialized`).
     - **Logcat Proof Banner**: `FML_LOG(IMPORTANT) << "[EMBEDDER_API_PROOF] path=C_EMBEDDER_API proc_table=FlutterEngineInitialize shell_holder=NONE";`
   - Every engine initialization on the legacy path MUST emit:
     - **Perfetto Trace Slice**: `TRACE_EVENT0("flutter", "AndroidShellHolder::Initialize[LEGACY-SHELL]")`
     - **Logcat Proof Banner**: `FML_LOG(IMPORTANT) << "[EMBEDDER_API_PROOF] path=LEGACY_SHELL shell_create=ACTIVE";`
   - Any test run with the feature flag `true` is **INVALID** (and treated as a hard failure) unless captured Perfetto traces and `adb logcat` output simultaneously prove the presence of `FlutterEmbedderNative::Initialize[C-API]` / `path=C_EMBEDDER_API` and the **complete absence** (`count == 0`) of `AndroidShellHolder` / `Shell::Create` / `path=LEGACY_SHELL`.

3. **Real-Device `dev/integration_tests` and `dev/devicelab` Execution**:
   - Verification MUST be performed on a connected Android device (`adb`) using real integration tests in `dev/integration_tests/` and `dev/devicelab/bin/tasks/` built against `--local-engine=android_debug_unopt_arm64` (or `android_debug_unopt_x64`) and `--local-engine-host=host_debug_unopt`—**NOT** merely C++ unit tests.

4. **Monotonic Integration Test Failure Ratchet**:
   - Tracked in `.agents/embedder_migration/integration_test_ratchet.json`.
   - When running the canonical `dev/integration_tests` + `dev/devicelab` suite with the feature flag `true`:
     - Even if an integration test fails due to an unmigrated subsystem (e.g. `external_textures` failing on branch `2.2` before Milestone `2.5`), its captured Perfetto trace and logcat MUST still prove that the engine initialized via `path=C_EMBEDDER_API` with zero `Shell::Create` calls.
     - Across the stacked PR chain (`branch[i]` vs parent `branch[i-1]`), the number of failing integration tests with the feature flag `true` MUST monotonically decrease:
       $$\text{failing\_test\_count}(\text{branch}_i) \le \text{failing\_test\_count}(\text{branch}_{i-1})$$
     - Once an integration test passes with the feature flag `true`, it is added to `passing_locked_tests` and may **NEVER** regress in any downstream branch.
     - By Phase 3 (`3.0-flip-embedder-api-flag`), `failing_test_count` MUST reach `0`.

## Chosen Solution
Implement `.agents/skills/embedder-flag-and-integration-verifier/scripts/verify_embedder_flag_and_ratchet.dart` and `.agents/embedder_migration/integration_test_ratchet.json`, and enforce ratchet monotonicity in `.agents/skills/pr-chain-manager/scripts/pre_commit_linter.dart`.
