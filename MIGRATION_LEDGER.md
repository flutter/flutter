# Migration Ledger

## Phase 1: Baseline Parity and C-API Extensions
- [ ] 1.1 `TEST_P` Multi-backend test matrix initialized.
- [ ] 1.2 `embedder.h` API abstractions prepared for AHardwareBuffer, Vulkan instances, and Engine Spawning.
- [ ] 1.3 Granular rollout flags (`--enable-embedder-api-*`) added to `Settings` and Java.

## Phase 2: Decoupled Subsystems
- [ ] 2.1 `APKAssetProvider` adapted to Embedder Custom Asset Resolver.
- [ ] 2.2 Dart Callback lookup API integrated.
- [ ] 2.3 `AndroidImageGenerator` hooked to `FlutterEngineRegisterImageDecoder`.
- [ ] 2.4 `AndroidMutatorsMapper` implemented.

## Phase 3: Advanced Graphics & Multi-Engine Integration
- [ ] 3.1 `AHardwareBuffer` and Vulkan External Textures wired.
- [ ] 3.2 SurfaceControl HCPP dual-mode presentation enabled.
- [ ] 3.3 Add-to-App capabilities wired to `FlutterEngineSpawn`.

## Phase 4: AndroidEngine Orchestrator & Validation
- [ ] 4.1 `OSLibraryLoader` implemented for mocked dynamic choreographer lookups (`dlopen`).
- [ ] 4.2 JNI inline routing implemented.
- [ ] 4.3 E2E emulator tests pass on both flag combinations (Proof of 100% parity for Vulkan and Multi-engine).

## Phase 5: Emancipation
- [ ] 5.1 Embedder flags defaulted to `true`.
- [ ] 5.2 **Legacy Code Deletion**: Legacy bridge wiped. 
- [ ] 5.3 **Strict GN Target Isolation**: `flutter_shell_native` strictly isolated in `BUILD.gn`.
