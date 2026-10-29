# Experimental Impeller Vulkan on GTK4

Set `FLUTTER_LINUX_RENDERER=vulkan` when launching a GTK4 app with a local engine
built with Vulkan support. OpenGL remains the default. Vulkan requires a loader,
a Vulkan 1.1 device with a queue supporting graphics and compute, and the
surface/Wayland-surface and swapchain extensions currently required by Impeller.
The GTK presentation renderer is independent: `GSK_RENDERER=vulkan` alone does
not select Impeller Vulkan.

An explicit Vulkan request enables Impeller. `--enable-impeller=false` is an
error, and loader/device failures fail startup rather than silently running GLES.
Flutter GPU additionally requires `--enable-flutter-gpu`, supplied by the Dart
project or engine switches. This is not a new framework context override.

## Organization and ownership

- `fl_vulkan_manager` loads `libvulkan.so.1` on demand, creates the device and
  queue, allocates optimal-tiling RGBA8 backing images, and performs fallback readback.
  DMA-BUF extensions and exportable-buffer support are negotiated independently.
  There are no mandatory Vulkan library imports and no newer GTK API dependency.
- Both Vulkan procedure resolvers are intercepted, including resolver pointers
  returned by other resolvers. Queue submission, queue waits and device waits
  share a per-device lock in `fl_vulkan_queue_sync`. Registry lookup uses a short
  separate lock; no driver call holds it. An idle wait on one engine therefore
  does not serialize submissions on another engine's device. All users must retain
  a device lease through the operation; unregister follows the final lease release.
  Device feature enablement matches the Impeller capability chain for the
  advertised extensions.
- `embedder_render_target_vulkan_impeller` wraps compositor images as Impeller
  attachments with MSAA and depth/stencil transients. The shared embedder waits
  for Vulkan completion before invoking its compositor presentation callback.
  Wrapped attachments finish in `GENERAL`; the readback path restores that
  layout before cached backing stores can be reused.
- `fl_vulkan_snapshot` copies a single origin-aligned backing image into an
  immutable, dedicated DMA-BUF buffer on the GPU. Rows are explicitly linear and
  aligned, with DRM ABGR8888 describing RGBA bytes. The source image is restored
  to `GENERAL`. The buffer is released to `VK_QUEUE_FAMILY_FOREIGN_EXT`, and a
  fence completes before GTK can import it. No implicit producer fence is assumed.
