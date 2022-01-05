// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_benchmarks.h"
#include "flutter/testing/test_gl_surface.h"

#include "third_party/skia/include/core/SkCanvas.h"

namespace flutter {
namespace testing {

class OpenGLCanvasProvider : public CanvasProvider {
 public:
  virtual ~OpenGLCanvasProvider() = default;
  void InitializeSurface(const size_t width, const size_t height) override {
    surface_size_ = SkISize::Make(width, height);

    gl_surface_ = std::make_unique<TestGLSurface>(surface_size_);
    gl_surface_->MakeCurrent();

    const auto image_info = SkImageInfo::MakeN32Premul(surface_size_);
    surface_ = SkSurface::MakeRenderTarget(
        gl_surface_->GetGrContext().get(), SkBudgeted::kNo, image_info, 1,
        kTopLeft_GrSurfaceOrigin, nullptr, false);
    surface_->getCanvas()->clear(SK_ColorTRANSPARENT);
  }

  sk_sp<SkSurface> GetSurface() override {
    if (!gl_surface_->MakeCurrent()) {
      return nullptr;
    }
    return surface_;
  }

  sk_sp<SkSurface> MakeOffscreenSurface(const size_t width,
                                        const size_t height) override {
    surface_size_ = SkISize::Make(width, height);
    const auto image_info = SkImageInfo::MakeN32Premul(surface_size_);

    auto offscreen_surface = SkSurface::MakeRenderTarget(
        gl_surface_->GetGrContext().get(), SkBudgeted::kNo, image_info, 1,
        kTopLeft_GrSurfaceOrigin, nullptr, false);

    offscreen_surface->getCanvas()->clear(SK_ColorTRANSPARENT);
    return offscreen_surface;
  }

  const std::string BackendName() override { return "OpenGL"; }

 private:
  SkISize surface_size_;
  sk_sp<SkSurface> surface_;
  std::unique_ptr<TestGLSurface> gl_surface_;
};

RUN_DISPLAYLIST_BENCHMARKS(OpenGL)

}  // namespace testing
}  // namespace flutter
