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
  void (*on_is_active_notify)(void);
  void (*on_title_notify)(void);
  void (*on_moved_to_rect)(int, int, int, int);
  void (*on_close)(void);
  void (*on_destroy)(void);
};

G_DEFINE_TYPE(FlWindowMonitor, fl_window_monitor, G_TYPE_OBJECT)

#if FLUTTER_LINUX_GTK4
// GtkPopover is not a GtkWindow, but windowing clients still need to observe
// dismissal so their Flutter view can be removed with the popover.
typedef struct _FlPopoverMonitorClass FlPopoverMonitorClass;

struct _FlPopoverMonitor {
  GObject parent_instance;

  GtkPopover* popover;
  flutter::Isolate isolate;
  void (*on_closed)(void);
};

struct _FlPopoverMonitorClass {
  GObjectClass parent_class;
};

G_DEFINE_TYPE(FlPopoverMonitor, fl_popover_monitor, G_TYPE_OBJECT)

static void popover_closed_cb(FlPopoverMonitor* self) {
  flutter::IsolateScope scope(self->isolate);
  self->on_closed();
}

static void fl_popover_monitor_dispose(GObject* object) {
  FlPopoverMonitor* self = reinterpret_cast<FlPopoverMonitor*>(object);
  g_clear_object(&self->popover);

  G_OBJECT_CLASS(fl_popover_monitor_parent_class)->dispose(object);
}

static void fl_popover_monitor_class_init(FlPopoverMonitorClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_popover_monitor_dispose;
}

static void fl_popover_monitor_init(FlPopoverMonitor* self) {}
#endif

#if !FLUTTER_LINUX_GTK4
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
  self->on_is_active_notify();
}

static void title_notify_cb(FlWindowMonitor* self) {
  flutter::IsolateScope scope(self->isolate);
  self->on_title_notify();
}

static void moved_to_rect_cb(FlWindowMonitor* self,
                             GdkRectangle* flipped_rect,
                             GdkRectangle* final_rect,
                             gboolean flipped_x,
                             gboolean flipped_y) {
  // According to the documentation, the final_rect can be null
  // if the backend can't obtain it.
  // Reference: https://docs.gtk.org/gdk3/signal.Window.moved-to-rect.html
  if (final_rect == nullptr) {
    return;
  }

  flutter::IsolateScope scope(self->isolate);
  self->on_moved_to_rect(final_rect->x, final_rect->y, final_rect->width,
                         final_rect->height);
}

