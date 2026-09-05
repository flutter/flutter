// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_OPENGL_PRIVATE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_OPENGL_PRIVATE_H_

#include "flutter/shell/platform/linux/fl_compositor_opengl.h"

#if FLUTTER_LINUX_GTK4
constexpr guint kGtk4DmabufSnapshotCount = 3;

enum class Gtk4DmabufSnapshotState {
  kAvailable,
  kPublished,
  kInUse,
};

struct Gtk4DmabufSnapshot {
  FlFramebuffer* framebuffer;
  Gtk4DmabufSnapshotState state;
};
#endif

struct _FlCompositorOpenGL {
  FlCompositor parent_instance;
  FlTaskRunner* task_runner;
  gboolean shareable;
  gboolean can_blit;
  gboolean can_fence;
  FlOpenGLManager* opengl_manager;
  FlFramebuffer* framebuffer;
  uint8_t* pixels;
  size_t pixels_length;
  gboolean pixels_are_bgra;
  bool blocking_main_thread;
  bool had_first_frame;

#if FLUTTER_LINUX_GTK4
  // Published EGL image storage must not be overwritten while GDK retains it.
  gboolean framebuffer_published;
  Gtk4DmabufSnapshot dmabuf_snapshots[kGtk4DmabufSnapshotCount];
  // Fence for a shareable framebuffer handed to GDK through a different GL
  // context. DMA-BUF textures have their own native fence.
  EGLDisplay native_texture_sync_display;
  EGLSyncKHR native_texture_sync;
  gboolean native_texture_sync_can_wait;
  gint dmabuf_published_snapshot;
  gboolean dmabuf_path_logged;
  gboolean dmabuf_capabilities_logged;
  gboolean dmabuf_fallback_logged;
  gboolean dmabuf_disabled;
  gboolean dmabuf_frame_failed;
  gboolean dmabuf_sync_warning_logged;
  gboolean dmabuf_snapshot_exhaustion_logged;
  int dmabuf_sync_fd;
#endif

  GLuint program;
  GLint offset_location;
  GLint scale_location;
  GLuint vertex_buffer;
  GMutex frame_mutex;
};

gboolean fl_compositor_opengl_ensure_pixel_buffer(FlCompositorOpenGL* self,
                                                  size_t width,
                                                  size_t height);

#if FLUTTER_LINUX_GTK4
gboolean fl_compositor_opengl_gtk4_wait_for_texture(FlCompositorOpenGL* self);
GdkTexture* fl_compositor_opengl_acquire_texture(FlCompositor* compositor,
                                                 FlGdkSurface* surface,
                                                 GdkGLContext* context,
                                                 size_t width,
                                                 size_t height,
                                                 gboolean wait_for_frame);
void fl_compositor_opengl_gtk4_finish_present(FlCompositorOpenGL* self,
                                              GLint format,
                                              size_t width,
                                              size_t height);
void fl_compositor_opengl_gtk4_reset_frame_failure(FlCompositorOpenGL* self);
void fl_compositor_opengl_gtk4_init(FlCompositorOpenGL* self);
void fl_compositor_opengl_gtk4_dispose(FlCompositorOpenGL* self);
#endif

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_OPENGL_PRIVATE_H_
