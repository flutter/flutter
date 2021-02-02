// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/testing/mock_renderer.h"

struct _FlMockRenderer {
  FlRenderer parent_instance;
};

G_DEFINE_TYPE(FlMockRenderer, fl_mock_renderer, fl_renderer_get_type())

// Implements FlRenderer::create_contexts.
static gboolean fl_mock_renderer_create_contexts(FlRenderer* renderer,
                                                 GtkWidget* widget,
                                                 GdkGLContext** visible,
                                                 GdkGLContext** resource,
                                                 GError** error) {
  return TRUE;
}

// Implements FlRenderer::create_backing_store.
static gboolean fl_mock_renderer_create_backing_store(
    FlRenderer* renderer,
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
  return TRUE;
}

// Implements FlRenderer::collect_backing_store.
static gboolean fl_mock_renderer_collect_backing_store(
    FlRenderer* self,
    const FlutterBackingStore* backing_store) {
  return TRUE;
}

// Implements FlRenderer::present_layers.
static gboolean fl_mock_renderer_present_layers(FlRenderer* self,
                                                const FlutterLayer** layers,
                                                size_t layers_count) {
  return TRUE;
}

static void fl_mock_renderer_class_init(FlMockRendererClass* klass) {
  FL_RENDERER_CLASS(klass)->create_contexts = fl_mock_renderer_create_contexts;
  FL_RENDERER_CLASS(klass)->create_backing_store =
      fl_mock_renderer_create_backing_store;
  FL_RENDERER_CLASS(klass)->collect_backing_store =
      fl_mock_renderer_collect_backing_store;
  FL_RENDERER_CLASS(klass)->present_layers = fl_mock_renderer_present_layers;
}

static void fl_mock_renderer_init(FlMockRenderer* self) {}

// Creates a stub renderer
FlMockRenderer* fl_mock_renderer_new() {
  return FL_MOCK_RENDERER(g_object_new(fl_mock_renderer_get_type(), nullptr));
}
