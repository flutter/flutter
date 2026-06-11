// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_view_private.h"

#include "flutter/shell/platform/linux/fl_gtk.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_keyboard_manager.h"
#include "flutter/shell/platform/linux/fl_pointer_manager.h"
#include "flutter/shell/platform/linux/fl_scrolling_manager.h"
#include "flutter/shell/platform/linux/fl_touch_manager.h"

static FlutterPointerDeviceKind get_pointer_device_kind(GdkEvent* event) {
  GdkDevice* device = gdk_event_get_device(event);
  if (device == nullptr) {
    return kFlutterPointerDeviceKindMouse;
  }

  switch (gdk_device_get_source(device)) {
    case GDK_SOURCE_PEN:
    case GDK_SOURCE_TABLET_PAD:
      return kFlutterPointerDeviceKindStylus;
    case GDK_SOURCE_TOUCHSCREEN:
      return kFlutterPointerDeviceKindTouch;
    case GDK_SOURCE_TOUCHPAD:
    case GDK_SOURCE_TRACKPOINT:
    case GDK_SOURCE_KEYBOARD:
    case GDK_SOURCE_MOUSE:
      return kFlutterPointerDeviceKindMouse;
  }

  return kFlutterPointerDeviceKindMouse;
}

static void gesture_rotation_begin_cb(FlView* view) {
  fl_scrolling_manager_handle_rotation_begin(view->scrolling_manager);
}

static void gesture_rotation_update_cb(FlView* view,
                                       gdouble rotation,
                                       gdouble delta) {
  fl_scrolling_manager_handle_rotation_update(view->scrolling_manager, rotation);
}

static void gesture_rotation_end_cb(FlView* view) {
  fl_scrolling_manager_handle_rotation_end(view->scrolling_manager);
}

static void gesture_zoom_begin_cb(FlView* view) {
  fl_scrolling_manager_handle_zoom_begin(view->scrolling_manager);
}

static void gesture_zoom_update_cb(FlView* view, gdouble scale) {
  fl_scrolling_manager_handle_zoom_update(view->scrolling_manager, scale);
}

static void gesture_zoom_end_cb(FlView* view) {
  fl_scrolling_manager_handle_zoom_end(view->scrolling_manager);
}

GtkWidget* fl_view_gtk4_get_toplevel_window(FlView* view) {
  GtkWidget* toplevel_window =
      GTK_WIDGET(gtk_widget_get_root(GTK_WIDGET(view)));
  return GTK_IS_WINDOW(toplevel_window) ? toplevel_window : nullptr;
}

void fl_view_gtk4_set_cursor(FlView* view, const gchar* cursor_name) {
  FlGdkSurface* surface = fl_gtk_widget_get_surface(GTK_WIDGET(view));
  if (surface == nullptr) {
    return;
  }

  g_autoptr(GdkCursor) cursor = gdk_cursor_new_from_name(cursor_name, nullptr);
  fl_gtk_surface_set_cursor(surface, cursor);
}

