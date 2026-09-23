---
name: zero-copy-buffer-lifecycle-checker
description: >
  Audits zero-copy native memory pipelines in the Android Embedder per RFC 410.0000.
  Covers AHardwareBuffer Vulkan texture import (SurfaceProducer / ycbcr_conversion_info) and
  memory-mapped Dart deferred libraries (mmap / destruction_callback / munmap).

  When to use:
  - When implementing or reviewing AndroidHardwareBuffer or AndroidVulkanExternalTexture.
  - When working with Dart deferred library loading (FlutterEngineLoadDartDeferredLibrary).
  - To prevent buffer use-after-free, memory leaks, or sampling errors in camera/video decoders.
---

# Zero-Copy Buffer Lifecycle Checker Skill

Per **RFC 410.0000**, Android embedders rely on zero-copy memory pipelines across two critical subsystems:
1. **External Textures via `SurfaceProducer` & `AHardwareBuffer`**
2. **Dart Deferred Library Snapshots via `AAssetManager` Memory Mapping**

## 1. `AHardwareBuffer` & Vulkan External Textures

When importing hardware buffers into Vulkan:
- **Discriminated Union**: Check that `FlutterVulkanExternalTexture.type` correctly indicates `kFlutterVulkanExternalTextureTypeAHardwareBuffer`.
- **YCbCr Sampling**: For camera and video decoder streams, `ycbcr_conversion_info` must be populated with the vendor's external format identifier. Without it, GPU hardware sampling produces corrupt or green frames.
- **Destruction Callback**: `destruction_callback` must be provided to release or unreference the `AHardwareBuffer` once Vulkan frame composition is finished.

## 2. Dart Deferred Library Snapshot Memory Lifetime

Split APK loading uses `mmap()` to load compiled snapshot bytecode without heap allocation:

```c
typedef struct {
  size_t struct_size;
  intptr_t loading_unit_id;
  const uint8_t* snapshot_data;
  size_t snapshot_data_size;
  const uint8_t* snapshot_instructions;
  size_t snapshot_instructions_size;
  void* user_data;
  VoidCallback destruction_callback;
} FlutterDartDeferredLibrary;
```

### Strict Memory Contract
- **Asynchronous Execution**: `FlutterRequestDartDeferredLibraryCallback` returns immediately (`void`); download or extraction occurs asynchronously.
- **Valid Buffers**: `snapshot_data` and `snapshot_instructions` must remain memory-mapped and non-executable/executable respectively until the engine invokes `destruction_callback(user_data)`.
- **Unmap Trigger**: The embedder MUST NOT call `munmap()` or close the underlying `AAsset` handle before `destruction_callback` is executed by the Dart VM.
- **Isolate Teardown**: Upon isolate shutdown or loading failure, `destruction_callback` triggers, allowing safe cleanup.

## Audit Checklist
- [ ] Confirm `ycbcr_conversion_info` is initialized for non-RGB camera formats.
- [ ] Ensure `mmap` pointer lifetimes are tied strictly to `FlutterDartDeferredLibrary.destruction_callback`.
- [ ] Verify zero heap allocations occur in per-frame texture callbacks.
