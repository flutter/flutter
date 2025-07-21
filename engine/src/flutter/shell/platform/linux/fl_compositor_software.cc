// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_compositor_software.h"

struct _FlCompositorSoftware {
  FlCompositor parent_instance;

  // Width of frame in pixels.
  size_t width;

  // Height of frame in pixels.
  size_t height;

  // Surface to draw on view.
  cairo_surface_t* surface;

  // Ensure Flutter and GTK can access the surface.
  GMutex frame_mutex;

  // Allow GTK to wait for Flutter to generate a suitable frame.
  GCond frame_cond;
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
        static_cast<unsigned char*>(realloc(old_data, allocation_length));
    memcpy(data, backing_store->software.allocation, allocation_length);
    cairo_surface_destroy(self->surface);
    self->surface = cairo_image_surface_create_for_data(
        data, CAIRO_FORMAT_ARGB32, backing_store->software.row_bytes / 4,
        backing_store->software.height, backing_store->software.row_bytes);
  }

  // Signal a frame is ready.
  g_cond_signal(&self->frame_cond);

  return TRUE;
}

static void fl_compositor_software_dispose(GObject* object) {
  FlCompositorSoftware* self = FL_COMPOSITOR_SOFTWARE(object);

  if (self->surface != nullptr) {
    free(cairo_image_surface_get_data(self->surface));
  }
  g_clear_pointer(&self->surface, cairo_surface_destroy);
  g_mutex_clear(&self->frame_mutex);
  g_cond_clear(&self->frame_cond);

  G_OBJECT_CLASS(fl_compositor_software_parent_class)->dispose(object);
}

static void fl_compositor_software_class_init(
    FlCompositorSoftwareClass* klass) {
  FL_COMPOSITOR_CLASS(klass)->present_layers =
      fl_compositor_software_present_layers;

  G_OBJECT_CLASS(klass)->dispose = fl_compositor_software_dispose;
}

static void fl_compositor_software_init(FlCompositorSoftware* self) {
  g_mutex_init(&self->frame_mutex);
  g_cond_init(&self->frame_cond);
}

FlCompositorSoftware* fl_compositor_software_new() {
  FlCompositorSoftware* self = FL_COMPOSITOR_SOFTWARE(
      g_object_new(fl_compositor_software_get_type(), nullptr));
  return self;
}

gboolean fl_compositor_software_render(FlCompositorSoftware* self,
                                       cairo_t* cr,
                                       size_t width,
                                       size_t height,
                                       gint scale_factor) {
  g_return_val_if_fail(FL_IS_COMPOSITOR_SOFTWARE(self), FALSE);

  g_autoptr(GMutexLocker) locker = g_mutex_locker_new(&self->frame_mutex);

  if (self->surface == nullptr) {
    return FALSE;
  }

  // If frame not ready, then wait for it.
  while (self->width != width || self->height != height) {
    g_cond_wait(&self->frame_cond, &self->frame_mutex);
  }

  cairo_surface_set_device_scale(self->surface, scale_factor, scale_factor);
  cairo_set_source_surface(cr, self->surface, 0.0, 0.0);
  cairo_paint(cr);

  return TRUE;
}
