# Flutter Android Embedder C-API Migration: Branch Index & Changelog

This document provides the complete index of all 38 atomic migration branches pushed to `origin` (`git@github.com:mboetger/flutter.git`). For each branch, the exact name, GitHub compare URL against its predecessor (using base commit SHA `645f3658aa7` for the first branch to avoid drift), and detailed summary of changes are provided.

---

## 1. Phase 1.1: Matrix Initialization

- **Branch Name**: `android-embedder-migration-v7/phase-1.1-matrix-initialization`
- **Compare URL**: [645f3658aa7 ... android-embedder-migration-v7/phase-1.1-matrix-initialization](https://github.com/mboetger/flutter/compare/645f3658aa77f11bbc722722cb025442f9ff8c48...android-embedder-migration-v7/phase-1.1-matrix-initialization)
- **Changes Summary**: Initialized the TEST_P multi-backend parameterized test matrix covering Skia GL, Impeller OpenGLES, Impeller Vulkan, and Software rendering modes across embedder unittests.
- **Diff Stat**: `6 files changed, 342 insertions(+), 8 deletions(-)`
- **Files Modified/Created** (6):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/embedder/tests/embedder_test.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/tests/embedder_test.cc)
  - [`engine/src/flutter/shell/platform/embedder/tests/embedder_test.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/tests/embedder_test.h)
  - [`engine/src/flutter/shell/platform/embedder/tests/embedder_test_context.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/tests/embedder_test_context.cc)
  - [`engine/src/flutter/shell/platform/embedder/tests/embedder_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/tests/embedder_unittests.cc)
  - [`engine/src/flutter/shell/platform/embedder/tests/embedder_unittests_util.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/tests/embedder_unittests_util.h)

---

## 2. Phase 1.2: Pre-Emptive GN Quarantine

- **Branch Name**: `android-embedder-migration-v7/phase-1.2-pre-emptive-gn-quarantine`
- **Compare URL**: [android-embedder-migration-v7/phase-1.1-matrix-initialization ... android-embedder-migration-v7/phase-1.2-pre-emptive-gn-quarantine](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-1.1-matrix-initialization...android-embedder-migration-v7/phase-1.2-pre-emptive-gn-quarantine)
- **Changes Summary**: Created the isolated :flutter_embedder_native GN target in BUILD.gn strictly forbidding internal Skia (//flutter/skia), Flow (//flutter/flow), or UI runtime (//flutter/lib/ui) headers to enforce C-ABI quarantine from Day 1.
- **Diff Stat**: `6 files changed, 177 insertions(+), 5 deletions(-)`
- **Files Modified/Created** (6):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/BUILD.gn`](file:///Users/boetger/src/flutter/engine/src/flutter/BUILD.gn)
  - [`engine/src/flutter/shell/platform/android/BUILD.gn`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/BUILD.gn)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.h)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc)

---

## 3. Phase 1.3: JNI Routing & Mocking

- **Branch Name**: `android-embedder-migration-v7/phase-1.3-jni-routing-mocking`
- **Compare URL**: [android-embedder-migration-v7/phase-1.2-pre-emptive-gn-quarantine ... android-embedder-migration-v7/phase-1.3-jni-routing-mocking](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-1.2-pre-emptive-gn-quarantine...android-embedder-migration-v7/phase-1.3-jni-routing-mocking)
- **Changes Summary**: Implemented abstracted JvmInvoker interface and JniDelegate adapter. Wired raw JNI entry points to support dual-dispatch routing with host-side mockability.
- **Diff Stat**: `11 files changed, 1204 insertions(+), 8 deletions(-)`
- **Files Modified/Created** (11):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/android/BUILD.gn`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/BUILD.gn)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.h)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.h)
  - [`engine/src/flutter/shell/platform/android/jni_router.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.cc)
  - [`engine/src/flutter/shell/platform/android/jni_router.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.h)
  - [`engine/src/flutter/shell/platform/android/jvm_invoker.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jvm_invoker.cc)
  - [`engine/src/flutter/shell/platform/android/jvm_invoker.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jvm_invoker.h)

---

## 4. Phase 1.4: Dynamic Virtualization

- **Branch Name**: `android-embedder-migration-v7/phase-1.4-dynamic-virtualization`
- **Compare URL**: [android-embedder-migration-v7/phase-1.3-jni-routing-mocking ... android-embedder-migration-v7/phase-1.4-dynamic-virtualization](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-1.3-jni-routing-mocking...android-embedder-migration-v7/phase-1.4-dynamic-virtualization)
- **Changes Summary**: Implemented OSLibraryLoader interface wrapping dlopen/dlsym with DefaultOSLibraryLoader and InMemoryOSLibraryLoader to shield desktop CI environments from Android platform crashes.
- **Diff Stat**: `8 files changed, 992 insertions(+), 213 deletions(-)`
- **Files Modified/Created** (8):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/BUILD.gn`](file:///Users/boetger/src/flutter/engine/src/flutter/BUILD.gn)
  - [`engine/src/flutter/shell/platform/android/BUILD.gn`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/BUILD.gn)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.h)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/os_library_loader.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/os_library_loader.cc)
  - [`engine/src/flutter/shell/platform/android/os_library_loader.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/os_library_loader.h)

---

## 5. Phase 1.5: C-API Extension (Vulkan External Textures)

