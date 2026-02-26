// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"

#if !FLUTTER_LINUX_GTK4
#include <atk/atk.h>
#endif
#if FLUTTER_LINUX_GTK4
#include <gdk/wayland/gdkwayland.h>
#else
#include <gdk/gdkwayland.h>
#endif
#if !FLUTTER_LINUX_GTK4
#include <gtk/gtk-a11y.h>
#endif

#include <cstring>

#include "flutter/common/constants.h"
#if !FLUTTER_LINUX_GTK4
#include "flutter/shell/platform/linux/fl_accessible_node.h"
#endif
#include "flutter/shell/platform/linux/fl_compositor_opengl.h"
#include "flutter/shell/platform/linux/fl_compositor_software.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_gtk.h"
#include "flutter/shell/platform/linux/fl_key_event.h"
#include "flutter/shell/platform/linux/fl_opengl_manager.h"
#include "flutter/shell/platform/linux/fl_plugin_registrar_private.h"
#include "flutter/shell/platform/linux/fl_pointer_manager.h"
#include "flutter/shell/platform/linux/fl_scrolling_manager.h"
#if !FLUTTER_LINUX_GTK4
#include "flutter/shell/platform/linux/fl_socket_accessible.h"
#endif
#include "flutter/shell/platform/linux/fl_touch_manager.h"
#if !FLUTTER_LINUX_GTK4
#include "flutter/shell/platform/linux/fl_view_accessible.h"
#endif
#include "flutter/shell/platform/linux/fl_view_private.h"
#include "flutter/shell/platform/linux/fl_window_state_monitor.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_engine.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_plugin_registry.h"

struct _FlView {
  GtkBox parent_instance;

  // Event box the render area goes inside.
  GtkWidget* event_box;

  // The widget rendering the Flutter view.
  GtkDrawingArea* render_area;

  // Rendering context when using OpenGL.
  GdkGLContext* render_context;

  // Engine this view is showing.
  FlEngine* engine;

  // Combines layers into frame.
  FlCompositor* compositor;

  // Signal subscription for engine restart signal.
  guint on_pre_engine_restart_cb_id;

  // Signal subscription for updating semantics signal.
  guint update_semantics_cb_id;

  // ID for this view.
  FlutterViewId view_id;

  // Background color.
  GdkRGBA* background_color;

  // TRUE if have got the first frame to render.
  gboolean have_first_frame;

  // Monitor to track window state.
  FlWindowStateMonitor* window_state_monitor;

  // Manages scrolling events.
  FlScrollingManager* scrolling_manager;

  // Manages pointer events.
  FlPointerManager* pointer_manager;

  // Manages touch events.
  FlTouchManager* touch_manager;

#if !FLUTTER_LINUX_GTK4
  // Accessible tree from Flutter, exposed as an AtkPlug.
  FlViewAccessible* view_accessible;
#endif

  // Signal subscripton for cursor changes.
  guint cursor_changed_cb_id;

  GCancellable* cancellable;

#if FLUTTER_LINUX_GTK4
  GtkEventControllerMotion* motion_controller;
  GtkGestureClick* click_gesture;
  GtkEventControllerScroll* scroll_controller;
  GtkEventControllerKey* key_controller;
  GtkGestureZoom* zoom_gesture;
  GtkGestureRotate* rotate_gesture;
#endif
};

enum { SIGNAL_FIRST_FRAME, LAST_SIGNAL };

static guint fl_view_signals[LAST_SIGNAL];

static void fl_renderable_iface_init(FlRenderableInterface* iface);

static void fl_view_plugin_registry_iface_init(
    FlPluginRegistryInterface* iface);

static void log_once(bool* flag, const char* message) {
  if (*flag) {
    return;
  }
  *flag = true;
  g_warning("%s", message);
}

G_DEFINE_TYPE_WITH_CODE(
    FlView,
    fl_view,
    GTK_TYPE_BOX,
    G_IMPLEMENT_INTERFACE(fl_renderable_get_type(), fl_renderable_iface_init)
        G_IMPLEMENT_INTERFACE(fl_plugin_registry_get_type(),
                              fl_view_plugin_registry_iface_init))

// Redraw the view from the GTK thread.
static gboolean redraw_cb(gpointer user_data) {
  FlView* self = FL_VIEW(user_data);

  gtk_widget_queue_draw(GTK_WIDGET(self->render_area));

  if (!self->have_first_frame) {
    self->have_first_frame = TRUE;
    g_signal_emit(self, fl_view_signals[SIGNAL_FIRST_FRAME], 0);
  }

  return FALSE;
}

static GtkWidget* fl_view_get_toplevel_widget(FlView* self) {
#if FLUTTER_LINUX_GTK4
  GtkRoot* root = gtk_widget_get_root(GTK_WIDGET(self));
  return root != nullptr ? GTK_WIDGET(root) : nullptr;
#else
  return gtk_widget_get_toplevel(GTK_WIDGET(self));
#endif
}

static FlGdkSurface* fl_view_get_toplevel_surface(FlView* self) {
  GtkWidget* toplevel = fl_view_get_toplevel_widget(self);
  return toplevel != nullptr ? fl_gtk_widget_get_surface(toplevel) : nullptr;
}

// Signal handler for GtkWidget::delete-event (GTK3 only)
#if !FLUTTER_LINUX_GTK4
static gboolean window_delete_event_cb(FlView* self) {
  fl_engine_request_app_exit(self->engine);
  // Stop the event from propagating.
  return TRUE;
}
#endif

