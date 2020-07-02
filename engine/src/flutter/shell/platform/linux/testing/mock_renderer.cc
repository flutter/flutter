// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/testing/mock_renderer.h"

struct _FlMockRenderer {
  FlRenderer parent_instance;
};

G_DEFINE_TYPE(FlMockRenderer, fl_mock_renderer, fl_renderer_get_type())

// Implements FlRenderer::get_visual.
static GdkVisual* fl_mock_renderer_get_visual(FlRenderer* renderer,
                                              GdkScreen* screen,
                                              EGLint visual_id) {
  return static_cast<GdkVisual*>(g_object_new(GDK_TYPE_VISUAL, nullptr));
}

// Implements FlRenderer::create_surface.
static EGLSurface fl_mock_renderer_create_surface(FlRenderer* renderer,
                                                  EGLDisplay display,
                                                  EGLConfig config) {
  return eglCreateWindowSurface(display, config, 0, nullptr);
}

static void fl_mock_renderer_class_init(FlMockRendererClass* klass) {
  FL_RENDERER_CLASS(klass)->get_visual = fl_mock_renderer_get_visual;
  FL_RENDERER_CLASS(klass)->create_surface = fl_mock_renderer_create_surface;
}

static void fl_mock_renderer_init(FlMockRenderer* self) {}

// Creates a stub renderer
FlMockRenderer* fl_mock_renderer_new() {
  return FL_MOCK_RENDERER(g_object_new(fl_mock_renderer_get_type(), nullptr));
}
