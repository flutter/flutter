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
  share a lock, including across multiple engines. Device feature enablement
  matches the Impeller capability chain for the advertised extensions.
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
