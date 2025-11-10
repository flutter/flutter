// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_compositor_opengl.h"

#include <epoxy/egl.h>
#include <epoxy/gl.h>

#include "flutter/common/constants.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_framebuffer.h"

// Vertex shader to draw Flutter window contents.
static const char* vertex_shader_src =
    "attribute vec2 position;\n"
    "attribute vec2 in_texcoord;\n"
    "uniform vec2 offset;\n"
    "uniform vec2 scale;\n"
    "varying vec2 texcoord;\n"
    "\n"
    "void main() {\n"
    "  gl_Position = vec4(offset + position * scale, 0, 1);\n"
    "  texcoord = in_texcoord;\n"
    "}\n";

// Fragment shader to draw Flutter window contents.
static const char* fragment_shader_src =
    "#ifdef GL_ES\n"
    "precision mediump float;\n"
    "#endif\n"
    "\n"
    "uniform sampler2D texture;\n"
    "varying vec2 texcoord;\n"
    "\n"
    "void main() {\n"
    "  gl_FragColor = texture2D(texture, texcoord);\n"
    "}\n";

struct _FlCompositorOpenGL {
  FlCompositor parent_instance;

  // Task runner to wait for frames on.
  FlTaskRunner* task_runner;

  // TRUE if can share framebuffers between contexts.
  gboolean shareable;

  // Flutter OpenGL contexts.
  FlOpenGLManager* opengl_manager;

  // Last rendered frame.
  FlFramebuffer* framebuffer;

  // Last rendered frame pixels (only set if shareable is TRUE).
  uint8_t* pixels;

  // whether the renderer waits for frame render
  bool blocking_main_thread;

  // true if frame was completed; resizing is not synchronized until first frame
  // was rendered
  bool had_first_frame;

  // Shader program.
  GLuint program;

  // Location of layer offset in [program].
  GLuint offset_location;

  // Location of layer scale in [program].
  GLuint scale_location;

  // Verticies for the uniform square.
  GLuint vertex_buffer;

  // Ensure Flutter and GTK can access the frame data (framebuffer or pixels).
  GMutex frame_mutex;
};

G_DEFINE_TYPE(FlCompositorOpenGL,
              fl_compositor_opengl,
              fl_compositor_get_type())

// Returns the log for the given OpenGL shader. Must be freed by the caller.
static gchar* get_shader_log(GLuint shader) {
  GLint log_length;
  gchar* log;

  glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &log_length);

  log = static_cast<gchar*>(g_malloc(log_length + 1));
  glGetShaderInfoLog(shader, log_length, nullptr, log);

  return log;
}

// Returns the log for the given OpenGL program. Must be freed by the caller.
static gchar* get_program_log(GLuint program) {
  GLint log_length;
  gchar* log;

  glGetProgramiv(program, GL_INFO_LOG_LENGTH, &log_length);

  log = static_cast<gchar*>(g_malloc(log_length + 1));
  glGetProgramInfoLog(program, log_length, nullptr, log);

  return log;
}

static void setup_shader(FlCompositorOpenGL* self) {
  if (!fl_opengl_manager_make_current(self->opengl_manager)) {
    g_warning(
        "Failed to setup compositor shaders, unable to make OpenGL context "
        "current");
    return;
  }

  GLuint vertex_shader = glCreateShader(GL_VERTEX_SHADER);
  glShaderSource(vertex_shader, 1, &vertex_shader_src, nullptr);
  glCompileShader(vertex_shader);
  GLint vertex_compile_status;
  glGetShaderiv(vertex_shader, GL_COMPILE_STATUS, &vertex_compile_status);
  if (vertex_compile_status == GL_FALSE) {
    g_autofree gchar* shader_log = get_shader_log(vertex_shader);
    g_warning("Failed to compile vertex shader: %s", shader_log);
  }

  GLuint fragment_shader = glCreateShader(GL_FRAGMENT_SHADER);
  glShaderSource(fragment_shader, 1, &fragment_shader_src, nullptr);
  glCompileShader(fragment_shader);
  GLint fragment_compile_status;
  glGetShaderiv(fragment_shader, GL_COMPILE_STATUS, &fragment_compile_status);
  if (fragment_compile_status == GL_FALSE) {
    g_autofree gchar* shader_log = get_shader_log(fragment_shader);
    g_warning("Failed to compile fragment shader: %s", shader_log);
  }

  self->program = glCreateProgram();
  glAttachShader(self->program, vertex_shader);
  glAttachShader(self->program, fragment_shader);
  glLinkProgram(self->program);

  GLint link_status;
  glGetProgramiv(self->program, GL_LINK_STATUS, &link_status);
  if (link_status == GL_FALSE) {
    g_autofree gchar* program_log = get_program_log(self->program);
    g_warning("Failed to link program: %s", program_log);
  }

  self->offset_location = glGetUniformLocation(self->program, "offset");
  self->scale_location = glGetUniformLocation(self->program, "scale");

  glDeleteShader(vertex_shader);
  glDeleteShader(fragment_shader);

  // The uniform square abcd in two triangles cba + cdb
  // a--b
  // |  |
  // c--d
  GLfloat vertex_data[] = {-1, -1, 0, 0, 1, 1,  1, 1, -1, 1, 0, 1,
                           -1, -1, 0, 0, 1, -1, 1, 0, 1,  1, 1, 1};

  glGenBuffers(1, &self->vertex_buffer);
  glBindBuffer(GL_ARRAY_BUFFER, self->vertex_buffer);
  glBufferData(GL_ARRAY_BUFFER, sizeof(vertex_data), vertex_data,
               GL_STATIC_DRAW);
}

