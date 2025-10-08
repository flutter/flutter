// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <gtk/gtk.h>

#include "flutter/shell/platform/common/isolate_scope.h"
#include "flutter/shell/platform/linux/fl_window_monitor.h"

struct _FlWindowMonitor {
  GObject parent_instance;

  // Window being monitored.
  GtkWindow* window;

  // Isolate to call callbacks with.
  flutter::Isolate isolate;

  // Callbacks.
  void (*on_configure)(void);
  void (*on_state_changed)(void);
  void (*is_active_notify)(void);
  void (*on_close)(void);
  void (*on_destroy)(void);

  // Signal subscriptions.
  gulong configure_event_cb_id;
  gulong window_state_event_cb_id;
  gulong is_active_notify_cb_id;
  gulong delete_event_cb_id;
  gulong destroy_cb_id;
};

G_DEFINE_TYPE(FlWindowMonitor, fl_window_monitor, G_TYPE_OBJECT)

static gboolean configure_event_cb(FlWindowMonitor* self,
                                   GdkEventConfigure* event) {
  flutter::IsolateScope scope(self->isolate);
  self->on_configure();

  return FALSE;
}

static gboolean window_state_event_cb(FlWindowMonitor* self,
                                      GdkEventWindowState* event) {
  flutter::IsolateScope scope(self->isolate);
  self->on_state_changed();

  return FALSE;
}

static void is_active_notify_cb(FlWindowMonitor* self) {
  flutter::IsolateScope scope(self->isolate);
  self->is_active_notify();
}

static gboolean delete_event_cb(FlWindowMonitor* self, GdkEvent* event) {
  flutter::IsolateScope scope(self->isolate);
  self->on_close();

  // Stop default behaviour of destroying the window.
  return TRUE;
}

static void destroy_cb(FlWindowMonitor* self) {
  flutter::IsolateScope scope(self->isolate);
  self->on_destroy();
}

static void fl_window_monitor_dispose(GObject* object) {
  FlWindowMonitor* self = FL_WINDOW_MONITOR(object);

  g_clear_object(&self->window);
  g_signal_handler_disconnect(self->window, self->configure_event_cb_id);
  g_signal_handler_disconnect(self->window, self->window_state_event_cb_id);
  g_signal_handler_disconnect(self->window, self->is_active_notify_cb_id);
  g_signal_handler_disconnect(self->window, self->delete_event_cb_id);
  g_signal_handler_disconnect(self->window, self->destroy_cb_id);

  G_OBJECT_CLASS(fl_window_monitor_parent_class)->dispose(object);
}

static void fl_window_monitor_class_init(FlWindowMonitorClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_window_monitor_dispose;
}

static void fl_window_monitor_init(FlWindowMonitor* self) {}

G_MODULE_EXPORT FlWindowMonitor* fl_window_monitor_new(
    GtkWindow* window,
    void (*on_configure)(void),
    void (*on_state_changed)(void),
    void (*is_active_notify)(void),
    void (*on_close)(void),
    void (*on_destroy)(void)) {
  FlWindowMonitor* self =
      FL_WINDOW_MONITOR(g_object_new(fl_window_monitor_get_type(), nullptr));

  self->window = GTK_WINDOW(g_object_ref(window));
  self->isolate = flutter::Isolate::Current();
  self->on_configure = on_configure;
  self->on_state_changed = on_state_changed;
  self->is_active_notify = is_active_notify;
  self->on_close = on_close;
  self->on_destroy = on_destroy;
  self->configure_event_cb_id = g_signal_connect_swapped(
      window, "configure-event", G_CALLBACK(configure_event_cb), self);
  self->window_state_event_cb_id = g_signal_connect_swapped(
      window, "window-state-event", G_CALLBACK(window_state_event_cb), self);
  self->is_active_notify_cb_id = g_signal_connect_swapped(
      window, "notify::is-active", G_CALLBACK(is_active_notify_cb), self);
  self->delete_event_cb_id = g_signal_connect_swapped(
      window, "delete-event", G_CALLBACK(delete_event_cb), self);
  self->destroy_cb_id =
      g_signal_connect_swapped(window, "destroy", G_CALLBACK(destroy_cb), self);

  return self;
}
