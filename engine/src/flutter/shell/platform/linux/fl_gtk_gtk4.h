// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK_GTK4_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK_GTK4_H_

#include <gtk/gtk.h>
#include "flutter/shell/platform/linux/fl_gtk4_runtime_api.h"

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

static inline double fl_gtk_surface_get_scale_with_api(
    FlGdkSurface* surface,
    const FlGtkRuntimeApi* api) {
  return api->gdk_surface_get_scale != nullptr
             ? api->gdk_surface_get_scale(surface)
             : static_cast<double>(gdk_surface_get_scale_factor(surface));
}

static inline double fl_gtk_surface_get_scale(FlGdkSurface* surface) {
  return fl_gtk_surface_get_scale_with_api(surface, fl_gtk_runtime_api_get());
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

static inline double fl_gtk_widget_get_scale(GtkWidget* widget) {
  FlGdkSurface* surface = fl_gtk_widget_get_surface(widget);
  return surface != nullptr
             ? fl_gtk_surface_get_scale(surface)
             : static_cast<double>(gtk_widget_get_scale_factor(widget));
}

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK_GTK4_H_
