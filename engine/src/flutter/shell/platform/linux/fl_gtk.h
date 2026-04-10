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

static inline double fl_gtk_surface_get_scale(FlGdkSurface* surface) {
#if GTK_CHECK_VERSION(4, 12, 0)
  return gdk_surface_get_scale(surface);
#else
  return static_cast<double>(gdk_surface_get_scale_factor(surface));
#endif
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

static inline double fl_gtk_monitor_get_scale(GdkMonitor* monitor) {
#if GTK_CHECK_VERSION(4, 14, 0)
  return gdk_monitor_get_scale(monitor);
#else
  return static_cast<double>(gdk_monitor_get_scale_factor(monitor));
#endif
}

static inline double fl_gtk_widget_get_scale(GtkWidget* widget) {
  FlGdkSurface* surface = fl_gtk_widget_get_surface(widget);
  return surface != nullptr
             ? fl_gtk_surface_get_scale(surface)
             : static_cast<double>(gtk_widget_get_scale_factor(widget));
}

static inline size_t fl_gtk_size_to_pixels(double logical_size, double scale) {
  return logical_size <= 0.0 || scale <= 0.0
             ? 0
             : static_cast<size_t>(logical_size * scale + 0.5);
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

static inline double fl_gtk_surface_get_scale(FlGdkSurface* surface) {
  return static_cast<double>(gdk_window_get_scale_factor(surface));
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

static inline double fl_gtk_monitor_get_scale(GdkMonitor* monitor) {
  return static_cast<double>(gdk_monitor_get_scale_factor(monitor));
}

static inline double fl_gtk_widget_get_scale(GtkWidget* widget) {
  return static_cast<double>(gtk_widget_get_scale_factor(widget));
}

static inline size_t fl_gtk_size_to_pixels(double logical_size, double scale) {
  return logical_size <= 0.0 || scale <= 0.0
             ? 0
             : static_cast<size_t>(logical_size * scale + 0.5);
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
