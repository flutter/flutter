// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/surface_mtl.h"

#include "flutter/fml/trace_event.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/backend/metal/texture_mtl.h"
#include "impeller/renderer/render_target.h"

namespace impeller {

std::unique_ptr<Surface> SurfaceMTL::WrapCurrentMetalLayerDrawable(
    std::shared_ptr<Context> context,
    CAMetalLayer* layer) {
  TRACE_EVENT0("flutter", __FUNCTION__);

  if (context == nullptr || !context->IsValid() || layer == nil) {
    return nullptr;
  }

  auto current_drawable = [layer nextDrawable];

  if (!current_drawable) {
    VALIDATION_LOG << "Could not acquire current drawable.";
    return nullptr;
  }

  TextureDescriptor msaa_tex_desc;
  msaa_tex_desc.type = TextureType::k2DMultisample;
  msaa_tex_desc.sample_count = SampleCount::kCount4;
  msaa_tex_desc.format = PixelFormat::kB8G8R8A8UNormInt;
  msaa_tex_desc.size = {
      static_cast<ISize::Type>(current_drawable.texture.width),
      static_cast<ISize::Type>(current_drawable.texture.height)};
  msaa_tex_desc.usage = static_cast<uint64_t>(TextureUsage::kRenderTarget);

  auto msaa_tex = context->GetPermanentsAllocator()->CreateTexture(
      StorageMode::kDeviceTransient, msaa_tex_desc);
  if (!msaa_tex) {
    FML_LOG(ERROR) << "Could not allocate MSAA resolve texture.";
    return nullptr;
  }

  msaa_tex->SetLabel("ImpellerOnscreenColor4xMSAA");

  TextureDescriptor onscreen_tex_desc;
  onscreen_tex_desc.format = PixelFormat::kB8G8R8A8UNormInt;
  onscreen_tex_desc.size = msaa_tex_desc.size;
  onscreen_tex_desc.usage = static_cast<uint64_t>(TextureUsage::kRenderTarget);

  ColorAttachment color0;
  color0.texture = msaa_tex;
  color0.clear_color = Color::DarkSlateGray();
  color0.load_action = LoadAction::kClear;
  color0.store_action = StoreAction::kMultisampleResolve;
  color0.resolve_texture =
      std::make_shared<TextureMTL>(onscreen_tex_desc, current_drawable.texture);

  TextureDescriptor stencil0_tex;
  stencil0_tex.type = TextureType::k2DMultisample;
  stencil0_tex.sample_count = SampleCount::kCount4;
  stencil0_tex.format = PixelFormat::kS8UInt;
  stencil0_tex.size = msaa_tex_desc.size;
  stencil0_tex.usage =
      static_cast<TextureUsageMask>(TextureUsage::kRenderTarget);
  auto stencil_texture = context->GetPermanentsAllocator()->CreateTexture(
      StorageMode::kDeviceTransient, stencil0_tex);
  stencil_texture->SetLabel("ImpellerOnscreenStencil");

  StencilAttachment stencil0;
  stencil0.texture = stencil_texture;
  stencil0.clear_stencil = 0;
  stencil0.load_action = LoadAction::kClear;
  stencil0.store_action = StoreAction::kDontCare;

  RenderTarget desc;
  desc.SetColorAttachment(color0, 0u);
  desc.SetStencilAttachment(stencil0);

  // The constructor is private. So make_unique may not be used.
  return std::unique_ptr<SurfaceMTL>(
      new SurfaceMTL(std::move(desc), current_drawable));
}

SurfaceMTL::SurfaceMTL(RenderTarget target, id<MTLDrawable> drawable)
    : Surface(std::move(target)), drawable_(drawable) {}

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

}  // namespace impeller
