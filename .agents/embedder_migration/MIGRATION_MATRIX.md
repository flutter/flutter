# Android Embedder C-API Subsystem Migration Matrix (RFC 410)

This matrix defines the deterministic state machine for migrating the Flutter Android Embedder (`//shell/platform/android/`) to the public C-API (`embedder.h`).

All branches in the chain follow the slug: `android-embedder-migration-v10/*`

| Subsystem & Responsibility | Baseline Headers | Target Component in `:flutter_embedder_native_src` | Embedder C-API Target | Active Phase | Branch / PR | Status | Verification Target |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **0. LLM Configuration & PR Chain** | N/A | `.agents/skills/`, `session_state.json` | N/A | Phase 0 | `0.0-llm-configuration` | **ACTIVE** | `dart pr_chain.dart verify` |
| **1. Embedder C-API Extensions** | 0 | `shell/platform/embedder/embedder.h` | `FlutterEngineSpawn`, `FlutterPlatformMessageCallback2`, etc. | Phase 1 | `1.0-embedder-c-api-extensions` | **PLANNED** | `embedder_unittests` |
| **2. GN Firewall & Partitioning** | 98 | `:flutter_embedder_native_src` | `FLUTTER_ENGINE_NO_PROTOTYPES`, `check_includes = true` | Phase 2 | `2.0-gn-firewall-modularization` | **PLANNED** | `check_android_embedder_deps.py` |
| **3. Surface Control & HCPP** | 5 | `AndroidSurfaceControl` | `FlutterEngineNotifyCreated/Destroyed`, `SetGpuAvailability` | Phase 2 | `2.1-surface-control` | **PLANNED** | Host unit tests + Concurrency |
| **4. Platform Views & Mutators** | 2 | `AndroidPlatformViewsController`, `AndroidMutatorsMapper` | `FlutterCompositor`, `FlutterPlatformViewMutation` | Phase 2 | `2.2-platform-views-hcpp` | **PLANNED** | Goldens across API 34+ / TLHC |
| **5. External Textures & AHB** | 5 | `AndroidHardwareBuffer`, `AndroidVulkanExternalTexture` | `FlutterVulkanExternalTexture`, `FlutterOpenGLTexture2` | Phase 2 | `2.3-external-textures` | **PLANNED** | Video/Camera playback tests |
| **6. Task Runners & Vsync** | 25 | `AndroidVsyncWaiter`, Looper delegates | `FlutterCustomTaskRunners`, `FlutterEngineOnVsync` | Phase 2 | `2.4-task-runners-vsync` | **PLANNED** | `TaskRunnerTest.*`, `VsyncTest.*` |
| **7. Platform Channels & Input** | 5 | `FlutterEmbedderNative`, `DartMessenger` | `FlutterPlatformMessageCallback2`, `FlutterPointerEvent` | Phase 2 | `2.5-platform-channels-input` | **PLANNED** | Background Task Queue tests |
| **8. Semantics & Asset Provider** | 2 | `AndroidSemanticsMapper`, `APKAssetProvider` | `FlutterSemanticsNode2` (in-place), `FlutterCustomAssetResolver` | Phase 2 | `2.6-semantics-assets` | **PLANNED** | `AccessibilityBridgeTest.*` |
| **9. C-API Cutover** | 98 | `FlutterEmbedderNative` JNI Registration | `FlutterEngineInitialize`, `FlutterEngineRunInitialized` | Phase 3 | `3.0-c-api-cutover` | **PLANNED** | Full E2E & CTS Conformance |
| **10. Legacy Purge & Lock** | 0 | Delete `AndroidShellHolder`, `PlatformViewAndroid` | Terminal Lock (`total_allowed_internal_headers: 0`) | Phase 4 | `4.0-legacy-purge` | **PLANNED** | Ratchet zero tolerance |
