// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_surface_mac.h"

#include "base/mac/scoped_nsautorelease_pool.h"
#include "ui/gl/gl_context.h"
#include "ui/gl/gl_enums.h"
#include "base/logging.h"

namespace gfx {

GLSurfaceMac::GLSurfaceMac(gfx::AcceleratedWidget widget,
                     const gfx::SurfaceConfiguration requested_configuration)
    : GLSurface(requested_configuration),
      widget_(widget) {
}

GLSurfaceMac::~GLSurfaceMac() {
  Destroy();
}

bool GLSurfaceMac::OnMakeCurrent(GLContext* context) {
  DCHECK(false);
  return false;
}

bool GLSurfaceMac::SwapBuffers() {
  DCHECK(false);
  return false;
}

void GLSurfaceMac::Destroy() {
  DCHECK(false);
}

bool GLSurfaceMac::IsOffscreen() {
  DCHECK(false);
  return false;
}

gfx::Size GLSurfaceMac::GetSize() {
  DCHECK(false);
  return Size(0.0, 0.0);
}

void* GLSurfaceMac::GetHandle() {
  return (void*)widget_;
}

bool GLSurface::InitializeOneOffInternal() {
  // On EGL, this method is used to perfom one-time initialization tasks like
  // initializing the display, setting up config lists, etc. There is no such
  // setup on Mac.
  return true;
}

// static
scoped_refptr<GLSurface> GLSurface::CreateViewGLSurface(
      gfx::AcceleratedWidget window,
      const gfx::SurfaceConfiguration& requested_configuration) {
  DCHECK(window != kNullAcceleratedWidget);
  scoped_refptr<GLSurfaceMac> surface =
    new GLSurfaceMac(window, requested_configuration);

  if (!surface->Initialize())
    return NULL;

  return surface;
}

}  // namespace gfx
