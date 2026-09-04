// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_touch_manager.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"

static constexpr int kMicrosecondsPerMillisecond = 1000;
static const int kMinTouchDeviceId = 0;
static const int kMaxTouchDeviceId = 128;

// State of a touch point that has been added to the engine.
typedef struct {
  // Sequence number this touch point was generated from.
  uint32_t number;

  // Last known location of this touch point.
  gdouble x;
  gdouble y;
} FlTouchPoint;

struct _FlTouchManager {
  GObject parent_instance;

  GWeakRef engine;

  FlutterViewId view_id;

  // Table of touch ID to #FlTouchPoint for the touch devices that have been
  // added to the engine.
  GHashTable* added_touch_devices;

  GHashTable* number_to_id;

  // Minimum touch device ID that can be used.
  guint min_touch_device_id;
};

G_DEFINE_TYPE(FlTouchManager, fl_touch_manager, G_TYPE_OBJECT);

static void fl_touch_manager_dispose(GObject* object) {
  FlTouchManager* self = FL_TOUCH_MANAGER(object);

  g_weak_ref_clear(&self->engine);

  g_clear_pointer(&self->added_touch_devices, g_hash_table_unref);

  g_clear_pointer(&self->number_to_id, g_hash_table_unref);

  G_OBJECT_CLASS(fl_touch_manager_parent_class)->dispose(object);
}

static void fl_touch_manager_class_init(FlTouchManagerClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_touch_manager_dispose;
}

static void fl_touch_manager_init(FlTouchManager* self) {}

FlTouchManager* fl_touch_manager_new(FlEngine* engine, FlutterViewId view_id) {
  g_return_val_if_fail(FL_IS_ENGINE(engine), nullptr);

  FlTouchManager* self =
      FL_TOUCH_MANAGER(g_object_new(fl_touch_manager_get_type(), nullptr));

  g_weak_ref_init(&self->engine, engine);
  self->view_id = view_id;

  self->number_to_id =
      g_hash_table_new_full(g_direct_hash, g_direct_equal, nullptr, nullptr);

  self->added_touch_devices =
      g_hash_table_new_full(g_direct_hash, g_direct_equal, nullptr, g_free);

  self->min_touch_device_id = kMinTouchDeviceId;

  return self;
}

// Ensures that a touch add event is sent for the given device and records the
// location of this touch point.
static void ensure_touch_added(_FlTouchManager* self,
                               guint event_time,
                               gdouble x,
                               gdouble y,
                               uint32_t number,
                               int32_t touch_id,
                               int32_t device_id) {
  FlTouchPoint* point = static_cast<FlTouchPoint*>(g_hash_table_lookup(
      self->added_touch_devices, GINT_TO_POINTER(touch_id)));
  if (point != nullptr) {
    point->x = x;
    point->y = y;
    return;
  }

  g_autoptr(FlEngine) engine = FL_ENGINE(g_weak_ref_get(&self->engine));
  if (engine == nullptr) {
    return;
  }

  fl_engine_send_touch_add_event(engine, self->view_id,
                                 event_time * kMicrosecondsPerMillisecond, x, y,
                                 device_id);

  point = g_new0(FlTouchPoint, 1);
  point->number = number;
  point->x = x;
  point->y = y;
  g_hash_table_insert(self->added_touch_devices, GINT_TO_POINTER(touch_id),
                      point);
}

// Generates a unique ID to represent |number|. The generated ID is the
// smallest available ID greater than or equal to the minimum touch device ID.
static uint32_t get_generated_id(_FlTouchManager* self, uint32_t number) {
  gpointer value;
  if (g_hash_table_lookup_extended(self->number_to_id, GUINT_TO_POINTER(number),
                                   nullptr, &value)) {
    uint32_t id;
    if (value == nullptr) {
      id = 0;
    } else {
      id = GPOINTER_TO_UINT(value);
    }
    return id;
  }
  g_autoptr(GList) values = g_hash_table_get_values(self->number_to_id);
  while (values != nullptr &&
         g_list_find(values, GUINT_TO_POINTER(self->min_touch_device_id)) !=
             nullptr &&
         self->min_touch_device_id < kMaxTouchDeviceId) {
    ++self->min_touch_device_id;
  }
  if (self->min_touch_device_id >= kMaxTouchDeviceId) {
    self->min_touch_device_id = kMinTouchDeviceId;
  }

  g_hash_table_insert(self->number_to_id, GUINT_TO_POINTER(number),
                      GUINT_TO_POINTER(self->min_touch_device_id));
  return self->min_touch_device_id;
}

