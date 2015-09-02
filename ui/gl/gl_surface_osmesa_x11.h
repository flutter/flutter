// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GL_SURFACE_OSMESA_X11_H_
#define UI_GL_GL_SURFACE_OSMESA_X11_H_

#include <EGL/eglplatform.h>

#include "ui/gfx/native_widget_types.h"
#include "ui/gfx/x/x11_types.h"
#include "ui/gl/gl_surface.h"
#include "ui/gl/gl_surface_osmesa.h"

namespace gfx {

// This OSMesa GL surface can use XLib to swap the contents of the buffer to a
// view.
class NativeViewGLSurfaceOSMesa : public GLSurfaceOSMesa {
 public:
  NativeViewGLSurfaceOSMesa(
      AcceleratedWidget window,
      const SurfaceConfiguration& requested_configuration);

  static bool InitializeOneOff();

  // Implement a subset of GLSurface.
  bool Initialize() override;
  void Destroy() override;
  bool Resize(const Size& new_size) override;
  bool IsOffscreen() override;
  bool SwapBuffers() override;
  bool SupportsPostSubBuffer() override;
  bool PostSubBuffer(int x, int y, int width, int height) override;

 protected:
  ~NativeViewGLSurfaceOSMesa() override;

 private:
  XDisplay* xdisplay_;
  GC window_graphics_context_;
  AcceleratedWidget window_;
  GC pixmap_graphics_context_;
  EGLNativePixmapType pixmap_;

  DISALLOW_COPY_AND_ASSIGN(NativeViewGLSurfaceOSMesa);
};

}  // namespace gfx

#endif  // UI_GL_GL_SURFACE_OSMESA_X11_H_
