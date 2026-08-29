# Migration Ledger

Track the completion of the migration phases here. Mark with `[x]` when the Pull Request is merged into the master branch and all integration tests have passed on both primary and fallback flag configurations.

## Phase 1: Baseline Parity and C-ABI Struct Definitions
- [ ] 1.1 `TEST_P` Multi-backend test matrix initialized.
- [ ] 1.2 `AndroidPointerData`, `AndroidISize` structs implemented.
- [ ] 1.3 Granular rollout flags (`--enable-embedder-api-*`) added to `Settings` and Java.

## Phase 2: Decoupled Subsystems
- [ ] 2.1 `APKAssetProvider` adapted to Embedder Custom Asset Resolver.
- [ ] 2.2 Dart Callback lookup API integrated.
- [ ] 2.3 `AndroidImageGenerator` hooked to `FlutterEngineRegisterImageDecoder`.
- [ ] 2.4 `AndroidMutatorsMapper` implemented for DPR-aware mutation conversion.

## Phase 3: AndroidEngine Orchestrator
- [ ] 3.1 `dlopen(libandroid.so)` dynamic choreographer bindings implemented.
- [ ] 3.2 `PlatformViewAndroidJniDelegate` (JNI DI Mock boundary) established.
- [ ] 3.3 `AndroidEngine` orchestrator implemented leveraging public C-API.

## Phase 4: JNI Inline Routing & Validation
- [ ] 4.1 JNI routing in `platform_view_android_jni_impl.cc` implemented.
- [ ] 4.2 Local unittests pass.
- [ ] 4.3 E2E integration tests (Golden/Screenshot, Message Passing) pass with flags `true` and `false`.

## Phase 5: Emancipation
- [ ] 5.1 Embedder flags defaulted to `true`.
- [ ] 5.2 **Legacy Code Deletion**: `android_context`, `external_view_embedder`, `platform_view_android_delegate`, `android_surface` deleted.
- [ ] 5.3 **Strict GN Target Isolation**: `BUILD.gn` pruned. `flutter_shell_native` isolated to `embedder_as_internal_library`, `fml`, `common`, `third_party`, `icu`, and NDK libraries.

## Phase 6: Advanced Modernization
- [ ] 6.1 `AHardwareBuffer` and Vulkan External Textures integrated explicitly.
- [ ] 6.2 SurfaceControl HCPP dual-mode presentation enabled.
- [ ] 6.3 `FlutterEngineSpawn` exposed.
