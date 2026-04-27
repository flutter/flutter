// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_TESTING_IMPELLER_DL_TEST_SURFACE_PROVIDER_IMPELLER_H_
#define FLUTTER_DISPLAY_LIST_TESTING_IMPELLER_DL_TEST_SURFACE_PROVIDER_IMPELLER_H_

#include "flutter/display_list/testing/dl_test_surface_provider.h"

#include "flutter/display_list/testing/impeller/dl_test_surface_instance_impeller.h"

namespace flutter {
namespace testing {

class DlSurfaceProviderImpeller : public DlSurfaceProvider {
 public:
  virtual ~DlSurfaceProviderImpeller() = default;

  bool InitializeSurface(size_t width,
                         size_t height,
                         PixelFormat format) override;
  std::shared_ptr<DlSurfaceInstance> GetPrimarySurface() const override;
  std::shared_ptr<DlSurfaceInstance> MakeOffscreenSurface(
      size_t width,
      size_t height,
      PixelFormat format) const override;
  bool SupportsPixelFormat(PixelFormat format) const override;
  bool SupportsImpeller() const override;

 protected:
  DlSurfaceProviderImpeller();

  virtual impeller::PlaygroundImpl* GetPlayground() const = 0;

  static std::unique_ptr<impeller::PlaygroundImpl> MakePlayground(
      impeller::PlaygroundBackend backend);

 private:
  std::shared_ptr<DlSurfaceInstance> primary_;
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_TESTING_IMPELLER_DL_TEST_SURFACE_PROVIDER_IMPELLER_H_
