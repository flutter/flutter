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
    "varying vec2 texcoord;\n"
    "\n"
    "void main() {\n"
    "  gl_Position = vec4(position, 0, 1);\n"
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

  // OpenGL contexts.
  FlOpenGLManager* opengl_manager;

  // Flag to track lazy initialization.
  gboolean initialized;

  // The pixel format passed to the engine.
  GLint sized_format;

  // The format used to create textures.
  GLint general_format;

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

  // Framebuffers to render keyed by view ID.
  GHashTable* framebuffers_by_view_id;

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

// Check if running on an NVIDIA driver.
static gboolean is_nvidia() {
  const gchar* vendor = reinterpret_cast<const gchar*>(glGetString(GL_VENDOR));
  return strstr(vendor, "NVIDIA") != nullptr;
}

// Check if running on an Vivante Corporation driver.
static gboolean is_vivante() {
  const gchar* vendor = reinterpret_cast<const gchar*>(glGetString(GL_VENDOR));
  return strstr(vendor, "Vivante Corporation") != nullptr;
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

/// Converts a pixel co-ordinate from 0..pixels to OpenGL -1..1.
static GLfloat pixels_to_gl_coords(GLfloat position, GLfloat pixels) {
  return (2.0 * position / pixels) - 1.0;
}

// Perform single run OpenGL initialization.
static void initialize(FlCompositorOpenGL* self) {
  if (self->initialized) {
    return;
  }
  self->initialized = TRUE;

  if (epoxy_has_gl_extension("GL_EXT_texture_format_BGRA8888")) {
    self->sized_format = GL_BGRA8_EXT;
    self->general_format = GL_BGRA_EXT;
  } else {
    self->sized_format = GL_RGBA8;
    self->general_format = GL_RGBA;
  }
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

  glDeleteShader(vertex_shader);
  glDeleteShader(fragment_shader);
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

  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  glUseProgram(self->program);

  for (guint i = 0; i < framebuffers->len; i++) {
    FlFramebuffer* framebuffer =
        FL_FRAMEBUFFER(g_ptr_array_index(framebuffers, i));

    GLuint texture_id = fl_framebuffer_get_texture_id(framebuffer);
    glBindTexture(GL_TEXTURE_2D, texture_id);

    // Translate into OpenGL co-ordinates
    size_t texture_width = fl_framebuffer_get_width(framebuffer);
    size_t texture_height = fl_framebuffer_get_height(framebuffer);
    GLfloat x0 = pixels_to_gl_coords(0, width);
    GLfloat y0 = pixels_to_gl_coords(height - texture_height, height);
    GLfloat x1 = pixels_to_gl_coords(texture_width, width);
    GLfloat y1 = pixels_to_gl_coords(height, height);
    GLfloat vertex_data[] = {x0, y0, 0, 0, x1, y1, 1, 1, x0, y1, 0, 1,
                             x0, y0, 0, 0, x1, y0, 1, 0, x1, y1, 1, 1};

    GLuint vao, vertex_buffer;
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);
    glGenBuffers(1, &vertex_buffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertex_buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertex_data), vertex_data,
                 GL_STATIC_DRAW);
    GLint position_index = glGetAttribLocation(self->program, "position");
    glEnableVertexAttribArray(position_index);
    glVertexAttribPointer(position_index, 2, GL_FLOAT, GL_FALSE,
                          sizeof(GLfloat) * 4, 0);
    GLint texcoord_index = glGetAttribLocation(self->program, "in_texcoord");
    glEnableVertexAttribArray(texcoord_index);
    glVertexAttribPointer(texcoord_index, 2, GL_FLOAT, GL_FALSE,
                          sizeof(GLfloat) * 4,
                          reinterpret_cast<void*>(sizeof(GLfloat) * 2));

    glDrawArrays(GL_TRIANGLES, 0, 6);

    glDeleteVertexArrays(1, &vao);
    glDeleteBuffers(1, &vertex_buffer);
  }

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
                               FlutterViewId view_id,
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

  g_autoptr(FlEngine) engine = FL_ENGINE(g_weak_ref_get(&self->engine));
  if (engine == nullptr) {
    return TRUE;
  }
  g_autoptr(FlRenderable) renderable =
      fl_engine_get_renderable(engine, view_id);
  if (renderable == nullptr) {
    return TRUE;
  }

  if (view_id == flutter::kFlutterImplicitViewId) {
    // Store for rendering later
    g_hash_table_insert(self->framebuffers_by_view_id, GINT_TO_POINTER(view_id),
                        g_ptr_array_ref(framebuffers));
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
          fl_framebuffer_new(self->general_format, width, height);
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
    glReadPixels(0, 0, width, height, self->general_format, GL_UNSIGNED_BYTE,
                 data);

    // Write into a texture in the views context.
    fl_renderable_make_current(renderable);
    FlFramebuffer* view_framebuffer =
        fl_framebuffer_new(self->general_format, width, height);
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER,
                      fl_framebuffer_get_id(view_framebuffer));
    glBindTexture(GL_TEXTURE_2D,
                  fl_framebuffer_get_texture_id(view_framebuffer));
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA,
                 GL_UNSIGNED_BYTE, data);

    g_autoptr(GPtrArray) secondary_framebuffers =
        g_ptr_array_new_with_free_func(g_object_unref);
    g_ptr_array_add(secondary_framebuffers, g_object_ref(view_framebuffer));
    g_hash_table_insert(self->framebuffers_by_view_id, GINT_TO_POINTER(view_id),
                        g_ptr_array_ref(secondary_framebuffers));
  }

  fl_renderable_redraw(renderable);

  return TRUE;
}

