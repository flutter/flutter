#if FLUTTER_LINUX_GTK4
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
#include "flutter/shell/platform/linux/fl_gtk.h"
#if FLUTTER_LINUX_GTK4 && GTK_CHECK_VERSION(4, 12, 0)
#include <gdk/gdkgltexturebuilder.h>
#endif

struct _FlCompositorOpenGL {
  FlCompositor parent_instance;

  // Task runner to wait for frames on.
  FlTaskRunner* task_runner;

  // TRUE if can share framebuffers between contexts.
  gboolean shareable;

  // Flutter OpenGL contexts.
  FlOpenGLManager* opengl_manager;

  // OpenGL shader program and vertex buffer.
  GLuint program;
  GLuint vertex_buffer;
  GLint offset_location;
  GLint scale_location;

  // Last rendered frame.
  FlFramebuffer* framebuffer;

  // Last rendered frame pixels (only set if shareable is FALSE).
  uint8_t* pixels;

  // Size of the allocated pixel buffer.
  size_t pixels_length;

  // TRUE when self->pixels are in Cairo/GDK default BGRA byte order.
  gboolean pixels_are_bgra;

  // whether the renderer waits for frame render
  bool blocking_main_thread;

  // true if frame was completed; resizing is not synchronized until first frame
  // was rendered
  bool had_first_frame;

  // Shader program used to composite layers.
  FlCompositorOpenGLShader* shader;

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

  uint8_t* pixels =
      static_cast<uint8_t*>(g_try_realloc(self->pixels, data_length));
  if (pixels == nullptr) {
    return false;
  }

  self->pixels = pixels;
  self->pixels_length = data_length;
  return true;
}

#if FLUTTER_LINUX_GTK4
static gboolean gtk4_readback_disabled() {
  return g_strcmp0(g_getenv("FLUTTER_GTK4_DISABLE_READBACK"), "1") == 0;
}

// Used only by the GTK4 readback/memory-texture fallback. The native
// GdkGLTexture path keeps the frame on the GPU and does not swizzle pixels.
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

static void draw_texture_to_cairo(cairo_t* cr,
                                  FlGdkSurface* surface,
                                  GLuint texture_id,
                                  gint scale_factor,
                                  size_t width,
                                  size_t height) {
#if FLUTTER_LINUX_GTK4
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
#endif
  gdk_cairo_draw_from_gl(cr, surface, texture_id, GL_TEXTURE, scale_factor, 0,
                         0, width, height);
#if FLUTTER_LINUX_GTK4
  G_GNUC_END_IGNORE_DEPRECATIONS
#endif
}

static void paint_shareable_framebuffer(FlFramebuffer* framebuffer,
                                        cairo_t* cr,
                                        FlGdkSurface* surface,
                                        gint scale_factor,
                                        size_t width,
                                        size_t height) {
  g_autoptr(FlFramebuffer) sibling = fl_framebuffer_create_sibling(framebuffer);
  draw_texture_to_cairo(cr, surface, fl_framebuffer_get_texture_id(sibling),
                        scale_factor, width, height);
}

static void paint_readback_framebuffer(FlCompositorOpenGL* self,
                                       cairo_t* cr,
                                       FlGdkSurface* surface,
                                       gint scale_factor,
                                       size_t width,
                                       size_t height) {
  GLint saved_texture_binding;
  glGetIntegerv(GL_TEXTURE_BINDING_2D, &saved_texture_binding);

  GLuint texture_id;
  glGenTextures(1, &texture_id);
  glBindTexture(GL_TEXTURE_2D, texture_id);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA,
               GL_UNSIGNED_BYTE, self->pixels);

  draw_texture_to_cairo(cr, surface, texture_id, scale_factor, width, height);

  glDeleteTextures(1, &texture_id);
  glBindTexture(GL_TEXTURE_2D, saved_texture_binding);
}

#if FLUTTER_LINUX_GTK4
struct Gtk4NativeTextureData {
  FlFramebuffer* framebuffer;
};

static void release_native_texture_data(gpointer user_data) {
  Gtk4NativeTextureData* data = static_cast<Gtk4NativeTextureData*>(user_data);
  g_clear_object(&data->framebuffer);
  g_free(data);
}

