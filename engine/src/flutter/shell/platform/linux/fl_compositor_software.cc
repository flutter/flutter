// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_compositor_software.h"

struct _FlCompositorSoftware {
  GObject parent_instance;
};

G_DEFINE_TYPE(FlCompositorSoftware, fl_compositor_software, G_TYPE_OBJECT)

static void fl_compositor_software_class_init(
    FlCompositorSoftwareClass* klass) {}

static void fl_compositor_software_init(FlCompositorSoftware* self) {}

FlCompositorSoftware* fl_compositor_software_new() {
  return FL_COMPOSITOR_SOFTWARE(
      g_object_new(fl_compositor_software_get_type(), nullptr));
}

gboolean fl_compositor_software_composite_layers(FlCompositorSoftware* self,
                                                 cairo_t* cr,
                                                 const FlutterLayer** layers,
                                                 size_t layers_count) {
  if (layers_count == 0) {
    return TRUE;
  }

  // TODO(robert-ancell): Support multiple layers
  if (layers_count == 1) {
    const FlutterLayer* layer = layers[0];
    g_assert(layer->type == kFlutterLayerContentTypeBackingStore);
    g_assert(layer->backing_store->type == kFlutterBackingStoreTypeSoftware);
    const FlutterBackingStore* backing_store = layer->backing_store;

    cairo_surface_t* surface = cairo_image_surface_create_for_data(
        static_cast<unsigned char*>(
            const_cast<void*>(backing_store->software.allocation)),
        CAIRO_FORMAT_ARGB32, backing_store->software.row_bytes / 4,
        backing_store->software.height, backing_store->software.row_bytes);
    cairo_set_source_surface(cr, surface, 0.0, 0.0);
    cairo_paint(cr);
    cairo_surface_destroy(surface);
  }

  return TRUE;
}
