// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/testing/mock_renderable.h"

struct _FlMockRenderable {
  GObject parent_instance;
};

static void mock_renderable_iface_init(FlRenderableInterface* iface);

G_DEFINE_TYPE_WITH_CODE(FlMockRenderable,
                        fl_mock_renderable,
                        g_object_get_type(),
                        G_IMPLEMENT_INTERFACE(fl_renderable_get_type(),
                                              mock_renderable_iface_init))

static void mock_renderable_present_layers(FlRenderable* renderable,
                                           const FlutterLayer** layers,
                                           size_t layers_count) {}

static void mock_renderable_iface_init(FlRenderableInterface* iface) {
  iface->present_layers = mock_renderable_present_layers;
}

static void fl_mock_renderable_class_init(FlMockRenderableClass* klass) {}

static void fl_mock_renderable_init(FlMockRenderable* self) {}

// Creates a sub renderable.
FlMockRenderable* fl_mock_renderable_new() {
  return FL_MOCK_RENDERABLE(
      g_object_new(fl_mock_renderable_get_type(), nullptr));
}
