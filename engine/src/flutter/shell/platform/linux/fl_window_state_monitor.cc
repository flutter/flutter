// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_window_state_monitor.h"

#include <gtk/gtk.h>

#include "flutter/shell/platform/linux/fl_engine_private.h"

struct _FlWindowStateMonitor {
  GObject parent_instance;

  // Engine to report state changes to.
  FlEngine* engine;

  // Window being monitored.
  GtkWindow* window;

  // Current state information.
  GdkWindowState window_state;
};

G_DEFINE_TYPE(FlWindowStateMonitor, fl_window_state_monitor, G_TYPE_OBJECT);

static gboolean is_hidden(GdkWindowState state) {
  return (state & GDK_WINDOW_STATE_WITHDRAWN) ||
         (state & GDK_WINDOW_STATE_ICONIFIED);
}

// Signal handler for GtkWindow::window-state-event
static gboolean window_state_event_cb(FlWindowStateMonitor* self,
                                      GdkEvent* event) {
  GdkWindowState state = event->window_state.new_window_state;
  GdkWindowState previous_state = self->window_state;
  self->window_state = state;
  bool was_visible = !is_hidden(previous_state);
  bool is_visible = !is_hidden(state);
  bool was_focused = (previous_state & GDK_WINDOW_STATE_FOCUSED);
  bool is_focused = (state & GDK_WINDOW_STATE_FOCUSED);

  if (was_visible != is_visible || was_focused != is_focused) {
    FlutterAppLifecycleState lifecycle_state;
    if (is_visible) {
      lifecycle_state = is_focused ? kFlutterAppLifecycleStateResumed
                                   : kFlutterAppLifecycleStateInactive;
    } else {
      lifecycle_state = kFlutterAppLifecycleStateHidden;
    }

    fl_engine_set_app_lifecycle_state(self->engine, lifecycle_state);
  }

  return FALSE;
}

static void fl_window_state_monitor_dispose(GObject* object) {
  FlWindowStateMonitor* self = FL_WINDOW_STATE_MONITOR(object);

  g_clear_object(&self->engine);

  G_OBJECT_CLASS(fl_window_state_monitor_parent_class)->dispose(object);
}

static void fl_window_state_monitor_class_init(
    FlWindowStateMonitorClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_window_state_monitor_dispose;
}

static void fl_window_state_monitor_init(FlWindowStateMonitor* self) {}

FlWindowStateMonitor* fl_window_state_monitor_new(FlEngine* engine,
                                                  GtkWindow* window) {
  FlWindowStateMonitor* self = FL_WINDOW_STATE_MONITOR(
      g_object_new(fl_window_state_monitor_get_type(), nullptr));
  self->engine = FL_ENGINE(g_object_ref(engine));
  self->window = window;

  // Listen to window state changes.
  g_signal_connect_object(self->window, "window-state-event",
                          G_CALLBACK(window_state_event_cb), self,
                          G_CONNECT_SWAPPED);
  self->window_state =
      gdk_window_get_state(gtk_widget_get_window(GTK_WIDGET(self->window)));

  return self;
}
