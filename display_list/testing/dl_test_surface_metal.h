// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_TESTING_DL_TEST_SURFACE_METAL_H_
#define FLUTTER_DISPLAY_LIST_TESTING_DL_TEST_SURFACE_METAL_H_

#include "flutter/display_list/testing/dl_test_surface_provider.h"

#include "flutter/testing/test_metal_surface.h"

namespace flutter {
namespace testing {

class DlMetalSurfaceProvider : public DlSurfaceProvider {
 public:
  explicit DlMetalSurfaceProvider() : DlSurfaceProvider() {}
  virtual ~DlMetalSurfaceProvider() = default;

  bool InitializeSurface(size_t width,
                         size_t height,
                         PixelFormat format) override;
  std::shared_ptr<DlSurfaceInstance> GetPrimarySurface() const override;
  std::shared_ptr<DlSurfaceInstance> MakeOffscreenSurface(
      size_t width,
      size_t height,
      PixelFormat format) const override;
  const std::string backend_name() const override { return "Metal"; }
  BackendType backend_type() const override { return kMetalBackend; }
  bool supports(PixelFormat format) const override {
    return format == kN32PremulPixelFormat;
  }

 private:
  std::unique_ptr<TestMetalContext> metal_context_;
  std::shared_ptr<DlSurfaceInstance> metal_surface_;
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_TESTING_DL_TEST_SURFACE_METAL_H_
