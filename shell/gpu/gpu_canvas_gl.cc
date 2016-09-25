// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu_canvas_gl.h"

#include "lib/ftl/arraysize.h"
#include "lib/ftl/logging.h"
#include "flutter/flow/gl_connection.h"
#include "third_party/skia/include/gpu/GrContext.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace shell {

// The limit of the number of GPU resources we hold in the GrContext's
// GPU cache.
static const int kMaxGaneshResourceCacheCount = 2048;

// The limit of the bytes allocated toward GPU resources in the GrContext's
// GPU cache.
static const size_t kMaxGaneshResourceCacheBytes = 96 * 1024 * 1024;

GPUCanvasGL::GPUCanvasGL(intptr_t fbo) : fbo_(fbo) {}

GPUCanvasGL::~GPUCanvasGL() = default;

bool GPUCanvasGL::Setup() {
  if (context_ != nullptr) {
    // Already setup.
    return false;
  }

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

bool GPUCanvasGL::IsValid() {
  return context_ != nullptr;
}

SkCanvas* GPUCanvasGL::AcquireCanvas(const SkISize& size) {
  auto surface = AcquireSurface(size);

  if (surface == nullptr) {
    return nullptr;
  }

  return surface->getCanvas();
}

bool GPUCanvasGL::SelectPixelConfig(GrPixelConfig* config) {
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

sk_sp<SkSurface> GPUCanvasGL::CreateSurface(const SkISize& size) {
  if (context_ == nullptr) {
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
  desc.fRenderTargetHandle = fbo_;

  return SkSurface::MakeFromBackendRenderTarget(context_.get(), desc, nullptr);
}

sk_sp<SkSurface> GPUCanvasGL::AcquireSurface(const SkISize& size) {
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

GrContext* GPUCanvasGL::GetContext() {
  return context_.get();
}

}  // namespace shell