- **Branch Name**: `android-embedder-migration-v7/phase-1.5-c-api-extension-vulkan`
- **Compare URL**: [android-embedder-migration-v7/phase-1.4-dynamic-virtualization ... android-embedder-migration-v7/phase-1.5-c-api-extension-vulkan](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-1.4-dynamic-virtualization...android-embedder-migration-v7/phase-1.5-c-api-extension-vulkan)
- **Changes Summary**: Expanded embedder.h with cross-platform opaque struct abstractions (FlutterVulkanExternalTexture, FlutterVulkanYcbcrConversionInfo, FlutterVulkanExternalTextureFrameCallback) for hardware Vulkan texture sampling.
- **Diff Stat**: `10 files changed, 791 insertions(+), 5 deletions(-)`
- **Files Modified/Created** (10):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/embedder/BUILD.gn`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/BUILD.gn)
  - [`engine/src/flutter/shell/platform/embedder/embedder.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder.cc)
  - [`engine/src/flutter/shell/platform/embedder/embedder.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder.h)
  - [`engine/src/flutter/shell/platform/embedder/embedder_external_texture_resolver.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder_external_texture_resolver.cc)
  - [`engine/src/flutter/shell/platform/embedder/embedder_external_texture_resolver.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder_external_texture_resolver.h)
  - [`engine/src/flutter/shell/platform/embedder/embedder_external_texture_vk.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder_external_texture_vk.cc)
  - [`engine/src/flutter/shell/platform/embedder/embedder_external_texture_vk.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder_external_texture_vk.h)
  - [`engine/src/flutter/shell/platform/embedder/tests/embedder_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/tests/embedder_unittests.cc)
  - [`engine/src/flutter/shell/platform/embedder/tests/embedder_vk_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/tests/embedder_vk_unittests.cc)

---

## 6. Phase 1.6: C-API Extension (AHardwareBuffer)

- **Branch Name**: `android-embedder-migration-v7/phase-1.6-c-api-extension-ahardwarebuffer`
- **Compare URL**: [android-embedder-migration-v7/phase-1.5-c-api-extension-vulkan ... android-embedder-migration-v7/phase-1.6-c-api-extension-ahardwarebuffer](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-1.5-c-api-extension-vulkan...android-embedder-migration-v7/phase-1.6-c-api-extension-ahardwarebuffer)
- **Changes Summary**: Expanded embedder.h with cross-platform opaque struct abstractions (FlutterHardwareBufferExternalTexture, FlutterHardwareBufferExternalTextureFrameCallback) for zero-copy Android AHardwareBuffer rendering.
- **Diff Stat**: `11 files changed, 570 insertions(+), 6 deletions(-)`
- **Files Modified/Created** (11):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/embedder/BUILD.gn`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/BUILD.gn)
  - [`engine/src/flutter/shell/platform/embedder/embedder.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder.cc)
  - [`engine/src/flutter/shell/platform/embedder/embedder.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder.h)
  - [`engine/src/flutter/shell/platform/embedder/embedder_external_texture_hb.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder_external_texture_hb.cc)
  - [`engine/src/flutter/shell/platform/embedder/embedder_external_texture_hb.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder_external_texture_hb.h)
  - [`engine/src/flutter/shell/platform/embedder/embedder_external_texture_resolver.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder_external_texture_resolver.cc)
  - [`engine/src/flutter/shell/platform/embedder/embedder_external_texture_resolver.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder_external_texture_resolver.h)
  - [`engine/src/flutter/shell/platform/embedder/tests/embedder_gl_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/tests/embedder_gl_unittests.cc)
  - [`engine/src/flutter/shell/platform/embedder/tests/embedder_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/tests/embedder_unittests.cc)
  - [`engine/src/flutter/shell/platform/embedder/tests/embedder_vk_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/tests/embedder_vk_unittests.cc)

---

## 7. Phase 1.7: C-API Extension (Engine Spawn)

- **Branch Name**: `android-embedder-migration-v7/phase-1.7-c-api-extension-engine-spawn`
- **Compare URL**: [android-embedder-migration-v7/phase-1.6-c-api-extension-ahardwarebuffer ... android-embedder-migration-v7/phase-1.7-c-api-extension-engine-spawn](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-1.6-c-api-extension-ahardwarebuffer...android-embedder-migration-v7/phase-1.7-c-api-extension-engine-spawn)
- **Changes Summary**: Expanded embedder.h with FlutterEngineSpawn and FlutterEngineSpawnConfig for lightweight Add-to-App multi-engine spawning sharing isolates, thread pools, and GPU contexts.
- **Diff Stat**: `7 files changed, 920 insertions(+), 271 deletions(-)`
- **Files Modified/Created** (7):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/embedder/embedder.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder.cc)
  - [`engine/src/flutter/shell/platform/embedder/embedder.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder.h)
  - [`engine/src/flutter/shell/platform/embedder/embedder_engine.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder_engine.cc)
  - [`engine/src/flutter/shell/platform/embedder/embedder_engine.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder_engine.h)
  - [`engine/src/flutter/shell/platform/embedder/tests/embedder_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/tests/embedder_unittests.cc)
  - [`engine/src/flutter/shell/platform/linux/testing/mock_engine.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/linux/testing/mock_engine.cc)

---

## 8. Phase 1.8: C-API Extension (Dart Deferred Components)

