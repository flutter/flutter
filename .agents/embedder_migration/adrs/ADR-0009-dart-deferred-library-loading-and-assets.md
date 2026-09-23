# ADR-0009: Dart Deferred Library Loading Memory Lifetime and APK Asset Resolution

## Status
ACCEPTED

## RFC 410 Cross-Reference
Section: *Detailed Design* -> *Dart Deferred Library Loading* and *Custom Asset and Kernel Resolution*

## Context & Problem Statement
Android supports dynamic delivery via Google Play Feature Delivery and split APKs. When Dart code requests a deferred component (`deferred as`), the Android embedder must download or extract the split APK and load the compiled snapshot into the running isolate.

Currently, this is handled through private JNI calls into `PlatformViewAndroid::LoadDartDeferredLibrary`. Because split APK snapshot assets are memory-mapped (`mmap`) from disk via `AAssetManager`, memory lifetime must be strictly synchronized: unmapping before Dart is done causes segmentation faults, while failing to unmap causes permanent memory leaks.

Additionally, desktop embedders load assets from loose filesystem paths (`FlutterProjectArgs.assets_path`), whereas Android streams assets directly from the APK via `AAssetManager`. Passing file paths would require extracting all assets to disk during startup, causing disk bloat and cold-startup latency.

## Non-Negotiable Invariants
1. **Asynchronous Request Callback**: `FlutterRequestDartDeferredLibraryCallback` must return immediately without blocking the engine isolate thread during split APK download or extraction.
2. **Deterministic Unmap Trigger**: The embedder MUST NOT call `munmap()` or close the underlying `AAsset` handle before the Dart VM triggers `FlutterDartDeferredLibrary.destruction_callback`.
3. **Zero-Copy APK Asset Streaming**: Assets and kernel blobs packaged in the APK must be streamed into memory via NDK `AAssetManager` memory mapping (`FlutterCustomAssetResolver`) without disk extraction.

## Chosen Solution
- Extend `embedder.h` with:
  ```c
  typedef void (*FlutterRequestDartDeferredLibraryCallback)(
      intptr_t loading_unit_id,
      void* user_data);

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

  FLUTTER_EXPORT
  FlutterEngineResult FlutterEngineLoadDartDeferredLibrary(
      FLUTTER_API_SYMBOL(FlutterEngine) engine,
      const FlutterDartDeferredLibrary* library);
  ```
- The engine captures `destruction_callback` in `DeferredLibraryLifetime` held by `fml::NonOwnedMapping`. When the Dart VM finishes loading and drops its references to data and instruction buffers, the destructor calls `destruction_callback`, allowing Android to safely `munmap()`.
- Introduce `FlutterCustomAssetResolver` and `FlutterAssetMapping` to stream APK assets directly through `APKAssetProvider` without subclassing internal `flutter::AssetResolver`.

## Rejected Alternatives & Rationale
- *Extracting split APK assets to disk*: Rejected because disk extraction causes startup delay, requires storage permissions, and bloats device disk usage.
- *Synchronous deferred library download*: Rejected because network and disk operations must never stall the engine UI isolate thread.

## Verification Contract
- Integration test loads 5 distinct deferred loading units and verifies that `destruction_callback` fires on isolate shutdown.
- AddressSanitizer and LeakSanitizer confirm zero memory leaks and zero use-after-free errors during deferred library lifecycle.
- APK asset resolver tests verify zero-copy asset loading latency matches the legacy implementation.
