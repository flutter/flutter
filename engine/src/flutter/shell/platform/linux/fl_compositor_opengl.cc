// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_compositor_opengl.h"

#include <cmath>

#include <epoxy/egl.h>
#include <epoxy/gl.h>

#include "flutter/common/constants.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_framebuffer.h"
#include "flutter/shell/platform/linux/fl_gtk.h"

// Vertex shader to draw Flutter window contents.
#if FLUTTER_LINUX_GTK4
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
#else
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
#endif

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

#if FLUTTER_LINUX_GTK4
constexpr size_t kGtk4ClientReadbackThresholdPixels = 4096;
#endif

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

  // Size of the allocated pixel buffer.
  size_t pixels_length;

  // TRUE when self->pixels are in Cairo-compatible BGRA byte order.
  gboolean pixels_are_bgra;

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

static bool ensure_pixel_buffer(FlCompositorOpenGL* self,
                                size_t width,
                                size_t height) {
  const size_t data_length = width * height * 4;
  if (self->pixels_length >= data_length) {
    return true;
  }

  uint8_t* pixels = static_cast<uint8_t*>(realloc(self->pixels, data_length));
  if (pixels == nullptr) {
    return false;
  }

  self->pixels = pixels;
  self->pixels_length = data_length;
  return true;
}

#if FLUTTER_LINUX_GTK4
static bool should_use_client_readback_fallback(FlGdkSurface* surface,
                                                size_t width,
                                                size_t height) {
  const gchar* force_readback = g_getenv("FLUTTER_GTK4_FORCE_CLIENT_READBACK");
  if (force_readback != nullptr &&
      (g_strcmp0(force_readback, "1") == 0 ||
       g_ascii_strcasecmp(force_readback, "true") == 0)) {
    return true;
  }

  return fl_gtk_surface_get_scale_factor(surface) > 1 &&
         (width > kGtk4ClientReadbackThresholdPixels ||
          height > kGtk4ClientReadbackThresholdPixels);
}

static void paint_pixels_with_cairo(cairo_t* cr,
                                    const uint8_t* pixels,
                                    size_t width,
                                    size_t height,
                                    gint buffer_scale) {
  cairo_save(cr);
  cairo_translate(cr, 0.0, static_cast<double>(height) / buffer_scale);
  cairo_scale(cr, 1.0 / buffer_scale, -1.0 / buffer_scale);

  const int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
  cairo_surface_t* image_surface = cairo_image_surface_create_for_data(
      const_cast<unsigned char*>(pixels), CAIRO_FORMAT_ARGB32, width, height,
      stride);
  cairo_set_source_surface(cr, image_surface, 0.0, 0.0);
  cairo_surface_destroy(image_surface);

  cairo_paint(cr);
  cairo_restore(cr);
}

static void swizzle_rgba_to_bgra(uint8_t* pixels, size_t width, size_t height) {
  const size_t pixel_count = width * height;
  for (size_t i = 0; i < pixel_count; ++i) {
    const size_t offset = i * 4;
    const uint8_t red = pixels[offset];
    pixels[offset] = pixels[offset + 2];
    pixels[offset + 2] = red;
  }
}
#endif

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
  if (!fl_opengl_manager_make_platform_current(self->opengl_manager)) {
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
  if (!fl_opengl_manager_make_platform_current(self->opengl_manager)) {
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
  GLint saved_draw_framebuffer_binding;
  glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &saved_draw_framebuffer_binding);
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
      if (!ensure_pixel_buffer(self, width, height)) {
        g_warning("Failed to allocate OpenGL compositor pixel buffer");
        g_mutex_unlock(&self->frame_mutex);
        return FALSE;
      }
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
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, saved_draw_framebuffer_binding);
  glUseProgram(saved_current_program);
  glBlendFuncSeparate(saved_src_rgb, saved_dst_rgb, saved_src_alpha,
                      saved_dst_alpha);

  if (!self->shareable) {
    glBindFramebuffer(GL_READ_FRAMEBUFFER,
                      fl_framebuffer_get_id(self->framebuffer));
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, self->pixels);
    self->pixels_are_bgra = FALSE;
    glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
  }
  glBindFramebuffer(GL_READ_FRAMEBUFFER, saved_read_framebuffer_binding);

  g_mutex_unlock(&self->frame_mutex);

  fl_task_runner_stop_wait(self->task_runner);

  return TRUE;
}

static void fl_compositor_opengl_get_frame_size(FlCompositor* compositor,
                                                size_t* width,
                                                size_t* height) {
  FlCompositorOpenGL* self = FL_COMPOSITOR_OPENGL(compositor);

  g_autoptr(GMutexLocker) locker = g_mutex_locker_new(&self->frame_mutex);

  if (width != nullptr) {
    *width = self->framebuffer != nullptr
                 ? fl_framebuffer_get_width(self->framebuffer)
                 : 0;
  }
  if (height != nullptr) {
    *height = self->framebuffer != nullptr
                  ? fl_framebuffer_get_height(self->framebuffer)
                  : 0;
  }
}

