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

  // Engine we are rendering.
  GWeakRef engine;

  // Target OpenGL context;
  GdkGLContext* context;

  // Flutter OpenGL contexts.
  FlOpenGLManager* opengl_manager;

  // target dimension for resizing
  int target_width;
  int target_height;

  // whether the renderer waits for frame render
  bool blocking_main_thread;

  // true if frame was completed; resizing is not synchronized until first frame
  // was rendered
  bool had_first_frame;

  // True if we can use glBlitFramebuffer.
  bool has_gl_framebuffer_blit;

  // Shader program.
  GLuint program;

  // Location of layer offset in [program].
  GLuint offset_location;

  // Location of layer scale in [program].
  GLuint scale_location;

  // Verticies for the uniform square.
  GLuint vertex_buffer;

  // Framebuffers to render.
  GPtrArray* framebuffers;

  // Mutex used when blocking the raster thread until a task is completed on
  // platform thread.
  GMutex present_mutex;

  // Condition to unblock the raster thread after task is completed on platform
  // thread.
  GCond present_condition;
};

G_DEFINE_TYPE(FlCompositorOpenGL,
              fl_compositor_opengl,
              fl_compositor_get_type())

// Check if running on driver supporting blit.
static gboolean driver_supports_blit() {
  const gchar* vendor = reinterpret_cast<const gchar*>(glGetString(GL_VENDOR));

  // Note: List of unsupported vendors due to issue
  // https://github.com/flutter/flutter/issues/152099
  const char* unsupported_vendors_exact[] = {"Vivante Corporation", "ARM"};
  const char* unsupported_vendors_fuzzy[] = {"NVIDIA"};

  for (const char* unsupported : unsupported_vendors_fuzzy) {
    if (strstr(vendor, unsupported) != nullptr) {
      return FALSE;
    }
  }
  for (const char* unsupported : unsupported_vendors_exact) {
    if (strcmp(vendor, unsupported) == 0) {
      return FALSE;
    }
  }
  return TRUE;
}

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

static void fl_compositor_opengl_unblock_main_thread(FlCompositorOpenGL* self) {
  if (self->blocking_main_thread) {
    self->blocking_main_thread = false;

    g_autoptr(FlEngine) engine = FL_ENGINE(g_weak_ref_get(&self->engine));
    if (engine != nullptr) {
      fl_task_runner_release_main_thread(fl_engine_get_task_runner(engine));
    }
  }
}

static void setup_shader(FlCompositorOpenGL* self) {
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

static void render_with_blit(FlCompositorOpenGL* self,
                             GPtrArray* framebuffers) {
  // Disable the scissor test as it can affect blit operations.
  // Prevents regressions like: https://github.com/flutter/flutter/issues/140828
  // See OpenGL specification version 4.6, section 18.3.1.
  glDisable(GL_SCISSOR_TEST);

  for (guint i = 0; i < framebuffers->len; i++) {
    FlFramebuffer* framebuffer =
        FL_FRAMEBUFFER(g_ptr_array_index(framebuffers, i));

    GLuint framebuffer_id = fl_framebuffer_get_id(framebuffer);
    glBindFramebuffer(GL_READ_FRAMEBUFFER, framebuffer_id);
    size_t width = fl_framebuffer_get_width(framebuffer);
    size_t height = fl_framebuffer_get_height(framebuffer);
    glBlitFramebuffer(0, 0, width, height, 0, 0, width, height,
                      GL_COLOR_BUFFER_BIT, GL_NEAREST);
  }
  glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
}

static void render_with_textures(FlCompositorOpenGL* self,
                                 GPtrArray* framebuffers,
                                 int width,
                                 int height) {
  // Save bindings that are set by this function.  All bindings must be restored
  // to their original values because Skia expects that its bindings have not
  // been altered.
  GLint saved_texture_binding;
  glGetIntegerv(GL_TEXTURE_BINDING_2D, &saved_texture_binding);
  GLint saved_vao_binding;
  glGetIntegerv(GL_VERTEX_ARRAY_BINDING, &saved_vao_binding);
  GLint saved_array_buffer_binding;
  glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &saved_array_buffer_binding);

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

  for (guint i = 0; i < framebuffers->len; i++) {
    FlFramebuffer* framebuffer =
        FL_FRAMEBUFFER(g_ptr_array_index(framebuffers, i));

    // FIXME(robert-ancell): The offset from present_layers() is not here, needs
    // to be updated.
    size_t texture_width = fl_framebuffer_get_width(framebuffer);
    size_t texture_height = fl_framebuffer_get_height(framebuffer);
    glUniform2f(self->offset_location, 0, 0);
    glUniform2f(self->scale_location, texture_width / width,
                texture_height / height);

    GLuint texture_id = fl_framebuffer_get_texture_id(framebuffer);
    glBindTexture(GL_TEXTURE_2D, texture_id);

    glDrawArrays(GL_TRIANGLES, 0, 6);
  }

  glDeleteVertexArrays(1, &vao);

  glDisable(GL_BLEND);

  glBindTexture(GL_TEXTURE_2D, saved_texture_binding);
  glBindVertexArray(saved_vao_binding);
  glBindBuffer(GL_ARRAY_BUFFER, saved_array_buffer_binding);
}

