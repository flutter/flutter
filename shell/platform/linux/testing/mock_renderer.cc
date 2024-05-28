// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/testing/mock_renderer.h"

struct _FlMockRenderer {
  FlRenderer parent_instance;
  FlMockRendererGetRefreshRate get_refresh_rate;
};

G_DEFINE_TYPE(FlMockRenderer, fl_mock_renderer, fl_renderer_get_type())

// Implements FlRenderer::make_current.
static void fl_mock_renderer_make_current(FlRenderer* renderer) {}

// Implements FlRenderer::make_resource_current.
static void fl_mock_renderer_make_resource_current(FlRenderer* renderer) {}

// Implements FlRenderer::clear_current.
static void fl_mock_renderer_clear_current(FlRenderer* renderer) {}

// Implements FlRenderer::get_refresh_rate.
static gdouble fl_mock_renderer_default_get_refresh_rate(FlRenderer* renderer) {
  FlMockRenderer* self = FL_MOCK_RENDERER(renderer);
  if (self->get_refresh_rate != nullptr) {
    return self->get_refresh_rate(renderer);
  }
  return -1.0;
}

static void fl_mock_renderer_class_init(FlMockRendererClass* klass) {
  FL_RENDERER_CLASS(klass)->make_current = fl_mock_renderer_make_current;
  FL_RENDERER_CLASS(klass)->make_resource_current =
      fl_mock_renderer_make_resource_current;
  FL_RENDERER_CLASS(klass)->clear_current = fl_mock_renderer_clear_current;
  FL_RENDERER_CLASS(klass)->get_refresh_rate =
      fl_mock_renderer_default_get_refresh_rate;
}

static void fl_mock_renderer_init(FlMockRenderer* self) {}

// Creates a stub renderer
FlMockRenderer* fl_mock_renderer_new(
    FlMockRendererGetRefreshRate get_refresh_rate) {
  FlMockRenderer* fl_mock_renderer = FL_MOCK_RENDERER(
      g_object_new_valist(fl_mock_renderer_get_type(), nullptr, nullptr));
  fl_mock_renderer->get_refresh_rate = get_refresh_rate;
  return fl_mock_renderer;
}
