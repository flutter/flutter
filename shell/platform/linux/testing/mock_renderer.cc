// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/testing/mock_renderer.h"

struct _FlMockRenderer {
  FlRenderer parent_instance;
};

G_DEFINE_TYPE(FlMockRenderer, fl_mock_renderer, fl_renderer_get_type())

// Implements FlRenderer::make_current.
static void fl_mock_renderer_make_current(FlRenderer* renderer) {}

// Implements FlRenderer::make_resource_current.
static void fl_mock_renderer_make_resource_current(FlRenderer* renderer) {}

// Implements FlRenderer::clear_current.
static void fl_mock_renderer_clear_current(FlRenderer* renderer) {}

static void fl_mock_renderer_class_init(FlMockRendererClass* klass) {
  FL_RENDERER_CLASS(klass)->make_current = fl_mock_renderer_make_current;
  FL_RENDERER_CLASS(klass)->make_resource_current =
      fl_mock_renderer_make_resource_current;
  FL_RENDERER_CLASS(klass)->clear_current = fl_mock_renderer_clear_current;
}

static void fl_mock_renderer_init(FlMockRenderer* self) {}

// Creates a stub renderer
FlMockRenderer* fl_mock_renderer_new() {
  return FL_MOCK_RENDERER(g_object_new(fl_mock_renderer_get_type(), nullptr));
}
