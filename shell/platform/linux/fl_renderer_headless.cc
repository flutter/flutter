// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_renderer_headless.h"

struct _FlRendererHeadless {
  FlRenderer parent_instance;
};

G_DEFINE_TYPE(FlRendererHeadless, fl_renderer_headless, fl_renderer_get_type())

// Implements FlRenderer::create_contexts.
static gboolean fl_renderer_headless_create_contexts(FlRenderer* renderer,
                                                     GtkWidget* widget,
                                                     GdkGLContext** visible,
                                                     GdkGLContext** resource,
                                                     GError** error) {
  return FALSE;
}

// Implements FlRenderer::create_backing_store.
static gboolean fl_renderer_headless_create_backing_store(
    FlRenderer* renderer,
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
  return FALSE;
}

// Implements FlRenderer::collect_backing_store.
static gboolean fl_renderer_headless_collect_backing_store(
    FlRenderer* self,
    const FlutterBackingStore* backing_store) {
  return FALSE;
}

// Implements FlRenderer::present_layers.
static gboolean fl_renderer_headless_present_layers(FlRenderer* self,
                                                    const FlutterLayer** layers,
                                                    size_t layers_count) {
  return FALSE;
}

static void fl_renderer_headless_class_init(FlRendererHeadlessClass* klass) {
  FL_RENDERER_CLASS(klass)->create_contexts =
      fl_renderer_headless_create_contexts;
  FL_RENDERER_CLASS(klass)->create_backing_store =
      fl_renderer_headless_create_backing_store;
  FL_RENDERER_CLASS(klass)->collect_backing_store =
      fl_renderer_headless_collect_backing_store;
  FL_RENDERER_CLASS(klass)->present_layers =
      fl_renderer_headless_present_layers;
}

static void fl_renderer_headless_init(FlRendererHeadless* self) {}

FlRendererHeadless* fl_renderer_headless_new() {
  return FL_RENDERER_HEADLESS(
      g_object_new(fl_renderer_headless_get_type(), nullptr));
}