#if FLUTTER_LINUX_GTK4
// Signal handler for GtkWindow::close-request.
static gboolean window_close_request_cb(GtkWindow* window, FlView* self) {
  (void)window;
  fl_engine_request_app_exit(self->engine);
  // Allow the default handler to destroy the window if the engine doesn't.
  return FALSE;
}
#endif

static void init_scrolling(FlView* self) {
  g_clear_object(&self->scrolling_manager);
  self->scrolling_manager =
      fl_scrolling_manager_new(self->engine, self->view_id);
}

static void init_touch(FlView* self) {
  g_clear_object(&self->touch_manager);
  self->touch_manager = fl_touch_manager_new(self->engine, self->view_id);
}

static FlutterPointerDeviceKind get_device_kind(GdkEvent* event) {
#if FLUTTER_LINUX_GTK4
  GdkDevice* device = gdk_event_get_device(event);
#else
  GdkDevice* device = gdk_event_get_source_device(event);
#endif
  GdkInputSource source = gdk_device_get_source(device);
#if FLUTTER_LINUX_GTK4
  switch (source) {
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
#else
  switch (source) {
    case GDK_SOURCE_PEN:
    case GDK_SOURCE_ERASER:
    case GDK_SOURCE_CURSOR:
    case GDK_SOURCE_TABLET_PAD:
      return kFlutterPointerDeviceKindStylus;
    case GDK_SOURCE_TOUCHSCREEN:
      return kFlutterPointerDeviceKindTouch;
    case GDK_SOURCE_TOUCHPAD:  // trackpad device type is reserved for gestures
    case GDK_SOURCE_TRACKPOINT:
    case GDK_SOURCE_KEYBOARD:
    case GDK_SOURCE_MOUSE:
      return kFlutterPointerDeviceKindMouse;
  }
#endif
  return kFlutterPointerDeviceKindMouse;
}

// Called when the mouse cursor changes.
static void cursor_changed_cb(FlView* self) {
  FlMouseCursorHandler* handler =
      fl_engine_get_mouse_cursor_handler(self->engine);
  const gchar* cursor_name = fl_mouse_cursor_handler_get_cursor_name(handler);
  FlGdkSurface* surface = fl_view_get_toplevel_surface(self);
  if (surface == nullptr) {
    return;
  }
#if FLUTTER_LINUX_GTK4
  g_autoptr(GdkCursor) cursor = gdk_cursor_new_from_name(cursor_name, nullptr);
#else
  g_autoptr(GdkCursor) cursor = gdk_cursor_new_from_name(
      fl_gtk_surface_get_display(surface), cursor_name);
#endif
  fl_gtk_surface_set_cursor(surface, cursor);
}

// Set the mouse cursor.
static void setup_cursor(FlView* self) {
  FlMouseCursorHandler* handler =
      fl_engine_get_mouse_cursor_handler(self->engine);

  self->cursor_changed_cb_id = g_signal_connect_swapped(
      handler, "cursor-changed", G_CALLBACK(cursor_changed_cb), self);
  cursor_changed_cb(self);
}

// Updates the engine with the current window metrics.
static void handle_geometry_changed_with_size(FlView* self,
                                              int width,
                                              int height) {
  gint scale_factor = gtk_widget_get_scale_factor(GTK_WIDGET(self));

  if (width == 0 || height == 0) {
    // Try to fall back to the toplevel surface size if available.
    FlGdkSurface* surface = fl_view_get_toplevel_surface(self);
    if (surface != nullptr) {
      width = fl_gtk_surface_get_width(surface);
      height = fl_gtk_surface_get_height(surface);
    }
    if (width == 0 || height == 0) {
      static bool logged_zero_allocation = false;
      log_once(&logged_zero_allocation,
               "handle_geometry_changed: zero-size allocation");
      return;
    }
  }

  // Note we can't detect if a window is moved between monitors - this
  // information is provided by Wayland but GTK only notifies us if the scale
  // has changed, so moving between two monitors of the same scale doesn't
  // provide any information.

  FlGdkSurface* surface = fl_view_get_toplevel_surface(self);
  // NOTE(robert-ancell) If we haven't got a window we default to display 0.
  // This is probably indicating a problem with this code in that we
  // shouldn't be generating anything until the window is created.
  // Another event with the correct display ID is generated soon after.
  // I haven't changed this code in case there are side-effects but we
  // probably shouldn't call handle_geometry_changed after the view is
  // added but only when the window is realized.
  FlutterEngineDisplayId display_id = 0;
  if (surface != nullptr) {
    GdkMonitor* monitor = fl_gtk_display_get_monitor_at_surface(
        fl_gtk_surface_get_display(surface), surface);
    display_id = fl_display_monitor_get_display_id(
        fl_engine_get_display_monitor(self->engine), monitor);
  }
  fl_engine_send_window_metrics_event(self->engine, display_id, self->view_id,
                                      width * scale_factor,
                                      height * scale_factor, scale_factor);

  {
    static bool logged_metrics = false;
    if (!logged_metrics) {
      logged_metrics = true;
      g_warning("handle_geometry_changed: metrics %d x %d (scale %d)", width,
                height, scale_factor);
    }
  }
}

static void handle_geometry_changed(FlView* self) {
#if FLUTTER_LINUX_GTK4
  int width = gtk_widget_get_width(GTK_WIDGET(self->render_area));
  int height = gtk_widget_get_height(GTK_WIDGET(self->render_area));
  handle_geometry_changed_with_size(self, width, height);
#else
  GtkAllocation allocation;
  gtk_widget_get_allocation(GTK_WIDGET(self), &allocation);
  handle_geometry_changed_with_size(self, allocation.width, allocation.height);
#endif
}

static void view_added_cb(GObject* object,
                          GAsyncResult* result,
                          gpointer user_data) {
  FlView* self = FL_VIEW(user_data);

  g_autoptr(GError) error = nullptr;
  if (!fl_engine_add_view_finish(FL_ENGINE(object), result, &error)) {
    if (g_error_matches(error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
      return;
    }

    g_warning("Failed to add view: %s", error->message);
    // FIXME: Show on the GLArea
    return;
  }

  handle_geometry_changed(self);
}

// Called when the engine updates accessibility.
static void update_semantics_cb(FlView* self,
                                const FlutterSemanticsUpdate2* update) {
  // A semantics update is routed to a particular view.
  if (update->view_id != self->view_id) {
    return;
  }

#if !FLUTTER_LINUX_GTK4
  fl_view_accessible_handle_update_semantics(self->view_accessible, update);
#else
  (void)self;
  (void)update;
#endif
}

// Invoked by the engine right before the engine is restarted.
//
// This method should reset states to be as if the engine had just been started,
// which usually indicates the user has requested a hot restart (Shift-R in the
// Flutter CLI.)
static void on_pre_engine_restart_cb(FlView* self) {
  init_scrolling(self);
  init_touch(self);
}

// Implements FlRenderable::present_layers
static void fl_view_present_layers(FlRenderable* renderable,
                                   const FlutterLayer** layers,
                                   size_t layers_count) {
  FlView* self = FL_VIEW(renderable);

  if (layers_count > 0 && layers[0] != nullptr) {
    static bool logged_first_layers = false;
    log_once(&logged_first_layers,
             "fl_view_present_layers: received first frame layers");
    static bool logged_layer_size = false;
    if (!logged_layer_size) {
      logged_layer_size = true;
      g_warning("fl_view_present_layers: first layer size %g x %g",
                layers[0]->size.width, layers[0]->size.height);
    }
  }

  fl_compositor_present_layers(self->compositor, layers, layers_count);

  // Perform the redraw in the GTK thead.
  g_idle_add(redraw_cb, self);
}

// Implements FlPluginRegistry::get_registrar_for_plugin.
static FlPluginRegistrar* fl_view_get_registrar_for_plugin(
    FlPluginRegistry* registry,
    const gchar* name) {
  FlView* self = FL_VIEW(registry);

  return fl_plugin_registrar_new(self,
                                 fl_engine_get_binary_messenger(self->engine),
                                 fl_engine_get_texture_registrar(self->engine));
}

static void fl_renderable_iface_init(FlRenderableInterface* iface) {
  iface->present_layers = fl_view_present_layers;
}

static void fl_view_plugin_registry_iface_init(
    FlPluginRegistryInterface* iface) {
  iface->get_registrar_for_plugin = fl_view_get_registrar_for_plugin;
}

static void sync_modifier_if_needed(FlView* self, GdkEvent* event) {
  guint event_time = gdk_event_get_time(event);
#if FLUTTER_LINUX_GTK4
  GdkModifierType event_state = gdk_event_get_modifier_state(event);
#else
  GdkModifierType event_state = static_cast<GdkModifierType>(0);
  gdk_event_get_state(event, &event_state);
#endif
  fl_keyboard_manager_sync_modifier_if_needed(
      fl_engine_get_keyboard_manager(self->engine), event_state, event_time);
}

static void set_scrolling_position(FlView* self, gdouble x, gdouble y) {
  gint scale_factor = gtk_widget_get_scale_factor(GTK_WIDGET(self));
  fl_scrolling_manager_set_last_mouse_position(
      self->scrolling_manager, x * scale_factor, y * scale_factor);
}

#if !FLUTTER_LINUX_GTK4
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
  return fl_pointer_manager_handle_button_press(
      self->pointer_manager, gdk_event_get_time(event), get_device_kind(event),
      x * scale_factor, y * scale_factor, button);
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
  return fl_pointer_manager_handle_button_release(
      self->pointer_manager, gdk_event_get_time(event), get_device_kind(event),
      x * scale_factor, y * scale_factor, button);
}

// Signal handler for GtkWidget::scroll-event
static gboolean scroll_event_cb(FlView* self, GdkEventScroll* event) {
  // TODO(robert-ancell): Update to use GtkEventControllerScroll when we can
  // depend on GTK 3.24.

  fl_scrolling_manager_handle_scroll_event(
      self->scrolling_manager, reinterpret_cast<GdkEvent*>(event),
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
  return fl_pointer_manager_handle_motion(
      self->pointer_manager, gdk_event_get_time(event), get_device_kind(event),
      x * scale_factor, y * scale_factor);
}

// Signal handler for GtkWidget::enter-notify-event
static gboolean enter_notify_event_cb(FlView* self,
                                      GdkEventCrossing* crossing_event) {
  GdkEvent* event = reinterpret_cast<GdkEvent*>(crossing_event);
  gdouble x = 0.0, y = 0.0;
  gdk_event_get_coords(event, &x, &y);
  gint scale_factor = gtk_widget_get_scale_factor(GTK_WIDGET(self));
  return fl_pointer_manager_handle_enter(
      self->pointer_manager, gdk_event_get_time(event), get_device_kind(event),
      x * scale_factor, y * scale_factor);
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
  return fl_pointer_manager_handle_leave(
      self->pointer_manager, gdk_event_get_time(event), get_device_kind(event),
      x * scale_factor, y * scale_factor);
}
#endif  // !FLUTTER_LINUX_GTK4

#if FLUTTER_LINUX_GTK4
static guint32 get_event_time_or_now(GdkEvent* event) {
  if (event != nullptr) {
    return gdk_event_get_time(event);
  }
  return static_cast<guint32>(g_get_real_time() / 1000);
}

static GdkEvent* get_current_event(GtkEventController* controller) {
  return gtk_event_controller_get_current_event(controller);
}

static FlutterPointerDeviceKind get_device_kind_or_default(GdkEvent* event) {
  if (event != nullptr) {
    return get_device_kind(event);
  }
  return kFlutterPointerDeviceKindMouse;
}

static void motion_event_cb(FlView* self, gdouble x, gdouble y) {
  GdkEvent* event =
      get_current_event(GTK_EVENT_CONTROLLER(self->motion_controller));
  if (event == nullptr) {
    return;
  }

  sync_modifier_if_needed(self, event);

  // return if touch event
  auto event_type = gdk_event_get_event_type(event);
  if (event_type == GDK_TOUCH_BEGIN || event_type == GDK_TOUCH_UPDATE ||
      event_type == GDK_TOUCH_END || event_type == GDK_TOUCH_CANCEL) {
    return;
  }

  gint scale_factor = gtk_widget_get_scale_factor(GTK_WIDGET(self));
  fl_pointer_manager_handle_motion(
      self->pointer_manager, gdk_event_get_time(event), get_device_kind(event),
      x * scale_factor, y * scale_factor);
}

static void enter_event_cb(FlView* self, gdouble x, gdouble y) {
  GdkEvent* event =
      get_current_event(GTK_EVENT_CONTROLLER(self->motion_controller));
  gint scale_factor = gtk_widget_get_scale_factor(GTK_WIDGET(self));
  fl_pointer_manager_handle_enter(
      self->pointer_manager, get_event_time_or_now(event),
      get_device_kind_or_default(event), x * scale_factor, y * scale_factor);
}

static void leave_event_cb(FlView* self, gdouble x, gdouble y) {
  GdkEvent* event =
      get_current_event(GTK_EVENT_CONTROLLER(self->motion_controller));
  gint scale_factor = gtk_widget_get_scale_factor(GTK_WIDGET(self));
  fl_pointer_manager_handle_leave(
      self->pointer_manager, get_event_time_or_now(event),
      get_device_kind_or_default(event), x * scale_factor, y * scale_factor);
}

static void click_pressed_cb(FlView* self, gint n_press, gdouble x, gdouble y) {
  if (n_press > 1) {
    return;
  }

  GdkEvent* event =
      get_current_event(GTK_EVENT_CONTROLLER(self->click_gesture));
  if (event == nullptr) {
    return;
  }

  guint button = gtk_gesture_single_get_current_button(
      GTK_GESTURE_SINGLE(self->click_gesture));

  set_scrolling_position(self, x, y);
  sync_modifier_if_needed(self, event);

  gint scale_factor = gtk_widget_get_scale_factor(GTK_WIDGET(self));
  fl_pointer_manager_handle_button_press(
      self->pointer_manager, gdk_event_get_time(event), get_device_kind(event),
      x * scale_factor, y * scale_factor, button);
}

static void click_released_cb(FlView* self,
                              gint n_press,
                              gdouble x,
                              gdouble y) {
  (void)n_press;
  GdkEvent* event =
      get_current_event(GTK_EVENT_CONTROLLER(self->click_gesture));
  if (event == nullptr) {
    return;
  }

  guint button = gtk_gesture_single_get_current_button(
      GTK_GESTURE_SINGLE(self->click_gesture));

  set_scrolling_position(self, x, y);
  sync_modifier_if_needed(self, event);

  gint scale_factor = gtk_widget_get_scale_factor(GTK_WIDGET(self));
  fl_pointer_manager_handle_button_release(
      self->pointer_manager, gdk_event_get_time(event), get_device_kind(event),
      x * scale_factor, y * scale_factor, button);
}

static gboolean scroll_event_cb(FlView* self, gdouble dx, gdouble dy) {
  (void)dx;
  (void)dy;
  GdkEvent* event =
      get_current_event(GTK_EVENT_CONTROLLER(self->scroll_controller));
  if (event == nullptr) {
    return FALSE;
  }

  fl_scrolling_manager_handle_scroll_event(
      self->scrolling_manager, event,
      gtk_widget_get_scale_factor(GTK_WIDGET(self)));
  return TRUE;
}

static gboolean handle_key_event(FlView* self,
                                 GdkEvent* event,
                                 gboolean is_press,
                                 guint keyval,
                                 guint keycode,
                                 GdkModifierType state) {
  g_autoptr(FlKeyEvent) key_event = nullptr;
  if (event != nullptr) {
    key_event = fl_key_event_new_from_gdk_event(event);
  } else {
    key_event = fl_key_event_new(get_event_time_or_now(event), is_press,
                                 keycode, keyval, state, 0);
  }

  fl_keyboard_manager_handle_event(
      fl_engine_get_keyboard_manager(self->engine), key_event,
      self->cancellable,
      [](GObject* object, GAsyncResult* result, gpointer user_data) {
        FlView* self = FL_VIEW(user_data);

        g_autoptr(FlKeyEvent) redispatch_event = nullptr;
        g_autoptr(GError) error = nullptr;
        if (!fl_keyboard_manager_handle_event_finish(
                FL_KEYBOARD_MANAGER(object), result, &redispatch_event,
                &error)) {
          if (g_error_matches(error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
            return;
          }

          g_warning("Failed to handle key event: %s", error->message);
        }

        if (redispatch_event != nullptr) {
          if (!fl_text_input_handler_filter_keypress(
                  fl_engine_get_text_input_handler(self->engine),
                  redispatch_event)) {
            fl_keyboard_manager_add_redispatched_event(
                fl_engine_get_keyboard_manager(self->engine), redispatch_event);
            // TODO(gtk4): Redispatch unhandled events to GTK.
          }
        }
      },
      self);

  return TRUE;
}

static gboolean key_pressed_cb(FlView* self,
                               guint keyval,
                               guint keycode,
                               GdkModifierType state) {
  GdkEvent* event =
      get_current_event(GTK_EVENT_CONTROLLER(self->key_controller));
  return handle_key_event(self, event, TRUE, keyval, keycode, state);
}

static gboolean key_released_cb(FlView* self,
                                guint keyval,
                                guint keycode,
                                GdkModifierType state) {
  GdkEvent* event =
      get_current_event(GTK_EVENT_CONTROLLER(self->key_controller));
  return handle_key_event(self, event, FALSE, keyval, keycode, state);
}
#endif  // FLUTTER_LINUX_GTK4

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

static void setup_opengl(FlView* self) {
  g_autoptr(GError) error = nullptr;

  FlGdkSurface* surface =
      fl_gtk_widget_get_surface(GTK_WIDGET(self->render_area));
  if (surface == nullptr) {
    g_warning("Failed to create OpenGL context: surface not available");
    return;
  }

  self->render_context = fl_gtk_surface_create_gl_context(surface, &error);
  if (self->render_context == nullptr) {
    g_warning("Failed to create OpenGL context: %s", error->message);
    return;
  }

  if (!gdk_gl_context_realize(self->render_context, &error)) {
    g_warning("Failed to realize OpenGL context: %s", error->message);
    return;
  }

  // If using Wayland, then EGL is in use and we can access the frame
  // from the Flutter context using EGLImage. If not (i.e. X11 using GLX)
  // then we have to copy the texture via the CPU.
  gboolean shareable =
      GDK_IS_WAYLAND_DISPLAY(fl_gtk_surface_get_display(surface));
  self->compositor = FL_COMPOSITOR(fl_compositor_opengl_new(
      fl_engine_get_task_runner(self->engine),
      fl_engine_get_opengl_manager(self->engine), shareable));
}

static void setup_software(FlView* self) {
  self->compositor = FL_COMPOSITOR(
      fl_compositor_software_new(fl_engine_get_task_runner(self->engine)));
}

static void realize_cb(FlView* self) {
  switch (fl_engine_get_renderer_type(self->engine)) {
    case kOpenGL:
      setup_opengl(self);
      break;
    case kSoftware:
      setup_software(self);
      break;
    default:
      break;
  }

  if (self->view_id != flutter::kFlutterImplicitViewId) {
    setup_cursor(self);
    return;
  }

  GtkWidget* toplevel_window = fl_view_get_toplevel_widget(self);

  self->window_state_monitor =
      fl_window_state_monitor_new(fl_engine_get_binary_messenger(self->engine),
                                  GTK_WINDOW(toplevel_window));

  // Handle requests by the user to close the application.
#if FLUTTER_LINUX_GTK4
  g_signal_connect(toplevel_window, "close-request",
                   G_CALLBACK(window_close_request_cb), self);
#else
  g_signal_connect_swapped(toplevel_window, "delete-event",
                           G_CALLBACK(window_delete_event_cb), self);
#endif

  // Flutter engine will need to make the context current from raster thread
  // during initialization.
  fl_opengl_manager_clear_current(fl_engine_get_opengl_manager(self->engine));

  g_autoptr(GError) error = nullptr;
  if (!fl_engine_start(self->engine, &error)) {
    g_warning("Failed to start Flutter engine: %s", error->message);
    return;
  }

#if FLUTTER_LINUX_GTK4
  fl_text_input_handler_set_widget(
      fl_engine_get_text_input_handler(self->engine), GTK_WIDGET(self));
#endif

  setup_cursor(self);

  handle_geometry_changed(self);
}

#if !FLUTTER_LINUX_GTK4
static void size_allocate_cb(FlView* self) {
  handle_geometry_changed(self);
}
#endif

#if FLUTTER_LINUX_GTK4
static void resize_cb(FlView* self, int width, int height) {
  if (width > 0 && height > 0) {
    static bool logged_resize = false;
    log_once(&logged_resize,
             "resize_cb: received non-zero size for render area");
  }
  handle_geometry_changed_with_size(self, width, height);
}
#endif

static void paint_background(FlView* self, cairo_t* cr) {
  // Don't bother drawing if fully transparent - the widget above this will
  // already be drawn by GTK.
  if (self->background_color->red == 0 && self->background_color->green == 0 &&
      self->background_color->blue == 0 && self->background_color->alpha == 0) {
    return;
  }

  gdk_cairo_set_source_rgba(cr, self->background_color);
  cairo_paint(cr);
}

static gboolean draw_cb(FlView* self, cairo_t* cr) {
  paint_background(self, cr);

  if (self->render_context) {
    gdk_gl_context_make_current(self->render_context);
  }

  FlGdkSurface* surface =
      fl_gtk_widget_get_surface(GTK_WIDGET(self->render_area));
  if (surface == nullptr) {
    static bool logged_surface_null = false;
    log_once(&logged_surface_null, "draw_cb: render area has no surface");
    if (self->render_context) {
      gdk_gl_context_clear_current();
    }
    return FALSE;
  }

  {
    static bool logged_surface_size = false;
    if (!logged_surface_size) {
      logged_surface_size = true;
      g_warning("draw_cb: surface size %d x %d (scale %d)",
                fl_gtk_surface_get_width(surface),
                fl_gtk_surface_get_height(surface),
                fl_gtk_surface_get_scale_factor(surface));
    }
  }

  gboolean result = fl_compositor_render(self->compositor, cr, surface);

  if (self->render_context) {
    gdk_gl_context_clear_current();
  }

  if (!result) {
    static bool logged_render_false = false;
    log_once(&logged_render_false, "draw_cb: compositor render returned false");
  }

  return result;
}

#if FLUTTER_LINUX_GTK4
static void draw_cb_gtk4(GtkDrawingArea* area,
                         cairo_t* cr,
                         int width,
                         int height,
                         gpointer user_data) {
  (void)area;
  (void)width;
  (void)height;
  FlView* self = FL_VIEW(user_data);
  draw_cb(self, cr);
}
#endif  // FLUTTER_LINUX_GTK4

static void fl_view_notify(GObject* object, GParamSpec* pspec) {
  FlView* self = FL_VIEW(object);

  if (strcmp(pspec->name, "scale-factor") == 0) {
    handle_geometry_changed(self);
  }

  if (G_OBJECT_CLASS(fl_view_parent_class)->notify != nullptr) {
    G_OBJECT_CLASS(fl_view_parent_class)->notify(object, pspec);
  }
}

static void fl_view_dispose(GObject* object) {
  FlView* self = FL_VIEW(object);

  g_cancellable_cancel(self->cancellable);

  if (self->engine != nullptr) {
    FlMouseCursorHandler* handler =
        fl_engine_get_mouse_cursor_handler(self->engine);
    if (self->cursor_changed_cb_id != 0) {
      g_signal_handler_disconnect(handler, self->cursor_changed_cb_id);
      self->cursor_changed_cb_id = 0;
    }

    // Release the view ID from the engine.
    fl_engine_remove_view(self->engine, self->view_id, nullptr, nullptr,
                          nullptr);
  }

  if (self->on_pre_engine_restart_cb_id != 0) {
    g_signal_handler_disconnect(self->engine,
                                self->on_pre_engine_restart_cb_id);
    self->on_pre_engine_restart_cb_id = 0;
  }

  if (self->update_semantics_cb_id != 0) {
    g_signal_handler_disconnect(self->engine, self->update_semantics_cb_id);
    self->update_semantics_cb_id = 0;
  }

  g_clear_object(&self->render_context);
  g_clear_object(&self->engine);
  g_clear_object(&self->compositor);
  g_clear_pointer(&self->background_color, gdk_rgba_free);
  g_clear_object(&self->window_state_monitor);
  g_clear_object(&self->scrolling_manager);
  g_clear_object(&self->pointer_manager);
  g_clear_object(&self->touch_manager);
#if FLUTTER_LINUX_GTK4
  g_clear_object(&self->motion_controller);
  g_clear_object(&self->click_gesture);
  g_clear_object(&self->scroll_controller);
  g_clear_object(&self->key_controller);
  g_clear_object(&self->zoom_gesture);
  g_clear_object(&self->rotate_gesture);
#endif
#if !FLUTTER_LINUX_GTK4
  g_clear_object(&self->view_accessible);
#endif
  g_clear_object(&self->cancellable);

  G_OBJECT_CLASS(fl_view_parent_class)->dispose(object);
}

// Implements GtkWidget::realize.
static void fl_view_realize(GtkWidget* widget) {
#if !FLUTTER_LINUX_GTK4
  FlView* self = FL_VIEW(widget);
#endif

  GTK_WIDGET_CLASS(fl_view_parent_class)->realize(widget);

  // Realize the child widgets.
#if !FLUTTER_LINUX_GTK4
  gtk_widget_realize(GTK_WIDGET(self->render_area));
#endif
}

#if !FLUTTER_LINUX_GTK4
static gboolean handle_key_event(FlView* self, GdkEventKey* key_event) {
  g_autoptr(FlKeyEvent) event =
      fl_key_event_new_from_gdk_event(reinterpret_cast<GdkEvent*>(key_event));

  fl_keyboard_manager_handle_event(
      fl_engine_get_keyboard_manager(self->engine), event, self->cancellable,
      [](GObject* object, GAsyncResult* result, gpointer user_data) {
        FlView* self = FL_VIEW(user_data);

        g_autoptr(FlKeyEvent) redispatch_event = nullptr;
        g_autoptr(GError) error = nullptr;
        if (!fl_keyboard_manager_handle_event_finish(
                FL_KEYBOARD_MANAGER(object), result, &redispatch_event,
                &error)) {
          if (g_error_matches(error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
            return;
          }

          g_warning("Failed to handle key event: %s", error->message);
        }

        if (redispatch_event != nullptr) {
          if (!fl_text_input_handler_filter_keypress(
                  fl_engine_get_text_input_handler(self->engine),
                  redispatch_event)) {
            fl_keyboard_manager_add_redispatched_event(
                fl_engine_get_keyboard_manager(self->engine), redispatch_event);
            gdk_event_put(fl_key_event_get_origin(redispatch_event));
          }
        }
      },
      self);

  return TRUE;
}

// Implements GtkWidget::key_press_event.
static gboolean fl_view_focus_in_event(GtkWidget* widget,
                                       GdkEventFocus* event) {
  FlView* self = FL_VIEW(widget);
  fl_text_input_handler_set_widget(
      fl_engine_get_text_input_handler(self->engine), widget);
  return FALSE;
}

// Implements GtkWidget::key_press_event.
static gboolean fl_view_key_press_event(GtkWidget* widget,
                                        GdkEventKey* key_event) {
  FlView* self = FL_VIEW(widget);
  return handle_key_event(self, key_event);
}

// Implements GtkWidget::key_release_event.
static gboolean fl_view_key_release_event(GtkWidget* widget,
                                          GdkEventKey* key_event) {
  FlView* self = FL_VIEW(widget);
  return handle_key_event(self, key_event);
}
#endif  // !FLUTTER_LINUX_GTK4

static void fl_view_class_init(FlViewClass* klass) {
  GObjectClass* object_class = G_OBJECT_CLASS(klass);
  object_class->notify = fl_view_notify;
  object_class->dispose = fl_view_dispose;

  GtkWidgetClass* widget_class = GTK_WIDGET_CLASS(klass);
  widget_class->realize = fl_view_realize;
#if !FLUTTER_LINUX_GTK4
  widget_class->focus_in_event = fl_view_focus_in_event;
  widget_class->key_press_event = fl_view_key_press_event;
  widget_class->key_release_event = fl_view_key_release_event;
#endif

  fl_view_signals[SIGNAL_FIRST_FRAME] =
      g_signal_new("first-frame", fl_view_get_type(), G_SIGNAL_RUN_LAST, 0,
                   NULL, NULL, NULL, G_TYPE_NONE, 0);

#if !FLUTTER_LINUX_GTK4
  gtk_widget_class_set_accessible_type(GTK_WIDGET_CLASS(klass),
                                       fl_socket_accessible_get_type());
#endif
}

// Engine related construction.
static void setup_engine(FlView* self) {
#if !FLUTTER_LINUX_GTK4
  self->view_accessible = fl_view_accessible_new(self->engine, self->view_id);
  fl_socket_accessible_embed(
      FL_SOCKET_ACCESSIBLE(gtk_widget_get_accessible(GTK_WIDGET(self))),
      atk_plug_get_id(ATK_PLUG(self->view_accessible)));
#endif

  self->pointer_manager = fl_pointer_manager_new(self->view_id, self->engine);

  init_scrolling(self);
  init_touch(self);

  self->on_pre_engine_restart_cb_id =
      g_signal_connect_swapped(self->engine, "on-pre-engine-restart",
                               G_CALLBACK(on_pre_engine_restart_cb), self);
  self->update_semantics_cb_id = g_signal_connect_swapped(
      self->engine, "update-semantics", G_CALLBACK(update_semantics_cb), self);
}

static void fl_view_init(FlView* self) {
  self->cancellable = g_cancellable_new();

#if FLUTTER_LINUX_GTK4
  gtk_widget_set_focusable(GTK_WIDGET(self), TRUE);
#else
  gtk_widget_set_can_focus(GTK_WIDGET(self), TRUE);
#endif

  self->view_id = -1;

  GdkRGBA default_background = {
      .red = 0.0, .green = 0.0, .blue = 0.0, .alpha = 1.0};
  self->background_color = gdk_rgba_copy(&default_background);

#if !FLUTTER_LINUX_GTK4
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
  GtkGesture* zoom = gtk_gesture_zoom_new(self->event_box);
  g_signal_connect_swapped(zoom, "begin", G_CALLBACK(gesture_zoom_begin_cb),
                           self);
  g_signal_connect_swapped(zoom, "scale-changed",
                           G_CALLBACK(gesture_zoom_update_cb), self);
  g_signal_connect_swapped(zoom, "end", G_CALLBACK(gesture_zoom_end_cb), self);
  GtkGesture* rotate = gtk_gesture_rotate_new(self->event_box);
  g_signal_connect_swapped(rotate, "begin",
                           G_CALLBACK(gesture_rotation_begin_cb), self);
  g_signal_connect_swapped(rotate, "angle-changed",
                           G_CALLBACK(gesture_rotation_update_cb), self);
  g_signal_connect_swapped(rotate, "end", G_CALLBACK(gesture_rotation_end_cb),
                           self);
  g_signal_connect_swapped(self->event_box, "touch-event",
                           G_CALLBACK(touch_event_cb), self);
#endif  // !FLUTTER_LINUX_GTK4

  self->render_area = GTK_DRAWING_AREA(gtk_drawing_area_new());
  gtk_widget_show(GTK_WIDGET(self->render_area));
#if FLUTTER_LINUX_GTK4
  gtk_widget_set_hexpand(GTK_WIDGET(self->render_area), TRUE);
  gtk_widget_set_vexpand(GTK_WIDGET(self->render_area), TRUE);
  gtk_box_append(GTK_BOX(self), GTK_WIDGET(self->render_area));
#else
  gtk_container_add(GTK_CONTAINER(self->event_box),
                    GTK_WIDGET(self->render_area));
#endif
  g_signal_connect_swapped(self->render_area, "realize", G_CALLBACK(realize_cb),
                           self);
#if FLUTTER_LINUX_GTK4
  g_signal_connect_swapped(self->render_area, "resize", G_CALLBACK(resize_cb),
                           self);
#else
  g_signal_connect_swapped(self->render_area, "size-allocate",
                           G_CALLBACK(size_allocate_cb), self);
#endif
#if FLUTTER_LINUX_GTK4
  gtk_drawing_area_set_draw_func(self->render_area, draw_cb_gtk4, self,
                                 nullptr);
#else
  g_signal_connect_swapped(self->render_area, "draw", G_CALLBACK(draw_cb),
                           self);
#endif

#if FLUTTER_LINUX_GTK4
  self->motion_controller =
      GTK_EVENT_CONTROLLER_MOTION(gtk_event_controller_motion_new());
  g_signal_connect_swapped(self->motion_controller, "motion",
                           G_CALLBACK(motion_event_cb), self);
  g_signal_connect_swapped(self->motion_controller, "enter",
                           G_CALLBACK(enter_event_cb), self);
  g_signal_connect_swapped(self->motion_controller, "leave",
                           G_CALLBACK(leave_event_cb), self);
  gtk_widget_add_controller(GTK_WIDGET(self->render_area),
                            GTK_EVENT_CONTROLLER(self->motion_controller));

  self->click_gesture = GTK_GESTURE_CLICK(gtk_gesture_click_new());
  g_signal_connect_swapped(self->click_gesture, "pressed",
                           G_CALLBACK(click_pressed_cb), self);
  g_signal_connect_swapped(self->click_gesture, "released",
                           G_CALLBACK(click_released_cb), self);
  gtk_widget_add_controller(GTK_WIDGET(self->render_area),
                            GTK_EVENT_CONTROLLER(self->click_gesture));

  self->scroll_controller = GTK_EVENT_CONTROLLER_SCROLL(
      gtk_event_controller_scroll_new(GTK_EVENT_CONTROLLER_SCROLL_BOTH_AXES));
  g_signal_connect_swapped(self->scroll_controller, "scroll",
                           G_CALLBACK(scroll_event_cb), self);
  gtk_widget_add_controller(GTK_WIDGET(self->render_area),
                            GTK_EVENT_CONTROLLER(self->scroll_controller));

  self->key_controller =
      GTK_EVENT_CONTROLLER_KEY(gtk_event_controller_key_new());
  g_signal_connect_swapped(self->key_controller, "key-pressed",
                           G_CALLBACK(key_pressed_cb), self);
  g_signal_connect_swapped(self->key_controller, "key-released",
                           G_CALLBACK(key_released_cb), self);
  gtk_widget_add_controller(GTK_WIDGET(self),
                            GTK_EVENT_CONTROLLER(self->key_controller));

  self->zoom_gesture = GTK_GESTURE_ZOOM(gtk_gesture_zoom_new());
  g_signal_connect_swapped(self->zoom_gesture, "begin",
                           G_CALLBACK(gesture_zoom_begin_cb), self);
  g_signal_connect_swapped(self->zoom_gesture, "scale-changed",
                           G_CALLBACK(gesture_zoom_update_cb), self);
  g_signal_connect_swapped(self->zoom_gesture, "end",
                           G_CALLBACK(gesture_zoom_end_cb), self);
  gtk_widget_add_controller(GTK_WIDGET(self->render_area),
                            GTK_EVENT_CONTROLLER(self->zoom_gesture));

  self->rotate_gesture = GTK_GESTURE_ROTATE(gtk_gesture_rotate_new());
  g_signal_connect_swapped(self->rotate_gesture, "begin",
                           G_CALLBACK(gesture_rotation_begin_cb), self);
  g_signal_connect_swapped(self->rotate_gesture, "angle-changed",
                           G_CALLBACK(gesture_rotation_update_cb), self);
  g_signal_connect_swapped(self->rotate_gesture, "end",
                           G_CALLBACK(gesture_rotation_end_cb), self);
  gtk_widget_add_controller(GTK_WIDGET(self->render_area),
                            GTK_EVENT_CONTROLLER(self->rotate_gesture));
#endif  // FLUTTER_LINUX_GTK4
}

G_MODULE_EXPORT FlView* fl_view_new(FlDartProject* project) {
  g_autoptr(FlEngine) engine = fl_engine_new(project);
  FlView* self = FL_VIEW(g_object_new(fl_view_get_type(), nullptr));

  self->view_id = flutter::kFlutterImplicitViewId;
  self->engine = FL_ENGINE(g_object_ref(engine));

  setup_engine(self);

  fl_engine_set_implicit_view(engine, FL_RENDERABLE(self));

  return self;
}

G_MODULE_EXPORT FlView* fl_view_new_for_engine(FlEngine* engine) {
  FlView* self = FL_VIEW(g_object_new(fl_view_get_type(), nullptr));

  self->engine = FL_ENGINE(g_object_ref(engine));

  self->view_id = fl_engine_add_view(engine, FL_RENDERABLE(self), 1, 1, 1.0,
                                     self->cancellable, view_added_cb, self);

  setup_engine(self);

  return self;
}

G_MODULE_EXPORT FlEngine* fl_view_get_engine(FlView* self) {
  g_return_val_if_fail(FL_IS_VIEW(self), nullptr);
  return self->engine;
}

G_MODULE_EXPORT
int64_t fl_view_get_id(FlView* self) {
  g_return_val_if_fail(FL_IS_VIEW(self), -1);
  return self->view_id;
}

G_MODULE_EXPORT void fl_view_set_background_color(FlView* self,
                                                  const GdkRGBA* color) {
  g_return_if_fail(FL_IS_VIEW(self));
  gdk_rgba_free(self->background_color);
  self->background_color = gdk_rgba_copy(color);
}

#if !FLUTTER_LINUX_GTK4
FlViewAccessible* fl_view_get_accessible(FlView* self) {
  g_return_val_if_fail(FL_IS_VIEW(self), nullptr);
  return self->view_accessible;
}
#endif
