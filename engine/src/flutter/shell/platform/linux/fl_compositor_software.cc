// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_compositor_software.h"

#include "flutter/shell/platform/linux/fl_gtk.h"

struct _FlCompositorSoftware {
  FlCompositor parent_instance;

  // Task runner to wait for frames on.
  FlTaskRunner* task_runner;

  // Width of frame in pixels.
  size_t width;

  // Height of frame in pixels.
  size_t height;

  // Surface to draw on view.
  cairo_surface_t* surface;

  // Ensure Flutter and GTK can access the surface.
  GMutex frame_mutex;
};

G_DEFINE_TYPE(FlCompositorSoftware,
              fl_compositor_software,
              fl_compositor_get_type())

static gboolean fl_compositor_software_present_layers(
    FlCompositor* compositor,
    const FlutterLayer** layers,
    size_t layers_count) {
  FlCompositorSoftware* self = FL_COMPOSITOR_SOFTWARE(compositor);

  g_autoptr(GMutexLocker) locker = g_mutex_locker_new(&self->frame_mutex);

  if (layers_count == 0) {
    return TRUE;
  }

  self->width = layers[0]->size.width;
  self->height = layers[0]->size.height;

  // TODO(robert-ancell): Support multiple layers
  if (layers_count == 1) {
    const FlutterLayer* layer = layers[0];
    g_assert(layer->type == kFlutterLayerContentTypeBackingStore);
    g_assert(layer->backing_store->type == kFlutterBackingStoreTypeSoftware);
    const FlutterBackingStore* backing_store = layer->backing_store;

    size_t allocation_length =
        backing_store->software.row_bytes * backing_store->software.height;
    unsigned char* old_data = self->surface != nullptr
                                  ? cairo_image_surface_get_data(self->surface)
                                  : nullptr;
    unsigned char* data =
        static_cast<unsigned char*>(g_realloc(old_data, allocation_length));
    memcpy(data, backing_store->software.allocation, allocation_length);
    cairo_surface_destroy(self->surface);
    self->surface = cairo_image_surface_create_for_data(
        data, CAIRO_FORMAT_ARGB32, backing_store->software.row_bytes / 4,
        backing_store->software.height, backing_store->software.row_bytes);
  }

  fl_task_runner_stop_wait(self->task_runner);

  return TRUE;
}

static void fl_compositor_software_get_frame_size(FlCompositor* compositor,
                                                  size_t* width,
                                                  size_t* height) {
  FlCompositorSoftware* self = FL_COMPOSITOR_SOFTWARE(compositor);

  g_autoptr(GMutexLocker) locker = g_mutex_locker_new(&self->frame_mutex);

  if (width != nullptr) {
    *width = self->width;
  }
  if (height != nullptr) {
    *height = self->height;
  }
}

static gboolean fl_compositor_software_render(FlCompositor* compositor,
                                              cairo_t* cr,
                                              FlGdkSurface* surface,
                                              gboolean wait_for_frame) {
  FlCompositorSoftware* self = FL_COMPOSITOR_SOFTWARE(compositor);

  g_autoptr(GMutexLocker) locker = g_mutex_locker_new(&self->frame_mutex);

  if (self->surface == nullptr) {
    return FALSE;
  }

  // If frame not ready, then wait for it.
  const double scale = fl_gtk_surface_get_scale(surface);
  if (wait_for_frame) {
    gint64 expiry_time =
        g_get_monotonic_time() + kCompositorRenderTimeoutMicroseconds;
    while (true) {
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
      const gint buffer_scale = fl_gtk_surface_get_scale_factor(surface);
      size_t width = fl_gtk_surface_get_width(surface) * buffer_scale;
      size_t height = fl_gtk_surface_get_height(surface) * buffer_scale;
#endif
      if (self->width == width && self->height == height) {
        break;
      }

      if (g_get_monotonic_time() > expiry_time) {
        g_warning(
            "Timed out waiting for software frame of size %zdx%zd (have "
            "%zdx%zd)",
            width, height, self->width, self->height);
        break;
      }

      g_mutex_unlock(&self->frame_mutex);
      fl_task_runner_wait(self->task_runner, expiry_time);
      g_mutex_lock(&self->frame_mutex);
    }
  }

  cairo_surface_set_device_scale(self->surface, scale, scale);
  cairo_set_source_surface(cr, self->surface, 0.0, 0.0);
  cairo_paint(cr);

  return TRUE;
}

#if FLUTTER_LINUX_GTK4
static GdkTexture* fl_compositor_software_acquire_texture(
    FlCompositor* compositor,
    FlGdkSurface* surface,
    GdkGLContext* context,
    gboolean wait_for_frame) {
  (void)surface;
  (void)context;
  (void)wait_for_frame;

  FlCompositorSoftware* self = FL_COMPOSITOR_SOFTWARE(compositor);

  g_autoptr(GMutexLocker) locker = g_mutex_locker_new(&self->frame_mutex);

  if (self->surface == nullptr || self->width == 0 || self->height == 0) {
    return nullptr;
  }

  cairo_surface_flush(self->surface);
  const gsize stride = cairo_image_surface_get_stride(self->surface);
  const gsize length = stride * self->height;
  g_autoptr(GBytes) bytes =
      g_bytes_new(cairo_image_surface_get_data(self->surface), length);

  return gdk_memory_texture_new(static_cast<int>(self->width),
                                static_cast<int>(self->height),
                                GDK_MEMORY_DEFAULT, bytes, stride);
}
#endif

static void fl_compositor_software_dispose(GObject* object) {
  FlCompositorSoftware* self = FL_COMPOSITOR_SOFTWARE(object);

  g_clear_object(&self->task_runner);
  if (self->surface != nullptr) {
    g_free(cairo_image_surface_get_data(self->surface));
  }
  g_clear_pointer(&self->surface, cairo_surface_destroy);
  g_mutex_clear(&self->frame_mutex);

  G_OBJECT_CLASS(fl_compositor_software_parent_class)->dispose(object);
}

static void fl_compositor_software_class_init(
    FlCompositorSoftwareClass* klass) {
  FL_COMPOSITOR_CLASS(klass)->present_layers =
      fl_compositor_software_present_layers;
  FL_COMPOSITOR_CLASS(klass)->get_frame_size =
      fl_compositor_software_get_frame_size;
  FL_COMPOSITOR_CLASS(klass)->render = fl_compositor_software_render;
#if FLUTTER_LINUX_GTK4
  FL_COMPOSITOR_CLASS(klass)->acquire_texture =
      fl_compositor_software_acquire_texture;
#endif

  G_OBJECT_CLASS(klass)->dispose = fl_compositor_software_dispose;
}

static void fl_compositor_software_init(FlCompositorSoftware* self) {
  g_mutex_init(&self->frame_mutex);
}

FlCompositorSoftware* fl_compositor_software_new(FlTaskRunner* task_runner) {
  FlCompositorSoftware* self = FL_COMPOSITOR_SOFTWARE(
      g_object_new(fl_compositor_software_get_type(), nullptr));
  self->task_runner = FL_TASK_RUNNER(g_object_ref(task_runner));
  return self;
}
