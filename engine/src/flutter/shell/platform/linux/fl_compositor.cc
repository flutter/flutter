// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_compositor.h"

G_DEFINE_QUARK(fl_compositor_error_quark, fl_compositor_error)

G_DEFINE_TYPE(FlCompositor, fl_compositor, G_TYPE_OBJECT)

static void fl_compositor_class_init(FlCompositorClass* klass) {}

static void fl_compositor_init(FlCompositor* self) {}

gboolean fl_compositor_create_backing_store(
    FlCompositor* self,
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
  g_return_val_if_fail(FL_IS_COMPOSITOR(self), FALSE);
  return FL_COMPOSITOR_GET_CLASS(self)->create_backing_store(self, config,
                                                             backing_store_out);
}

gboolean fl_compositor_collect_backing_store(
    FlCompositor* self,
    const FlutterBackingStore* backing_store) {
  g_return_val_if_fail(FL_IS_COMPOSITOR(self), FALSE);
  return FL_COMPOSITOR_GET_CLASS(self)->collect_backing_store(self,
                                                              backing_store);
}

void fl_compositor_wait_for_frame(FlCompositor* self,
                                  int target_width,
                                  int target_height) {
  g_return_if_fail(FL_IS_COMPOSITOR(self));
  FL_COMPOSITOR_GET_CLASS(self)->wait_for_frame(self, target_width,
                                                target_height);
}

gboolean fl_compositor_present_layers(FlCompositor* self,
                                      FlutterViewId view_id,
                                      const FlutterLayer** layers,
                                      size_t layers_count) {
  g_return_val_if_fail(FL_IS_COMPOSITOR(self), FALSE);
  return FL_COMPOSITOR_GET_CLASS(self)->present_layers(self, view_id, layers,
                                                       layers_count);
}
