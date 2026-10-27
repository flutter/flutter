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
  queue, allocates optimal-tiling RGBA8 backing images, and performs readback.
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
- `fl_compositor_vulkan` snapshots each layer on the raster thread, composes
  layers in order at their offsets, then hands immutable bytes to GTK. Resize
  waits are bounded. An empty frame clears the previous contents. The GTK thread
  creates `GdkMemoryTexture` without creating a Flutter GL context or flipping Y.
- Outstanding backing images retain the device state. GTK textures retain
  immutable host bytes, independently of engine backing-store collection and
  device teardown. Engine shutdown precedes releasing the manager.

This first implementation uses a GPU transfer to host memory, explicit RGBA to
native ARGB conversion, CPU layer composition, and GTK texture upload. It is a
correctness baseline for compute, not an optimized presentation implementation.
Vulkan DMA-BUF export, native synchronization handoff, allocation pooling and
GPU composition need separate design and performance validation. The existing
EGL export path and Wayland EGL subsurface renderer do not apply. A
`GtkGraphicsOffload` wrapper does not make memory textures offloadable.

GL and pixel-buffer plugin textures are explicitly rejected. Native Vulkan
plugin texture support is not implemented. Platform-view layers are rejected;
multi-window lifecycle, broad driver coverage and device-loss recovery need
additional integration validation. No automatic GLES retry is implemented.

## Tests

Build `flutter_linux_gtk4` and `flutter_linux_gtk4_unittests`. Unit coverage
includes lazy backend selection and rejecting allocation before initialization.
The opt-in integration cases exercise real Vulkan allocations, odd-sized resize,
readback pixels, invalid dimensions, device lifetime, recursive resolver
synchronization, layer offsets/order, empty-frame clearing and GTK texture
lifetime. Run with either a software ICD or a hardware ICD:

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
requiring a Vulkan driver skip explicitly.

For a real GTK4 compute app:

1. Create a fresh GTK4 app and add a path dependency on
   `engine/src/flutter/lib/gpu`, plus `vector_math`.
2. Copy `fixtures/compute_dispatch.dart` into `lib/main.dart`.
3. Copy `out/host_debug_unopt/gen/flutter/lib/ui/fixtures/shaders/test.shaderbundle`
   from the engine source directory to the app and list it in `flutter.assets`.
   The engine shader fixtures build generates this bundle.
4. Include `fixtures/compute_snapshot.h` in the native runner and call
   `watch_compute_snapshot(GTK_WIDGET(view))` after realizing the view.
5. Build the app with the matching local debug engine, then run:

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
survived the embedder's backing store and GTK presentation. Capability detection
alone is not counted as a dispatch test.

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
