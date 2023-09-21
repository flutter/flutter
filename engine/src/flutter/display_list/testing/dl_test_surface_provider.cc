// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/testing/dl_test_surface_provider.h"

#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkData.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/encode/SkPngEncoder.h"

#ifdef ENABLE_SOFTWARE_BENCHMARKS
#include "flutter/display_list/testing/dl_test_surface_software.h"
#endif
#ifdef ENABLE_OPENGL_BENCHMARKS
#include "flutter/display_list/testing/dl_test_surface_gl.h"
#endif
#ifdef ENABLE_METAL_BENCHMARKS
#include "flutter/display_list/testing/dl_test_surface_metal.h"
#endif

namespace flutter {
namespace testing {

std::unique_ptr<DlSurfaceProvider> DlSurfaceProvider::Create(
    BackendType backend_type) {
  switch (backend_type) {
#ifdef ENABLE_SOFTWARE_BENCHMARKS
    case kSoftwareBackend:
      return std::make_unique<DlSoftwareSurfaceProvider>();
#endif
#ifdef ENABLE_OPENGL_BENCHMARKS
    case kOpenGLBackend:
      return std::make_unique<DlOpenGLSurfaceProvider>();
#endif
#ifdef ENABLE_METAL_BENCHMARKS
    case kMetalBackend:
      return std::make_unique<DlMetalSurfaceProvider>();
#endif
    default:
      return nullptr;
  }

  return nullptr;
}

bool DlSurfaceProvider::Snapshot(std::string& filename) const {
#ifdef BENCHMARKS_NO_SNAPSHOT
  return false;
#else
  auto image = GetPrimarySurface()->sk_surface()->makeImageSnapshot();
  if (!image) {
    return false;
  }
  auto raster = image->makeRasterImage();
  if (!raster) {
    return false;
  }
  auto data = SkPngEncoder::Encode(nullptr, raster.get(), {});
  if (!data) {
    return false;
  }
  fml::NonOwnedMapping mapping(static_cast<const uint8_t*>(data->data()),
                               data->size());
  return WriteAtomically(OpenFixturesDirectory(), filename.c_str(), mapping);
#endif
}

}  // namespace testing
}  // namespace flutter
