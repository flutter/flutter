# Migration Ledger: Detailed Execution & Validation Tracking

This ledger strictly enforces that **all tests are explicitly run and validated** throughout the atomic migration steps. A phase cannot be marked complete until both the implementation PR has merged and the corresponding test matrix validations are explicitly verified as passing locally and in CI.

## Phase 1: Foundations, Safety Nets, and C-API Prep
- [x] **1.1 Matrix Initialization**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-1.1-matrix-initialization`
    - [x] `TEST_P` Multi-backend test matrix initialized.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: Multi-backend test fixture isolation verified: `EmbedderAllBackendsTest` separated from `EmbedderTestMultiBackend` preventing cross-test fixture pollution on software backends across Linux/Windows/macOS host builds.
    - [x] *Validation*: `embedder_unittests` pass locally on macOS/Linux hosts.
- [x] **1.2 Pre-Emptive GN Quarantine**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-1.2-pre-emptive-gn-quarantine`
    - [x] `flutter_embedder_native` target initialized strictly forbidding Skia/UI headers.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: `ninja -C out/android_debug_unopt flutter_embedder_native` builds successfully.
- [x] **1.3 JNI Routing & Mocking**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-1.3-jni-routing-mocking`
    - [x] `JvmInvoker` abstracted; JNI routing wired to `JniDelegate`.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: Host-side C++ Mocking validates routing flip without crashing.
- [x] **1.4 Dynamic Virtualization**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-1.4-dynamic-virtualization`
    - [x] `OSLibraryLoader` implemented for mocked dynamic Android symbol lookups.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: Host desktop CI pipeline is verified completely green (no macOS `dlopen` segfaults).
- [x] **1.5 C-API Extension (Vulkan)**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-1.5-c-api-extension-vulkan`
    - [x] `embedder.h` API extension: Vulkan External Textures (opaque structs).
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: `embedder_unittests` covering new structs pass.
- [x] **1.6 C-API Extension (AHardwareBuffer)**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-1.6-c-api-extension-ahardwarebuffer`
    - [x] `embedder.h` API extension: AHardwareBuffer (opaque structs).
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: `embedder_unittests` covering new structs pass.
- [x] **1.7 C-API Extension (Engine Spawn)**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-1.7-c-api-extension-engine-spawn`
    - [x] `embedder.h` API extension: `FlutterEngineSpawn`.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: `embedder_unittests` covering EngineSpawn pass.
- [x] **1.8 C-API Extension (Dart Deferred Components)**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-1.8-c-api-extension-dart-deferred-components`
    - [x] `embedder.h` API extension: `FlutterEngineLoadDartDeferredLibrary`.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: `embedder_unittests` covering deferred library loading pass.
- [x] **1.9 C-API Extension (Screenshot API)**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-1.9-c-api-extension-screenshot-api`
    - [x] `embedder.h` API extension: `FlutterEngineScreenshot` and `FlutterEngineFreeScreenshot`.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: `embedder_unittests` covering screenshot structs pass.
- [x] **1.10 C-API Extension (Raster Context Hooks)**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-1.10-c-api-extension-raster-context-hooks`
    - [x] `embedder.h` API extension: `raster_thread_context_make_current` and `clear_current`.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: `embedder_unittests` covering context hooks pass.
