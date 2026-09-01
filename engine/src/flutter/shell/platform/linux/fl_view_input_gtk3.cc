// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_view_private.h"

#include "flutter/shell/platform/linux/fl_engine_private.h"

static FlutterPointerDeviceKind get_pointer_device_kind(GdkEvent* event) {
  GdkDevice* device = gdk_event_get_source_device(event);
  if (device == nullptr) {
    return kFlutterPointerDeviceKindMouse;
  }

  GdkInputSource source = gdk_device_get_source(device);
  switch (source) {
    case GDK_SOURCE_PEN:
    case GDK_SOURCE_CURSOR:
    case GDK_SOURCE_TABLET_PAD:
      return kFlutterPointerDeviceKindStylus;
    case GDK_SOURCE_ERASER:
      return kFlutterPointerDeviceKindInvertedStylus;
    case GDK_SOURCE_TOUCHSCREEN:
      return kFlutterPointerDeviceKindTouch;
    case GDK_SOURCE_TOUCHPAD:  // trackpad device type is reserved for gestures
    case GDK_SOURCE_TRACKPOINT:
    case GDK_SOURCE_KEYBOARD:
    case GDK_SOURCE_MOUSE:
      return kFlutterPointerDeviceKindMouse;
  }
}

// Gets the pointer state for a GDK event.
static void get_pointer_device_state(GdkEvent* event,
                                     gdouble* rotation,
                                     gdouble* pressure) {
  *rotation = 0.0;
  *pressure = 0.0;
  if (event == nullptr) {
    return;
  }

  gdouble pressure_value = 0.0;
  gdouble rotation_value = 0.0;
  gdk_event_get_axis(event, GDK_AXIS_PRESSURE, &pressure_value);
  gdk_event_get_axis(event, GDK_AXIS_ROTATION, &rotation_value);
  *pressure = pressure_value;
  *rotation = rotation_value;
}

static void sync_modifier_if_needed(FlView* self, GdkEvent* event) {
  guint event_time = gdk_event_get_time(event);
  GdkModifierType event_state = static_cast<GdkModifierType>(0);
  gdk_event_get_state(event, &event_state);
  fl_keyboard_manager_sync_modifier_if_needed(
      fl_engine_get_keyboard_manager(self->engine), event_state, event_time);
}

static void set_scrolling_position(FlView* self, gdouble x, gdouble y) {
  gint scale_factor = gtk_widget_get_scale_factor(GTK_WIDGET(self));
  fl_scrolling_manager_set_last_mouse_position(
      self->scrolling_manager, x * scale_factor, y * scale_factor);
}

// Signal handler for GtkWidget::button-press-event
static gboolean button_press_event_cb(FlView* self,
                                      GdkEventButton* button_event) {
  GdkEvent* event = reinterpret_cast<GdkEvent*>(button_event);

  // Flutter doesn't handle double and triple click events.
  GdkEventType event_type = gdk_event_get_event_type(event);
  if (event_type == GDK_DOUBLE_BUTTON_PRESS ||
      event_type == GDK_TRIPLE_BUTTON_PRESS) {
    return FALSE;
  }

  guint button = 0;
  gdk_event_get_button(event, &button);

  gdouble x = 0.0, y = 0.0;
  gdk_event_get_coords(event, &x, &y);

  set_scrolling_position(self, x, y);
  sync_modifier_if_needed(self, event);

  gint scale_factor = gtk_widget_get_scale_factor(GTK_WIDGET(self));
  gdouble rotation = 0.0;
  gdouble pressure = 0.0;
  get_pointer_device_state(event, &rotation, &pressure);
  return fl_pointer_manager_handle_button_press(
      self->pointer_manager, gdk_event_get_time(event),
      get_pointer_device_kind(event), x * scale_factor, y * scale_factor,
      button, rotation, pressure);
}

