// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_surface_glfw.h"

#include <GLFW/glfw3.h>

#include "ui/gl/gl_context.h"
#include "ui/gl/gl_enums.h"
#include "base/logging.h"

#define WIDGET_AS_VIEW (reinterpret_cast<NSOpenGLView*>(widget_))

namespace gfx {

GLSurfaceGlfw::GLSurfaceGlfw(gfx::AcceleratedWidget widget,
                     const gfx::SurfaceConfiguration requested_configuration)
    : GLSurface(requested_configuration),
      widget_(widget) {
}

GLSurfaceGlfw::~GLSurfaceGlfw() {
  Destroy();
}

bool GLSurfaceGlfw::OnMakeCurrent(GLContext* context) {
  // The actual "make current" is done in the context.
  return true;
}

bool GLSurfaceGlfw::SwapBuffers() {
  glfwSwapBuffers(widget_);
  return true;
}

void GLSurfaceGlfw::Destroy() {
  DCHECK(false);
}

bool GLSurfaceGlfw::IsOffscreen() {
  return false;
}

gfx::Size GLSurfaceGlfw::GetSize() {
  int width;
  int height;
  glfwGetWindowSize(widget_, &width, &height);
  return Size(width, height);
}

void* GLSurfaceGlfw::GetHandle() {
  return (void*)widget_;
}

bool GLSurfaceGlfw::Resize(const gfx::Size& size) {
  return true;
}

bool GLSurface::InitializeOneOffInternal() {
  if (!GLSurfaceGlfw::InitializeOneOff()) {
    LOG(ERROR) << "GLSurfaceGlfw::InitializeOneOff failed.";
    return false;
  }
  return true;
}

// static
bool GLSurfaceGlfw::InitializeOneOff() {
  return true;
}

// static
scoped_refptr<GLSurface> GLSurface::CreateViewGLSurface(
      gfx::AcceleratedWidget window,
      const gfx::SurfaceConfiguration& requested_configuration) {
  DCHECK(window != kNullAcceleratedWidget);
  scoped_refptr<GLSurfaceGlfw> surface =
    new GLSurfaceGlfw(window, requested_configuration);

  if (!surface->Initialize())
    return NULL;

  return surface;
}

}  // namespace gfx
