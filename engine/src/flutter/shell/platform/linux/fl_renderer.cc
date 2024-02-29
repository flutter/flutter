// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_renderer.h"

#include <epoxy/egl.h>
#include <epoxy/gl.h>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/linux/fl_backing_store_provider.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_view_private.h"

// Vertex shader to draw Flutter window contents.
static const char* vertex_shader_src =
    "attribute vec2 position;\n"
    "attribute vec2 in_texcoord;\n"
    "varying vec2 texcoord;\n"
    "\n"
    "void main() {\n"
    "  gl_Position = vec4(position, 0, 1);\n"
    "  texcoord = in_texcoord;\n"
    "}\n";

// Fragment shader to draw Flutter window contents.
static const char* fragment_shader_src =
    "uniform sampler2D texture;\n"
    "varying vec2 texcoord;\n"
    "\n"
    "void main() {\n"
    "  gl_FragColor = texture2D(texture, texcoord);\n"
    "}\n";

G_DEFINE_QUARK(fl_renderer_error_quark, fl_renderer_error)

typedef struct {
  FlView* view;

  // target dimension for resizing
  int target_width;
  int target_height;

  // whether the renderer waits for frame render
  bool blocking_main_thread;

  // true if frame was completed; resizing is not synchronized until first frame
  // was rendered
  bool had_first_frame;

  // Shader program.
  GLuint program;

  // Textures to render.
  GPtrArray* textures;
} FlRendererPrivate;

G_DEFINE_TYPE_WITH_PRIVATE(FlRenderer, fl_renderer, G_TYPE_OBJECT)

// Returns the log for the given OpenGL shader. Must be freed by the caller.
static gchar* get_shader_log(GLuint shader) {
  int log_length;
  gchar* log;

  glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &log_length);

  log = static_cast<gchar*>(g_malloc(log_length + 1));
  glGetShaderInfoLog(shader, log_length, nullptr, log);

  return log;
}

// Returns the log for the given OpenGL program. Must be freed by the caller.
static gchar* get_program_log(GLuint program) {
  int log_length;
  gchar* log;

  glGetProgramiv(program, GL_INFO_LOG_LENGTH, &log_length);

  log = static_cast<gchar*>(g_malloc(log_length + 1));
  glGetProgramInfoLog(program, log_length, nullptr, log);

  return log;
}

/// Converts a pixel co-ordinate from 0..pixels to OpenGL -1..1.
static GLfloat pixels_to_gl_coords(GLfloat position, GLfloat pixels) {
  return (2.0 * position / pixels) - 1.0;
}

static void fl_renderer_unblock_main_thread(FlRenderer* self) {
  FlRendererPrivate* priv = reinterpret_cast<FlRendererPrivate*>(
      fl_renderer_get_instance_private(self));
  if (priv->blocking_main_thread) {
    priv->blocking_main_thread = false;

    FlTaskRunner* runner =
        fl_engine_get_task_runner(fl_view_get_engine(priv->view));
    fl_task_runner_release_main_thread(runner);
  }
}

static void fl_renderer_dispose(GObject* object) {
  FlRenderer* self = FL_RENDERER(object);
  FlRendererPrivate* priv = reinterpret_cast<FlRendererPrivate*>(
      fl_renderer_get_instance_private(self));

  fl_renderer_unblock_main_thread(self);

  g_clear_pointer(&priv->textures, g_ptr_array_unref);

  G_OBJECT_CLASS(fl_renderer_parent_class)->dispose(object);
}

static void fl_renderer_class_init(FlRendererClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_renderer_dispose;
}

static void fl_renderer_init(FlRenderer* self) {
  FlRendererPrivate* priv = reinterpret_cast<FlRendererPrivate*>(
      fl_renderer_get_instance_private(self));
  priv->textures = g_ptr_array_new_with_free_func(g_object_unref);
}

gboolean fl_renderer_start(FlRenderer* self, FlView* view) {
  FlRendererPrivate* priv = reinterpret_cast<FlRendererPrivate*>(
      fl_renderer_get_instance_private(self));

  g_return_val_if_fail(FL_IS_RENDERER(self), FALSE);

  priv->view = view;
  return TRUE;
}

void* fl_renderer_get_proc_address(FlRenderer* self, const char* name) {
  g_return_val_if_fail(FL_IS_RENDERER(self), NULL);

  return reinterpret_cast<void*>(eglGetProcAddress(name));
}

void fl_renderer_make_current(FlRenderer* self) {
  g_return_if_fail(FL_IS_RENDERER(self));
  FL_RENDERER_GET_CLASS(self)->make_current(self);
}

