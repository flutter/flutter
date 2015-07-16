// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GL_CONTEXT_STUB_H_
#define UI_GL_GL_CONTEXT_STUB_H_

#include "ui/gl/gl_context.h"

namespace gfx {

// A GLContext that does nothing for unit tests.
class GL_EXPORT GLContextStub : public GLContextReal {
 public:
  GLContextStub();

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
  std::string GetGLRenderer() override;

 protected:
  ~GLContextStub() override;

 private:
  DISALLOW_COPY_AND_ASSIGN(GLContextStub);
};

}  // namespace gfx

#endif  // UI_GL_GL_CONTEXT_STUB_H_
