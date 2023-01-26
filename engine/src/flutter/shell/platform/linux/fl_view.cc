// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"

#include "flutter/shell/platform/linux/fl_view_private.h"

#include <cstring>

#include "flutter/shell/platform/linux/fl_accessibility_plugin.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_key_event.h"
#include "flutter/shell/platform/linux/fl_keyboard_manager.h"
#include "flutter/shell/platform/linux/fl_keyboard_view_delegate.h"
#include "flutter/shell/platform/linux/fl_mouse_cursor_plugin.h"
#include "flutter/shell/platform/linux/fl_platform_plugin.h"
#include "flutter/shell/platform/linux/fl_plugin_registrar_private.h"
#include "flutter/shell/platform/linux/fl_renderer_gl.h"
#include "flutter/shell/platform/linux/fl_scrolling_manager.h"
#include "flutter/shell/platform/linux/fl_scrolling_view_delegate.h"
#include "flutter/shell/platform/linux/fl_text_input_plugin.h"
#include "flutter/shell/platform/linux/fl_text_input_view_delegate.h"
#include "flutter/shell/platform/linux/fl_view_accessible.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_engine.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_plugin_registry.h"

static constexpr int kMicrosecondsPerMillisecond = 1000;

struct _FlView {
  GtkContainer parent_instance;

  // Project being run.
  FlDartProject* project;

  // Rendering output.
  FlRenderer* renderer;

  // Engine running @project.
  FlEngine* engine;

  // Pointer button state recorded for sending status updates.
  int64_t button_state;

  // Flutter system channel handlers.
  FlAccessibilityPlugin* accessibility_plugin;
  FlKeyboardManager* keyboard_manager;
  FlScrollingManager* scrolling_manager;
  FlTextInputPlugin* text_input_plugin;
  FlMouseCursorPlugin* mouse_cursor_plugin;
  FlPlatformPlugin* platform_plugin;

  GList* gl_area_list;
  GList* used_area_list;

  GtkWidget* event_box;

  GList* children_list;
  GList* pending_children_list;

  // Tracks whether mouse pointer is inside the view.
  gboolean pointer_inside;

  /* FlKeyboardViewDelegate related properties */
  KeyboardLayoutNotifier keyboard_layout_notifier;
  GdkKeymap* keymap;
  gulong keymap_keys_changed_cb_id;  // Signal connection ID.
};

typedef struct _FlViewChild {
  GtkWidget* widget;
  GdkRectangle geometry;
} FlViewChild;

enum { kPropFlutterProject = 1, kPropLast };

static void fl_view_plugin_registry_iface_init(
    FlPluginRegistryInterface* iface);

static void fl_view_keyboard_delegate_iface_init(
    FlKeyboardViewDelegateInterface* iface);

static void fl_view_scrolling_delegate_iface_init(
    FlScrollingViewDelegateInterface* iface);

static void fl_view_text_input_delegate_iface_init(
    FlTextInputViewDelegateInterface* iface);

G_DEFINE_TYPE_WITH_CODE(
    FlView,
    fl_view,
    GTK_TYPE_CONTAINER,
    G_IMPLEMENT_INTERFACE(fl_plugin_registry_get_type(),
                          fl_view_plugin_registry_iface_init)
        G_IMPLEMENT_INTERFACE(fl_keyboard_view_delegate_get_type(),
                              fl_view_keyboard_delegate_iface_init)
            G_IMPLEMENT_INTERFACE(fl_scrolling_view_delegate_get_type(),
                                  fl_view_scrolling_delegate_iface_init)
                G_IMPLEMENT_INTERFACE(fl_text_input_view_delegate_get_type(),
                                      fl_view_text_input_delegate_iface_init))

// Initialize keyboard manager.
static void init_keyboard(FlView* self) {
  FlBinaryMessenger* messenger = fl_engine_get_binary_messenger(self->engine);

  GdkWindow* window =
      gtk_widget_get_window(gtk_widget_get_toplevel(GTK_WIDGET(self)));
  g_return_if_fail(GDK_IS_WINDOW(window));
  g_autoptr(GtkIMContext) im_context = gtk_im_multicontext_new();
  gtk_im_context_set_client_window(im_context, window);

  self->text_input_plugin = fl_text_input_plugin_new(
      messenger, im_context, FL_TEXT_INPUT_VIEW_DELEGATE(self));
  self->keyboard_manager =
      fl_keyboard_manager_new(FL_KEYBOARD_VIEW_DELEGATE(self));
}

static void init_scrolling(FlView* self) {
  self->scrolling_manager =
      fl_scrolling_manager_new(FL_SCROLLING_VIEW_DELEGATE(self));
}

