# Migration Ledger: Detailed Execution & Validation Tracking

This ledger strictly enforces that **all tests are explicitly run and validated** throughout the atomic migration steps. A phase cannot be marked complete until both the implementation PR has merged and the corresponding test matrix validations are explicitly verified as passing locally and in CI.

## Phase 1: Foundations, Safety Nets, and C-API Prep
- [ ] **1.1 Matrix Initialization**:
    - [ ] `TEST_P` Multi-backend test matrix initialized.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR and feedback addressed.
    - [ ] *Validation*: `embedder_unittests` pass locally on macOS/Linux hosts.
- [ ] **1.2 Pre-Emptive GN Quarantine**:
    - [ ] `flutter_embedder_native` target initialized strictly forbidding Skia/UI headers.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR and feedback addressed.
    - [ ] *Validation*: `ninja -C out/android_debug_unopt flutter_embedder_native` builds successfully.
- [ ] **1.3 JNI Routing & Mocking**:
    - [ ] `JvmInvoker` abstracted; JNI routing wired to `JniDelegate`.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR and feedback addressed.
    - [ ] *Validation*: Host-side C++ Mocking validates routing flip without crashing.
- [ ] **1.4 Dynamic Virtualization**:
    - [ ] `OSLibraryLoader` implemented for mocked dynamic Android symbol lookups.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR and feedback addressed.
    - [ ] *Validation*: Host desktop CI pipeline is verified completely green (no macOS `dlopen` segfaults).
- [ ] **1.5 C-API Extension (Vulkan)**:
    - [ ] `embedder.h` API extension: Vulkan External Textures (opaque structs).
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR and feedback addressed.
    - [ ] *Validation*: `embedder_unittests` covering new structs pass.
- [ ] **1.6 C-API Extension (AHardwareBuffer)**:
    - [ ] `embedder.h` API extension: AHardwareBuffer (opaque structs).
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR and feedback addressed.
    - [ ] *Validation*: `embedder_unittests` covering new structs pass.
- [ ] **1.7 C-API Extension (Engine Spawn)**:
    - [ ] `embedder.h` API extension: `FlutterEngineSpawn`.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR and feedback addressed.
    - [ ] *Validation*: `embedder_unittests` covering EngineSpawn pass.


- [ ] **Phase 1 Parity Checkpoint**:
    - [ ] *Validation*: Framework unit tests (`flutter test`) and `flutter_shell_native_unittests` run globally across the directory, ensuring no cascading failures.
    - [ ] *Validation*: Golden tests verified to ensure zero pixel-level regressions on Android canvases. **Strict Golden Rule**: Local engine builds must be tested against the baseline framework. Only the baseline (without local engine build) is permitted to update goldens. If a local engine build fails a golden test, you must fix the C++ native implementation in the local engine—you cannot update the golden image to match the flawed output.
    - [ ] *Validation*: Core integration tests (`dev/integration_tests/*`) pass unconditionally.
    - [ ] *Review*: Any deviations or failing tests are caught, adversarially root-caused, and pushed back into the specific atomic branches for this phase before proceeding.

## Phase 2: Decoupled Subsystems
*For each subsystem, both Java `android_test` and C++ `flutter_shell_native_unittests` must pass before proceeding.*
- [ ] **2.1 Asset Resolver**: 
    - [ ] `APKAssetProvider` adapted to Embedder Custom Asset Resolver.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR and feedback addressed.
    - [ ] *Validation*: `//shell/platform/android:robolectric_tests` (`FlutterLoaderTest.java`, `ApplicationInfoLoaderTest.java`) AND `//shell/platform/android:flutter_shell_native_unittests` (`apk_asset_provider_unittests.cc`) pass.
- [ ] **2.2 Dart Callbacks**: 
    - [ ] Dart Callback lookup API integrated.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR and feedback addressed.
    - [ ] *Validation*: `//shell/platform/android:robolectric_tests` (`FlutterJNITest.java`) AND `//shell/platform/android:flutter_shell_native_unittests` (`platform_view_android_delegate_unittests.cc`) pass.
- [ ] **2.3 Image Generators**: 
    - [ ] `AndroidImageGenerator` hooked to `FlutterEngineRegisterImageDecoder`.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR and feedback addressed.
    - [ ] *Validation*: `//shell/platform/android:robolectric_tests` (`ImageDecoderDefaultImplTest.java`, `ImageDecoderHeifApi36ImplTest.java`) AND `//shell/platform/android:flutter_shell_native_unittests` (`image_lru_unittests.cc`) pass.
