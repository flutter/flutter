// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_benchmarks.h"
#include "flutter/testing/test_metal_surface.h"

#include "third_party/skia/include/core/SkCanvas.h"

namespace flutter {
namespace testing {

class MetalCanvasProvider : public CanvasProvider {
 public:
  virtual ~MetalCanvasProvider() = default;
  void InitializeSurface(const size_t width, const size_t height) override {
    metal_context_ = std::make_unique<TestMetalContext>();
    metal_surface_ =
        TestMetalSurface::Create(*metal_context_, SkISize::Make(width, height));
    metal_surface_->GetSurface()->getCanvas()->clear(SK_ColorTRANSPARENT);
  }

  sk_sp<SkSurface> GetSurface() override {
    if (!metal_surface_) {
      return nullptr;
    }
    return metal_surface_->GetSurface();
  }

  sk_sp<SkSurface> MakeOffscreenSurface(const size_t width,
                                        const size_t height) override {
    metal_offscreen_surface_ =
        TestMetalSurface::Create(*metal_context_, SkISize::Make(width, height));
    return metal_offscreen_surface_->GetSurface();
  }

  const std::string BackendName() override { return "Metal"; }

 private:
  std::unique_ptr<TestMetalContext> metal_context_;
  std::unique_ptr<TestMetalSurface> metal_surface_;
  std::unique_ptr<TestMetalSurface> metal_offscreen_surface_;
};

RUN_DISPLAYLIST_BENCHMARKS(Metal)

}  // namespace testing
}  // namespace flutter
