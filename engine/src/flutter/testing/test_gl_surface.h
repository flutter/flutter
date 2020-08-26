// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TESTING_TEST_GL_SURFACE_H_
#define FLUTTER_TESTING_TEST_GL_SURFACE_H_

#include <cstdint>

#include "flutter/fml/macros.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"

namespace flutter {
namespace testing {

class TestGLSurface {
 public:
  TestGLSurface(SkISize surface_size);

  ~TestGLSurface();

  const SkISize& GetSurfaceSize() const;

  bool MakeCurrent();

  bool ClearCurrent();

  bool Present();

  uint32_t GetFramebuffer(uint32_t width, uint32_t height) const;

  bool MakeResourceCurrent();

  void* GetProcAddress(const char* name) const;

  sk_sp<SkSurface> GetOnscreenSurface();

  sk_sp<GrDirectContext> GetGrContext();

  sk_sp<GrDirectContext> CreateGrContext();

  sk_sp<SkImage> GetRasterSurfaceSnapshot();

  uint32_t GetWindowFBOId() const;

 private:
  // Importing the EGL.h pulls in platform headers which are problematic
  // (especially X11 which #defineds types like Bool). Any TUs importing
  // this header then become susceptible to failures because of platform
  // specific craziness. Don't expose EGL internals via this header.
  using EGLDisplay = void*;
  using EGLContext = void*;
  using EGLSurface = void*;

  const SkISize surface_size_;
  EGLDisplay display_;
  EGLContext onscreen_context_;
  EGLContext offscreen_context_;
  EGLSurface onscreen_surface_;
  EGLSurface offscreen_surface_;
  sk_sp<GrDirectContext> context_;

  FML_DISALLOW_COPY_AND_ASSIGN(TestGLSurface);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_TESTING_TEST_GL_SURFACE_H_
