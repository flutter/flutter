// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_compositor_opengl_private.h"

#include <epoxy/egl.h>
#include <epoxy/gl.h>
#include <errno.h>
#include <linux/dma-buf.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include "flutter/shell/platform/linux/fl_gtk4_runtime_api.h"
#include "flutter/shell/platform/linux/fl_linux_gtk4_debug.h"
#if GTK_CHECK_VERSION(4, 12, 0)
#include <gdk/gdkgltexturebuilder.h>
#endif

#if FLUTTER_LINUX_GTK4
static gboolean gtk4_readback_disabled() {
  return g_strcmp0(g_getenv("FLUTTER_GTK4_DISABLE_READBACK"), "1") == 0;
}

static gboolean gtk4_dmabuf_enabled() {
  return g_strcmp0(g_getenv("FLUTTER_GTK4_ENABLE_DMABUF"), "1") == 0;
}

static void update_dmabuf_sync(FlCompositorOpenGL* self) {
  if (self->dmabuf_sync_fd >= 0) {
    close(self->dmabuf_sync_fd);
    self->dmabuf_sync_fd = -1;
  }

  EGLDisplay display = eglGetCurrentDisplay();
  if (!gtk4_dmabuf_enabled() || self->dmabuf_disabled ||
      self->dmabuf_frame_failed || !fl_gtk_runtime_supports_dmabuf_textures() ||
      display == EGL_NO_DISPLAY ||
      !epoxy_has_egl_extension(display, "EGL_ANDROID_native_fence_sync")) {
    glFlush();
    return;
  }

  EGLSyncKHR sync =
      eglCreateSyncKHR(display, EGL_SYNC_NATIVE_FENCE_ANDROID, nullptr);
  glFlush();
  if (sync == EGL_NO_SYNC_KHR) {
    return;
  }

  int sync_fd = eglDupNativeFenceFDANDROID(display, sync);
  eglDestroySyncKHR(display, sync);
  if (sync_fd < 0) {
    return;
  }

  self->dmabuf_sync_fd = sync_fd;
}

static void log_dmabuf_format(guint32 fourcc,
                              guint64 modifier,
                              gpointer user_data) {
  (void)user_data;
  flutter_linux_gtk4_dbg("gtk4_dmabuf_capabilities",
                    "gdk_format fourcc=0x%x modifier=0x%" G_GINT64_MODIFIER "x",
                    fourcc, modifier);
}

