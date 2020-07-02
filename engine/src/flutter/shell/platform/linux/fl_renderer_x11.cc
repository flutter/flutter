// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_renderer_x11.h"

struct _FlRendererX11 {
  FlRenderer parent_instance;

  GdkX11Window* window;
};

G_DEFINE_TYPE(FlRendererX11, fl_renderer_x11, fl_renderer_get_type())

static void fl_renderer_x11_dispose(GObject* object) {
  FlRendererX11* self = FL_RENDERER_X11(object);

  g_clear_object(&self->window);

  G_OBJECT_CLASS(fl_renderer_x11_parent_class)->dispose(object);
}

// Implments FlRenderer::get_visual.
static GdkVisual* fl_renderer_x11_get_visual(FlRenderer* renderer,
                                             GdkScreen* screen,
                                             EGLint visual_id) {
  return gdk_x11_screen_lookup_visual(GDK_X11_SCREEN(screen), visual_id);
}

// Implments FlRenderer::create_surface.
static EGLSurface fl_renderer_x11_create_surface(FlRenderer* renderer,
                                                 EGLDisplay display,
                                                 EGLConfig config) {
  FlRendererX11* self = FL_RENDERER_X11(renderer);
  return eglCreateWindowSurface(display, config,
                                gdk_x11_window_get_xid(self->window), nullptr);
}

static void fl_renderer_x11_class_init(FlRendererX11Class* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_renderer_x11_dispose;
  FL_RENDERER_CLASS(klass)->get_visual = fl_renderer_x11_get_visual;
  FL_RENDERER_CLASS(klass)->create_surface = fl_renderer_x11_create_surface;
}

static void fl_renderer_x11_init(FlRendererX11* self) {}

FlRendererX11* fl_renderer_x11_new() {
  return FL_RENDERER_X11(g_object_new(fl_renderer_x11_get_type(), nullptr));
}

void fl_renderer_x11_set_window(FlRendererX11* self, GdkX11Window* window) {
  g_return_if_fail(FL_IS_RENDERER_X11(self));
  self->window = GDK_X11_WINDOW(g_object_ref(window));
}