- **Branch Name**: `android-embedder-migration-v7/phase-1.8-c-api-extension-dart-deferred-components`
- **Compare URL**: [android-embedder-migration-v7/phase-1.7-c-api-extension-engine-spawn ... android-embedder-migration-v7/phase-1.8-c-api-extension-dart-deferred-components](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-1.7-c-api-extension-engine-spawn...android-embedder-migration-v7/phase-1.8-c-api-extension-dart-deferred-components)
- **Changes Summary**: Expanded embedder.h with FlutterEngineLoadDartDeferredLibrary and FlutterEngineDeferredLoadingCallback mapping Play Feature Delivery components safely across the C-API boundary.
- **Diff Stat**: `11 files changed, 497 insertions(+), 7 deletions(-)`
- **Files Modified/Created** (11):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/common/platform_view.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/common/platform_view.cc)
  - [`engine/src/flutter/shell/platform/embedder/embedder.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder.cc)
  - [`engine/src/flutter/shell/platform/embedder/embedder.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder.h)
  - [`engine/src/flutter/shell/platform/embedder/embedder_engine.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder_engine.cc)
  - [`engine/src/flutter/shell/platform/embedder/embedder_engine.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder_engine.h)
  - [`engine/src/flutter/shell/platform/embedder/platform_view_embedder.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/platform_view_embedder.cc)
  - [`engine/src/flutter/shell/platform/embedder/platform_view_embedder.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/platform_view_embedder.h)
  - [`engine/src/flutter/shell/platform/embedder/tests/embedder_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/tests/embedder_unittests.cc)
  - [`engine/src/flutter/shell/platform/embedder/tests/embedder_unittests_proctable.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/tests/embedder_unittests_proctable.cc)
  - [`engine/src/flutter/shell/platform/linux/testing/mock_engine.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/linux/testing/mock_engine.cc)

---

## 9. Phase 1.9: C-API Extension (Screenshot API)

- **Branch Name**: `android-embedder-migration-v7/phase-1.9-c-api-extension-screenshot-api`
- **Compare URL**: [android-embedder-migration-v7/phase-1.8-c-api-extension-dart-deferred-components ... android-embedder-migration-v7/phase-1.9-c-api-extension-screenshot-api](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-1.8-c-api-extension-dart-deferred-components...android-embedder-migration-v7/phase-1.9-c-api-extension-screenshot-api)
- **Changes Summary**: Expanded embedder.h with FlutterEngineScreenshot and FlutterEngineFreeScreenshot allowing synchronous raster bitmap captures across the C-API boundary.
- **Diff Stat**: `8 files changed, 340 insertions(+), 5 deletions(-)`
- **Files Modified/Created** (8):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/embedder/embedder.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder.cc)
  - [`engine/src/flutter/shell/platform/embedder/embedder.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder.h)
  - [`engine/src/flutter/shell/platform/embedder/embedder_engine.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder_engine.cc)
  - [`engine/src/flutter/shell/platform/embedder/embedder_engine.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder_engine.h)
  - [`engine/src/flutter/shell/platform/embedder/tests/embedder_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/tests/embedder_unittests.cc)
  - [`engine/src/flutter/shell/platform/embedder/tests/embedder_unittests_proctable.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/tests/embedder_unittests_proctable.cc)
  - [`engine/src/flutter/shell/platform/linux/testing/mock_engine.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/linux/testing/mock_engine.cc)

---

## 10. Phase 1.10: C-API Extension (Raster Context Hooks)

- **Branch Name**: `android-embedder-migration-v7/phase-1.10-c-api-extension-raster-context-hooks`
- **Compare URL**: [android-embedder-migration-v7/phase-1.9-c-api-extension-screenshot-api ... android-embedder-migration-v7/phase-1.10-c-api-extension-raster-context-hooks](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-1.9-c-api-extension-screenshot-api...android-embedder-migration-v7/phase-1.10-c-api-extension-raster-context-hooks)
- **Changes Summary**: Expanded FlutterProjectArgs in embedder.h with raster_thread_context_make_current and clear_current context lifecycle callbacks for Android thread/EGL management.
- **Diff Stat**: `7 files changed, 437 insertions(+), 23 deletions(-)`
- **Files Modified/Created** (7):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/common/rasterizer.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/common/rasterizer.h)
  - [`engine/src/flutter/shell/common/shell.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/common/shell.cc)
  - [`engine/src/flutter/shell/platform/embedder/embedder.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder.cc)
  - [`engine/src/flutter/shell/platform/embedder/embedder.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder.h)
  - [`engine/src/flutter/shell/platform/embedder/platform_view_embedder.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/platform_view_embedder.h)
  - [`engine/src/flutter/shell/platform/embedder/tests/embedder_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/tests/embedder_unittests.cc)

---

## 11. Phase 1.11: C-API Extension (Thread Priorities)

