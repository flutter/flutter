---
name: embedder-concurrency-characterizer
description: >
  Designs and executes concurrency stress tests targeting pre-existing Android embedder testing gaps
  identified in RFC 410.0000. Validates thread-sensitive race conditions, rapid surface detachment,
  window reattachment, and headless background execution to prevent false-positive test runs.

  When to use:
  - When modifying surface lifecycle, task runners, vsync, or background execution in the Android embedder.
  - Before declaring any milestone complete in the android-embedder-migration-v10 chain.
  - When debugging race conditions between the Android platform UI Looper and the raster thread.
---

# Embedder Concurrency Characterizer Skill (RFC 410 Aligned)

Per **RFC 410.0000**, historical testing in the Android embedder contains notable test coverage gaps, particularly around concurrency and OS lifecycle transitions. Relying solely on existing test suites creates a false sense of security where pre-existing bugs remain hidden during the refactor.

This skill provides testing procedures for the **4 mandatory concurrency gap suites**:

## 1. Surface Destruction Concurrent with Frame Submission

* **Hazard**: Native Android `SurfaceView` and `TextureView` destroy surfaces asynchronously on the Android UI thread while the rasterizer submits draw calls on the raster thread.
* **Test Strategy**:
  - Spawn an active render loop generating animated frames at 120 Hz.
  - Concurrently trigger rapid window detachment (`SurfaceHolder.Callback.surfaceDestroyed`) on the UI thread.
  - Assert that `FlutterEngineNotifyDestroyed` completes synchronously before `surfaceDestroyed()` returns.
  - Verify zero `SIGSEGV` or `EGL_BAD_NATIVE_WINDOW` / `VK_ERROR_SURFACE_LOST_KHR` crashes across 10,000 iterations.

## 2. Initialization and Destruction Races

* **Hazard**: Multi-threaded startup where Flutter engine initialization coincides with rapid `Activity` finish/destruction.
* **Test Strategy**:
  - Rapidly instantiate `FlutterEngine`, call `FlutterEngineInitialize`, and immediately invoke `FlutterEngineDeinitialize` / shutdown before initial frame presentation.
  - Verify that `ALooper` callbacks and native task runners drain pending tasks without referencing deallocated engine memory.

## 3. Window Surface Reattachment without Engine Destruction

* **Hazard**: Configuration changes (screen rotation, foldable posture changes, split-screen resize) detach the window surface and rebind a new surface while Dart isolates continue running.
* **Test Strategy**:
  - Run continuous state updates in a background Dart isolate.
  - Execute `FlutterEngineNotifyDestroyed` -> verify swapchain teardown.
  - Execute `FlutterEngineNotifyCreated` with a new `ANativeWindow` -> verify new swapchain allocation.
  - Assert that isolate state is preserved, texture handles remain valid, and frame rendering resumes without context leaks.

## 4. Headless Execution and Background Services

* **Hazard**: Android `Service` or `BroadcastReceiver` components executing platform channels and Dart code when no window surface is bound and GPU is suspended.
* **Test Strategy**:
  - Launch engine in headless mode without attaching any `ANativeWindow`.
  - Invoke `FlutterEngineSetGpuAvailability(engine, kFlutterGpuAvailabilityUnavailable)`.
  - Dispatch platform messages to background Dart isolates and verify response delivery.
  - Assert that no raster tasks attempt GPU driver submission while unavailable.
