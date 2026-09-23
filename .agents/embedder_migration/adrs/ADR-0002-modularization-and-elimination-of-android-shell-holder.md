# ADR-0002: Modularization and Elimination of `AndroidShellHolder` and `PlatformViewAndroid`

## Status
ACCEPTED

## RFC 410 Cross-Reference
Section: *Target Architecture and Design Principles* -> *Decomposition and Elimination of AndroidShellHolder and PlatformViewAndroid*

## Context & Problem Statement
In the legacy production architecture, the Android embedder C++ layer is concentrated in three tightly coupled classes:
1. `AndroidShellHolder`: Creates `fml::ThreadHost`, directly calls `flutter::Shell::Create(...)`, and owns `PlatformViewAndroid`.
2. `PlatformViewAndroid`: Subclasses internal `flutter::PlatformView`, conflating window surfaces, external textures, semantics, and platform views.
3. `PlatformViewAndroidJNIImpl`: Casts `jlong` handles to raw `AndroidShellHolder*` pointers and directly dispatches across JNI.

This design treats Android as an internal engine subsystem rather than an external client, forcing 98 internal header inclusions.

## Non-Negotiable Invariants
1. **Zero Subclassing of Engine Internals**: The Android embedder must never subclass `flutter::PlatformView`, `flutter::VsyncWaiter`, `flutter::ExternalViewEmbedder`, or `flutter::Texture`.
2. **Single-Responsibility Decomposition**: The monolithic classes must be decomposed into focused, decoupled components in `:flutter_embedder_native_src`.
3. **Phased Removal (Four Stages)**:
   - Stage 1: Legacy monolithic production.
   - Stage 2: Target partitioning and construction of modular components behind the `AndroidEngine` seam.
   - Stage 3: `FlutterEmbedderNative` registers JNI bindings directly.
   - Stage 4: Permanent deletion (`git rm android_shell_holder.* platform_view_android.* external_view_embedder/`).
4. **Behavioral Parity**: Each decomposed component must reach functional and performance parity verified by tests before legacy deletion.

## Chosen Solution
- Decompose responsibilities into focused target components:
  - `FlutterEmbedderNative`: Top-level JNI coordinator and opaque `FlutterEngine` owner.
  - `JniRouter` / `JniDelegate` / `JvmInvoker`: Outbound JNI abstraction.
  - `AndroidSurfaceControl`: Native window surfaces and `ASurfaceControl` layer trees.
  - `AndroidPlatformViewsController` & `AndroidMutatorsMapper`: Platform view composition.
  - `AndroidHardwareBuffer` & `AndroidVulkanExternalTexture`: External textures.
  - `AndroidSemanticsMapper` & `AndroidWindowMetricsMapper`: Accessibility and metrics.
  - `AndroidVsyncWaiter`: Choreographer frame pacing.
  - `AndroidVMInit` & `AndroidEngineGroup`: VM arguments and multi-engine spawning.
  - `APKAssetProvider`: APK asset resolution.
- During Phases 2–3, introduce a transitional polymorphic delegate interface (`AndroidEngine`, implemented by `ShellAndroidEngine` and `EmbedderAndroidEngine`) to allow piecemeal subsystem verification.
- In Phase 4, permanently purge all legacy classes and reduce `:flutter_shell_native_src` to three files: `flutter_main.cc`, `flutter_main.h`, and `library_loader.cc`.

## Rejected Alternatives & Rationale
- *Parallel Build Target Rewrite*: Rejected because isolated secondary build targets drift from `main`, are not exercised by CI presubmits, and incentivize omitting platform features.
- *Monolithic Big-Bang Cutover without Seam*: Rejected because a single massive replacement of `AndroidShellHolder` and `PlatformViewAndroid` without a phased fallback increases regression risk, prevents side-by-side CI verification, and impedes defect triage.
- *Status Quo (Tightly Coupled Direct Shell Interaction)*: Rejected because it permanently blocks engine modularization and prevents establishing an ABI boundary.

## Verification Contract
- `flutter_embedder_native_unittests` validates all modular components individually.
- In Phase 4, `git diff` confirms zero remaining occurrences of `AndroidShellHolder` and `PlatformViewAndroid`.
- Full Android embedding integration tests pass cleanly under `FlutterEmbedderNative`.