// Converts a GDK button event into a Flutter event and sends it to the engine.
static gboolean send_pointer_button_event(FlView* self, GdkEventButton* event) {
  int64_t button;
  switch (event->button) {
    case 1:
      button = kFlutterPointerButtonMousePrimary;
      break;
    case 2:
      button = kFlutterPointerButtonMouseMiddle;
      break;
    case 3:
      button = kFlutterPointerButtonMouseSecondary;
      break;
    default:
      return FALSE;
  }
  int old_button_state = self->button_state;
  FlutterPointerPhase phase = kMove;
  if (event->type == GDK_BUTTON_PRESS) {
    // Drop the event if Flutter already thinks the button is down.
    if ((self->button_state & button) != 0) {
      return FALSE;
    }
    self->button_state ^= button;

    phase = old_button_state == 0 ? kDown : kMove;
  } else if (event->type == GDK_BUTTON_RELEASE) {
    // Drop the event if Flutter already thinks the button is up.
    if ((self->button_state & button) == 0) {
      return FALSE;
    }
    self->button_state ^= button;

    phase = self->button_state == 0 ? kUp : kMove;
  }

  if (self->engine == nullptr) {
    return FALSE;
  }

  gint scale_factor = gtk_widget_get_scale_factor(GTK_WIDGET(self));
  fl_scrolling_manager_set_last_mouse_position(self->scrolling_manager,
                                               event->x * scale_factor,
                                               event->y * scale_factor);
  fl_keyboard_manager_sync_modifier_if_needed(self->keyboard_manager,
                                              event->state, event->time);
  fl_engine_send_mouse_pointer_event(
      self->engine, phase, event->time * kMicrosecondsPerMillisecond,
      event->x * scale_factor, event->y * scale_factor, 0, 0,
      self->button_state);

  return TRUE;
}

// Generates a mouse pointer event if the pointer appears inside the window.
static void check_pointer_inside(FlView* view, GdkEvent* event) {
  if (!view->pointer_inside) {
    view->pointer_inside = TRUE;

    gdouble x, y;
    if (gdk_event_get_coords(event, &x, &y)) {
      gint scale_factor = gtk_widget_get_scale_factor(GTK_WIDGET(view));

      fl_engine_send_mouse_pointer_event(
          view->engine, kAdd,
          gdk_event_get_time(event) * kMicrosecondsPerMillisecond,
          x * scale_factor, y * scale_factor, 0, 0, view->button_state);
    }
  }
}

// Updates the engine with the current window metrics.
static void handle_geometry_changed(FlView* self) {
  GtkAllocation allocation;
  gtk_widget_get_allocation(GTK_WIDGET(self), &allocation);
  gint scale_factor = gtk_widget_get_scale_factor(GTK_WIDGET(self));
  fl_engine_send_window_metrics_event(
      self->engine, allocation.width * scale_factor,
      allocation.height * scale_factor, scale_factor);

  // Make sure the view has been realized and its size has been allocated before
  // waiting for a frame. `fl_view_realize()` and `fl_view_size_allocate()` may
  // be called in either order depending on the order in which the window is
  // shown and the view is added to a container in the app runner.
  //
  // Note: `gtk_widget_init()` initializes the size allocation to 1x1.
  if (allocation.width > 1 && allocation.height > 1 &&
      gtk_widget_get_realized(GTK_WIDGET(self))) {
    fl_renderer_wait_for_frame(self->renderer, allocation.width * scale_factor,
                               allocation.height * scale_factor);
  }
}

// Adds a widget to render in this view.
static void add_pending_child(FlView* self,
                              GtkWidget* widget,
                              GdkRectangle* geometry) {
  FlViewChild* child = g_new(FlViewChild, 1);
  child->widget = widget;
  if (geometry) {
    child->geometry = *geometry;
  } else {
    child->geometry = {0, 0, 0, 0};
  }

  self->pending_children_list =
      g_list_append(self->pending_children_list, child);
}

// Finds the node with the specified widget in a list of FlViewChild.
static GList* find_child(GList* list, GtkWidget* widget) {
  for (GList* i = list; i; i = i->next) {
    FlViewChild* child = reinterpret_cast<FlViewChild*>(i->data);
    if (child && child->widget == widget) {
      return i;
    }
  }
  return nullptr;
}

// Called when the engine updates accessibility nodes.
static void update_semantics_node_cb(FlEngine* engine,
                                     const FlutterSemanticsNode* node,
                                     gpointer user_data) {
  FlView* self = FL_VIEW(user_data);

  fl_accessibility_plugin_handle_update_semantics_node(
      self->accessibility_plugin, node);
}