static void render(FlCompositorOpenGL* self,
                   GPtrArray* framebuffers,
                   int width,
                   int height) {
  if (self->has_gl_framebuffer_blit) {
    render_with_blit(self, framebuffers);
  } else {
    render_with_textures(self, framebuffers, width, height);
  }
}

static gboolean present_layers(FlCompositorOpenGL* self,
                               const FlutterLayer** layers,
                               size_t layers_count) {
  g_return_val_if_fail(FL_IS_COMPOSITOR_OPENGL(self), FALSE);

  // ignore incoming frame with wrong dimensions in trivial case with just one
  // layer
  if (self->blocking_main_thread && layers_count == 1 &&
      layers[0]->offset.x == 0 && layers[0]->offset.y == 0 &&
      (layers[0]->size.width != self->target_width ||
       layers[0]->size.height != self->target_height)) {
    return TRUE;
  }

  self->had_first_frame = true;

  fl_compositor_opengl_unblock_main_thread(self);

  GLint general_format = GL_RGBA;
  if (epoxy_has_gl_extension("GL_EXT_texture_format_BGRA8888")) {
    general_format = GL_BGRA_EXT;
  }

  g_autoptr(GPtrArray) framebuffers =
      g_ptr_array_new_with_free_func(g_object_unref);
  for (size_t i = 0; i < layers_count; ++i) {
    const FlutterLayer* layer = layers[i];
    switch (layer->type) {
      case kFlutterLayerContentTypeBackingStore: {
        const FlutterBackingStore* backing_store = layer->backing_store;
        FlFramebuffer* framebuffer =
            FL_FRAMEBUFFER(backing_store->open_gl.framebuffer.user_data);
        g_ptr_array_add(framebuffers, g_object_ref(framebuffer));
      } break;
      case kFlutterLayerContentTypePlatformView: {
        // TODO(robert-ancell) Not implemented -
        // https://github.com/flutter/flutter/issues/41724
      } break;
    }
  }

  if (self->context == nullptr) {
    // Store for rendering later
    g_ptr_array_unref(self->framebuffers);
    self->framebuffers = g_ptr_array_ref(framebuffers);
  } else {
    // Composite into a single framebuffer.
    if (framebuffers->len > 1) {
      size_t width = 0, height = 0;

      for (guint i = 0; i < framebuffers->len; i++) {
        FlFramebuffer* framebuffer =
            FL_FRAMEBUFFER(g_ptr_array_index(framebuffers, i));

        size_t w = fl_framebuffer_get_width(framebuffer);
        size_t h = fl_framebuffer_get_height(framebuffer);
        if (w > width) {
          width = w;
        }
        if (h > height) {
          height = h;
        }
      }

      FlFramebuffer* view_framebuffer =
          fl_framebuffer_new(general_format, width, height);
      glBindFramebuffer(GL_DRAW_FRAMEBUFFER,
                        fl_framebuffer_get_id(view_framebuffer));
      render(self, framebuffers, width, height);
      g_ptr_array_set_size(framebuffers, 0);
      g_ptr_array_add(framebuffers, view_framebuffer);
    }

    // Read back pixel values.
    FlFramebuffer* framebuffer =
        FL_FRAMEBUFFER(g_ptr_array_index(framebuffers, 0));
    size_t width = fl_framebuffer_get_width(framebuffer);
    size_t height = fl_framebuffer_get_height(framebuffer);
    size_t data_length = width * height * 4;
    g_autofree uint8_t* data = static_cast<uint8_t*>(malloc(data_length));
    glBindFramebuffer(GL_READ_FRAMEBUFFER, fl_framebuffer_get_id(framebuffer));
    glReadPixels(0, 0, width, height, general_format, GL_UNSIGNED_BYTE, data);

    // Write into a texture in the views context.
    gdk_gl_context_make_current(self->context);
    g_autoptr(FlFramebuffer) view_framebuffer =
        fl_framebuffer_new(general_format, width, height);
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER,
                      fl_framebuffer_get_id(view_framebuffer));
    glBindTexture(GL_TEXTURE_2D,
                  fl_framebuffer_get_texture_id(view_framebuffer));
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA,
                 GL_UNSIGNED_BYTE, data);

    g_autoptr(GPtrArray) secondary_framebuffers =
        g_ptr_array_new_with_free_func(g_object_unref);
    g_ptr_array_add(secondary_framebuffers, g_object_ref(view_framebuffer));
    g_ptr_array_unref(self->framebuffers);
    self->framebuffers = g_ptr_array_ref(secondary_framebuffers);
  }

  return TRUE;
}

