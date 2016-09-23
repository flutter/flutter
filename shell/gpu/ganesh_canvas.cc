// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/gpu/ganesh_canvas.h"

#include "flutter/flow/gl_connection.h"
#include "lib/ftl/arraysize.h"
#include "lib/ftl/logging.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"

namespace shell {
namespace {

// The limit of the number of GPU resources we hold in the GrContext's
// GPU cache.
const int kMaxGaneshResourceCacheCount = 2048;

// The limit of the bytes allocated toward GPU resources in the GrContext's
// GPU cache.
const size_t kMaxGaneshResourceCacheBytes = 96 * 1024 * 1024;

}  // namespace

GaneshCanvas::GaneshCanvas() {}

GaneshCanvas::~GaneshCanvas() {}

bool GaneshCanvas::SetupGrGLInterface() {
  sk_surface_ = nullptr;
  gr_context_ = sk_sp<GrContext>(GrContext::Create(
      kOpenGL_GrBackend,
      reinterpret_cast<GrBackendContext>(GrGLCreateNativeInterface())));

  if (gr_context_ == nullptr) {
    flow::GLConnection connection;
    FTL_LOG(INFO) << "Failed to setup GL context. Aborting.";
    FTL_LOG(INFO) << connection.Description();
  }

  if (!gr_context_)
    return false;

  gr_context_->setResourceCacheLimits(kMaxGaneshResourceCacheCount,
                                      kMaxGaneshResourceCacheBytes);
  return true;
}

bool GaneshCanvas::SelectPixelConfig(GrPixelConfig* config) {
  static const GrPixelConfig kConfigOptions[] = {
      kSkia8888_GrPixelConfig, kRGBA_4444_GrPixelConfig,
  };

  for (size_t i = 0; i < arraysize(kConfigOptions); i++) {
    if (gr_context_->caps()->isConfigRenderable(kConfigOptions[i], false)) {
      *config = kConfigOptions[i];
      return true;
    }
  }

  return false;
}

SkCanvas* GaneshCanvas::GetCanvas(int32_t fbo, const SkISize& size) {
  FTL_DCHECK(IsValid());

  if (sk_surface_ && sk_surface_->width() == size.width() &&
      sk_surface_->height() == size.height())
    return sk_surface_->getCanvas();

  GrBackendRenderTargetDesc desc;
  desc.fWidth = size.width();
  desc.fHeight = size.height();
  FTL_CHECK(SelectPixelConfig(&desc.fConfig));
  desc.fStencilBits = 8;
  desc.fOrigin = kBottomLeft_GrSurfaceOrigin;
  desc.fRenderTargetHandle = fbo;

  sk_surface_ =
      SkSurface::MakeFromBackendRenderTarget(gr_context_.get(), desc, nullptr);
  FTL_DCHECK(sk_surface_);
  return sk_surface_->getCanvas();
}

bool GaneshCanvas::IsValid() {
  return gr_context_;
}

}  // namespace shell