gboolean fl_view_gtk4_legacy_event_cb(FlView* view, GdkEvent* event) {
  GdkEventType event_type = gdk_event_get_event_type(event);
  gint scale_factor = gtk_widget_get_scale_factor(GTK_WIDGET(view));

  switch (event_type) {
    case GDK_BUTTON_PRESS:
    case GDK_BUTTON_RELEASE: {
      guint button = gdk_button_event_get_button(event);

      gdouble x = 0.0, y = 0.0;
      gdk_event_get_position(event, &x, &y);

      fl_scrolling_manager_set_last_mouse_position(view->scrolling_manager,
                                                   x * scale_factor,
                                                   y * scale_factor);
      fl_keyboard_manager_sync_modifier_if_needed(
          fl_engine_get_keyboard_manager(view->engine),
          gdk_event_get_modifier_state(event), gdk_event_get_time(event));

      if (event_type == GDK_BUTTON_PRESS) {
        return fl_pointer_manager_handle_button_press(
            view->pointer_manager, gdk_event_get_time(event),
            get_pointer_device_kind(event), x * scale_factor, y * scale_factor,
            button);
      }
      return fl_pointer_manager_handle_button_release(
          view->pointer_manager, gdk_event_get_time(event),
          get_pointer_device_kind(event), x * scale_factor, y * scale_factor,
          button);
    }
    case GDK_SCROLL:
      fl_scrolling_manager_handle_scroll_event(view->scrolling_manager, event,
                                               scale_factor);
      return TRUE;
    case GDK_MOTION_NOTIFY: {
      fl_keyboard_manager_sync_modifier_if_needed(
          fl_engine_get_keyboard_manager(view->engine),
          gdk_event_get_modifier_state(event), gdk_event_get_time(event));
      gdouble x = 0.0, y = 0.0;
      gdk_event_get_position(event, &x, &y);
      return fl_pointer_manager_handle_motion(
          view->pointer_manager, gdk_event_get_time(event),
          get_pointer_device_kind(event), x * scale_factor, y * scale_factor);
    }
    case GDK_ENTER_NOTIFY:
    case GDK_LEAVE_NOTIFY: {
      if (event_type == GDK_LEAVE_NOTIFY &&
          gdk_crossing_event_get_mode(event) != GDK_CROSSING_NORMAL) {
        return FALSE;
      }

      gdouble x = 0.0, y = 0.0;
      gdk_event_get_position(event, &x, &y);
      if (event_type == GDK_ENTER_NOTIFY) {
        return fl_pointer_manager_handle_enter(
            view->pointer_manager, gdk_event_get_time(event),
            get_pointer_device_kind(event), x * scale_factor, y * scale_factor);
      }
      return fl_pointer_manager_handle_leave(
          view->pointer_manager, gdk_event_get_time(event),
          get_pointer_device_kind(event), x * scale_factor, y * scale_factor);
    }
    case GDK_TOUCH_BEGIN:
    case GDK_TOUCH_UPDATE:
    case GDK_TOUCH_END:
    case GDK_TOUCH_CANCEL:
      fl_touch_manager_handle_touch_event(view->touch_manager, event,
                                          scale_factor);
      return TRUE;
    default:
      return FALSE;
  }
}

void fl_view_gtk4_setup(FlView* view) {
  gtk_box_append(GTK_BOX(view), GTK_WIDGET(view->render_area));

  GtkEventController* legacy = gtk_event_controller_legacy_new();
  g_signal_connect_swapped(legacy, "event",
                           G_CALLBACK(fl_view_gtk4_legacy_event_cb), view);
  gtk_widget_add_controller(GTK_WIDGET(view->render_area), legacy);

  view->zoom_gesture = gtk_gesture_zoom_new();
  g_signal_connect_swapped(view->zoom_gesture, "begin",
                           G_CALLBACK(gesture_zoom_begin_cb), view);
  g_signal_connect_swapped(view->zoom_gesture, "scale-changed",
                           G_CALLBACK(gesture_zoom_update_cb), view);
  g_signal_connect_swapped(view->zoom_gesture, "end",
                           G_CALLBACK(gesture_zoom_end_cb), view);
  gtk_widget_add_controller(GTK_WIDGET(view->render_area),
                            GTK_EVENT_CONTROLLER(view->zoom_gesture));

  view->rotate_gesture = gtk_gesture_rotate_new();
  g_signal_connect_swapped(view->rotate_gesture, "begin",
                           G_CALLBACK(gesture_rotation_begin_cb), view);
  g_signal_connect_swapped(view->rotate_gesture, "angle-changed",
                           G_CALLBACK(gesture_rotation_update_cb), view);
  g_signal_connect_swapped(view->rotate_gesture, "end",
                           G_CALLBACK(gesture_rotation_end_cb), view);
  gtk_widget_add_controller(GTK_WIDGET(view->render_area),
                            GTK_EVENT_CONTROLLER(view->rotate_gesture));
}