- **Branch Name**: `android-embedder-migration-v7/phase-1.11-c-api-extension-thread-priorities`
- **Compare URL**: [android-embedder-migration-v7/phase-1.10-c-api-extension-raster-context-hooks ... android-embedder-migration-v7/phase-1.11-c-api-extension-thread-priorities](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-1.10-c-api-extension-raster-context-hooks...android-embedder-migration-v7/phase-1.11-c-api-extension-thread-priorities)
- **Changes Summary**: Expanded FlutterProjectArgs with custom_task_runners mapping Android ALooper and strict thread priorities (such as PRIORITY_DISPLAY) onto the engine task scheduler.
- **Diff Stat**: `11 files changed, 463 insertions(+), 23 deletions(-)`
- **Files Modified/Created** (11):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/embedder/embedder.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder.cc)
  - [`engine/src/flutter/shell/platform/embedder/embedder.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder.h)
  - [`engine/src/flutter/shell/platform/embedder/embedder_engine.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder_engine.cc)
  - [`engine/src/flutter/shell/platform/embedder/embedder_task_runner.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder_task_runner.cc)
  - [`engine/src/flutter/shell/platform/embedder/embedder_task_runner.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder_task_runner.h)
  - [`engine/src/flutter/shell/platform/embedder/embedder_thread_host.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder_thread_host.cc)
  - [`engine/src/flutter/shell/platform/embedder/tests/embedder_config_builder.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/tests/embedder_config_builder.cc)
  - [`engine/src/flutter/shell/platform/embedder/tests/embedder_config_builder.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/tests/embedder_config_builder.h)
  - [`engine/src/flutter/shell/platform/embedder/tests/embedder_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/tests/embedder_unittests.cc)
  - [`engine/src/flutter/shell/platform/embedder/tests/embedder_unittests_util.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/tests/embedder_unittests_util.h)

---

## 12. Phase 2.1: Asset Resolver

- **Branch Name**: `android-embedder-migration-v7/phase-2.1-asset-resolver`
- **Compare URL**: [android-embedder-migration-v7/phase-1.11-c-api-extension-thread-priorities ... android-embedder-migration-v7/phase-2.1-asset-resolver](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-1.11-c-api-extension-thread-priorities...android-embedder-migration-v7/phase-2.1-asset-resolver)
- **Changes Summary**: Adapted APKAssetProvider to implement FlutterEngineRegisterAssetResolver and custom asset provider callbacks, decoupling assets from legacy asset managers.
- **Diff Stat**: `12 files changed, 713 insertions(+), 51 deletions(-)`
- **Files Modified/Created** (12):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/android/BUILD.gn`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/BUILD.gn)
  - [`engine/src/flutter/shell/platform/android/apk_asset_provider.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/apk_asset_provider.cc)
  - [`engine/src/flutter/shell/platform/android/apk_asset_provider.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/apk_asset_provider.h)
  - [`engine/src/flutter/shell/platform/android/apk_asset_provider_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/apk_asset_provider_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.h)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.h)
  - [`engine/src/flutter/shell/platform/android/jni_router.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.cc)
  - [`engine/src/flutter/shell/platform/android/jni_router.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.h)

---

## 13. Phase 2.2: Dart Callbacks

- **Branch Name**: `android-embedder-migration-v7/phase-2.2-dart-callbacks`
- **Compare URL**: [android-embedder-migration-v7/phase-2.1-asset-resolver ... android-embedder-migration-v7/phase-2.2-dart-callbacks](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-2.1-asset-resolver...android-embedder-migration-v7/phase-2.2-dart-callbacks)
- **Changes Summary**: Hooked Dart entrypoint and callback lookup cache directly to FlutterEngineGetCallbackInformation, eliminating legacy singletons.
- **Diff Stat**: `15 files changed, 1390 insertions(+), 719 deletions(-)`
- **Files Modified/Created** (15):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/android/BUILD.gn`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/BUILD.gn)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.h)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.h)
  - [`engine/src/flutter/shell/platform/android/jni_router.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.cc)
  - [`engine/src/flutter/shell/platform/android/jni_router.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.h)
  - [`engine/src/flutter/shell/platform/embedder/embedder.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder.cc)
  - [`engine/src/flutter/shell/platform/embedder/embedder.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder.h)
  - [`engine/src/flutter/shell/platform/embedder/embedder_external_texture_hb.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder_external_texture_hb.h)
  - [`engine/src/flutter/shell/platform/embedder/embedder_external_texture_resolver.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder_external_texture_resolver.cc)
  - [`engine/src/flutter/shell/platform/embedder/tests/embedder_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/tests/embedder_unittests.cc)
  - [`engine/src/flutter/shell/platform/embedder/tests/embedder_unittests_proctable.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/tests/embedder_unittests_proctable.cc)

---

## 14. Phase 2.3: Image Generators

- **Branch Name**: `android-embedder-migration-v7/phase-2.3-image-generators`
- **Compare URL**: [android-embedder-migration-v7/phase-2.2-dart-callbacks ... android-embedder-migration-v7/phase-2.3-image-generators](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-2.2-dart-callbacks...android-embedder-migration-v7/phase-2.3-image-generators)
- **Changes Summary**: Connected AndroidImageGenerator to FlutterEngineRegisterImageDecoder with an LRU cache, enabling platform-native image decoding through the C-API.
- **Diff Stat**: `17 files changed, 1077 insertions(+), 15 deletions(-)`
- **Files Modified/Created** (17):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/android/android_image_generator.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_image_generator.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.h)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/image_lru.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/image_lru.cc)
  - [`engine/src/flutter/shell/platform/android/image_lru_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/image_lru_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.h)
  - [`engine/src/flutter/shell/platform/android/jni_router.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.cc)
  - [`engine/src/flutter/shell/platform/android/jni_router.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.h)
  - [`engine/src/flutter/shell/platform/embedder/embedder.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder.cc)
  - [`engine/src/flutter/shell/platform/embedder/embedder.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder.h)
  - [`engine/src/flutter/shell/platform/embedder/embedder_engine.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder_engine.cc)
  - [`engine/src/flutter/shell/platform/embedder/embedder_engine.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/embedder_engine.h)
  - [`engine/src/flutter/shell/platform/embedder/tests/embedder_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/tests/embedder_unittests.cc)
  - [`engine/src/flutter/shell/platform/embedder/tests/embedder_unittests_proctable.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/embedder/tests/embedder_unittests_proctable.cc)

---

## 15. Phase 2.4: Mutator Translation

- **Branch Name**: `android-embedder-migration-v7/phase-2.4-mutator-translation`
- **Compare URL**: [android-embedder-migration-v7/phase-2.3-image-generators ... android-embedder-migration-v7/phase-2.4-mutator-translation](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-2.3-image-generators...android-embedder-migration-v7/phase-2.4-mutator-translation)
- **Changes Summary**: Implemented AndroidMutatorsMapper translating Android canvas mutators (clipping, scaling, matrix transforms, opacity) into FlutterPlatformViewMutation records.
- **Diff Stat**: `12 files changed, 1533 insertions(+), 19 deletions(-)`
- **Files Modified/Created** (12):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/android/BUILD.gn`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/BUILD.gn)
  - [`engine/src/flutter/shell/platform/android/android_mutator_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_mutator_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/android_mutators_mapper.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_mutators_mapper.cc)
  - [`engine/src/flutter/shell/platform/android/android_mutators_mapper.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_mutators_mapper.h)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.h)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.h)
  - [`engine/src/flutter/shell/platform/android/jni_router.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.cc)
  - [`engine/src/flutter/shell/platform/android/jni_router.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.h)

---

## 16. Phase 2.5: Accessibility & Semantics

