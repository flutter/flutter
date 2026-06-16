// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_TESTING_DL_TEST_SURFACE_GL_H_
#define FLUTTER_DISPLAY_LIST_TESTING_DL_TEST_SURFACE_GL_H_

#include "flutter/display_list/testing/dl_test_surface_provider.h"

#include "flutter/testing/test_gl_surface.h"

namespace flutter {
namespace testing {

class DlOpenGLSurfaceProvider : public DlSurfaceProvider {
 public:
  DlOpenGLSurfaceProvider() : DlSurfaceProvider() {}
  virtual ~DlOpenGLSurfaceProvider() = default;

  bool InitializeSurface(size_t width,
                         size_t height,
                         PixelFormat format) override;
  std::shared_ptr<DlSurfaceInstance> GetPrimarySurface() const override;
  std::shared_ptr<DlSurfaceInstance> MakeOffscreenSurface(
      size_t width,
      size_t height,
      PixelFormat format) const override;
  const std::string GetBackendName() const override { return "OpenGL"; }
  BackendType GetBackendType() const override {
    return BackendType::kSkiaOpenGL;
  }
  bool SupportsPixelFormat(PixelFormat format) const override {
    return format == kN32Premul;
  }

 private:
  std::shared_ptr<DlSurfaceInstance> primary_;
  std::unique_ptr<TestGLSurface> gl_surface_;
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_TESTING_DL_TEST_SURFACE_GL_H_
