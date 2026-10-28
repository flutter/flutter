// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <gtk/gtk.h>

#include "flutter/shell/platform/common/isolate_scope.h"
#if FLUTTER_LINUX_GTK4
#include "flutter/shell/platform/linux/fl_view_private.h"
#endif
#include "flutter/shell/platform/linux/fl_view_monitor.h"

struct _FlViewMonitor {
  GObject parent_instance;

  // View being monitored.
  FlView* view;

  // Isolate to call callbacks with.
  flutter::Isolate isolate;

  // Callbacks.
  void (*on_first_frame)(void);
  void (*on_size_changed)(int width, int height);
};

G_DEFINE_TYPE(FlViewMonitor, fl_view_monitor, G_TYPE_OBJECT)

static void first_frame_cb(FlViewMonitor* self) {
  flutter::IsolateScope scope(self->isolate);
  if (self->on_first_frame) {
    self->on_first_frame();
  }
}

#if !FLUTTER_LINUX_GTK4
static void size_allocate_cb(FlViewMonitor* self, GtkAllocation* allocation) {
  flutter::IsolateScope scope(self->isolate);
  if (self->on_size_changed) {
    self->on_size_changed(allocation->width, allocation->height);
  }
}
#endif

#if FLUTTER_LINUX_GTK4
static void resize_cb(FlViewMonitor* self, int width, int height) {
  flutter::IsolateScope scope(self->isolate);
  if (self->on_size_changed) {
    self->on_size_changed(width, height);
  }
}
#endif
static void fl_view_monitor_dispose(GObject* object) {
  FlViewMonitor* self = FL_VIEW_MONITOR(object);

  g_clear_object(&self->view);

  G_OBJECT_CLASS(fl_view_monitor_parent_class)->dispose(object);
}

static void fl_view_monitor_class_init(FlViewMonitorClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_view_monitor_dispose;
}

static void fl_view_monitor_init(FlViewMonitor* self) {}

G_MODULE_EXPORT FlViewMonitor* fl_view_monitor_new(
    FlView* view,
    void (*on_first_frame)(void),
    void (*on_size_changed)(int width, int height)) {
  FlViewMonitor* self =
      FL_VIEW_MONITOR(g_object_new(fl_view_monitor_get_type(), nullptr));

  self->view = FL_VIEW(g_object_ref(view));
  self->isolate = flutter::Isolate::Current();
  self->on_first_frame = on_first_frame;
  self->on_size_changed = on_size_changed;
  g_signal_connect_object(view, "first-frame", G_CALLBACK(first_frame_cb), self,
                          G_CONNECT_SWAPPED);
#if FLUTTER_LINUX_GTK4
  // A secondary view can render before Dart has created this monitor. Replay
  // the state so clients that present a window on its first frame do not wait
  // indefinitely for a signal that has already been emitted.
  if (view->have_first_frame) {
    first_frame_cb(self);
  }

  // GTK4 removed GtkWidget::size-allocate. Monitor the render area, which
  // emits GTK4's resize signal with the same logical-pixel dimensions.
  g_signal_connect_object(view->render_area, "resize", G_CALLBACK(resize_cb),
                          self, G_CONNECT_SWAPPED);
#else
  g_signal_connect_object(view, "size-allocate", G_CALLBACK(size_allocate_cb),
                          self, G_CONNECT_SWAPPED);
#endif

  return self;
}
