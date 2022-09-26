// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/surface_vk.h"

#include "impeller/renderer/backend/vulkan/texture_vk.h"
#include "impeller/renderer/surface.h"

namespace impeller {
std::unique_ptr<SurfaceVK> SurfaceVK::WrapSwapchainImage(
    uint32_t frame_num,
    SwapchainImageVK* swapchain_image,
    ContextVK* context,
    SwapCallback swap_callback) {
  if (!swapchain_image) {
    return nullptr;
  }

  TextureDescriptor color0_tex;
  color0_tex.type = TextureType::kTexture2D;
  color0_tex.format = swapchain_image->GetPixelFormat();
  color0_tex.size = swapchain_image->GetSize();
  color0_tex.usage = static_cast<TextureUsageMask>(TextureUsage::kRenderTarget);
  color0_tex.sample_count = SampleCount::kCount1;
  color0_tex.storage_mode = StorageMode::kDevicePrivate;

  ColorAttachment color0;
  auto color_texture_info = std::make_unique<TextureInfoVK>(TextureInfoVK{
      .backing_type = TextureBackingTypeVK::kWrappedTexture,
      .wrapped_texture =
          {
              .swapchain_image = swapchain_image,
              .frame_num = frame_num,
          },
  });
  color0.texture = std::make_shared<TextureVK>(std::move(color0_tex), context,
                                               std::move(color_texture_info));
  color0.clear_color = Color::DarkSlateGray();
  color0.load_action = LoadAction::kClear;
  color0.store_action = StoreAction::kDontCare;

  TextureDescriptor stencil0_tex;
  stencil0_tex.type = TextureType::kTexture2D;
  stencil0_tex.format = swapchain_image->GetPixelFormat();
  stencil0_tex.size = swapchain_image->GetSize();
  stencil0_tex.usage =
      static_cast<TextureUsageMask>(TextureUsage::kRenderTarget);
  stencil0_tex.sample_count = SampleCount::kCount1;

  StencilAttachment stencil0;
  stencil0.clear_stencil = 0;
  auto stencil_texture_info = std::make_unique<TextureInfoVK>(TextureInfoVK{
      .backing_type = TextureBackingTypeVK::kWrappedTexture,
      .wrapped_texture =
          {
              .swapchain_image = swapchain_image,
              .frame_num = frame_num,
          },
  });
  stencil0.texture = std::make_shared<TextureVK>(
      std::move(stencil0_tex), context, std::move(stencil_texture_info));
  stencil0.load_action = LoadAction::kClear;
  stencil0.store_action = StoreAction::kDontCare;

  RenderTarget render_target_desc;
  render_target_desc.SetColorAttachment(color0, 0u);

  return std::unique_ptr<SurfaceVK>(new SurfaceVK(std::move(render_target_desc),
                                                  swapchain_image,
                                                  std::move(swap_callback)));
}

SurfaceVK::SurfaceVK(RenderTarget target,
                     SwapchainImageVK* swapchain_image,
                     SwapCallback swap_callback)
    : Surface(target) {
  swap_callback_ = std::move(swap_callback);
}

SurfaceVK::~SurfaceVK() = default;

bool SurfaceVK::Present() const {
  return swap_callback_ ? swap_callback_() : false;
}

}  // namespace impeller
