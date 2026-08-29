# Migration Ledger

## Phase 1: Foundations, Safety Nets, and C-API Prep
- [ ] 1.1 `TEST_P` Multi-backend test matrix initialized.
- [ ] 1.2 Pre-Emptive GN Quarantine: strict `flutter_embedder_native` target initialized.
- [ ] 1.3 JNI inline routing logic wired; true branch mapped to `JniDelegate`.
- [ ] 1.4 `OSLibraryLoader` implemented for mocked dynamic Android symbol lookups.
- [ ] 1.5 `embedder.h` API abstractions prepared.

## Phase 2: Decoupled Subsystems
- [ ] 2.1 `APKAssetProvider` adapted to Embedder Custom Asset Resolver.
- [ ] 2.2 Dart Callback lookup API integrated.
- [ ] 2.3 `AndroidImageGenerator` hooked to `FlutterEngineRegisterImageDecoder`.
- [ ] 2.4 `AndroidMutatorsMapper` implemented.

## Phase 3: Advanced Graphics & Multi-Engine Integration
- [ ] 3.1 `AHardwareBuffer` and Vulkan External Textures wired (via Virtualization).
- [ ] 3.2 SurfaceControl HCPP dual-mode presentation enabled.
- [ ] 3.3 Add-to-App capabilities wired to `FlutterEngineSpawn` capturing Java lifecycles.

## Phase 4: E2E Parity Validation
- [ ] 4.1 E2E emulator tests pass on both flag combinations (Proof of 100% parity).

## Phase 5: Emancipation
- [ ] 5.1 Embedder flags defaulted to `true`.
- [ ] 5.2 **Legacy Code Deletion**: Legacy bridge wiped, flags pruned, and JNI `else` conditions annihilated.
- [ ] 5.3 **Strict GN Target Isolation**: `flutter_shell_native` lock down finalized.
