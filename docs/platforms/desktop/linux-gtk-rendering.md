# Linux GTK Rendering Paths

## Scope

This document describes how the Linux embedder presents Flutter output through
GTK3 and GTK4, including the opt-in GTK4 Impeller Vulkan backend. It deliberately distinguishes CPU-copy avoidance,
GPU-copy avoidance, and synchronization: describing every accelerated path as
"direct" hides important performance and correctness tradeoffs.

The selected path depends on the GTK variant, display backend, GTK/GDK runtime
capabilities, EGL driver extensions, and the selected renderer.

This covers presentation of Flutter's composed frame, not video decoding or
the plugin-to-Flutter external-texture boundary. Enabling DMA-BUF here does not
make a media plugin export DMA-BUFs or select Flutter's Vulkan backend.

## Frame pacing selection

Set `FLUTTER_LINUX_FRAME_PACER=gtk` (the current default) or `engine` before
starting the app to compare scheduling policies independently of its rendering
backend. Selection applies to both GTK3 and GTK4 and is fixed at engine startup;
invalid values fail startup. The engine fallback currently uses a fixed 60 Hz
phase. See [frame pacing and lifecycle tests](../../../engine/src/flutter/shell/platform/linux/testing/FRAME_PACING.md)
for ownership, recovery behavior, benchmark requirements, and limitations.

## Terminology

* **CPU-copy-free**: pixels do not pass through `glReadPixels` or CPU memory.
* **Strict zero-copy**: the consumer samples the producer's original backing
  allocation; no CPU or GPU copy is made.
* **GPU-only copy**: a GPU blit or resolve produces a second allocation, without
  CPU readback. This does not imply dedicated video memory; integrated GPUs
  can use shared system memory.
* **Direct rendering** is avoided below unless the exact ownership and copy
  behavior are stated.

## Paths

| Path | GTK | Pixel transfer | Synchronization | Notes |
| --- | --- | --- | --- | --- |
| Memory texture/readback | GTK4 | `glReadPixels`, RGBA-to-BGRA swizzle, `GdkMemoryTexture` | Readback synchronizes | Most compatible GTK4 fallback; highest CPU cost. |
| Impeller Vulkan readback | GTK4 | Optimal-tiling Vulkan image copied to coherent host memory, composed into `GdkMemoryTexture` | Engine host completion, transfer barriers and a readback fence | Enables Flutter GPU compute. Currently has CPU copies and no Vulkan DMA-BUF export; experimental and opt-in. |
| Shared GL texture | GTK4 | EGLImage import into a sibling framebuffer, then `GdkGLTexture` | EGL fence; GPU wait when GDK has a compatible EGL context | CPU-copy-free and usually no GPU pixel copy. Falls back to a client wait for GLX/non-EGL consumers, or `glFinish()` when fences are unavailable. |
| Exported DMA-BUF texture | GTK4 | Render framebuffer is GPU-blitted to an EGLImage-backed export snapshot; GDK imports its DMA-BUF | Native fence handoff, with completion fallback | CPU-copy-free and cross-renderer-oriented. Current implementation is **not** strict zero-copy because of the snapshot blit. |
| GTK graphics offload | GTK4, 4.14+ runtime | Optional `GtkGraphicsOffload` wrapper around the texture widget; suitable DMA-BUFs can be handed to the Wayland compositor | Existing texture ownership and synchronization | GTK decides acceptance per scene and uses ordinary composition when unavailable. Independent of Flutter's subsurface renderer and of compositor direct scanout. |
| Wayland EGL subsurface | GTK3/GTK4 | Flutter texture is rendered into a separate subsurface EGL surface | EGL/context handoff | CPU-copy-free presentation path for whole-view Wayland content. It is not a replacement for a `GdkTexture` used in GTK composition. |
| GTK3 normal compositor | GTK3 | CPU readback/upload where a Wayland subsurface is not used | Readback | Compatibility fallback; upstream intentionally removed GTK3 shared-EGL-image frame sharing. |

## GTK4 OpenGL Selection

The GTK4 compositor chooses a route in this order:

1. **DMA-BUF**, when `FLUTTER_GTK4_ENABLE_DMABUF=1` (or graphics offload requests
   it implicitly) and all runtime checks
   pass:
   GTK exposes the DMA-BUF texture APIs, the EGL driver exposes
   `EGL_MESA_image_dma_buf_export`, GDK accepts the exported format/modifier,
   and an export snapshot is available.
2. **Shared GL texture**, when the compositor framebuffer is shareable. An
   EGLImage lets a framebuffer in the GDK GL context sample the same backing
   texture and produce a `GdkGLTexture`.