static void cleanup_shader(FlCompositorOpenGL* self) {
  if (!fl_opengl_manager_make_current(self->opengl_manager)) {
    g_warning(
        "Failed to cleanup compositor shaders, unable to make OpenGL context "
        "current");
    return;
  }

  if (self->program != 0) {
    glDeleteProgram(self->program);
  }
  if (self->vertex_buffer != 0) {
    glDeleteBuffers(1, &self->vertex_buffer);
  }
}

static void composite_layer(FlCompositorOpenGL* self,
                            FlFramebuffer* framebuffer,
                            double x,
                            double y,
                            int width,
                            int height) {
  size_t texture_width = fl_framebuffer_get_width(framebuffer);
  size_t texture_height = fl_framebuffer_get_height(framebuffer);
  glUniform2f(self->offset_location, (2 * x / width) - 1.0,
              (2 * y / width) - 1.0);
  glUniform2f(self->scale_location, texture_width / width,
              texture_height / height);

  GLuint texture_id = fl_framebuffer_get_texture_id(framebuffer);
  glBindTexture(GL_TEXTURE_2D, texture_id);

  glDrawArrays(GL_TRIANGLES, 0, 6);
}

static gboolean fl_compositor_opengl_present_layers(FlCompositor* compositor,
                                                    const FlutterLayer** layers,
                                                    size_t layers_count) {
  FlCompositorOpenGL* self = FL_COMPOSITOR_OPENGL(compositor);

  g_mutex_lock(&self->frame_mutex);
  if (layers_count == 0) {
    g_mutex_unlock(&self->frame_mutex);
    return TRUE;
  }

  GLint general_format = GL_RGBA;
  if (epoxy_has_gl_extension("GL_EXT_texture_format_BGRA8888")) {
    general_format = GL_BGRA_EXT;
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
  GLint saved_framebuffer_binding;
  glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &saved_framebuffer_binding);

  // Update framebuffer to write into.
  size_t width = layers[0]->size.width;
  size_t height = layers[0]->size.height;
  if (self->framebuffer == nullptr ||
      fl_framebuffer_get_width(self->framebuffer) != width ||
      fl_framebuffer_get_height(self->framebuffer) != height) {
    g_clear_object(&self->framebuffer);
    self->framebuffer =
        fl_framebuffer_new(general_format, width, height, self->shareable);

    // If not shareable make buffer to copy frame pixels into.
    if (!self->shareable) {
      size_t data_length = width * height * 4;
      self->pixels = static_cast<uint8_t*>(realloc(self->pixels, data_length));
    }
  }

  self->had_first_frame = true;

  // FIXME(robert-ancell): The vertex array is the same for all views, but
  // cannot be shared in OpenGL. Find a way to not generate this every time.
  GLuint vao;
  glGenVertexArrays(1, &vao);
  glBindVertexArray(vao);
  glBindBuffer(GL_ARRAY_BUFFER, self->vertex_buffer);
  GLint position_location = glGetAttribLocation(self->program, "position");
  glEnableVertexAttribArray(position_location);
  glVertexAttribPointer(position_location, 2, GL_FLOAT, GL_FALSE,
                        sizeof(GLfloat) * 4, 0);
  GLint texcoord_location = glGetAttribLocation(self->program, "in_texcoord");
  glEnableVertexAttribArray(texcoord_location);
  glVertexAttribPointer(texcoord_location, 2, GL_FLOAT, GL_FALSE,
                        sizeof(GLfloat) * 4,
                        reinterpret_cast<void*>(sizeof(GLfloat) * 2));

  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  glUseProgram(self->program);

  // Disable the scissor test as it can affect blit operations.
  // Prevents regressions like: https://github.com/flutter/flutter/issues/140828
  // See OpenGL specification version 4.6, section 18.3.1.
  glDisable(GL_SCISSOR_TEST);

  glBindFramebuffer(GL_DRAW_FRAMEBUFFER,
                    fl_framebuffer_get_id(self->framebuffer));
  gboolean first_layer = TRUE;
  for (size_t i = 0; i < layers_count; ++i) {
    const FlutterLayer* layer = layers[i];
    switch (layer->type) {
      case kFlutterLayerContentTypeBackingStore: {
        const FlutterBackingStore* backing_store = layer->backing_store;
        FlFramebuffer* framebuffer =
            FL_FRAMEBUFFER(backing_store->open_gl.framebuffer.user_data);
        glBindFramebuffer(GL_READ_FRAMEBUFFER,
                          fl_framebuffer_get_id(framebuffer));
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
          composite_layer(self, framebuffer, layer->offset.x, layer->offset.y,
                          width, height);
        }
      } break;
      case kFlutterLayerContentTypePlatformView: {
        // TODO(robert-ancell) Not implemented -
        // https://github.com/flutter/flutter/issues/41724
      } break;
    }
  }
  glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
  glFlush();

  glDeleteVertexArrays(1, &vao);

  glDisable(GL_BLEND);

  glBindTexture(GL_TEXTURE_2D, saved_texture_binding);
  glBindVertexArray(saved_vao_binding);
  glBindBuffer(GL_ARRAY_BUFFER, saved_array_buffer_binding);
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, saved_framebuffer_binding);

  if (!self->shareable) {
    glBindFramebuffer(GL_READ_FRAMEBUFFER,
                      fl_framebuffer_get_id(self->framebuffer));
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, self->pixels);
    glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
  }

  g_mutex_unlock(&self->frame_mutex);

  fl_task_runner_stop_wait(self->task_runner);

  return TRUE;
}

