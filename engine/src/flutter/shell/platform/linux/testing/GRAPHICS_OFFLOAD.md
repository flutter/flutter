# GTK4 graphics offload

Graphics offload is an experimental, opt-in presentation hint:

```sh
FLUTTER_GTK4_ENABLE_GRAPHICS_OFFLOAD=1 ./your_flutter_app
```

`fl_graphics_offload_gtk4` owns the request policy and presentation wrapper.
`FlView` only parents the returned widget. Rendering, input controllers and
accessibility remain on the existing render widget; the wrapper has the
presentation accessibility role and no label. The shared runtime API table
resolves the optional GTK type getter dynamically. GTK3 is unaffected.

GTK 4.14 or newer is required for the wrapper. On an older runtime or a missing
symbol, the original widget hierarchy is retained. GTK decides whether each
scene can be offloaded and renders normally when it cannot. Clipping, overlays,
texture formats, transforms, alpha and compositor support can affect acceptance.
The implementation preserves transparency; it does not force an opaque backing.

Requesting offload also requests the existing DMA-BUF export path, unless
`FLUTTER_GTK4_ENABLE_DMABUF` is explicitly set. Set it to `0` to exercise texture
fallback. Export failures retain the existing GL texture/readback fallbacks.
Use the texture presentation path when testing this feature; the independent
`FLUTTER_GTK4_ENABLE_SUBSURFACE` path bypasses it.

This does not change Impeller's rendering backend or enable compute shaders.
Export currently includes a framebuffer snapshot GPU blit. Accepted GTK offload
and compositor direct scanout are separate decisions; neither implies zero-copy
rendering or a measured performance improvement.

## Validation

Build `flutter_linux_gtk4` and `flutter_linux_gtk4_unittests`. The
`FlGraphicsOffloadGtk4Test` suite covers explicit opt-in, old runtimes/missing
symbols, hierarchy, sizing, child lifetime and accessibility role. Run the full
suite with the flag enabled to exercise existing accessibility/input tests
through the wrapper. The artificial surface lifecycle test preserves the whole
presentation subtree when reparenting it.

The Wayland scale and render-scale drivers accept `--graphics-offload`:

```sh
python3 engine/src/flutter/shell/platform/linux/testing/run_gtk4_wayland_scale_test.py --help
python3 engine/src/flutter/shell/platform/linux/testing/run_gtk4_wayland_render_scale_test.py --help
```

Those drivers check resize/scaling and engine pixel readback respectively. They
do not prove that GTK accepted offload or validate the final compositor image.
The runtime compatibility validator also checks that the library does not
hard-import the optional type getter and runs the offload unit suite.

For actual acceptance evidence, run a visible, animated fixture on Wayland:

```sh
GDK_BACKEND=wayland GSK_RENDERER=gl GDK_DEBUG=offload,dmabuf \
WAYLAND_DEBUG=client FLUTTER_GTK4_ENABLE_GRAPHICS_OFFLOAD=1 \
FLUTTER_GTK4_ENABLE_SUBSURFACE=0 ./your_flutter_app 2>offload.log
```

Repeat with `GSK_RENDERER=vulkan`. Correlate the child surface ID from
`wl_subcompositor.get_subsurface` with subsequent non-null
`wl_surface.attach(wl_buffer, ...)` calls. Creating the child surface alone is
insufficient. Keep the fixture visible: an occluded or idle window may provide
no useful frame handoff evidence. Retain diagnostics, versions and scene details.
Benchmark separately with equal viewport/workload and offload enabled/disabled.

[GTK API documentation](https://docs.gtk.org/gtk4/class.GraphicsOffload.html)
describes the presentation hint. Remaining performance and direct-scanout work
is tracked in [the rendering backlog](../GTK4_BACKLOG.md).
