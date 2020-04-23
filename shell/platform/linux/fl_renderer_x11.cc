// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_renderer_x11.h"

struct _FlRendererX11 {
  FlRenderer parent_instance;

  Window xid;
};

G_DEFINE_TYPE(FlRendererX11, fl_renderer_x11, fl_renderer_get_type())

static EGLSurface fl_renderer_x11_create_surface(FlRenderer* renderer,
                                                 EGLDisplay display,
                                                 EGLConfig config) {
  FlRendererX11* self = FL_RENDERER_X11(renderer);
  return eglCreateWindowSurface(display, config, self->xid, nullptr);
}

static void fl_renderer_x11_class_init(FlRendererX11Class* klass) {
  FL_RENDERER_CLASS(klass)->create_surface = fl_renderer_x11_create_surface;
}

static void fl_renderer_x11_init(FlRendererX11* self) {}

FlRendererX11* fl_renderer_x11_new(Window xid) {
  FlRendererX11* self = static_cast<FlRendererX11*>(
      g_object_new(fl_renderer_x11_get_type(), nullptr));
  self->xid = xid;
  return self;
}