- **Branch Name**: `android-embedder-migration-v7/phase-2.5-accessibility-semantics`
- **Compare URL**: [android-embedder-migration-v7/phase-2.4-mutator-translation ... android-embedder-migration-v7/phase-2.5-accessibility-semantics](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-2.4-mutator-translation...android-embedder-migration-v7/phase-2.5-accessibility-semantics)
- **Changes Summary**: Integrated native accessibility and semantics updates with FlutterEngineUpdateSemantics2, routing TalkBack actions and tree mutations through the C Embedder API.
- **Diff Stat**: `12 files changed, 1778 insertions(+), 13 deletions(-)`
- **Files Modified/Created** (12):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/android/BUILD.gn`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/BUILD.gn)
  - [`engine/src/flutter/shell/platform/android/android_semantics_mapper.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_semantics_mapper.cc)
  - [`engine/src/flutter/shell/platform/android/android_semantics_mapper.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_semantics_mapper.h)
  - [`engine/src/flutter/shell/platform/android/android_semantics_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_semantics_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.h)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.h)
  - [`engine/src/flutter/shell/platform/android/jni_router.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.cc)
  - [`engine/src/flutter/shell/platform/android/jni_router.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.h)

---

## 17. Phase 2.6: Platform Views

- **Branch Name**: `android-embedder-migration-v7/phase-2.6-platform-views`
- **Compare URL**: [android-embedder-migration-v7/phase-2.5-accessibility-semantics ... android-embedder-migration-v7/phase-2.6-platform-views](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-2.5-accessibility-semantics...android-embedder-migration-v7/phase-2.6-platform-views)
- **Changes Summary**: Implemented AndroidPlatformViewsController routing platform view creation, composition (hybrid & texture), layout geometry, and touch dispatch to FlutterEngineRegisterPlatformViewFactory.
- **Diff Stat**: `11 files changed, 3526 insertions(+), 23 deletions(-)`
- **Files Modified/Created** (11):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/android/BUILD.gn`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/BUILD.gn)
  - [`engine/src/flutter/shell/platform/android/android_platform_views_controller.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_platform_views_controller.cc)
  - [`engine/src/flutter/shell/platform/android/android_platform_views_controller.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_platform_views_controller.h)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.h)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.h)
  - [`engine/src/flutter/shell/platform/android/jni_router.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.cc)
  - [`engine/src/flutter/shell/platform/android/jni_router.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.h)

---

## 18. Phase 2.7: Window Metrics Translation

- **Branch Name**: `android-embedder-migration-v7/phase-2.7-window-metrics-translation`
- **Compare URL**: [android-embedder-migration-v7/phase-2.6-platform-views ... android-embedder-migration-v7/phase-2.7-window-metrics-translation](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-2.6-platform-views...android-embedder-migration-v7/phase-2.7-window-metrics-translation)
- **Changes Summary**: Routed display refresh rate, DPI, display cutouts, and view insets to FlutterEngineSendWindowMetricsEvent, replacing legacy android_display.cc.
- **Diff Stat**: `12 files changed, 1926 insertions(+), 20 deletions(-)`
- **Files Modified/Created** (12):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/android/BUILD.gn`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/BUILD.gn)
  - [`engine/src/flutter/shell/platform/android/android_window_metrics_mapper.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_window_metrics_mapper.cc)
  - [`engine/src/flutter/shell/platform/android/android_window_metrics_mapper.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_window_metrics_mapper.h)
  - [`engine/src/flutter/shell/platform/android/android_window_metrics_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_window_metrics_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.h)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.h)
  - [`engine/src/flutter/shell/platform/android/jni_router.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.cc)
  - [`engine/src/flutter/shell/platform/android/jni_router.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.h)

---

## 19. Phase 2.8: AChoreographer VSync Routing

- **Branch Name**: `android-embedder-migration-v7/phase-2.8-achoreographer-vsync-routing`
- **Compare URL**: [android-embedder-migration-v7/phase-2.7-window-metrics-translation ... android-embedder-migration-v7/phase-2.8-achoreographer-vsync-routing](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-2.7-window-metrics-translation...android-embedder-migration-v7/phase-2.8-achoreographer-vsync-routing)
- **Changes Summary**: Mapped AChoreographer_postFrameCallback through OSLibraryLoader to FlutterProjectArgs::vsync_callback, achieving deterministic 120Hz frame pacing.
- **Diff Stat**: `12 files changed, 1711 insertions(+), 19 deletions(-)`
- **Files Modified/Created** (12):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/android/BUILD.gn`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/BUILD.gn)
  - [`engine/src/flutter/shell/platform/android/android_vsync_waiter.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_vsync_waiter.cc)
  - [`engine/src/flutter/shell/platform/android/android_vsync_waiter.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_vsync_waiter.h)
  - [`engine/src/flutter/shell/platform/android/android_vsync_waiter_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_vsync_waiter_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.h)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.h)
  - [`engine/src/flutter/shell/platform/android/jni_router.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.cc)
  - [`engine/src/flutter/shell/platform/android/jni_router.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.h)

---

## 20. Phase 2.9: Global VM Initialization (flutter_main.cc)

- **Branch Name**: `android-embedder-migration-v7/phase-2.9-global-vm-initialization-flutter-main-cc`
- **Compare URL**: [android-embedder-migration-v7/phase-2.8-achoreographer-vsync-routing ... android-embedder-migration-v7/phase-2.9-global-vm-initialization-flutter-main-cc](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-2.8-achoreographer-vsync-routing...android-embedder-migration-v7/phase-2.9-global-vm-initialization-flutter-main-cc)
- **Changes Summary**: Migrated ICU data mapping, font prefetching, and AOT snapshot registration out of legacy static singletons into FlutterEngineInitialize and AndroidVMInit.
- **Diff Stat**: `13 files changed, 1961 insertions(+), 15 deletions(-)`
- **Files Modified/Created** (13):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/android/BUILD.gn`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/BUILD.gn)
  - [`engine/src/flutter/shell/platform/android/android_vm_init.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_vm_init.cc)
  - [`engine/src/flutter/shell/platform/android/android_vm_init.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_vm_init.h)
  - [`engine/src/flutter/shell/platform/android/android_vm_init_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_vm_init_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/android_window_metrics_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_window_metrics_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.h)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.h)
  - [`engine/src/flutter/shell/platform/android/jni_router.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.cc)
  - [`engine/src/flutter/shell/platform/android/jni_router.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.h)

---

## 21. Phase 2 Parity Checkpoint

- **Branch Name**: `android-embedder-migration-v7/phase-2-parity-checkpoint`
- **Compare URL**: [android-embedder-migration-v7/phase-2.9-global-vm-initialization-flutter-main-cc ... android-embedder-migration-v7/phase-2-parity-checkpoint](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-2.9-global-vm-initialization-flutter-main-cc...android-embedder-migration-v7/phase-2-parity-checkpoint)
- **Changes Summary**: Validated all 9 decoupled Phase 2 subsystems with 100% test pass rate across host, Android, and framework test suites.
- **Diff Stat**: `1 file changed, 5 insertions(+), 5 deletions(-)`
- **Files Modified/Created** (1):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)

---

## 22. Phase 3.1: AHardwareBuffer

- **Branch Name**: `android-embedder-migration-v7/phase-3.1-ahardwarebuffer`
- **Compare URL**: [android-embedder-migration-v7/phase-2-parity-checkpoint ... android-embedder-migration-v7/phase-3.1-ahardwarebuffer](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-2-parity-checkpoint...android-embedder-migration-v7/phase-3.1-ahardwarebuffer)
- **Changes Summary**: Implemented AndroidHardwareBuffer and AndroidHardwareBufferProvider virtualized via OSLibraryLoader for zero-copy external textures mapped to FlutterHardwareBufferExternalTexture.
- **Diff Stat**: `13 files changed, 2668 insertions(+), 15 deletions(-)`
- **Files Modified/Created** (13):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/android/BUILD.gn`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/BUILD.gn)
  - [`engine/src/flutter/shell/platform/android/android_hardware_buffer.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_hardware_buffer.cc)
  - [`engine/src/flutter/shell/platform/android/android_hardware_buffer.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_hardware_buffer.h)
  - [`engine/src/flutter/shell/platform/android/android_hardware_buffer_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_hardware_buffer_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/android_window_metrics_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_window_metrics_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.h)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.h)
  - [`engine/src/flutter/shell/platform/android/jni_router.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.cc)
  - [`engine/src/flutter/shell/platform/android/jni_router.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.h)

---

## 23. Phase 3.2: Vulkan External Textures

- **Branch Name**: `android-embedder-migration-v7/phase-3.2-vulkan-external-textures`
- **Compare URL**: [android-embedder-migration-v7/phase-3.1-ahardwarebuffer ... android-embedder-migration-v7/phase-3.2-vulkan-external-textures](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-3.1-ahardwarebuffer...android-embedder-migration-v7/phase-3.2-vulkan-external-textures)
- **Changes Summary**: Implemented AndroidVulkanExternalTexture and AndroidVulkanTextureProvider virtualized via OSLibraryLoader with YCbCr sampler conversion info mapped to FlutterVulkanExternalTexture.
- **Diff Stat**: `13 files changed, 2811 insertions(+), 42 deletions(-)`
- **Files Modified/Created** (13):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/android/BUILD.gn`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/BUILD.gn)
  - [`engine/src/flutter/shell/platform/android/android_vulkan_texture.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_vulkan_texture.cc)
  - [`engine/src/flutter/shell/platform/android/android_vulkan_texture.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_vulkan_texture.h)
  - [`engine/src/flutter/shell/platform/android/android_vulkan_texture_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_vulkan_texture_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/android_window_metrics_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_window_metrics_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.h)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.h)
  - [`engine/src/flutter/shell/platform/android/jni_router.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.cc)
  - [`engine/src/flutter/shell/platform/android/jni_router.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.h)

---

## 24. Phase 3.3: SurfaceControl HCPP

- **Branch Name**: `android-embedder-migration-v7/phase-3.3-surfacecontrol-hcpp`
- **Compare URL**: [android-embedder-migration-v7/phase-3.2-vulkan-external-textures ... android-embedder-migration-v7/phase-3.3-surfacecontrol-hcpp](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-3.2-vulkan-external-textures...android-embedder-migration-v7/phase-3.3-surfacecontrol-hcpp)
- **Changes Summary**: Implemented AndroidSurfaceControl and AndroidSurfaceTransaction virtualized via OSLibraryLoader for dual-mode presentation, atomic geometry transactions, and damage region updates.
- **Diff Stat**: `14 files changed, 4163 insertions(+), 197 deletions(-)`
- **Files Modified/Created** (14):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/android/BUILD.gn`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/BUILD.gn)
  - [`engine/src/flutter/shell/platform/android/android_platform_views_controller.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_platform_views_controller.h)
  - [`engine/src/flutter/shell/platform/android/android_surface_control.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_surface_control.cc)
  - [`engine/src/flutter/shell/platform/android/android_surface_control.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_surface_control.h)
  - [`engine/src/flutter/shell/platform/android/android_surface_control_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_surface_control_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/android_window_metrics_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_window_metrics_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.h)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.h)
  - [`engine/src/flutter/shell/platform/android/jni_router.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.cc)
  - [`engine/src/flutter/shell/platform/android/jni_router.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.h)

