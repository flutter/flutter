// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_display_monitor_backend.h"

struct _FlDisplayMonitorBackend {
  GdkDisplay* display;
  FlDisplayMonitorBackendChanged changed;
  gpointer user_data;
};

static void monitor_added_cb(GdkDisplay* display,
                             GdkMonitor* monitor,
                             FlDisplayMonitorBackend* self) {
  self->changed(nullptr, FALSE, self->user_data);
}

static void monitor_removed_cb(GdkDisplay* display,
                               GdkMonitor* monitor,
                               FlDisplayMonitorBackend* self) {
  self->changed(monitor, FALSE, self->user_data);
}

FlDisplayMonitorBackend* fl_display_monitor_backend_new(
    GdkDisplay* display,
    FlDisplayMonitorBackendChanged changed,
    gpointer user_data) {
  FlDisplayMonitorBackend* self = g_new0(FlDisplayMonitorBackend, 1);
  self->display = GDK_DISPLAY(g_object_ref(display));
  self->changed = changed;
  self->user_data = user_data;
  g_signal_connect(display, "monitor-added", G_CALLBACK(monitor_added_cb),
                   self);
  g_signal_connect(display, "monitor-removed", G_CALLBACK(monitor_removed_cb),
                   self);
  return self;
}

void fl_display_monitor_backend_free(FlDisplayMonitorBackend* self) {
  g_signal_handlers_disconnect_by_data(self->display, self);
  g_clear_object(&self->display);
  g_free(self);
}

GPtrArray* fl_display_monitor_backend_get_monitors(
    FlDisplayMonitorBackend* self) {
  GPtrArray* monitors = g_ptr_array_new_with_free_func(g_object_unref);
  const int count = gdk_display_get_n_monitors(self->display);
  for (int i = 0; i < count; i++) {
    g_ptr_array_add(monitors,
                    g_object_ref(gdk_display_get_monitor(self->display, i)));
  }
  return monitors;
}

double fl_display_monitor_backend_get_scale(GdkMonitor* monitor) {
  return gdk_monitor_get_scale_factor(monitor);
}
