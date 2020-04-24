// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"

#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_renderer_x11.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_engine.h"

#include <gdk/gdkx.h>

static constexpr int kMicrosecondsPerMillisecond = 1000;

struct _FlView {
  GtkWidget parent_instance;

  FlDartProject* project;
  FlEngine* engine;
  int64_t button_state;
};

enum { PROP_FLUTTER_PROJECT = 1, PROP_LAST };

G_DEFINE_TYPE(FlView, fl_view, GTK_TYPE_WIDGET)

// Convert a GDK button event into a Flutter event and send to the engine
static gboolean fl_view_send_pointer_button_event(FlView* self,
                                                  GdkEventButton* event) {
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
  FlutterPointerPhase phase;
  if (event->type == GDK_BUTTON_PRESS) {
    // Drop the event if Flutter already thinks the button is down
    if ((self->button_state & button) != 0)
      return FALSE;
    self->button_state ^= button;

    phase = old_button_state == 0 ? kDown : kMove;
  } else if (event->type == GDK_BUTTON_RELEASE) {
    // Drop the event if Flutter already thinks the button is up
    if ((self->button_state & button) == 0)
      return FALSE;
    self->button_state ^= button;

    phase = self->button_state == 0 ? kUp : kMove;
  }

  if (self->engine == nullptr)
    return FALSE;

  fl_engine_send_mouse_pointer_event(self->engine, phase,
                                     event->time * kMicrosecondsPerMillisecond,
                                     event->x, event->y, self->button_state);
  return TRUE;
}

static void fl_view_set_property(GObject* object,
                                 guint prop_id,
                                 const GValue* value,
                                 GParamSpec* pspec) {
  FlView* self = FL_VIEW(object);

  switch (prop_id) {
    case PROP_FLUTTER_PROJECT:
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
    case PROP_FLUTTER_PROJECT:
      g_value_set_object(value, self->project);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID(object, prop_id, pspec);
      break;
  }
}

static void fl_view_dispose(GObject* object) {
  FlView* self = FL_VIEW(object);

  g_clear_object(&self->project);
  g_clear_object(&self->engine);

  G_OBJECT_CLASS(fl_view_parent_class)->dispose(object);
}

static void fl_view_realize(GtkWidget* widget) {
  FlView* self = FL_VIEW(widget);

  gtk_widget_set_realized(widget, TRUE);

  GtkAllocation allocation;
  gtk_widget_get_allocation(widget, &allocation);

  GdkWindowAttr window_attributes;
  window_attributes.window_type = GDK_WINDOW_CHILD;
  window_attributes.x = allocation.x;
  window_attributes.y = allocation.y;
  window_attributes.width = allocation.width;
  window_attributes.height = allocation.height;
  window_attributes.wclass = GDK_INPUT_OUTPUT;
  window_attributes.visual = gtk_widget_get_visual(widget);
  window_attributes.event_mask =
      gtk_widget_get_events(widget) | GDK_EXPOSURE_MASK |
      GDK_POINTER_MOTION_MASK | GDK_BUTTON_PRESS_MASK | GDK_BUTTON_RELEASE_MASK;

  gint window_attributes_mask = GDK_WA_X | GDK_WA_Y | GDK_WA_VISUAL;

  GdkWindow* window =
      gdk_window_new(gtk_widget_get_parent_window(widget), &window_attributes,
                     window_attributes_mask);
  gtk_widget_register_window(widget, window);
  gtk_widget_set_window(widget, window);

  Window xid = gdk_x11_window_get_xid(gtk_widget_get_window(GTK_WIDGET(self)));
  g_autoptr(FlRendererX11) renderer = fl_renderer_x11_new(xid);
  self->engine = fl_engine_new(self->project, FL_RENDERER(renderer));
  g_autoptr(GError) error = nullptr;
  if (!fl_engine_start(self->engine, &error))
    g_printerr("Failed to start Flutter engine: %s", error->message);
}

static void fl_view_size_allocate(GtkWidget* widget,
                                  GtkAllocation* allocation) {
  FlView* self = FL_VIEW(widget);

  gtk_widget_set_allocation(widget, allocation);

  if (gtk_widget_get_realized(widget) && gtk_widget_get_has_window(widget))
    gdk_window_move_resize(gtk_widget_get_window(widget), allocation->x,
                           allocation->y, allocation->width,
                           allocation->height);

  // TODO(robert-ancell): This pixel ratio won't work on hidpi displays
  fl_engine_send_window_metrics_event(self->engine, allocation->width,
                                      allocation->height, 1);
}

static gboolean fl_view_button_press_event(GtkWidget* widget,
                                           GdkEventButton* event) {
  FlView* self = FL_VIEW(widget);

  // Flutter doesn't handle double and triple click events
  if (event->type == GDK_DOUBLE_BUTTON_PRESS ||
      event->type == GDK_TRIPLE_BUTTON_PRESS)
    return FALSE;

  return fl_view_send_pointer_button_event(self, event);
}

static gboolean fl_view_button_release_event(GtkWidget* widget,
                                             GdkEventButton* event) {
  FlView* self = FL_VIEW(widget);

  return fl_view_send_pointer_button_event(self, event);
}

static gboolean fl_view_motion_notify_event(GtkWidget* widget,
                                            GdkEventMotion* event) {
  FlView* self = FL_VIEW(widget);

  if (self->engine == nullptr)
    return FALSE;

  fl_engine_send_mouse_pointer_event(self->engine,
                                     self->button_state != 0 ? kMove : kHover,
                                     event->time * kMicrosecondsPerMillisecond,
                                     event->x, event->y, self->button_state);

  return TRUE;
}

static void fl_view_class_init(FlViewClass* klass) {
  G_OBJECT_CLASS(klass)->set_property = fl_view_set_property;
  G_OBJECT_CLASS(klass)->get_property = fl_view_get_property;
  G_OBJECT_CLASS(klass)->dispose = fl_view_dispose;
  GTK_WIDGET_CLASS(klass)->realize = fl_view_realize;
  GTK_WIDGET_CLASS(klass)->size_allocate = fl_view_size_allocate;
  GTK_WIDGET_CLASS(klass)->button_press_event = fl_view_button_press_event;
  GTK_WIDGET_CLASS(klass)->button_release_event = fl_view_button_release_event;
  GTK_WIDGET_CLASS(klass)->motion_notify_event = fl_view_motion_notify_event;

  g_object_class_install_property(
      G_OBJECT_CLASS(klass), PROP_FLUTTER_PROJECT,
      g_param_spec_object(
          "flutter-project", "flutter-project", "Flutter project in use",
          fl_dart_project_get_type(),
          static_cast<GParamFlags>(G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY |
                                   G_PARAM_STATIC_STRINGS)));
}

static void fl_view_init(FlView* self) {}

G_MODULE_EXPORT FlView* fl_view_new(FlDartProject* project) {
  return static_cast<FlView*>(
      g_object_new(fl_view_get_type(), "flutter-project", project, nullptr));
}

G_MODULE_EXPORT FlEngine* fl_view_get_engine(FlView* view) {
  g_return_val_if_fail(FL_IS_VIEW(view), nullptr);
  return view->engine;
}