// Invoked by the engine right before the engine is restarted.
//
// This method should reset states to be as if the engine had just been started,
// which usually indicates the user has requested a hot restart (Shift-R in the
// Flutter CLI.)
static void on_pre_engine_restart_cb(FlEngine* engine, gpointer user_data) {
  FlView* self = FL_VIEW(user_data);

  g_clear_object(&self->keyboard_manager);
  g_clear_object(&self->text_input_plugin);
  g_clear_object(&self->scrolling_manager);
  init_keyboard(self);
  init_scrolling(self);
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

static void fl_view_plugin_registry_iface_init(
    FlPluginRegistryInterface* iface) {
  iface->get_registrar_for_plugin = fl_view_get_registrar_for_plugin;
}

static void fl_view_keyboard_delegate_iface_init(
    FlKeyboardViewDelegateInterface* iface) {
  iface->send_key_event =
      [](FlKeyboardViewDelegate* view_delegate, const FlutterKeyEvent* event,
         FlutterKeyEventCallback callback, void* user_data) {
        FlView* self = FL_VIEW(view_delegate);
        if (self->engine != nullptr) {
          fl_engine_send_key_event(self->engine, event, callback, user_data);
        };
      };

  iface->text_filter_key_press = [](FlKeyboardViewDelegate* view_delegate,
                                    FlKeyEvent* event) {
    FlView* self = FL_VIEW(view_delegate);
    return fl_text_input_plugin_filter_keypress(self->text_input_plugin, event);
  };

  iface->get_messenger = [](FlKeyboardViewDelegate* view_delegate) {
    FlView* self = FL_VIEW(view_delegate);
    return fl_engine_get_binary_messenger(self->engine);
  };

  iface->redispatch_event = [](FlKeyboardViewDelegate* view_delegate,
                               std::unique_ptr<FlKeyEvent> in_event) {
    FlKeyEvent* event = in_event.release();
    GdkEvent* gdk_event = reinterpret_cast<GdkEvent*>(event->origin);
    GdkEventType type = gdk_event->type;
    g_return_if_fail(type == GDK_KEY_PRESS || type == GDK_KEY_RELEASE);
    gdk_event_put(gdk_event);
    fl_key_event_dispose(event);
  };

  iface->subscribe_to_layout_change = [](FlKeyboardViewDelegate* view_delegate,
                                         KeyboardLayoutNotifier notifier) {
    FlView* self = FL_VIEW(view_delegate);
    self->keyboard_layout_notifier = std::move(notifier);
  };

  iface->lookup_key = [](FlKeyboardViewDelegate* view_delegate,
                         const GdkKeymapKey* key) -> guint {
    FlView* self = FL_VIEW(view_delegate);
    g_return_val_if_fail(self->keymap != nullptr, 0);
    return gdk_keymap_lookup_key(self->keymap, key);
  };
}

static void fl_view_scrolling_delegate_iface_init(
    FlScrollingViewDelegateInterface* iface) {
  iface->send_mouse_pointer_event =
      [](FlScrollingViewDelegate* view_delegate, FlutterPointerPhase phase,
         size_t timestamp, double x, double y, double scroll_delta_x,
         double scroll_delta_y, int64_t buttons) {
        FlView* self = FL_VIEW(view_delegate);
        if (self->engine != nullptr) {
          fl_engine_send_mouse_pointer_event(self->engine, phase, timestamp, x,
                                             y, scroll_delta_x, scroll_delta_y,
                                             buttons);
        }
      };
  iface->send_pointer_pan_zoom_event =
      [](FlScrollingViewDelegate* view_delegate, size_t timestamp, double x,
         double y, FlutterPointerPhase phase, double pan_x, double pan_y,
         double scale, double rotation) {
        FlView* self = FL_VIEW(view_delegate);
        if (self->engine != nullptr) {
          fl_engine_send_pointer_pan_zoom_event(self->engine, timestamp, x, y,
                                                phase, pan_x, pan_y, scale,
                                                rotation);
        };
      };
}

static void fl_view_text_input_delegate_iface_init(
    FlTextInputViewDelegateInterface* iface) {
  iface->translate_coordinates = [](FlTextInputViewDelegate* delegate,
                                    gint view_x, gint view_y, gint* window_x,
                                    gint* window_y) {
    FlView* self = FL_VIEW(delegate);
    gtk_widget_translate_coordinates(GTK_WIDGET(self),
                                     gtk_widget_get_toplevel(GTK_WIDGET(self)),
                                     view_x, view_y, window_x, window_y);
  };
}

// Signal handler for GtkWidget::button-press-event
static gboolean button_press_event_cb(GtkWidget* widget,
                                      GdkEventButton* event,
                                      FlView* view) {
  // Flutter doesn't handle double and triple click events.
  if (event->type == GDK_DOUBLE_BUTTON_PRESS ||
      event->type == GDK_TRIPLE_BUTTON_PRESS) {
    return FALSE;
  }

  if (!gtk_widget_has_focus(GTK_WIDGET(view))) {
    gtk_widget_grab_focus(GTK_WIDGET(view));
  }

  return send_pointer_button_event(view, event);
}

// Signal handler for GtkWidget::button-release-event
static gboolean button_release_event_cb(GtkWidget* widget,
                                        GdkEventButton* event,
                                        FlView* view) {
  return send_pointer_button_event(view, event);
}

// Signal handler for GtkWidget::scroll-event
static gboolean scroll_event_cb(GtkWidget* widget,
                                GdkEventScroll* event,
                                FlView* view) {
  // TODO(robert-ancell): Update to use GtkEventControllerScroll when we can
  // depend on GTK 3.24.

  fl_scrolling_manager_handle_scroll_event(
      view->scrolling_manager, event,
      gtk_widget_get_scale_factor(GTK_WIDGET(view)));
  return TRUE;
}

// Signal handler for GtkWidget::motion-notify-event
static gboolean motion_notify_event_cb(GtkWidget* widget,
                                       GdkEventMotion* event,
                                       FlView* view) {
  if (view->engine == nullptr) {
    return FALSE;
  }

  check_pointer_inside(view, reinterpret_cast<GdkEvent*>(event));

  gint scale_factor = gtk_widget_get_scale_factor(GTK_WIDGET(view));

  fl_keyboard_manager_sync_modifier_if_needed(view->keyboard_manager,
                                              event->state, event->time);
  fl_engine_send_mouse_pointer_event(
      view->engine, view->button_state != 0 ? kMove : kHover,
      event->time * kMicrosecondsPerMillisecond, event->x * scale_factor,
      event->y * scale_factor, 0, 0, view->button_state);

  return TRUE;
}

// Signal handler for GtkWidget::enter-notify-event
static gboolean enter_notify_event_cb(GtkWidget* widget,
                                      GdkEventCrossing* event,
                                      FlView* view) {
  if (view->engine == nullptr) {
    return FALSE;
  }

  check_pointer_inside(view, reinterpret_cast<GdkEvent*>(event));

  return TRUE;
}

// Signal handler for GtkWidget::leave-notify-event
static gboolean leave_notify_event_cb(GtkWidget* widget,
                                      GdkEventCrossing* event,
                                      FlView* view) {
  if (view->engine == nullptr) {
    return FALSE;
  }

  // Don't remove pointer while button is down; In case of dragging outside of
  // window with mouse grab active Gtk will send another leave notify on
  // release.
  if (view->pointer_inside && view->button_state == 0) {
    gint scale_factor = gtk_widget_get_scale_factor(GTK_WIDGET(view));
    fl_engine_send_mouse_pointer_event(
        view->engine, kRemove, event->time * kMicrosecondsPerMillisecond,
        event->x * scale_factor, event->y * scale_factor, 0, 0,
        view->button_state);
    view->pointer_inside = FALSE;
  }

  return TRUE;
}

static void keymap_keys_changed_cb(GdkKeymap* self, FlView* view) {
  if (view->keyboard_layout_notifier == nullptr) {
    return;
  }

  view->keyboard_layout_notifier();
}

static void gesture_rotation_begin_cb(GtkGestureRotate* gesture,
                                      GdkEventSequence* sequence,
                                      FlView* view) {
  fl_scrolling_manager_handle_rotation_begin(view->scrolling_manager);
}

static void gesture_rotation_update_cb(GtkGestureRotate* widget,
                                       gdouble rotation,
                                       gdouble delta,
                                       FlView* view) {
  fl_scrolling_manager_handle_rotation_update(view->scrolling_manager,
                                              rotation);
}

static void gesture_rotation_end_cb(GtkGestureRotate* gesture,
                                    GdkEventSequence* sequence,
                                    FlView* view) {
  fl_scrolling_manager_handle_rotation_end(view->scrolling_manager);
}

static void gesture_zoom_begin_cb(GtkGestureZoom* gesture,
                                  GdkEventSequence* sequence,
                                  FlView* view) {
  fl_scrolling_manager_handle_zoom_begin(view->scrolling_manager);
}

static void gesture_zoom_update_cb(GtkGestureZoom* widget,
                                   gdouble scale,
                                   FlView* view) {
  fl_scrolling_manager_handle_zoom_update(view->scrolling_manager, scale);
}

static void gesture_zoom_end_cb(GtkGestureZoom* gesture,
                                GdkEventSequence* sequence,
                                FlView* view) {
  fl_scrolling_manager_handle_zoom_end(view->scrolling_manager);
}

static void fl_view_constructed(GObject* object) {
  FlView* self = FL_VIEW(object);

  self->renderer = FL_RENDERER(fl_renderer_gl_new());
  self->engine = fl_engine_new(self->project, self->renderer);
  fl_engine_set_update_semantics_node_handler(
      self->engine, update_semantics_node_cb, self, nullptr);
  fl_engine_set_on_pre_engine_restart_handler(
      self->engine, on_pre_engine_restart_cb, self, nullptr);

  // Must initialize the keymap before the keyboard.
  self->keymap = gdk_keymap_get_for_display(gdk_display_get_default());

  // Create system channel handlers.
  FlBinaryMessenger* messenger = fl_engine_get_binary_messenger(self->engine);
  self->accessibility_plugin = fl_accessibility_plugin_new(self);
  init_scrolling(self);
  self->mouse_cursor_plugin = fl_mouse_cursor_plugin_new(messenger, self);
  self->platform_plugin = fl_platform_plugin_new(messenger);

  self->event_box = gtk_event_box_new();
  gtk_widget_set_parent(self->event_box, GTK_WIDGET(self));
  gtk_widget_show(self->event_box);
  gtk_widget_add_events(self->event_box,
                        GDK_POINTER_MOTION_MASK | GDK_BUTTON_PRESS_MASK |
                            GDK_BUTTON_RELEASE_MASK | GDK_SCROLL_MASK |
                            GDK_SMOOTH_SCROLL_MASK);

  g_signal_connect(self->event_box, "button-press-event",
                   G_CALLBACK(button_press_event_cb), self);
  g_signal_connect(self->event_box, "button-release-event",
                   G_CALLBACK(button_release_event_cb), self);
  g_signal_connect(self->event_box, "scroll-event", G_CALLBACK(scroll_event_cb),
                   self);
  g_signal_connect(self->event_box, "motion-notify-event",
                   G_CALLBACK(motion_notify_event_cb), self);
  g_signal_connect(self->event_box, "enter-notify-event",
                   G_CALLBACK(enter_notify_event_cb), self);
  g_signal_connect(self->event_box, "leave-notify-event",
                   G_CALLBACK(leave_notify_event_cb), self);
  self->keymap_keys_changed_cb_id = g_signal_connect(
      self->keymap, "keys-changed", G_CALLBACK(keymap_keys_changed_cb), self);
  GtkGesture* zoom = gtk_gesture_zoom_new(self->event_box);
  g_signal_connect(zoom, "begin", G_CALLBACK(gesture_zoom_begin_cb), self);
  g_signal_connect(zoom, "scale-changed", G_CALLBACK(gesture_zoom_update_cb),
                   self);
  g_signal_connect(zoom, "end", G_CALLBACK(gesture_zoom_end_cb), self);
  GtkGesture* rotate = gtk_gesture_rotate_new(self->event_box);
  g_signal_connect(rotate, "begin", G_CALLBACK(gesture_rotation_begin_cb),
                   self);
  g_signal_connect(rotate, "angle-changed",
                   G_CALLBACK(gesture_rotation_update_cb), self);
  g_signal_connect(rotate, "end", G_CALLBACK(gesture_rotation_end_cb), self);
}

static void fl_view_set_property(GObject* object,
                                 guint prop_id,
                                 const GValue* value,
                                 GParamSpec* pspec) {
  FlView* self = FL_VIEW(object);

  switch (prop_id) {
    case kPropFlutterProject:
      g_set_object(&self->project,
                   static_cast<FlDartProject*>(g_value_get_object(value)));
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID(object, prop_id, pspec);
      break;
  }
}

static void fl_view_get_property(GObject* object,
                                 guint prop_id,
                                 GValue* value,
                                 GParamSpec* pspec) {
  FlView* self = FL_VIEW(object);

  switch (prop_id) {
    case kPropFlutterProject:
      g_value_set_object(value, self->project);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID(object, prop_id, pspec);
      break;
  }
}

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

  if (self->engine != nullptr) {
    fl_engine_set_update_semantics_node_handler(self->engine, nullptr, nullptr,
                                                nullptr);
    fl_engine_set_on_pre_engine_restart_handler(self->engine, nullptr, nullptr,
                                                nullptr);
  }

  g_clear_object(&self->project);
  g_clear_object(&self->renderer);
  g_clear_object(&self->engine);
  g_clear_object(&self->accessibility_plugin);
  g_clear_object(&self->keyboard_manager);
  if (self->keymap_keys_changed_cb_id != 0) {
    g_signal_handler_disconnect(self->keymap, self->keymap_keys_changed_cb_id);
    self->keymap_keys_changed_cb_id = 0;
  }
  g_clear_object(&self->mouse_cursor_plugin);
  g_clear_object(&self->platform_plugin);
  g_list_free_full(self->gl_area_list, g_object_unref);
  self->gl_area_list = nullptr;

  G_OBJECT_CLASS(fl_view_parent_class)->dispose(object);
}

