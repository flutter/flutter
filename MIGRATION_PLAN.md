# Flutter Android Embedder Migration: Ultimate Master Plan

This document represents the synthesized, battle-hardened blueprint for migrating the Flutter Android Embedder to the public C Embedder API (`embedder.h`). It amalgamates the successful strategies from 5 prior implementation attempts, eliminating structural traps and out-of-sequence feature creep.

## 1. Architectural Guardrails (The Invariants)

1. **Strict C-ABI Protection**: The Android embedder layer MUST NOT leak internal C++ engine dependencies (e.g., `lib/ui`, Skia, Impeller). Map directly from JNI structures to `embedder.h` structs (e.g., `FlutterSize`, `FlutterPointerEvent`). Do NOT create redundant middle-man C++ structures (`AndroidISize`) unless strictly required.
2. **JNI Inline Routing vs. Mocking Boundary**: Use structural `if (IsEmbedderEnabled())` conditionally inside the JNI methods to route to either the legacy `PlatformView` or the new `AndroidEngine`. To support host-side C++ testing without Android HAL, create a strict `JniDelegate` adapter boundary for Java callbacks. (This is the *only* permitted polymorphic boundary).
3. **Dynamic Decoupling & Host Test Safety**: Android OS level bindings (like `AChoreographer`) cannot be linked statically. Use `dlsym`/`dlopen`—BUT wrap this in an `OSLibraryLoader` interface so `embedder_unittests` running on macOS/Linux hosts can fake the lookup rather than segfaulting on `null`.
4. **Granular Strangler Fig Enablers**: Add granular flags (`--enable-embedder-api-rendering`, `--enable-embedder-api-input`) to support partial rollback. **Critically**, these flags MUST be deleted immediately when the legacy code is burned in Phase 5 to prevent black-hole state crashes.

## 2. Sequencing Rules (Correcting Oversights)

- **Rule 1: Advanced Features come LAST (But prep their C-APIs first)**: Support for `AHardwareBuffer`, Vulkan External Textures, and `FlutterEngineSpawn` MUST be deferred to **Phase 6**. However, the `embedder.h` core abstractions for these features must be prepared in Phase 1 so they don't break the Phase 5 GN quarantine. E2E tests (Phase 4) testing camera/video on Vulkan must be temporarily skipped until Phase 6 Vulkan External Textures land.
- **Rule 2: Atomic Cleanup**: Phase 5.2 must exclusively delete legacy code and all fallback feature flags/test matrices. The GN target visibility lockdown MUST occur in a separate atomic PR (Phase 5.3).
- **Rule 3: Multi-Backend Matrix Testing**: All tests must utilize Parameterized Tests (`TEST_P`) across backends: `Software`, `Skia GL`, `Impeller GL`, `Impeller Vulkan`, and `Impeller Autoselect`. 

---

## 3. The Phased Blueprint

### Phase 1: Baseline Parity, C-API Prep, and Test Harness
* **1.1 Test Matrix**: Wire up `TEST_P` logic for the multi-backend test suite.
* **1.2 C-API Extensions**: Expand `embedder.h` with abstractions for Vulkan External Textures and AHardwareBuffer (so Phase 6 can implement them without breaking GN isolation boundaries later).
* **1.3 Granular Flags**: Wire `--enable-embedder-api-rendering`, `--enable-embedder-api-input`, etc.

### Phase 2: Decoupled Subsystems
* **2.1 Asset Resolver**: Adapt `APKAssetProvider` to `FlutterCustomAssetResolver`.
* **2.2 Dart Callbacks**: Implement `FlutterEngineGetCallbackInformation` hook.
* **2.3 Image Generators**: Adapt `AndroidImageGenerator` to register via `FlutterImageDecoderRegistration`.
* **2.4 Mutator Translation**: Implement `AndroidMutatorsMapper` translating `FlutterPlatformViewMutation` directly to JNI (DPR-normalized).

### Phase 3: AndroidEngine Orchestrator (The Strangler)
* **3.1 Dynamic Choreographer**: Implement `OSLibraryLoader` wrapper to `dlopen(libandroid.so)` for `AChoreographer`, ensuring macOS/Linux host tests can provide a stub.
* **3.2 JNI DI Interface**: Abstract JNI method dispatch behind `PlatformViewAndroidJniDelegate` for C++ mocking.
* **3.3 AndroidEngine Class**: Build the core object that wraps the `FLUTTER_API_SYMBOL(FlutterEngine)` functions and Surface Managers.

### Phase 4: JNI Inline Routing
* **4.1 Routing JNI**: Implement `if (Flags.isEmbedderApiInputEnabled()) { engine->DispatchInput() } else { legacy->DispatchInput() }` directly within `platform_view_android_jni_impl.cc`.
* **4.2 CI E2E Harness**: Verify via `dev/integration_tests/channels` running on an emulator. Exclude Vulkan Video/Camera external texture tests until Phase 6.

### Phase 5: Emancipation (The Purge)
* **5.1 Default Flip**: Change the default settings fallback to `true`.
* **5.2 Legacy Deletion**: Mass-delete `android_context`, `external_view_embedder`, and `android_surface`. **CRITICAL**: Delete all `--enable-embedder-api-*` flags, fallback logic, and legacy `TEST_P` matrices.
* **5.3 GN Target Isolation**: Update `BUILD.gn` so `flutter_shell_native` strictly depends only on `embedder_as_internal_library`, `fml`, `common`, `third_party`, `icu` and native NDK. Set `visibility = [ ":*" ]`.

### Phase 6: Advanced Modernization (Post-Isolation)
* **6.1 AHardwareBuffer & Vulkan Textures**: Integrate zero-copy camera/video backing using the C-APIs prepped in Phase 1. Enable Vulkan E2E video tests.
* **6.2 SurfaceControl HCPP**: Add dual-mode UI presentation.
* **6.3 Multi-Engine Spawning**: Surface `FlutterEngineSpawn` to Dart.
