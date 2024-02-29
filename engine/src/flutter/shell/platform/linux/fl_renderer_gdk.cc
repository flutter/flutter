// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_renderer_gdk.h"

struct _FlRendererGdk {
  FlRenderer parent_instance;

  // Window being rendered on.
  GdkWindow* window;

  // Main OpenGL rendering context.
  GdkGLContext* main_context;

  // Secondary OpenGL rendering context.
  GdkGLContext* resource_context;
};

G_DEFINE_TYPE(FlRendererGdk, fl_renderer_gdk, fl_renderer_get_type())

// Implements FlRenderer::make_current.
static void fl_renderer_gdk_make_current(FlRenderer* renderer) {
  FlRendererGdk* self = FL_RENDERER_GDK(renderer);
  gdk_gl_context_make_current(self->main_context);
}

// Implements FlRenderer::make_resource_current.
static void fl_renderer_gdk_make_resource_current(FlRenderer* renderer) {
  FlRendererGdk* self = FL_RENDERER_GDK(renderer);
  gdk_gl_context_make_current(self->resource_context);
}

// Implements FlRenderer::clear_current.
static void fl_renderer_gdk_clear_current(FlRenderer* renderer) {
  gdk_gl_context_clear_current();
}

static void fl_renderer_gdk_dispose(GObject* object) {
  FlRendererGdk* self = FL_RENDERER_GDK(object);

  g_clear_object(&self->main_context);
  g_clear_object(&self->resource_context);

  G_OBJECT_CLASS(fl_renderer_gdk_parent_class)->dispose(object);
}

static void fl_renderer_gdk_class_init(FlRendererGdkClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_renderer_gdk_dispose;

  FL_RENDERER_CLASS(klass)->make_current = fl_renderer_gdk_make_current;
  FL_RENDERER_CLASS(klass)->make_resource_current =
      fl_renderer_gdk_make_resource_current;
  FL_RENDERER_CLASS(klass)->clear_current = fl_renderer_gdk_clear_current;
}

static void fl_renderer_gdk_init(FlRendererGdk* self) {}

FlRendererGdk* fl_renderer_gdk_new(GdkWindow* window) {
  FlRendererGdk* self =
      FL_RENDERER_GDK(g_object_new(fl_renderer_gdk_get_type(), nullptr));
  self->window = window;
  return self;
}

gboolean fl_renderer_gdk_create_contexts(FlRendererGdk* self, GError** error) {
  self->main_context = gdk_window_create_gl_context(self->window, error);
  if (self->main_context == nullptr) {
    return FALSE;
  }
  if (!gdk_gl_context_realize(self->main_context, error)) {
    return FALSE;
  }

  self->resource_context = gdk_window_create_gl_context(self->window, error);
  if (self->resource_context == nullptr) {
    return FALSE;
  }
  if (!gdk_gl_context_realize(self->resource_context, error)) {
    return FALSE;
  }

  return TRUE;
}

GdkGLContext* fl_renderer_gdk_get_context(FlRendererGdk* self) {
  g_return_val_if_fail(FL_IS_RENDERER_GDK(self), nullptr);
  return self->main_context;
}
