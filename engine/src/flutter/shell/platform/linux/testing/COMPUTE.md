# Flutter GPU compute on the GTK4 embedder

Investigated at `655f44114e4` with Flutter GPU compute PR
[#193805](https://github.com/flutter/flutter/pull/193805) (`a3a21c83724`) included.

GTK4 now has an experimental opt-in Impeller Vulkan backend selected with
`FLUTTER_LINUX_RENDERER=vulkan`. Enable Flutter GPU as well to use compute.
The default remains OpenGL ES; `GSK_RENDERER=vulkan` alone changes GTK
presentation and does not enable compute. The Vulkan path can present via DMA-BUF with a readback fallback. Functional
compute and native presentation support do not by themselves prove better
rendering performance. See [Vulkan setup and tests](VULKAN.md).

The capability-only probe below remains useful for the GLES regression. For an
actual dispatch, use `fixtures/compute_dispatch.dart`, include the engine's
`test.shaderbundle` as an app asset, and run the driver with
`--flutter-renderer vulkan --dispatch`. Add the native `compute_snapshot.h`
runner helper and `--gtk-snapshot` to verify GTK widget pixels as well.

The remaining investigation records the earlier GLES-only implementation at
`655f44114e4`; its Vulkan integration gaps are addressed by the new opt-in path,
with the limitations documented in `VULKAN.md`.

## Reproduction and evidence

Create a fresh GTK4 app (recreating over an existing GTK3 runner does not replace
its files), add a path dependency on this checkout's `engine/src/flutter/lib/gpu`,
and copy `fixtures/compute_capabilities.dart` into its `lib/main.dart`:

```sh
bin/flutter create --platforms=linux --linux-gtk=gtk4 \
  --project-name gtk4_compute_probe /tmp/flutter_gtk4_compute_probe
```

Build with the local debug engine, then run:

```sh
python3 engine/src/flutter/shell/platform/linux/testing/run_gtk4_compute_test.py \
  /tmp/flutter_gtk4_compute_probe/build/linux-gtk4/x64/debug/bundle/gtk4_compute_probe \
  --engine-dir engine/src/out/host_debug_unopt \
  --gsk-renderer gl --output /tmp/gtk4-compute-gl.json
```

Repeat with `--gsk-renderer vulkan`. The driver enables Impeller and Flutter GPU,
checks the mapped GTK4 engine library hash, verifies GTK4 was loaded, and checks
the observed Impeller backend. GSK is a **request**, not confirmation of GTK's
selected renderer. Both requests produced these results in the investigation:

- Impeller backend: `OpenGLESSDF`.
- `gpuContext.supportsCompute`: false.
- All exposed compute limits: zero.
- `createComputePass()`: throws `UnsupportedError`.

This is a successful capability-gating regression, not a compute dispatch test.

Separate Vulkan tests demonstrate that the implementation below the embedder is
working: all 18 `Compute/ComputeTest.*/Vulkan` tests passed, and the full Dart
`gpu_test.dart` suite on Vulkan passed 135 tests with two skips. These runs used
Lavapipe (CPU software Vulkan), so they establish correctness, not hardware GPU
offload or rendering performance. No GTK integration is exercised by those
Vulkan tests.

## Original GLES limitation

The gate in `lib/gpu/context.cc::SupportsCompute` intentionally accepts only
Metal and Vulkan. Removing that gate would expose incomplete GLES functionality:

- `CommandBufferGLES::OnCreateComputePass()` returns null.
- `PipelineLibraryGLES::GetPipeline(ComputePipelineDescriptor, ...)` returns a
  null pipeline.
- `CapabilitiesGLES::SupportsCompute()` returns false.
- GLES needs GPU-written storage-buffer handling, dispatch, barriers, readback,
  and GPU-completion semantics; CPU shadow copies cannot stand in for GPU writes.
- The Linux OpenGL manager currently requests EGL client version 2. Raising the
  context request alone does not implement the missing Impeller functionality.

The comment mentioning GLES 3.2 in `OnCreateComputePass` is stale: compute is
core in GLES **3.1**. The upstream
[compute roadmap #188474](https://github.com/flutter/flutter/issues/188474)
records both that correction and the remaining GLES work. Its Wave 3 explicitly
includes Linux context negotiation. This is an existing upstream feature gap,
not a GTK4-only defect.

## Routes considered before Vulkan integration

### GLES compute, aligned with upstream Wave 3

Keep the existing GTK4 image handoff. Negotiate GLES 3.1 where available, query
compute limits, implement compute program linking/dispatch and storage bindings,
ensure writes are visible to later passes/readbacks, and signal completion only
when the GPU finishes. The capability gate must remain false until the entire
Flutter GPU contract is supported. Test compute-to-render, dependent dispatches,
readbacks, pass ordering, shader reload, and unsupported-device fallbacks.

This route preserves the current rendering architecture, but is substantial
backend work rather than an embedder switch.

### Opt-in Vulkan rendering in the GTK4 embedder

The engine already has `EmbedderSurfaceVulkanImpeller` and
`FlutterVulkanRendererConfig`. At the investigation base, Linux's
`fl_engine_start` rejected `kVulkan` and only configured software and OpenGL.
The integration work identified was:

1. A device/queue manager and thread-safe queue access, including enabled
   extensions and physical-device compatibility.
2. Vulkan backing-store image allocation and the matching compositor callbacks.
   Linux's current GL backing-store implementation cannot consume Vulkan images.
3. A GTK4 texture handoff, ownership and synchronization strategy. DMA-BUF export
   and GTK import are candidates, using the existing runtime capability checks.
   GTK's public Vulkan context API does not expose its device/queue as a ready
   replacement for an embedder-owned Vulkan device.
4. Resize, scale, multiview, texture/plugin compatibility, GPU/device failure,
   image lifetime and GLES fallback coverage.

A CPU readback into a `GdkMemoryTexture` could establish an early correctness
prototype, but must not be mistaken for a performant production image handoff.
The embedder Vulkan API also documents host synchronization at handoff; account
for this in pacing measurements rather than assuming Vulkan means zero stalls.

The existing desktop Vulkan [design #183495](https://github.com/flutter/flutter/issues/183495)
and closed [PR #183382](https://github.com/flutter/flutter/pull/183382) contain
relevant design/implementation material. That large closed PR is not an
upstream fix to blindly cherry-pick.

For a GTK4-focused prototype, the Vulkan route reuses the compute backend that
already passes tests. Keep it opt-in, preserve GLES as the baseline, and first
prove a compute dispatch writes vertices or pixels which appear in the GTK4
window. Then compare CPU, GPU activity, copies, synchronization and frame pacing
before making any performance or default-selection claim.

## Avoid an independent context override

`flutter::gpu::Context::SetOverrideContext` exists for renderer tests. It is not
a public Dart context-selection API. Forcing a Vulkan Flutter GPU context while
the UI renderer remains GLES does not provide cross-backend sharing for textures,
images or vertex buffers. It would require a separate explicit transfer/interoperability
contract and is not a shortcut to integrating this feature.
