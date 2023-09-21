// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/testing/dl_test_surface_metal.h"

#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {
namespace testing {

class DlMetalSurfaceInstance : public DlSurfaceInstance {
 public:
  explicit DlMetalSurfaceInstance(
      std::unique_ptr<TestMetalSurface> metal_surface)
      : metal_surface_(std::move(metal_surface)) {}
  ~DlMetalSurfaceInstance() = default;

  sk_sp<SkSurface> sk_surface() const override {
    return metal_surface_->GetSurface();
  }

 private:
  std::unique_ptr<TestMetalSurface> metal_surface_;
};

bool DlMetalSurfaceProvider::InitializeSurface(size_t width,
                                               size_t height,
                                               PixelFormat format) {
  if (format != kN32PremulPixelFormat) {
    return false;
  }
  metal_context_ = std::make_unique<TestMetalContext>();
  metal_surface_ = MakeOffscreenSurface(width, height, format);
  return true;
}

std::shared_ptr<DlSurfaceInstance> DlMetalSurfaceProvider::GetPrimarySurface()
    const {
  if (!metal_surface_) {
    return nullptr;
  }
  return metal_surface_;
}

std::shared_ptr<DlSurfaceInstance> DlMetalSurfaceProvider::MakeOffscreenSurface(
    size_t width,
    size_t height,
    PixelFormat format) const {
  auto surface =
      TestMetalSurface::Create(*metal_context_, SkISize::Make(width, height));
  surface->GetSurface()->getCanvas()->clear(SK_ColorTRANSPARENT);
  return std::make_shared<DlMetalSurfaceInstance>(std::move(surface));
}

}  // namespace testing
}  // namespace flutter
