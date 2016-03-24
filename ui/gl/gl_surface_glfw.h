// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GL_SURFACE_GLFW_H_
#define UI_GL_GL_SURFACE_GLFW_H_

#include "ui/gl/gl_surface.h"

namespace gfx {

class GL_EXPORT GLSurfaceGlfw : public GLSurface {
 public:
  GLSurfaceGlfw(gfx::AcceleratedWidget widget,
                const gfx::SurfaceConfiguration requested_configuration);

  static bool InitializeOneOff();

  static bool HasExtension(const char* name);
  static bool IsCreateContextRobustnessSupported();

  bool SwapBuffers() override;
  void Destroy() override;
  bool IsOffscreen() override;
  gfx::Size GetSize() override;
  void* GetHandle() override;
  bool Resize(const gfx::Size& size) override;
  bool OnMakeCurrent(GLContext* context) override;

 private:
  ~GLSurfaceGlfw() override;

  gfx::AcceleratedWidget widget_;

  DISALLOW_COPY_AND_ASSIGN(GLSurfaceGlfw);
};

}  // namespace gfx

#endif  // UI_GL_GL_SURFACE_GLFW_H_
