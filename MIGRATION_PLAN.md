# Flutter Android Embedder Migration: Ultimate Master Plan

This document represents the synthesized blueprint for migrating the Flutter Android Embedder to the public C Embedder API (`embedder.h`). It guarantees 100% feature parity without regressions by ensuring all capabilities (including advanced graphics and Add-to-App spawning) are fully integrated before legacy deletion.

## 1. Architectural Guardrails (The Invariants)

1. **Zero-Regression Feature Parity**: All existing features—including Vulkan External Textures and Add-to-App multi-engine spawning—MUST be fully ported to the new Embedder API *before* the legacy code is deleted. 
2. **Strict C-ABI Protection**: Map directly from JNI structures to `embedder.h` structs (`FlutterSize`, `FlutterPointerEvent`). Do NOT create redundant middle-man C++ structures.
3. **JNI Routing Boundary**: The structural rollout flip (`if (IsEmbedderEnabled())`) MUST occur natively inside the raw JNI boundary function. If false, the unmodified legacy bridge receives the raw `JNIEnv*`. If true, the inputs are mapped to standard C++ primitives and handed to the `JniDelegate`. Host tests achieve decoupling by directly testing the `JniDelegate`.
4. **Dynamic Decoupling & Host Test Safety**: Use `dlsym`/`dlopen` wrapped in an `OSLibraryLoader` interface for Android native bindings (like `AChoreographer`, `AHardwareBuffer`). This MUST be present before any Android-specific graphics are implemented to protect desktop CI.
5. **Pre-Emptive GN Shield**: Do not wait until Phase 5 to quarantine targets. Create a strict `flutter_embedder_native` GN target in Phase 1 that explicitly forbids internal UI/Skia headers, ensuring all new development is structurally validated from Day 1.

## 2. Sequencing Rules (Correcting Oversights)

- **Rule 1: Virtualization & Routing First**: The JNI routing logic (`if/else`), `JniDelegate` adapter, and `OSLibraryLoader` must be implemented in Phase 1 BEFORE subsystem logic. This protects desktop CI and ensures subsequent phases are dynamically exercisable.
- **Rule 2: Atomic Deletion**: Phase 5.2 must atomically delete the legacy components, the legacy fallback CI matrices, AND the fallback `else` branches in the JNI routing logic.
- **Rule 3: Multi-Backend Matrix Testing**: All tests must utilize Parameterized Tests (`TEST_P`) across backends: `Software`, `Skia GL`, `Impeller GL`, `Impeller Vulkan`, and `Impeller Autoselect`. 

---

## 3. The Phased Blueprint

### Phase 1: Foundations, Safety Nets, and C-API Prep
* **1.1 Test Matrix**: Wire up `TEST_P` logic. 
* **1.2 Pre-Emptive GN Quarantine**: Create `flutter_embedder_native` target dependent strictly on `embedder.h`.
* **1.3 JNI DI Interface & Inline Routing**: Implement `if (Flags.isEmbedderApiInputEnabled())` inside the raw JNI boundary. Map true paths to `JniDelegate`.
* **1.4 Dynamic Virtualization**: Implement `OSLibraryLoader` wrapper to `dlopen(libandroid.so)` for `AChoreographer` and native graphics APIs to shield desktop host tests.
* **1.5 C-API Extensions**: Expand `embedder.h` with abstractions for Vulkan External Textures, AHardwareBuffer, and `FlutterEngineSpawn`.

### Phase 2: Decoupled Subsystems
* **2.1 Asset Resolver**: Adapt `APKAssetProvider`.
* **2.2 Dart Callbacks**: Implement `FlutterEngineGetCallbackInformation` hook.
* **2.3 Image Generators**: Hook `AndroidImageGenerator` to `FlutterEngineRegisterImageDecoder`.
* **2.4 Mutator Translation**: Implement `AndroidMutatorsMapper`.

### Phase 3: Advanced Graphics & Multi-Engine Integration
* **3.1 AHardwareBuffer & Vulkan Textures**: Wire the Android implementation to the Phase 1.5 `embedder.h` Vulkan hooks securely relying on Phase 1.4 `OSLibraryLoader`.
* **3.2 SurfaceControl HCPP**: Add dual-mode UI presentation natively into the new pipeline.
* **3.3 Add-to-App Multi-Engine**: Wire `FlutterEngineGroup` natively to `FlutterEngineSpawn`. JNI bridge must capture the raw C pointer to retroactively construct Java wrapper lifecycles.

### Phase 4: E2E Parity
* **4.1 CI E2E Harness**: Verify 100% test passing on `dev/integration_tests/channels` across all Vulkan, Video/Camera, and Add-to-App targets.

### Phase 5: Emancipation (The Purge)
* **5.1 Default Flip**: Change the default settings fallback to `true`.
* **5.2 Legacy Deletion**: Mass-delete `android_context`, `external_view_embedder`, `android_surface`, legacy tests, feature flags, and the dangling `else` JNI logic branches.
* **5.3 Final GN Integration**: Complete migration of `flutter_embedder_native` into `flutter_shell_native` and delete legacy targets.
