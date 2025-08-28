// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_framebuffer.h"

#include <epoxy/egl.h>
#include <epoxy/gl.h>

struct _FlFramebuffer {
  GObject parent_instance;

  // Width of framebuffer in pixels.
  size_t width;

  // Height of framebuffer in pixels.
  size_t height;

  // Framebuffer ID.
  GLuint framebuffer_id;

  // Texture backing framebuffer.
  GLuint texture_id;

  // Stencil buffer associated with this framebuffer.
  GLuint depth_stencil;

  // EGL image for this texture.
  EGLImage image;
};

G_DEFINE_TYPE(FlFramebuffer, fl_framebuffer, G_TYPE_OBJECT)

static EGLImage create_egl_image(GLuint texture_id) {
  EGLDisplay egl_display = eglGetCurrentDisplay();
  if (egl_display == EGL_NO_DISPLAY) {
    g_warning("Failed to create EGL image: Failed to get current EGL display");
    return nullptr;
  }

  EGLContext egl_context = eglGetCurrentContext();
  if (egl_context == EGL_NO_CONTEXT) {
    g_warning("Failed to create EGL image: Failed to get current EGL context");
    return nullptr;
  }

  return eglCreateImage(
      egl_display, egl_context, EGL_GL_TEXTURE_2D,
      reinterpret_cast<EGLClientBuffer>(static_cast<intptr_t>(texture_id)),
      nullptr);
}

static void fl_framebuffer_dispose(GObject* object) {
  FlFramebuffer* self = FL_FRAMEBUFFER(object);

  glDeleteFramebuffers(1, &self->framebuffer_id);
  glDeleteTextures(1, &self->texture_id);
  glDeleteRenderbuffers(1, &self->depth_stencil);

  G_OBJECT_CLASS(fl_framebuffer_parent_class)->dispose(object);
}

static void fl_framebuffer_class_init(FlFramebufferClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_framebuffer_dispose;
}

static void fl_framebuffer_init(FlFramebuffer* self) {}

FlFramebuffer* fl_framebuffer_new(GLint format,
                                  size_t width,
                                  size_t height,
                                  gboolean shareable) {
  FlFramebuffer* self =
      FL_FRAMEBUFFER(g_object_new(fl_framebuffer_get_type(), nullptr));

  self->width = width;
  self->height = height;

  glGenTextures(1, &self->texture_id);
  glGenFramebuffers(1, &self->framebuffer_id);

  glBindFramebuffer(GL_FRAMEBUFFER, self->framebuffer_id);

  glBindTexture(GL_TEXTURE_2D, self->texture_id);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexImage2D(GL_TEXTURE_2D, 0, format, width, height, 0, format,
               GL_UNSIGNED_BYTE, NULL);
  glBindTexture(GL_TEXTURE_2D, 0);

  if (shareable) {
    self->image = create_egl_image(self->texture_id);
  }

  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                         self->texture_id, 0);

  glGenRenderbuffers(1, &self->depth_stencil);
  glBindRenderbuffer(GL_RENDERBUFFER, self->depth_stencil);
  glRenderbufferStorage(GL_RENDERBUFFER,      // target
                        GL_DEPTH24_STENCIL8,  // internal format
                        width,                // width
                        height                // height
  );
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                            GL_RENDERBUFFER, self->depth_stencil);
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT,
                            GL_RENDERBUFFER, self->depth_stencil);

  return self;
}

gboolean fl_framebuffer_get_shareable(FlFramebuffer* self) {
  g_return_val_if_fail(FL_IS_FRAMEBUFFER(self), FALSE);
  return self->image != nullptr;
}

FlFramebuffer* fl_framebuffer_create_sibling(FlFramebuffer* self) {
  g_return_val_if_fail(FL_IS_FRAMEBUFFER(self), nullptr);
  g_return_val_if_fail(self->image != nullptr, nullptr);

  FlFramebuffer* sibling =
      FL_FRAMEBUFFER(g_object_new(fl_framebuffer_get_type(), nullptr));

  sibling->width = self->width;
  sibling->height = self->height;
  sibling->image = self->image;

  // Make texture from existing image.
  glGenTextures(1, &sibling->texture_id);
  glBindTexture(GL_TEXTURE_2D, sibling->texture_id);
  glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, self->image);

  // Make framebuffer that uses this texture.
  glGenFramebuffers(1, &sibling->framebuffer_id);
  GLint saved_framebuffer_binding;
  glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &saved_framebuffer_binding);
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, sibling->framebuffer_id);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                         sibling->texture_id, 0);
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, saved_framebuffer_binding);

  return sibling;
}

GLuint fl_framebuffer_get_id(FlFramebuffer* self) {
  return self->framebuffer_id;
}

GLuint fl_framebuffer_get_texture_id(FlFramebuffer* self) {
  return self->texture_id;
}

size_t fl_framebuffer_get_width(FlFramebuffer* self) {
  return self->width;
}

size_t fl_framebuffer_get_height(FlFramebuffer* self) {
  return self->height;
}
