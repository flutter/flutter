// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "render_context.h"

#include "export.h"
#include "flutter/display_list/skia/dl_sk_dispatcher.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/gpu/ganesh/GrBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/GrDirectContext.h"
#include "third_party/skia/include/gpu/ganesh/SkSurfaceGanesh.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLDirectContext.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLInterface.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLMakeWebGLInterface.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLTypes.h"

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>

SKWASM_EXPORT bool skwasm_isWimp() {
  return false;
}

using namespace Skwasm;
namespace {
class SkiaRenderContext : public RenderContext {
 public:
  SkiaRenderContext(int sampleCount, int stencil)
      : _sampleCount(sampleCount),
        _stencil(stencil),
        _grContext(GrDirectContexts::MakeGL(GrGLInterfaces::MakeWebGL())),
        _fbInfo({0, GL_RGBA8_OES}) {
    _grContext->resetContext(kRenderTarget_GrGLBackendState |
                             kMisc_GrGLBackendState);
  }

  virtual void renderPicture(
      const sk_sp<flutter::DisplayList> displayList) override {
    auto canvas = _surface->getCanvas();
    canvas->drawColor(SK_ColorTRANSPARENT, SkBlendMode::kSrc);
    auto dispatcher = flutter::DlSkCanvasDispatcher(canvas);
    dispatcher.save();
    dispatcher.drawDisplayList(displayList, 1.0f);
    dispatcher.restore();

    _grContext->flush(_surface.get());
  }

  virtual void renderImage(flutter::DlImage* image,
                           ImageByteFormat format) override {
    auto canvas = _surface->getCanvas();
    canvas->drawColor(SK_ColorTRANSPARENT, SkBlendMode::kSrc);

    // We want the pixels from the upper left corner, but glReadPixels gives us
    // the pixels from the lower left corner. So we have to flip the image when
    // we are drawing it to get the pixels in the desired order.
    canvas->save();
    canvas->scale(1, -1);
    canvas->drawImage(image->skia_image(), 0, -_height);
    canvas->restore();
    _grContext->flush(_surface.get());
  }

  virtual void resize(int width, int height) override {
    if (_width != width || _height != height) {
      _width = width;
      _height = height;
      auto target = GrBackendRenderTargets::MakeGL(width, height, _sampleCount,
                                                   _stencil, _fbInfo);
      _surface = SkSurfaces::WrapBackendRenderTarget(
          _grContext.get(), target, kBottomLeft_GrSurfaceOrigin,
          kRGBA_8888_SkColorType, SkColorSpace::MakeSRGB(), nullptr);
    }
  }

  virtual void setResourceCacheLimit(int bytes) override {
    _grContext->setResourceCacheLimit(bytes);
  }

 private:
  sk_sp<GrDirectContext> _grContext = nullptr;
  sk_sp<SkSurface> _surface = nullptr;
  GrGLFramebufferInfo _fbInfo;
  GrGLint _sampleCount;
  GrGLint _stencil;
  int _width = 0;
  int _height = 0;
};
}  // namespace

std::unique_ptr<RenderContext> Skwasm::RenderContext::Make(int sampleCount,
                                                           int stencil) {
  return std::make_unique<SkiaRenderContext>(sampleCount, stencil);
}