- [ ] **2.4 Mutator Translation**: 
    - [ ] `AndroidMutatorsMapper` implemented.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR and feedback addressed.
    - [ ] *Validation*: `//shell/platform/android:robolectric_tests` (`FlutterMutatorViewTest.java`) AND `//shell/platform/android:flutter_shell_native_unittests` (`android_mutator_unittests.cc`) pass.
- [ ] **2.5 Accessibility & Semantics**: 
    - [ ] `Accessibility` & `Semantics` natively wired.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR and feedback addressed.
    - [ ] *Validation*: `dev/integration_tests/android_semantics` passes across CI matrix.
- [ ] **2.6 Platform Views**: 
    - [ ] `PlatformViewsController` integrations wired.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR and feedback addressed.
    - [ ] *Validation*: `dev/integration_tests/android_views` passes (texture & hybrid composition).


- [ ] **Phase 2 Parity Checkpoint**:
    - [ ] *Validation*: Framework unit tests (`flutter test`) and `flutter_shell_native_unittests` run globally across the directory, ensuring no cascading failures.
    - [ ] *Validation*: Golden tests verified to ensure zero pixel-level regressions on Android canvases. **Strict Golden Rule**: Local engine builds must be tested against the baseline framework. Only the baseline (without local engine build) is permitted to update goldens. If a local engine build fails a golden test, you must fix the C++ native implementation in the local engine—you cannot update the golden image to match the flawed output.
    - [ ] *Validation*: Core integration tests (`dev/integration_tests/*`) pass unconditionally.
    - [ ] *Review*: Any deviations or failing tests are caught, adversarially root-caused, and pushed back into the specific atomic branches for this phase before proceeding.

## Phase 3: Advanced Graphics & Multi-Engine Integration
- [ ] **3.1 AHardwareBuffer**:
    - [ ] `AHardwareBuffer` wired via Virtualization.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR and feedback addressed.
    - [ ] *Validation*: `//shell/platform/android:flutter_shell_native_unittests` (`hardware_buffer_unittests.cc`, `android_surface_unittests.cc`) pass.
- [ ] **3.2 Vulkan External Textures**:
    - [ ] `Vulkan External Textures` wired.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR and feedback addressed.
    - [ ] *Validation*: `dev/integration_tests/android_views` AND `dev/devicelab/bin/tasks/plugin_test_android_variants.dart` pass using Impeller Vulkan backend.
- [ ] **3.3 SurfaceControl HCPP**:
    - [ ] SurfaceControl HCPP dual-mode presentation enabled.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR and feedback addressed.
    - [ ] *Validation*: Native presentation path tests pass in `android_views`.
- [ ] **3.4 Multi-Engine & Add-to-App**:
    - [ ] Add-to-App capabilities wired to `FlutterEngineSpawn` with Java `Cleaner`/`PhantomReference` bindings.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR and feedback addressed.
    - [ ] *Validation*: `dev/devicelab/bin/tasks/build_android_host_app_with_module_source.dart` succeeds.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR and feedback addressed.
    - [ ] *Validation*: `//shell/platform/android:robolectric_tests` (`FlutterEngineGroupTest.java`, `FlutterEngineTest.java`) AND `//shell/platform/android:flutter_shell_native_unittests` (`android_shell_holder_unittests.cc`) pass.


- [ ] **Phase 3 Parity Checkpoint**:
    - [ ] *Validation*: Framework unit tests (`flutter test`) and `flutter_shell_native_unittests` run globally across the directory, ensuring no cascading failures.
    - [ ] *Validation*: Golden tests verified to ensure zero pixel-level regressions on Android canvases. **Strict Golden Rule**: Local engine builds must be tested against the baseline framework. Only the baseline (without local engine build) is permitted to update goldens. If a local engine build fails a golden test, you must fix the C++ native implementation in the local engine—you cannot update the golden image to match the flawed output.
    - [ ] *Validation*: Core integration tests (`dev/integration_tests/*`) pass unconditionally.
    - [ ] *Review*: Any deviations or failing tests are caught, adversarially root-caused, and pushed back into the specific atomic branches for this phase before proceeding.

## Phase 4: Extreme E2E Parity Validation
*Before ANY legacy code is deleted in Phase 5, the entire engine, framework, and DeviceLab matrices must be run unconditionally against the new Embedder API logic.*
- [ ] **4.1 Engine Unit Tests**:
    - [ ] `embedder_unittests` (Host macOS/Linux) - Passed.
    - [ ] `flutter_shell_native_unittests` (Android Emulator) - Passed.
