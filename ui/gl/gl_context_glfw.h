// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GL_CONTEXT_GLFW_H_
#define UI_GL_GL_CONTEXT_GLFW_H_

#include <string>

#include "base/compiler_specific.h"
#include "ui/gl/gl_context.h"
#include "ui/gfx/native_widget_types.h"

typedef void* EGLContext;
typedef void* EGLDisplay;
typedef void* EGLConfig;

namespace gfx {

class GLSurface;

// Presents a GLFW window as a GLContext.
class GLContextGlfw : public GLContextReal {
 public:
  explicit GLContextGlfw(GLShareGroup* share_group);


  // Implement GLContext.
  bool Initialize(GLSurface* compatible_surface,
                  GpuPreference gpu_preference) override;
  void Destroy() override;
  bool MakeCurrent(GLSurface* surface) override;
  void ReleaseCurrent(GLSurface* surface) override;
  bool IsCurrent(GLSurface* surface) override;
  void* GetHandle() override;
  void OnSetSwapInterval(int interval) override;
  std::string GetExtensions() override;
  bool WasAllocatedUsingRobustnessExtension() override;
  bool GetTotalGpuMemory(size_t* bytes) override;
  void SetUnbindFboOnMakeCurrent() override;

 protected:
  ~GLContextGlfw() override;

 private:
  GLSurface* surface_;
  gfx::AcceleratedWidget context_;
  bool unbind_fbo_on_makecurrent_;
  int swap_interval_;

  DISALLOW_COPY_AND_ASSIGN(GLContextGlfw);
};

}  // namespace gfx

#endif  // UI_GL_GL_CONTEXT_EGL_H_
