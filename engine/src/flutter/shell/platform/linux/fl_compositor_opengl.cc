// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_compositor_opengl.h"

#include <epoxy/egl.h>
#include <epoxy/gl.h>

#include "flutter/common/constants.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/linux/fl_compositor_opengl_shader.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_framebuffer.h"

struct _FlCompositorOpenGL {
  GObject parent_instance;

  // Flutter OpenGL contexts.
  FlOpenGLManager* opengl_manager;

  // Shader program used to composite layers.
  FlCompositorOpenGLShader* shader;
};

G_DEFINE_TYPE(FlCompositorOpenGL, fl_compositor_opengl, G_TYPE_OBJECT)

static void fl_compositor_opengl_dispose(GObject* object) {
  FlCompositorOpenGL* self = FL_COMPOSITOR_OPENGL(object);

  g_clear_object(&self->shader);
  g_clear_object(&self->opengl_manager);

  G_OBJECT_CLASS(fl_compositor_opengl_parent_class)->dispose(object);
}

static void fl_compositor_opengl_class_init(FlCompositorOpenGLClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_compositor_opengl_dispose;
}

static void fl_compositor_opengl_init(FlCompositorOpenGL* self) {}

FlCompositorOpenGL* fl_compositor_opengl_new(FlOpenGLManager* opengl_manager) {
  FlCompositorOpenGL* self = FL_COMPOSITOR_OPENGL(
      g_object_new(fl_compositor_opengl_get_type(), nullptr));

  self->opengl_manager = FL_OPENGL_MANAGER(g_object_ref(opengl_manager));
  self->shader = fl_compositor_opengl_shader_new(opengl_manager);

  return self;
}

static void composite_layer(FlCompositorOpenGL* self,
                            FlFramebuffer* framebuffer,
                            double x,
                            double y,
                            int width,
                            int height) {
  size_t texture_width = fl_framebuffer_get_width(framebuffer);
  size_t texture_height = fl_framebuffer_get_height(framebuffer);
  fl_compositor_opengl_shader_set_offset(self->shader, (2 * x / width) - 1.0,
                                         (2 * y / height) - 1.0);
  fl_compositor_opengl_shader_set_scale(self->shader, texture_width / width,
                                        texture_height / height);

  GLuint texture_id = fl_framebuffer_get_texture_id(framebuffer);
  glBindTexture(GL_TEXTURE_2D, texture_id);

  glDrawArrays(GL_TRIANGLES, 0, 6);
}

void fl_compositor_opengl_composite_layers(FlCompositorOpenGL* self,
                                           const FlutterLayer** layers,
                                           size_t layers_count) {
  if (layers_count == 0) {
    return;
  }

  // Save bindings that are set by this function.  All bindings must be restored
  // to their original values because Skia expects that its bindings have not
  // been altered.
  GLint saved_texture_binding;
  glGetIntegerv(GL_TEXTURE_BINDING_2D, &saved_texture_binding);
  GLint saved_vao_binding;
  glGetIntegerv(GL_VERTEX_ARRAY_BINDING, &saved_vao_binding);
  GLint saved_array_buffer_binding;
  glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &saved_array_buffer_binding);
  GLint saved_read_framebuffer_binding;
  glGetIntegerv(GL_READ_FRAMEBUFFER_BINDING, &saved_read_framebuffer_binding);
  GLint saved_current_program;
  glGetIntegerv(GL_CURRENT_PROGRAM, &saved_current_program);
  GLboolean saved_scissor_test = glIsEnabled(GL_SCISSOR_TEST);
  GLboolean saved_blend = glIsEnabled(GL_BLEND);
  GLint saved_src_rgb;
  glGetIntegerv(GL_BLEND_SRC_RGB, &saved_src_rgb);
  GLint saved_src_alpha;
  glGetIntegerv(GL_BLEND_SRC_ALPHA, &saved_src_alpha);
  GLint saved_dst_rgb;
  glGetIntegerv(GL_BLEND_DST_RGB, &saved_dst_rgb);
  GLint saved_dst_alpha;
  glGetIntegerv(GL_BLEND_DST_ALPHA, &saved_dst_alpha);

  size_t width = layers[0]->size.width;
  size_t height = layers[0]->size.height;

  // FIXME(robert-ancell): The vertex array is the same for all views, but
  // cannot be shared in OpenGL. Find a way to not generate this every time.
  GLuint vao;
  glGenVertexArrays(1, &vao);
  glBindVertexArray(vao);

  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  fl_compositor_opengl_shader_use(self->shader);

  // Disable the scissor test as it can affect blit operations.
  // Prevents regressions like: https://github.com/flutter/flutter/issues/140828
  // See OpenGL specification version 4.6, section 18.3.1.
  glDisable(GL_SCISSOR_TEST);

  gboolean first_layer = TRUE;
  for (size_t i = 0; i < layers_count; ++i) {
    const FlutterLayer* layer = layers[i];
    switch (layer->type) {
      case kFlutterLayerContentTypeBackingStore: {
        const FlutterBackingStore* backing_store = layer->backing_store;
        FlFramebuffer* layer_framebuffer =
            FL_FRAMEBUFFER(backing_store->open_gl.framebuffer.user_data);
        glBindFramebuffer(GL_READ_FRAMEBUFFER,
                          fl_framebuffer_get_id(layer_framebuffer));
        // The first layer can be blitted, and following layers composited with
        // this.
        if (first_layer) {
          glBlitFramebuffer(layer->offset.x, layer->offset.y, layer->size.width,
                            layer->size.height, layer->offset.x,
                            layer->offset.y, layer->size.width,
                            layer->size.height, GL_COLOR_BUFFER_BIT,
                            GL_NEAREST);
          first_layer = FALSE;
        } else {
          composite_layer(self, layer_framebuffer, layer->offset.x,
                          layer->offset.y, width, height);
        }
      } break;
      case kFlutterLayerContentTypePlatformView: {
        // TODO(robert-ancell) Not implemented -
        // https://github.com/flutter/flutter/issues/41724
      } break;
    }
  }
  glFlush();

  glDeleteVertexArrays(1, &vao);

  if (saved_blend) {
    glEnable(GL_BLEND);
  } else {
    glDisable(GL_BLEND);
  }
  if (saved_scissor_test) {
    glEnable(GL_SCISSOR_TEST);
  } else {
    glDisable(GL_SCISSOR_TEST);
  }

  glBindTexture(GL_TEXTURE_2D, saved_texture_binding);
  glBindVertexArray(saved_vao_binding);
  glBindBuffer(GL_ARRAY_BUFFER, saved_array_buffer_binding);
  glBindFramebuffer(GL_READ_FRAMEBUFFER, saved_read_framebuffer_binding);
  glUseProgram(saved_current_program);
  glBlendFuncSeparate(saved_src_rgb, saved_dst_rgb, saved_src_alpha,
                      saved_dst_alpha);
}
