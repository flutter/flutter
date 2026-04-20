// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/testing/impeller/dl_test_surface_provider_impeller.h"

namespace flutter {
namespace testing {

DlSurfaceProviderImpeller::DlSurfaceProviderImpeller() : DlSurfaceProvider() {}

std::unique_ptr<impeller::PlaygroundImpl>
DlSurfaceProviderImpeller::MakePlayground(impeller::PlaygroundBackend backend) {
  impeller::PlaygroundSwitches switches;
  return impeller::PlaygroundImpl::Create(backend, switches);
}

bool DlSurfaceProviderImpeller::InitializeSurface(size_t width,
                                                  size_t height,
                                                  PixelFormat format) {
  if (primary_ == nullptr) {
    impeller::PlaygroundImpl* playground = GetPlayground();
    std::shared_ptr<impeller::Context> context = playground->GetContext();
    std::shared_ptr<impeller::Surface> surface =
        playground->AcquireSurfaceFrame(context);
    primary_ = std::make_shared<DlSurfaceInstanceImpeller>(std::move(context),
                                                           surface);
  }
  return true;
}

std::shared_ptr<DlSurfaceInstance>
DlSurfaceProviderImpeller::GetPrimarySurface() const {
  return primary_;
}

std::shared_ptr<DlSurfaceInstance>
DlSurfaceProviderImpeller::MakeOffscreenSurface(size_t width,
                                                size_t height,
                                                PixelFormat format) const {
  DlISize size(width, height);
  return std::make_shared<DlSurfaceInstanceImpeller>(nullptr, nullptr);
}

bool DlSurfaceProviderImpeller::supports(PixelFormat format) const {
  return format == kN32Premul;
}

bool DlSurfaceProviderImpeller::supports_impeller() const {
  return true;
}

}  // namespace testing
}  // namespace flutter