- [x] **1.11 C-API Extension (Thread Priorities)**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-1.11-c-api-extension-thread-priorities`
    - [x] `embedder.h` API extension: `custom_task_runners` with Android thread mapping.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: `embedder_unittests` covering task runners pass.


- [x] **Phase 1 Parity Checkpoint**:
    - [x] *Validation*: Framework unit tests (`flutter test`) and `flutter_shell_native_unittests` run globally across the directory, ensuring no cascading failures.
    - [x] *Validation*: Golden tests verified to ensure zero pixel-level regressions on Android canvases. **Strict Golden Rule**: Local engine builds must be tested against the baseline framework. Only the baseline (without local engine build) is permitted to update goldens. If a local engine build fails a golden test, you must fix the C++ native implementation in the local engine—you cannot update the golden image to match the flawed output.
    - [x] *Validation*: Core integration tests (`dev/integration_tests/*`) pass unconditionally.
    - [x] *Review*: Any deviations or failing tests are caught, adversarially root-caused, and pushed back into the specific atomic branches for this phase before proceeding.

## Phase 2: Decoupled Subsystems
*For each subsystem, both Java `android_test` and C++ `flutter_shell_native_unittests` must pass before proceeding.*
- [x] **2.1 Asset Resolver**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-2.1-asset-resolver`
    - [x] `APKAssetProvider` adapted to Embedder Custom Asset Resolver.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: `//shell/platform/android:robolectric_tests` (`FlutterLoaderTest.java`, `ApplicationInfoLoaderTest.java`) AND `//shell/platform/android:flutter_shell_native_unittests` (`apk_asset_provider_unittests.cc`) pass.
- [x] **2.2 Dart Callbacks**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-2.2-dart-callbacks`
    - [x] Dart Callback lookup API integrated.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: `//shell/platform/android:robolectric_tests` (`FlutterJNITest.java`) AND `//shell/platform/android:flutter_shell_native_unittests` (`platform_view_android_delegate_unittests.cc`) pass.
- [x] **2.3 Image Generators**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-2.3-image-generators`
    - [x] `AndroidImageGenerator` hooked to `FlutterEngineRegisterImageDecoder`.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: `//shell/platform/android:robolectric_tests` (`ImageDecoderDefaultImplTest.java`, `ImageDecoderHeifApi36ImplTest.java`) AND `//shell/platform/android:flutter_shell_native_unittests` (`image_lru_unittests.cc`) pass.
- [x] **2.4 Mutator Translation**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-2.4-mutator-translation`
    - [x] `AndroidMutatorsMapper` implemented.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: `//shell/platform/android:robolectric_tests` (`FlutterMutatorViewTest.java`) AND `//shell/platform/android:flutter_shell_native_unittests` (`android_mutator_unittests.cc`) pass.
- [x] **2.5 Accessibility & Semantics**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-2.5-accessibility-semantics`
    - [x] `Accessibility` & `Semantics` natively wired.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: `dev/integration_tests/android_semantics` passes across CI matrix.
- [x] **2.6 Platform Views**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-2.6-platform-views`
    - [x] `PlatformViewsController` integrations wired.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: `dev/integration_tests/android_views` passes (texture & hybrid composition).
- [x] **2.7 Window Metrics Translation**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-2.7-window-metrics-translation`
    - [x] `FlutterEngineSendWindowMetricsEvent` bounds and insets hooked to replace native `android_display`.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: `dev/devicelab/bin/tasks/android_display_cutout.dart` passes.
- [x] **2.8 AChoreographer VSync Routing**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-2.8-achoreographer-vsync-routing`
    - [x] `AChoreographer_postFrameCallback` mapped to `FlutterProjectArgs::vsync_callback` via `OSLibraryLoader`.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: `dev/devicelab/bin/tasks/android_choreographer_do_frame_test.dart` passes, and Perfetto traces confirm strict frame pacing correctness.


- [x] **2.9 Global VM Initialization (`flutter_main.cc`)**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-2.9-global-vm-initialization-flutter-main-cc`
    - [x] Route global ICU, font, and AOT snapshot mapping entirely via `FlutterEngineInitialize`.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: `devicelab` App startup does not stall or lose AOT symbol maps.


- [x] **Phase 2 Parity Checkpoint**:
    - [x] *Validation*: Framework unit tests (`flutter test`) and `flutter_shell_native_unittests` run globally across the directory, ensuring no cascading failures.
    - [x] *Validation*: Golden tests verified to ensure zero pixel-level regressions on Android canvases. **Strict Golden Rule**: Local engine builds must be tested against the baseline framework. Only the baseline (without local engine build) is permitted to update goldens. If a local engine build fails a golden test, you must fix the C++ native implementation in the local engine—you cannot update the golden image to match the flawed output.
    - [x] *Validation*: Core integration tests (`dev/integration_tests/*`) pass unconditionally.
    - [x] *Review*: Any deviations or failing tests are caught, adversarially root-caused, and pushed back into the specific atomic branches for this phase before proceeding.

## Phase 3: Advanced Graphics & Multi-Engine Integration
- [x] **3.1 AHardwareBuffer**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-3.1-ahardwarebuffer`
    - [x] `AHardwareBuffer` wired via Virtualization.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: `//shell/platform/android:flutter_shell_native_unittests` (`hardware_buffer_unittests.cc`, `android_surface_unittests.cc`) pass.
- [x] **3.2 Vulkan External Textures**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-3.2-vulkan-external-textures`
    - [x] `Vulkan External Textures` wired.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: `dev/integration_tests/android_views` AND `dev/devicelab/bin/tasks/plugin_test_android_variants.dart` pass using Impeller Vulkan backend.
- [x] **3.3 SurfaceControl HCPP**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-3.3-surfacecontrol-hcpp`
    - [x] SurfaceControl HCPP dual-mode presentation enabled.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: Native presentation path tests pass in `android_views`.
- [x] **3.4 Multi-Engine & Add-to-App**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-3.4-multi-engine-add-to-app`
    - [x] Add-to-App capabilities wired to `FlutterEngineSpawn` with Java `Cleaner`/`PhantomReference` bindings.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: `dev/devicelab/bin/tasks/build_android_host_app_with_module_source.dart` succeeds.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: `//shell/platform/android:robolectric_tests` (`FlutterEngineGroupTest.java`, `FlutterEngineTest.java`) AND `//shell/platform/android:flutter_shell_native_unittests` (`android_shell_holder_unittests.cc`) pass.


- [x] **Phase 3 Parity Checkpoint**:
    - [x] *Validation*: Framework unit tests (`flutter test`) and `flutter_shell_native_unittests` run globally across the directory, ensuring no cascading failures.
    - [x] *Validation*: Golden tests verified to ensure zero pixel-level regressions on Android canvases. **Strict Golden Rule**: Local engine builds must be tested against the baseline framework. Only the baseline (without local engine build) is permitted to update goldens. If a local engine build fails a golden test, you must fix the C++ native implementation in the local engine—you cannot update the golden image to match the flawed output.
    - [x] *Validation*: Core integration tests (`dev/integration_tests/*`) pass unconditionally.
    - [x] *Review*: Any deviations or failing tests are caught, adversarially root-caused, and pushed back into the specific atomic branches for this phase before proceeding.

## Phase 4: Extreme E2E Parity Validation
*Before ANY legacy code is deleted in Phase 5, the entire engine, framework, and DeviceLab matrices must be run unconditionally against the new Embedder API logic.*
- [x] **4.1 Engine Unit Tests**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-4.1-engine-unit-tests`
    - [x] `embedder_unittests` (Host macOS/Linux) - Passed.
    - [x] `flutter_shell_native_unittests` (Android Emulator) - Passed.
- [x] **4.2 Framework Integration Tests (Skia GL / Software)**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-4.2-framework-integration-tests-skia-gl-software`
    - [x] `dev/integration_tests/android_views` - Passed.
    - [x] `dev/integration_tests/channels` - Passed.
    - [x] `dev/integration_tests/platform_interaction` - Passed.
    - [x] `dev/integration_tests/android_engine_test` - Passed.
- [x] **4.3 Framework Integration Tests (Impeller)**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-4.3-framework-integration-tests-impeller`
    - [x] `dev/integration_tests/android_views` (Backend: Impeller OpenGLES) - Passed.
    - [x] `dev/integration_tests/android_views` (Backend: Impeller Vulkan) - Passed.
- [x] **4.4 DeviceLab Android Lifecycle & Platform Views**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-4.4-devicelab-android-lifecycle-platform-views`
    - [x] `dev/devicelab/bin/tasks/android_lifecycles_test.dart` - Passed.
    - [x] `dev/devicelab/bin/tasks/android_verified_input_test.dart` - Passed.
    - [x] `dev/devicelab/bin/tasks/android_semantics_integration_test.dart` - Passed.
    - [x] `dev/devicelab/bin/tasks/hybrid_android_views_integration_test.dart` - Passed.
    - [x] `dev/devicelab/bin/tasks/android_engine_flags_debug_test.dart` - Passed.
    - [x] `dev/devicelab/bin/tasks/android_engine_flags_release_test.dart` - Passed.
- [x] **4.5 DeviceLab Performance & Memory Parity (No Regressions)**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-4.5-devicelab-performance-memory-parity-no-regressions`
    - [x] `dev/devicelab/bin/tasks/complex_layout_android__scroll_smoothness.dart` - Passed.
    - [x] `dev/devicelab/bin/tasks/android_view_scroll_perf__timeline_summary.dart` - Passed.
    - [x] `dev/devicelab/bin/tasks/flutter_engine_group_performance.dart` - Passed.

## Phase 5: Emancipation
- [x] **5.1 Target Flip**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-5.1-target-flip`
    - [x] Embedder flags defaulted to `true`.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: CI remains unconditionally green on default runs.
- [x] **5.2 Legacy Deletion (Subsystems)**:
    - [x] *Branch Stub*: `android-embedder-migration-v7/phase-5.2-legacy-deletion-subsystems`
    - [x] Assets, Images, Callbacks, Mutators wiped.
    - [x] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [x] *Validation*: `ninja -C out/android_debug_unopt flutter_shell_native_unittests` compiles successfully AND `//shell/platform/android:robolectric_tests` passes entirely without legacy code.
- [ ] **5.3 Legacy Deletion (Platform Views/Semantics)**:
    - [ ] *Branch Stub*: `android-embedder-migration-v7/phase-5.3-legacy-deletion-platform-views-semantics`
    - [ ] Platform views and semantics wiped.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [ ] *Validation*: `ninja -C out/android_debug_unopt flutter_shell_native_unittests` compiles successfully AND `//shell/platform/android:robolectric_tests` passes entirely without legacy code.
- [ ] **5.4 Legacy Deletion (Graphics Pipeline)**:
    - [ ] *Branch Stub*: `android-embedder-migration-v7/phase-5.4-legacy-deletion-graphics-pipeline`
    - [ ] `android_context`, `android_surface` wiped.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [ ] *Validation*: `ninja -C out/android_debug_unopt flutter_shell_native_unittests` compiles successfully AND `//shell/platform/android:robolectric_tests` passes entirely without legacy code.
- [ ] **5.5 Flag Obliteration**:
    - [ ] *Branch Stub*: `android-embedder-migration-v7/phase-5.5-flag-obliteration`
    - [ ] Flags pruned and routing hardcoded unconditionally.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [ ] *Validation*: CLI flags `--enable-embedder-api` are rejected by build scripts appropriately.
- [ ] **5.6 Strict GN Target Isolation**:
    - [ ] *Branch Stub*: `android-embedder-migration-v7/phase-5.6-strict-gn-target-isolation`
    - [ ] `flutter_shell_native` internal Skia/UI dependencies purged; targets merged.
    - [ ] *Review*: Autonomous Adversarial Review Loop executed natively on PR (including Perfetto trace instrumentation verification) and feedback addressed.
    - [ ] *Validation*: Clean `gn` re-run; `ninja` builds successfully assuring absolute GN C-ABI quarantine.

- [ ] **Phase 5 Parity Checkpoint**:
    - [ ] *Validation*: Framework unit tests (`flutter test`) and `flutter_shell_native_unittests` run globally across the directory, ensuring no cascading failures.
    - [ ] *Validation*: Golden tests verified to ensure zero pixel-level regressions on Android canvases. **Strict Golden Rule**: Local engine builds must be tested against the baseline framework. Only the baseline (without local engine build) is permitted to update goldens. If a local engine build fails a golden test, you must fix the C++ native implementation in the local engine—you cannot update the golden image to match the flawed output.
    - [ ] *Validation*: Core integration tests (`dev/integration_tests/*`) pass unconditionally.
    - [ ] *Review*: Any deviations or failing tests are caught, adversarially root-caused, and pushed back into the specific atomic branches for this phase before proceeding.
