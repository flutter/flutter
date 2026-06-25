// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_TESTING_IMPELLER_DL_TEST_SURFACE_PROVIDER_IMPELLER_METAL_H_
#define FLUTTER_DISPLAY_LIST_TESTING_IMPELLER_DL_TEST_SURFACE_PROVIDER_IMPELLER_METAL_H_

#include "flutter/display_list/testing/dl_test_surface_provider.h"

#include "flutter/display_list/testing/impeller/dl_test_surface_instance_impeller.h"
#include "flutter/display_list/testing/impeller/dl_test_surface_provider_impeller.h"

namespace flutter {
namespace testing {

class DlSurfaceProviderImpellerMetal : public DlSurfaceProviderImpeller {
 public:
  DlSurfaceProviderImpellerMetal();

  const std::string GetBackendName() const override;
  BackendType GetBackendType() const override;

 protected:
  impeller::PlaygroundImpl* GetPlayground() const override;

 private:
  static std::unique_ptr<impeller::PlaygroundImpl> playground_;
};

class DlSurfaceProviderImpellerMetalSDF : public DlSurfaceProviderImpeller {
 public:
  DlSurfaceProviderImpellerMetalSDF();

  const std::string GetBackendName() const override;
  BackendType GetBackendType() const override;

 protected:
  impeller::PlaygroundImpl* GetPlayground() const override;

 private:
  static std::unique_ptr<impeller::PlaygroundImpl> playground_;
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_TESTING_IMPELLER_DL_TEST_SURFACE_PROVIDER_IMPELLER_METAL_H_
