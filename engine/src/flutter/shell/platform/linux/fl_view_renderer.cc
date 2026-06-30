// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_view_renderer.h"

enum { SIGNAL_FIRST_FRAME, LAST_SIGNAL };

static guint fl_view_renderer_signals[LAST_SIGNAL];

G_DEFINE_TYPE(FlViewRenderer, fl_view_renderer, GTK_TYPE_DRAWING_AREA)

static void fl_view_renderer_class_init(FlViewRendererClass* klass) {
  fl_view_renderer_signals[SIGNAL_FIRST_FRAME] =
      g_signal_new("first-frame", fl_view_renderer_get_type(),
                   G_SIGNAL_RUN_LAST, 0, NULL, NULL, NULL, G_TYPE_NONE, 0);
}

static void fl_view_renderer_init(FlViewRenderer* self) {}

void fl_view_renderer_set_background_color(FlViewRenderer* self,
                                           const GdkRGBA* color) {
  g_return_if_fail(FL_IS_VIEW_RENDERER(self));

  FlViewRendererClass* klass = FL_VIEW_RENDERER_GET_CLASS(self);
  if (klass->set_background_color != nullptr) {
    klass->set_background_color(self, color);
  }
}

void fl_view_renderer_present_layers(FlViewRenderer* self,
                                     const FlutterLayer** layers,
                                     size_t layers_count) {
  g_return_if_fail(FL_IS_VIEW_RENDERER(self));

  FlViewRendererClass* klass = FL_VIEW_RENDERER_GET_CLASS(self);
  if (klass->present_layers != nullptr) {
    klass->present_layers(self, layers, layers_count);
  }
}

void fl_view_renderer_emit_first_frame(FlViewRenderer* self) {
  g_return_if_fail(FL_IS_VIEW_RENDERER(self));

  g_signal_emit(self, fl_view_renderer_signals[SIGNAL_FIRST_FRAME], 0);
}
