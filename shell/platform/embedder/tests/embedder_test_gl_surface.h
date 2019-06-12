// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_GL_SURFACE_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_GL_SURFACE_H_

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

class EmbedderTestGLSurface {
 public:
  EmbedderTestGLSurface();

  ~EmbedderTestGLSurface();

  bool MakeCurrent();

  bool ClearCurrent();

  bool Present();

  uint32_t GetFramebuffer();

  bool MakeResourceCurrent();

  void* GetProcAddress(const char* name);

 private:
  // Importing the EGL.h pulls in platform headers which are problematic
  // (especially X11 which #defineds types like Bool). Any TUs importing this
  // header then become susceptible to failures because of platform specific
  // craziness. Don't expose EGL internals via this header.
  using EGLDisplay = void*;
  using EGLContext = void*;
  using EGLSurface = void*;

  EGLDisplay display_;
  EGLContext onscreen_context_;
  EGLContext offscreen_context_;
  EGLSurface onscreen_surface_;
  EGLSurface offscreen_surface_;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderTestGLSurface);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_GL_SURFACE_H_
