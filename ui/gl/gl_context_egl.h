// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GL_CONTEXT_EGL_H_
#define UI_GL_GL_CONTEXT_EGL_H_

#include <string>

#include "base/compiler_specific.h"
#include "ui/gl/gl_context.h"

typedef void* EGLContext;
typedef void* EGLDisplay;
typedef void* EGLConfig;

namespace gfx {

class GLSurface;

// Encapsulates an EGL OpenGL ES context.
class GLContextEGL : public GLContextReal {
 public:
  explicit GLContextEGL(GLShareGroup* share_group);

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
  ~GLContextEGL() override;

 private:
  EGLContext context_;
  EGLDisplay display_;
  EGLConfig config_;
  bool unbind_fbo_on_makecurrent_;
  int swap_interval_;

  DISALLOW_COPY_AND_ASSIGN(GLContextEGL);
};

}  // namespace gfx

#endif  // UI_GL_GL_CONTEXT_EGL_H_
