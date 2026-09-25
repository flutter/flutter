# ADR-0004: Graphics Backend Probing, Caching, and Renderer Lifecycle Decoupling

## Status
ACCEPTED

## RFC 410 Cross-Reference
Section: *Detailed Design* -> *Graphics Surface Setup, Context Ownership, and Surface Lifecycle* and *Renderer Availability, Multi-Window Lifecycle, and FlutterViewId Keying*

## Context & Problem Statement
In the existing architecture, `AndroidContextDynamicImpeller` deferred the decision between Vulkan and OpenGL ES until `GetImpellerContext` was called on the raster thread via `SetupImpellerContext`. However, `embedder.h` requires a concrete renderer configuration struct (`FlutterRendererConfig` selecting `kOpenGL` or `kVulkan`) at `FlutterEngineInitialize` time.

Performing synchronous Vulkan driver queries during `FlutterLoader.ensureInitializationComplete` on Android's main thread introduces a 15–30 ms cold-startup delay on budget devices (such as MediaTek or older Mali chipsets) due to driver library loading and physical device property enumeration.

Furthermore, Android window surfaces are created and destroyed dynamically across Activity lifecycle events. Destroying and recreating the entire `FlutterRendererConfig` during window changes introduces severe driver overhead and destroys pipeline caches.

## Non-Negotiable Invariants
1. **Zero Main-Thread Driver Stall**: Application startup on the Android UI thread must never perform synchronous Vulkan physical device enumeration.
2. **Orthogonality of Config and Surface**: Static graphics configuration (`FlutterRendererConfig`) must remain immutable across Activity lifecycle events; dynamic window presentation must attach/detach via `FlutterEngineNotifyCreated` and `FlutterEngineNotifyDestroyed`.
3. **Synchronous Surface Destruction**: When `surfaceDestroyed()` is called by Android, `FlutterEngineNotifyDestroyed` must complete synchronously before the callback returns to the OS, ensuring all on-screen swapchains and `ANativeWindow` references are released.
4. **GPU Availability Suspension**: When an app is backgrounded (`onStop`), the embedder must call `FlutterEngineSetGpuAvailability(engine, kFlutterGpuAvailabilityFlushAndMakeUnavailable)` followed by `kFlutterGpuAvailabilityUnavailable` to prevent `VK_ERROR_DEVICE_LOST` or OS process termination.

## Chosen Solution
- **Asynchronous Vulkan Probe**:
  1. `FlutterLoader.startInitialization` dispatches an asynchronous Vulkan capability check to a background worker isolate/thread during `Application.onCreate`.
  2. The probe results are cached in Android `SharedPreferences`.
  3. Subsequent app launches read the cached flag in <0.5 ms during `ensureInitializationComplete`.
  4. If a driver crash or OS upgrade occurs, the embedder falls back safely to OpenGLES.
- **Renderer Lifecycle Separation**:
  - `FlutterRendererConfig` (OpenGL or Vulkan) is populated once and passed to `FlutterEngineInitialize`.
  - Window surface attachments (`ANativeWindow`) and swapchains are created and destroyed dynamically via `FlutterEngineNotifyCreated` and `FlutterEngineNotifyDestroyed` without tearing down the underlying GPU context or pipeline caches.
  - Multi-window surfaces are registered and destroyed via `FlutterEngineAddView` and `FlutterEngineRemoveView`, keyed strictly by `FlutterViewId`.

## Rejected Alternatives & Rationale
- *Synchronous Vulkan probing on main thread*: Rejected because it introduces a 15–30 ms jank stall directly on the critical startup path of budget mobile devices.
- *Recreating `FlutterRendererConfig` on every Activity resume*: Rejected because destroying the GPU context destroys compiled Impeller pipeline state objects (PSOs), triggering severe frame shader compilation stutter on resume.
- *Asynchronous `surfaceDestroyed` processing*: Rejected because Android requires that native window handles be released before `surfaceDestroyed` returns; delayed release causes fatal `SIGSEGV` or `EGL_BAD_NATIVE_WINDOW` errors.

## Verification Contract
- Startup benchmark on budget Android devices verifies that `ensureInitializationComplete` completes in under 0.5 ms.
- Stress test: Rapidly pausing and resuming an Activity 1,000 times verifies zero context leaks and zero dropped frames.
- Cold-start test with driver failure simulation asserts clean fallback to OpenGL ES.
