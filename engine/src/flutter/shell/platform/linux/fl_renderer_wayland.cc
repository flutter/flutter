// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define WL_EGL_PLATFORM

#include "fl_renderer_wayland.h"
#include "flutter/shell/platform/linux/egl_utils.h"

#include <gdk/gdkwayland.h>
#include <wayland-egl-core.h>
#include <cstring>

struct _FlRendererWayland {
  FlRenderer parent_instance;
  wl_registry* registry;
  wl_subcompositor* subcompositor;

  struct {
    wl_subsurface* subsurface;
    wl_surface* surface;
    wl_egl_window* egl_window;
    GdkRectangle geometry;
    gint scale;
  } subsurface;

  // The resource surface will not be mapped, but needs to be a wl_surface
  // because ONLY window EGL surfaces are supported on Wayland.
  struct {
    wl_surface* surface;
    wl_egl_window* egl_window;
  } resource;
};

G_DEFINE_TYPE(FlRendererWayland, fl_renderer_wayland, fl_renderer_get_type())

// wl_registry.global callback.
static void registry_handle_global(void* data,
                                   wl_registry* registry,
                                   uint32_t id,
                                   const char* name,
                                   uint32_t max_version) {
  FlRendererWayland* self = FL_RENDERER_WAYLAND(data);
  if (strcmp(name, wl_subcompositor_interface.name) == 0) {
    uint32_t version = MIN(
        static_cast<uint32_t>(wl_subcompositor_interface.version), max_version);
    self->subcompositor = static_cast<wl_subcompositor*>(
        wl_registry_bind(registry, id, &wl_subcompositor_interface, version));
  }
}

// wl_registry.global_remove callback.
// Can be safely ignored unless we bind to globals that might be removed.
static void registry_handle_global_remove(void*, wl_registry*, uint32_t) {}

static const wl_registry_listener registry_listener = {
    .global = registry_handle_global,
    .global_remove = registry_handle_global_remove,
};

// The first time this function is called, all Wayland globals are initialized
// (which blocks for a round trip to the Wayland compositor).
// Subsequent calls return immediately.
static void fl_renderer_wayland_lazy_init_wl(FlRendererWayland* self) {
  if (self->registry) {
    return;
  }

  GdkWaylandDisplay* gdk_display =
      GDK_WAYLAND_DISPLAY(gdk_display_get_default());
  g_return_if_fail(gdk_display);

  wl_display* display = gdk_wayland_display_get_wl_display(gdk_display);
  self->registry = wl_display_get_registry(display);
  wl_registry_add_listener(self->registry, &registry_listener, self);
  wl_display_roundtrip(display);
}

// Implements GObject::dispose.
static void fl_renderer_wayland_dispose(GObject* object) {
  FlRendererWayland* self = FL_RENDERER_WAYLAND(object);

  g_clear_pointer(&self->registry, wl_registry_destroy);
  g_clear_pointer(&self->subcompositor, wl_subcompositor_destroy);

  g_clear_pointer(&self->subsurface.subsurface, wl_subsurface_destroy);
  g_clear_pointer(&self->subsurface.egl_window, wl_egl_window_destroy);
  g_clear_pointer(&self->subsurface.surface, wl_surface_destroy);

  g_clear_pointer(&self->resource.egl_window, wl_egl_window_destroy);
  g_clear_pointer(&self->resource.surface, wl_surface_destroy);

  G_OBJECT_CLASS(fl_renderer_wayland_parent_class)->dispose(object);
}

// Implements FlRenderer::create_display.
static EGLDisplay fl_renderer_wayland_create_display(FlRenderer* /*renderer*/) {
  GdkWaylandDisplay* gdk_display =
      GDK_WAYLAND_DISPLAY(gdk_display_get_default());
  g_return_val_if_fail(gdk_display, nullptr);
  return eglGetDisplay(gdk_wayland_display_get_wl_display(gdk_display));
}

static void fl_renderer_wayland_on_window_map(FlRendererWayland* self,
                                              GtkWidget* widget) {
  if (self->subsurface.subsurface) {
    g_error("fl_renderer_wayland_on_window_map: already has a subsurface");
    return;
  }

  GdkWaylandDisplay* gdk_display =
      GDK_WAYLAND_DISPLAY(gdk_display_get_default());

  wl_compositor* compositor =
      gdk_wayland_display_get_wl_compositor(gdk_display);

  fl_renderer_wayland_lazy_init_wl(self);
  if (!self->subcompositor) {
    g_error(
        "fl_renderer_wayland_on_window_map: could not bind to "
        "wl_subcompositor");
    return;
  }

  GdkWaylandWindow* window = GDK_WAYLAND_WINDOW(gtk_widget_get_window(widget));
  if (!window) {
    g_error("fl_renderer_wayland_on_window_map: not a Wayland window");
    return;
  }
  wl_surface* toplevel_surface = gdk_wayland_window_get_wl_surface(window);
  if (!toplevel_surface) {
    g_error("fl_renderer_wayland_on_window_map: could not get wl_surface");
    return;
  }

  self->subsurface.subsurface = wl_subcompositor_get_subsurface(
      self->subcompositor, self->subsurface.surface, toplevel_surface);
  if (!self->subsurface.subsurface) {
    g_error("fl_renderer_wayland_on_window_map: could not create subsurface");
    return;
  }

  wl_subsurface_set_desync(self->subsurface.subsurface);
  wl_subsurface_set_position(self->subsurface.subsurface,
                             self->subsurface.geometry.x,
                             self->subsurface.geometry.y);

  // Give the subsurface an empty input region so the main surface gets input.
  wl_region* region = wl_compositor_create_region(compositor);
  wl_surface_set_input_region(self->subsurface.surface, region);
  wl_region_destroy(region);

  wl_surface_commit(self->subsurface.surface);
}

