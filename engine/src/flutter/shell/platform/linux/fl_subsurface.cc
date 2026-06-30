// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_subsurface.h"

#include <gdk/gdkwayland.h>
#include <wayland-client.h>

struct _FlSubsurface {
  GObject parent_instance;

  // Wayland globals used to create the subsurface.
  struct wl_compositor* compositor;
  struct wl_subcompositor* subcompositor;

  // Surface backing the subsurface and the subsurface itself.
  struct wl_surface* surface;
  struct wl_subsurface* subsurface;
};

G_DEFINE_TYPE(FlSubsurface, fl_subsurface, G_TYPE_OBJECT)

// Wayland registry handling.
static void registry_global(void* data,
                            struct wl_registry* registry,
                            uint32_t name,
                            const char* interface,
                            uint32_t version) {
  FlSubsurface* self = FL_SUBSURFACE(data);
  if (g_strcmp0(interface, wl_compositor_interface.name) == 0) {
    self->compositor = static_cast<struct wl_compositor*>(wl_registry_bind(
        registry, name, &wl_compositor_interface, MIN(version, 4)));
  } else if (g_strcmp0(interface, wl_subcompositor_interface.name) == 0) {
    self->subcompositor = static_cast<struct wl_subcompositor*>(
        wl_registry_bind(registry, name, &wl_subcompositor_interface, 1));
  }
}

static void registry_global_remove(void* data,
                                   struct wl_registry* registry,
                                   uint32_t name) {}

static const struct wl_registry_listener kRegistryListener = {
    .global = registry_global,
    .global_remove = registry_global_remove,
};

static void fl_subsurface_dispose(GObject* object) {
  FlSubsurface* self = FL_SUBSURFACE(object);

  g_clear_pointer(&self->subsurface, wl_subsurface_destroy);
  g_clear_pointer(&self->surface, wl_surface_destroy);
  g_clear_pointer(&self->subcompositor, wl_subcompositor_destroy);
  g_clear_pointer(&self->compositor, wl_compositor_destroy);

  G_OBJECT_CLASS(fl_subsurface_parent_class)->dispose(object);
}

static void fl_subsurface_class_init(FlSubsurfaceClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_subsurface_dispose;
}

static void fl_subsurface_init(FlSubsurface* self) {}

FlSubsurface* fl_subsurface_new(GtkWidget* widget) {
  GdkDisplay* gdk_display = gtk_widget_get_display(widget);
  if (!GDK_IS_WAYLAND_DISPLAY(gdk_display)) {
    g_warning("FlSubsurface requires a Wayland display");
    return nullptr;
  }

  FlSubsurface* self =
      FL_SUBSURFACE(g_object_new(fl_subsurface_get_type(), nullptr));

  struct wl_display* display = gdk_wayland_display_get_wl_display(gdk_display);

  // Bind the Wayland globals needed to create the subsurface.
  struct wl_registry* registry = wl_display_get_registry(display);
  wl_registry_add_listener(registry, &kRegistryListener, self);
  wl_display_roundtrip(display);
  wl_registry_destroy(registry);
  if (self->compositor == nullptr || self->subcompositor == nullptr) {
    g_warning("Required Wayland globals not available for subsurface");
    g_object_unref(self);
    return nullptr;
  }

  // Create a subsurface on the toplevel's surface.
  GtkWidget* toplevel = gtk_widget_get_toplevel(widget);
  GdkWindow* gdk_window = gtk_widget_get_window(toplevel);
  struct wl_surface* parent_surface =
      gdk_wayland_window_get_wl_surface(gdk_window);
  self->surface = wl_compositor_create_surface(self->compositor);
  self->subsurface = wl_subcompositor_get_subsurface(
      self->subcompositor, self->surface, parent_surface);
  wl_subsurface_set_sync(self->subsurface);

  gint x, y;
  gtk_widget_translate_coordinates(widget, toplevel, 0, 0, &x, &y);
  wl_subsurface_set_position(self->subsurface, x, y);

  return self;
}

struct wl_surface* fl_subsurface_get_surface(FlSubsurface* self) {
  g_return_val_if_fail(FL_IS_SUBSURFACE(self), nullptr);
  return self->surface;
}

void fl_subsurface_set_position(FlSubsurface* self, gint x, gint y) {
  g_return_if_fail(FL_IS_SUBSURFACE(self));
  if (self->subsurface != nullptr) {
    wl_subsurface_set_position(self->subsurface, x, y);
  }
}
