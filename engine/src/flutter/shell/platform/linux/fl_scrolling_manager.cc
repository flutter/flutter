// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_scrolling_manager.h"

static constexpr int kMicrosecondsPerMillisecond = 1000;

struct _FlScrollingManager {
  GObject parent_instance;

  FlScrollingViewDelegate* view_delegate;

  gdouble last_x;
  gdouble last_y;

  gboolean pan_started;
  gdouble pan_x;
  gdouble pan_y;

  gboolean zoom_started;
  gboolean rotate_started;
  gdouble scale;
  gdouble rotation;
};

G_DEFINE_TYPE(FlScrollingManager, fl_scrolling_manager, G_TYPE_OBJECT);

static void fl_scrolling_manager_dispose(GObject* object);

static void fl_scrolling_manager_class_init(FlScrollingManagerClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_scrolling_manager_dispose;
}

static void fl_scrolling_manager_init(FlScrollingManager* self) {}

static void fl_scrolling_manager_dispose(GObject* object) {
  G_OBJECT_CLASS(fl_scrolling_manager_parent_class)->dispose(object);
}

FlScrollingManager* fl_scrolling_manager_new(
    FlScrollingViewDelegate* view_delegate) {
  g_return_val_if_fail(FL_IS_SCROLLING_VIEW_DELEGATE(view_delegate), nullptr);

  FlScrollingManager* self = FL_SCROLLING_MANAGER(
      g_object_new(fl_scrolling_manager_get_type(), nullptr));

  self->view_delegate = view_delegate;
  g_object_add_weak_pointer(
      G_OBJECT(view_delegate),
      reinterpret_cast<gpointer*>(&(self->view_delegate)));

  self->pan_started = false;
  self->zoom_started = false;
  self->rotate_started = false;

  return self;
}

void fl_scrolling_manager_set_last_mouse_position(FlScrollingManager* self,
                                                  gdouble x,
                                                  gdouble y) {
  self->last_x = x;
  self->last_y = y;
}

void fl_scrolling_manager_handle_scroll_event(FlScrollingManager* self,
                                              GdkEventScroll* event,
                                              gint scale_factor) {
  gdouble scroll_delta_x = 0.0, scroll_delta_y = 0.0;
  if (event->direction == GDK_SCROLL_SMOOTH) {
    scroll_delta_x = event->delta_x;
    scroll_delta_y = event->delta_y;
  } else if (event->direction == GDK_SCROLL_UP) {
    scroll_delta_y = -1;
  } else if (event->direction == GDK_SCROLL_DOWN) {
    scroll_delta_y = 1;
  } else if (event->direction == GDK_SCROLL_LEFT) {
    scroll_delta_x = -1;
  } else if (event->direction == GDK_SCROLL_RIGHT) {
    scroll_delta_x = 1;
  }

  // The multiplier is taken from the Chromium source
  // (ui/events/x/events_x_utils.cc).
  const int kScrollOffsetMultiplier = 53;
  scroll_delta_x *= kScrollOffsetMultiplier * scale_factor;
  scroll_delta_y *= kScrollOffsetMultiplier * scale_factor;

  if (gdk_device_get_source(gdk_event_get_source_device((GdkEvent*)event)) ==
      GDK_SOURCE_TOUCHPAD) {
    scroll_delta_x *= -1;
    scroll_delta_y *= -1;
    if (event->is_stop) {
      fl_scrolling_view_delegate_send_pointer_pan_zoom_event(
          self->view_delegate, event->time * kMicrosecondsPerMillisecond,
          event->x * scale_factor, event->y * scale_factor, kPanZoomEnd,
          self->pan_x, self->pan_y, 0, 0);
      self->pan_started = FALSE;
    } else {
      if (!self->pan_started) {
        self->pan_x = 0;
        self->pan_y = 0;
        fl_scrolling_view_delegate_send_pointer_pan_zoom_event(
            self->view_delegate, event->time * kMicrosecondsPerMillisecond,
            event->x * scale_factor, event->y * scale_factor, kPanZoomStart, 0,
            0, 0, 0);
        self->pan_started = TRUE;
      }
      self->pan_x += scroll_delta_x;
      self->pan_y += scroll_delta_y;
      fl_scrolling_view_delegate_send_pointer_pan_zoom_event(
          self->view_delegate, event->time * kMicrosecondsPerMillisecond,
          event->x * scale_factor, event->y * scale_factor, kPanZoomUpdate,
          self->pan_x, self->pan_y, 1, 0);
    }
  } else {
    self->last_x = event->x * scale_factor;
    self->last_y = event->y * scale_factor;
    fl_scrolling_view_delegate_send_mouse_pointer_event(
        self->view_delegate,
        FlutterPointerPhase::kMove /* arbitrary value, phase will be ignored as
                                      this is a discrete scroll event */
        ,
        event->time * kMicrosecondsPerMillisecond, event->x * scale_factor,
        event->y * scale_factor, scroll_delta_x, scroll_delta_y, 0);
  }
}

void fl_scrolling_manager_handle_rotation_begin(FlScrollingManager* self) {
  self->rotate_started = true;
  if (!self->zoom_started) {
    self->scale = 1;
    self->rotation = 0;
    fl_scrolling_view_delegate_send_pointer_pan_zoom_event(
        self->view_delegate, g_get_real_time(), self->last_x, self->last_y,
        kPanZoomStart, 0, 0, 0, 0);
  }
}

void fl_scrolling_manager_handle_rotation_update(FlScrollingManager* self,
                                                 gdouble rotation) {
  self->rotation = rotation;
  fl_scrolling_view_delegate_send_pointer_pan_zoom_event(
      self->view_delegate, g_get_real_time(), self->last_x, self->last_y,
      kPanZoomUpdate, 0, 0, self->scale, self->rotation);
}
void fl_scrolling_manager_handle_rotation_end(FlScrollingManager* self) {
  self->rotate_started = false;
  if (!self->zoom_started) {
    fl_scrolling_view_delegate_send_pointer_pan_zoom_event(
        self->view_delegate, g_get_real_time(), self->last_x, self->last_y,
        kPanZoomEnd, 0, 0, 0, 0);
  }
}

void fl_scrolling_manager_handle_zoom_begin(FlScrollingManager* self) {
  self->zoom_started = true;
  if (!self->rotate_started) {
    self->scale = 1;
    self->rotation = 0;
    fl_scrolling_view_delegate_send_pointer_pan_zoom_event(
        self->view_delegate, g_get_real_time(), self->last_x, self->last_y,
        kPanZoomStart, 0, 0, 0, 0);
  }
}
void fl_scrolling_manager_handle_zoom_update(FlScrollingManager* self,
                                             gdouble scale) {
  self->scale = scale;
  fl_scrolling_view_delegate_send_pointer_pan_zoom_event(
      self->view_delegate, g_get_real_time(), self->last_x, self->last_y,
      kPanZoomUpdate, 0, 0, self->scale, self->rotation);
}
void fl_scrolling_manager_handle_zoom_end(FlScrollingManager* self) {
  self->zoom_started = false;
  if (!self->rotate_started) {
    fl_scrolling_view_delegate_send_pointer_pan_zoom_event(
        self->view_delegate, g_get_real_time(), self->last_x, self->last_y,
        kPanZoomEnd, 0, 0, 0, 0);
  }
}