// Signal handler for GtkWidget::button-release-event
static gboolean button_release_event_cb(FlView* self,
                                        GdkEventButton* button_event) {
  GdkEvent* event = reinterpret_cast<GdkEvent*>(button_event);

  guint button = 0;
  gdk_event_get_button(event, &button);

  gdouble x = 0.0, y = 0.0;
  gdk_event_get_coords(event, &x, &y);

  set_scrolling_position(self, x, y);
  sync_modifier_if_needed(self, event);

  gint scale_factor = gtk_widget_get_scale_factor(GTK_WIDGET(self));
  gdouble rotation = 0.0;
  gdouble pressure = 0.0;
  get_pointer_device_state(event, &rotation, &pressure);
  return fl_pointer_manager_handle_button_release(
      self->pointer_manager, gdk_event_get_time(event),
      get_pointer_device_kind(event), x * scale_factor, y * scale_factor,
      button, rotation, pressure);
}

// Signal handler for GtkWidget::scroll-event
static gboolean scroll_event_cb(FlView* self, GdkEventScroll* event) {
  GdkEvent* gdk_event = reinterpret_cast<GdkEvent*>(event);
  gdouble x = 0.0, y = 0.0;
  gdk_event_get_coords(gdk_event, &x, &y);

  gdouble delta_x = 0.0, delta_y = 0.0;
  GdkScrollDirection direction;
  if (gdk_event_get_scroll_direction(gdk_event, &direction)) {
    switch (direction) {
      case GDK_SCROLL_UP:
        delta_y = -1.0;
        break;
      case GDK_SCROLL_DOWN:
        delta_y = 1.0;
        break;
      case GDK_SCROLL_LEFT:
        delta_x = -1.0;
        break;
      case GDK_SCROLL_RIGHT:
        delta_x = 1.0;
        break;
      case GDK_SCROLL_SMOOTH:
        break;
    }
  } else {
    gdk_event_get_scroll_deltas(gdk_event, &delta_x, &delta_y);
  }

  fl_scrolling_manager_handle_scroll_event(
      self->scrolling_manager, event, x, y, TRUE, delta_x, delta_y,
      gtk_widget_get_scale_factor(GTK_WIDGET(self)));
  return TRUE;
}

static gboolean touch_event_cb(FlView* self, GdkEventTouch* event) {
  fl_touch_manager_handle_touch_event(
      self->touch_manager, event,
      gtk_widget_get_scale_factor(GTK_WIDGET(self)));
  return TRUE;
}

// Signal handler for GtkWidget::motion-notify-event
static gboolean motion_notify_event_cb(FlView* self,
                                       GdkEventMotion* motion_event) {
  GdkEvent* event = reinterpret_cast<GdkEvent*>(motion_event);
  sync_modifier_if_needed(self, event);

  // return if touch event
  auto event_type = gdk_event_get_event_type(event);
  if (event_type == GDK_TOUCH_BEGIN || event_type == GDK_TOUCH_UPDATE ||
      event_type == GDK_TOUCH_END || event_type == GDK_TOUCH_CANCEL) {
    return FALSE;
  }

  gdouble x = 0.0, y = 0.0;
  gdk_event_get_coords(event, &x, &y);
  gint scale_factor = gtk_widget_get_scale_factor(GTK_WIDGET(self));
  gdouble rotation = 0.0;
  gdouble pressure = 0.0;
  get_pointer_device_state(event, &rotation, &pressure);
  return fl_pointer_manager_handle_motion(
      self->pointer_manager, gdk_event_get_time(event),
      get_pointer_device_kind(event), x * scale_factor, y * scale_factor,
      rotation, pressure);
}

// Signal handler for GtkWidget::enter-notify-event
static gboolean enter_notify_event_cb(FlView* self,
                                      GdkEventCrossing* crossing_event) {
  GdkEvent* event = reinterpret_cast<GdkEvent*>(crossing_event);
  gdouble x = 0.0, y = 0.0;
  gdk_event_get_coords(event, &x, &y);
  gint scale_factor = gtk_widget_get_scale_factor(GTK_WIDGET(self));
  gdouble rotation = 0.0;
  gdouble pressure = 0.0;
  get_pointer_device_state(event, &rotation, &pressure);
  return fl_pointer_manager_handle_enter(
      self->pointer_manager, gdk_event_get_time(event),
      get_pointer_device_kind(event), x * scale_factor, y * scale_factor,
      rotation, pressure);
}

