// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_pointer_manager.h"

#include "flutter/shell/platform/linux/fl_engine_private.h"

static constexpr int kMicrosecondsPerMillisecond = 1000;

struct _FlPointerManager {
  GObject parent_instance;

  // Engine to send pointer events to.
  GWeakRef engine;

  // ID to mark events with.
  FlutterViewId view_id;

  // TRUE if the mouse pointer is inside the view, used for generating missing
  // add events.
  gboolean pointer_inside;

  // Pointer button state recorded for sending status updates.
  int64_t button_state;

  // TRUE if a leave event was received while a button was pressed, and the
  // matching remove event has not been sent yet.
  gboolean leave_pending;

  // Last known pointer position and device, used when synthesizing events.
  FlutterPointerDeviceKind last_device_kind;
  gdouble last_x;
  gdouble last_y;
  gdouble last_rotation;
  gdouble last_pressure;
};

G_DEFINE_TYPE(FlPointerManager, fl_pointer_manager, G_TYPE_OBJECT);

// 8 corresponds to mouse back button on both x11 and wayland
static constexpr guint kMouseButtonBack = 8;

// 9 corresponds to mouse forward button on both x11 and wayland
static constexpr guint kMouseButtonForward = 9;

// Convert a GDK button ID into a Flutter button ID
static gboolean get_mouse_button(guint gdk_button, int64_t* button) {
  switch (gdk_button) {
    case GDK_BUTTON_PRIMARY:
      *button = kFlutterPointerButtonMousePrimary;
      return TRUE;
    case GDK_BUTTON_MIDDLE:
      *button = kFlutterPointerButtonMouseMiddle;
      return TRUE;
    case GDK_BUTTON_SECONDARY:
      *button = kFlutterPointerButtonMouseSecondary;
      return TRUE;
    case kMouseButtonBack:
      *button = kFlutterPointerButtonMouseBack;
      return TRUE;
    case kMouseButtonForward:
      *button = kFlutterPointerButtonMouseForward;
      return TRUE;
    default:
      return FALSE;
  }
}

static gboolean get_button(FlutterPointerDeviceKind device_kind,
                           guint gdk_button,
                           int64_t* button) {
  if (device_kind == kFlutterPointerDeviceKindStylus ||
      device_kind == kFlutterPointerDeviceKindInvertedStylus) {
    // GDK button names describe the physical button action, where "primary"
    // is the stylus tip contact. Flutter stylus button names reserve "primary"
    // for the first barrel button, so the GDK secondary button maps there.
    switch (gdk_button) {
      case GDK_BUTTON_PRIMARY:
        *button = kFlutterPointerButtonStylusContact;
        return TRUE;
      case GDK_BUTTON_SECONDARY:
        *button = kFlutterPointerButtonStylusPrimary;
        return TRUE;
      case GDK_BUTTON_MIDDLE:
        *button = kFlutterPointerButtonStylusSecondary;
        return TRUE;
      default:
        return FALSE;
    }
  }

  return get_mouse_button(gdk_button, button);
}

// Records the most recent pointer state so that events can be synthesized
// from it later.
static void record_pointer_state(FlPointerManager* self,
                                 FlutterPointerDeviceKind device_kind,
                                 gdouble x,
                                 gdouble y,
                                 gdouble rotation,
                                 gdouble pressure) {
  self->last_device_kind = device_kind;
  self->last_x = x;
  self->last_y = y;
  self->last_rotation = rotation;
  self->last_pressure = pressure;
}

// Generates a mouse pointer event if the pointer appears inside the window.
static void ensure_pointer_added(FlPointerManager* self,
                                 guint event_time,
                                 FlutterPointerDeviceKind device_kind,
                                 gdouble x,
                                 gdouble y,
                                 gdouble rotation,
                                 gdouble pressure) {
  record_pointer_state(self, device_kind, x, y, rotation, pressure);

  // The pointer is generating events again, so it is inside the view.
  self->leave_pending = FALSE;

  if (self->pointer_inside) {
    return;
  }
  self->pointer_inside = TRUE;

  g_autoptr(FlEngine) engine = FL_ENGINE(g_weak_ref_get(&self->engine));
  if (engine == nullptr) {
    return;
  }

  fl_engine_send_mouse_pointer_event(
      engine, self->view_id, kAdd, event_time * kMicrosecondsPerMillisecond, x,
      y, device_kind, 0, 0, self->button_state, rotation, pressure);
}

