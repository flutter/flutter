// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_compositor_software.h"

#include "flutter/shell/platform/linux/fl_engine_private.h"

struct _FlCompositorSoftware {
  FlCompositor parent_instance;

  // Engine we are rendering.
  GWeakRef engine;

  // Surfaces to draw on each view.
  GHashTable* surfaces_by_view_id;

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

static void fl_compositor_software_setup(FlCompositor* compositor) {
  // No special work required.
}

static gboolean fl_compositor_software_create_backing_store(
    FlCompositor* compositor,
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
  size_t allocation_length = config->size.width * config->size.height * 4;
  uint8_t* allocation = static_cast<uint8_t*>(malloc(allocation_length));
  if (allocation == nullptr) {
    return FALSE;
  }

  backing_store_out->type = kFlutterBackingStoreTypeSoftware;
  backing_store_out->software.allocation = allocation;
  backing_store_out->software.height = config->size.height;
  backing_store_out->software.row_bytes = config->size.width * 4;
  backing_store_out->software.user_data = nullptr;
  backing_store_out->software.destruction_callback = [](void* p) {
    // Backing store destroyed in
    // fl_compositor_software_collect_backing_store(), set on
    // FlutterCompositor.collect_backing_store_callback during engine start.
  };

  return TRUE;
}

static gboolean fl_compositor_software_collect_backing_store(
    FlCompositor* compositor,
    const FlutterBackingStore* backing_store) {
  free(const_cast<void*>(backing_store->software.allocation));

  return TRUE;
}

static void fl_compositor_software_wait_for_frame(FlCompositor* compositor,
                                                  int target_width,
                                                  int target_height) {}

static gboolean fl_compositor_software_present_layers(
    FlCompositor* compositor,
    FlutterViewId view_id,
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

    cairo_surface_t* surface =
        reinterpret_cast<cairo_surface_t*>((g_hash_table_lookup(
            self->surfaces_by_view_id, GINT_TO_POINTER(view_id))));

    size_t allocation_length =
        backing_store->software.row_bytes * backing_store->software.height;
    unsigned char* old_data =
        surface != nullptr ? cairo_image_surface_get_data(surface) : nullptr;
    unsigned char* data =
        static_cast<unsigned char*>(realloc(old_data, allocation_length));
    memcpy(data, backing_store->software.allocation, allocation_length);
    cairo_surface_t* new_surface = cairo_image_surface_create_for_data(
        data, CAIRO_FORMAT_ARGB32, backing_store->software.row_bytes / 4,
        backing_store->software.height, backing_store->software.row_bytes);
    g_hash_table_insert(self->surfaces_by_view_id, GINT_TO_POINTER(view_id),
                        new_surface);
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

  fl_renderable_redraw(renderable);

  return TRUE;
}

static void fl_compositor_software_dispose(GObject* object) {
  FlCompositorSoftware* self = FL_COMPOSITOR_SOFTWARE(object);

  g_weak_ref_clear(&self->engine);
  if (self->surfaces_by_view_id != nullptr) {
    GHashTableIter iter;
    g_hash_table_iter_init(&iter, self->surfaces_by_view_id);
    gpointer value;
    while (g_hash_table_iter_next(&iter, nullptr, &value)) {
      cairo_surface_t* surface = reinterpret_cast<cairo_surface_t*>(value);
      free(cairo_image_surface_get_data(surface));
    }
  }
  g_clear_pointer(&self->surfaces_by_view_id, g_hash_table_unref);

  G_OBJECT_CLASS(fl_compositor_software_parent_class)->dispose(object);
}

static void fl_compositor_software_class_init(
    FlCompositorSoftwareClass* klass) {
  FL_COMPOSITOR_CLASS(klass)->get_renderer_type =
      fl_compositor_software_get_renderer_type;
  FL_COMPOSITOR_CLASS(klass)->setup = fl_compositor_software_setup;
  FL_COMPOSITOR_CLASS(klass)->create_backing_store =
      fl_compositor_software_create_backing_store;
  FL_COMPOSITOR_CLASS(klass)->collect_backing_store =
      fl_compositor_software_collect_backing_store;
  FL_COMPOSITOR_CLASS(klass)->wait_for_frame =
      fl_compositor_software_wait_for_frame;
  FL_COMPOSITOR_CLASS(klass)->present_layers =
      fl_compositor_software_present_layers;

  G_OBJECT_CLASS(klass)->dispose = fl_compositor_software_dispose;
}

static void fl_compositor_software_init(FlCompositorSoftware* self) {
  self->surfaces_by_view_id = g_hash_table_new_full(
      g_direct_hash, g_direct_equal, nullptr,
      reinterpret_cast<GDestroyNotify>(cairo_surface_destroy));
}

FlCompositorSoftware* fl_compositor_software_new(FlEngine* engine) {
  FlCompositorSoftware* self = FL_COMPOSITOR_SOFTWARE(
      g_object_new(fl_compositor_software_get_type(), nullptr));

  g_weak_ref_init(&self->engine, engine);

  return self;
}

gboolean fl_compositor_software_render(FlCompositorSoftware* self,
                                       FlutterViewId view_id,
                                       cairo_t* cr,
                                       gint scale_factor) {
  g_autoptr(GMutexLocker) locker = g_mutex_locker_new(&self->frame_mutex);

  cairo_surface_t* surface =
      reinterpret_cast<cairo_surface_t*>((g_hash_table_lookup(
          self->surfaces_by_view_id, GINT_TO_POINTER(view_id))));
  if (surface == nullptr) {
    return FALSE;
  }

  cairo_surface_set_device_scale(surface, scale_factor, scale_factor);
  cairo_set_source_surface(cr, surface, 0.0, 0.0);
  cairo_paint(cr);

  return TRUE;
}
