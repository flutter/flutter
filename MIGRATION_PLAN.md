# Flutter Android Embedder Migration: Ultimate Master Plan

This document represents the synthesized blueprint for migrating the Flutter Android Embedder to the public C Embedder API (`embedder.h`). It guarantees 100% feature parity without regressions by ensuring all capabilities (including advanced graphics and Add-to-App spawning) are fully integrated before legacy deletion.

## 1. Architectural Guardrails (The Invariants)

1. **Zero-Regression Feature Parity**: All existing features—including Vulkan External Textures and Add-to-App multi-engine spawning—MUST be fully ported to the new Embedder API *before* the legacy code is deleted. 
2. **Strict C-ABI Protection**: Map directly from JNI structures to `embedder.h` structs (`FlutterSize`, `FlutterPointerEvent`). Do NOT create redundant middle-man C++ structures.
3. **JNI Pass-Through & Mocking Boundary**: The raw JNI boundary (`Java_io_flutter_...`) must be a dumb pass-through layer that immediately converts `JNIEnv` arguments into standard C++ abstractions and hands them to a `JniDelegate`. All structural conditional routing (`if (IsEmbedderEnabled())`) MUST occur *behind* this delegate boundary to enable host-side C++ Mocking without Android's HAL.
4. **Dynamic Decoupling & Host Test Safety**: Use `dlsym`/`dlopen` wrapped in an `OSLibraryLoader` interface for Android native bindings (like `AChoreographer`) so `embedder_unittests` running on macOS/Linux hosts can fake the lookup.
5. **Pre-Emptive GN Shield**: Do not wait until Phase 5 to quarantine targets. Create a strict `flutter_embedder_native` GN target in Phase 1 that explicitly forbids internal UI/Skia headers, ensuring all new development is structurally validated from Day 1.

## 2. Sequencing Rules (Correcting Oversights)

- **Rule 1: JNI Routing First (No Dead Code)**: The JNI routing logic (`if/else`) and `JniDelegate` adapter must be implemented in Phase 1 BEFORE subsystem logic. This ensures Phases 2 and 3 can be dynamically exercised during development instead of resulting in a "big bang" integration.
- **Rule 2: Atomic Deletion**: Phase 5.2 must atomically delete the legacy components, the legacy fallback CI matrices, AND the fallback `else` branches in the JNI routing logic. This prevents dangling references from breaking compilation.
- **Rule 3: Multi-Backend Matrix Testing**: All tests must utilize Parameterized Tests (`TEST_P`) across backends: `Software`, `Skia GL`, `Impeller GL`, `Impeller Vulkan`, and `Impeller Autoselect`. 

---

## 3. The Phased Blueprint

### Phase 1: JNI Routing, Safety Nets, and C-API Prep
* **1.1 Test Matrix**: Wire up `TEST_P` logic. 
* **1.2 Pre-Emptive GN Quarantine**: Create `flutter_embedder_native` target dependent strictly on `embedder.h` for all new implementation code to securely dodge the legacy target's exposed UI headers.
* **1.3 JNI DI Interface & Inline Routing**: Abstract JNI callback dispatch behind `JniDelegate`. Implement `if (Flags.isEmbedderApiInputEnabled())` behind this mock boundary.
* **1.4 C-API Extensions**: Expand `embedder.h` with abstractions for Vulkan External Textures, AHardwareBuffer, and `FlutterEngineSpawn`.

### Phase 2: Decoupled Subsystems
* **2.1 Asset Resolver**: Adapt `APKAssetProvider`.
* **2.2 Dart Callbacks**: Implement `FlutterEngineGetCallbackInformation` hook.
* **2.3 Image Generators**: Hook `AndroidImageGenerator` to `FlutterEngineRegisterImageDecoder`.
* **2.4 Mutator Translation**: Implement `AndroidMutatorsMapper`.

### Phase 3: Advanced Graphics & Multi-Engine Integration
* **3.1 AHardwareBuffer & Vulkan Textures**: Wire the Android implementation to the Phase 1.4 `embedder.h` Vulkan hooks.
* **3.2 SurfaceControl HCPP**: Add dual-mode UI presentation natively into the new pipeline.
* **3.3 Add-to-App Multi-Engine**: Wire `FlutterEngineGroup` natively to `FlutterEngineSpawn`. JNI bridge must capture the raw C pointer to retroactively construct Java wrapper lifecycles.

### Phase 4: AndroidEngine Orchestrator & E2E Parity
* **4.1 Dynamic Choreographer**: Implement `OSLibraryLoader` wrapper to `dlopen(libandroid.so)` for `AChoreographer`.
* **4.2 CI E2E Harness**: Verify 100% test passing on `dev/integration_tests/channels` across all Vulkan, Video/Camera, and Add-to-App targets.

### Phase 5: Emancipation (The Purge)
* **5.1 Default Flip**: Change the default settings fallback to `true`.
* **5.2 Legacy Deletion**: Mass-delete `android_context`, `external_view_embedder`, `android_surface`, legacy tests, feature flags, and the dangling `else` JNI logic branches.
* **5.3 Final GN Integration**: Complete migration of `flutter_embedder_native` into `flutter_shell_native` and delete legacy targets.
