// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_subsurface.h"

#include <wayland-client.h>

struct _FlSubsurface {
  GObject parent_instance;

  // Surface backing the subsurface and the subsurface itself.
  struct wl_surface* surface;
  struct wl_subsurface* subsurface;
};

G_DEFINE_TYPE(FlSubsurface, fl_subsurface, G_TYPE_OBJECT)

static void fl_subsurface_dispose(GObject* object) {
  FlSubsurface* self = FL_SUBSURFACE(object);

  g_clear_pointer(&self->subsurface, wl_subsurface_destroy);
  g_clear_pointer(&self->surface, wl_surface_destroy);

  G_OBJECT_CLASS(fl_subsurface_parent_class)->dispose(object);
}

static void fl_subsurface_class_init(FlSubsurfaceClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_subsurface_dispose;
}

static void fl_subsurface_init(FlSubsurface* self) {}

FlSubsurface* fl_subsurface_new(struct wl_compositor* compositor,
                                struct wl_subcompositor* subcompositor,
                                struct wl_surface* parent_surface) {
  FlSubsurface* self =
      FL_SUBSURFACE(g_object_new(fl_subsurface_get_type(), nullptr));

  self->surface = wl_compositor_create_surface(compositor);
  self->subsurface = wl_subcompositor_get_subsurface(
      subcompositor, self->surface, parent_surface);
  wl_subsurface_set_sync(self->subsurface);

  // Give the subsurface an empty input region so pointer, touch and keyboard
  // events pass through to the parent (GTK) surface, which handles all input
  // for the view.
  struct wl_region* input_region = wl_compositor_create_region(compositor);
  wl_surface_set_input_region(self->surface, input_region);
  wl_region_destroy(input_region);

  return self;
}

struct wl_surface* fl_subsurface_get_surface(FlSubsurface* self) {
  g_return_val_if_fail(FL_IS_SUBSURFACE(self), nullptr);
  return self->surface;
}

void fl_subsurface_set_position(FlSubsurface* self, gint x, gint y) {
  g_return_if_fail(FL_IS_SUBSURFACE(self));
  wl_subsurface_set_position(self->subsurface, x, y);
}