typedef struct {
  FlCompositorOpenGL* self;

  const FlutterLayer** layers;
  size_t layers_count;

  gboolean result;

  gboolean finished;
} PresentLayersData;

// Perform the present on the main thread.
static void present_layers_task_cb(gpointer user_data) {
  PresentLayersData* data = static_cast<PresentLayersData*>(user_data);
  FlCompositorOpenGL* self = data->self;

  // Perform the present.
  fl_opengl_manager_make_current(self->opengl_manager);
  data->result = present_layers(self, data->layers, data->layers_count);
  fl_opengl_manager_clear_current(self->opengl_manager);

  // Complete fl_compositor_opengl_present_layers().
  g_autoptr(GMutexLocker) locker = g_mutex_locker_new(&self->present_mutex);
  data->finished = TRUE;
  g_cond_signal(&self->present_condition);
}

static FlutterRendererType fl_compositor_opengl_get_renderer_type(
    FlCompositor* compositor) {
  return kOpenGL;
}

static void fl_compositor_opengl_wait_for_frame(FlCompositor* compositor,
                                                int target_width,
                                                int target_height) {
  FlCompositorOpenGL* self = FL_COMPOSITOR_OPENGL(compositor);

  self->target_width = target_width;
  self->target_height = target_height;

  if (self->had_first_frame && !self->blocking_main_thread) {
    self->blocking_main_thread = true;
    g_autoptr(FlEngine) engine = FL_ENGINE(g_weak_ref_get(&self->engine));
    if (engine != nullptr) {
      fl_task_runner_block_main_thread(fl_engine_get_task_runner(engine));
    }
  }
}