void fl_renderer_make_resource_current(FlRenderer* self) {
  g_return_if_fail(FL_IS_RENDERER(self));
  FL_RENDERER_GET_CLASS(self)->make_resource_current(self);
}

void fl_renderer_clear_current(FlRenderer* self) {
  g_return_if_fail(FL_IS_RENDERER(self));
  FL_RENDERER_GET_CLASS(self)->clear_current(self);
}

guint32 fl_renderer_get_fbo(FlRenderer* self) {
  g_return_val_if_fail(FL_IS_RENDERER(self), 0);

  // There is only one frame buffer object - always return that.
  return 0;
}

gboolean fl_renderer_create_backing_store(
    FlRenderer* renderer,
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
  fl_renderer_make_current(renderer);

  FlBackingStoreProvider* provider =
      fl_backing_store_provider_new(config->size.width, config->size.height);
  if (!provider) {
    g_warning("Failed to create backing store");
    return FALSE;
  }

  uint32_t name = fl_backing_store_provider_get_gl_framebuffer_id(provider);
  uint32_t format = fl_backing_store_provider_get_gl_format(provider);

  backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
  backing_store_out->open_gl.type = kFlutterOpenGLTargetTypeFramebuffer;
  backing_store_out->open_gl.framebuffer.user_data = provider;
  backing_store_out->open_gl.framebuffer.name = name;
  backing_store_out->open_gl.framebuffer.target = format;
  backing_store_out->open_gl.framebuffer.destruction_callback = [](void* p) {
    // Backing store destroyed in fl_renderer_collect_backing_store(), set
    // on FlutterCompositor.collect_backing_store_callback during engine start.
  };

  return TRUE;
}

gboolean fl_renderer_collect_backing_store(
    FlRenderer* self,
    const FlutterBackingStore* backing_store) {
  fl_renderer_make_current(self);

  // OpenGL context is required when destroying #FlBackingStoreProvider.
  g_object_unref(backing_store->open_gl.framebuffer.user_data);
  return TRUE;
}

void fl_renderer_wait_for_frame(FlRenderer* self,
                                int target_width,
                                int target_height) {
  FlRendererPrivate* priv = reinterpret_cast<FlRendererPrivate*>(
      fl_renderer_get_instance_private(self));

  g_return_if_fail(FL_IS_RENDERER(self));

  priv->target_width = target_width;
  priv->target_height = target_height;

  if (priv->had_first_frame && !priv->blocking_main_thread) {
    priv->blocking_main_thread = true;
    FlTaskRunner* runner =
        fl_engine_get_task_runner(fl_view_get_engine(priv->view));
    fl_task_runner_block_main_thread(runner);
  }
}

gboolean fl_renderer_present_layers(FlRenderer* self,
                                    const FlutterLayer** layers,
                                    size_t layers_count) {
  FlRendererPrivate* priv = reinterpret_cast<FlRendererPrivate*>(
      fl_renderer_get_instance_private(self));

  g_return_val_if_fail(FL_IS_RENDERER(self), FALSE);

  // ignore incoming frame with wrong dimensions in trivial case with just one
  // layer
  if (priv->blocking_main_thread && layers_count == 1 &&
      layers[0]->offset.x == 0 && layers[0]->offset.y == 0 &&
      (layers[0]->size.width != priv->target_width ||
       layers[0]->size.height != priv->target_height)) {
    return true;
  }

  priv->had_first_frame = true;

  fl_renderer_unblock_main_thread(self);

  if (!priv->view) {
    return FALSE;
  }

  g_ptr_array_set_size(priv->textures, 0);
  for (size_t i = 0; i < layers_count; ++i) {
    const FlutterLayer* layer = layers[i];
    switch (layer->type) {
      case kFlutterLayerContentTypeBackingStore: {
        const FlutterBackingStore* backing_store = layer->backing_store;
        auto framebuffer = &backing_store->open_gl.framebuffer;
        FlBackingStoreProvider* provider =
            FL_BACKING_STORE_PROVIDER(framebuffer->user_data);
        g_ptr_array_add(priv->textures, g_object_ref(provider));
      } break;
      case kFlutterLayerContentTypePlatformView: {
        // TODO(robert-ancell) Not implemented -
        // https://github.com/flutter/flutter/issues/41724
      } break;
    }
  }

  fl_view_redraw(priv->view);

  return TRUE;
}

