# Non-Negotiable Invariants: Android Embedder C-API Migration

These architectural invariants are absolute requirements derived from **RFC 410.0000** and the Flutter Android team standards.
No implementation shortcuts or temporary workarounds may violate these rules.

---

## 1. Dynamic Proc Table & Firewall Invariant (`FLUTTER_ENGINE_NO_PROTOTYPES`)
- All modular code in `:flutter_embedder_native_src` must compile under `defines = [ "FLUTTER_ENGINE_NO_PROTOTYPES" ]` with `check_includes = true`.
- Zero direct calls to global C symbols (`FlutterEngineRun`, `FlutterEngineInitialize`, etc.) are permitted.
- All C-API operations must dispatch through the `FlutterEngineProcTable` struct.

## 2. JNI Lifetime & Thread Safety Invariant
- `JNIEnv*` pointers must **never** be cached across thread boundaries or stored as class member fields.
- Every inbound JNI callback from Java must resolve `JNIEnv*` via `fml::jni::AttachCurrentThread()`.
- Every JNI invocation into Java must be checked immediately via `fml::jni::CheckException(env)`.
- Global Java references must use `fml::jni::ScopedJavaGlobalRef`. Local frames with loops must use `fml::jni::ScopedJavaLocalFrame`.

## 3. Hardware Sync Fence (`synchronization_fence_fd`) Ownership Invariant
- The embedder takes full POSIX ownership of `FlutterBackingStorePresentInfo.synchronization_fence_fd`.
- The file descriptor must be transferred to Android via `SurfaceControl.Transaction.setBuffer` or closed explicitly via `::close(fd)` on **every** code path (including errors and early returns).
- Once closed or handed off, the local handle must immediately be reset to `-1` to prevent double-close hazards.

## 4. Multi-View Value Capture Invariant
- To prevent cross-thread data races between consecutive views in multi-view/multi-window configurations, per-frame composition state (`FlutterLayer` slices, mutator stacks) must **never** be stored as mutable member variables on shared controllers.
- Frame state must be captured **by value** inside the `present_view_callback` closure before dispatching to the platform task runner.

## 5. Synchronous Surface Destruction Invariant
- When Android signals `SurfaceHolder.Callback.surfaceDestroyed`, `FlutterEngineNotifyDestroyed` (or `FlutterEngineRemoveView`) must complete synchronously before `surfaceDestroyed()` returns to the OS.
- All swapchains and raster references must be released to prevent `SIGSEGV` or `EGL_BAD_NATIVE_WINDOW` errors on subsequent draw attempts.

## 6. Monotonic Dependency Decrement Invariant
- The internal header baseline in `allowed_internal_headers.yaml` (98 headers across 9 subsystems) is strictly monotonic.
- Zero new files may include internal headers.
- Zero new internal headers may be added.
- When an internal header is eliminated, the YAML baseline must be decremented in the same PR.
- No `// nogncheck` or visibility expansion is allowed.

## 7. Mandatory Perfetto Tracing Invariant
- Every native JNI entrypoint, task runner trampoline, vsync callback, and surface lifecycle transition must emit a `TRACE_EVENT("flutter", ...)` slice.
- Cross-thread async hops must emit flow events visible in Perfetto traces.

## 8. Feature-Flag Shell Isolation, Perfetto Proof & Integration Ratchet Invariant (ADR-0011)
- **Zero `Shell::Create` / `AndroidShellHolder` When Flag is `true`**: When the feature flag (`io.flutter.embedding.android.EnableAndroidEmbedderApi` / `--enable-android-embedder-api`) is `true`, **NO `flutter::Shell` object, `Shell::Create` call, or `AndroidShellHolder` instance** may exist in the Android Embedder path (`shell/platform/android/`). `AndroidShellHolder::AndroidShellHolder` must guard with `FML_CHECK(!use_embedder_api)`.
- **Perfetto & Logcat Proof**: Engine initialization via C-API must emit `TRACE_EVENT0("flutter", "FlutterEmbedderNative::Initialize[C-API]")` and `FML_LOG(IMPORTANT) << "[EMBEDDER_API_PROOF] path=C_EMBEDDER_API proc_table=FlutterEngineInitialize shell_holder=NONE";`.
- **Real-Device Integration & DeviceLab Verification**: Must be verified on a connected Android device using `dev/integration_tests/*` and `dev/devicelab/*` (not merely unit tests) via `dart .agents/skills/embedder-flag-and-integration-verifier/scripts/verify_embedder_flag_and_ratchet.dart`.
- **Monotonic Integration Failure Ratchet**: Tracked in `.agents/embedder_migration/integration_test_ratchet.json`. Even if an unmigrated subsystem's integration test fails when the flag is `true`, its Perfetto trace and logcat must prove `path=C_EMBEDDER_API` (zero `Shell::Create`), and the total number of failing integration tests must monotonically decrease across stacked branches (`failing_count(branch_i) <= failing_count(branch_{i-1})`) with zero regressions in `passing_locked_tests`.