- [ ] **4.2 Framework Integration Tests (Skia GL / Software)**:
    - [ ] `dev/integration_tests/android_views` - Passed.
    - [ ] `dev/integration_tests/channels` - Passed.
    - [ ] `dev/integration_tests/platform_interaction` - Passed.
    - [ ] `dev/integration_tests/android_engine_test` - Passed.
- [ ] **4.3 Framework Integration Tests (Impeller)**:
    - [ ] `dev/integration_tests/android_views` (Backend: Impeller OpenGLES) - Passed.
    - [ ] `dev/integration_tests/android_views` (Backend: Impeller Vulkan) - Passed.
- [ ] **4.4 DeviceLab Android Lifecycle & Platform Views**:
    - [ ] `dev/devicelab/bin/tasks/android_lifecycles_test.dart` - Passed.
    - [ ] `dev/devicelab/bin/tasks/android_verified_input_test.dart` - Passed.
    - [ ] `dev/devicelab/bin/tasks/android_semantics_integration_test.dart` - Passed.
    - [ ] `dev/devicelab/bin/tasks/hybrid_android_views_integration_test.dart` - Passed.
    - [ ] `dev/devicelab/bin/tasks/android_engine_flags_debug_test.dart` - Passed.
    - [ ] `dev/devicelab/bin/tasks/android_engine_flags_release_test.dart` - Passed.
- [ ] **4.5 DeviceLab Performance & Memory Parity (No Regressions)**:
    - [ ] `dev/devicelab/bin/tasks/complex_layout_android__scroll_smoothness.dart` - Passed.
    - [ ] `dev/devicelab/bin/tasks/android_view_scroll_perf__timeline_summary.dart` - Passed.
    - [ ] `dev/devicelab/bin/tasks/flutter_engine_group_performance.dart` - Passed.

## Phase 5: Emancipation
- [ ] **5.1 Target Flip**: 
    - [ ] Embedder flags defaulted to `true`.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR and feedback addressed.
    - [ ] *Validation*: CI remains unconditionally green on default runs.
- [ ] **5.2 Legacy Deletion (Subsystems)**: 
    - [ ] Assets, Images, Callbacks, Mutators wiped. 
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR and feedback addressed.
    - [ ] *Validation*: `ninja -C out/android_debug_unopt flutter_shell_native_unittests` compiles successfully AND `//shell/platform/android:robolectric_tests` passes entirely without legacy code.
- [ ] **5.3 Legacy Deletion (Platform Views/Semantics)**: 
    - [ ] Platform views and semantics wiped.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR and feedback addressed.
    - [ ] *Validation*: `ninja -C out/android_debug_unopt flutter_shell_native_unittests` compiles successfully AND `//shell/platform/android:robolectric_tests` passes entirely without legacy code.
- [ ] **5.4 Legacy Deletion (Graphics Pipeline)**: 
    - [ ] `android_context`, `android_surface` wiped.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR and feedback addressed.
    - [ ] *Validation*: `ninja -C out/android_debug_unopt flutter_shell_native_unittests` compiles successfully AND `//shell/platform/android:robolectric_tests` passes entirely without legacy code.
- [ ] **5.5 Flag Obliteration**: 
    - [ ] Flags pruned and routing hardcoded unconditionally.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR and feedback addressed.
    - [ ] *Validation*: CLI flags `--enable-embedder-api` are rejected by build scripts appropriately.
- [ ] **5.6 Strict GN Target Isolation**: 
    - [ ] `flutter_shell_native` internal Skia/UI dependencies purged; targets merged.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR and feedback addressed.
    - [ ] *Validation*: Clean `gn` re-run; `ninja` builds successfully assuring absolute GN C-ABI quarantine.

- [ ] **Phase 5 Parity Checkpoint**:
    - [ ] *Validation*: Framework unit tests (`flutter test`) and `flutter_shell_native_unittests` run globally across the directory, ensuring no cascading failures.
    - [ ] *Validation*: Golden tests verified to ensure zero pixel-level regressions on Android canvases. **Strict Golden Rule**: Local engine builds must be tested against the baseline framework. Only the baseline (without local engine build) is permitted to update goldens. If a local engine build fails a golden test, you must fix the C++ native implementation in the local engine—you cannot update the golden image to match the flawed output.
    - [ ] *Validation*: Core integration tests (`dev/integration_tests/*`) pass unconditionally.
    - [ ] *Review*: Any deviations or failing tests are caught, adversarially root-caused, and pushed back into the specific atomic branches for this phase before proceeding.