// Implements GtkWidget::realize.
static void fl_view_realize(GtkWidget* widget) {
  FlView* self = FL_VIEW(widget);
  g_autoptr(GError) error = nullptr;

  GtkAllocation allocation;
  gtk_widget_get_allocation(widget, &allocation);

  gtk_widget_set_realized(widget, TRUE);

  GdkWindowAttr attributes;
  attributes.window_type = GDK_WINDOW_CHILD;
  attributes.x = allocation.x;
  attributes.y = allocation.y;
  attributes.width = allocation.width;
  attributes.height = allocation.height;
  attributes.wclass = GDK_INPUT_OUTPUT;
  attributes.visual = gtk_widget_get_visual(widget);
  attributes.event_mask =
      gtk_widget_get_events(widget) | GDK_KEY_PRESS_MASK | GDK_KEY_RELEASE_MASK;
  gint attributes_mask = GDK_WA_X | GDK_WA_Y | GDK_WA_VISUAL;
  GdkWindow* window = gdk_window_new(gtk_widget_get_parent_window(widget),
                                     &attributes, attributes_mask);
  gtk_widget_set_window(widget, window);
  gtk_widget_register_window(widget, window);

  init_keyboard(self);

  if (!fl_renderer_start(self->renderer, self, &error)) {
    g_warning("Failed to start Flutter renderer: %s", error->message);
    return;
  }

  if (!fl_engine_start(self->engine, &error)) {
    g_warning("Failed to start Flutter engine: %s", error->message);
    return;
  }

  handle_geometry_changed(self);
}

