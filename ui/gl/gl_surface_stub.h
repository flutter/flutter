// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GL_SURFACE_STUB_H_
#define UI_GL_GL_SURFACE_STUB_H_

#include "ui/gl/gl_surface.h"

namespace gfx {

// A GLSurface that does nothing for unit tests.
class GL_EXPORT GLSurfaceStub : public GLSurface {
 public:
  explicit GLSurfaceStub(
    const gfx::SurfaceConfiguration requested_configuration);

  void SetSize(const gfx::Size& size) { size_ = size; }

  // Implement GLSurface.
  void Destroy() override;
  bool IsOffscreen() override;
  bool SwapBuffers() override;
  gfx::Size GetSize() override;
  void* GetHandle() override;

 protected:
  ~GLSurfaceStub() override;

 private:
  gfx::Size size_;
};

}  // namespace gfx

#endif  // UI_GL_GL_SURFACE_STUB_H_
