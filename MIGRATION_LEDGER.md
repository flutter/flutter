# Migration Ledger: Detailed Execution & Validation Tracking

This ledger strictly enforces that **all tests are explicitly run and validated** throughout the atomic migration steps. A phase cannot be marked complete until both the implementation PR has merged and the corresponding test matrix validations are explicitly verified as passing locally and in CI.

## Phase 1: Foundations, Safety Nets, and C-API Prep
- [ ] **1.1 Matrix Initialization**:
    - [ ] `TEST_P` Multi-backend test matrix initialized.
    - [ ] *Validation*: `embedder_unittests` pass locally on macOS/Linux hosts.
- [ ] **1.2 Pre-Emptive GN Quarantine**:
    - [ ] `flutter_embedder_native` target initialized strictly forbidding Skia/UI headers.
    - [ ] *Validation*: `ninja -C out/android_debug_unopt flutter_embedder_native` builds successfully.
- [ ] **1.3 JNI Routing & Mocking**:
    - [ ] `JvmInvoker` abstracted; JNI routing wired to `JniDelegate`.
    - [ ] *Validation*: Host-side C++ Mocking validates routing flip without crashing.
- [ ] **1.4 Dynamic Virtualization**:
    - [ ] `OSLibraryLoader` implemented for mocked dynamic Android symbol lookups.
    - [ ] *Validation*: Host desktop CI pipeline is verified completely green (no macOS `dlopen` segfaults).
- [ ] **1.5 C-API Extension (Vulkan)**:
    - [ ] `embedder.h` API extension: Vulkan External Textures (opaque structs).
    - [ ] *Validation*: `embedder_unittests` covering new structs pass.
- [ ] **1.6 C-API Extension (AHardwareBuffer)**:
    - [ ] `embedder.h` API extension: AHardwareBuffer (opaque structs).
    - [ ] *Validation*: `embedder_unittests` covering new structs pass.
- [ ] **1.7 C-API Extension (Engine Spawn)**:
    - [ ] `embedder.h` API extension: `FlutterEngineSpawn`.
    - [ ] *Validation*: `embedder_unittests` covering EngineSpawn pass.

## Phase 2: Decoupled Subsystems
*For each subsystem, both Java `android_test` and C++ `flutter_shell_native_unittests` must pass before proceeding.*
- [ ] **2.1 Asset Resolver**: 
    - [ ] `APKAssetProvider` adapted to Embedder Custom Asset Resolver.
    - [ ] *Validation*: Asset resolution unit tests pass.
- [ ] **2.2 Dart Callbacks**: 
    - [ ] Dart Callback lookup API integrated.
    - [ ] *Validation*: Engine callback C++ integration tests pass.
- [ ] **2.3 Image Generators**: 
    - [ ] `AndroidImageGenerator` hooked to `FlutterEngineRegisterImageDecoder`.
    - [ ] *Validation*: Image decoding Java/JNI tests pass.
- [ ] **2.4 Mutator Translation**: 
    - [ ] `AndroidMutatorsMapper` implemented.
    - [ ] *Validation*: Platform view mutator stack unit tests pass.
- [ ] **2.5 Accessibility & Semantics**: 
    - [ ] `Accessibility` & `Semantics` natively wired.
    - [ ] *Validation*: `dev/integration_tests/android_semantics` passes across CI matrix.
- [ ] **2.6 Platform Views**: 
    - [ ] `PlatformViewsController` integrations wired.
    - [ ] *Validation*: `dev/integration_tests/android_views` passes (texture & hybrid composition).

## Phase 3: Advanced Graphics & Multi-Engine Integration
- [ ] **3.1 AHardwareBuffer**:
    - [ ] `AHardwareBuffer` wired via Virtualization.
    - [ ] *Validation*: Zero-copy texture allocation C++ tests pass.
- [ ] **3.2 Vulkan External Textures**:
    - [ ] `Vulkan External Textures` wired.
    - [ ] *Validation*: E2E Vulkan video playback tests pass (Camera/VideoPlayer plugins).
- [ ] **3.3 SurfaceControl HCPP**:
    - [ ] SurfaceControl HCPP dual-mode presentation enabled.
    - [ ] *Validation*: Native presentation path tests pass in `android_views`.
- [ ] **3.4 Multi-Engine & Add-to-App**:
    - [ ] Add-to-App capabilities wired to `FlutterEngineSpawn` with Java `Cleaner`/`PhantomReference` bindings.
    - [ ] *Validation*: Engine lifecycle/GC memory leak unit tests pass.

## Phase 4: Extreme E2E Parity Validation
*Before ANY legacy code is deleted in Phase 5, the entire engine and framework E2E matrix must be run unconditionally against the new Embedder API logic.*
- [ ] **4.1 Engine Unit Tests**:
    - [ ] `embedder_unittests` (Host macOS/Linux) - Passed.
    - [ ] `flutter_shell_native_unittests` (Android Emulator) - Passed.
- [ ] **4.2 Framework Integration Tests (Skia GL / Software)**:
    - [ ] `dev/integration_tests/android_views` - Passed.
    - [ ] `dev/integration_tests/channels` - Passed.
    - [ ] `dev/integration_tests/platform_interaction` - Passed.
- [ ] **4.3 Framework Integration Tests (Impeller)**:
    - [ ] `dev/integration_tests/android_views` (Backend: Impeller OpenGLES) - Passed.
    - [ ] `dev/integration_tests/android_views` (Backend: Impeller Vulkan) - Passed.

## Phase 5: Emancipation
- [ ] **5.1 Target Flip**: 
    - [ ] Embedder flags defaulted to `true`.
    - [ ] *Validation*: CI remains unconditionally green on default runs.
- [ ] **5.2 Legacy Deletion (Subsystems)**: 
    - [ ] Assets, Images, Callbacks, Mutators wiped. 
    - [ ] *Validation*: Build compiles successfully; tests pass.
- [ ] **5.3 Legacy Deletion (Platform Views/Semantics)**: 
    - [ ] Platform views and semantics wiped.
    - [ ] *Validation*: Build compiles successfully; tests pass.
- [ ] **5.4 Legacy Deletion (Graphics Pipeline)**: 
    - [ ] `android_context`, `android_surface` wiped.
    - [ ] *Validation*: Build compiles successfully; tests pass.
- [ ] **5.5 Flag Obliteration**: 
    - [ ] Flags pruned and routing hardcoded unconditionally.
    - [ ] *Validation*: CLI flags `--enable-embedder-api` are rejected by build scripts appropriately.
- [ ] **5.6 Strict GN Target Isolation**: 
    - [ ] `flutter_shell_native` internal Skia/UI dependencies purged; targets merged.
    - [ ] *Validation*: Clean `gn` re-run; `ninja` builds successfully assuring absolute GN C-ABI quarantine.
