# GTK4 rendering backlog

## Evaluate GtkGraphicsOffload for Flutter DMA-BUF content

Status: opt-in implementation added; correctness and hardware handoff checked.
Measure benefit and broaden coverage before enabling by default. See
[implementation and validation](testing/GRAPHICS_OFFLOAD.md).

Investigate wrapping the Flutter texture widget in `GtkGraphicsOffload` so GTK
can hand suitable DMA-BUF content to the Wayland compositor without a GSK
composition pass. This is a GTK-managed optimization of the current widget path;
it does not require adopting Flutter's separate subsurface renderer.

- Implemented: optional GTK 4.14+ runtime type discovery and a dedicated
  presentation wrapper, preserving older GTK builds and texture fallbacks.
  The flag also requests DMA-BUF export unless explicitly overridden.
- Confirm which DMA-BUF formats/modifiers, alpha/opacity, clipping, transforms,
  scales and compositor capabilities permit offload. Exercise both ordinary
  windows and fullscreen; direct scanout is a separate compositor decision.
- Preserve buffer ownership, release and synchronization across raster/GTK
  threads. Verify resize, monitor moves, fractional scaling, overlays, input,
  accessibility and fallback transitions without stale frames or flashes.
- Measure the existing framebuffer-to-export-snapshot GPU blit separately.
  DMA-BUF sharing does not prove zero-copy, and graphics offload does not remove
  that blit automatically. Explore rendering into exportable buffers as a
  separate optimization with independent lifetime/synchronization tests.
- Record **observed** offload using GTK diagnostics (`GDK_DEBUG=offload,dmabuf`)
  and compositor evidence. Distinguish requested mode, accepted GTK offload and
  actual direct scanout; never infer success from an environment variable.
- Benchmark enabled/disabled with equal pixel workloads: per-thread/process CPU,
  app and compositor GPU activity, copies/readbacks, fence waits, throughput,
  frame pacing and actual presentation timing where available. Include multiple
  real apps and supported GSK renderer modes; retain raw samples/provenance.

Acceptance: demonstrate correctness and repeatable benefit on supported hardware,
with an explicit fallback when offload is unavailable. Do not claim that offload
alone enables Flutter GPU compute: the current Impeller GLES backend still lacks
its compute implementation. A future Vulkan renderer can reuse the image-handoff
strategy but needs Vulkan-specific allocation/export/synchronization.

References:
[GtkGraphicsOffload API](https://gnome.pages.gitlab.gnome.org/gtk/gtk4/class.GraphicsOffload.html),
[GTK graphics offload discussion](https://blogs.gnome.org/gtk/2024/04/17/graphics-offload-revisited/),
and [local compute investigation](testing/COMPUTE.md).