// Implements GtkWidget::get-preferred-width
static void fl_view_get_preferred_width(GtkWidget* widget,
                                        gint* minimum,
                                        gint* natural) {
  FlView* self = FL_VIEW(widget);
  gint child_min, child_nat;

  *minimum = 0;
  *natural = 0;

  for (GList* iterator = self->children_list; iterator;
       iterator = iterator->next) {
    FlViewChild* child = reinterpret_cast<FlViewChild*>(iterator->data);

    if (!gtk_widget_get_visible(child->widget)) {
      continue;
    }

    gtk_widget_get_preferred_width(child->widget, &child_min, &child_nat);

    *minimum = MAX(*minimum, child->geometry.x + child_min);
    *natural = MAX(*natural, child->geometry.x + child_nat);
  }
}

// Implements GtkWidget::get-preferred-height
static void fl_view_get_preferred_height(GtkWidget* widget,
                                         gint* minimum,
                                         gint* natural) {
  FlView* self = FL_VIEW(widget);
  gint child_min, child_nat;

  *minimum = 0;
  *natural = 0;

  for (GList* iterator = self->children_list; iterator;
       iterator = iterator->next) {
    FlViewChild* child = reinterpret_cast<FlViewChild*>(iterator->data);

    if (!gtk_widget_get_visible(child->widget)) {
      continue;
    }

    gtk_widget_get_preferred_height(child->widget, &child_min, &child_nat);

    *minimum = MAX(*minimum, child->geometry.y + child_min);
    *natural = MAX(*natural, child->geometry.y + child_nat);
  }
}