static void fl_pointer_manager_dispose(GObject* object) {
  FlPointerManager* self = FL_POINTER_MANAGER(object);

  g_weak_ref_clear(&self->engine);

  G_OBJECT_CLASS(fl_pointer_manager_parent_class)->dispose(object);
}

static void fl_pointer_manager_class_init(FlPointerManagerClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_pointer_manager_dispose;
}

static void fl_pointer_manager_init(FlPointerManager* self) {
  self->last_device_kind = kFlutterPointerDeviceKindMouse;
}

FlPointerManager* fl_pointer_manager_new(FlutterViewId view_id,
                                         FlEngine* engine) {
  FlPointerManager* self =
      FL_POINTER_MANAGER(g_object_new(fl_pointer_manager_get_type(), nullptr));

  self->view_id = view_id;
  g_weak_ref_init(&self->engine, engine);

  return self;
}

gboolean fl_pointer_manager_handle_button_press(
    FlPointerManager* self,
    guint event_time,
    FlutterPointerDeviceKind device_kind,
    gdouble x,
    gdouble y,
    guint gdk_button,
    gdouble rotation,
    gdouble pressure) {
  g_return_val_if_fail(FL_IS_POINTER_MANAGER(self), FALSE);

  int64_t button;
  if (!get_button(device_kind, gdk_button, &button)) {
    return FALSE;
  }

  ensure_pointer_added(self, event_time, device_kind, x, y, rotation, pressure);

  // GDK never sends two presses of the same button without a release in
  // between, so if Flutter thinks this button is already down then the release
  // was lost, e.g. it was delivered to the window manager because it ended an
  // interactive move or resize. Cancel the stale press so this one is not
  // dropped.
  if ((self->button_state & button) != 0) {
    fl_pointer_manager_handle_grab_broken(self, event_time);
  }

  int old_button_state = self->button_state;
  FlutterPointerPhase phase = kMove;
  self->button_state ^= button;
  phase = old_button_state == 0 ? kDown : kMove;

  g_autoptr(FlEngine) engine = FL_ENGINE(g_weak_ref_get(&self->engine));
  if (engine == nullptr) {
    return FALSE;
  }

  fl_engine_send_mouse_pointer_event(
      engine, self->view_id, phase, event_time * kMicrosecondsPerMillisecond, x,
      y, device_kind, 0, 0, self->button_state, rotation, pressure);

  return TRUE;
}

gboolean fl_pointer_manager_handle_button_release(
    FlPointerManager* self,
    guint event_time,
    FlutterPointerDeviceKind device_kind,
    gdouble x,
    gdouble y,
    guint gdk_button,
    gdouble rotation,
    gdouble pressure) {
  g_return_val_if_fail(FL_IS_POINTER_MANAGER(self), FALSE);

  int64_t button;
  if (!get_button(device_kind, gdk_button, &button)) {
    return FALSE;
  }

  record_pointer_state(self, device_kind, x, y, rotation, pressure);

  // Drop the event if Flutter already thinks the button is up.
  if ((self->button_state & button) == 0) {
    return FALSE;
  }

  FlutterPointerPhase phase = kMove;
  self->button_state ^= button;

  phase = self->button_state == 0 ? kUp : kMove;

  g_autoptr(FlEngine) engine = FL_ENGINE(g_weak_ref_get(&self->engine));
  if (engine == nullptr) {
    return FALSE;
  }

  fl_engine_send_mouse_pointer_event(
      engine, self->view_id, phase, event_time * kMicrosecondsPerMillisecond, x,
      y, device_kind, 0, 0, self->button_state, rotation, pressure);

  return TRUE;
}

