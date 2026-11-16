### Title
[Impeller] `SurfaceVK::WrapSwapchainImage` does not check for null MSAA or depth-stencil transient textures

### Problem
In `engine/src/flutter/impeller/renderer/backend/vulkan/swapchain/surface_vk.cc`, `SurfaceVK::WrapSwapchainImage` assigns `transients->GetMSAATexture()` to `color0.texture` without checking whether `GetMSAATexture()` returned `nullptr`:

```cpp
  if (enable_msaa) {
    color0.texture = transients->GetMSAATexture();
    color0.store_action = StoreAction::kMultisampleResolve;
    color0.resolve_texture = resolve_tex;
  }
```

If `SwapchainTransientsVK` fails to allocate the 4x MSAA color texture (for example, due to out-of-memory conditions or an embedder-requested size exceeding `maxImageDimension2D` / zero size), `color0.texture` is `nullptr`. `RenderTarget::SetColorAttachment` silently ignores a null texture (`render_target.cc`), so `SurfaceVK::WrapSwapchainImage` still returns a non-null `SurfaceVK` whose `color0` attachment is missing. Subsequent rendering (such as `Canvas::SetupRenderPass` calling `color0.texture->GetSize()`) will dereference `nullptr`.

By contrast, the Metal embedder path in `engine/src/flutter/shell/platform/embedder/embedder.cc` explicitly checks `if (!msaa_tex) { return nullptr; }`.

### Context
Identified during review of the Impeller Vulkan embedder backing store work (related to `flutter/flutter#187525`). Because `SurfaceVK::WrapSwapchainImage` is shared between `GPUSurfaceVulkanImpeller` and `CreateEmbedderRenderTarget`, this pre-existing gap affects both root surfaces and embedder backing stores (and is easier to hit with embedder-supplied dimensions).

### Suggested Fix
- Check that `transients->GetMSAATexture()` (when `enable_msaa` is true) and `transients->GetDepthStencilTexture()` are non-null in `SurfaceVK::WrapSwapchainImage`, returning `nullptr` if allocation failed.
- Add a unit test covering failed transient allocation (e.g., oversized dimensions or null transients).
