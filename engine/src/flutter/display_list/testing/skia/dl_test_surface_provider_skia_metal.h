// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_TESTING_SKIA_DL_TEST_SURFACE_PROVIDER_SKIA_METAL_H_
#define FLUTTER_DISPLAY_LIST_TESTING_SKIA_DL_TEST_SURFACE_PROVIDER_SKIA_METAL_H_

#include "flutter/display_list/testing/dl_test_surface_provider.h"

#include "flutter/fml/platform/darwin/scoped_nsautorelease_pool.h"
#include "flutter/impeller/golden_tests/metal_screenshotter.h"
#include "flutter/testing/test_metal_surface.h"

namespace flutter {
namespace testing {

using MetalScreenshotter = impeller::testing::MetalScreenshotter;

class DlSurfaceProviderSkiaMetal : public DlSurfaceProvider {
 public:
  explicit DlSurfaceProviderSkiaMetal(bool use_sdfs)
      : DlSurfaceProvider(), use_sdfs_(use_sdfs) {}
  virtual ~DlSurfaceProviderSkiaMetal() = default;

  bool InitializeSurface(size_t width,
                         size_t height,
                         PixelFormat format) override;
  std::shared_ptr<DlSurfaceInstance> GetPrimarySurface() const override;
  std::shared_ptr<DlSurfaceInstance> MakeOffscreenSurface(
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
  bool SupportsImpeller() const override { return true; }
  sk_sp<DlPixelData> ImpellerSnapshot(const sk_sp<DisplayList>& list,
                                      int width,
                                      int height) const override;
  virtual sk_sp<DlImage> MakeImpellerImage(const sk_sp<DisplayList>& list,
                                           int width,
                                           int height) const override;

 private:
  // This must be placed before any other members that may use the
  // autorelease pool.
  fml::ScopedNSAutoreleasePool autorelease_pool_;

  bool use_sdfs_;
  std::unique_ptr<TestMetalContext> metal_context_;
  std::shared_ptr<DlSurfaceInstance> metal_surface_;
  mutable std::unique_ptr<MetalScreenshotter> snapshotter_;
  mutable std::unique_ptr<impeller::AiksContext> aiks_context_;

  void InitScreenShotter() const;
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_TESTING_SKIA_DL_TEST_SURFACE_PROVIDER_SKIA_METAL_H_