gboolean fl_pointer_manager_handle_motion(FlPointerManager* self,
                                          guint event_time,
                                          FlutterPointerDeviceKind device_kind,
                                          gdouble x,
                                          gdouble y,
                                          gdouble rotation,
                                          gdouble pressure) {
  g_return_val_if_fail(FL_IS_POINTER_MANAGER(self), FALSE);

  g_autoptr(FlEngine) engine = FL_ENGINE(g_weak_ref_get(&self->engine));
  if (engine == nullptr) {
    return FALSE;
  }

  ensure_pointer_added(self, event_time, device_kind, x, y, rotation, pressure);

  fl_engine_send_mouse_pointer_event(
      engine, self->view_id, self->button_state != 0 ? kMove : kHover,
      event_time * kMicrosecondsPerMillisecond, x, y, device_kind, 0, 0,
      self->button_state, rotation, pressure);

  return TRUE;
}

gboolean fl_pointer_manager_handle_enter(FlPointerManager* self,
                                         guint event_time,
                                         FlutterPointerDeviceKind device_kind,
                                         gdouble x,
                                         gdouble y,
                                         gdouble rotation,
                                         gdouble pressure) {
  g_return_val_if_fail(FL_IS_POINTER_MANAGER(self), FALSE);

  g_autoptr(FlEngine) engine = FL_ENGINE(g_weak_ref_get(&self->engine));
  if (engine == nullptr) {
    return FALSE;
  }

  ensure_pointer_added(self, event_time, device_kind, x, y, rotation, pressure);

  return TRUE;
}

gboolean fl_pointer_manager_handle_leave(FlPointerManager* self,
                                         guint event_time,
                                         FlutterPointerDeviceKind device_kind,
                                         gdouble x,
                                         gdouble y,
                                         gdouble rotation,
                                         gdouble pressure) {
  g_return_val_if_fail(FL_IS_POINTER_MANAGER(self), FALSE);

  g_autoptr(FlEngine) engine = FL_ENGINE(g_weak_ref_get(&self->engine));
  if (engine == nullptr) {
    return FALSE;
  }

  if (!self->pointer_inside) {
    return TRUE;
  }

  // Don't remove pointer while button is down; In case of dragging outside of
  // window with mouse grab active Gtk will send another leave notify on
  // release. Remember the leave so the pointer can still be removed if that
  // release is never delivered, e.g. because the grab was broken.
  if (self->button_state != 0) {
    record_pointer_state(self, device_kind, x, y, rotation, pressure);
    self->leave_pending = TRUE;
    return TRUE;
  }

  fl_engine_send_mouse_pointer_event(
      engine, self->view_id, kRemove, event_time * kMicrosecondsPerMillisecond,
      x, y, device_kind, 0, 0, self->button_state, rotation, pressure);
  self->pointer_inside = FALSE;
  self->leave_pending = FALSE;

  return TRUE;
}

gboolean fl_pointer_manager_handle_grab_broken(FlPointerManager* self,
                                               guint event_time) {
  g_return_val_if_fail(FL_IS_POINTER_MANAGER(self), FALSE);

  // Nothing to do if no buttons are pressed.
  if (self->button_state == 0) {
    return FALSE;
  }

  self->button_state = 0;

  g_autoptr(FlEngine) engine = FL_ENGINE(g_weak_ref_get(&self->engine));
  if (engine == nullptr) {
    return FALSE;
  }

  fl_engine_send_mouse_pointer_event(
      engine, self->view_id, kCancel, event_time * kMicrosecondsPerMillisecond,
      self->last_x, self->last_y, self->last_device_kind, 0, 0,
      self->button_state, self->last_rotation, self->last_pressure);

  // The pointer left the view while the button was down, so the remove event
  // was delayed until the button was released. That release will never
  // arrive, so remove the pointer now.
  if (self->leave_pending) {
    fl_engine_send_mouse_pointer_event(
        engine, self->view_id, kRemove,
        event_time * kMicrosecondsPerMillisecond, self->last_x, self->last_y,
        self->last_device_kind, 0, 0, self->button_state, self->last_rotation,
        self->last_pressure);
    self->pointer_inside = FALSE;
    self->leave_pending = FALSE;
  }

  return TRUE;
}