// Implements GtkWidget::size-allocate.
static void fl_view_size_allocate(GtkWidget* widget,
                                  GtkAllocation* allocation) {
  FlView* self = FL_VIEW(widget);

  gtk_widget_set_allocation(widget, allocation);

  if (gtk_widget_get_has_window(widget)) {
    if (gtk_widget_get_realized(widget)) {
      gdk_window_move_resize(gtk_widget_get_window(widget), allocation->x,
                             allocation->y, allocation->width,
                             allocation->height);
    }
  }

  for (GList* iterator = self->children_list; iterator;
       iterator = iterator->next) {
    FlViewChild* child = reinterpret_cast<FlViewChild*>(iterator->data);
    if (!gtk_widget_get_visible(child->widget)) {
      continue;
    }

    GtkAllocation child_allocation = child->geometry;
    GtkRequisition child_requisition;
    gtk_widget_get_preferred_size(child->widget, &child_requisition, NULL);

    if (!gtk_widget_get_has_window(widget)) {
      child_allocation.x += allocation->x;
      child_allocation.y += allocation->y;
    }

    if (child_allocation.width == 0 && child_allocation.height == 0) {
      child_allocation.width = allocation->width;
      child_allocation.height = allocation->height;
    }

    gtk_widget_size_allocate(child->widget, &child_allocation);
  }

  GtkAllocation event_box_allocation = {
      .x = 0,
      .y = 0,
      .width = allocation->width,
      .height = allocation->height,
  };
  if (!gtk_widget_get_has_window(self->event_box)) {
    event_box_allocation.x += allocation->x;
    event_box_allocation.y += allocation->y;
  }
  gtk_widget_size_allocate(self->event_box, &event_box_allocation);

  handle_geometry_changed(self);
}