static void log_dmabuf_capabilities(FlCompositorOpenGL* self,
                                    GdkDisplay* gdk_display) {
  if (self->dmabuf_capabilities_logged || !flutter_linux_gtk4_debug_enabled()) {
    return;
  }
  self->dmabuf_capabilities_logged = TRUE;

  const gboolean has_gtk_dmabuf = fl_gtk_runtime_supports_dmabuf_textures();
  EGLDisplay egl_display = eglGetCurrentDisplay();
  const gboolean has_egl_export =
      egl_display != EGL_NO_DISPLAY &&
      epoxy_has_egl_extension(egl_display, "EGL_MESA_image_dma_buf_export");
  const gboolean has_egl_import =
      egl_display != EGL_NO_DISPLAY &&
      epoxy_has_egl_extension(egl_display, "EGL_EXT_image_dma_buf_import");
  const gboolean has_egl_modifiers =
      egl_display != EGL_NO_DISPLAY &&
      epoxy_has_egl_extension(egl_display,
                              "EGL_EXT_image_dma_buf_import_modifiers");
  const gboolean has_native_fence =
      egl_display != EGL_NO_DISPLAY &&
      epoxy_has_egl_extension(egl_display, "EGL_ANDROID_native_fence_sync");

  if (has_gtk_dmabuf && gdk_display != nullptr) {
    fl_gtk_runtime_for_each_dmabuf_format(gdk_display, log_dmabuf_format,
                                          nullptr);
  }

  flutter_linux_gtk4_dbg("gtk4_dmabuf_capabilities",
                    "gtk_runtime=%u.%u.%u gtk_dmabuf=%d egl_current=%d "
                    "egl_import=%d egl_modifiers=%d egl_mesa_export=%d "
                    "native_fence=%d export_prototype_enabled=%d",
                    gtk_get_major_version(), gtk_get_minor_version(),
                    gtk_get_micro_version(), has_gtk_dmabuf,
                    egl_display != EGL_NO_DISPLAY, has_egl_import,
                    has_egl_modifiers, has_egl_export, has_native_fence,
                    gtk4_dmabuf_enabled());
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

// Returns the log for the given OpenGL shader. Must be freed by the caller.
#if FLUTTER_LINUX_GTK4
struct Gtk4NativeTextureData {
  FlFramebuffer* framebuffer;
  GdkGLContext* context;
};

struct Gtk4DmabufTextureData {
  FlCompositorOpenGL* compositor;
  guint snapshot_index;
  int fds[kFlGtk4DmabufMaxPlanes];
  int n_planes;
};

static void release_dmabuf_texture_data(gpointer user_data) {
  Gtk4DmabufTextureData* data = static_cast<Gtk4DmabufTextureData*>(user_data);
  for (int i = 0; i < data->n_planes; ++i) {
    if (data->fds[i] >= 0) {
      close(data->fds[i]);
    }
  }
  if (data->compositor != nullptr) {
    g_mutex_lock(&data->compositor->frame_mutex);
    Gtk4DmabufSnapshot& snapshot =
        data->compositor->dmabuf_snapshots[data->snapshot_index];
    if (snapshot.state == Gtk4DmabufSnapshotState::kInUse) {
      snapshot.state = Gtk4DmabufSnapshotState::kAvailable;
    }
    g_mutex_unlock(&data->compositor->frame_mutex);
    g_object_unref(data->compositor);
  }
  g_free(data);
}

static void log_dmabuf_fallback(FlCompositorOpenGL* self,
                                const gchar* reason,
                                gboolean disable) {
  if (!self->dmabuf_fallback_logged) {
    flutter_linux_gtk4_dbg("gtk4_dmabuf", "fallback=%s", reason);
    self->dmabuf_fallback_logged = TRUE;
  }
  if (disable) {
    self->dmabuf_disabled = TRUE;
  } else {
    self->dmabuf_frame_failed = TRUE;
  }
}

static void import_dmabuf_sync(FlCompositorOpenGL* self,
                               const Gtk4DmabufTextureData* data) {
  if (self->dmabuf_sync_fd < 0) {
    return;
  }

  dma_buf_import_sync_file sync = {
      .flags = DMA_BUF_SYNC_WRITE,
      .fd = self->dmabuf_sync_fd,
  };
  for (int i = 0; i < data->n_planes; ++i) {
    if (ioctl(data->fds[i], DMA_BUF_IOCTL_IMPORT_SYNC_FILE, &sync) != 0) {
      if (!self->dmabuf_sync_warning_logged) {
        flutter_linux_gtk4_dbg("gtk4_dmabuf",
                          "failed to import frame fence for plane %d: %s", i,
                          g_strerror(errno));
        self->dmabuf_sync_warning_logged = TRUE;
      }
      break;
    }
  }

  close(self->dmabuf_sync_fd);
  self->dmabuf_sync_fd = -1;
}

static void release_native_texture_data(gpointer user_data) {
  Gtk4NativeTextureData* data = static_cast<Gtk4NativeTextureData*>(user_data);

  // GDK may release the texture after snapshotting, when no GL context is
  // current. The sibling framebuffer belongs to the GDK context used to import
  // the EGL image, so make that context current before deleting its GL objects.
  GdkGLContext* old_context = gdk_gl_context_get_current();
  if (old_context != data->context) {
    gdk_gl_context_make_current(data->context);
  }
  g_clear_object(&data->framebuffer);
  if (old_context != data->context) {
    gdk_gl_context_clear_current();
    if (old_context != nullptr) {
      gdk_gl_context_make_current(old_context);
    }
  }
  g_clear_object(&data->context);
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
  data->context = GDK_GL_CONTEXT(g_object_ref(context));
#if GTK_CHECK_VERSION(4, 12, 0)
  g_autoptr(GdkGLTextureBuilder) builder = gdk_gl_texture_builder_new();
  gdk_gl_texture_builder_set_context(builder, context);
  gdk_gl_texture_builder_set_id(builder,
                                fl_framebuffer_get_texture_id(sibling));
  gdk_gl_texture_builder_set_width(
      builder, static_cast<int>(fl_framebuffer_get_width(framebuffer)));
  gdk_gl_texture_builder_set_height(
      builder, static_cast<int>(fl_framebuffer_get_height(framebuffer)));
  GdkTexture* texture =
      gdk_gl_texture_builder_build(builder, release_native_texture_data, data);
#else
  GdkTexture* texture = gdk_gl_texture_new(
      context, fl_framebuffer_get_texture_id(sibling),
      static_cast<int>(fl_framebuffer_get_width(framebuffer)),
      static_cast<int>(fl_framebuffer_get_height(framebuffer)),
      release_native_texture_data, data);
#endif
  if (texture == nullptr) {
    release_native_texture_data(data);
  }
  return texture;
}

static GdkTexture* acquire_dmabuf_texture(FlCompositorOpenGL* self,
                                          guint snapshot_index,
                                          FlFramebuffer* framebuffer,
                                          GdkDisplay* display) {
  if (!gtk4_dmabuf_enabled()) {
    return nullptr;
  }
  if (self->dmabuf_disabled || self->dmabuf_frame_failed) {
    return nullptr;
  }
  if (!fl_gtk_runtime_supports_dmabuf_textures()) {
    log_dmabuf_fallback(self, "GTK DMA-BUF API unavailable", TRUE);
    return nullptr;
  }
  if (display == nullptr) {
    log_dmabuf_fallback(self, "GDK display unavailable", FALSE);
    return nullptr;
  }

  FlEGLImage* egl_image = fl_framebuffer_get_egl_image(framebuffer);
  if (egl_image == nullptr) {
    log_dmabuf_fallback(self, "framebuffer has no EGL image", FALSE);
    return nullptr;
  }

  EGLDisplay egl_display = fl_egl_image_get_display(egl_image);
  if (egl_display == EGL_NO_DISPLAY ||
      !epoxy_has_egl_extension(egl_display, "EGL_MESA_image_dma_buf_export")) {
    log_dmabuf_fallback(self, "EGL DMA-BUF export unavailable", TRUE);
    return nullptr;
  }

  int fourcc = 0;
  int n_planes = 0;
  EGLuint64KHR modifier = 0;
  if (!eglExportDMABUFImageQueryMESA(egl_display,
                                     fl_egl_image_get_image(egl_image), &fourcc,
                                     &n_planes, &modifier) ||
      n_planes <= 0 || n_planes > static_cast<int>(kFlGtk4DmabufMaxPlanes)) {
    log_dmabuf_fallback(self, "EGL DMA-BUF query failed", FALSE);
    return nullptr;
  }

  if (!fl_gtk_runtime_dmabuf_format_supported(display, fourcc, modifier)) {
    if (!self->dmabuf_fallback_logged) {
      flutter_linux_gtk4_dbg("gtk4_dmabuf",
                        "fallback=GDK rejected format fourcc=0x%x "
                        "modifier=0x%" G_GINT64_MODIFIER "x planes=%d",
                        fourcc, modifier, n_planes);
      self->dmabuf_fallback_logged = TRUE;
      self->dmabuf_disabled = TRUE;
    }
    return nullptr;
  }

  Gtk4DmabufTextureData* data = g_new0(Gtk4DmabufTextureData, 1);
  data->snapshot_index = snapshot_index;
  data->n_planes = n_planes;
  for (guint i = 0; i < kFlGtk4DmabufMaxPlanes; ++i) {
    data->fds[i] = -1;
  }
  EGLint strides[kFlGtk4DmabufMaxPlanes] = {};
  EGLint offsets[kFlGtk4DmabufMaxPlanes] = {};
  if (!eglExportDMABUFImageMESA(egl_display, fl_egl_image_get_image(egl_image),
                                data->fds, strides, offsets)) {
    log_dmabuf_fallback(self, "EGL DMA-BUF export failed", FALSE);
    release_dmabuf_texture_data(data);
    return nullptr;
  }
  import_dmabuf_sync(self, data);

  FlGtk4DmabufDescriptor descriptor = {
      .width = static_cast<guint>(fl_framebuffer_get_width(framebuffer)),
      .height = static_cast<guint>(fl_framebuffer_get_height(framebuffer)),
      .fourcc = static_cast<guint32>(fourcc),
      .modifier = modifier,
      .premultiplied = TRUE,
      .n_planes = static_cast<guint>(n_planes),
  };
  for (int i = 0; i < n_planes; ++i) {
    descriptor.planes[i] = {
        .fd = data->fds[i],
        .stride = static_cast<guint>(strides[i]),
        .offset = static_cast<guint>(offsets[i]),
    };
  }

  g_autoptr(GError) error = nullptr;
  GdkTexture* texture = fl_gtk_runtime_build_dmabuf_texture(
      display, &descriptor, release_dmabuf_texture_data, data, &error);
  if (texture == nullptr) {
    flutter_linux_gtk4_dbg("gtk4_dmabuf",
                      "failed to build texture: %s; using GL texture",
                      error != nullptr ? error->message : "unknown error");
    self->dmabuf_fallback_logged = TRUE;
    self->dmabuf_frame_failed = TRUE;
    release_dmabuf_texture_data(data);
  } else {
    data->compositor = FL_COMPOSITOR_OPENGL(g_object_ref(self));
  }
  return texture;
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

static gboolean publish_dmabuf_snapshot(FlCompositorOpenGL* self,
                                        GLint format,
                                        size_t width,
                                        size_t height) {
  if (self->dmabuf_published_snapshot >= 0) {
    Gtk4DmabufSnapshot& previous =
        self->dmabuf_snapshots[self->dmabuf_published_snapshot];
    if (previous.state == Gtk4DmabufSnapshotState::kPublished) {
      previous.state = Gtk4DmabufSnapshotState::kAvailable;
    }
    self->dmabuf_published_snapshot = -1;
  }

  if (!gtk4_dmabuf_enabled() || self->dmabuf_disabled ||
      self->dmabuf_frame_failed || !fl_gtk_runtime_supports_dmabuf_textures()) {
    return FALSE;
  }

  // Snapshot export currently copies the rendered framebuffer with a blit.
  // Use the normal shared-texture fallback when the driver does not support a
  // reliable blit path.
  if (!self->can_blit) {
    log_dmabuf_fallback(self, "framebuffer blit unavailable", TRUE);
    return FALSE;
  }

  for (guint i = 0; i < kGtk4DmabufSnapshotCount; ++i) {
    Gtk4DmabufSnapshot& snapshot = self->dmabuf_snapshots[i];
    if (snapshot.state != Gtk4DmabufSnapshotState::kAvailable) {
      continue;
    }

    if (snapshot.framebuffer == nullptr ||
        fl_framebuffer_get_width(snapshot.framebuffer) != width ||
        fl_framebuffer_get_height(snapshot.framebuffer) != height) {
      g_clear_object(&snapshot.framebuffer);
      snapshot.framebuffer =
          fl_framebuffer_new_shareable(format, width, height);
    }
    if (!fl_framebuffer_get_shareable(snapshot.framebuffer)) {
      log_dmabuf_fallback(self, "snapshot is not exportable", TRUE);
      return FALSE;
    }

    glBindFramebuffer(GL_READ_FRAMEBUFFER,
                      fl_framebuffer_get_id(self->framebuffer));
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER,
                      fl_framebuffer_get_id(snapshot.framebuffer));
    if (glCheckFramebufferStatus(GL_DRAW_FRAMEBUFFER) !=
        GL_FRAMEBUFFER_COMPLETE) {
      log_dmabuf_fallback(self, "snapshot framebuffer is incomplete", TRUE);
      return FALSE;
    }
    glBlitFramebuffer(0, 0, width, height, 0, 0, width, height,
                      GL_COLOR_BUFFER_BIT, GL_NEAREST);

    snapshot.state = Gtk4DmabufSnapshotState::kPublished;
    self->dmabuf_published_snapshot = static_cast<gint>(i);
    self->dmabuf_snapshot_exhaustion_logged = FALSE;
    return TRUE;
  }

  if (!self->dmabuf_snapshot_exhaustion_logged) {
    flutter_linux_gtk4_dbg(
        "gtk4_dmabuf",
        "all snapshots are still owned by GTK; using GL texture fallback");
    self->dmabuf_snapshot_exhaustion_logged = TRUE;
  }
  return FALSE;
}

GdkTexture* fl_compositor_opengl_acquire_texture(FlCompositor* compositor,
                                                 FlGdkSurface* surface,
                                                 GdkGLContext* context,
                                                 size_t width,
                                                 size_t height,
                                                 gboolean wait_for_frame) {
  FlCompositorOpenGL* self = FL_COMPOSITOR_OPENGL(compositor);
  (void)surface;

  log_dmabuf_capabilities(self, gdk_gl_context_get_display(context));

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
    if (self->dmabuf_published_snapshot >= 0) {
      const guint snapshot_index =
          static_cast<guint>(self->dmabuf_published_snapshot);
      Gtk4DmabufSnapshot& snapshot = self->dmabuf_snapshots[snapshot_index];
      texture =
          acquire_dmabuf_texture(self, snapshot_index, snapshot.framebuffer,
                                 gdk_gl_context_get_display(context));
      snapshot.state = texture != nullptr ? Gtk4DmabufSnapshotState::kInUse
                                          : Gtk4DmabufSnapshotState::kAvailable;
      self->dmabuf_published_snapshot = -1;
    }
    if (texture != nullptr && !self->dmabuf_path_logged) {
      flutter_linux_gtk4_dbg("gtk4_dmabuf", "using exported DMA-BUF texture");
      self->dmabuf_path_logged = TRUE;
    }
    if (texture == nullptr) {
      texture = acquire_shareable_texture(self->framebuffer, context);
    }
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

void fl_compositor_opengl_gtk4_finish_present(FlCompositorOpenGL* self,
                                              GLint format,
                                              size_t width,
                                              size_t height) {
  if (self->shareable && publish_dmabuf_snapshot(self, format, width, height)) {
    update_dmabuf_sync(self);
    return;
  }

  if (self->dmabuf_sync_fd >= 0) {
    close(self->dmabuf_sync_fd);
    self->dmabuf_sync_fd = -1;
  }
  glFlush();
}

void fl_compositor_opengl_gtk4_reset_frame_failure(FlCompositorOpenGL* self) {
  self->dmabuf_frame_failed = FALSE;
  if (self->dmabuf_sync_fd >= 0) {
    close(self->dmabuf_sync_fd);
    self->dmabuf_sync_fd = -1;
  }
}

void fl_compositor_opengl_gtk4_init(FlCompositorOpenGL* self) {
  self->dmabuf_published_snapshot = -1;
  self->dmabuf_sync_fd = -1;
}

void fl_compositor_opengl_gtk4_dispose(FlCompositorOpenGL* self) {
  for (Gtk4DmabufSnapshot& snapshot : self->dmabuf_snapshots) {
    g_clear_object(&snapshot.framebuffer);
  }
  if (self->dmabuf_sync_fd >= 0) {
    close(self->dmabuf_sync_fd);
    self->dmabuf_sync_fd = -1;
  }
}
#endif
