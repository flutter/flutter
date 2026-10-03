// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_view_private.h"

#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_gtk.h"
#include "flutter/shell/platform/linux/fl_key_event.h"
#include "flutter/shell/platform/linux/fl_keyboard_manager.h"
#include "flutter/shell/platform/linux/fl_pointer_manager.h"
#include "flutter/shell/platform/linux/fl_scrolling_manager.h"
#include "flutter/shell/platform/linux/fl_text_input_handler.h"
#include "flutter/shell/platform/linux/fl_touch_manager.h"
#include "flutter/shell/platform/linux/fl_view_gtk4_accessibility.h"

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
  fl_scrolling_manager_handle_rotation_update(view->scrolling_manager,
                                              rotation);
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

void fl_view_gtk4_update_accessible_name(FlView* view) {
  if (view->accessibility_backend != nullptr) {
    fl_view_gtk4_accessibility_update_accessible_name(
        view->accessibility_backend);
  }
}

void fl_view_gtk4_update_accessible_tree(FlView* view) {
  if (view->accessibility_backend != nullptr) {
    fl_view_gtk4_accessibility_update_accessible_tree(
        view->accessibility_backend);
  }
}

void fl_view_gtk4_set_cursor(FlView* view, const gchar* cursor_name) {
  FlGdkSurface* surface = fl_gtk_widget_get_surface(GTK_WIDGET(view));
  if (surface == nullptr) {
    return;
  }

  g_autoptr(GdkCursor) cursor = gdk_cursor_new_from_name(cursor_name, nullptr);
  fl_gtk_surface_set_cursor(surface, cursor);
}

static gboolean get_event_position(FlView* view,
                                   GdkEvent* event,
                                   gdouble* x,
                                   gdouble* y) {
  gdouble event_x = 0.0;
  gdouble event_y = 0.0;
  if (!gdk_event_get_position(event, &event_x, &event_y)) {
    return FALSE;
  }

  GtkWidget* render_area = GTK_WIDGET(view->render_area);
  GtkNative* native = gtk_widget_get_native(render_area);
  if (native == nullptr) {
    *x = event_x;
    *y = event_y;
    return TRUE;
  }

  gdouble native_x = 0.0;
  gdouble native_y = 0.0;
  gtk_native_get_surface_transform(native, &native_x, &native_y);

  graphene_point_t event_point = {
      static_cast<float>(event_x - native_x),
      static_cast<float>(event_y - native_y),
  };
  graphene_point_t point;
  if (!gtk_widget_compute_point(GTK_WIDGET(native), render_area, &event_point,
                                &point)) {
    return FALSE;
  }

  *x = point.x;
  *y = point.y;
  return TRUE;
}

static gboolean scroll_cb(GtkEventControllerScroll* controller,
                          gdouble delta_x,
                          gdouble delta_y,
                          FlView* view) {
  GdkEvent* event =
      gtk_event_controller_get_current_event(GTK_EVENT_CONTROLLER(controller));
  if (event == nullptr) {
    return FALSE;
  }

  gdouble x = 0.0, y = 0.0;
  gboolean position_valid = get_event_position(view, event, &x, &y);

  fl_scrolling_manager_handle_scroll_event(
      view->scrolling_manager, event, x, y, position_valid, delta_x, delta_y,
      gtk_widget_get_scale_factor(GTK_WIDGET(view)));
  return TRUE;
}

