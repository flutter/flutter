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
  cairo_save(cr);
  cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR);
  cairo_paint(cr);
  cairo_restore(cr);

  for (size_t i = 0; i < layers_count; i++) {
    const FlutterLayer* layer = layers[i];
    switch (layer->type) {
      case kFlutterLayerContentTypeBackingStore: {
        const FlutterBackingStore* backing_store = layer->backing_store;
        g_assert(backing_store->type == kFlutterBackingStoreTypeSoftware);

        cairo_surface_t* surface = cairo_image_surface_create_for_data(
            static_cast<unsigned char*>(
                const_cast<void*>(backing_store->software.allocation)),
            CAIRO_FORMAT_ARGB32, backing_store->software.row_bytes / 4,
            backing_store->software.height, backing_store->software.row_bytes);

        // Layers are placed at their offset in the frame, and only cover the
        // area they were rendered for.
        cairo_save(cr);
        cairo_rectangle(cr, layer->offset.x, layer->offset.y, layer->size.width,
                        layer->size.height);
        cairo_clip(cr);
        cairo_set_source_surface(cr, surface, layer->offset.x, layer->offset.y);
        cairo_paint(cr);
        cairo_restore(cr);

        cairo_surface_destroy(surface);
      } break;
      case kFlutterLayerContentTypePlatformView: {
        // TODO(robert-ancell) Not implemented -
        // https://github.com/flutter/flutter/issues/41724
      } break;
    }
  }

  return TRUE;
}