static GdkTexture* acquire_shareable_texture(FlFramebuffer* framebuffer,
                                             GdkGLContext* context) {
  g_return_val_if_fail(framebuffer != nullptr, nullptr);
  g_return_val_if_fail(context != nullptr, nullptr);

  g_autoptr(FlFramebuffer) sibling = fl_framebuffer_create_sibling(framebuffer);
  if (sibling == nullptr) {
    return nullptr;
  }

  Gtk4NativeTextureData* data = g_new0(Gtk4NativeTextureData, 1);
  data->framebuffer = FL_FRAMEBUFFER(g_object_ref(sibling));
#if GTK_CHECK_VERSION(4, 12, 0)
  g_autoptr(GdkGLTextureBuilder) builder = gdk_gl_texture_builder_new();
  gdk_gl_texture_builder_set_context(builder, context);
  gdk_gl_texture_builder_set_id(builder,
                                fl_framebuffer_get_texture_id(sibling));
  gdk_gl_texture_builder_set_width(
      builder, static_cast<int>(fl_framebuffer_get_width(framebuffer)));
  gdk_gl_texture_builder_set_height(
      builder, static_cast<int>(fl_framebuffer_get_height(framebuffer)));
  return gdk_gl_texture_builder_build(builder, release_native_texture_data,
                                      data);
#else
  return gdk_gl_texture_new(
      context, fl_framebuffer_get_texture_id(sibling),
      static_cast<int>(fl_framebuffer_get_width(framebuffer)),
      static_cast<int>(fl_framebuffer_get_height(framebuffer)),
      release_native_texture_data, data);
#endif
}

static GdkTexture* acquire_memory_texture(FlCompositorOpenGL* self,
                                          FlFramebuffer* framebuffer) {
  g_return_val_if_fail(framebuffer != nullptr, nullptr);
  g_return_val_if_fail(self->pixels != nullptr, nullptr);

  const int width = static_cast<int>(fl_framebuffer_get_width(framebuffer));
  const int height = static_cast<int>(fl_framebuffer_get_height(framebuffer));
  if (!self->pixels_are_bgra) {
    // glReadPixels populates RGBA bytes. GDK_MEMORY_DEFAULT matches Cairo's
    // native-endian ARGB32 memory layout, which is BGRA on little-endian hosts.
    swizzle_rgba_to_bgra(self->pixels, width, height);
    self->pixels_are_bgra = TRUE;
  }

  const gsize stride =
      cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
  g_autoptr(GBytes) bytes = g_bytes_new(self->pixels, stride * height);
  return gdk_memory_texture_new(width, height, GDK_MEMORY_DEFAULT, bytes,
                                stride);
}

static GdkTexture* fl_compositor_opengl_acquire_texture(
    FlCompositor* compositor,
    FlGdkSurface* surface,
    GdkGLContext* context,
    size_t width,
    size_t height,
    gboolean wait_for_frame) {
  FlCompositorOpenGL* self = FL_COMPOSITOR_OPENGL(compositor);
  (void)surface;

  g_mutex_lock(&self->frame_mutex);
  if (self->framebuffer == nullptr) {
    g_mutex_unlock(&self->frame_mutex);
    return nullptr;
  }

  gint64 expiry_time =
      g_get_monotonic_time() + kCompositorRenderTimeoutMicroseconds;
  while (true) {
    if (!wait_for_frame) {
      break;
    }

    size_t framebuffer_width = fl_framebuffer_get_width(self->framebuffer);
    size_t framebuffer_height = fl_framebuffer_get_height(self->framebuffer);
    if (framebuffer_width == width && framebuffer_height == height) {
      break;
    }

    if (g_get_monotonic_time() > expiry_time) {
      g_warning(
          "Timed out waiting for OpenGL frame of size %zdx%zd (have %zdx%zd)",
          width, height, framebuffer_width, framebuffer_height);
      break;
    }

    g_mutex_unlock(&self->frame_mutex);
    fl_task_runner_wait(self->task_runner, expiry_time);
    g_mutex_lock(&self->frame_mutex);
  }

  GdkTexture* texture = nullptr;
  if (fl_framebuffer_get_shareable(self->framebuffer)) {
    texture = acquire_shareable_texture(self->framebuffer, context);
  } else {
    if (gtk4_readback_disabled()) {
      g_warning(
          "GTK4 OpenGL compositor readback disabled, but native texture "
          "sharing is unavailable");
      g_mutex_unlock(&self->frame_mutex);
      return nullptr;
    }
    texture = acquire_memory_texture(self, self->framebuffer);
  }

  g_mutex_unlock(&self->frame_mutex);
  return texture;
}
#endif

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
#if !FLUTTER_LINUX_GTK4
  if (epoxy_has_gl_extension("GL_EXT_texture_format_BGRA8888")) {
    general_format = GL_BGRA_EXT;
  }
