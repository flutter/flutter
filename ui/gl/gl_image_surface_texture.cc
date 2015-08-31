// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_image_surface_texture.h"

#include "base/trace_event/trace_event.h"
#include "ui/gl/android/surface_texture.h"

namespace gfx {

GLImageSurfaceTexture::GLImageSurfaceTexture(const gfx::Size& size)
    : size_(size), texture_id_(0) {
}

GLImageSurfaceTexture::~GLImageSurfaceTexture() {
  DCHECK(!surface_texture_.get());
  DCHECK_EQ(0, texture_id_);
}

bool GLImageSurfaceTexture::Initialize(SurfaceTexture* surface_texture) {
  DCHECK(!surface_texture_.get());
  surface_texture_ = surface_texture;
  return true;
}

void GLImageSurfaceTexture::Destroy(bool have_context) {
  surface_texture_ = NULL;
  texture_id_ = 0;
}

gfx::Size GLImageSurfaceTexture::GetSize() { return size_; }

bool GLImageSurfaceTexture::BindTexImage(unsigned target) {
  TRACE_EVENT0("gpu", "GLImageSurfaceTexture::BindTexImage");

  if (target != GL_TEXTURE_EXTERNAL_OES) {
    LOG(ERROR)
        << "Surface texture can only be bound to TEXTURE_EXTERNAL_OES target";
    return false;
  }

  GLint texture_id;
  glGetIntegerv(GL_TEXTURE_BINDING_EXTERNAL_OES, &texture_id);
  DCHECK(texture_id);

  if (texture_id_ && texture_id_ != texture_id) {
    LOG(ERROR) << "Surface texture can only be bound to one texture ID";
    return false;
  }

  DCHECK(surface_texture_.get());
  if (texture_id != texture_id_) {
    // Note: Surface textures used as gpu memory buffers are created with an
    // initial dummy texture id of 0. We need to call DetachFromGLContext() here
    // to detach from the dummy texture before we can attach to a real texture
    // id. DetachFromGLContext() will delete the texture for the current
    // attachment point so it's important that this is never called when
    // attached to a real texture id. Detaching from the dummy texture id should
    // not cause any problems as the GL should silently ignore 0 when passed to
    // glDeleteTextures.
    DCHECK_EQ(0, texture_id_);
    surface_texture_->DetachFromGLContext();

    // This will attach the surface texture to the texture currently bound to
    // GL_TEXTURE_EXTERNAL_OES target.
    surface_texture_->AttachToGLContext();
    texture_id_ = texture_id;
  }

  surface_texture_->UpdateTexImage();
  return true;
}

bool GLImageSurfaceTexture::CopyTexImage(unsigned target) {
  return false;
}

bool GLImageSurfaceTexture::ScheduleOverlayPlane(gfx::AcceleratedWidget widget,
                                                 int z_order,
                                                 OverlayTransform transform,
                                                 const Rect& bounds_rect,
                                                 const RectF& crop_rect) {
  return false;
}

}  // namespace gfx
