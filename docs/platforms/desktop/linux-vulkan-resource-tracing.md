# Linux Vulkan resource tracing

Use the engine timeline to distinguish backing-store reuse, Impeller attachment
creation, and GTK presentation resources. These have separate lifetimes: a GTK
snapshot export can be replaced while the engine continues rendering into a
cached backing store and its existing attachments.

## Capture

With a debug or profile engine, record a Flutter DevTools performance timeline
that includes engine events. For an embedder-controlled capture, pass
`--trace-startup` and `--trace-to-file=/absolute/path/vulkan-resources.pftrace`
in `FlutterProjectArgs.command_line_argv`, then shut down the engine normally to
flush the recording. Open the resulting protobuf trace in Perfetto. These are
engine arguments; a runner must forward them to the engine.

Record startup, a sustained fixed-size interval, a resize, and shutdown. Keep
captures short because startup tracing enables a broad set of timeline streams.

## Events

| Event | Meaning |
| --- | --- |
| `EmbedderRenderTargetCacheLookup` | `hit=true` means a compatible backing store was reused; `false` means the embedder needs to supply one. Applies to all compositor backends. |
| `CreateVulkanImpellerRenderTarget` | Vulkan target wrapping attempt, with requested `width` and `height`. Failed attempts are included. |
| `SwapchainTransientsVK::GetMSAATexture` | `cache_hit` distinguishes reuse of an existing MSAA attachment from an allocation attempt. |
| `SwapchainTransientsVK::GetDepthStencilTexture` | The equivalent lookup for the depth/stencil attachment. |
| `CreateMSAATexture`, `CreateDepthStencilTexture` | Time spent attempting to create the corresponding transient texture. |
| `VulkanTransientAttachmentAllocated` | One successfully created transient texture; `kind` is `msaa` or `depth_stencil`. This is a texture allocation count, not a device-memory allocation or byte count. |

The attachment events also cover Vulkan root surfaces and swapchains. Filter by
thread and time interval and correlate them with target creation when attributing
allocations to an embedder compositor. A hit in the backing-store cache normally
bypasses target creation and both attachment lookups entirely.

GTK4 uses the compositor's backing-store cache by default. With one fixed-size
layer, expect initial target and attachment creation followed by cache hits.
Resize or additional layers can require more targets. Embedders that set
`FlutterCompositor.avoid_backing_store_cache` deliberately recreate their backing
stores. Compare that case separately from the default GTK4 path.

These events do not measure GTK DMA-BUF snapshot allocations, GPU utilization,
physical memory consumption, or presentation latency. Pair allocation counts
with the corresponding presentation, CPU, GPU, and memory measurements before
claiming a performance improvement. Use an untraced run for throughput comparisons.

## Regression coverage

After building `embedder_unittests`, run:

```sh
engine/src/out/host_debug_unopt/embedder_unittests \
  --gtest_filter='VulkanImpellerRenderTargetTest.*:VulkanCompositor/*' \
  --gtest_output=json:/tmp/vulkan-resources-tests.json
```

The tests cover callback ownership on rejected targets, target/context lifetime,
cache eviction, 60 fixed-size rendered frames with caching enabled and disabled,
resize, and engine shutdown. They use SwiftShader and record backing-store counts
as JSON test properties. Their runtime is not a hardware performance benchmark.
