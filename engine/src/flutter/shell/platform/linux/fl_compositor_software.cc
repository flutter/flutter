// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_compositor_software.h"

struct _FlCompositorSoftware {
  FlCompositor parent_instance;

  // Surface to draw on view.
  cairo_surface_t* surface;

  // Control thread access to the frame.
  GMutex frame_mutex;
};

G_DEFINE_TYPE(FlCompositorSoftware,
              fl_compositor_software,
              fl_compositor_get_type())

static FlutterRendererType fl_compositor_software_get_renderer_type(
    FlCompositor* compositor) {
  return kSoftware;
}

static void fl_compositor_software_wait_for_frame(FlCompositor* compositor,
                                                  int target_width,
                                                  int target_height) {}

static gboolean fl_compositor_software_present_layers(
    FlCompositor* compositor,
    const FlutterLayer** layers,
    size_t layers_count) {
  FlCompositorSoftware* self = FL_COMPOSITOR_SOFTWARE(compositor);

  g_autoptr(GMutexLocker) locker = g_mutex_locker_new(&self->frame_mutex);

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

  return TRUE;
}

static void fl_compositor_software_dispose(GObject* object) {
  FlCompositorSoftware* self = FL_COMPOSITOR_SOFTWARE(object);

  if (self->surface != nullptr) {
    free(cairo_image_surface_get_data(self->surface));
  }
  g_clear_pointer(&self->surface, cairo_surface_destroy);

  G_OBJECT_CLASS(fl_compositor_software_parent_class)->dispose(object);
}

static void fl_compositor_software_class_init(
    FlCompositorSoftwareClass* klass) {
  FL_COMPOSITOR_CLASS(klass)->get_renderer_type =
      fl_compositor_software_get_renderer_type;
  FL_COMPOSITOR_CLASS(klass)->wait_for_frame =
      fl_compositor_software_wait_for_frame;
  FL_COMPOSITOR_CLASS(klass)->present_layers =
      fl_compositor_software_present_layers;

  G_OBJECT_CLASS(klass)->dispose = fl_compositor_software_dispose;
}

static void fl_compositor_software_init(FlCompositorSoftware* self) {}

FlCompositorSoftware* fl_compositor_software_new() {
  FlCompositorSoftware* self = FL_COMPOSITOR_SOFTWARE(
      g_object_new(fl_compositor_software_get_type(), nullptr));
  return self;
}

gboolean fl_compositor_software_render(FlCompositorSoftware* self,
                                       cairo_t* cr,
                                       gint scale_factor) {
  g_autoptr(GMutexLocker) locker = g_mutex_locker_new(&self->frame_mutex);

  if (self->surface == nullptr) {
    return FALSE;
  }

  cairo_surface_set_device_scale(self->surface, scale_factor, scale_factor);
  cairo_set_source_surface(cr, self->surface, 0.0, 0.0);
  cairo_paint(cr);

  return TRUE;
}
