// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_renderable.h"

G_DEFINE_INTERFACE(FlRenderable, fl_renderable, G_TYPE_OBJECT)

static void fl_renderable_default_init(FlRenderableInterface* iface) {}

void fl_renderable_present_layers(FlRenderable* self,
                                  const FlutterLayer** layers,
                                  size_t layers_count) {
  g_return_if_fail(FL_IS_RENDERABLE(self));

  FL_RENDERABLE_GET_IFACE(self)->present_layers(self, layers, layers_count);
}

void fl_renderable_notify_first_frame(FlRenderable* self) {
  g_return_if_fail(FL_IS_RENDERABLE(self));

  FlRenderableInterface* iface = FL_RENDERABLE_GET_IFACE(self);
  if (iface->notify_first_frame == nullptr) {
    return;
  }

  iface->notify_first_frame(self);
}