3. **Memory texture readback**, when native GL sharing is unavailable. Set
   `FLUTTER_GTK4_DISABLE_READBACK=1` to turn this fallback into a visible
   failure while diagnosing an accelerated path.

DMA-BUF is deliberately opt-in while the compatibility matrix is still being
validated. Unsupported DMA-BUF configurations normally fall back to shared GL.
A failed synchronization wait rejects the texture rather than publishing
unfinished pixels. Readback is available when the compositor selects its
non-sharing mode; it is not a guaranteed recovery from every per-frame EGL
image or synchronization failure.

This ordering applies to the GTK4 OpenGL texture compositor. A view using the Wayland
subsurface renderer has a separate presentation path. GTK4 subsurface support
is opt-in through `FLUTTER_GTK4_ENABLE_SUBSURFACE=1`; it also requires a suitable
Wayland surface and currently applies only to the implicit OpenGL view, not
secondary views. Leave this unset when comparing GTK texture routes.

## GTK Graphics Offload

Set `FLUTTER_GTK4_ENABLE_GRAPHICS_OFFLOAD=1` to place the texture widget inside
`GtkGraphicsOffload`. This also requests DMA-BUF export unless
`FLUTTER_GTK4_ENABLE_DMABUF` is explicitly set; `=0` preserves texture fallback
for diagnostic comparisons. With the flag unset, the hierarchy is unchanged.

The wrapper is discovered through the runtime API table, requiring GTK 4.14+
and `gtk_graphics_offload_get_type`. Older runtimes or a missing symbol retain
the original widget. On a supported runtime, GTK still decides whether the
scene, texture format/modifier, clipping, transform and compositor allow offload.
Input, sizing and semantic nodes stay on the render widget; the wrapper has the
presentation accessibility role and no label. Transparency is preserved.

Confirm acceptance with GTK diagnostics and non-null buffer attachments to
GTK's child Wayland surface. A configured wrapper or successful DMA-BUF export
alone does not prove acceptance. The export snapshot blit remains, and accepted
offload does not establish direct scanout, zero-copy rendering or lower latency.
Compare app and compositor CPU/GPU work together, with equal viewports/workloads.

See [offload validation](../../../engine/src/flutter/shell/platform/linux/testing/GRAPHICS_OFFLOAD.md)
for test coverage and observed-handoff checks.

## What DMA-BUF Improves

DMA-BUF avoids the expensive CPU readback and re-upload boundary. Its imported
texture can be consumed by GTK renderers that are not using the same OpenGL
context, including Vulkan-oriented GTK configurations, subject to driver and
format support.

The current route still has a GPU-only copy:

```text
Flutter render framebuffer
  -> GPU framebuffer blit
DMA-BUF export snapshot (EGLImage-backed)
  -> EGL DMA-BUF export and native fence
GDK DMA-BUF texture
```

The snapshot is necessary today because GTK may retain a texture after Flutter
has begun rendering the next frame. The snapshot pool gives GTK stable
ownership without racing the producer. Eliminating that blit would require a
safe producer-buffer lifetime protocol and should be measured before adding
complexity.

## Synchronization Boundaries

The paths have different synchronization quality:

* **DMA-BUF** exports an Android native EGL fence and imports it into the
  exported DMA-BUF plane. This allows GPU-side readiness tracking without a
  CPU completion wait when fence export/import succeeds. The implementation
  uses completion synchronization (`glFinish()`) when that handoff is unavailable.
* **Shared GL texture** creates an `EGL_KHR_fence_sync` fence after Flutter
  submits the frame. When GDK has a compatible EGL context, it inserts an
  `eglWaitSyncKHR` GPU wait before sampling. GLX or non-EGL consumers use a
  client wait; drivers without fences retain the `glFinish()` fallback.
* **Readback** necessarily synchronizes as part of `glReadPixels`.
* **Subsurface** has its own EGL presentation boundary and producer fence
  handling, with a `glFinish()` fallback when fence support is unavailable.

DMA-BUF is a candidate for reducing cross-renderer handoff cost, not a guarantee
of lower latency than shared GL or subsurfaces. Compare the actual driver,
renderer, synchronization path, and workload.

## GTK Renderer Considerations

GTK4 renderers make the distinction more important:

* `GSK_RENDERER=ngl` or `gl`: shared GL textures are a natural fit, though the
  fallback `glFinish()` or client waits can still limit frame pacing.
* `GSK_RENDERER=vulkan`: DMA-BUF is the promising interop route. A GL texture
  alone does not create Vulkan interop.
* `GSK_RENDERER=cairo`: useful as a diagnostic software baseline, not an
  accelerated presentation target.

Available renderer names depend on the installed GTK version. `GSK_RENDERER`
selects GTK's renderer, not Flutter's rendering backend.