struct _ReorderData {
  GdkWindow* parent_window;
  GdkWindow* last_window;
};

static void fl_view_reorder_forall(GtkWidget* widget, gpointer user_data) {
  _ReorderData* data = reinterpret_cast<_ReorderData*>(user_data);
  GdkWindow* window = gtk_widget_get_window(widget);
  if (window && window != data->parent_window) {
    if (data->last_window) {
      gdk_window_restack(window, data->last_window, TRUE);
    }
    data->last_window = window;
  }
}

// Implements GtkWidget::key_press_event.
static gboolean fl_view_key_press_event(GtkWidget* widget, GdkEventKey* event) {
  FlView* self = FL_VIEW(widget);

  return fl_keyboard_manager_handle_event(
      self->keyboard_manager, fl_key_event_new_from_gdk_event(gdk_event_copy(
                                  reinterpret_cast<GdkEvent*>(event))));
}

// Implements GtkWidget::key_release_event.
static gboolean fl_view_key_release_event(GtkWidget* widget,
                                          GdkEventKey* event) {
  FlView* self = FL_VIEW(widget);
  return fl_keyboard_manager_handle_event(
      self->keyboard_manager, fl_key_event_new_from_gdk_event(gdk_event_copy(
                                  reinterpret_cast<GdkEvent*>(event))));
}

static void put_widget(FlView* self,
                       GtkWidget* widget,
                       GdkRectangle* geometry) {
  FlViewChild* child = g_new(FlViewChild, 1);
  child->widget = widget;
  child->geometry = *geometry;

  gtk_widget_set_parent(widget, GTK_WIDGET(self));
  self->children_list = g_list_append(self->children_list, child);
}

// Implements GtkContainer::add
static void fl_view_add(GtkContainer* container, GtkWidget* widget) {
  GdkRectangle geometry = {
      .x = 0,
      .y = 0,
      .width = 0,
      .height = 0,
  };
  put_widget(FL_VIEW(container), widget, &geometry);
}

// Implements GtkContainer::remove
static void fl_view_remove(GtkContainer* container, GtkWidget* widget) {
  FlView* self = FL_VIEW(container);
  for (GList* iterator = self->children_list; iterator;
       iterator = iterator->next) {
    FlViewChild* child = reinterpret_cast<FlViewChild*>(iterator->data);
    if (child->widget == widget) {
      g_object_ref(widget);
      gtk_widget_unparent(widget);
      self->children_list = g_list_remove_link(self->children_list, iterator);
      g_list_free(iterator);
      g_free(child);

      break;
    }
  }

  if (widget == GTK_WIDGET(self->event_box)) {
    g_clear_object(&self->event_box);
  }
}

// Implements GtkContainer::forall
static void fl_view_forall(GtkContainer* container,
                           gboolean include_internals,
                           GtkCallback callback,
                           gpointer callback_data) {
  FlView* self = FL_VIEW(container);
  for (GList* iterator = self->children_list; iterator;
       iterator = iterator->next) {
    FlViewChild* child = reinterpret_cast<FlViewChild*>(iterator->data);
    (*callback)(child->widget, callback_data);
  }

  if (include_internals) {
    (*callback)(self->event_box, callback_data);
  }
}

// Implements GtkContainer::child_type
static GType fl_view_child_type(GtkContainer* container) {
  return GTK_TYPE_WIDGET;
}

// Implements GtkContainer::set_child_property
static void fl_view_set_child_property(GtkContainer* container,
                                       GtkWidget* child,
                                       guint property_id,
                                       const GValue* value,
                                       GParamSpec* pspec) {}

// Implements GtkContainer::get_child_property
static void fl_view_get_child_property(GtkContainer* container,
                                       GtkWidget* child,
                                       guint property_id,
                                       GValue* value,
                                       GParamSpec* pspec) {}

