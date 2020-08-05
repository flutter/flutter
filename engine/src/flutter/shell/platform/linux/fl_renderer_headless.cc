// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_renderer_headless.h"

struct _FlRendererHeadless {
  FlRenderer parent_instance;
};

G_DEFINE_TYPE(FlRendererHeadless, fl_renderer_headless, fl_renderer_get_type())

static gboolean fl_renderer_headless_create_surfaces(FlRenderer* renderer,
                                                     EGLDisplay display,
                                                     EGLConfig config,
                                                     EGLSurface* visible,
                                                     EGLSurface* resource,
                                                     GError** error) {
  return FALSE;
}

static void fl_renderer_headless_class_init(FlRendererHeadlessClass* klass) {
  FL_RENDERER_CLASS(klass)->create_surfaces =
      fl_renderer_headless_create_surfaces;
}

static void fl_renderer_headless_init(FlRendererHeadless* self) {}

FlRendererHeadless* fl_renderer_headless_new() {
  return FL_RENDERER_HEADLESS(
      g_object_new(fl_renderer_headless_get_type(), nullptr));
}