static void release_number(_FlTouchManager* self, uint32_t number) {
  if (g_hash_table_contains(self->number_to_id, GINT_TO_POINTER(number))) {
    auto id = g_hash_table_lookup(self->number_to_id, GINT_TO_POINTER(number));
    if (GPOINTER_TO_UINT(id) < self->min_touch_device_id) {
      self->min_touch_device_id = GPOINTER_TO_UINT(id);
    }
    g_hash_table_remove(self->number_to_id, GINT_TO_POINTER(number));
  }
}

// Forgets a touch point that is no longer in contact with the screen.
static void remove_touch_point(_FlTouchManager* self,
                               uint32_t number,
                               uint32_t touch_id) {
  release_number(self, number);
  g_hash_table_remove(self->added_touch_devices, GINT_TO_POINTER(touch_id));
}

void fl_touch_manager_handle_touch_event(FlTouchManager* self,
                                         GdkEventTouch* touch_event,
                                         gint scale_factor) {
  g_return_if_fail(FL_IS_TOUCH_MANAGER(self));

  g_autoptr(FlEngine) engine = FL_ENGINE(g_weak_ref_get(&self->engine));
  if (engine == nullptr) {
    return;
  }

  GdkEvent* event = reinterpret_cast<GdkEvent*>(touch_event);
  // get sequence id from GdkEvent
  GdkEventSequence* seq = gdk_event_get_event_sequence(event);
  // cast pointer to int to get unique id
  uint32_t id = reinterpret_cast<uint64_t>(seq);
  // generate touch id from unique id
  auto touch_id = get_generated_id(self, id);
  // get device id
  auto device_id =
      static_cast<int32_t>(kFlutterPointerDeviceKindTouch) << 28 | touch_id;

  gdouble event_x = 0.0, event_y = 0.0;
  gdk_event_get_coords(event, &event_x, &event_y);

  double x = event_x * scale_factor;
  double y = event_y * scale_factor;

  guint event_time = gdk_event_get_time(event);

  ensure_touch_added(self, event_time, x, y, id, touch_id, device_id);

  GdkEventType touch_event_type = gdk_event_get_event_type(event);

  switch (touch_event_type) {
    case GDK_TOUCH_BEGIN:
      fl_engine_send_touch_down_event(engine, self->view_id,
                                      event_time * kMicrosecondsPerMillisecond,
                                      x, y, device_id);
      break;
    case GDK_TOUCH_UPDATE:
      fl_engine_send_touch_move_event(engine, self->view_id,
                                      event_time * kMicrosecondsPerMillisecond,
                                      x, y, device_id);
      break;
    case GDK_TOUCH_END:
      fl_engine_send_touch_up_event(engine, self->view_id,
                                    event_time * kMicrosecondsPerMillisecond, x,
                                    y, device_id);

      fl_engine_send_touch_remove_event(
          engine, self->view_id, event_time * kMicrosecondsPerMillisecond, x, y,
          device_id);
      remove_touch_point(self, id, touch_id);
      break;
    case GDK_TOUCH_CANCEL:
      // The touch sequence was aborted, e.g. the compositor took over the
      // touch to move or resize the window. No touch end event will be
      // received, so cancel the touch point here.
      fl_engine_send_touch_cancel_event(
          engine, self->view_id, event_time * kMicrosecondsPerMillisecond, x, y,
          device_id);

      fl_engine_send_touch_remove_event(
          engine, self->view_id, event_time * kMicrosecondsPerMillisecond, x, y,
          device_id);
      remove_touch_point(self, id, touch_id);
      break;
    default:
      break;
  }
}

void fl_touch_manager_handle_grab_broken(FlTouchManager* self,
                                         guint event_time) {
  g_return_if_fail(FL_IS_TOUCH_MANAGER(self));

  if (g_hash_table_size(self->added_touch_devices) == 0) {
    return;
  }

  g_autoptr(FlEngine) engine = FL_ENGINE(g_weak_ref_get(&self->engine));
  if (engine == nullptr) {
    return;
  }

  g_autoptr(GList) touch_ids = g_hash_table_get_keys(self->added_touch_devices);
  for (GList* link = touch_ids; link != nullptr; link = link->next) {
    uint32_t touch_id = GPOINTER_TO_UINT(link->data);
    FlTouchPoint* point = static_cast<FlTouchPoint*>(
        g_hash_table_lookup(self->added_touch_devices, link->data));
    int32_t device_id =
        static_cast<int32_t>(kFlutterPointerDeviceKindTouch) << 28 | touch_id;

    fl_engine_send_touch_cancel_event(engine, self->view_id,
                                      event_time * kMicrosecondsPerMillisecond,
                                      point->x, point->y, device_id);

    fl_engine_send_touch_remove_event(engine, self->view_id,
                                      event_time * kMicrosecondsPerMillisecond,
                                      point->x, point->y, device_id);

    remove_touch_point(self, point->number, touch_id);
  }
}
