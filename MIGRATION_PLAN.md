# Flutter Android Embedder Migration: Ultimate Master Plan

This document represents the synthesized blueprint for migrating the Flutter Android Embedder to the public C Embedder API (`embedder.h`). It guarantees 100% feature parity without regressions by ensuring all capabilities (including advanced graphics and Add-to-App spawning) are fully integrated before legacy deletion.

## 1. Architectural Guardrails (The Invariants)

1. **Zero-Regression Feature Parity**: All existing features—including Vulkan External Textures and Add-to-App multi-engine spawning—MUST be fully ported to the new Embedder API *before* the legacy code is deleted. We cannot afford temporary regressions on `master`.
2. **Strict C-ABI Protection**: Map directly from JNI structures to `embedder.h` structs (`FlutterSize`, `FlutterPointerEvent`). Do NOT create redundant middle-man C++ structures.
3. **JNI Inline Routing vs. Mocking Boundary**: Use structural `if (IsEmbedderEnabled())` conditionally inside the JNI methods to route to either the legacy `PlatformView` or the new `AndroidEngine`. To support host-side C++ testing without Android HAL, create a strict `JniDelegate` adapter boundary for Java callbacks.
4. **Dynamic Decoupling & Host Test Safety**: Use `dlsym`/`dlopen` wrapped in an `OSLibraryLoader` interface for Android native bindings (like `AChoreographer`) so `embedder_unittests` running on macOS/Linux hosts can fake the lookup.
5. **Granular Strangler Fig Enablers**: Add granular flags (`--enable-embedder-api-*`) to support partial rollback. These must be deleted alongside the legacy code in Phase 5.

## 2. Sequencing Rules (Correcting Oversights)

- **Rule 1: Prepare the C-API First**: Abstractions for Vulkan External Textures, AHardwareBuffer, and Engine Spawning must be added to `embedder.h` in Phase 1 to prevent GN quarantine boundary violations later.
- **Rule 2: Atomic Cleanup**: Phase 5 must be split into ultra-atomic PRs to reduce review complexity. Phase 5.2 must *exclusively* delete legacy code. Phase 5.3 must *exclusively* lock the GN visibility target. New features must not be implemented during Phase 5.
- **Rule 3: Multi-Backend Matrix Testing**: All tests must utilize Parameterized Tests (`TEST_P`) across backends: `Software`, `Skia GL`, `Impeller GL`, `Impeller Vulkan`, and `Impeller Autoselect`. 

---

## 3. The Phased Blueprint

### Phase 1: Baseline Parity, C-API Prep, and Test Harness
* **1.1 Test Matrix**: Wire up `TEST_P` logic. 
* **1.2 C-API Extensions**: Expand `embedder.h` with abstractions for Vulkan External Textures, AHardwareBuffer, and `FlutterEngineSpawn`.
* **1.3 Granular Flags**: Wire `--enable-embedder-api` parameters.

### Phase 2: Decoupled Subsystems
* **2.1 Asset Resolver**: Adapt `APKAssetProvider`.
* **2.2 Dart Callbacks**: Implement `FlutterEngineGetCallbackInformation` hook.
* **2.3 Image Generators**: Hook `AndroidImageGenerator` to `FlutterEngineRegisterImageDecoder`.
* **2.4 Mutator Translation**: Implement `AndroidMutatorsMapper`.

### Phase 3: Advanced Graphics & Multi-Engine Integration
* **3.1 AHardwareBuffer & Vulkan Textures**: Wire the Android implementation to the Phase 1.2 `embedder.h` Vulkan hooks.
* **3.2 SurfaceControl HCPP**: Add dual-mode UI presentation natively into the new pipeline.
* **3.3 Add-to-App Multi-Engine**: Wire `FlutterEngineGroup` natively to `FlutterEngineSpawn`.

### Phase 4: AndroidEngine Orchestrator & E2E Parity
* **4.1 Dynamic Choreographer**: Implement `OSLibraryLoader` wrapper to `dlopen(libandroid.so)` for `AChoreographer`.
* **4.2 JNI DI Interface & Inline Routing**: Abstract JNI callback dispatch and conditionally route incoming Java inputs via `if (Flags.isEmbedderApiInputEnabled())`.
* **4.3 CI E2E Harness**: Verify 100% test passing on `dev/integration_tests/channels` across all Vulkan, Video/Camera, and Add-to-App targets.

### Phase 5: Emancipation (The Purge)
* **5.1 Default Flip**: Change the default settings fallback to `true`.
* **5.2 Legacy Deletion**: Mass-delete `android_context`, `external_view_embedder`, and `android_surface`. (No other logic changes permitted in this PR).
* **5.3 GN Target Isolation**: Update `BUILD.gn` so `flutter_shell_native` strictly depends only on authorized core modules (`embedder_as_internal_library`, `fml`, native NDK).