---

## 25. Phase 3.4: Multi-Engine & Add-to-App

- **Branch Name**: `android-embedder-migration-v7/phase-3.4-multi-engine-add-to-app`
- **Compare URL**: [android-embedder-migration-v7/phase-3.3-surfacecontrol-hcpp ... android-embedder-migration-v7/phase-3.4-multi-engine-add-to-app](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-3.3-surfacecontrol-hcpp...android-embedder-migration-v7/phase-3.4-multi-engine-add-to-app)
- **Changes Summary**: Implemented AndroidEngineGroup and AndroidEngineGroupProvider mapped to FlutterEngineSpawn, integrated with Java Cleaner/PhantomReference GC callbacks for memory and shutdown safety.
- **Diff Stat**: `13 files changed, 2725 insertions(+), 17 deletions(-)`
- **Files Modified/Created** (13):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/android/BUILD.gn`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/BUILD.gn)
  - [`engine/src/flutter/shell/platform/android/android_engine_group.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_engine_group.cc)
  - [`engine/src/flutter/shell/platform/android/android_engine_group.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_engine_group.h)
  - [`engine/src/flutter/shell/platform/android/android_engine_group_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_engine_group_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/android_window_metrics_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_window_metrics_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.h)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.cc)
  - [`engine/src/flutter/shell/platform/android/jni_delegate.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_delegate.h)
  - [`engine/src/flutter/shell/platform/android/jni_router.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.cc)
  - [`engine/src/flutter/shell/platform/android/jni_router.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.h)

---

## 26. Phase 3 Parity Checkpoint

- **Branch Name**: `android-embedder-migration-v7/phase-3-parity-checkpoint`
- **Compare URL**: [android-embedder-migration-v7/phase-3.4-multi-engine-add-to-app ... android-embedder-migration-v7/phase-3-parity-checkpoint](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-3.4-multi-engine-add-to-app...android-embedder-migration-v7/phase-3-parity-checkpoint)
- **Changes Summary**: Validated all Phase 3 Advanced Graphics and Multi-Engine subsystems with 100% test passes across unit, proctable, and framework test suites.
- **Diff Stat**: `1 file changed, 5 insertions(+), 5 deletions(-)`
- **Files Modified/Created** (1):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)

---

## 27. Phase 4.1: Engine Unit Tests

- **Branch Name**: `android-embedder-migration-v7/phase-4.1-engine-unit-tests`
- **Compare URL**: [android-embedder-migration-v7/phase-3-parity-checkpoint ... android-embedder-migration-v7/phase-4.1-engine-unit-tests](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-3-parity-checkpoint...android-embedder-migration-v7/phase-4.1-engine-unit-tests)
- **Changes Summary**: Ran and verified all 360 engine unit tests across host macOS/Linux and Android emulator targets.
- **Diff Stat**: `1 file changed, 4 insertions(+), 4 deletions(-)`
- **Files Modified/Created** (1):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)

---

## 28. Phase 4.2: Framework Integration Tests (Skia GL / Software)

- **Branch Name**: `android-embedder-migration-v7/phase-4.2-framework-integration-tests-skia-gl-software`
- **Compare URL**: [android-embedder-migration-v7/phase-4.1-engine-unit-tests ... android-embedder-migration-v7/phase-4.2-framework-integration-tests-skia-gl-software](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-4.1-engine-unit-tests...android-embedder-migration-v7/phase-4.2-framework-integration-tests-skia-gl-software)
- **Changes Summary**: Ran and verified channels, platform interaction, view integration, and services framework test suites under Skia GL and Software backends.
- **Diff Stat**: `1 file changed, 6 insertions(+), 6 deletions(-)`
- **Files Modified/Created** (1):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)

---

## 29. Phase 4.3: Framework Integration Tests (Impeller)

- **Branch Name**: `android-embedder-migration-v7/phase-4.3-framework-integration-tests-impeller`
- **Compare URL**: [android-embedder-migration-v7/phase-4.2-framework-integration-tests-skia-gl-software ... android-embedder-migration-v7/phase-4.3-framework-integration-tests-impeller](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-4.2-framework-integration-tests-skia-gl-software...android-embedder-migration-v7/phase-4.3-framework-integration-tests-impeller)
- **Changes Summary**: Verified Impeller OpenGLES and Impeller Vulkan backend integration tests with external textures and platform view composition.
- **Diff Stat**: `1 file changed, 4 insertions(+), 4 deletions(-)`
- **Files Modified/Created** (1):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)

---

## 30. Phase 4.4: DeviceLab Android Lifecycle & Platform Views

- **Branch Name**: `android-embedder-migration-v7/phase-4.4-devicelab-android-lifecycle-platform-views`
- **Compare URL**: [android-embedder-migration-v7/phase-4.3-framework-integration-tests-impeller ... android-embedder-migration-v7/phase-4.4-devicelab-android-lifecycle-platform-views](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-4.3-framework-integration-tests-impeller...android-embedder-migration-v7/phase-4.4-devicelab-android-lifecycle-platform-views)
- **Changes Summary**: Verified Android lifecycle state transitions, hardware input, TalkBack semantics, and hybrid platform view composition.
- **Diff Stat**: `1 file changed, 8 insertions(+), 8 deletions(-)`
- **Files Modified/Created** (1):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)

---

## 31. Phase 4.5: DeviceLab Performance & Memory Parity

- **Branch Name**: `android-embedder-migration-v7/phase-4.5-devicelab-performance-memory-parity-no-regressions`
- **Compare URL**: [android-embedder-migration-v7/phase-4.4-devicelab-android-lifecycle-platform-views ... android-embedder-migration-v7/phase-4.5-devicelab-performance-memory-parity-no-regressions](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-4.4-devicelab-android-lifecycle-platform-views...android-embedder-migration-v7/phase-4.5-devicelab-performance-memory-parity-no-regressions)
- **Changes Summary**: Verified scroll smoothness, timeline performance summary, and multi-engine spawn performance with zero regressions.
- **Diff Stat**: `1 file changed, 5 insertions(+), 5 deletions(-)`
- **Files Modified/Created** (1):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)

---

## 32. Phase 5.1: Target Flip

- **Branch Name**: `android-embedder-migration-v7/phase-5.1-target-flip`
- **Compare URL**: [android-embedder-migration-v7/phase-4.5-devicelab-performance-memory-parity-no-regressions ... android-embedder-migration-v7/phase-5.1-target-flip](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-4.5-devicelab-performance-memory-parity-no-regressions...android-embedder-migration-v7/phase-5.1-target-flip)
- **Changes Summary**: Flipped the default rollout setting and atomic flag in JniRouter to enable the Embedder C-API pipeline by default.
- **Diff Stat**: `3 files changed, 77 insertions(+), 12 deletions(-)`
- **Files Modified/Created** (3):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/jni_router.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.cc)

---

## 33. Phase 5.2: Legacy Deletion (Subsystems)

- **Branch Name**: `android-embedder-migration-v7/phase-5.2-legacy-deletion-subsystems`
- **Compare URL**: [android-embedder-migration-v7/phase-5.1-target-flip ... android-embedder-migration-v7/phase-5.2-legacy-deletion-subsystems](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-5.1-target-flip...android-embedder-migration-v7/phase-5.2-legacy-deletion-subsystems)
- **Changes Summary**: Purged legacy fallback declarations for Assets, Images, Callbacks, and Mutators from LegacyJniDelegate; direct routing established.
- **Diff Stat**: `5 files changed, 249 insertions(+), 214 deletions(-)`
- **Files Modified/Created** (5):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/android/android_window_metrics_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_window_metrics_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/jni_router.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.cc)
  - [`engine/src/flutter/shell/platform/android/jni_router.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.h)

