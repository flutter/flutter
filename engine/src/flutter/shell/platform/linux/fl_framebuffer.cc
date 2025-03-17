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

  // EGL image for this texture.
  EGLImage image;
};

G_DEFINE_TYPE(FlFramebuffer, fl_framebuffer, G_TYPE_OBJECT)

static void fl_framebuffer_dispose(GObject* object) {
  FlFramebuffer* self = FL_FRAMEBUFFER(object);

  glDeleteFramebuffers(1, &self->framebuffer_id);
  glDeleteTextures(1, &self->texture_id);

  G_OBJECT_CLASS(fl_framebuffer_parent_class)->dispose(object);
}

static void fl_framebuffer_class_init(FlFramebufferClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_framebuffer_dispose;
}

static void fl_framebuffer_init(FlFramebuffer* self) {}

FlFramebuffer* fl_framebuffer_new(GLint format, size_t width, size_t height) {
  FlFramebuffer* self =
      FL_FRAMEBUFFER(g_object_new(fl_framebuffer_get_type(), nullptr));

  self->width = width;
  self->height = height;

  // Generate texture of this size.
  glGenTextures(1, &self->texture_id);
  glBindTexture(GL_TEXTURE_2D, self->texture_id);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexImage2D(GL_TEXTURE_2D, 0, format, width, height, 0, format,
               GL_UNSIGNED_BYTE, NULL);
  glBindTexture(GL_TEXTURE_2D, 0);

  // Make image from texture so can be used in other contexts.
  EGLDisplay egl_display = eglGetCurrentDisplay();
  EGLContext egl_context = eglGetCurrentContext();
  self->image =
      eglCreateImage(egl_display, egl_context, EGL_GL_TEXTURE_2D,
                     (EGLClientBuffer)(intptr_t)self->texture_id, nullptr);

  // Make framebuffer that uses this texture.
  glGenFramebuffers(1, &self->framebuffer_id);
  glBindFramebuffer(GL_FRAMEBUFFER, self->framebuffer_id);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                         self->texture_id, 0);

  GLuint depth_stencil;
  glGenRenderbuffers(1, &depth_stencil);
  glBindRenderbuffer(GL_RENDERBUFFER, depth_stencil);
  glRenderbufferStorage(GL_RENDERBUFFER,      // target
                        GL_DEPTH24_STENCIL8,  // internal format
                        width,                // width
                        height                // height
  );
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                            GL_RENDERBUFFER, depth_stencil);
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT,
                            GL_RENDERBUFFER, depth_stencil);

  return self;
}

FlFramebuffer* fl_framebuffer_create_sibling(FlFramebuffer* self) {
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
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, sibling->framebuffer_id);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                         sibling->texture_id, 0);

  return sibling;
}

GLuint fl_framebuffer_get_id(FlFramebuffer* self) {
  return self->framebuffer_id;
}

GLuint fl_framebuffer_get_texture_id(FlFramebuffer* self) {
  return self->texture_id;
}

GLenum fl_framebuffer_get_target(FlFramebuffer* self) {
  return GL_TEXTURE_2D;
}

size_t fl_framebuffer_get_width(FlFramebuffer* self) {
  return self->width;
}

size_t fl_framebuffer_get_height(FlFramebuffer* self) {
  return self->height;
}
