// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_image_egl.h"

#include "ui/gl/gl_surface_egl.h"

namespace gfx {

GLImageEGL::GLImageEGL(const gfx::Size& size)
    : egl_image_(EGL_NO_IMAGE_KHR), size_(size) {
}

GLImageEGL::~GLImageEGL() {
  DCHECK_EQ(EGL_NO_IMAGE_KHR, egl_image_);
}

bool GLImageEGL::Initialize(EGLenum target,
                            EGLClientBuffer buffer,
                            const EGLint* attrs) {
  DCHECK_EQ(EGL_NO_IMAGE_KHR, egl_image_);
  egl_image_ = eglCreateImageKHR(GLSurfaceEGL::GetHardwareDisplay(),
                                 EGL_NO_CONTEXT,
                                 target,
                                 buffer,
                                 attrs);
  if (egl_image_ == EGL_NO_IMAGE_KHR) {
    EGLint error = eglGetError();
    LOG(ERROR) << "Error creating EGLImage: " << error;
    return false;
  }

  return true;
}

void GLImageEGL::Destroy(bool have_context) {
  if (egl_image_ != EGL_NO_IMAGE_KHR) {
    eglDestroyImageKHR(GLSurfaceEGL::GetHardwareDisplay(), egl_image_);
    egl_image_ = EGL_NO_IMAGE_KHR;
  }
}

gfx::Size GLImageEGL::GetSize() { return size_; }

bool GLImageEGL::BindTexImage(unsigned target) {
  DCHECK_NE(EGL_NO_IMAGE_KHR, egl_image_);
  glEGLImageTargetTexture2DOES(target, egl_image_);
  DCHECK_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());
  return true;
}

bool GLImageEGL::CopyTexImage(unsigned target) {
  return false;
}

bool GLImageEGL::ScheduleOverlayPlane(gfx::AcceleratedWidget widget,
                                      int z_order,
                                      OverlayTransform transform,
                                      const Rect& bounds_rect,
                                      const RectF& crop_rect) {
  return false;
}

}  // namespace gfx