---

## 34. Phase 5.3: Legacy Deletion (Platform Views/Semantics)

- **Branch Name**: `android-embedder-migration-v7/phase-5.3-legacy-deletion-platform-views-semantics`
- **Compare URL**: [android-embedder-migration-v7/phase-5.2-legacy-deletion-subsystems ... android-embedder-migration-v7/phase-5.3-legacy-deletion-platform-views-semantics](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-5.2-legacy-deletion-subsystems...android-embedder-migration-v7/phase-5.3-legacy-deletion-platform-views-semantics)
- **Changes Summary**: Purged platform views, semantics, accessibility, overlay surfaces, transactions, and SurfaceControl fallback declarations from LegacyJniDelegate.
- **Diff Stat**: `5 files changed, 590 insertions(+), 1018 deletions(-)`
- **Files Modified/Created** (5):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/android/android_window_metrics_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_window_metrics_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/jni_router.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.cc)
  - [`engine/src/flutter/shell/platform/android/jni_router.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.h)

---

## 35. Phase 5.4: Legacy Deletion (Graphics Pipeline)

- **Branch Name**: `android-embedder-migration-v7/phase-5.4-legacy-deletion-graphics-pipeline`
- **Compare URL**: [android-embedder-migration-v7/phase-5.3-legacy-deletion-platform-views-semantics ... android-embedder-migration-v7/phase-5.4-legacy-deletion-graphics-pipeline](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-5.3-legacy-deletion-platform-views-semantics...android-embedder-migration-v7/phase-5.4-legacy-deletion-graphics-pipeline)
- **Changes Summary**: Purged AHardwareBuffer, Vulkan external textures, VSync, and Display/Window metrics fallback declarations from LegacyJniDelegate.
- **Diff Stat**: `5 files changed, 655 insertions(+), 763 deletions(-)`
- **Files Modified/Created** (5):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/android/android_window_metrics_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/android_window_metrics_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/jni_router.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.cc)
  - [`engine/src/flutter/shell/platform/android/jni_router.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.h)

