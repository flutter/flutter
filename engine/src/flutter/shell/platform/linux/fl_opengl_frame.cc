// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_opengl_frame.h"

#include <epoxy/egl.h>
#include <epoxy/gl.h>

#include "flutter/shell/platform/linux/fl_framebuffer.h"

struct _FlOpenGLFrame {
  GObject parent_instance;

  // TRUE if the frame can be shared between OpenGL contexts.
  gboolean shareable;

  // Framebuffer the current frame is composited into.
  FlFramebuffer* framebuffer;

  // Copy of the current frame in CPU memory (only set if shareable is FALSE).
  uint8_t* pixels;
};

G_DEFINE_TYPE(FlOpenGLFrame, fl_opengl_frame, G_TYPE_OBJECT)

static void fl_opengl_frame_dispose(GObject* object) {
  FlOpenGLFrame* self = FL_OPENGL_FRAME(object);

  g_clear_object(&self->framebuffer);

  G_OBJECT_CLASS(fl_opengl_frame_parent_class)->dispose(object);
}

static void fl_opengl_frame_finalize(GObject* object) {
  FlOpenGLFrame* self = FL_OPENGL_FRAME(object);

  g_clear_pointer(&self->pixels, g_free);

  G_OBJECT_CLASS(fl_opengl_frame_parent_class)->finalize(object);
}

static void fl_opengl_frame_class_init(FlOpenGLFrameClass* klass) {
  GObjectClass* object_class = G_OBJECT_CLASS(klass);
  object_class->dispose = fl_opengl_frame_dispose;
  object_class->finalize = fl_opengl_frame_finalize;
}

static void fl_opengl_frame_init(FlOpenGLFrame* self) {}

FlOpenGLFrame* fl_opengl_frame_new(gboolean shareable) {
  FlOpenGLFrame* self =
      FL_OPENGL_FRAME(g_object_new(fl_opengl_frame_get_type(), nullptr));
  self->shareable = shareable;
  return self;
}

void fl_opengl_frame_composite(FlOpenGLFrame* self,
                               FlCompositorOpenGL* compositor,
                               const FlutterLayer** layers,
                               size_t layers_count) {
  g_return_if_fail(FL_IS_OPENGL_FRAME(self));

  if (layers_count == 0) {
    return;
  }

  size_t width = layers[0]->size.width;
  size_t height = layers[0]->size.height;

  if (width == 0 || height == 0) {
    // A zero-sized layer has no content to show. Drop any existing frame so
    // the renderer reports no frame rather than an empty framebuffer (a 0x0
    // framebuffer would otherwise be treated as a valid frame while matching
    // the "no frame" size of 0x0).
    g_clear_object(&self->framebuffer);
    g_clear_pointer(&self->pixels, g_free);
    return;
  }

  // Recreate the framebuffer if the frame size has changed.
  if (self->framebuffer == nullptr ||
      fl_framebuffer_get_width(self->framebuffer) != width ||
      fl_framebuffer_get_height(self->framebuffer) != height) {
    GLint general_format = GL_RGBA;
    if (epoxy_has_gl_extension("GL_EXT_texture_format_BGRA8888")) {
      general_format = GL_BGRA_EXT;
    }
    g_clear_object(&self->framebuffer);
    self->framebuffer =
        fl_framebuffer_new(general_format, width, height, self->shareable);

    // If not shareable make a buffer to copy the frame pixels into.
    if (!self->shareable) {
      size_t data_length = width * height * 4;
      self->pixels =
          static_cast<uint8_t*>(g_realloc(self->pixels, data_length));
    }
  }

  // Bind the target framebuffer so the compositor draws into it, then read the
  // frame back into CPU memory when it can't be shared between contexts.
  GLint saved_draw_framebuffer_binding;
  glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &saved_draw_framebuffer_binding);
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER,
                    fl_framebuffer_get_id(self->framebuffer));

  fl_compositor_opengl_composite_layers(compositor, layers, layers_count);

  if (!self->shareable) {
    GLint saved_read_framebuffer_binding;
    glGetIntegerv(GL_READ_FRAMEBUFFER_BINDING, &saved_read_framebuffer_binding);
    glBindFramebuffer(GL_READ_FRAMEBUFFER,
                      fl_framebuffer_get_id(self->framebuffer));
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, self->pixels);
    glBindFramebuffer(GL_READ_FRAMEBUFFER, saved_read_framebuffer_binding);
  }

  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, saved_draw_framebuffer_binding);
}

void fl_opengl_frame_get_size(FlOpenGLFrame* self,
                              size_t* width,
                              size_t* height) {
  g_return_if_fail(FL_IS_OPENGL_FRAME(self));

  if (self->framebuffer != nullptr) {
    *width = fl_framebuffer_get_width(self->framebuffer);
    *height = fl_framebuffer_get_height(self->framebuffer);
  } else {
    *width = 0;
    *height = 0;
  }
}

gboolean fl_opengl_frame_draw(FlOpenGLFrame* self,
                              cairo_t* cr,
                              GdkWindow* window,
                              gint scale_factor,
                              size_t width,
                              size_t height) {
  g_return_val_if_fail(FL_IS_OPENGL_FRAME(self), FALSE);

  if (self->framebuffer == nullptr) {
    return FALSE;
  }

  if (fl_framebuffer_get_shareable(self->framebuffer)) {
    g_autoptr(FlFramebuffer) sibling =
        fl_framebuffer_create_sibling(self->framebuffer);
    gdk_cairo_draw_from_gl(cr, window, fl_framebuffer_get_texture_id(sibling),
                           GL_TEXTURE, scale_factor, 0, 0, width, height);
  } else {
    GLint saved_texture_binding;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &saved_texture_binding);

    GLuint texture_id;
    glGenTextures(1, &texture_id);
    glBindTexture(GL_TEXTURE_2D, texture_id);
    GLsizei fb_width =
        static_cast<GLsizei>(fl_framebuffer_get_width(self->framebuffer));
    GLsizei fb_height =
        static_cast<GLsizei>(fl_framebuffer_get_height(self->framebuffer));
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fb_width, fb_height, 0, GL_RGBA,
                 GL_UNSIGNED_BYTE, self->pixels);

    gdk_cairo_draw_from_gl(cr, window, texture_id, GL_TEXTURE, scale_factor, 0,
                           0, width, height);

    glDeleteTextures(1, &texture_id);

    glBindTexture(GL_TEXTURE_2D, saved_texture_binding);
  }

  glFlush();

  return TRUE;
}
