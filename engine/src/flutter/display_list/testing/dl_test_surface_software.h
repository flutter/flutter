// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_TESTING_DL_TEST_SURFACE_SOFTWARE_H_
#define FLUTTER_DISPLAY_LIST_TESTING_DL_TEST_SURFACE_SOFTWARE_H_

#include "flutter/display_list/testing/dl_test_surface_provider.h"

namespace flutter {
namespace testing {

class DlSoftwareSurfaceProvider : public DlSurfaceProvider {
 public:
  DlSoftwareSurfaceProvider() = default;
  virtual ~DlSoftwareSurfaceProvider() = default;

  bool InitializeSurface(size_t width,
                         size_t height,
                         PixelFormat format) override;
  std::shared_ptr<DlSurfaceInstance> GetPrimarySurface() const override {
    return primary_;
  }
  std::shared_ptr<DlSurfaceInstance> MakeOffscreenSurface(
      size_t width,
      size_t height,
      PixelFormat format) const override;
  const std::string backend_name() const override { return "Software"; }
  BackendType backend_type() const override { return kSoftwareBackend; }
  bool supports(PixelFormat format) const override { return true; }

 private:
  std::shared_ptr<DlSurfaceInstance> primary_;
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_TESTING_DL_TEST_SURFACE_SOFTWARE_H_
