// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_benchmarks.h"
#include "flutter/display_list/display_list_builder.h"
#include "third_party/skia/include/core/SkPoint.h"
#include "third_party/skia/include/core/SkTextBlob.h"

namespace flutter {
namespace testing {

class SoftwareCanvasProvider : public CanvasProvider {
 public:
  virtual ~SoftwareCanvasProvider() = default;
  void InitializeSurface(const size_t width, const size_t height) override {
    surface_ = SkSurface::MakeRasterN32Premul(width, height);
    surface_->getCanvas()->clear(SK_ColorTRANSPARENT);
  }

  sk_sp<SkSurface> GetSurface() override { return surface_; }

  sk_sp<SkSurface> MakeOffscreenSurface(const size_t width,
                                        const size_t height) override {
    auto surface = SkSurface::MakeRasterN32Premul(width, height);
    surface->getCanvas()->clear(SK_ColorTRANSPARENT);
    return surface;
  }

  const std::string BackendName() override { return "Software"; }

 private:
  sk_sp<SkSurface> surface_;
};

RUN_DISPLAYLIST_BENCHMARKS(Software)

}  // namespace testing
}  // namespace flutter
