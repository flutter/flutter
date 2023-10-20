// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/surface_gles.h"

#include "flutter/fml/trace_event.h"
#include "impeller/base/config.h"
#include "impeller/renderer/backend/gles/context_gles.h"
#include "impeller/renderer/backend/gles/texture_gles.h"

namespace impeller {

std::unique_ptr<Surface> SurfaceGLES::WrapFBO(
    const std::shared_ptr<Context>& context,
    SwapCallback swap_callback,
    GLuint fbo,
    PixelFormat color_format,
    ISize fbo_size) {
  TRACE_EVENT0("impeller", "SurfaceGLES::WrapOnScreenFBO");

  if (context == nullptr || !context->IsValid() || !swap_callback) {
    return nullptr;
  }

  const auto& gl_context = ContextGLES::Cast(*context);

  TextureDescriptor color0_tex;
  color0_tex.type = TextureType::kTexture2D;
  color0_tex.format = color_format;
  color0_tex.size = fbo_size;
  color0_tex.usage = static_cast<TextureUsageMask>(TextureUsage::kRenderTarget);
  color0_tex.sample_count = SampleCount::kCount1;
  color0_tex.storage_mode = StorageMode::kDevicePrivate;

  ColorAttachment color0;
  color0.texture = std::make_shared<TextureGLES>(
      gl_context.GetReactor(), color0_tex, TextureGLES::IsWrapped::kWrapped);
  color0.clear_color = Color::DarkSlateGray();
  color0.load_action = LoadAction::kClear;
  color0.store_action = StoreAction::kStore;

  TextureDescriptor stencil0_tex;
  stencil0_tex.type = TextureType::kTexture2D;
  stencil0_tex.format = color_format;
  stencil0_tex.size = fbo_size;
  stencil0_tex.usage =
      static_cast<TextureUsageMask>(TextureUsage::kRenderTarget);
  stencil0_tex.sample_count = SampleCount::kCount1;

  StencilAttachment stencil0;
  stencil0.clear_stencil = 0;
  stencil0.texture = std::make_shared<TextureGLES>(
      gl_context.GetReactor(), stencil0_tex, TextureGLES::IsWrapped::kWrapped);
  stencil0.load_action = LoadAction::kClear;
  stencil0.store_action = StoreAction::kDontCare;

  RenderTarget render_target_desc;

  render_target_desc.SetColorAttachment(color0, 0u);
  render_target_desc.SetStencilAttachment(stencil0);

#ifdef IMPELLER_DEBUG
  gl_context.GetGPUTracer()->RecordRasterThread();
#endif  // IMPELLER_DEBUG

  return std::unique_ptr<SurfaceGLES>(
      new SurfaceGLES(std::move(swap_callback), render_target_desc));
}

SurfaceGLES::SurfaceGLES(SwapCallback swap_callback,
                         const RenderTarget& target_desc)
    : Surface(target_desc), swap_callback_(std::move(swap_callback)) {}

// |Surface|
SurfaceGLES::~SurfaceGLES() = default;

// |Surface|
bool SurfaceGLES::Present() const {
  return swap_callback_ ? swap_callback_() : false;
}

}  // namespace impeller