static gboolean fl_compositor_opengl_render(FlCompositor* compositor,
                                            cairo_t* cr,
                                            FlGdkSurface* surface,
                                            gboolean wait_for_frame) {
  FlCompositorOpenGL* self = FL_COMPOSITOR_OPENGL(compositor);

  g_mutex_lock(&self->frame_mutex);
  if (self->framebuffer == nullptr) {
    g_mutex_unlock(&self->frame_mutex);
    return FALSE;
  }

  // If frame not ready, then wait for it.
  const gint buffer_scale = fl_gtk_surface_get_scale_factor(surface);
  const double scale = fl_gtk_surface_get_scale(surface);
  const bool has_fractional_scale =
      std::abs(scale - static_cast<double>(buffer_scale)) > 0.001;
#if FLUTTER_LINUX_GTK4
  double x1 = 0.0, y1 = 0.0, x2 = 0.0, y2 = 0.0;
  cairo_clip_extents(cr, &x1, &y1, &x2, &y2);
  size_t width = fl_gtk_size_to_pixels(x2 - x1, scale);
  size_t height = fl_gtk_size_to_pixels(y2 - y1, scale);
  if (width == 0 || height == 0) {
    width = fl_gtk_surface_get_width(surface);
    height = fl_gtk_surface_get_height(surface);
  }
#else
  size_t width = fl_gtk_surface_get_width(surface) * buffer_scale;
  size_t height = fl_gtk_surface_get_height(surface) * buffer_scale;
#endif
  const bool use_client_readback_fallback =
      should_use_client_readback_fallback(surface, width, height);
  if (wait_for_frame) {
    gint64 expiry_time =
        g_get_monotonic_time() + kCompositorRenderTimeoutMicroseconds;
    while (fl_framebuffer_get_width(self->framebuffer) != width ||
           fl_framebuffer_get_height(self->framebuffer) != height) {
      if (g_get_monotonic_time() > expiry_time) {
        g_warning(
            "Timed out waiting for OpenGL frame of size %zdx%zd (have %zdx%zd)",
            width, height, fl_framebuffer_get_width(self->framebuffer),
            fl_framebuffer_get_height(self->framebuffer));
        break;
      }
      g_mutex_unlock(&self->frame_mutex);
      fl_task_runner_wait(self->task_runner, expiry_time);
      g_mutex_lock(&self->frame_mutex);
    }
  }

  if (fl_framebuffer_get_shareable(self->framebuffer)) {
    g_autoptr(FlFramebuffer) sibling =
        fl_framebuffer_create_sibling(self->framebuffer);
    if (use_client_readback_fallback) {
      if (!ensure_pixel_buffer(self, width, height)) {
        g_warning("Failed to allocate OpenGL compositor fallback buffer");
        g_mutex_unlock(&self->frame_mutex);
        return FALSE;
      }

      GLint saved_read_framebuffer_binding;
      glGetIntegerv(GL_READ_FRAMEBUFFER_BINDING,
                    &saved_read_framebuffer_binding);
      glBindFramebuffer(GL_READ_FRAMEBUFFER, fl_framebuffer_get_id(sibling));
      glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE,
                   self->pixels);
      glBindFramebuffer(GL_READ_FRAMEBUFFER, saved_read_framebuffer_binding);
      swizzle_rgba_to_bgra(self->pixels, width, height);
      self->pixels_are_bgra = TRUE;
      paint_pixels_with_cairo(cr, self->pixels, width, height, buffer_scale);
    } else {
#if FLUTTER_LINUX_GTK4
      cairo_save(cr);
      if (has_fractional_scale) {
        cairo_translate(cr, 0.0, static_cast<double>(height) / scale);
        cairo_scale(cr, 1.0 / scale, -1.0 / scale);
      } else {
        cairo_translate(cr, 0.0, static_cast<double>(height));
        cairo_scale(cr, 1.0, -1.0);
      }
      G_GNUC_BEGIN_IGNORE_DEPRECATIONS
#endif
      gdk_cairo_draw_from_gl(cr, surface,
                             fl_framebuffer_get_texture_id(sibling), GL_TEXTURE,
                             has_fractional_scale ? 1 : buffer_scale, 0, 0,
                             width, height);
#if FLUTTER_LINUX_GTK4
      G_GNUC_END_IGNORE_DEPRECATIONS
      cairo_restore(cr);
#endif
    }
  } else {
    if (use_client_readback_fallback) {
      if (!self->pixels_are_bgra) {
        swizzle_rgba_to_bgra(self->pixels, width, height);
        self->pixels_are_bgra = TRUE;
      }
      paint_pixels_with_cairo(cr, self->pixels, width, height, buffer_scale);
    } else {
      GLint saved_texture_binding;
      glGetIntegerv(GL_TEXTURE_BINDING_2D, &saved_texture_binding);

      GLuint texture_id;
      glGenTextures(1, &texture_id);
      glBindTexture(GL_TEXTURE_2D, texture_id);
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA,
                   GL_UNSIGNED_BYTE, self->pixels);

#if FLUTTER_LINUX_GTK4
      cairo_save(cr);
      if (has_fractional_scale) {
        cairo_translate(cr, 0.0, static_cast<double>(height) / scale);
        cairo_scale(cr, 1.0 / scale, -1.0 / scale);
      } else {
        cairo_translate(cr, 0.0, static_cast<double>(height));
        cairo_scale(cr, 1.0, -1.0);
      }
      G_GNUC_BEGIN_IGNORE_DEPRECATIONS
#endif
      gdk_cairo_draw_from_gl(
          cr, surface, texture_id, GL_TEXTURE,
          has_fractional_scale ? 1 : buffer_scale, 0, 0, width, height);
#if FLUTTER_LINUX_GTK4
      G_GNUC_END_IGNORE_DEPRECATIONS
      cairo_restore(cr);
#endif

      glDeleteTextures(1, &texture_id);

      glBindTexture(GL_TEXTURE_2D, saved_texture_binding);
    }
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
  FL_COMPOSITOR_CLASS(klass)->get_frame_size =
      fl_compositor_opengl_get_frame_size;
  FL_COMPOSITOR_CLASS(klass)->render = fl_compositor_opengl_render;

  G_OBJECT_CLASS(klass)->dispose = fl_compositor_opengl_dispose;
}

static void fl_compositor_opengl_init(FlCompositorOpenGL* self) {
  g_mutex_init(&self->frame_mutex);
  self->pixels_are_bgra = FALSE;
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