- `fl_vulkan_snapshot_pool` retains at most three export allocations per manager,
  including their command pools, command buffers and fences. A slot is reusable
  only after every snapshot/GTK texture lease releases (the
  [GTK texture release contract](https://docs.gtk.org/gdk4/method.DmabufTextureBuilder.build.html))
  and nonblocking
  [DMA-BUF fence polling](https://docs.kernel.org/driver-api/dma-buf.html#implicit-fence-poll-support)
  reports no outstanding implicit readers or writers. Reuse reacquires buffer
  ownership from `VK_QUEUE_FAMILY_FOREIGN_EXT`. Idle allocations of obsolete sizes
  are retired on the raster thread. A busy pool selects readback for that frame
  and retries export later. Final cleanup runs on a GLib worker with its own
  device lease, independently of engine teardown and GTK's release callback.
- `fl_compositor_vulkan` publishes snapshots on the raster thread and imports
  them through the existing GTK 4.14 runtime bindings on the GTK thread. It caches
  the resulting texture. Unsupported exports and multi-layer scenes use readback
  and Cairo composition. Failed GTK imports use host-accessible snapshot memory
  for the same frame, then disable further export attempts for that compositor.
  Resize waits remain bounded; empty frames clear the previous contents.
- `fl_vulkan_device_context` leases the device to snapshot and upload helpers;
  each helper owns its command pool and uses the manager's synchronized submit
  callback. Backing stores, plugin images and GTK textures can independently keep
  the device alive. Exported descriptors stay open until GTK releases its texture.
- `fl_pixel_buffer_texture_vulkan` implements the existing plugin RGBA callback
  using a staging upload to an optimal-tiling sampled image. The upload completes
  in `SHADER_READ_ONLY_OPTIMAL` before returning to the engine. Texture lookup
  retains the plugin under the registrar mutex so concurrent unregister cannot
  invalidate the callback. Engine texture destruction releases the image lease.

DMA-BUF is attempted by default for Vulkan when GTK's runtime supports it;
`FLUTTER_GTK4_ENABLE_DMABUF=0` forces the readback route. This differs from the
OpenGL path, where DMA-BUF is opt-in. Export requires `VK_KHR_external_memory_fd`,
`VK_EXT_external_memory_dma_buf`, `VK_EXT_queue_family_foreign`, exportable buffer
support, and a compatible host-visible/coherent memory type. Device-local memory
is preferred when it also meets those requirements. GTK must accept the linear
ABGR8888 format. Import rejection does not prevent rendering.

The successful route avoids CPU pixel copies and GTK texture upload, but still
performs one GPU image-to-buffer copy and a completion wait. It is not direct
rendering into scanout memory, nor a zero-copy or performance claim. Graphics
offload can consume the DMA-BUF texture when GTK and the compositor accept it;
set `FLUTTER_GTK4_ENABLE_GRAPHICS_OFFLOAD=1` to request that separately.
`FLUTTER_LINUX_GTK_DEBUG=1` reports `event=vulkan-presentation path=dmabuf` or
`path=readback`. EGL export and direct Wayland EGL rendering are independent.

Pixel-buffer plugin textures work with Vulkan. GL-only plugin textures are
rejected at registration; they require OpenGL. A native Vulkan plugin API is not
provided. Platform-view layers are rejected. Allocation pooling, modifier-aware
image export, GPU multi-layer composition, finer completion synchronization,
device-loss recovery and broader multi-window/driver coverage remain follow-up
work. No automatic GLES retry is implemented.

## Tests

Build `flutter_linux_gtk4` and `flutter_linux_gtk4_unittests`. Unit coverage
includes lazy backend selection and rejecting allocation before initialization.
The opt-in integration cases exercise real Vulkan allocations, odd-sized resize,
readback pixels, invalid dimensions, device lifetime, recursive resolver
synchronization, layer offsets/order, empty-frame clearing and GTK texture
lifetime, exported snapshots surviving source reuse/engine teardown, plugin
upload lifetime, and cached texture clearing. Run with either a software ICD or a hardware ICD:

```sh
FLUTTER_TEST_VULKAN=1 \
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json \
GDK_BACKEND=x11 GDK_DISABLE=gl,vulkan GSK_RENDERER=cairo GTK_A11Y=none \
xvfb-run -a dbus-run-session -- \
  engine/src/out/host_debug_unopt/flutter_linux_gtk4_unittests \
  --gtest_filter='FlVulkan*:FlEngineTest.SelectVulkanWithoutInitializingDriver'
```

GTK graphics are disabled here because this unit-test binary mocks EGL. This
does not disable Vulkan in the manager. Without `FLUTTER_TEST_VULKAN=1`, cases
requiring a Vulkan driver skip explicitly. Set `FLUTTER_TEST_VULKAN_DMABUF=1`
to require export support rather than allowing the export case to skip.

For a real GTK4 compute app:

1. Create a fresh GTK4 app and add a path dependency on
   `engine/src/flutter/lib/gpu`, plus `vector_math`.
2. Copy `fixtures/compute_dispatch.dart` into `lib/main.dart`.
3. Copy `out/host_debug_unopt/gen/flutter/lib/ui/fixtures/shaders/test.shaderbundle`
   from the engine source directory to the app and list it in `flutter.assets`.
   The engine shader fixtures build generates this bundle.
4. Include `fixtures/compute_snapshot.h` in the native runner and call
   `watch_compute_snapshot(GTK_WIDGET(view))` after realizing the view.
5. To test pixel-buffer plugins too, include `fixtures/compute_pixel_texture.h`
   and call `install_compute_pixel_texture(view)` after realizing the view.
   The Dart fixture accepts `--pixel-buffer-texture`; the driver forwards it.
6. Build the app with the matching local debug engine, then run:

```sh
python3 engine/src/flutter/shell/platform/linux/testing/run_gtk4_compute_test.py \
  /path/to/bundle/gtk4_compute_probe \
  --engine-dir engine/src/out/host_debug_unopt \
  --flutter-renderer vulkan --dispatch --gtk-snapshot \
  --gsk-renderer cairo --output /tmp/gtk4-compute-vulkan.json
```

Repeat with GTK GL and Vulkan presentation, and hardware and software ICDs.
Xvfb lacks DRI3 and can fall back from Vulkan to GL: that is a failed Vulkan
presentation check, even if compute and pixels pass. Use `--display-backend
wayland` with the correct `WAYLAND_DISPLAY` for an existing Wayland session to
exercise actual `GskVulkanRenderer`. The snapshot runner closes the window on
the driver's quit handshake, requiring a clean exit through engine teardown.
The driver verifies the loaded engine hash, observed Impeller backend, compute
limits, compute-to-render pixels, and a GTK widget snapshot plus its actual
GSK renderer. A zeroed vertex buffer only covers the viewport after the compute
dispatch writes it. The native snapshot independently checks that the image
survived the embedder's backing store and GTK import. The capture uses a
surfaceless instance of the observed renderer class: GTK 4.22.5's window-bound
renderer omits content already assigned to its child surfaces, even when
rendering to a texture. Both renderer classes are recorded and must match.
This capture does not prove compositor scanout; preserve Wayland buffer/child
surface attachment evidence separately when testing graphics offload. Capability detection
alone is not counted as a dispatch test.

Use `--vulkan-presentation dmabuf` to require native import evidence, or
`FLUTTER_GTK4_ENABLE_DMABUF=0` with `--vulkan-presentation readback` to test the
fallback. Add `--pixel-buffer-texture --gtk-snapshot --dispatch` to verify a
red/green/blue/white plugin pattern after compute succeeds; asymmetric samples
catch flips and channel swaps. Run GL and Vulkan GTK presentation separately.

Retain reports, logs, hashes and screenshots in the sibling plans repository
under `gtk4/test-results/`; keep generated evidence out of the Flutter source
repository. Performance benchmarking and the memory comparison remain separate.

## Frame pacing follow-up

GTK frame-clock scheduling now returns Flutter vsync batons on the GTK main
context. Requests already on that dispatch thread arm the tick immediately;
worker requests are marshalled even if the worker can acquire the GLib context.
This avoids an unnecessary main-loop turn without running GTK on engine workers.
For the primary view, frame start and refresh interval come from its
`GdkFrameClock`; an unmapped view uses a 16 ms timer. Multiwindow engines still
need per-view clock selection, and runtime refresh-rate changes need focused
coverage. Refresh intervals and candidate targets come from completed frame-clock
history (`gdk_frame_clock_get_refresh_info`), since the current frame's timing
can still be incomplete during UPDATE. Missing/stale predictions use the
reported refresh interval, or a conservative 60 Hz fallback. Pure timing tests
cover 60/120/144 Hz, unit conversion and strictly future targets. GDK's predicted
target is a scheduling hint, not measured compositor presentation.

A delivered tick callback remains registered for one extra tick so a
following animation request can overlap it. This keeps GTK updating continuously
instead of ending and restarting its animation-clock phase for every Flutter
frame. With no following request, it removes itself after that idle tick;
unmapping removes it immediately without delivering the baton again. Mapped
GTK4 regression tests cover continuity, idle removal and both unmap cases.
A mapped request also has a progress guard: after four refresh intervals (at
least 20 ms) without a tick, remove the callback and return its baton using the
conservative wall-time fallback. Normal delivery or unmapping cancels the guard.
It is armed only for pending requests, not a permanent timer. This handles
first-frame and occluded/frozen-clock stalls without claiming a presentation.

Before presenting Vulkan backing images, the embedder submits an empty marker
submission to Impeller's graphics queue and waits for its fence. This preserves
host completion for Vulkan compositor clients while avoiding a device-wide idle
that also waits unrelated queues. If fence creation or submission fails, it falls
back to the device idle path. GTK's snapshot/readback fence still completes the
subsequent copy before source-image reuse.

Measure actual compositor presentation feedback alongside Flutter's engine
timings before changing publication synchronization. A high raster-finish FPS
can include frames superseded before presentation. Verify clock continuity
with optimized-engine, repeated comparisons at equal actual render area and
report CPU/GPU activity, memory and measurement overhead. An asynchronous
bounded in-flight snapshot queue remains a separate experiment requiring an
explicit producer-completion and ownership contract. Snapshot export allocations are pooled;
plugin upload/readback and the embedder marker fence remain separate reuse
opportunities. Benchmark
frame intervals and missed deadlines, including p95/p99, alongside CPU/GPU time
and memory; cover multiple windows, refresh rates and resize. A GTK texture
capture does not prove compositor presentation.

The queue synchronization tests use blocked fake driver calls to verify both
cross-device progress and same-device exclusion without a GPU. An engine test
checks that vsync batons return on the GTK main context. Real-driver tests cover
pixels and image lifetime. The frame-fence benchmark compares GTK3 OpenGL,
GTK4 OpenGL and GTK4 Vulkan under the same Wayland session; its reports live in
the sibling plans repository. These are engine/compositor timing samples, not
input-to-photon or scanout measurements.

## Upstream work

At local base `37a63dc716e`, the Vulkan branch of
`CreateEmbedderRenderTarget` in `embedder.cc` logs `Unimplemented` when Impeller
is enabled. A minimal reproduction supplies a Vulkan renderer configuration and
a compositor returning a valid Vulkan image, then requests a frame: the embedder
fails to construct the target. The expected behavior is rendering into the
compositor image and completing GPU work before handing it to the embedder.
Without compositor support, the GTK4 integration cannot use its normal multiview
backing-store contract. The prior local workaround was to keep Impeller GLES,
which has no Flutter GPU compute support.

An upstream issue/PR search for `Impeller Vulkan compositor` on 2026-10-27 found
no equivalent result. File an upstream issue with the reproduction and focused
adapter/synchronization fix before treating this as a permanent local patch.
The new target adapter and host-completion change should
be reviewed as a focused embedder contribution independently of GTK4 integration,
with dedicated upstream embedder tests before submission. No upstream issue or
PR was filed by this work. The GTK4 dispatch fixture supplies local end-to-end
coverage; it is not a replacement for those upstream tests.

### GTK offload capture investigation

With GTK 4.22.5, an offloaded widget captured through its window's renderer
produced transparent pixels with both GSK GL and Vulkan, while the same imported
texture without offload rendered correctly. The source of
[`gsk_gpu_node_processor_add_subsurface_node`](https://github.com/GNOME/gtk/blob/4.22.5/gsk/gpu/gskgpunodeprocessor.c)
skips a child assigned to that renderer's surface. Reproduction: put an imported
DMA-BUF texture in `GtkGraphicsOffload`, wait for offload, then capture its
`GtkWidgetPaintable` node using `gsk_renderer_render_texture` on the window's
renderer. Expected capture: the texture; observed: transparent pixels. Capturing
with a surfaceless renderer of the same class preserves the scene and pixels.
This workaround is confined to the test fixture. An upstream search on
2026-10-28 found no equivalent report/fix; recommend reporting this minimal GTK
capture case. No GTK issue was filed and no GTK runtime patch is carried.

## Snapshot resource reuse diagnostics

With `FLUTTER_LINUX_GTK_DEBUG=1`, `vulkan-snapshot-pool` logs allocation counts
and a final summary of allocations, reuse and pool exhaustion. Trace events
`VulkanSnapshotAllocate`, `VulkanSnapshotCopy` and `VulkanSnapshotFenceWait`
separate allocation/copy work from the retained host completion wait. Pooling
removes repeated resource creation; it does not remove the GPU copy or make
publication asynchronous.

For pacing investigations, the Embedder timeline stream also contains
`VulkanGraphicsCompletion` (marker fence creation, submission and host wait),
`VulkanGraphicsFenceWait` (the wait itself), `VulkanPresentLayers` (snapshot or
readback publication), and `VulkanAcquireTexture` (GTK-side frame acquisition
and texture import). `VulkanAcquireFrameWait` identifies size-dependent frame
waiting within acquisition. These are CPU-side scopes, not GPU timestamps;
parent and child durations overlap and must not be added. Collect through the
Dart VM service in a diagnostic run and verify the timeline buffer covers the
measured frame window. Keep tracing disabled for primary throughput comparisons.
Engine raster completion and these scopes do not establish compositor scanout;
use actual presentation feedback separately.

`FlVulkanSnapshotPoolTest` uses a driver stand-in to check steady-state resource
counts, retained leases, pool exhaustion/recovery, unready DMA-BUFs, resize,
failed completion and cleanup outside the texture-release callback. The real
DMA-BUF integration test repeatedly reuses one allocation and checks that new
blue pixels and retained red fallback pixels remain correct. Hardware exports
can be made mandatory with `FLUTTER_TEST_VULKAN_DMABUF=1`.


## Vsync and publication trace correlation

The optional Embedder timeline stream includes `LinuxVsyncRequest`,
`LinuxVsyncTick` (with GTK frame counter), `LinuxVsyncTiming` (start/target in
nanoseconds), `LinuxVsyncRefresh` (history interval), `LinuxVsyncDeliver`, and
`LinuxVsyncClockTimeout`. Request/tick/
delivery batons correlate across engine and GTK threads. `GTK4UpdateTexture`
and `GTK4Snapshot` show the later texture publication and GTK snapshot phases.
Match these with actual `wp_presentation` feedback in a diagnostic run; neither
an engine callback, GTK tick nor snapshot proves a physical presentation.
Tracing remains disabled for primary throughput comparisons.

The history query and stalled-clock guard follow techniques explored in
[the Linux Vulkan pacing work](https://github.com/ales-drnz/flutter/blob/impeller-vulkan-linux/engine/src/flutter/shell/platform/linux/fl_vsync_waiter.cc).
[The shared VSync cleanup](https://github.com/flutter/flutter/pull/191444),
already present in this branch, also motivates avoiding redundant event-loop
turns on the platform thread. GTK/GSK owns commits and offloaded child surfaces
in this presentation path. Committing its parent surface independently or
changing its child synchronization mode requires a separate integration design;
it is not equivalent to pacing an embedder-owned Vulkan swapchain surface.
