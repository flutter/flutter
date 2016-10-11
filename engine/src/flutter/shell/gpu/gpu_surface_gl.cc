// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu_surface_gl.h"

#include "flutter/flow/gl_connection.h"
#include "flutter/glue/trace_event.h"
#include "lib/ftl/arraysize.h"
#include "lib/ftl/logging.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/gpu/GrContext.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"

namespace shell {

// The limit of the number of GPU resources we hold in the GrContext's
// GPU cache.
static const int kMaxGaneshResourceCacheCount = 2048;

// The limit of the bytes allocated toward GPU resources in the GrContext's
// GPU cache.
static const size_t kMaxGaneshResourceCacheBytes = 96 * 1024 * 1024;

GPUSurfaceFrameGL::GPUSurfaceFrameGL(sk_sp<SkSurface> surface,
                                     SubmitCallback submit_callback)
    : surface_(surface), submit_callback_(submit_callback) {}

GPUSurfaceFrameGL::~GPUSurfaceFrameGL() {
  if (submit_callback_) {
    // Dropping without a Submit. Callback with nullptr so that the current
    // context on the thread is cleared.
    submit_callback_(nullptr);
  }
}

SkCanvas* GPUSurfaceFrameGL::SkiaCanvas() {
  return surface_->getCanvas();
}

bool GPUSurfaceFrameGL::PerformSubmit() {
  if (submit_callback_ == nullptr) {
    return false;
  }

  FLUTTER_THREAD_CHECKER_CHECK(checker_);

  if (submit_callback_(surface_->getCanvas())) {
    surface_ = nullptr;
    return true;
  }

  return false;
}

GPUSurfaceGL::GPUSurfaceGL(GPUSurfaceGLDelegate* delegate)
    : delegate_(delegate), weak_factory_(this) {}

GPUSurfaceGL::~GPUSurfaceGL() = default;

bool GPUSurfaceGL::Setup() {
  if (delegate_ == nullptr) {
    // Invalid delegate.
    return false;
  }

  if (context_ != nullptr) {
    // Already setup.
    return false;
  }

  if (!delegate_->GLContextMakeCurrent()) {
    // Could not make the context current to create the native interface.
    return false;
  }

  // Create the native interface.
  auto backend_context =
      reinterpret_cast<GrBackendContext>(GrGLCreateNativeInterface());

  context_ =
      sk_sp<GrContext>(GrContext::Create(kOpenGL_GrBackend, backend_context));

  if (context_ == nullptr) {
    flow::GLConnection connection;
    FTL_LOG(INFO) << "Failed to setup GL context. Aborting.";
    FTL_LOG(INFO) << connection.Description();
  }

  context_->setResourceCacheLimits(kMaxGaneshResourceCacheCount,
                                   kMaxGaneshResourceCacheBytes);

  return true;
}

bool GPUSurfaceGL::IsValid() {
  return context_ != nullptr;
}

std::unique_ptr<SurfaceFrame> GPUSurfaceGL::AcquireFrame(const SkISize& size) {
  if (delegate_ == nullptr) {
    return nullptr;
  }

  sk_sp<SkSurface> surface = AcquireSurface(size);

  if (surface == nullptr) {
    return nullptr;
  }

  auto weak_this = weak_factory_.GetWeakPtr();

  GPUSurfaceFrameGL::SubmitCallback submit_callback =
      [weak_this](SkCanvas* canvas) {
        return weak_this ? weak_this->PresentSurface(canvas) : false;
      };

  return std::unique_ptr<GPUSurfaceFrameGL>(
      new GPUSurfaceFrameGL(surface, submit_callback));
}

bool GPUSurfaceGL::PresentSurface(SkCanvas* canvas) {
  if (delegate_ == nullptr || canvas == nullptr) {
    return false;
  }

  {
    TRACE_EVENT0("flutter", "SkCanvas::Flush");
    canvas->flush();
  }

  delegate_->GLContextPresent();

  return true;
}

bool GPUSurfaceGL::SelectPixelConfig(GrPixelConfig* config) {
  static const GrPixelConfig kConfigOptions[] = {
      kSkia8888_GrPixelConfig, kRGBA_4444_GrPixelConfig,
  };

  for (size_t i = 0; i < arraysize(kConfigOptions); i++) {
    if (context_->caps()->isConfigRenderable(kConfigOptions[i], false)) {
      *config = kConfigOptions[i];
      return true;
    }
  }

  return false;
}

sk_sp<SkSurface> GPUSurfaceGL::CreateSurface(const SkISize& size) {
  if (delegate_ == nullptr || context_ == nullptr) {
    return nullptr;
  }

  GrBackendRenderTargetDesc desc;

  if (!SelectPixelConfig(&desc.fConfig)) {
    return nullptr;
  }

  desc.fWidth = size.width();
  desc.fHeight = size.height();
  desc.fStencilBits = 8;
  desc.fOrigin = kBottomLeft_GrSurfaceOrigin;
  desc.fRenderTargetHandle = delegate_->GLContextFBO();

  return SkSurface::MakeFromBackendRenderTarget(context_.get(), desc, nullptr);
}

sk_sp<SkSurface> GPUSurfaceGL::AcquireSurface(const SkISize& size) {
  // There is no cached surface.
  if (cached_surface_ == nullptr) {
    cached_surface_ = CreateSurface(size);
    return cached_surface_;
  }

  // There is a surface previously created of the same size.
  if (cached_surface_->width() == size.width() &&
      cached_surface_->height() == size.height()) {
    return cached_surface_;
  }

  cached_surface_ = CreateSurface(size);
  return cached_surface_;
}

GrContext* GPUSurfaceGL::GetContext() {
  return context_.get();
}

}  // namespace shell
