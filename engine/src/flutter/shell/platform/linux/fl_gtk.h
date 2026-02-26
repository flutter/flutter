// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK_H_

#include <gtk/gtk.h>

#if FLUTTER_LINUX_GTK4
typedef GdkSurface FlGdkSurface;

static inline FlGdkSurface* fl_gtk_widget_get_surface(GtkWidget* widget) {
  GtkNative* native = gtk_widget_get_native(widget);
  return native != nullptr ? gtk_native_get_surface(native) : nullptr;
}

static inline GdkDisplay* fl_gtk_surface_get_display(FlGdkSurface* surface) {
  return gdk_surface_get_display(surface);
}

static inline gint fl_gtk_surface_get_scale_factor(FlGdkSurface* surface) {
  return gdk_surface_get_scale_factor(surface);
}

static inline gint fl_gtk_surface_get_width(FlGdkSurface* surface) {
  return gdk_surface_get_width(surface);
}

static inline gint fl_gtk_surface_get_height(FlGdkSurface* surface) {
  return gdk_surface_get_height(surface);
}

static inline GdkMonitor* fl_gtk_display_get_monitor_at_surface(
    GdkDisplay* display,
    FlGdkSurface* surface) {
  return gdk_display_get_monitor_at_surface(display, surface);
}

static inline void fl_gtk_surface_set_cursor(FlGdkSurface* surface,
                                             GdkCursor* cursor) {
  gdk_surface_set_cursor(surface, cursor);
}

static inline GdkGLContext* fl_gtk_surface_create_gl_context(
    FlGdkSurface* surface,
    GError** error) {
  return gdk_surface_create_gl_context(surface, error);
}
#else
typedef GdkWindow FlGdkSurface;

static inline FlGdkSurface* fl_gtk_widget_get_surface(GtkWidget* widget) {
  return gtk_widget_get_window(widget);
}

static inline GdkDisplay* fl_gtk_surface_get_display(FlGdkSurface* surface) {
  return gdk_window_get_display(surface);
}

static inline gint fl_gtk_surface_get_scale_factor(FlGdkSurface* surface) {
  return gdk_window_get_scale_factor(surface);
}

static inline gint fl_gtk_surface_get_width(FlGdkSurface* surface) {
  return gdk_window_get_width(surface);
}

static inline gint fl_gtk_surface_get_height(FlGdkSurface* surface) {
  return gdk_window_get_height(surface);
}

static inline GdkMonitor* fl_gtk_display_get_monitor_at_surface(
    GdkDisplay* display,
    FlGdkSurface* surface) {
  return gdk_display_get_monitor_at_window(display, surface);
}

static inline void fl_gtk_surface_set_cursor(FlGdkSurface* surface,
                                             GdkCursor* cursor) {
  gdk_window_set_cursor(surface, cursor);
}

static inline GdkGLContext* fl_gtk_surface_create_gl_context(
    FlGdkSurface* surface,
    GError** error) {
  return gdk_window_create_gl_context(surface, error);
}
#endif  // FLUTTER_LINUX_GTK4

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK_H_
