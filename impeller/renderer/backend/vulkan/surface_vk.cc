// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/surface_vk.h"

#include "impeller/renderer/backend/vulkan/swapchain_image_vk.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"
#include "impeller/renderer/surface.h"

namespace impeller {

std::unique_ptr<SurfaceVK> SurfaceVK::WrapSwapchainImage(
    const std::shared_ptr<Context>& context,
    const std::shared_ptr<SwapchainImageVK>& swapchain_image,
    SwapCallback swap_callback) {
  if (!context || !swapchain_image || !swap_callback) {
    return nullptr;
  }

  TextureDescriptor msaa_tex_desc;
  msaa_tex_desc.storage_mode = StorageMode::kDeviceTransient;
  msaa_tex_desc.type = TextureType::kTexture2DMultisample;
  msaa_tex_desc.sample_count = SampleCount::kCount4;
  msaa_tex_desc.format = swapchain_image->GetPixelFormat();
  msaa_tex_desc.size = swapchain_image->GetSize();
  msaa_tex_desc.usage = static_cast<uint64_t>(TextureUsage::kRenderTarget);

  auto msaa_tex = context->GetResourceAllocator()->CreateTexture(msaa_tex_desc);
  if (!msaa_tex) {
    VALIDATION_LOG << "Could not allocate MSAA color texture.";
    return nullptr;
  }
  msaa_tex->SetLabel("ImpellerOnscreenColorMSAA");

  TextureDescriptor resolve_tex_desc;
  resolve_tex_desc.type = TextureType::kTexture2D;
  resolve_tex_desc.format = swapchain_image->GetPixelFormat();
  resolve_tex_desc.size = swapchain_image->GetSize();
  resolve_tex_desc.usage =
      static_cast<TextureUsageMask>(TextureUsage::kRenderTarget);
  resolve_tex_desc.sample_count = SampleCount::kCount1;
  resolve_tex_desc.storage_mode = StorageMode::kDevicePrivate;

  std::shared_ptr<Texture> resolve_tex =
      std::make_shared<TextureVK>(context,         //
                                  swapchain_image  //
      );

  if (!resolve_tex) {
    VALIDATION_LOG << "Could not wrap resolve texture.";
    return nullptr;
  }
  resolve_tex->SetLabel("ImpellerOnscreenResolve");

  ColorAttachment color0;
  color0.texture = msaa_tex;
  color0.clear_color = Color::DarkSlateGray();
  color0.load_action = LoadAction::kClear;
  color0.store_action = StoreAction::kMultisampleResolve;
  color0.resolve_texture = resolve_tex;

  RenderTarget render_target_desc;
  render_target_desc.SetColorAttachment(color0, 0u);

  // The constructor is private. So make_unique may not be used.
  return std::unique_ptr<SurfaceVK>(
      new SurfaceVK(render_target_desc, std::move(swap_callback)));
}

SurfaceVK::SurfaceVK(const RenderTarget& target, SwapCallback swap_callback)
    : Surface(target), swap_callback_(std::move(swap_callback)) {}

SurfaceVK::~SurfaceVK() = default;

bool SurfaceVK::Present() const {
  return swap_callback_ ? swap_callback_() : false;
}

}  // namespace impeller
