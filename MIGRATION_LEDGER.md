# Migration Ledger

## Phase 1: Foundations, Safety Nets, and C-API Prep
- [ ] 1.1 `TEST_P` Multi-backend test matrix initialized.
- [ ] 1.2 Pre-Emptive GN Quarantine: strict `flutter_embedder_native` target initialized.
- [ ] 1.3 `JvmInvoker` abstracted; JNI routing wired to `JniDelegate`.
- [ ] 1.4 `OSLibraryLoader` implemented for mocked dynamic Android symbol lookups.
- [ ] 1.5 `embedder.h` API extension: Vulkan External Textures.
- [ ] 1.6 `embedder.h` API extension: AHardwareBuffer (opaque structs).
- [ ] 1.7 `embedder.h` API extension: `FlutterEngineSpawn`.

## Phase 2: Decoupled Subsystems
- [ ] 2.1 `APKAssetProvider` adapted to Embedder Custom Asset Resolver.
- [ ] 2.2 Dart Callback lookup API integrated.
- [ ] 2.3 `AndroidImageGenerator` hooked to `FlutterEngineRegisterImageDecoder`.
- [ ] 2.4 `AndroidMutatorsMapper` implemented.
- [ ] 2.5 `Accessibility` & `Semantics` natively wired.
- [ ] 2.6 `PlatformViewsController` integrations wired.

## Phase 3: Advanced Graphics & Multi-Engine Integration
- [ ] 3.1 `AHardwareBuffer` wired via Virtualization.
- [ ] 3.2 `Vulkan External Textures` wired.
- [ ] 3.3 SurfaceControl HCPP dual-mode presentation enabled.
- [ ] 3.4 Add-to-App capabilities wired to `FlutterEngineSpawn` with Java `Cleaner`/`PhantomReference` bindings.

## Phase 4: E2E Parity Validation
- [ ] 4.1 E2E emulator tests pass on both flag combinations (Proof of 100% parity).

## Phase 5: Emancipation
- [ ] 5.1 Embedder flags defaulted to `true`.
- [ ] 5.2 **Legacy Code Deletion**: Subsystems (Assets, Images, Callbacks, Mutators) wiped.
- [ ] 5.3 **Legacy Code Deletion**: platform views and semantics wiped.
- [ ] 5.4 **Legacy Code Deletion**: Graphics Pipeline (`android_context`, `android_surface`) wiped.
- [ ] 5.5 **Flag Obliteration**: Flags pruned and routing hardcoded unconditionally.
- [ ] 5.6 **Strict GN Target Isolation**: `flutter_shell_native` internal Skia/UI dependencies purged; targets merged.
