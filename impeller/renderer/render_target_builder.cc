// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/render_target_builder.h"
#include "impeller/base/strings.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/allocator.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/texture.h"

namespace impeller {

RenderTargetBuilder::RenderTargetBuilder() = default;

RenderTargetBuilder::~RenderTargetBuilder() = default;

RenderTarget RenderTargetBuilder::Build(const Context& context) const {
  if (render_target_type_ == RenderTargetType::kOffscreen) {
    return CreateOffscreen(context);
  } else if (render_target_type_ == RenderTargetType::kOffscreenMSAA) {
    return CreateOffscreenMSAA(context);
  } else {
    return {};
  }
}

RenderTarget RenderTargetBuilder::CreateOffscreen(
    const Context& context) const {
  if (size_.IsEmpty()) {
    return {};
  }

  TextureDescriptor color_tex0;
  color_tex0.storage_mode = color_storage_mode_;
  color_tex0.format = PixelFormat::kDefaultColor;
  color_tex0.size = size_;
  color_tex0.usage = static_cast<uint64_t>(TextureUsage::kRenderTarget) |
                     static_cast<uint64_t>(TextureUsage::kShaderRead);

  TextureDescriptor stencil_tex0;
  stencil_tex0.storage_mode = stencil_storage_mode_;
  stencil_tex0.format = PixelFormat::kDefaultStencil;
  stencil_tex0.size = size_;
  stencil_tex0.usage =
      static_cast<TextureUsageMask>(TextureUsage::kRenderTarget);

  ColorAttachment color0;
  color0.clear_color = Color::BlackTransparent();
  color0.load_action = color_load_action_;
  color0.store_action = color_store_action_;
  color0.texture = context.GetResourceAllocator()->CreateTexture(color_tex0);

  if (!color0.texture) {
    return {};
  }

  color0.texture->SetLabel(SPrintF("%s Color Texture", label_.c_str()));

  StencilAttachment stencil0;
  stencil0.load_action = stencil_load_action_;
  stencil0.store_action = stencil_store_action_;
  stencil0.clear_stencil = 0u;
  stencil0.texture =
      context.GetResourceAllocator()->CreateTexture(stencil_tex0);

  if (!stencil0.texture) {
    return {};
  }

  stencil0.texture->SetLabel(SPrintF("%s Stencil Texture", label_.c_str()));

  RenderTarget target;
  target.SetColorAttachment(std::move(color0), 0u);
  target.SetStencilAttachment(std::move(stencil0));

  return target;
}

RenderTarget RenderTargetBuilder::CreateOffscreenMSAA(
    const Context& context) const {
  if (size_.IsEmpty()) {
    return {};
  }

  // Create MSAA color texture.

  TextureDescriptor color0_tex_desc;
  color0_tex_desc.storage_mode = color_storage_mode_;
  color0_tex_desc.type = TextureType::kTexture2DMultisample;
  color0_tex_desc.sample_count = SampleCount::kCount4;
  color0_tex_desc.format = PixelFormat::kDefaultColor;
  color0_tex_desc.size = size_;
  color0_tex_desc.usage = static_cast<uint64_t>(TextureUsage::kRenderTarget);

  auto color0_msaa_tex =
      context.GetResourceAllocator()->CreateTexture(color0_tex_desc);
  if (!color0_msaa_tex) {
    VALIDATION_LOG << "Could not create multisample color texture.";
    return {};
  }
  color0_msaa_tex->SetLabel(
      SPrintF("%s Color Texture (Multisample)", label_.c_str()));

  // Create color resolve texture.

  TextureDescriptor color0_resolve_tex_desc;
  color0_resolve_tex_desc.storage_mode = color_resolve_storage_mode_;
  color0_resolve_tex_desc.format = PixelFormat::kDefaultColor;
  color0_resolve_tex_desc.size = size_;
  color0_resolve_tex_desc.usage =
      static_cast<uint64_t>(TextureUsage::kRenderTarget) |
      static_cast<uint64_t>(TextureUsage::kShaderRead);

  auto color0_resolve_tex =
      context.GetResourceAllocator()->CreateTexture(color0_resolve_tex_desc);
  if (!color0_resolve_tex) {
    VALIDATION_LOG << "Could not create color texture.";
    return {};
  }
  color0_resolve_tex->SetLabel(SPrintF("%s Color Texture", label_.c_str()));

  // Color attachment.

  ColorAttachment color0;
  color0.clear_color = Color::BlackTransparent();
  color0.load_action = color_load_action_;
  color0.store_action = color_store_action_;
  color0.texture = color0_msaa_tex;
  color0.resolve_texture = color0_resolve_tex;

  // Create MSAA stencil texture.

  TextureDescriptor stencil_tex0;
  stencil_tex0.storage_mode = stencil_storage_mode_;
  stencil_tex0.type = TextureType::kTexture2DMultisample;
  stencil_tex0.sample_count = SampleCount::kCount4;
  stencil_tex0.format = PixelFormat::kDefaultStencil;
  stencil_tex0.size = size_;
  stencil_tex0.usage =
      static_cast<TextureUsageMask>(TextureUsage::kRenderTarget);

  StencilAttachment stencil0;
  stencil0.load_action = stencil_load_action_;
  stencil0.store_action = stencil_store_action_;
  stencil0.clear_stencil = 0u;
  stencil0.texture =
      context.GetResourceAllocator()->CreateTexture(stencil_tex0);

  if (!stencil0.texture) {
    return {};
  }

  stencil0.texture->SetLabel(SPrintF("%s Stencil Texture", label_.c_str()));

  RenderTarget target;
  target.SetColorAttachment(std::move(color0), 0u);
  target.SetStencilAttachment(std::move(stencil0));

  return target;
}

RenderTargetBuilder& RenderTargetBuilder::SetSize(ISize size) {
  size_ = size;
  return *this;
}

RenderTargetBuilder& RenderTargetBuilder::SetLabel(std::string label) {
  label_ = label;
  return *this;
}

RenderTargetBuilder& RenderTargetBuilder::SetColorStorageMode(
    StorageMode mode) {
  color_storage_mode_ = mode;
  return *this;
}

RenderTargetBuilder& RenderTargetBuilder::SetColorLoadAction(
    LoadAction action) {
  color_load_action_ = action;
  return *this;
}

RenderTargetBuilder& RenderTargetBuilder::SetColorStoreAction(
    StoreAction action) {
  color_store_action_ = action;
  return *this;
}

RenderTargetBuilder& RenderTargetBuilder::SetStencilStorageMode(
    StorageMode mode) {
  stencil_storage_mode_ = mode;
  return *this;
}

RenderTargetBuilder& RenderTargetBuilder::SetStencilLoadAction(
    LoadAction action) {
  stencil_load_action_ = action;
  return *this;
}

RenderTargetBuilder& RenderTargetBuilder::SetStencilStoreAction(
    StoreAction action) {
  stencil_store_action_ = action;
  return *this;
}

RenderTargetBuilder& RenderTargetBuilder::SetColorResolveStorageMode(
    StorageMode mode) {
  color_resolve_storage_mode_ = mode;
  return *this;
}

RenderTargetBuilder& RenderTargetBuilder::SetRenderTargetType(
    RenderTargetType type) {
  render_target_type_ = type;
  return *this;
}

}  // namespace impeller
