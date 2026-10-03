// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_view_private.h"

#include <gdk/wayland/gdkwayland.h>

#include "flutter/common/constants.h"
#include "flutter/shell/platform/linux/fl_compositor_opengl.h"
#include "flutter/shell/platform/linux/fl_compositor_software.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_gtk.h"
#include "flutter/shell/platform/linux/fl_wayland_display.h"

static gboolean gtk4_subsurface_enabled() {
  return g_strcmp0(g_getenv("FLUTTER_GTK4_ENABLE_SUBSURFACE"), "1") == 0;
}

void fl_view_gtk4_setup_subsurface(FlView* view) {
  if (view->engine == nullptr || !gtk4_subsurface_enabled() ||
      fl_engine_get_renderer_type(view->engine) != kOpenGL ||
      view->view_id != flutter::kFlutterImplicitViewId) {
    return;
  }

  GtkWidget* toplevel = fl_view_gtk4_get_toplevel_window(view);
  if (toplevel == nullptr || !GTK_IS_NATIVE(toplevel)) {
    return;
  }
  GdkSurface* surface = gtk_native_get_surface(GTK_NATIVE(toplevel));
  if (!GDK_IS_WAYLAND_SURFACE(surface)) {
    return;
  }

  FlWaylandDisplay* display =
      fl_wayland_display_get_for_display(gtk_widget_get_display(toplevel));
  if (display == nullptr) {
    return;
  }
  FlSubsurface* subsurface = fl_wayland_display_create_subsurface(
      display, gdk_wayland_surface_get_wl_surface(surface));
  if (subsurface == nullptr) {
    return;
  }

  const int width = gtk_widget_get_width(view->render_area);
  const int height = gtk_widget_get_height(view->render_area);
  if (width <= 0 || height <= 0) {
    return;
  }
  const int scale = MAX(gtk_widget_get_scale_factor(view->render_area), 1);
  FlSubsurfaceEGL* subsurface_egl =
      fl_subsurface_egl_new(fl_engine_get_opengl_manager(view->engine),
                            subsurface, width, height, scale);
  if (!fl_subsurface_egl_is_ready(subsurface_egl)) {
    g_object_unref(subsurface_egl);
    g_object_unref(subsurface);
    return;
  }

  graphene_point_t point = GRAPHENE_POINT_INIT(0.0f, 0.0f);
  graphene_point_t translated_point;
  if (gtk_widget_compute_point(view->render_area, toplevel, &point,
                               &translated_point)) {
    fl_subsurface_set_position(subsurface, static_cast<int>(translated_point.x),
                               static_cast<int>(translated_point.y));
  }

  g_mutex_lock(&view->subsurface_mutex);
  view->subsurface = subsurface;
  view->subsurface_egl = subsurface_egl;
  view->subsurface_enabled = TRUE;
  g_mutex_unlock(&view->subsurface_mutex);
}

void fl_view_gtk4_resize_subsurface(FlView* view, int width, int height) {
  g_mutex_lock(&view->subsurface_mutex);
  const gboolean subsurface_enabled = view->subsurface_enabled;
  if (view->subsurface_enabled && view->subsurface_egl != nullptr) {
    const int scale = MAX(gtk_widget_get_scale_factor(view->render_area), 1);
    fl_subsurface_egl_resize(view->subsurface_egl, width * scale,
                             height * scale);
  }
  g_mutex_unlock(&view->subsurface_mutex);

  if (!subsurface_enabled && width > 0 && height > 0) {
    fl_view_gtk4_setup_subsurface(view);
  }
}

static void setup_opengl(FlView* self) {
  g_autoptr(GError) error = nullptr;

  FlGdkSurface* surface =
      fl_gtk_widget_get_surface(GTK_WIDGET(self->render_area));
  if (surface == nullptr) {
    return;
  }
  self->render_context = fl_gtk_surface_create_gl_context(surface, &error);
  if (self->render_context == nullptr) {
    g_warning("Failed to create OpenGL context: %s", error->message);
    return;
  }

  if (!gdk_gl_context_realize(self->render_context, &error)) {
    g_warning("Failed to realize OpenGL context: %s", error->message);
    return;
  }

  // If using Wayland, then EGL is in use and we can access the frame
  // from the Flutter context using EGLImage. If not (i.e. X11 using GLX)
  // then we have to copy the texture via the CPU.
  gboolean shareable =
      GDK_IS_WAYLAND_DISPLAY(fl_gtk_surface_get_display(surface));
  self->compositor = FL_COMPOSITOR(fl_compositor_opengl_new(
      fl_engine_get_task_runner(self->engine),
      fl_engine_get_opengl_manager(self->engine), shareable));
}

static void setup_software(FlView* self) {
  self->compositor = FL_COMPOSITOR(
      fl_compositor_software_new(fl_engine_get_task_runner(self->engine)));
}

void fl_view_gtk4_setup_rendering(FlView* self) {
  switch (fl_engine_get_renderer_type(self->engine)) {
    case kOpenGL:
      setup_opengl(self);
      break;
    case kSoftware:
      setup_software(self);
      break;
    default:
      break;
  }

  fl_view_gtk4_setup_subsurface(self);
}

// Called on the raster thread after compositing the frame.
void fl_view_gtk4_present_subsurface(FlView* self) {
  g_autoptr(FlSubsurfaceEGL) subsurface_egl = nullptr;
  g_mutex_lock(&self->subsurface_mutex);
  if (self->subsurface_enabled && self->subsurface_egl != nullptr) {
    subsurface_egl = FL_SUBSURFACE_EGL(g_object_ref(self->subsurface_egl));
  }
  g_mutex_unlock(&self->subsurface_mutex);
  if (subsurface_egl != nullptr && FL_IS_COMPOSITOR_OPENGL(self->compositor)) {
    fl_compositor_opengl_present_to_subsurface(
        FL_COMPOSITOR_OPENGL(self->compositor), subsurface_egl);
  }
}