// Signal handler for GtkWidget::leave-notify-event
static gboolean leave_notify_event_cb(FlView* self,
                                      GdkEventCrossing* crossing_event) {
  if (crossing_event->mode != GDK_CROSSING_NORMAL) {
    return FALSE;
  }

  GdkEvent* event = reinterpret_cast<GdkEvent*>(crossing_event);
  gdouble x = 0.0, y = 0.0;
  gdk_event_get_coords(event, &x, &y);
  gint scale_factor = gtk_widget_get_scale_factor(GTK_WIDGET(self));
  gdouble rotation = 0.0;
  gdouble pressure = 0.0;
  get_pointer_device_state(event, &rotation, &pressure);
  return fl_pointer_manager_handle_leave(
      self->pointer_manager, gdk_event_get_time(event),
      get_pointer_device_kind(event), x * scale_factor, y * scale_factor,
      rotation, pressure);
}

static void gesture_rotation_begin_cb(FlView* self) {
  fl_scrolling_manager_handle_rotation_begin(self->scrolling_manager);
}

static void gesture_rotation_update_cb(FlView* self,
                                       gdouble rotation,
                                       gdouble delta) {
  fl_scrolling_manager_handle_rotation_update(self->scrolling_manager,
                                              rotation);
}

static void gesture_rotation_end_cb(FlView* self) {
  fl_scrolling_manager_handle_rotation_end(self->scrolling_manager);
}

static void gesture_zoom_begin_cb(FlView* self) {
  fl_scrolling_manager_handle_zoom_begin(self->scrolling_manager);
}

static void gesture_zoom_update_cb(FlView* self, gdouble scale) {
  fl_scrolling_manager_handle_zoom_update(self->scrolling_manager, scale);
}

static void gesture_zoom_end_cb(FlView* self) {
  fl_scrolling_manager_handle_zoom_end(self->scrolling_manager);
}

void fl_view_input_gtk3_setup(FlView* self) {
  self->event_box = gtk_event_box_new();
  gtk_widget_set_hexpand(self->event_box, TRUE);
  gtk_widget_set_vexpand(self->event_box, TRUE);
  gtk_container_add(GTK_CONTAINER(self), self->event_box);
  gtk_widget_show(self->event_box);
  gtk_widget_add_events(self->event_box,
                        GDK_POINTER_MOTION_MASK | GDK_BUTTON_PRESS_MASK |
                            GDK_BUTTON_RELEASE_MASK | GDK_SCROLL_MASK |
                            GDK_SMOOTH_SCROLL_MASK | GDK_TOUCH_MASK);

  g_signal_connect_swapped(self->event_box, "button-press-event",
                           G_CALLBACK(button_press_event_cb), self);
  g_signal_connect_swapped(self->event_box, "button-release-event",
                           G_CALLBACK(button_release_event_cb), self);
  g_signal_connect_swapped(self->event_box, "scroll-event",
                           G_CALLBACK(scroll_event_cb), self);
  g_signal_connect_swapped(self->event_box, "motion-notify-event",
                           G_CALLBACK(motion_notify_event_cb), self);
  g_signal_connect_swapped(self->event_box, "enter-notify-event",
                           G_CALLBACK(enter_notify_event_cb), self);
  g_signal_connect_swapped(self->event_box, "leave-notify-event",
                           G_CALLBACK(leave_notify_event_cb), self);
  self->zoom_gesture = gtk_gesture_zoom_new(self->event_box);
  g_signal_connect_swapped(self->zoom_gesture, "begin",
                           G_CALLBACK(gesture_zoom_begin_cb), self);
  g_signal_connect_swapped(self->zoom_gesture, "scale-changed",
                           G_CALLBACK(gesture_zoom_update_cb), self);
  g_signal_connect_swapped(self->zoom_gesture, "end",
                           G_CALLBACK(gesture_zoom_end_cb), self);
  self->rotate_gesture = gtk_gesture_rotate_new(self->event_box);
  g_signal_connect_swapped(self->rotate_gesture, "begin",
                           G_CALLBACK(gesture_rotation_begin_cb), self);
  g_signal_connect_swapped(self->rotate_gesture, "angle-changed",
                           G_CALLBACK(gesture_rotation_update_cb), self);
  g_signal_connect_swapped(self->rotate_gesture, "end",
                           G_CALLBACK(gesture_rotation_end_cb), self);
  g_signal_connect_swapped(self->event_box, "touch-event",
                           G_CALLBACK(touch_event_cb), self);
}