typedef struct {
  FlCompositorOpenGL* self;

  FlutterViewId view_id;

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
  data->result =
      present_layers(self, data->view_id, data->layers, data->layers_count);
  fl_opengl_manager_clear_current(self->opengl_manager);

  // Complete fl_compositor_opengl_present_layers().
  g_autoptr(GMutexLocker) locker = g_mutex_locker_new(&self->present_mutex);
  data->finished = TRUE;
  g_cond_signal(&self->present_condition);
}

static gboolean fl_compositor_opengl_create_backing_store(
    FlCompositor* compositor,
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
  FlCompositorOpenGL* self = FL_COMPOSITOR_OPENGL(compositor);

  fl_opengl_manager_make_current(self->opengl_manager);

  initialize(self);

  FlFramebuffer* framebuffer = fl_framebuffer_new(
      self->general_format, config->size.width, config->size.height);
  if (!framebuffer) {
    g_warning("Failed to create backing store");
    return FALSE;
  }

  backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
  backing_store_out->open_gl.type = kFlutterOpenGLTargetTypeFramebuffer;
  backing_store_out->open_gl.framebuffer.user_data = framebuffer;
  backing_store_out->open_gl.framebuffer.name =
      fl_framebuffer_get_id(framebuffer);
  backing_store_out->open_gl.framebuffer.target = self->sized_format;
  backing_store_out->open_gl.framebuffer.destruction_callback = [](void* p) {
    // Backing store destroyed in fl_compositor_opengl_collect_backing_store(),
    // set on FlutterCompositor.collect_backing_store_callback during engine
    // start.
  };

  return TRUE;
}

static gboolean fl_compositor_opengl_collect_backing_store(
    FlCompositor* compositor,
    const FlutterBackingStore* backing_store) {
  FlCompositorOpenGL* self = FL_COMPOSITOR_OPENGL(compositor);

  fl_opengl_manager_make_current(self->opengl_manager);

  // OpenGL context is required when destroying #FlFramebuffer.
  g_object_unref(backing_store->open_gl.framebuffer.user_data);
  return TRUE;
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
                                                    FlutterViewId view_id,
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
      .view_id = view_id,
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
  g_clear_object(&self->opengl_manager);
  g_clear_pointer(&self->framebuffers_by_view_id, g_hash_table_unref);
  g_mutex_clear(&self->present_mutex);
  g_cond_clear(&self->present_condition);

  G_OBJECT_CLASS(fl_compositor_opengl_parent_class)->dispose(object);
}

static void fl_compositor_opengl_class_init(FlCompositorOpenGLClass* klass) {
  FL_COMPOSITOR_CLASS(klass)->create_backing_store =
      fl_compositor_opengl_create_backing_store;
  FL_COMPOSITOR_CLASS(klass)->collect_backing_store =
      fl_compositor_opengl_collect_backing_store;
  FL_COMPOSITOR_CLASS(klass)->wait_for_frame =
      fl_compositor_opengl_wait_for_frame;
  FL_COMPOSITOR_CLASS(klass)->present_layers =
      fl_compositor_opengl_present_layers;

  G_OBJECT_CLASS(klass)->dispose = fl_compositor_opengl_dispose;
}

static void fl_compositor_opengl_init(FlCompositorOpenGL* self) {
  self->framebuffers_by_view_id = g_hash_table_new_full(
      g_direct_hash, g_direct_equal, nullptr,
      reinterpret_cast<GDestroyNotify>(g_ptr_array_unref));
  g_mutex_init(&self->present_mutex);
  g_cond_init(&self->present_condition);
}

FlCompositorOpenGL* fl_compositor_opengl_new(FlEngine* engine) {
  FlCompositorOpenGL* self = FL_COMPOSITOR_OPENGL(
      g_object_new(fl_compositor_opengl_get_type(), nullptr));

  g_weak_ref_init(&self->engine, engine);
  self->opengl_manager =
      FL_OPENGL_MANAGER(g_object_ref(fl_engine_get_opengl_manager(engine)));

  return self;
}

void fl_compositor_opengl_setup(FlCompositorOpenGL* self) {
  g_return_if_fail(FL_IS_COMPOSITOR_OPENGL(self));

  // Note: NVIDIA and Vivante are temporarily disabled due to
  // https://github.com/flutter/flutter/issues/152099
  self->has_gl_framebuffer_blit =
      !is_nvidia() && !is_vivante() &&
      (epoxy_gl_version() >= 30 ||
       epoxy_has_gl_extension("GL_EXT_framebuffer_blit"));

  if (!self->has_gl_framebuffer_blit) {
    setup_shader(self);
  }
}

void fl_compositor_opengl_render(FlCompositorOpenGL* self,
                                 FlutterViewId view_id,
                                 int width,
                                 int height,
                                 const GdkRGBA* background_color) {
  g_return_if_fail(FL_IS_COMPOSITOR_OPENGL(self));

  glClearColor(background_color->red, background_color->green,
               background_color->blue, background_color->alpha);
  glClear(GL_COLOR_BUFFER_BIT);

  GPtrArray* framebuffers = reinterpret_cast<GPtrArray*>((g_hash_table_lookup(
      self->framebuffers_by_view_id, GINT_TO_POINTER(view_id))));
  if (framebuffers != nullptr) {
    render(self, framebuffers, width, height);
  }

  glFlush();
}

void fl_compositor_opengl_cleanup(FlCompositorOpenGL* self) {
  g_return_if_fail(FL_IS_COMPOSITOR_OPENGL(self));

  if (self->program != 0) {
    glDeleteProgram(self->program);
  }
}
