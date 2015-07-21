// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_surface.h"

namespace gfx {

class GL_EXPORT GLSurfaceMac : public GLSurface {
 public:
  GLSurfaceMac(gfx::AcceleratedWidget widget,
               const gfx::SurfaceConfiguration requested_configuration);

  bool SwapBuffers() override;
  void Destroy() override;
  bool IsOffscreen() override;
  gfx::Size GetSize() override;
  void* GetHandle() override;
  bool OnMakeCurrent(GLContext* context) override;
  
 private:
  ~GLSurfaceMac() override;
  
  gfx::AcceleratedWidget widget_;
  
  DISALLOW_COPY_AND_ASSIGN(GLSurfaceMac);
};

}  // namespace gfx
