# Flutter Android Embedder Migration: Ultimate Master Plan

This document represents the synthesized blueprint for migrating the Flutter Android Embedder to the public C Embedder API (`embedder.h`). It guarantees 100% feature parity without regressions by ensuring all capabilities (including advanced graphics and Add-to-App spawning) are fully integrated before legacy deletion.

## 1. Architectural Guardrails (The Invariants)

1. **Zero-Regression Feature Parity**: All existing features—including Vulkan External Textures and Add-to-App multi-engine spawning—MUST be fully ported to the new Embedder API *before* the legacy code is deleted. 
2. **Strict C-ABI Protection (Opaque Handles)**: `embedder.h` must remain strictly OS-agnostic. Android-specific OS constructs (`AHardwareBuffer`) must be modeled as opaque handles (e.g., `void* os_handle`) within universal structs, or strictly confined to separate OS-specific extension headers. Do NOT shatter the standard C-ABI.
3. **JNI Routing Boundary & JvmInvoker**: The structural rollout flip (`if (IsEmbedderEnabled())`) MUST occur natively inside the raw JNI boundary function. If true, the `JniDelegate` handles the call, but it MUST be injected with an abstracted `JvmInvoker` interface. This prevents the raw JNI boundary from becoming a monolithic god-class and allows host tests to inject a mocked `JvmInvoker` to test JVM callback logic.
4. **Dynamic Decoupling & Host Test Safety**: Use `dlsym`/`dlopen` wrapped in an `OSLibraryLoader` interface for Android native bindings (like `AChoreographer`, `AHardwareBuffer`). This MUST be present before any Android-specific graphics are implemented to protect desktop CI.
5. **Pre-Emptive GN Shield**: Create a strict `flutter_embedder_native` GN target in Phase 1 that explicitly forbids internal UI/Skia headers, ensuring all new development is structurally validated from Day 1.

## 2. Sequencing Rules (Correcting Oversights)

- **Rule 1: Virtualization & Routing First**: The JNI routing logic (`if/else`), `JniDelegate` adapter (with `JvmInvoker`), and `OSLibraryLoader` must be implemented in Phase 1 BEFORE subsystem logic.
- **Rule 2: Complete Flag Eradication**: Phase 5.2 must completely eradicate the rollout flag from the Java/C++ API surface and obliterate the `if/else` conditional entirely. Hardcode unconditional routing to the new Embedder API to prevent downstream failures.
- **Rule 3: Multi-Backend Matrix Testing**: All tests must utilize Parameterized Tests (`TEST_P`) across backends.

---

## 3. The Phased Blueprint

### Phase 1: Foundations, Safety Nets, and C-API Prep
* **1.1 Test Matrix**: Wire up `TEST_P` logic. 
* **1.2 Pre-Emptive GN Quarantine**: Create `flutter_embedder_native` target dependent strictly on `embedder.h`.
* **1.3 JNI DI Interface & Inline Routing**: Implement `if (Flags.isEmbedderApiInputEnabled())` inside the raw JNI boundary. Inject `JvmInvoker` into `JniDelegate` for abstracted JVM callbacks.
* **1.4 Dynamic Virtualization**: Implement `OSLibraryLoader` wrapper to shield desktop host tests.
* **1.5 C-API Extension (Vulkan)**: Expand `embedder.h` with opaque cross-platform abstractions for Vulkan External Textures.
* **1.6 C-API Extension (AHardwareBuffer)**: Expand `embedder.h` with opaque abstractions for Android `AHardwareBuffer` zero-copy textures.
* **1.7 C-API Extension (Engine Spawn)**: Expand `embedder.h` with `FlutterEngineSpawn` support for Add-to-App capabilities.

### Phase 2: Decoupled Subsystems
* **2.1 Asset Resolver**: Adapt `APKAssetProvider`.
* **2.2 Dart Callbacks**: Implement `FlutterEngineGetCallbackInformation` hook.
* **2.3 Image Generators**: Hook `AndroidImageGenerator` to `FlutterEngineRegisterImageDecoder`.
* **2.4 Mutator Translation**: Implement `AndroidMutatorsMapper`.
* **2.5 Accessibility & Semantics**: Wire the Android accessibility bridge tree native updates.
* **2.6 Platform Views**: Wire `AndroidPlatformView` and `PlatformViewsController` integrations.

### Phase 3: Advanced Graphics & Multi-Engine Integration
* **3.1 AHardwareBuffer**: Wire the Android implementation to the Phase 1 opaque hooks via `OSLibraryLoader`.
* **3.2 Vulkan External Textures**: Wire the Android Vulkan instances relying on the `OSLibraryLoader` virtualization.
* **3.3 SurfaceControl HCPP**: Add dual-mode UI presentation natively into the new pipeline.
* **3.4 Add-to-App Multi-Engine**: Wire `FlutterEngineGroup` natively to `FlutterEngineSpawn`. Java wrappers must be explicitly wired with a JNI `PhantomReference` or `Cleaner` registry catching GC events to route `FlutterEngineShutdown` and prevent pointer leaks.

### Phase 4: E2E Parity
* **4.1 CI E2E Harness**: Verify 100% test passing on `dev/integration_tests/channels`.

### Phase 5: Emancipation (The Purge)
* **5.1 Default Flip**: Change the default settings fallback to `true`.
* **5.2 Legacy Deletion (Subsystems)**: Delete legacy classes for Asset, Callback, Image, and Mutators.
* **5.3 Legacy Deletion (Platform Views & Semantics)**: Purge legacy accessibility and platform view hierarchies.
* **5.4 Legacy Deletion (Graphics Pipeline)**: Delete `android_context`, `external_view_embedder`, and `android_surface`.
* **5.5 Flag Obliteration**: Obliterate the `IsEmbedderEnabled` flag entirely and hardcode unconditionally to the new Embedder API.
* **5.6 Final GN Integration**: Migrate `flutter_embedder_native` into `flutter_shell_native` AND explicitly purge all legacy UI/Skia dependencies from `flutter_shell_native`'s `BUILD.gn` to prevent Post-Migration Relapse.
