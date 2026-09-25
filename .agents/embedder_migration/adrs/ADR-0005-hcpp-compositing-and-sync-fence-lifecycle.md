# ADR-0005: Hybrid Composition++ (HCPP), POSIX `sync_fence` FD Lifecycle, and Multi-View Value Capture

## Status
ACCEPTED

## RFC 410 Cross-Reference
Section: *Detailed Design* -> *Hybrid Composition++ (HCPP), SurfaceControl Compositing, and Per-View Frame State*

## Context & Problem Statement
In legacy Hybrid Composition (HC) under Skia, coordinating native Android views with Flutter layers required dynamically merging the raster thread into the platform thread (`fml::RasterThreadMerger`) to avoid thread synchronization deadlocks. Dynamic thread merging leaked engine threading semantics into embedders, caused lease hysteresis complexity, and slowed frame pacing.

Starting with Android 14 (API level 34), Flutter supports Hybrid Composition++ (HCPP) under Impeller Vulkan. HCPP delegates layer compositing directly to Android's OS window compositor (`SurfaceFlinger`) via `SurfaceControl` transactions and hardware sync fences (`ASyncFence` / `VK_KHR_external_fence_fd`), allowing the raster thread and platform UI thread to run completely asynchronously without thread merging.

However, two critical hazards must be addressed:
1. Impeller Vulkan exports GPU completion semaphores into POSIX file descriptors (`synchronization_fence_fd`). Failing to close these descriptors leads to immediate file descriptor exhaustion (`EMFILE`) and fatal crashes.
2. In multi-view/multi-window configurations, consecutive views rasterizing on the raster thread will overwrite shared composition state if stored on a shared controller.

## Non-Negotiable Invariants
1. **No Thread Merging in C-API**: No `RasterThreadMerger` or thread-leasing handles may be added to `embedder.h`. `external_view_embedder/` is retained only in legacy code and deleted in Phase 4.
2. **Strict FD Ownership**: The embedder takes full POSIX ownership of `FlutterBackingStorePresentInfo.synchronization_fence_fd`. The descriptor must be transferred to `SurfaceControl.Transaction.setBuffer` or closed via `::close(fd)` on **every** code path (including errors). Once closed or transferred, the handle must be reset to `-1`.
3. **Per-View Value Capture**: All frame composition state (ordered `FlutterLayer` slices, bounds, and `FlutterPlatformViewMutation` arrays) must be captured **by value** in the `present_view_callback` closure before dispatching to the platform thread. No mutable per-frame fields may be stored on `AndroidPlatformViewsController`.
4. **View ID Keying**: All native window handles (`ANativeWindow*`) and layer trees (`ASurfaceControl*`) must be keyed strictly by `FlutterViewId`.

## Chosen Solution
- `AndroidPlatformViewsController` implements `FlutterCompositor` layer presentation (`present_view_callback` / `create_backing_store_callback`).
- In `present_view_callback`, `AndroidPlatformViewsController` receives `FlutterPresentViewInfo.view_id` and `FlutterBackingStorePresentInfo.synchronization_fence_fd`.
- Frame state is deep-copied by value into a lambda posted to the platform task runner.
- The platform task runner translates the layer sequence into atomic `SurfaceControl.Transaction` calls (`setLayer`, `setCrop`, `setMatrix`), attaches the `AHardwareBuffer` and sync fence via `setBuffer()`, and commits the transaction.
- When SurfaceFlinger finishes reading the buffer, the release fence signals, returning the backing store to `AndroidSurfaceControl`'s surface pool for recycling.

## Rejected Alternatives & Rationale
- *Adding thread-merger handles to `embedder.h`*: Rejected because exposing `RasterThreadMerger` lease semantics would leak internal engine threading models into the public C-ABI.
- *Storing frame state as member variables*: Rejected because concurrent multi-view presentation (View A presenting on platform thread while View B rasterizes on raster thread) causes data races and corrupted view slicing.
- *Synchronous CPU fence waiting*: Rejected because blocking the CPU thread to wait for GPU rendering destroys pipeline concurrency and causes dropped frames.

## Verification Contract
- Automated static and dynamic FD audit confirms zero file descriptor leaks across 100,000 consecutive frames.
- Golden tests validate that clipping paths, rounded corners, and opacity mutations render identically between HCPP, HC, and TLHC.
- Multi-view stress test running dual independent presentation displays verifies zero cross-view state corruption.
