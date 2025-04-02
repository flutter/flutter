// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_opengl_manager.h"

struct _FlOpenGLManager {
  GObject parent_instance;

  // OpenGL rendering context used by GDK.
  GdkGLContext* gdk_context;

  // Main OpenGL rendering context used by Flutter.
  GdkGLContext* main_context;

  // OpenGL rendering context used by a Flutter background thread for
  // asynchronous texture uploads.
  GdkGLContext* resource_context;
};

G_DEFINE_TYPE(FlOpenGLManager, fl_opengl_manager, G_TYPE_OBJECT)

static void fl_opengl_manager_dispose(GObject* object) {
  FlOpenGLManager* self = FL_OPENGL_MANAGER(object);

  g_clear_object(&self->gdk_context);
  g_clear_object(&self->main_context);
  g_clear_object(&self->resource_context);

  G_OBJECT_CLASS(fl_opengl_manager_parent_class)->dispose(object);
}

static void fl_opengl_manager_class_init(FlOpenGLManagerClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_opengl_manager_dispose;
}

static void fl_opengl_manager_init(FlOpenGLManager* self) {}

FlOpenGLManager* fl_opengl_manager_new() {
  FlOpenGLManager* self =
      FL_OPENGL_MANAGER(g_object_new(fl_opengl_manager_get_type(), nullptr));
  return self;
}

gboolean fl_opengl_manager_create_contexts(FlOpenGLManager* self,
                                           GdkWindow* window,
                                           GError** error) {
  g_return_val_if_fail(FL_IS_OPENGL_MANAGER(self), FALSE);

  self->gdk_context = gdk_window_create_gl_context(window, error);
  if (self->gdk_context == nullptr) {
    return FALSE;
  }
  if (!gdk_gl_context_realize(self->gdk_context, error)) {
    return FALSE;
  }

  self->main_context = gdk_window_create_gl_context(window, error);
  if (self->main_context == nullptr) {
    return FALSE;
  }
  if (!gdk_gl_context_realize(self->main_context, error)) {
    return FALSE;
  }

  self->resource_context = gdk_window_create_gl_context(window, error);
  if (self->resource_context == nullptr) {
    return FALSE;
  }
  if (!gdk_gl_context_realize(self->resource_context, error)) {
    return FALSE;
  }

  return TRUE;
}

GdkGLContext* fl_opengl_manager_get_context(FlOpenGLManager* self) {
  g_return_val_if_fail(FL_IS_OPENGL_MANAGER(self), nullptr);
  return self->gdk_context;
}

void fl_opengl_manager_make_current(FlOpenGLManager* self) {
  gdk_gl_context_make_current(self->main_context);
}

void fl_opengl_manager_make_resource_current(FlOpenGLManager* self) {
  gdk_gl_context_make_current(self->resource_context);
}

void fl_opengl_manager_clear_current(FlOpenGLManager* self) {
  gdk_gl_context_clear_current();
}
