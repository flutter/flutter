// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_render_target_vulkan_impeller.h"

#include "flutter/fml/trace_event.h"
#include "impeller/display_list/aiks_context.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/swapchain/surface_vk.h"
#include "impeller/renderer/backend/vulkan/texture_wrapper_vk.h"

namespace flutter {

std::unique_ptr<EmbedderRenderTarget> CreateVulkanImpellerRenderTarget(
    FlutterBackingStore backing_store,
    const FlutterBackingStoreConfig& config,
    const std::shared_ptr<impeller::AiksContext>& aiks_context,
    fml::ScopedCleanupClosure on_release) {
  FML_TRACE_EVENT("flutter", "CreateVulkanImpellerRenderTarget", "width",
                  config.size.width, "height", config.size.height);
  const auto& store = backing_store.vulkan;
  // The embedder has transferred its baton even if wrapping fails. Destroy it
  // before collecting the backing store, just as on successful target teardown.
  fml::ScopedCleanupClosure destruction(
      [callback = store.destruction_callback, user_data = store.user_data] {
        if (callback) {
          callback(user_data);
        }
      });
  if (!aiks_context || !store.image || !store.image->image) {
    FML_LOG(ERROR) << "Embedder supplied null Vulkan backing image.";
    return nullptr;
  }
  auto format = impeller::VkFormatToImpellerFormat(
      static_cast<impeller::vk::Format>(store.image->format));
  if (!format) {
    FML_LOG(ERROR) << "Unsupported Vulkan backing image format.";
    return nullptr;
  }
  const auto& context = aiks_context->GetContext();
  impeller::TextureDescriptor descriptor;
  descriptor.format = *format;
  descriptor.size = impeller::ISize(config.size.width, config.size.height);
  descriptor.storage_mode = impeller::StorageMode::kDevicePrivate;
  descriptor.usage = impeller::TextureUsage::kRenderTarget;
  auto source = impeller::WrapTextureSourceVK(
      context, descriptor,
      impeller::vk::Image(reinterpret_cast<VkImage>(store.image->image)));
  if (!source) {
    return nullptr;
  }
  auto transients = std::make_shared<impeller::SwapchainTransientsVK>(
      context, descriptor, /*enable_msaa=*/true);
  auto surface = impeller::SurfaceVK::WrapSwapchainImage(transients, source,
                                                         [] { return true; });
  if (!surface) {
    return nullptr;
  }
  // The wrapped source is a presentation attachment: render passes leave its
  // image in GENERAL. The embedder must preserve that layout when reusing it.
  // Ownership stays with the embedder until the target's collection callback.
  return std::make_unique<EmbedderRenderTargetImpeller>(
      backing_store, aiks_context,
      std::make_unique<impeller::RenderTarget>(surface->GetRenderTarget()),
      on_release.Release(), destruction.Release());
}

}  // namespace flutter
