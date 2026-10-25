// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_display_monitor_backend.h"

#include "flutter/shell/platform/linux/fl_gtk.h"

struct _FlDisplayMonitorBackend {
  GListModel* monitors;
  GPtrArray* subscribed_monitors;
  FlDisplayMonitorBackendChanged changed;
  gpointer user_data;
};

static void monitor_properties_changed_cb(GdkMonitor* monitor,
                                          GParamSpec* pspec,
                                          FlDisplayMonitorBackend* self) {
  if (g_str_equal(pspec->name, "scale") ||
      g_str_equal(pspec->name, "scale-factor") ||
      g_str_equal(pspec->name, "geometry") ||
      g_str_equal(pspec->name, "refresh-rate")) {
    self->changed(nullptr, FALSE, self->user_data);
  }
}

GPtrArray* fl_display_monitor_backend_get_monitors(
    FlDisplayMonitorBackend* self) {
  GPtrArray* monitors = g_ptr_array_new_with_free_func(g_object_unref);
  const guint count = g_list_model_get_n_items(self->monitors);
  for (guint i = 0; i < count; i++) {
    g_ptr_array_add(monitors, g_list_model_get_item(self->monitors, i));
  }
  return monitors;
}

static void subscribe_monitors(FlDisplayMonitorBackend* self) {
  if (self->subscribed_monitors != nullptr) {
    for (guint i = 0; i < self->subscribed_monitors->len; i++) {
      g_signal_handlers_disconnect_by_data(
          g_ptr_array_index(self->subscribed_monitors, i), self);
    }
    g_ptr_array_unref(self->subscribed_monitors);
  }
  self->subscribed_monitors = fl_display_monitor_backend_get_monitors(self);
  for (guint i = 0; i < self->subscribed_monitors->len; i++) {
    g_signal_connect(g_ptr_array_index(self->subscribed_monitors, i), "notify",
                     G_CALLBACK(monitor_properties_changed_cb), self);
  }
}

static void monitors_changed_cb(GListModel* monitors,
                                guint position,
                                guint removed,
                                guint added,
                                FlDisplayMonitorBackend* self) {
  subscribe_monitors(self);
  self->changed(nullptr, TRUE, self->user_data);
}

FlDisplayMonitorBackend* fl_display_monitor_backend_new(
    GdkDisplay* display,
    FlDisplayMonitorBackendChanged changed,
    gpointer user_data) {
  FlDisplayMonitorBackend* self = g_new0(FlDisplayMonitorBackend, 1);
  self->monitors =
      G_LIST_MODEL(g_object_ref(gdk_display_get_monitors(display)));
  self->changed = changed;
  self->user_data = user_data;
  subscribe_monitors(self);
  g_signal_connect(self->monitors, "items-changed",
                   G_CALLBACK(monitors_changed_cb), self);
  return self;
}

void fl_display_monitor_backend_free(FlDisplayMonitorBackend* self) {
  g_signal_handlers_disconnect_by_data(self->monitors, self);
  for (guint i = 0; i < self->subscribed_monitors->len; i++) {
    g_signal_handlers_disconnect_by_data(
        g_ptr_array_index(self->subscribed_monitors, i), self);
  }
  g_clear_pointer(&self->subscribed_monitors, g_ptr_array_unref);
  g_clear_object(&self->monitors);
  g_free(self);
}

double fl_display_monitor_backend_get_scale(GdkMonitor* monitor) {
  return fl_gtk_monitor_get_scale(monitor);
}
