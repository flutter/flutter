// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_framebuffer.h"

#include <epoxy/egl.h>
#include <epoxy/gl.h>

#include "flutter/shell/platform/linux/fl_egl_image.h"

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

  // Color renderbuffer backing framebuffer (if using offscreen MSAA).
  GLuint color_renderbuffer;

  // Depth and stencil renderbuffer associated with this framebuffer.
  GLuint depth_stencil;

  // EGL image for this texture.
  FlEGLImage* image;
};

G_DEFINE_TYPE(FlFramebuffer, fl_framebuffer, G_TYPE_OBJECT)

static void fl_framebuffer_dispose(GObject* object) {
  FlFramebuffer* self = FL_FRAMEBUFFER(object);

  if (self->framebuffer_id != 0) {
    glDeleteFramebuffers(1, &self->framebuffer_id);
  }
  if (self->texture_id != 0) {
    glDeleteTextures(1, &self->texture_id);
  }
  if (self->color_renderbuffer != 0) {
    glDeleteRenderbuffers(1, &self->color_renderbuffer);
  }
  if (self->depth_stencil != 0) {
    glDeleteRenderbuffers(1, &self->depth_stencil);
  }
  g_clear_object(&self->image);

  G_OBJECT_CLASS(fl_framebuffer_parent_class)->dispose(object);
}

static void fl_framebuffer_class_init(FlFramebufferClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_framebuffer_dispose;
}

static void fl_framebuffer_init(FlFramebuffer* self) {}

static bool check_supports_implicit_msaa() {
  return epoxy_has_gl_extension("GL_EXT_multisampled_render_to_texture");
}

static bool check_supports_offscreen_msaa() {
  if (epoxy_gl_version() >= 30 ||
      epoxy_has_gl_extension("GL_ANGLE_framebuffer_multisample") ||
      epoxy_has_gl_extension("GL_EXT_framebuffer_multisample")) {
    GLint max_samples = 0;
    glGetIntegerv(GL_MAX_SAMPLES, &max_samples);
    return max_samples >= 4;
  }
  if (epoxy_has_gl_extension("GL_EXT_multisampled_render_to_texture2")) {
    GLint max_samples = 0;
    glGetIntegerv(GL_MAX_SAMPLES_EXT, &max_samples);
    return max_samples >= 4;
  }
  return false;
}

static GLuint create_texture(GLint format, size_t width, size_t height) {
  GLuint texture_id;
  glGenTextures(1, &texture_id);
  glBindTexture(GL_TEXTURE_2D, texture_id);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexImage2D(GL_TEXTURE_2D, 0, format, width, height, 0, format,
               GL_UNSIGNED_BYTE, nullptr);
  glBindTexture(GL_TEXTURE_2D, 0);
  return texture_id;
}

static void attach_depth_stencil(GLuint framebuffer_id, GLuint depth_stencil) {
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                            GL_RENDERBUFFER, depth_stencil);
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT,
                            GL_RENDERBUFFER, depth_stencil);
}

FlFramebuffer* fl_framebuffer_new(GLint format,
                                  size_t width,
                                  size_t height,
                                  gboolean shareable) {
  FlFramebuffer* self =
      FL_FRAMEBUFFER(g_object_new(fl_framebuffer_get_type(), nullptr));

  self->width = width;
  self->height = height;

  glGenFramebuffers(1, &self->framebuffer_id);
  glBindFramebuffer(GL_FRAMEBUFFER, self->framebuffer_id);

  self->texture_id = create_texture(format, width, height);

  if (shareable) {
    self->image = fl_egl_image_new(self->texture_id);
  }

  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                         self->texture_id, 0);

  glGenRenderbuffers(1, &self->depth_stencil);
  glBindRenderbuffer(GL_RENDERBUFFER, self->depth_stencil);
  glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, width, height);
  attach_depth_stencil(self->framebuffer_id, self->depth_stencil);

  return self;
}

FlFramebuffer* fl_framebuffer_new_multisample(GLint sized_format,
                                              GLint general_format,
                                              size_t width,
                                              size_t height,
                                              gboolean use_msaa) {
  FlFramebuffer* self =
      FL_FRAMEBUFFER(g_object_new(fl_framebuffer_get_type(), nullptr));

  self->width = width;
  self->height = height;

  glGenFramebuffers(1, &self->framebuffer_id);
  glBindFramebuffer(GL_FRAMEBUFFER, self->framebuffer_id);

  if (use_msaa) {
    if (check_supports_implicit_msaa()) {
      // Implicit MSAA uses GL_EXT_multisampled_render_to_texture, where the
      // OpenGL driver automatically resolves multisamples into the attached
      // texture when rendering is completed.
      self->texture_id = create_texture(general_format, width, height);
      glFramebufferTexture2DMultisampleEXT(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                                           GL_TEXTURE_2D, self->texture_id, 0,
                                           4);

      glGenRenderbuffers(1, &self->depth_stencil);
      glBindRenderbuffer(GL_RENDERBUFFER, self->depth_stencil);
      glRenderbufferStorageMultisampleEXT(GL_RENDERBUFFER, 4,
                                          GL_DEPTH24_STENCIL8, width, height);
      attach_depth_stencil(self->framebuffer_id, self->depth_stencil);
    } else if (check_supports_offscreen_msaa()) {
      // Offscreen MSAA uses a multisample renderbuffer instead of a texture.
      // The multisample resolve occurs in fl_compositor_opengl_composite_layers
      // via glBlitFramebuffer (or composite_layer) into the compositor's
      // single-sample framebuffer texture.
      glGenRenderbuffers(1, &self->color_renderbuffer);
      glBindRenderbuffer(GL_RENDERBUFFER, self->color_renderbuffer);
      glRenderbufferStorageMultisample(GL_RENDERBUFFER, 4, sized_format, width,
                                       height);
      glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                                GL_RENDERBUFFER, self->color_renderbuffer);

      glGenRenderbuffers(1, &self->depth_stencil);
      glBindRenderbuffer(GL_RENDERBUFFER, self->depth_stencil);
      glRenderbufferStorageMultisample(GL_RENDERBUFFER, 4, GL_DEPTH24_STENCIL8,
                                       width, height);
      attach_depth_stencil(self->framebuffer_id, self->depth_stencil);
    } else {
      self->texture_id = create_texture(general_format, width, height);
      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                             GL_TEXTURE_2D, self->texture_id, 0);

      glGenRenderbuffers(1, &self->depth_stencil);
      glBindRenderbuffer(GL_RENDERBUFFER, self->depth_stencil);
      glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, width,
                            height);
      attach_depth_stencil(self->framebuffer_id, self->depth_stencil);
    }
  } else {
    self->texture_id = create_texture(general_format, width, height);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                           self->texture_id, 0);

    glGenRenderbuffers(1, &self->depth_stencil);
    glBindRenderbuffer(GL_RENDERBUFFER, self->depth_stencil);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, width, height);
    attach_depth_stencil(self->framebuffer_id, self->depth_stencil);
  }

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
  sibling->image = FL_EGL_IMAGE(g_object_ref(self->image));

  // Make texture from existing image.
  glGenTextures(1, &sibling->texture_id);
  glBindTexture(GL_TEXTURE_2D, sibling->texture_id);
  glEGLImageTargetTexture2DOES(GL_TEXTURE_2D,
                               fl_egl_image_get_image(self->image));

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
