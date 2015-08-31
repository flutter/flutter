// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

extern "C" {
#include <X11/Xlib.h>
}

#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_image_glx.h"
#include "ui/gl/gl_surface_glx.h"

namespace gfx {

namespace {

bool ValidFormat(unsigned internalformat) {
  switch (internalformat) {
    case GL_RGB:
    case GL_RGBA:
      return true;
    default:
      return false;
  }
}

int TextureFormat(unsigned internalformat) {
  switch (internalformat) {
    case GL_RGB:
      return GLX_TEXTURE_FORMAT_RGB_EXT;
    case GL_RGBA:
      return GLX_TEXTURE_FORMAT_RGBA_EXT;
    default:
      NOTREACHED();
      return 0;
  }
}

int BindToTextureFormat(unsigned internalformat) {
  switch (internalformat) {
    case GL_RGB:
      return GLX_BIND_TO_TEXTURE_RGB_EXT;
    case GL_RGBA:
      return GLX_BIND_TO_TEXTURE_RGBA_EXT;
    default:
      NOTREACHED();
      return 0;
  }
}

unsigned PixmapDepth(unsigned internalformat) {
  switch (internalformat) {
    case GL_RGBA:
      return 32u;
    case GL_RGB:
      return 24u;
    default:
      NOTREACHED();
      return 0u;
  }
}

bool ActualPixmapGeometry(XID pixmap, gfx::Size* size, unsigned* depth) {
  XID root_return;
  int x_return;
  int y_return;
  unsigned width_return;
  unsigned height_return;
  unsigned border_width_return;
  unsigned depth_return;
  if (!XGetGeometry(gfx::GetXDisplay(),
                    pixmap,
                    &root_return,
                    &x_return,
                    &y_return,
                    &width_return,
                    &height_return,
                    &border_width_return,
                    &depth_return))
    return false;

  if (size)
    *size = gfx::Size(width_return, height_return);
  if (depth)
    *depth = depth_return;
  return true;
}

unsigned ActualPixmapDepth(XID pixmap) {
  unsigned depth;
  if (!ActualPixmapGeometry(pixmap, NULL, &depth))
    return -1;

  return depth;
}

gfx::Size ActualPixmapSize(XID pixmap) {
  gfx::Size size;
  if (!ActualPixmapGeometry(pixmap, &size, NULL))
    return gfx::Size();

  return size;
}

}  // namespace anonymous

GLImageGLX::GLImageGLX(const gfx::Size& size, unsigned internalformat)
    : glx_pixmap_(0), size_(size), internalformat_(internalformat) {
}

GLImageGLX::~GLImageGLX() {
  DCHECK_EQ(0u, glx_pixmap_);
}

bool GLImageGLX::Initialize(XID pixmap) {
  if (!GLSurfaceGLX::IsTextureFromPixmapSupported()) {
    DVLOG(0) << "GLX_EXT_texture_from_pixmap not supported.";
    return false;
  }

  if (!ValidFormat(internalformat_)) {
    DVLOG(0) << "Invalid format: " << internalformat_;
    return false;
  }

  DCHECK_EQ(PixmapDepth(internalformat_), ActualPixmapDepth(pixmap));
  DCHECK_EQ(size_.ToString(), ActualPixmapSize(pixmap).ToString());

  int config_attribs[] = {
      GLX_DRAWABLE_TYPE,                    GLX_PIXMAP_BIT,
      GLX_BIND_TO_TEXTURE_TARGETS_EXT,      GLX_TEXTURE_2D_EXT,
      BindToTextureFormat(internalformat_), GL_TRUE,
      0};
  int num_elements = 0;
  gfx::XScopedPtr<GLXFBConfig> config(
      glXChooseFBConfig(gfx::GetXDisplay(), DefaultScreen(gfx::GetXDisplay()),
                        config_attribs, &num_elements));
  if (!config.get()) {
    DVLOG(0) << "glXChooseFBConfig failed.";
    return false;
  }
  if (!num_elements) {
    DVLOG(0) << "glXChooseFBConfig returned 0 elements.";
    return false;
  }

  int pixmap_attribs[] = {GLX_TEXTURE_TARGET_EXT, GLX_TEXTURE_2D_EXT,
                          GLX_TEXTURE_FORMAT_EXT,
                          TextureFormat(internalformat_), 0};
  glx_pixmap_ = glXCreatePixmap(
      gfx::GetXDisplay(), *config.get(), pixmap, pixmap_attribs);
  if (!glx_pixmap_) {
    DVLOG(0) << "glXCreatePixmap failed.";
    return false;
  }

  return true;
}

void GLImageGLX::Destroy(bool have_context) {
  if (glx_pixmap_) {
    glXDestroyGLXPixmap(gfx::GetXDisplay(), glx_pixmap_);
    glx_pixmap_ = 0;
  }
}

gfx::Size GLImageGLX::GetSize() { return size_; }

bool GLImageGLX::BindTexImage(unsigned target) {
  if (!glx_pixmap_)
    return false;

  // Requires TEXTURE_2D target.
  if (target != GL_TEXTURE_2D)
    return false;

  glXBindTexImageEXT(gfx::GetXDisplay(), glx_pixmap_, GLX_FRONT_LEFT_EXT, 0);
  return true;
}

void GLImageGLX::ReleaseTexImage(unsigned target) {
  DCHECK_NE(0u, glx_pixmap_);
  DCHECK_EQ(static_cast<GLenum>(GL_TEXTURE_2D), target);

  glXReleaseTexImageEXT(gfx::GetXDisplay(), glx_pixmap_, GLX_FRONT_LEFT_EXT);
}

bool GLImageGLX::CopyTexImage(unsigned target) {
  return false;
}

bool GLImageGLX::ScheduleOverlayPlane(gfx::AcceleratedWidget widget,
                                      int z_order,
                                      OverlayTransform transform,
                                      const Rect& bounds_rect,
                                      const RectF& crop_rect) {
  return false;
}

}  // namespace gfx
