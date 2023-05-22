// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/surface_mtl.h"

#include "flutter/fml/trace_event.h"
#include "flutter/impeller/renderer/command_buffer.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/backend/metal/context_mtl.h"
#include "impeller/renderer/backend/metal/formats_mtl.h"
#include "impeller/renderer/backend/metal/texture_mtl.h"
#include "impeller/renderer/render_target.h"

namespace impeller {

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunguarded-availability-new"

id<CAMetalDrawable> SurfaceMTL::GetMetalDrawableAndValidate(
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
  return current_drawable;
}

std::unique_ptr<SurfaceMTL> SurfaceMTL::WrapCurrentMetalLayerDrawable(
    const std::shared_ptr<Context>& context,
    id<CAMetalDrawable> drawable,
    std::optional<IRect> clip_rect) {
  bool requires_blit = ShouldPerformPartialRepaint(clip_rect);
  const auto color_format = FromMTLPixelFormat(drawable.texture.pixelFormat);

  if (color_format == PixelFormat::kUnknown) {
    VALIDATION_LOG << "Unknown drawable color format.";
    return nullptr;
  }
  // compositor_context.cc will offset the rendering by the clip origin. Here we
  // shrink to the size of the clip. This has the same effect as clipping the
  // rendering but also creates smaller intermediate passes.
  ISize root_size;
  if (requires_blit) {
    root_size = ISize(clip_rect->size.width, clip_rect->size.height);
  } else {
    root_size = {static_cast<ISize::Type>(drawable.texture.width),
                 static_cast<ISize::Type>(drawable.texture.height)};
  }

  TextureDescriptor msaa_tex_desc;
  msaa_tex_desc.storage_mode = StorageMode::kDeviceTransient;
  msaa_tex_desc.type = TextureType::kTexture2DMultisample;
  msaa_tex_desc.sample_count = SampleCount::kCount4;
  msaa_tex_desc.format = color_format;
  msaa_tex_desc.size = root_size;
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
  resolve_tex_desc.usage = static_cast<uint64_t>(TextureUsage::kRenderTarget) |
                           static_cast<uint64_t>(TextureUsage::kShaderRead);
  resolve_tex_desc.sample_count = SampleCount::kCount1;
  resolve_tex_desc.storage_mode = StorageMode::kDevicePrivate;

  // Create color resolve texture.
  std::shared_ptr<Texture> resolve_tex;
  if (requires_blit) {
    resolve_tex_desc.compression_type = CompressionType::kLossy;
    resolve_tex =
        context->GetResourceAllocator()->CreateTexture(resolve_tex_desc);
  } else {
    resolve_tex =
        std::make_shared<TextureMTL>(resolve_tex_desc, drawable.texture);
  }

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
  return std::unique_ptr<SurfaceMTL>(new SurfaceMTL(context, render_target_desc,
                                                    resolve_tex, drawable,
                                                    requires_blit, clip_rect));
}

SurfaceMTL::SurfaceMTL(const std::weak_ptr<Context>& context,
                       const RenderTarget& target,
                       std::shared_ptr<Texture> resolve_texture,
                       id<CAMetalDrawable> drawable,
                       bool requires_blit,
                       std::optional<IRect> clip_rect)
    : Surface(target),
      context_(context),
      resolve_texture_(std::move(resolve_texture)),
      drawable_(drawable),
      requires_blit_(requires_blit),
      clip_rect_(clip_rect) {}

// |Surface|
SurfaceMTL::~SurfaceMTL() = default;

bool SurfaceMTL::ShouldPerformPartialRepaint(std::optional<IRect> damage_rect) {
  // compositor_context.cc will conditionally disable partial repaint if the
  // damage region is large. If that happened, then a nullopt damage rect
  // will be provided here.
  if (!damage_rect.has_value()) {
    return false;
  }
  // If the damage rect is 0 in at least one dimension, partial repaint isn't
  // performed as we skip right to present.
  if (damage_rect->size.width <= 0 || damage_rect->size.height <= 0) {
    return false;
  }
  return true;
}

// |Surface|
IRect SurfaceMTL::coverage() const {
  return IRect::MakeSize(resolve_texture_->GetSize());
}

// |Surface|
bool SurfaceMTL::Present() const {
  if (drawable_ == nil) {
    return false;
  }

  auto context = context_.lock();
  if (!context) {
    return false;
  }

  if (requires_blit_) {
    auto blit_command_buffer = context->CreateCommandBuffer();
    if (!blit_command_buffer) {
      return false;
    }
    auto blit_pass = blit_command_buffer->CreateBlitPass();
    auto current = TextureMTL::Wrapper({}, drawable_.texture);
    blit_pass->AddCopy(resolve_texture_, current, std::nullopt,
                       clip_rect_->origin);
    blit_pass->EncodeCommands(context->GetResourceAllocator());
    if (!blit_command_buffer->SubmitCommands()) {
      return false;
    }
  }

#if ((FML_OS_MACOSX && !FML_OS_IOS) || FML_OS_IOS_SIMULATOR)
  // If a transaction is present, `presentDrawable` will present too early. And
  // so we wait on an empty command buffer to get scheduled instead, which
  // forces us to also wait for all of the previous command buffers in the queue
  // to get scheduled.
  id<MTLCommandBuffer> command_buffer =
      ContextMTL::Cast(context.get())->CreateMTLCommandBuffer();
  [command_buffer commit];
  [command_buffer waitUntilScheduled];
#endif  // ((FML_OS_MACOSX && !FML_OS_IOS) || FML_OS_IOS_SIMULATOR)

  [drawable_ present];

  return true;
}
#pragma GCC diagnostic pop

}  // namespace impeller