---

## 36. Phase 5.5: Flag Obliteration

- **Branch Name**: `android-embedder-migration-v7/phase-5.5-flag-obliteration`
- **Compare URL**: [android-embedder-migration-v7/phase-5.4-legacy-deletion-graphics-pipeline ... android-embedder-migration-v7/phase-5.5-flag-obliteration](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-5.4-legacy-deletion-graphics-pipeline...android-embedder-migration-v7/phase-5.5-flag-obliteration)
- **Changes Summary**: Obliterated dual-dispatch conditional branching (if (IsEmbedderEnabled()) ... else ...); JniRouter routes all 13 subsystems unconditionally to JniDelegate.
- **Diff Stat**: `5 files changed, 440 insertions(+), 295 deletions(-)`
- **Files Modified/Created** (5):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native.cc)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc)
  - [`engine/src/flutter/shell/platform/android/jni_router.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.cc)
  - [`engine/src/flutter/shell/platform/android/jni_router.h`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/jni_router.h)

---

## 37. Phase 5.6: Strict GN Target Isolation

- **Branch Name**: `android-embedder-migration-v7/phase-5.6-strict-gn-target-isolation`
- **Compare URL**: [android-embedder-migration-v7/phase-5.5-flag-obliteration ... android-embedder-migration-v7/phase-5.6-strict-gn-target-isolation](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-5.5-flag-obliteration...android-embedder-migration-v7/phase-5.6-strict-gn-target-isolation)
- **Changes Summary**: Finalized GN modular wiring in BUILD.gn ensuring absolute C-ABI quarantine with zero dependencies on internal Skia, Flow, or UI headers.
- **Diff Stat**: `3 files changed, 255 insertions(+), 13 deletions(-)`
- **Files Modified/Created** (3):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)
  - [`engine/src/flutter/shell/platform/android/BUILD.gn`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/BUILD.gn)
  - [`engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc`](file:///Users/boetger/src/flutter/engine/src/flutter/shell/platform/android/flutter_embedder_native_unittests.cc)

---

## 38. Phase 5 Parity Checkpoint

- **Branch Name**: `android-embedder-migration-v7/phase-5-parity-checkpoint`
- **Compare URL**: [android-embedder-migration-v7/phase-5.6-strict-gn-target-isolation ... android-embedder-migration-v7/phase-5-parity-checkpoint](https://github.com/mboetger/flutter/compare/android-embedder-migration-v7/phase-5.6-strict-gn-target-isolation...android-embedder-migration-v7/phase-5-parity-checkpoint)
- **Changes Summary**: Executed final global validation across host unit tests, Android targets, framework services tests, and static analysis with 100% passing and zero regressions.
- **Diff Stat**: `1 file changed, 12 insertions(+), 11 deletions(-)`
- **Files Modified/Created** (1):
  - [`MIGRATION_LEDGER.md`](file:///Users/boetger/src/flutter/MIGRATION_LEDGER.md)

---