static void fl_renderer_wayland_on_window_unmap(FlRendererWayland* self,
                                                GtkWidget* widget) {
  g_clear_pointer(&self->subsurface.subsurface, wl_subsurface_destroy);
}

// Implements FlRenderer::create_surfaces.
static gboolean fl_renderer_wayland_create_surfaces(FlRenderer* renderer,
                                                    GtkWidget* widget,
                                                    EGLDisplay display,
                                                    EGLConfig config,
                                                    EGLSurface* visible,
                                                    EGLSurface* resource,
                                                    GError** error) {
  FlRendererWayland* self = FL_RENDERER_WAYLAND(renderer);

  if (self->subsurface.surface || self->subsurface.egl_window ||
      self->resource.surface || self->resource.egl_window) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Surfaces already created");
    return FALSE;
  }

  if (!GDK_IS_WAYLAND_DISPLAY(gdk_display_get_default())) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Expected Wayland display");
    return FALSE;
  }
  GdkWaylandDisplay* gdk_display =
      GDK_WAYLAND_DISPLAY(gdk_display_get_default());

  wl_compositor* compositor =
      gdk_wayland_display_get_wl_compositor(gdk_display);
  if (!compositor) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "No wl_compositor");
    return FALSE;
  }

  // Make sure size and scale is not <= 0
  self->subsurface.scale = MAX(self->subsurface.scale, 1);
  self->subsurface.geometry.width = MAX(self->subsurface.geometry.width, 1);
  self->subsurface.geometry.height = MAX(self->subsurface.geometry.height, 1);

  self->subsurface.surface = wl_compositor_create_surface(compositor);
  self->resource.surface = wl_compositor_create_surface(compositor);
  if (!self->subsurface.surface || !self->resource.surface) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to create wl_surfaces");
    return FALSE;
  }
  wl_surface_set_buffer_scale(self->subsurface.surface, self->subsurface.scale);

  gint window_width = self->subsurface.geometry.width * self->subsurface.scale;
  gint window_height =
      self->subsurface.geometry.height * self->subsurface.scale;
  self->subsurface.egl_window = wl_egl_window_create(
      self->subsurface.surface, window_width, window_height);
  self->resource.egl_window =
      wl_egl_window_create(self->resource.surface, 1, 1);
  if (!self->subsurface.egl_window || !self->resource.egl_window) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to create EGL windows");
    return FALSE;
  }

  *visible = eglCreateWindowSurface(display, config,
                                    self->subsurface.egl_window, nullptr);
  *resource = eglCreateWindowSurface(display, config, self->resource.egl_window,
                                     nullptr);
  if (*visible == EGL_NO_SURFACE || *resource == EGL_NO_SURFACE) {
    EGLint egl_error = eglGetError();  // must be before egl_config_to_string()
    g_autofree gchar* config_string = egl_config_to_string(display, config);
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to create EGL surfaces using configuration (%s): %s",
                config_string, egl_error_to_string(egl_error));
    return FALSE;
  }

  GtkWidget* toplevel = gtk_widget_get_toplevel(widget);
  if (!toplevel) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Renderer does not have a widget");
    return FALSE;
  }
  g_signal_connect_object(toplevel, "map",
                          G_CALLBACK(fl_renderer_wayland_on_window_map), self,
                          G_CONNECT_SWAPPED);
  g_signal_connect_object(toplevel, "unmap",
                          G_CALLBACK(fl_renderer_wayland_on_window_unmap), self,
                          G_CONNECT_SWAPPED);
  if (gtk_widget_get_mapped(toplevel)) {
    fl_renderer_wayland_on_window_map(self, toplevel);
  }

  return TRUE;
}

// Implements FlRenderer::set_geometry.
static void fl_renderer_wayland_set_geometry(FlRenderer* renderer,
                                             GdkRectangle* geometry,
                                             gint scale) {
  FlRendererWayland* self = FL_RENDERER_WAYLAND(renderer);

  if (scale != self->subsurface.scale && self->subsurface.surface) {
    wl_surface_set_buffer_scale(self->subsurface.surface, scale);
  }

  // NOTE: position is unscaled but size is scaled.

  if ((geometry->x != self->subsurface.geometry.x ||
       geometry->y != self->subsurface.geometry.y) &&
      self->subsurface.subsurface) {
    wl_subsurface_set_position(self->subsurface.subsurface, geometry->x,
                               geometry->y);
  }

  if ((geometry->width != self->subsurface.geometry.width ||
       geometry->height != self->subsurface.geometry.height ||
       scale != self->subsurface.scale) &&
      self->subsurface.egl_window) {
    wl_egl_window_resize(self->subsurface.egl_window, geometry->width * scale,
                         geometry->height * scale, 0, 0);
  }

  self->subsurface.geometry = *geometry;
  self->subsurface.scale = scale;
}

static void fl_renderer_wayland_class_init(FlRendererWaylandClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_renderer_wayland_dispose;
  FL_RENDERER_CLASS(klass)->create_display = fl_renderer_wayland_create_display;
  FL_RENDERER_CLASS(klass)->create_surfaces =
      fl_renderer_wayland_create_surfaces;
  FL_RENDERER_CLASS(klass)->set_geometry = fl_renderer_wayland_set_geometry;
}

static void fl_renderer_wayland_init(FlRendererWayland* self) {}

FlRendererWayland* fl_renderer_wayland_new() {
  return FL_RENDERER_WAYLAND(
      g_object_new(fl_renderer_wayland_get_type(), nullptr));
}
