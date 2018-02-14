// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu_surface_gl.h"

#include "flutter/glue/trace_event.h"
#include "lib/fxl/arraysize.h"
#include "lib/fxl/logging.h"
#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/gpu/GrBackendSurface.h"
#include "third_party/skia/include/gpu/GrContextOptions.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"

namespace shell {

// Default maximum number of budgeted resources in the cache.
static const int kGrCacheMaxCount = 8192;

// Default maximum number of bytes of GPU memory of budgeted resources in the
// cache.
static const size_t kGrCacheMaxByteSize = 512 * (1 << 20);

GPUSurfaceGL::GPUSurfaceGL(GPUSurfaceGLDelegate* delegate)
    : delegate_(delegate), weak_factory_(this) {
  if (!delegate_->GLContextMakeCurrent()) {
    FXL_LOG(ERROR)
        << "Could not make the context current to setup the gr context.";
    return;
  }

  GrContextOptions options;
  options.fAvoidStencilBuffers = true;

  auto context = GrContext::MakeGL(GrGLMakeNativeInterface(), options);

  if (context == nullptr) {
    FXL_LOG(ERROR) << "Failed to setup Skia Gr context.";
    return;
  }

  context_ = std::move(context);

  context_->setResourceCacheLimits(kGrCacheMaxCount, kGrCacheMaxByteSize);

  delegate_->GLContextClearCurrent();

  valid_ = true;
}

GPUSurfaceGL::~GPUSurfaceGL() {
  if (!valid_) {
    return;
  }

  if (!delegate_->GLContextMakeCurrent()) {
    FXL_LOG(ERROR) << "Could not make the context current to destroy the "
                      "GrContext resources.";
    return;
  }

  onscreen_surface_ = nullptr;
  context_->releaseResourcesAndAbandonContext();
  context_ = nullptr;

  delegate_->GLContextClearCurrent();
}

bool GPUSurfaceGL::IsValid() {
  return valid_;
}

static GrPixelConfig FirstSupportedConfig(GrContext* context) {
#define RETURN_IF_RENDERABLE(x)                          \
  if (context->caps()->isConfigRenderable((x), false)) { \
    return (x);                                          \
  }
  RETURN_IF_RENDERABLE(kRGBA_8888_GrPixelConfig);
  RETURN_IF_RENDERABLE(kRGBA_4444_GrPixelConfig);
  RETURN_IF_RENDERABLE(kRGB_565_GrPixelConfig);
  return kUnknown_GrPixelConfig;
}

static sk_sp<SkSurface> WrapOnscreenSurface(GrContext* context,
                                            const SkISize& size,
                                            intptr_t fbo) {
  const GrGLFramebufferInfo framebuffer_info = {
      .fFBOID = static_cast<GrGLuint>(fbo),
  };

  const GrPixelConfig pixel_config = FirstSupportedConfig(context);

  GrBackendRenderTarget render_target(size.fWidth,      // width
                                      size.fHeight,     // height
                                      0,                // sample count
                                      0,                // stencil bits (TODO)
                                      pixel_config,     // pixel config
                                      framebuffer_info  // framebuffer info
  );

  sk_sp<SkColorSpace> colorspace = nullptr;

  SkSurfaceProps surface_props(
      SkSurfaceProps::InitType::kLegacyFontHost_InitType);

  return SkSurface::MakeFromBackendRenderTarget(
      context,                                       // gr context
      render_target,                                 // render target
      GrSurfaceOrigin::kBottomLeft_GrSurfaceOrigin,  // origin
      colorspace,                                    // colorspace
      &surface_props                                 // surface properties
  );
}

static sk_sp<SkSurface> CreateOffscreenSurface(GrContext* context,
                                               const SkISize& size) {
  const SkImageInfo image_info =
      SkImageInfo::MakeN32(size.fWidth, size.fHeight, kOpaque_SkAlphaType);

  const SkSurfaceProps surface_props(
      SkSurfaceProps::InitType::kLegacyFontHost_InitType);

  return SkSurface::MakeRenderTarget(context, SkBudgeted::kNo, image_info, 0,
                                     kBottomLeft_GrSurfaceOrigin,
                                     &surface_props);
}

bool GPUSurfaceGL::CreateOrUpdateSurfaces(const SkISize& size) {
  if (onscreen_surface_ != nullptr &&
      size == SkISize::Make(onscreen_surface_->width(),
                            onscreen_surface_->height())) {
    // Surface size appears unchanged. So bail.
    return true;
  }

  // We need to do some updates.
  TRACE_EVENT0("flutter", "UpdateSurfacesSize");

  // Either way, we need to get rid of previous surface.
  onscreen_surface_ = nullptr;
  offscreen_surface_ = nullptr;

  if (size.isEmpty()) {
    FXL_LOG(ERROR) << "Cannot create surfaces of empty size.";
    return false;
  }

  sk_sp<SkSurface> onscreen_surface, offscreen_surface;

  onscreen_surface =
      WrapOnscreenSurface(context_.get(), size, delegate_->GLContextFBO());

  if (onscreen_surface == nullptr) {
    // If the onscreen surface could not be wrapped. There is absolutely no
    // point in moving forward.
    FXL_LOG(ERROR) << "Could not wrap onscreen surface.";
    return false;
  }

  if (delegate_->UseOffscreenSurface()) {
    offscreen_surface = CreateOffscreenSurface(context_.get(), size);
    if (offscreen_surface == nullptr) {
      FXL_LOG(ERROR) << "Could not create offscreen surface.";
      return false;
    }
  }

  onscreen_surface_ = std::move(onscreen_surface);
  offscreen_surface_ = std::move(offscreen_surface);

  return true;
}

std::unique_ptr<SurfaceFrame> GPUSurfaceGL::AcquireFrame(const SkISize& size) {
  if (delegate_ == nullptr) {
    return nullptr;
  }

  if (!delegate_->GLContextMakeCurrent()) {
    FXL_LOG(ERROR)
        << "Could not make the context current to acquire the frame.";
    return nullptr;
  }

  sk_sp<SkSurface> surface = AcquireRenderSurface(size);

  if (surface == nullptr) {
    return nullptr;
  }

  auto weak_this = weak_factory_.GetWeakPtr();

  SurfaceFrame::SubmitCallback submit_callback =
      [weak_this](const SurfaceFrame& surface_frame, SkCanvas* canvas) {
        return weak_this ? weak_this->PresentSurface(canvas) : false;
      };

  return std::make_unique<SurfaceFrame>(surface, submit_callback);
}

bool GPUSurfaceGL::PresentSurface(SkCanvas* canvas) {
  if (delegate_ == nullptr || canvas == nullptr || context_ == nullptr) {
    return false;
  }

  if (offscreen_surface_ != nullptr) {
    TRACE_EVENT0("flutter", "CopyTextureOnscreen");
    SkPaint paint;
    onscreen_surface_->getCanvas()->drawImage(
        offscreen_surface_->makeImageSnapshot(), 0, 0, &paint);
  }

  {
    TRACE_EVENT0("flutter", "SkCanvas::Flush");
    onscreen_surface_->getCanvas()->flush();
  }

  delegate_->GLContextPresent();

  return true;
}

sk_sp<SkSurface> GPUSurfaceGL::AcquireRenderSurface(const SkISize& size) {
  if (!CreateOrUpdateSurfaces(size)) {
    return nullptr;
  }

  return offscreen_surface_ != nullptr ? offscreen_surface_ : onscreen_surface_;
}

GrContext* GPUSurfaceGL::GetContext() {
  return context_.get();
}

}  // namespace shell
