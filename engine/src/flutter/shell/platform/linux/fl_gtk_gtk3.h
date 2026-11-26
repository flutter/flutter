// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK_GTK3_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK_GTK3_H_

#include <gtk/gtk.h>

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

static inline double fl_gtk_widget_get_scale(GtkWidget* widget) {
  return static_cast<double>(gtk_widget_get_scale_factor(widget));
}

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK_GTK3_H_
