# Flutter Android Embedder Migration: Ultimate Master Plan

This document represents the synthesized, battle-hardened blueprint for migrating the Flutter Android Embedder to the public C Embedder API (`embedder.h`). It amalgamates the successful strategies from 5 prior implementation attempts, eliminating structural traps and out-of-sequence feature creep.

## 1. Architectural Guardrails (The Invariants)

1. **Strict C-ABI Protection (The Skia/UI Shield)**: The Android embedder layer MUST NOT leak internal C++ engine dependencies (e.g., `lib/ui`, Skia, Impeller). 
   - All C++ representations bound for the JNI layer MUST use bespoke Android analogs. Examples: Use `AndroidISize` instead of `SkISize`, use `AndroidMutatorsStack` instead of `flutter::MutatorsStack`, use `AndroidPointerData` instead of `flutter::PointerData`.
2. **JNI Inline Routing over Polymorphism**: Do NOT use object-oriented Polymorphic Facades (e.g., `AndroidEngineBridge`). Use explicit runtime conditional routing (`if (IsEmbedderEnabled())`) inside the JNI methods. This enables clean, deletion-only cleanup in Phase 5 without leaving lingering virtual function calls.
3. **Dynamic Decoupling**: Where Android OS subsystems map to Flutter internal singletons, they must be resolved dynamically. For example, use `<dlfcn.h>` and `dlopen("libandroid.so")` to load `AChoreographer` instead of including `impeller/toolkit/android`.
4. **Dependency Inversion in JNI Testing**: (New Pattern) The C++ layer of the Android engine MUST inject dependencies for Java JNI callbacks, allowing C++ `embedder_unittests` to run locally without a full Android HAL runtime.
5. **Granular Strangler Fig Enablers**: (New Pattern) The feature flag flip must not be monolithic. Add granular flags (`--enable-embedder-api-rendering`, `--enable-embedder-api-input`) to support partial rollback and continuous deployment.

## 2. Sequencing Rules (Correcting Oversights)

- **Rule 1: Advanced Features come LAST**: Do not commingle the structural migration with the introduction of new features. Support for `AHardwareBuffer`, Vulkan External Textures, HCPP (SurfaceControl) presentation, and `FlutterEngineSpawn` MUST be deferred to **Phase 6** (Post-Migration). 
- **Rule 2: Atomic Cleanup**: Phase 5.2 must exclusively delete legacy code. The GN target visibility lockdown MUST occur in a separate atomic PR (Phase 5.3).
- **Rule 3: Multi-Backend Matrix Testing**: All tests must utilize Parameterized Tests (`TEST_P`) testing the configuration across all backends: `Software`, `Skia GL`, `Impeller GL`, `Impeller Vulkan`, and `Impeller Autoselect`. Dual flag configuration (Embedder ON vs OFF).

---

## 3. The Phased Blueprint

### Phase 1: Baseline Parity and C-ABI Struct Definitions
* **1.1 Test Matrix**: Wire up `TEST_P` logic for the multi-backend test suite.
* **1.2 C-ABI Structs**: Define `AndroidPointerData`, `AndroidISize`, and `AndroidMutator`. Ensure all parameters crossing `embedder.h` adhere strictly to the `struct_size` backwards-compatibility rule.
* **1.3 Granular Flags**: Wire `--enable-embedder-api-rendering`, `--enable-embedder-api-input`, etc.

### Phase 2: Decoupled Subsystems
* **2.1 Asset Resolver**: Adapt `APKAssetProvider` to `FlutterCustomAssetResolver`.
* **2.2 Dart Callbacks**: Implement `FlutterEngineGetCallbackInformation` hook.
* **2.3 Image Generators**: Adapt `AndroidImageGenerator` to register via `FlutterImageDecoderRegistration`.
* **2.4 Mutator Translation**: Implement `AndroidMutatorsMapper` translating `FlutterPlatformViewMutation` with DPR normalization.

### Phase 3: AndroidEngine Orchestrator (The Strangler)
* **3.1 Dynamic Choreographer**: Load `AChoreographer` bindings via `dlsym`. 
* **3.2 JNI DI Interface**: Abstract JNI method dispatch behind `PlatformViewAndroidJniDelegate` for C++ mocking.
* **3.3 AndroidEngine Class**: Build the core object that wraps the `FLUTTER_API_SYMBOL(FlutterEngine)` functions and Surface Managers.

### Phase 4: JNI Inline Routing
* **4.1 Routing JNI**: Implement `if (Flags.isEmbedderApiInputEnabled()) { engine->DispatchInput() } else { legacy->DispatchInput() }` directly within `platform_view_android_jni_impl.cc`.
* **4.2 CI E2E Harness**: Verify via `dev/integration_tests/channels` running on an emulator. Both flag configurations.

### Phase 5: Emancipation (The Purge)
* **5.1 Default Flip**: Change the default settings fallback to `true`.
* **5.2 Legacy Deletion**: Mass-delete `android_context`, `external_view_embedder`, `platform_view_android_delegate`, and `android_surface`. (No other changes in this PR).
* **5.3 GN Target Isolation**: Update `BUILD.gn` so `flutter_shell_native` strictly depends only on `embedder_as_internal_library`, `fml`, `common`, `third_party`, and native NDK. Set `visibility = [ ":*" ]` to prevent back-linkage.

### Phase 6: Advanced Modernization (Post-Isolation)
* **6.1 AHardwareBuffer & Vulkan Textures**: Integrate zero-copy camera/video backing.
* **6.2 SurfaceControl HCPP**: Add dual-mode UI presentation.
* **6.3 Multi-Engine Spawning**: Surface `FlutterEngineSpawn` to Dart.