gboolean fl_view_gtk4_legacy_event_cb(FlView* view, GdkEvent* event) {
  GdkEventType event_type = gdk_event_get_event_type(event);
  gint scale_factor = gtk_widget_get_scale_factor(GTK_WIDGET(view));

  switch (event_type) {
    case GDK_BUTTON_PRESS:
    case GDK_BUTTON_RELEASE: {
      guint button = gdk_button_event_get_button(event);

      gdouble x = 0.0, y = 0.0;
      if (!get_event_position(view, event, &x, &y)) {
        return FALSE;
      }

      fl_scrolling_manager_set_last_mouse_position(
          view->scrolling_manager, x * scale_factor, y * scale_factor);
      fl_keyboard_manager_sync_modifier_if_needed(
          fl_engine_get_keyboard_manager(view->engine),
          gdk_event_get_modifier_state(event), gdk_event_get_time(event));

      if (event_type == GDK_BUTTON_PRESS) {
        return fl_pointer_manager_handle_button_press(
            view->pointer_manager, gdk_event_get_time(event),
            get_pointer_device_kind(event), x * scale_factor, y * scale_factor,
            button, 0.0, 0.0);
      }
      return fl_pointer_manager_handle_button_release(
          view->pointer_manager, gdk_event_get_time(event),
          get_pointer_device_kind(event), x * scale_factor, y * scale_factor,
          button, 0.0, 0.0);
    }
    case GDK_MOTION_NOTIFY: {
      fl_keyboard_manager_sync_modifier_if_needed(
          fl_engine_get_keyboard_manager(view->engine),
          gdk_event_get_modifier_state(event), gdk_event_get_time(event));
      gdouble x = 0.0, y = 0.0;
      if (!get_event_position(view, event, &x, &y)) {
        return FALSE;
      }
      return fl_pointer_manager_handle_motion(
          view->pointer_manager, gdk_event_get_time(event),
          get_pointer_device_kind(event), x * scale_factor, y * scale_factor,
          0.0, 0.0);
    }
    case GDK_ENTER_NOTIFY:
    case GDK_LEAVE_NOTIFY: {
      if (event_type == GDK_LEAVE_NOTIFY &&
          gdk_crossing_event_get_mode(event) != GDK_CROSSING_NORMAL) {
        return FALSE;
      }

      gdouble x = 0.0, y = 0.0;
      if (!get_event_position(view, event, &x, &y)) {
        return FALSE;
      }
      if (event_type == GDK_ENTER_NOTIFY) {
        return fl_pointer_manager_handle_enter(
            view->pointer_manager, gdk_event_get_time(event),
            get_pointer_device_kind(event), x * scale_factor, y * scale_factor,
            gdk_event_get_modifier_state(event), 0.0, 0.0);
      }
      return fl_pointer_manager_handle_leave(
          view->pointer_manager, gdk_event_get_time(event),
          get_pointer_device_kind(event), x * scale_factor, y * scale_factor,
          0.0, 0.0);
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

static gboolean handle_key_event(FlView* view, GdkEvent* event) {
  if (event == nullptr) {
    return FALSE;
  }

  g_autoptr(FlKeyEvent) key_event = fl_key_event_new_from_gdk_event(event);
  fl_keyboard_manager_handle_event(
      fl_engine_get_keyboard_manager(view->engine), key_event,
      view->cancellable,
      [](GObject* object, GAsyncResult* result, gpointer user_data) {
        FlView* view = FL_VIEW(user_data);
        g_autoptr(FlKeyEvent) redispatch_event = nullptr;
        g_autoptr(GError) error = nullptr;
        if (!fl_keyboard_manager_handle_event_finish(
                FL_KEYBOARD_MANAGER(object), result, &redispatch_event,
                &error)) {
          if (!g_error_matches(error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
            g_warning("Failed to handle key event: %s", error->message);
          }
          return;
        }

        FlTextInputHandler* handler =
            fl_engine_get_text_input_handler(view->engine);
        if (redispatch_event != nullptr &&
            fl_text_input_handler_get_widget(handler) == GTK_WIDGET(view)) {
          // GTK4 has no gdk_event_put equivalent. Do not record an event as
          // redispatched when it will never return through the event queue.
          fl_text_input_handler_filter_keypress(handler, redispatch_event);
        }
      },
      view);
  return TRUE;
}

static void focus_enter_cb(GtkEventControllerFocus* controller,
                           gpointer user_data) {
  FlView* view = FL_VIEW(user_data);
  fl_text_input_handler_set_widget(
      fl_engine_get_text_input_handler(view->engine), GTK_WIDGET(view));
}

static void focus_leave_cb(GtkEventControllerFocus* controller,
                           gpointer user_data) {
  FlView* view = FL_VIEW(user_data);
  FlTextInputHandler* handler = fl_engine_get_text_input_handler(view->engine);
  if (fl_text_input_handler_get_widget(handler) == GTK_WIDGET(view)) {
    fl_text_input_handler_set_widget(handler, nullptr);
  }
}

static gboolean key_pressed_cb(GtkEventControllerKey* controller,
                               guint keyval,
                               guint keycode,
                               GdkModifierType state,
                               gpointer user_data) {
  (void)keyval;
  (void)keycode;
  (void)state;
  return handle_key_event(
      FL_VIEW(user_data),
      gtk_event_controller_get_current_event(GTK_EVENT_CONTROLLER(controller)));
}

static void key_released_cb(GtkEventControllerKey* controller,
                            guint keyval,
                            guint keycode,
                            GdkModifierType state,
                            gpointer user_data) {
  (void)keyval;
  (void)keycode;
  (void)state;
  handle_key_event(FL_VIEW(user_data), gtk_event_controller_get_current_event(
                                           GTK_EVENT_CONTROLLER(controller)));
}

void fl_view_gtk4_setup(FlView* view) {
  gtk_box_append(GTK_BOX(view), GTK_WIDGET(view->render_area));

  GtkEventController* legacy = gtk_event_controller_legacy_new();
  g_signal_connect_swapped(legacy, "event",
                           G_CALLBACK(fl_view_gtk4_legacy_event_cb), view);
  gtk_widget_add_controller(GTK_WIDGET(view->render_area), legacy);

  GtkEventController* scroll =
      gtk_event_controller_scroll_new(GTK_EVENT_CONTROLLER_SCROLL_BOTH_AXES);
  gtk_event_controller_set_propagation_phase(scroll, GTK_PHASE_CAPTURE);
  g_signal_connect(scroll, "scroll", G_CALLBACK(scroll_cb), view);
  gtk_widget_add_controller(GTK_WIDGET(view->render_area), scroll);

  GtkEventController* key = gtk_event_controller_key_new();
  g_signal_connect(key, "key-pressed", G_CALLBACK(key_pressed_cb), view);
  g_signal_connect(key, "key-released", G_CALLBACK(key_released_cb), view);
  gtk_widget_add_controller(GTK_WIDGET(view), key);

  GtkEventController* focus = gtk_event_controller_focus_new();
  g_signal_connect(focus, "enter", G_CALLBACK(focus_enter_cb), view);
  g_signal_connect(focus, "leave", G_CALLBACK(focus_leave_cb), view);
  gtk_widget_add_controller(GTK_WIDGET(view), focus);

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
