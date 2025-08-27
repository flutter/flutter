// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_compositor.h"

G_DEFINE_QUARK(fl_compositor_error_quark, fl_compositor_error)

G_DEFINE_TYPE(FlCompositor, fl_compositor, G_TYPE_OBJECT)

static void fl_compositor_class_init(FlCompositorClass* klass) {}

static void fl_compositor_init(FlCompositor* self) {}

FlutterRendererType fl_compositor_get_renderer_type(FlCompositor* self) {
  g_return_val_if_fail(FL_IS_COMPOSITOR(self),
                       static_cast<FlutterRendererType>(0));
  return FL_COMPOSITOR_GET_CLASS(self)->get_renderer_type(self);
}

void fl_compositor_wait_for_frame(FlCompositor* self,
                                  int target_width,
                                  int target_height) {
  g_return_if_fail(FL_IS_COMPOSITOR(self));
  FL_COMPOSITOR_GET_CLASS(self)->wait_for_frame(self, target_width,
                                                target_height);
}

gboolean fl_compositor_present_layers(FlCompositor* self,
                                      const FlutterLayer** layers,
                                      size_t layers_count) {
  g_return_val_if_fail(FL_IS_COMPOSITOR(self), FALSE);
  return FL_COMPOSITOR_GET_CLASS(self)->present_layers(self, layers,
                                                       layers_count);
}