#endif

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
  gint scale_factor = fl_gtk_surface_get_scale_factor(surface);
  size_t width, height;
  gint64 expiry_time =
      g_get_monotonic_time() + kCompositorRenderTimeoutMicroseconds;
  while (true) {
    width = fl_gtk_surface_get_width(surface) * scale_factor;
    height = fl_gtk_surface_get_height(surface) * scale_factor;
    if (!wait_for_frame) {
      break;
    }

    size_t framebuffer_width = fl_framebuffer_get_width(self->framebuffer);
    size_t framebuffer_height = fl_framebuffer_get_height(self->framebuffer);
    if (framebuffer_width == width && framebuffer_height == height) {
      break;
    }

    if (g_get_monotonic_time() > expiry_time) {
      g_warning(
          "Timed out waiting for OpenGL frame of size %zdx%zd (have %zdx%zd)",
          width, height, framebuffer_width, framebuffer_height);
      break;
    }

    g_mutex_unlock(&self->frame_mutex);
    fl_task_runner_wait(self->task_runner, expiry_time);
    g_mutex_lock(&self->frame_mutex);
  }

  if (fl_framebuffer_get_shareable(self->framebuffer)) {
    paint_shareable_framebuffer(self->framebuffer, cr, surface, scale_factor,
                                width, height);
  } else {
    paint_readback_framebuffer(self, cr, surface, scale_factor, width, height);
  }

  glFlush();

  g_mutex_unlock(&self->frame_mutex);

  return TRUE;
}

static void fl_compositor_opengl_dispose(GObject* object) {
  FlCompositorOpenGL* self = FL_COMPOSITOR_OPENGL(object);

  g_clear_object(&self->shader);

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
#if FLUTTER_LINUX_GTK4
  FL_COMPOSITOR_CLASS(klass)->acquire_texture =
      fl_compositor_opengl_acquire_texture;
#endif

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
  self->shader = fl_compositor_opengl_shader_new(opengl_manager);

  return self;
}
#else
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

  // TRUE if can share framebuffers between contexts.
  gboolean shareable;

  // Flutter OpenGL contexts.
  FlOpenGLManager* opengl_manager;

  // Last rendered frame.
  FlFramebuffer* framebuffer;

  // Last rendered frame pixels (only set if shareable is FALSE).
  uint8_t* pixels;

  // Shader program used to composite layers.
  FlCompositorOpenGLShader* shader;
};

G_DEFINE_TYPE(FlCompositorOpenGL, fl_compositor_opengl, G_TYPE_OBJECT)

static void fl_compositor_opengl_dispose(GObject* object) {
  FlCompositorOpenGL* self = FL_COMPOSITOR_OPENGL(object);

  g_clear_object(&self->shader);

  g_clear_object(&self->opengl_manager);
  g_clear_object(&self->framebuffer);
  g_clear_pointer(&self->pixels, g_free);

  G_OBJECT_CLASS(fl_compositor_opengl_parent_class)->dispose(object);
}

static void fl_compositor_opengl_class_init(FlCompositorOpenGLClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_compositor_opengl_dispose;
}

static void fl_compositor_opengl_init(FlCompositorOpenGL* self) {}

FlCompositorOpenGL* fl_compositor_opengl_new(FlOpenGLManager* opengl_manager,
                                             gboolean shareable) {
  FlCompositorOpenGL* self = FL_COMPOSITOR_OPENGL(
      g_object_new(fl_compositor_opengl_get_type(), nullptr));

  self->shareable = shareable;
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

gboolean fl_compositor_opengl_composite_layers(FlCompositorOpenGL* self,
                                               const FlutterLayer** layers,
                                               size_t layers_count) {
  if (layers_count == 0) {
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
      size_t data_length = width * height * 4;
      self->pixels =
          static_cast<uint8_t*>(g_realloc(self->pixels, data_length));
    }
  }

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
    glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
  }
  glBindFramebuffer(GL_READ_FRAMEBUFFER, saved_read_framebuffer_binding);

  return TRUE;
}

void fl_compositor_opengl_get_frame_size(FlCompositorOpenGL* self,
                                         size_t* width,
                                         size_t* height) {
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

gboolean fl_compositor_opengl_render(FlCompositorOpenGL* self,
                                     cairo_t* cr,
                                     GdkWindow* window) {
  if (self->framebuffer == nullptr) {
    return FALSE;
  }

  gint scale_factor = gdk_window_get_scale_factor(window);
  size_t width = gdk_window_get_width(window) * scale_factor;
  size_t height = gdk_window_get_height(window) * scale_factor;

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
    GLsizei fb_width = 0;
    GLsizei fb_height = 0;
    if (self->framebuffer != nullptr) {
      fb_width =
          static_cast<GLsizei>(fl_framebuffer_get_width(self->framebuffer));
      fb_height =
          static_cast<GLsizei>(fl_framebuffer_get_height(self->framebuffer));
    }
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
#endif
