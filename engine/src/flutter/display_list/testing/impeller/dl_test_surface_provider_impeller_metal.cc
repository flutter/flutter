// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/testing/impeller/dl_test_surface_provider_impeller_metal.h"

#include "third_party/glfw/include/GLFW/glfw3.h"

namespace flutter {
namespace testing {

std::unique_ptr<DlSurfaceProvider> DlSurfaceProvider::CreateImpellerMetal() {
  return std::make_unique<DlSurfaceProviderImpellerMetal>();
}

std::unique_ptr<DlSurfaceProvider> DlSurfaceProvider::CreateImpellerMetalSDF() {
  return std::make_unique<DlSurfaceProviderImpellerMetalSDF>();
}

DlSurfaceProviderImpellerMetal::DlSurfaceProviderImpellerMetal()
    : DlSurfaceProviderImpeller() {}

std::unique_ptr<impeller::PlaygroundImpl>
    DlSurfaceProviderImpellerMetal::playground_;

DlSurfaceProviderImpellerMetalSDF::DlSurfaceProviderImpellerMetalSDF()
    : DlSurfaceProviderImpeller() {}

std::unique_ptr<impeller::PlaygroundImpl>
    DlSurfaceProviderImpellerMetalSDF::playground_;

impeller::PlaygroundImpl* DlSurfaceProviderImpellerMetal::GetPlayground()
    const {
  if (playground_ == nullptr) {
    FML_CHECK(::glfwInit() == GLFW_TRUE);
    playground_ = MakePlayground(impeller::PlaygroundBackend::kMetal);
  }
  return playground_.get();
}

impeller::PlaygroundImpl* DlSurfaceProviderImpellerMetalSDF::GetPlayground()
    const {
  if (playground_ == nullptr) {
    FML_CHECK(::glfwInit() == GLFW_TRUE);
    playground_ = MakePlayground(impeller::PlaygroundBackend::kMetalSDF);
  }
  return playground_.get();
}

const std::string DlSurfaceProviderImpellerMetal::GetBackendName() const {
  return "ImpellerMetal";
}

DlSurfaceProvider::BackendType DlSurfaceProviderImpellerMetal::GetBackendType()
    const {
  return BackendType::kImpellerMetal;
}

const std::string DlSurfaceProviderImpellerMetalSDF::GetBackendName() const {
  return "ImpellerMetalSDF";
}

DlSurfaceProvider::BackendType
DlSurfaceProviderImpellerMetalSDF::GetBackendType() const {
  return BackendType::kImpellerMetalSDF;
}

}  // namespace testing
}  // namespace flutter
