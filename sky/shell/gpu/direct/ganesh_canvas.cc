// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/gpu/direct/ganesh_canvas.h"

#include "base/logging.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"

namespace sky {
namespace shell {
namespace {

// The limit of the number of GPU resources we hold in the GrContext's
// GPU cache.
const int kMaxGaneshResourceCacheCount = 2048;

// The limit of the bytes allocated toward GPU resources in the GrContext's
// GPU cache.
const size_t kMaxGaneshResourceCacheBytes = 96 * 1024 * 1024;

}  // namespace

GaneshCanvas::GaneshCanvas() {
}

GaneshCanvas::~GaneshCanvas() {
}

void GaneshCanvas::SetGrGLInterface(const GrGLInterface* interface) {
  sk_surface_ = nullptr;
  if (interface) {
    gr_context_ = skia::AdoptRef(GrContext::Create(kOpenGL_GrBackend,
        reinterpret_cast<GrBackendContext>(interface)));
    DCHECK(gr_context_);
    gr_context_->setResourceCacheLimits(kMaxGaneshResourceCacheCount,
                                        kMaxGaneshResourceCacheBytes);
  } else if (gr_context_) {
    gr_context_->abandonContext();
    gr_context_.clear();
  }
}

bool GaneshCanvas::SelectPixelConfig(GrPixelConfig* config) {
  static const GrPixelConfig kConfigOptions[] = {
    kSkia8888_GrPixelConfig,
    kRGBA_4444_GrPixelConfig,
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
  DCHECK(IsValid());

  if (sk_surface_ && sk_surface_->width() == size.width()
      && sk_surface_->height() == size.height())
    return sk_surface_->getCanvas();

  GrBackendRenderTargetDesc desc;
  desc.fWidth = size.width();
  desc.fHeight = size.height();
  CHECK(SelectPixelConfig(&desc.fConfig));
  desc.fStencilBits = 8;
  desc.fOrigin = kBottomLeft_GrSurfaceOrigin;
  desc.fRenderTargetHandle = fbo;

  skia::RefPtr<GrRenderTarget> target = skia::AdoptRef(
    gr_context_->textureProvider()->wrapBackendRenderTarget(desc));
  DCHECK(target);
  sk_surface_ = SkSurface::MakeRenderTargetDirect(target.get());
  DCHECK(sk_surface_);
  return sk_surface_->getCanvas();
}

bool GaneshCanvas::IsValid() {
  return gr_context_;
}

}  // namespace shell
}  // namespace sky
