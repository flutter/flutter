---
name: sync-fence-and-fd-auditor
description: >
  Audits POSIX file descriptor lifecycle and hardware synchronization fence ownership for Hybrid Composition++
  (HCPP) via SurfaceControl.Transaction and Impeller Vulkan (synchronization_fence_fd).
  Prevents file descriptor leaks (EMFILE) and double-close hazards on all presentation and error code paths.

  When to use:
  - When implementing or reviewing AndroidPlatformViewsController, AndroidSurfaceControl, or present_view_callback.
  - When working with FlutterBackingStorePresentInfo.synchronization_fence_fd.
  - When handling SurfaceControl.Transaction.setBuffer fence handoff.
---

# Sync Fence & File Descriptor Auditor Skill

In **RFC 410.0000**, Hybrid Composition++ (HCPP) on Android 14+ (API 34+) uses hardware sync fences to coordinate layer presentation between Impeller Vulkan and `SurfaceControl.Transaction` without CPU blocking:

```c
typedef struct {
  size_t struct_size;
  FlutterRegion* paint_region;
  int synchronization_fence_fd;
} FlutterBackingStorePresentInfo;
```

## Strict File Descriptor Contract

The engine exports the GPU completion semaphore into a POSIX `sync_fence` file descriptor via `VK_KHR_external_fence_fd` (`vkGetFenceFdKHR`).

### Ownership Rule
**Ownership of `synchronization_fence_fd` transfers completely to the embedder.**
The embedder MUST close the file descriptor on **every code path**:

1. **Successful Presentation**:
   - The file descriptor is passed to Android's transaction:
     ```java
     transaction.setBuffer(surfaceControl, hardwareBuffer, syncFence, ...);
     ```
   - In native NDK or JNI wrapper, passing `fd` transfers ownership to the system `SyncFence` object.
2. **Error / Early Return / Fallback Path**:
   - If presentation is aborted, the surface is destroyed, or the transaction fails:
     ```cpp
     if (fence_fd >= 0) {
       ::close(fence_fd);
       fence_fd = -1;
     }
     ```
3. **No Double Close**:
   - Once handed off or closed, reset `fence_fd = -1` immediately to prevent closing an unrelated recycled file descriptor.

## Audit Checklist

When reviewing code touching `synchronization_fence_fd`:
- [ ] Check RAII wrapper: Does the implementation wrap the file descriptor in a scoped closer (e.g. `fml::UniqueFD`) immediately upon receiving `FlutterBackingStorePresentInfo`?
- [ ] Check early exits: Do any `return` or `break` statements exist between receipt of `fence_fd` and its handoff to `SurfaceControl` that could bypass `close()`?
- [ ] Check value when unused: Does the code correctly handle `fence_fd == -1` (no synchronization fence needed)?