static gboolean fl_compositor_opengl_render(FlCompositor* compositor,
                                            cairo_t* cr,
                                            GdkWindow* window) {
  FlCompositorOpenGL* self = FL_COMPOSITOR_OPENGL(compositor);

  g_mutex_lock(&self->frame_mutex);
  if (self->framebuffer == nullptr) {
    g_mutex_unlock(&self->frame_mutex);
    return FALSE;
  }

  // If frame not ready, then wait for it.
  gint scale_factor = gdk_window_get_scale_factor(window);
  size_t width = gdk_window_get_width(window) * scale_factor;
  size_t height = gdk_window_get_height(window) * scale_factor;
  while (fl_framebuffer_get_width(self->framebuffer) != width ||
         fl_framebuffer_get_height(self->framebuffer) != height) {
    g_mutex_unlock(&self->frame_mutex);
    fl_task_runner_wait(self->task_runner);
    g_mutex_lock(&self->frame_mutex);
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
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA,
                 GL_UNSIGNED_BYTE, self->pixels);

    gdk_cairo_draw_from_gl(cr, window, texture_id, GL_TEXTURE, scale_factor, 0,
                           0, width, height);

    glDeleteTextures(1, &texture_id);

    glBindTexture(GL_TEXTURE_2D, saved_texture_binding);
  }

  glFlush();

  g_mutex_unlock(&self->frame_mutex);

  return TRUE;
}

static void fl_compositor_opengl_dispose(GObject* object) {
  FlCompositorOpenGL* self = FL_COMPOSITOR_OPENGL(object);

  cleanup_shader(self);

  g_clear_object(&self->task_runner);
  g_clear_object(&self->opengl_manager);
  g_clear_object(&self->framebuffer);
  g_clear_pointer(&self->pixels, g_free);
  g_mutex_clear(&self->frame_mutex);

  G_OBJECT_CLASS(fl_compositor_opengl_parent_class)->dispose(object);
}

static void fl_compositor_opengl_class_init(FlCompositorOpenGLClass* klass) {
  FL_COMPOSITOR_CLASS(klass)->present_layers =
      fl_compositor_opengl_present_layers;
  FL_COMPOSITOR_CLASS(klass)->render = fl_compositor_opengl_render;

  G_OBJECT_CLASS(klass)->dispose = fl_compositor_opengl_dispose;
}

static void fl_compositor_opengl_init(FlCompositorOpenGL* self) {
  g_mutex_init(&self->frame_mutex);
}

FlCompositorOpenGL* fl_compositor_opengl_new(FlTaskRunner* task_runner,
                                             FlOpenGLManager* opengl_manager,
                                             gboolean shareable) {
  FlCompositorOpenGL* self = FL_COMPOSITOR_OPENGL(
      g_object_new(fl_compositor_opengl_get_type(), nullptr));

  self->task_runner = FL_TASK_RUNNER(g_object_ref(task_runner));
  self->shareable = shareable;
  self->opengl_manager = FL_OPENGL_MANAGER(g_object_ref(opengl_manager));

  setup_shader(self);

  return self;
}
