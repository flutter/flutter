// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/testing/skia/dl_test_surface_provider_skia_metal.h"

#include "flutter/display_list/testing/skia/dl_test_surface_instance_skia.h"
#include "flutter/impeller/display_list/dl_dispatcher.h"
#include "flutter/impeller/display_list/dl_image_impeller.h"
#include "flutter/impeller/typographer/backends/skia/typographer_context_skia.h"

#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {
namespace testing {

std::unique_ptr<DlSurfaceProvider> DlSurfaceProvider::CreateSkiaMetal() {
  return std::make_unique<DlSurfaceProviderSkiaMetal>();
}

class DlMetalSurfaceInstance : public DlSurfaceInstanceSkiaBase {
 public:
  explicit DlMetalSurfaceInstance(std::unique_ptr<TestMetalSurface> metal_surface)
      : DlSurfaceInstanceSkiaBase(), metal_surface_(std::move(metal_surface)) {}
  ~DlMetalSurfaceInstance() = default;

 protected:
  sk_sp<SkSurface> GetSurface() const override { return metal_surface_->GetSurface(); }

 private:
  std::unique_ptr<TestMetalSurface> metal_surface_;
};

bool DlSurfaceProviderSkiaMetal::InitializeSurface(size_t width,
                                                   size_t height,
                                                   PixelFormat format) {
  if (format != kN32Premul) {
    return false;
  }
  metal_context_ = std::make_unique<TestMetalContext>();
  metal_surface_ = MakeOffscreenSurface(width, height, format);
  return true;
}

std::shared_ptr<DlSurfaceInstance> DlSurfaceProviderSkiaMetal::GetPrimarySurface() const {
  if (!metal_surface_) {
    return nullptr;
  }
  return metal_surface_;
}

std::unique_ptr<DlSurfaceInstance> DlSurfaceProviderSkiaMetal::MakeOffscreenSurface(
    size_t width,
    size_t height,
    PixelFormat format) const {
  auto surface = TestMetalSurface::Create(*metal_context_, DlISize(width, height));
  surface->GetSurface()->getCanvas()->clear(SK_ColorTRANSPARENT);
  return std::make_unique<DlMetalSurfaceInstance>(std::move(surface));
}

}  // namespace testing
}  // namespace flutter
