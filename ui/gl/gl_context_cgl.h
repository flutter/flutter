// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GL_CONTEXT_CGL_H_
#define UI_GL_GL_CONTEXT_CGL_H_

#include <OpenGL/CGLTypes.h>

#include "ui/gl/gl_context.h"

namespace gfx {

class GLSurface;

// Encapsulates a CGL OpenGL context.
class GLContextCGL : public GLContextReal {
 public:
  explicit GLContextCGL(GLShareGroup* share_group);

  // Implement GLContext.
  bool Initialize(GLSurface* compatible_surface,
                  GpuPreference gpu_preference) override;
  void Destroy() override;
  bool MakeCurrent(GLSurface* surface) override;
  void ReleaseCurrent(GLSurface* surface) override;
  bool IsCurrent(GLSurface* surface) override;
  void* GetHandle() override;
  void OnSetSwapInterval(int interval) override;
  bool GetTotalGpuMemory(size_t* bytes) override;
  void SetSafeToForceGpuSwitch() override;
  bool ForceGpuSwitchIfNeeded() override;

 protected:
  ~GLContextCGL() override;

 private:
  GpuPreference GetGpuPreference();

  void* context_;
  GpuPreference gpu_preference_;

  CGLPixelFormatObj discrete_pixelformat_;

  int screen_;
  int renderer_id_;
  bool safe_to_force_gpu_switch_;

  DISALLOW_COPY_AND_ASSIGN(GLContextCGL);
};

}  // namespace gfx

#endif  // UI_GL_GL_CONTEXT_CGL_H_
