// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/surface_vk.h"

namespace impeller {
std::unique_ptr<SurfaceVK> SurfaceVK::WrapSwapchainImage(
    SwapchainImageVK* swapchain_image,
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

  ColorAttachment color0;
  // TODO (kaushikiska): this needs to be fixed.
  // color0.texture = std::make_shared<TextureGLES>(
  //     gl_context.GetReactor(), std::move(color0_tex),
  //     TextureGLES::IsWrapped::kWrapped);
  color0.clear_color = Color::DarkSlateGray();
  color0.load_action = LoadAction::kClear;
  color0.store_action = StoreAction::kStore;

  TextureDescriptor stencil0_tex;
  stencil0_tex.type = TextureType::kTexture2D;
  stencil0_tex.format = swapchain_image->GetPixelFormat();
  stencil0_tex.size = swapchain_image->GetSize();
  stencil0_tex.usage =
      static_cast<TextureUsageMask>(TextureUsage::kRenderTarget);
  stencil0_tex.sample_count = SampleCount::kCount1;

  StencilAttachment stencil0;
  stencil0.clear_stencil = 0;
  // TODO (kaushikiska): this needs to be fixed.
  // stencil0.texture = std::make_shared<TextureGLES>(
  //     gl_context.GetReactor(), std::move(stencil0_tex),
  //     TextureGLES::IsWrapped::kWrapped);
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
                     SwapCallback swap_callback) {}

SurfaceVK::~SurfaceVK() = default;

bool SurfaceVK::Present() const {
  return swap_callback_ ? swap_callback_() : false;
}

}  // namespace impeller
