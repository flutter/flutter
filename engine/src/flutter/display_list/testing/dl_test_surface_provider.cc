// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/testing/dl_test_surface_provider.h"

namespace flutter::testing {

std::string DlSurfaceProvider::BackendName(BackendType type) {
  switch (type) {
    case BackendType::kSkiaSoftware:
      return "SkiaSoftware";
    case BackendType::kSkiaOpenGL:
      return "SkiaOpenGL";
    case BackendType::kSkiaMetal:
      return "SkiaMetal";
    case BackendType::kImpellerMetal:
      return "ImpellerMetal";
    case BackendType::kImpellerMetalSDF:
      return "ImpellerMetalSDF";
  }
}

std::unique_ptr<DlSurfaceProvider> DlSurfaceProvider::Create(
    BackendType backend_type) {
  switch (backend_type) {
    case BackendType::kSkiaSoftware:
      return CreateSkiaSoftware();
    case BackendType::kSkiaOpenGL:
      return CreateSkiaOpenGL();
    case BackendType::kSkiaMetal:
      return CreateSkiaMetal();
    case BackendType::kImpellerMetal:
      return CreateImpellerMetal();
    case BackendType::kImpellerMetalSDF:
      return CreateImpellerMetalSDF();
  }
}

#ifndef ENABLE_SOFTWARE_BENCHMARKS
std::unique_ptr<DlSurfaceProvider> DlSurfaceProvider::CreateSkiaSoftware() {
  return nullptr;
}
#endif
#ifndef ENABLE_OPENGL_BENCHMARKS
std::unique_ptr<DlSurfaceProvider> DlSurfaceProvider::CreateSkiaOpenGL() {
  return nullptr;
}
#endif
#ifndef ENABLE_METAL_BENCHMARKS
std::unique_ptr<DlSurfaceProvider> DlSurfaceProvider::CreateSkiaMetal() {
  return nullptr;
}
#endif
#ifndef IMPELLER_ENABLE_METAL
std::unique_ptr<DlSurfaceProvider> DlSurfaceProvider::CreateImpellerMetal() {
  return nullptr;
}
std::unique_ptr<DlSurfaceProvider> DlSurfaceProvider::CreateImpellerMetalSDF() {
  return nullptr;
}
#endif

}  // namespace flutter::testing