void fl_renderer_setup(FlRenderer* self) {
  FlRendererPrivate* priv = reinterpret_cast<FlRendererPrivate*>(
      fl_renderer_get_instance_private(self));

  g_return_if_fail(FL_IS_RENDERER(self));

  GLuint vertex_shader = glCreateShader(GL_VERTEX_SHADER);
  glShaderSource(vertex_shader, 1, &vertex_shader_src, nullptr);
  glCompileShader(vertex_shader);
  int vertex_compile_status;
  glGetShaderiv(vertex_shader, GL_COMPILE_STATUS, &vertex_compile_status);
  if (vertex_compile_status == GL_FALSE) {
    g_autofree gchar* shader_log = get_shader_log(vertex_shader);
    g_warning("Failed to compile vertex shader: %s", shader_log);
  }

  GLuint fragment_shader = glCreateShader(GL_FRAGMENT_SHADER);
  glShaderSource(fragment_shader, 1, &fragment_shader_src, nullptr);
  glCompileShader(fragment_shader);
  int fragment_compile_status;
  glGetShaderiv(fragment_shader, GL_COMPILE_STATUS, &fragment_compile_status);
  if (fragment_compile_status == GL_FALSE) {
    g_autofree gchar* shader_log = get_shader_log(fragment_shader);
    g_warning("Failed to compile fragment shader: %s", shader_log);
  }

  priv->program = glCreateProgram();
  glAttachShader(priv->program, vertex_shader);
  glAttachShader(priv->program, fragment_shader);
  glLinkProgram(priv->program);

  int link_status;
  glGetProgramiv(priv->program, GL_LINK_STATUS, &link_status);
  if (link_status == GL_FALSE) {
    g_autofree gchar* program_log = get_program_log(priv->program);
    g_warning("Failed to link program: %s", program_log);
  }

  glDeleteShader(vertex_shader);
  glDeleteShader(fragment_shader);
}

void fl_renderer_render(FlRenderer* self, int width, int height) {
  FlRendererPrivate* priv = reinterpret_cast<FlRendererPrivate*>(
      fl_renderer_get_instance_private(self));

  g_return_if_fail(FL_IS_RENDERER(self));

  glClearColor(0.0, 0.0, 0.0, 1.0);
  glClear(GL_COLOR_BUFFER_BIT);

  glUseProgram(priv->program);

  for (guint i = 0; i < priv->textures->len; i++) {
    FlBackingStoreProvider* texture =
        FL_BACKING_STORE_PROVIDER(g_ptr_array_index(priv->textures, i));

    uint32_t texture_id = fl_backing_store_provider_get_gl_texture_id(texture);
    glBindTexture(GL_TEXTURE_2D, texture_id);

    // Translate into OpenGL co-ordinates
    GdkRectangle texture_geometry =
        fl_backing_store_provider_get_geometry(texture);
    GLfloat texture_x = texture_geometry.x;
    GLfloat texture_y = texture_geometry.y;
    GLfloat texture_width = texture_geometry.width;
    GLfloat texture_height = texture_geometry.height;
    GLfloat x0 = pixels_to_gl_coords(texture_x, width);
    GLfloat y0 =
        pixels_to_gl_coords(height - (texture_y + texture_height), height);
    GLfloat x1 = pixels_to_gl_coords(texture_x + texture_width, width);
    GLfloat y1 = pixels_to_gl_coords(height - texture_y, height);
    GLfloat vertex_data[] = {x0, y0, 0, 0, x1, y1, 1, 1, x0, y1, 0, 1,
                             x0, y0, 0, 0, x1, y0, 1, 0, x1, y1, 1, 1};

    GLuint vao, vertex_buffer;
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);
    glGenBuffers(1, &vertex_buffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertex_buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertex_data), vertex_data,
                 GL_STATIC_DRAW);
    GLint position_index = glGetAttribLocation(priv->program, "position");
    glEnableVertexAttribArray(position_index);
    glVertexAttribPointer(position_index, 2, GL_FLOAT, GL_FALSE,
                          sizeof(GLfloat) * 4, 0);
    GLint texcoord_index = glGetAttribLocation(priv->program, "in_texcoord");
    glEnableVertexAttribArray(texcoord_index);
    glVertexAttribPointer(texcoord_index, 2, GL_FLOAT, GL_FALSE,
                          sizeof(GLfloat) * 4, (void*)(sizeof(GLfloat) * 2));

    glDrawArrays(GL_TRIANGLES, 0, 6);

    glDeleteVertexArrays(1, &vao);
    glDeleteBuffers(1, &vertex_buffer);
  }

  glFlush();
}

void fl_renderer_cleanup(FlRenderer* self) {
  FlRendererPrivate* priv = reinterpret_cast<FlRendererPrivate*>(
      fl_renderer_get_instance_private(self));

  g_return_if_fail(FL_IS_RENDERER(self));

  glDeleteProgram(priv->program);
}