static gboolean fl_compositor_opengl_present_layers(FlCompositor* compositor,
                                                    const FlutterLayer** layers,
                                                    size_t layers_count) {
  FlCompositorOpenGL* self = FL_COMPOSITOR_OPENGL(compositor);

  // Detach the context from raster thread. Needed because blitting
  // will be done on the main thread, which will make the context current.
  fl_opengl_manager_clear_current(self->opengl_manager);

  g_autoptr(FlEngine) engine = FL_ENGINE(g_weak_ref_get(&self->engine));

  // Schedule the present to run on the main thread.
  FlTaskRunner* task_runner = fl_engine_get_task_runner(engine);
  PresentLayersData data = {
      .self = self,
      .layers = layers,
      .layers_count = layers_count,
      .result = FALSE,
      .finished = FALSE,
  };
  fl_task_runner_post_callback(task_runner, present_layers_task_cb, &data);

  // Block until present completes.
  g_autoptr(GMutexLocker) locker = g_mutex_locker_new(&self->present_mutex);
  while (!data.finished) {
    g_cond_wait(&self->present_condition, &self->present_mutex);
  }

  // Restore the context to the raster thread in case the engine needs it
  // to do some cleanup.
  fl_opengl_manager_make_current(self->opengl_manager);

  return data.result;
}

static void fl_compositor_opengl_dispose(GObject* object) {
  FlCompositorOpenGL* self = FL_COMPOSITOR_OPENGL(object);

  fl_compositor_opengl_unblock_main_thread(self);

  g_weak_ref_clear(&self->engine);
  g_clear_object(&self->context);
  g_clear_object(&self->opengl_manager);
  g_clear_pointer(&self->framebuffers, g_ptr_array_unref);
  g_mutex_clear(&self->present_mutex);
  g_cond_clear(&self->present_condition);

  G_OBJECT_CLASS(fl_compositor_opengl_parent_class)->dispose(object);
}

static void fl_compositor_opengl_class_init(FlCompositorOpenGLClass* klass) {
  FL_COMPOSITOR_CLASS(klass)->get_renderer_type =
      fl_compositor_opengl_get_renderer_type;
  FL_COMPOSITOR_CLASS(klass)->wait_for_frame =
      fl_compositor_opengl_wait_for_frame;
  FL_COMPOSITOR_CLASS(klass)->present_layers =
      fl_compositor_opengl_present_layers;

  G_OBJECT_CLASS(klass)->dispose = fl_compositor_opengl_dispose;
}

static void fl_compositor_opengl_init(FlCompositorOpenGL* self) {
  self->framebuffers = g_ptr_array_new();
  g_mutex_init(&self->present_mutex);
  g_cond_init(&self->present_condition);
}

FlCompositorOpenGL* fl_compositor_opengl_new(FlEngine* engine,
                                             GdkGLContext* context) {
  FlCompositorOpenGL* self = FL_COMPOSITOR_OPENGL(
      g_object_new(fl_compositor_opengl_get_type(), nullptr));

  g_weak_ref_init(&self->engine, engine);
  self->context =
      context != nullptr ? GDK_GL_CONTEXT(g_object_ref(context)) : nullptr;
  self->opengl_manager =
      FL_OPENGL_MANAGER(g_object_ref(fl_engine_get_opengl_manager(engine)));

  fl_opengl_manager_make_current(self->opengl_manager);

  self->has_gl_framebuffer_blit =
      driver_supports_blit() &&
      (epoxy_gl_version() >= 30 ||
       epoxy_has_gl_extension("GL_EXT_framebuffer_blit"));

  if (!self->has_gl_framebuffer_blit) {
    setup_shader(self);
  }

  return self;
}

void fl_compositor_opengl_render(FlCompositorOpenGL* self,
                                 int width,
                                 int height) {
  g_return_if_fail(FL_IS_COMPOSITOR_OPENGL(self));

  glClearColor(0.0, 0.0, 0.0, 0.0);
  glClear(GL_COLOR_BUFFER_BIT);

  render(self, self->framebuffers, width, height);

  glFlush();
}

void fl_compositor_opengl_cleanup(FlCompositorOpenGL* self) {
  g_return_if_fail(FL_IS_COMPOSITOR_OPENGL(self));

  if (self->program != 0) {
    glDeleteProgram(self->program);
  }
  if (self->vertex_buffer != 0) {
    glDeleteBuffers(1, &self->vertex_buffer);
  }
}
