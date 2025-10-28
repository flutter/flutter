// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_compositor.h"

G_DEFINE_QUARK(fl_compositor_error_quark, fl_compositor_error)

G_DEFINE_TYPE(FlCompositor, fl_compositor, G_TYPE_OBJECT)

static void fl_compositor_class_init(FlCompositorClass* klass) {}

static void fl_compositor_init(FlCompositor* self) {}

gboolean fl_compositor_present_layers(FlCompositor* self,
                                      const FlutterLayer** layers,
                                      size_t layers_count) {
  g_return_val_if_fail(FL_IS_COMPOSITOR(self), FALSE);
  return FL_COMPOSITOR_GET_CLASS(self)->present_layers(self, layers,
                                                       layers_count);
}

gboolean fl_compositor_render(FlCompositor* self,
                              cairo_t* cr,
                              GdkWindow* window) {
  g_return_val_if_fail(FL_IS_COMPOSITOR(self), FALSE);
  return FL_COMPOSITOR_GET_CLASS(self)->render(self, cr, window);
}
