// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/skwasm/render_context.h"

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>

#include "flutter/display_list/image/dl_image_skia.h"
#include "flutter/display_list/skia/dl_sk_dispatcher.h"
#include "flutter/skwasm/export.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/gpu/ganesh/GrBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/GrDirectContext.h"
#include "third_party/skia/include/gpu/ganesh/SkSurfaceGanesh.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLDirectContext.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLInterface.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLMakeWebGLInterface.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLTypes.h"

SKWASM_EXPORT bool skwasm_isWimp() {
  return false;
}

namespace {
class SkiaRenderContext : public Skwasm::RenderContext {
 public:
  SkiaRenderContext(int sample_count, int stencil)
      : sample_count_(sample_count),
        stencil_(stencil),
        gr_context_(GrDirectContexts::MakeGL(GrGLInterfaces::MakeWebGL())),
        fb_info_({0, GL_RGBA8_OES}) {
    gr_context_->resetContext(kRenderTarget_GrGLBackendState |
                              kMisc_GrGLBackendState);
  }

  virtual void RenderPicture(
      const sk_sp<flutter::DisplayList> display_list) override {
    auto canvas = surface_->getCanvas();
    canvas->drawColor(SK_ColorTRANSPARENT, SkBlendMode::kSrc);
    auto dispatcher = flutter::DlSkCanvasDispatcher(canvas);
    dispatcher.save();
    dispatcher.drawDisplayList(display_list, 1.0f);
    dispatcher.restore();

    gr_context_->flush(surface_.get());
  }

  virtual bool RasterizeImage(flutter::DlImage* image,
                              Skwasm::ImageByteFormat format,
                              void* out_pixels) override {
    // TODO(jacksongardner):
    // Normally we'd just call `readPixels` on the image. However, this doesn't
    // actually work in some cases due to a skia bug. Instead, we just draw the
    // image to our scratch canvas and grab the pixels out directly with
    // `glReadPixels`. Once the skia bug is fixed, we should switch back to
    // using `SkImage::readPixels` instead. See
    // https://g-issues.skia.org/issues/349201915
    RenderImage(image, format);
    glReadPixels(0, 0, image->width(), image->height(), GL_RGBA,
                 GL_UNSIGNED_BYTE, out_pixels);
    return true;
  }

  virtual void Resize(int width, int height) override {
    if (width_ != width || height_ != height) {
      width_ = width;
      height_ = height;
      auto target = GrBackendRenderTargets::MakeGL(width, height, sample_count_,
                                                   stencil_, fb_info_);
      surface_ = SkSurfaces::WrapBackendRenderTarget(
          gr_context_.get(), target, kBottomLeft_GrSurfaceOrigin,
          kRGBA_8888_SkColorType, SkColorSpace::MakeSRGB(), nullptr);
    }
  }

  virtual void SetResourceCacheLimit(int bytes) override {
    gr_context_->setResourceCacheLimit(bytes);
  }

 private:
  void RenderImage(flutter::DlImage* image, Skwasm::ImageByteFormat format) {
    auto canvas = surface_->getCanvas();
    canvas->drawColor(SK_ColorTRANSPARENT, SkBlendMode::kSrc);

    // We want the pixels from the upper left corner, but glReadPixels gives us
    // the pixels from the lower left corner. So we have to flip the image when
    // we are drawing it to get the pixels in the desired order.
    canvas->save();
    canvas->scale(1, -1);
    auto skia_image = image ? image->asSkiaImage() : nullptr;
    canvas->drawImage(skia_image ? skia_image->skia_image() : nullptr, 0,
                      -height_);
    canvas->restore();

    gr_context_->flush(surface_.get());
  }

  sk_sp<GrDirectContext> gr_context_ = nullptr;
  sk_sp<SkSurface> surface_ = nullptr;
  GrGLFramebufferInfo fb_info_;
  GrGLint sample_count_;
  GrGLint stencil_;
  int width_ = 0;
  int height_ = 0;
};
}  // namespace

std::unique_ptr<Skwasm::RenderContext> Skwasm::RenderContext::Make(
    int sample_count,
    int stencil) {
  return std::make_unique<SkiaRenderContext>(sample_count, stencil);
}