static void fl_view_class_init(FlViewClass* klass) {
  GObjectClass* object_class = G_OBJECT_CLASS(klass);
  object_class->constructed = fl_view_constructed;
  object_class->set_property = fl_view_set_property;
  object_class->get_property = fl_view_get_property;
  object_class->notify = fl_view_notify;
  object_class->dispose = fl_view_dispose;

  GtkWidgetClass* widget_class = GTK_WIDGET_CLASS(klass);
  widget_class->realize = fl_view_realize;
  widget_class->get_preferred_width = fl_view_get_preferred_width;
  widget_class->get_preferred_height = fl_view_get_preferred_height;
  widget_class->size_allocate = fl_view_size_allocate;
  widget_class->key_press_event = fl_view_key_press_event;
  widget_class->key_release_event = fl_view_key_release_event;

  GtkContainerClass* container_class = GTK_CONTAINER_CLASS(klass);
  container_class->add = fl_view_add;
  container_class->remove = fl_view_remove;
  container_class->forall = fl_view_forall;
  container_class->child_type = fl_view_child_type;
  container_class->set_child_property = fl_view_set_child_property;
  container_class->get_child_property = fl_view_get_child_property;

  g_object_class_install_property(
      G_OBJECT_CLASS(klass), kPropFlutterProject,
      g_param_spec_object(
          "flutter-project", "flutter-project", "Flutter project in use",
          fl_dart_project_get_type(),
          static_cast<GParamFlags>(G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY |
                                   G_PARAM_STATIC_STRINGS)));

  gtk_widget_class_set_accessible_type(GTK_WIDGET_CLASS(klass),
                                       fl_view_accessible_get_type());
}

static void fl_view_init(FlView* self) {
  gtk_widget_set_can_focus(GTK_WIDGET(self), TRUE);
}

G_MODULE_EXPORT FlView* fl_view_new(FlDartProject* project) {
  return static_cast<FlView*>(
      g_object_new(fl_view_get_type(), "flutter-project", project, nullptr));
}

G_MODULE_EXPORT FlEngine* fl_view_get_engine(FlView* view) {
  g_return_val_if_fail(FL_IS_VIEW(view), nullptr);
  return view->engine;
}

void fl_view_begin_frame(FlView* view) {
  g_return_if_fail(FL_IS_VIEW(view));
  FlView* self = FL_VIEW(view);

  self->used_area_list = self->gl_area_list;
  g_list_free_full(self->pending_children_list, g_free);
  self->pending_children_list = nullptr;
}

void fl_view_add_gl_area(FlView* view,
                         GdkGLContext* context,
                         FlBackingStoreProvider* texture) {
  g_return_if_fail(FL_IS_VIEW(view));

  FlGLArea* area;
  if (view->used_area_list) {
    area = reinterpret_cast<FlGLArea*>(view->used_area_list->data);
    view->used_area_list = view->used_area_list->next;
  } else {
    area = FL_GL_AREA(fl_gl_area_new(context));
    view->gl_area_list = g_list_append(view->gl_area_list, area);
  }

  gtk_widget_show(GTK_WIDGET(area));
  add_pending_child(view, GTK_WIDGET(area), nullptr);
  fl_gl_area_queue_render(area, texture);
}

void fl_view_add_widget(FlView* view,
                        GtkWidget* widget,
                        GdkRectangle* geometry) {
  gtk_widget_show(widget);
  add_pending_child(view, widget, geometry);
}

void fl_view_end_frame(FlView* view) {
  for (GList* pending_child = view->pending_children_list; pending_child;
       pending_child = pending_child->next) {
    FlViewChild* pending_view_child =
        reinterpret_cast<FlViewChild*>(pending_child->data);
    GList* child = find_child(view->children_list, pending_view_child->widget);

    if (child) {
      // existing child
      g_free(child->data);
      child->data = nullptr;
    } else {
      // newly added child
      gtk_widget_set_parent(pending_view_child->widget, GTK_WIDGET(view));
    }
  }

  for (GList* child = view->children_list; child; child = child->next) {
    FlViewChild* view_child = reinterpret_cast<FlViewChild*>(child->data);
    if (view_child) {
      // removed child
      g_object_ref(view_child->widget);
      gtk_widget_unparent(view_child->widget);
      g_free(view_child);
      child->data = nullptr;
    }
  }

  g_list_free(view->children_list);
  view->children_list = view->pending_children_list;
  view->pending_children_list = nullptr;

  struct _ReorderData data = {
      .parent_window = gtk_widget_get_window(GTK_WIDGET(view)),
      .last_window = nullptr,
  };

  gtk_container_forall(GTK_CONTAINER(view), fl_view_reorder_forall, &data);

  gtk_widget_queue_draw(GTK_WIDGET(view));
}