// The moved-to-rect signal is on the GdkWindow, which only exists while the
// widget is realized. Re-connected on each realize, since unrealizing destroys
// the GdkWindow (and with it this connection).
static void realize_cb(FlWindowMonitor* self) {
  GdkWindow* window = gtk_widget_get_window(GTK_WIDGET(self->window));
  if (window == nullptr) {
    return;
  }
  g_signal_connect_object(window, "moved-to-rect", G_CALLBACK(moved_to_rect_cb),
                          self, G_CONNECT_SWAPPED);
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
#else
static void configure_notify_cb(FlWindowMonitor* self, GParamSpec* pspec) {
  flutter::IsolateScope scope(self->isolate);
  self->on_configure();
}

static void window_state_notify_cb(FlWindowMonitor* self, GParamSpec* pspec) {
  flutter::IsolateScope scope(self->isolate);
  self->on_state_changed();
}

static void is_active_notify_cb(FlWindowMonitor* self, GParamSpec* pspec) {
  flutter::IsolateScope scope(self->isolate);
  self->on_is_active_notify();
}

static void title_notify_cb(FlWindowMonitor* self, GParamSpec* pspec) {
  flutter::IsolateScope scope(self->isolate);
  self->on_title_notify();
}

static gboolean close_request_cb(FlWindowMonitor* self) {
  flutter::IsolateScope scope(self->isolate);
  self->on_close();

  // The Dart delegate decides whether to destroy the window. Returning true
  // lets it veto the request just as the GTK3 delete-event callback does.
  return TRUE;
}
#endif

static void fl_window_monitor_dispose(GObject* object) {
  FlWindowMonitor* self = FL_WINDOW_MONITOR(object);

  g_clear_object(&self->window);

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
    void (*on_is_active_notify)(void),
    void (*on_title_notify)(void),
    void (*on_moved_to_rect)(int, int, int, int),
    void (*on_close)(void),
    void (*on_destroy)(void)) {
  FlWindowMonitor* self =
      FL_WINDOW_MONITOR(g_object_new(fl_window_monitor_get_type(), nullptr));

  self->window = GTK_WINDOW(g_object_ref(window));
  // Callbacks are made in the isolate this was created in. There is not always
  // an isolate, e.g. in unit tests, and the isolate this object is created with
  // does nothing when entered.
  if (Dart_CurrentIsolate() != nullptr) {
    self->isolate = flutter::Isolate::Current();
  }
  self->on_configure = on_configure;
  self->on_state_changed = on_state_changed;
  self->on_is_active_notify = on_is_active_notify;
  self->on_title_notify = on_title_notify;
  self->on_moved_to_rect = on_moved_to_rect;
  self->on_close = on_close;
  self->on_destroy = on_destroy;
#if !FLUTTER_LINUX_GTK4
  g_signal_connect_object(window, "configure-event",
                          G_CALLBACK(configure_event_cb), self,
                          G_CONNECT_SWAPPED);
  g_signal_connect_object(window, "window-state-event",
                          G_CALLBACK(window_state_event_cb), self,
                          G_CONNECT_SWAPPED);
  g_signal_connect_object(window, "notify::is-active",
                          G_CALLBACK(is_active_notify_cb), self,
                          G_CONNECT_SWAPPED);
  g_signal_connect_object(window, "notify::title", G_CALLBACK(title_notify_cb),
                          self, G_CONNECT_SWAPPED);
  g_signal_connect_object(window, "realize", G_CALLBACK(realize_cb), self,
                          G_CONNECT_SWAPPED);
  if (gtk_widget_get_realized(GTK_WIDGET(window))) {
    realize_cb(self);
  }
  g_signal_connect_object(window, "delete-event", G_CALLBACK(delete_event_cb),
                          self, G_CONNECT_SWAPPED);
  g_signal_connect_object(window, "destroy", G_CALLBACK(destroy_cb), self,
                          G_CONNECT_SWAPPED);
#else
  g_signal_connect_object(window, "notify::width",
                          G_CALLBACK(configure_notify_cb), self,
                          G_CONNECT_SWAPPED);
  g_signal_connect_object(window, "notify::height",
                          G_CALLBACK(configure_notify_cb), self,
                          G_CONNECT_SWAPPED);
  g_signal_connect_object(window, "notify::maximized",
                          G_CALLBACK(window_state_notify_cb), self,
                          G_CONNECT_SWAPPED);
  g_signal_connect_object(window, "notify::fullscreen",
                          G_CALLBACK(window_state_notify_cb), self,
                          G_CONNECT_SWAPPED);
  g_signal_connect_object(window, "notify::is-active",
                          G_CALLBACK(is_active_notify_cb), self,
                          G_CONNECT_SWAPPED);
  g_signal_connect_object(window, "notify::title", G_CALLBACK(title_notify_cb),
                          self, G_CONNECT_SWAPPED);
  g_signal_connect_object(window, "close-request", G_CALLBACK(close_request_cb),
                          self, G_CONNECT_SWAPPED);
#endif

  return self;
}

#if FLUTTER_LINUX_GTK4
G_MODULE_EXPORT FlPopoverMonitor* fl_popover_monitor_new(
    GtkPopover* popover,
    void (*on_closed)(void)) {
  g_return_val_if_fail(GTK_IS_POPOVER(popover), nullptr);

  FlPopoverMonitor* self = reinterpret_cast<FlPopoverMonitor*>(
      g_object_new(fl_popover_monitor_get_type(), nullptr));
  self->popover = GTK_POPOVER(g_object_ref(popover));
  if (Dart_CurrentIsolate() != nullptr) {
    self->isolate = flutter::Isolate::Current();
  }
  self->on_closed = on_closed;
  g_signal_connect_object(popover, "closed", G_CALLBACK(popover_closed_cb),
                          self, G_CONNECT_SWAPPED);
  return self;
}
#endif
