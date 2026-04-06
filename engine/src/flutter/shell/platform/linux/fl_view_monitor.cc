// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <gtk/gtk.h>

#include "flutter/shell/platform/common/isolate_scope.h"
#include "flutter/shell/platform/linux/fl_view_monitor.h"

struct _FlViewMonitor {
  GObject parent_instance;

  // View being monitored.
  FlView* view;

  // Isolate to call callbacks with.
  flutter::Isolate isolate;

  // Callbacks.
  void (*on_first_frame)(void);
};

G_DEFINE_TYPE(FlViewMonitor, fl_view_monitor, G_TYPE_OBJECT)

static void first_frame_cb(FlViewMonitor* self) {
  flutter::IsolateScope scope(self->isolate);
  if (self->on_first_frame) {
    self->on_first_frame();
  }
}

static void fl_view_monitor_dispose(GObject* object) {
  FlViewMonitor* self = FL_VIEW_MONITOR(object);

  // Disconnect all handlers using data. If we try and disconnect them
  // individually they generate warnings after the widget has been destroyed.
  g_signal_handlers_disconnect_by_data(self->view, self);
  g_clear_object(&self->view);

  G_OBJECT_CLASS(fl_view_monitor_parent_class)->dispose(object);
}

static void fl_view_monitor_class_init(FlViewMonitorClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_view_monitor_dispose;
}

static void fl_view_monitor_init(FlViewMonitor* self) {}

G_MODULE_EXPORT FlViewMonitor* fl_view_monitor_new(
    FlView* view,
    void (*on_first_frame)(void)) {
  FlViewMonitor* self =
      FL_VIEW_MONITOR(g_object_new(fl_view_monitor_get_type(), nullptr));

  self->view = FL_VIEW(g_object_ref(view));
  self->isolate = flutter::Isolate::Current();
  self->on_first_frame = on_first_frame;
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);

  return self;
}
