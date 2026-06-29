// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_view_renderer_subsurface.h"

#include "flutter/shell/platform/linux/fl_engine_private.h"

struct _FlViewRendererSubsurface {
  FlViewRenderer parent_instance;

  // Engine this widget is rendering.
  FlEngine* engine;

  // TRUE if the view size should be controlled by Flutter.
  gboolean sized_to_content;
};

G_DEFINE_TYPE(FlViewRendererSubsurface,
              fl_view_renderer_subsurface,
              fl_view_renderer_get_type())

static void fl_view_renderer_subsurface_dispose(GObject* object) {
  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(object);

  g_clear_object(&self->engine);

  G_OBJECT_CLASS(fl_view_renderer_subsurface_parent_class)->dispose(object);
}

static void fl_view_renderer_subsurface_class_init(
    FlViewRendererSubsurfaceClass* klass) {
  GObjectClass* object_class = G_OBJECT_CLASS(klass);
  object_class->dispose = fl_view_renderer_subsurface_dispose;
}

static void fl_view_renderer_subsurface_init(FlViewRendererSubsurface* self) {}

FlViewRendererSubsurface* fl_view_renderer_subsurface_new(
    FlEngine* engine,
    gboolean sized_to_content) {
  g_return_val_if_fail(FL_IS_ENGINE(engine), nullptr);

  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(
      g_object_new(fl_view_renderer_subsurface_get_type(), nullptr));
  self->engine = FL_ENGINE(g_object_ref(engine));
  self->sized_to_content = sized_to_content;
  return self;
}
