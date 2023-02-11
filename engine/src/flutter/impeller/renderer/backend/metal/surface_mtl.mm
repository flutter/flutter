// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/surface_mtl.h"

#include "flutter/fml/trace_event.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/backend/metal/formats_mtl.h"
#include "impeller/renderer/backend/metal/texture_mtl.h"
#include "impeller/renderer/render_target.h"

namespace impeller {

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunguarded-availability-new"

std::unique_ptr<SurfaceMTL> SurfaceMTL::WrapCurrentMetalLayerDrawable(
    const std::shared_ptr<Context>& context,
    CAMetalLayer* layer) {
  TRACE_EVENT0("impeller", "SurfaceMTL::WrapCurrentMetalLayerDrawable");

  if (context == nullptr || !context->IsValid() || layer == nil) {
    return nullptr;
  }

  id<CAMetalDrawable> current_drawable = nil;
  {
    TRACE_EVENT0("impeller", "WaitForNextDrawable");
    current_drawable = [layer nextDrawable];
  }

  if (!current_drawable) {
    VALIDATION_LOG << "Could not acquire current drawable.";
    return nullptr;
  }

  const auto color_format =
      FromMTLPixelFormat(current_drawable.texture.pixelFormat);

  if (color_format == PixelFormat::kUnknown) {
    VALIDATION_LOG << "Unknown drawable color format.";
    return nullptr;
  }

  TextureDescriptor color0_tex_desc;
  color0_tex_desc.storage_mode = StorageMode::kDeviceTransient;
  color0_tex_desc.type = TextureType::kTexture2DMultisample;
  color0_tex_desc.sample_count = SampleCount::kCount4;
  color0_tex_desc.format = color_format;
  color0_tex_desc.size = {
      static_cast<ISize::Type>(current_drawable.texture.width),
      static_cast<ISize::Type>(current_drawable.texture.height)};
  color0_tex_desc.usage = static_cast<uint64_t>(TextureUsage::kRenderTarget);

  auto msaa_tex =
      context->GetResourceAllocator()->CreateTexture(color0_tex_desc);
  if (!msaa_tex) {
    VALIDATION_LOG << "Could not allocate MSAA resolve texture.";
    return nullptr;
  }

  msaa_tex->SetLabel("ImpellerOnscreenColorMSAA");

  TextureDescriptor color0_resolve_tex_desc;
  color0_resolve_tex_desc.format = color_format;
  color0_resolve_tex_desc.size = color0_tex_desc.size;
  color0_resolve_tex_desc.usage =
      static_cast<uint64_t>(TextureUsage::kRenderTarget);
  color0_resolve_tex_desc.storage_mode = StorageMode::kDevicePrivate;

  ColorAttachment color0;
  color0.texture = msaa_tex;
  color0.clear_color = Color::DarkSlateGray();
  color0.load_action = LoadAction::kClear;
  color0.store_action = StoreAction::kMultisampleResolve;
  color0.resolve_texture = std::make_shared<TextureMTL>(
      color0_resolve_tex_desc, current_drawable.texture);

  TextureDescriptor stencil0_tex;
  stencil0_tex.storage_mode = StorageMode::kDeviceTransient;
  stencil0_tex.type = TextureType::kTexture2DMultisample;
  stencil0_tex.sample_count = SampleCount::kCount4;
  stencil0_tex.format = PixelFormat::kDefaultStencil;
  stencil0_tex.size = color0_tex_desc.size;
  stencil0_tex.usage =
      static_cast<TextureUsageMask>(TextureUsage::kRenderTarget);
  auto stencil_texture =
      context->GetResourceAllocator()->CreateTexture(stencil0_tex);

  if (!stencil_texture) {
    VALIDATION_LOG << "Could not create stencil texture.";
    return nullptr;
  }
  stencil_texture->SetLabel("ImpellerOnscreenStencil");

  StencilAttachment stencil0;
  stencil0.texture = stencil_texture;
  stencil0.clear_stencil = 0;
  stencil0.load_action = LoadAction::kClear;
  stencil0.store_action = StoreAction::kDontCare;

  RenderTarget render_target_desc;
  render_target_desc.SetColorAttachment(color0, 0u);
  render_target_desc.SetStencilAttachment(stencil0);

  // The constructor is private. So make_unique may not be used.
  return std::unique_ptr<SurfaceMTL>(
      new SurfaceMTL(render_target_desc, current_drawable));
}

SurfaceMTL::SurfaceMTL(const RenderTarget& target, id<MTLDrawable> drawable)
    : Surface(target), drawable_(drawable) {}

// |Surface|
SurfaceMTL::~SurfaceMTL() = default;

// |Surface|
bool SurfaceMTL::Present() const {
  if (drawable_ == nil) {
    return false;
  }

  [drawable_ present];
  return true;
}
#pragma GCC diagnostic pop

}  // namespace impeller
