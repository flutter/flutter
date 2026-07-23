// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_TESTING_SKIA_DL_TEST_SURFACE_PROVIDER_SKIA_METAL_H_
#define FLUTTER_DISPLAY_LIST_TESTING_SKIA_DL_TEST_SURFACE_PROVIDER_SKIA_METAL_H_

#include "flutter/display_list/testing/dl_test_surface_provider.h"

#include "flutter/fml/platform/darwin/scoped_nsautorelease_pool.h"
#include "flutter/testing/test_metal_surface.h"

namespace flutter {
namespace testing {

class DlSurfaceProviderSkiaMetal : public DlSurfaceProvider {
 public:
  explicit DlSurfaceProviderSkiaMetal() : DlSurfaceProvider() {}
  virtual ~DlSurfaceProviderSkiaMetal() = default;

  bool InitializeSurface(size_t width,
                         size_t height,
                         PixelFormat format) override;
  std::shared_ptr<DlSurfaceInstance> GetPrimarySurface() const override;
  std::unique_ptr<DlSurfaceInstance> MakeOffscreenSurface(
      size_t width,
      size_t height,
      PixelFormat format) const override;
  const std::string GetBackendName() const override { return "SkiaMetal"; }
  BackendType GetBackendType() const override {
    return BackendType::kSkiaMetal;
  }
  bool SupportsPixelFormat(PixelFormat format) const override {
    return format == kN32Premul;
  }
  bool TargetsImpeller() const override { return false; }

 private:
  // This must be placed before any other members that may use the
  // autorelease pool.
  fml::ScopedNSAutoreleasePool autorelease_pool_;

  std::unique_ptr<TestMetalContext> metal_context_;
  std::shared_ptr<DlSurfaceInstance> metal_surface_;
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_TESTING_SKIA_DL_TEST_SURFACE_PROVIDER_SKIA_METAL_H_
