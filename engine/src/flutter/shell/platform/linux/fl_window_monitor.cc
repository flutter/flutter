// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <gtk/gtk.h>

#include "dart_api.h"
#include "flutter/shell/platform/linux/fl_window_monitor.h"

struct _FlWindowMonitor {
  GObject parent_instance;

  GtkWindow* window;
  Dart_Isolate isolate;
  Dart_Isolate previous_isolate;
  void (*on_close)(void);
  void (*on_destroy)(void);
  gulong window_delete_event_cb_id;
  gulong window_destroy_cb_id;
};

G_DEFINE_TYPE(FlWindowMonitor, fl_window_monitor, G_TYPE_OBJECT)

static void enter_isolate(FlWindowMonitor* self) {
  Dart_Isolate current_isolate = Dart_CurrentIsolate();
  if (self->isolate == current_isolate) {
    return;
  }

  if (current_isolate) {
    Dart_ExitIsolate();
  }
  Dart_EnterIsolate(self->isolate);
  self->previous_isolate = current_isolate;
}

static void leave_isolate(FlWindowMonitor* self) {
  Dart_ExitIsolate();
  Dart_EnterIsolate(self->previous_isolate);
}

// FIXME: Move into window_helper.cc
static gboolean window_delete_event_cb(GtkWindow* window,
                                       GdkEvent* event,
                                       gpointer user_data) {
  FlWindowMonitor* request = reinterpret_cast<FlWindowMonitor*>(user_data);

  enter_isolate(request);
  request->on_close();
  leave_isolate(request);

  // Stop default behaviour of destroying the window.
  return TRUE;
}

static void window_destroy_cb(GtkWidget* widget, gpointer user_data) {
  FlWindowMonitor* request = reinterpret_cast<FlWindowMonitor*>(user_data);

  enter_isolate(request);
  request->on_destroy();
  leave_isolate(request);
}

static void fl_window_monitor_dispose(GObject* object) {
  FlWindowMonitor* self = FL_WINDOW_MONITOR(object);

  g_signal_handler_disconnect(self->window, self->window_delete_event_cb_id);
  g_signal_handler_disconnect(self->window, self->window_destroy_cb_id);

  G_OBJECT_CLASS(fl_window_monitor_parent_class)->dispose(object);
}

static void fl_window_monitor_class_init(FlWindowMonitorClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_window_monitor_dispose;
}

static void fl_window_monitor_init(FlWindowMonitor* self) {}

G_MODULE_EXPORT FlWindowMonitor* fl_window_monitor_new(
    GtkWindow* window,
    void (*on_close)(void),
    void (*on_destroy)(void)) {
  FlWindowMonitor* self =
      FL_WINDOW_MONITOR(g_object_new(fl_window_monitor_get_type(), nullptr));

  self->window = window;
  self->isolate = Dart_CurrentIsolate();
  self->previous_isolate = nullptr;
  self->window_delete_event_cb_id = g_signal_connect(
      window, "delete-event", G_CALLBACK(window_delete_event_cb), self);
  self->window_destroy_cb_id =
      g_signal_connect(window, "destroy", G_CALLBACK(window_destroy_cb), self);

  return self;
}
