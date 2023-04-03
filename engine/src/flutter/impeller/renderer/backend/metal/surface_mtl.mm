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

  TextureDescriptor msaa_tex_desc;
  msaa_tex_desc.storage_mode = StorageMode::kDeviceTransient;
  msaa_tex_desc.type = TextureType::kTexture2DMultisample;
  msaa_tex_desc.sample_count = SampleCount::kCount4;
  msaa_tex_desc.format = color_format;
  msaa_tex_desc.size = {
      static_cast<ISize::Type>(current_drawable.texture.width),
      static_cast<ISize::Type>(current_drawable.texture.height)};
  msaa_tex_desc.usage = static_cast<uint64_t>(TextureUsage::kRenderTarget);

  auto msaa_tex = context->GetResourceAllocator()->CreateTexture(msaa_tex_desc);
  if (!msaa_tex) {
    VALIDATION_LOG << "Could not allocate MSAA color texture.";
    return nullptr;
  }
  msaa_tex->SetLabel("ImpellerOnscreenColorMSAA");

  TextureDescriptor resolve_tex_desc;
  resolve_tex_desc.format = color_format;
  resolve_tex_desc.size = msaa_tex_desc.size;
  resolve_tex_desc.usage = static_cast<uint64_t>(TextureUsage::kRenderTarget);
  resolve_tex_desc.sample_count = SampleCount::kCount1;
  resolve_tex_desc.storage_mode = StorageMode::kDevicePrivate;

  std::shared_ptr<Texture> resolve_tex =
      std::make_shared<TextureMTL>(resolve_tex_desc, current_drawable.texture);
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

  TextureDescriptor stencil_tex_desc;
  stencil_tex_desc.storage_mode = StorageMode::kDeviceTransient;
  stencil_tex_desc.type = TextureType::kTexture2DMultisample;
  stencil_tex_desc.sample_count = SampleCount::kCount4;
  stencil_tex_desc.format =
      context->GetCapabilities()->GetDefaultStencilFormat();
  stencil_tex_desc.size = msaa_tex_desc.size;
  stencil_tex_desc.usage =
      static_cast<TextureUsageMask>(TextureUsage::kRenderTarget);
  auto stencil_tex =
      context->GetResourceAllocator()->CreateTexture(stencil_tex_desc);

  if (!stencil_tex) {
    VALIDATION_LOG << "Could not create stencil texture.";
    return nullptr;
  }
  stencil_tex->SetLabel("ImpellerOnscreenStencil");

  StencilAttachment stencil0;
  stencil0.texture = stencil_tex;
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