OpenGL remains the default Flutter backend. On GTK4,
`FLUTTER_LINUX_RENDERER=vulkan` selects the experimental Impeller Vulkan backend;
it requires a Vulkan 1.1 graphics/compute device and an engine built with Vulkan
support. Impeller is enabled for this selection; explicitly disabling Impeller
fails startup. Device initialization failures are reported without silently
selecting GLES. Flutter GPU must also be enabled to use its compute API.

`GSK_RENDERER=vulkan` alone still selects only GTK presentation. DMA-BUF and
graphics offload do not change Flutter's backend. The Vulkan implementation owns
its device/queue independently of GTK. A single origin-aligned Flutter layer is
copied on the GPU into an immutable linear DMA-BUF and imported by GTK 4.14 or
newer. Export/import capability failures and multi-layer scenes use readback.
`FLUTTER_GTK4_ENABLE_DMABUF=0` forces readback; unlike the OpenGL path, Vulkan
attempts DMA-BUF by default. Debug logs identify the selected presentation path.
The export completes before publication and stays alive until GTK releases it,
so engine backing-store reuse cannot overwrite a displayed frame. A bounded pool
reuses export buffers and their command resources after texture release and
reader-fence readiness; pool exhaustion uses readback for that frame.

GTK frame callbacks now schedule Flutter vsync from the primary view's GTK frame
clock, with a timer fallback when the view is unmapped. Vulkan rendering waits
on a marker fence in Impeller's graphics queue before handing the frame to the
compositor; fence setup failures retain the device-idle safety path. Multiple
Flutter views still need per-view display-clock selection.

This route makes one GPU copy and waits for completion. It avoids CPU pixel
processing and GTK upload when import succeeds, but is not zero-copy rendering.
The optional graphics-offload wrapper can consume the exported texture; actual
compositor handoff must still be verified. It uses neither EGL export nor the
Wayland EGL path above. Pixel-buffer plugins use a Vulkan upload and work with
their existing RGBA callback. GL-only plugins require the OpenGL renderer.

See [Vulkan architecture and validation](../../../engine/src/flutter/shell/platform/linux/testing/VULKAN.md)
and the [compute investigation](../../../engine/src/flutter/shell/platform/linux/testing/COMPUTE.md).
A local profile comparison now records GTK3 OpenGL, GTK4 OpenGL and GTK4
Vulkan frame timings, CPU use, DRM GPU activity and memory in the sibling plans
repository. It measures engine completion rather than compositor presentation;
more workloads and Wayland presentation feedback remain follow-up work.

Renderer names alone do not guarantee a path. The runtime API, EGL extensions,
format/modifier acceptance, and frame size must all pass the compositor's
checks.

## Debugging Matrix

Run these from a GTK4-capable application project with a matching GTK4 engine
artifact. Add the local-engine arguments described in
[Linux GTK Variant Selection](linux-gtk-variant.md#local-engine-builds) when
using a locally built engine. Compare the renderers available on the host:

```bash
GSK_RENDERER=ngl flutter run -d linux --linux-gtk=gtk4
GSK_RENDERER=gl flutter run -d linux --linux-gtk=gtk4
GSK_RENDERER=vulkan flutter run -d linux --linux-gtk=gtk4
GSK_RENDERER=cairo flutter run -d linux --linux-gtk=gtk4

FLUTTER_GTK4_ENABLE_DMABUF=1 GSK_RENDERER=vulkan \
  flutter run -d linux --linux-gtk=gtk4
FLUTTER_GTK4_ENABLE_GRAPHICS_OFFLOAD=1 GSK_RENDERER=vulkan \
  flutter run -d linux --linux-gtk=gtk4
FLUTTER_GTK4_DISABLE_READBACK=1 GSK_RENDERER=ngl \
  flutter run -d linux --linux-gtk=gtk4
```

Exercise startup, texture/video playback, resize in both directions, hiding
and restoring windows, and multi-window/popover surfaces. The accelerated
route must be compared with GTK3 and the GTK4 readback fallback for correctness
as well as throughput and latency.

## Implementation References

- [GTK4 compositor](../../../engine/src/flutter/shell/platform/linux/fl_compositor_opengl_gtk4.cc)
- [GTK4 graphics offload](../../../engine/src/flutter/shell/platform/linux/fl_graphics_offload_gtk4.cc)
- [GTK3 frame transfer](../../../engine/src/flutter/shell/platform/linux/fl_opengl_frame.cc)
- [Subsurface renderer](../../../engine/src/flutter/shell/platform/linux/fl_view_renderer_subsurface.cc)
- [GTK4 Runtime API Compatibility](linux-gtk4-runtime-api.md)
