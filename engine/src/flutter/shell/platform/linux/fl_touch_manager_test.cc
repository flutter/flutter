// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_touch_manager.h"
#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"

#include <gdk/gdkwayland.h>
#include <cstring>
#include <vector>

#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "gtest/gtest.h"

class FlTouchManagerTest : public flutter::testing::LinuxTest {};

TEST_F(FlTouchManagerTest, TouchEvents) {
  StartEngine();

  std::vector<FlutterPointerEvent> pointer_events;
  fl_engine_get_embedder_api(engine)->SendPointerEvent = MOCK_ENGINE_PROC(
      SendPointerEvent,
      ([&pointer_events](auto engine, const FlutterPointerEvent* events,
                         size_t events_count) {
        for (size_t i = 0; i < events_count; i++) {
          pointer_events.push_back(events[i]);
        }

        return kSuccess;
      }));

  g_autoptr(FlTouchManager) manager = fl_touch_manager_new(engine, 0);

  GdkDevice* touchscreen =
      GDK_DEVICE(g_object_new(gdk_wayland_device_get_type(), "input-source",
                              GDK_SOURCE_TOUCHSCREEN, nullptr));
  GdkEventTouch* event =
      reinterpret_cast<GdkEventTouch*>(gdk_event_new(GDK_TOUCH_BEGIN));
  event->time = 1;
  event->x = 4.0;
  event->y = 8.0;
  event->device = touchscreen;
  fl_touch_manager_handle_touch_event(manager, event, 1.0);
  EXPECT_EQ(pointer_events.size(), 2u);
  EXPECT_EQ(pointer_events[0].x, 4.0);
  EXPECT_EQ(pointer_events[0].y, 8.0);
  EXPECT_EQ(pointer_events[0].device_kind, kFlutterPointerDeviceKindTouch);
  EXPECT_EQ(pointer_events[0].timestamp,
            1000lu);  // Milliseconds -> Microseconds
  EXPECT_EQ(pointer_events[0].phase, kAdd);

  EXPECT_EQ(pointer_events[1].x, 4.0);
  EXPECT_EQ(pointer_events[1].y, 8.0);
  EXPECT_EQ(pointer_events[1].device_kind, kFlutterPointerDeviceKindTouch);
  EXPECT_EQ(pointer_events[1].timestamp,
            1000lu);  // Milliseconds -> Microseconds
  EXPECT_EQ(pointer_events[1].phase, kDown);

  event->type = GDK_TOUCH_UPDATE;
  fl_touch_manager_handle_touch_event(manager, event, 1.0);
  EXPECT_EQ(pointer_events.size(), 3u);
  EXPECT_EQ(pointer_events[2].x, 4.0);
  EXPECT_EQ(pointer_events[2].y, 8.0);
  EXPECT_EQ(pointer_events[2].device_kind, kFlutterPointerDeviceKindTouch);
  EXPECT_EQ(pointer_events[2].timestamp,
            1000lu);  // Milliseconds -> Microseconds
  EXPECT_EQ(pointer_events[2].phase, kMove);

  event->type = GDK_TOUCH_END;
  fl_touch_manager_handle_touch_event(manager, event, 1.0);
  EXPECT_EQ(pointer_events.size(), 5u);
  EXPECT_EQ(pointer_events[3].x, 4.0);
  EXPECT_EQ(pointer_events[3].y, 8.0);
  EXPECT_EQ(pointer_events[3].device_kind, kFlutterPointerDeviceKindTouch);
  EXPECT_EQ(pointer_events[3].timestamp,
            1000lu);  // Milliseconds -> Microseconds
  EXPECT_EQ(pointer_events[3].phase, kUp);

  EXPECT_EQ(pointer_events[4].x, 4.0);
  EXPECT_EQ(pointer_events[4].y, 8.0);
  EXPECT_EQ(pointer_events[4].device_kind, kFlutterPointerDeviceKindTouch);
  EXPECT_EQ(pointer_events[4].timestamp,
            1000lu);  // Milliseconds -> Microseconds
  EXPECT_EQ(pointer_events[4].phase, kRemove);
}
TEST_F(FlTouchManagerTest, TouchCancel) {
  StartEngine();

  std::vector<FlutterPointerEvent> pointer_events;
  fl_engine_get_embedder_api(engine)->SendPointerEvent = MOCK_ENGINE_PROC(
      SendPointerEvent,
      ([&pointer_events](auto engine, const FlutterPointerEvent* events,
                         size_t events_count) {
        for (size_t i = 0; i < events_count; i++) {
          pointer_events.push_back(events[i]);
        }

        return kSuccess;
      }));

  g_autoptr(FlTouchManager) manager = fl_touch_manager_new(engine, 0);

  GdkDevice* touchscreen =
      GDK_DEVICE(g_object_new(gdk_wayland_device_get_type(), "input-source",
                              GDK_SOURCE_TOUCHSCREEN, nullptr));
  GdkEventTouch* event =
      reinterpret_cast<GdkEventTouch*>(gdk_event_new(GDK_TOUCH_BEGIN));
  event->time = 1;
  event->x = 4.0;
  event->y = 8.0;
  event->device = touchscreen;
  fl_touch_manager_handle_touch_event(manager, event, 1.0);
  EXPECT_EQ(pointer_events.size(), 2u);

  // The touch sequence was aborted, e.g. the compositor started moving the
  // window.
  event->type = GDK_TOUCH_CANCEL;
  fl_touch_manager_handle_touch_event(manager, event, 1.0);
  EXPECT_EQ(pointer_events.size(), 4u);
  EXPECT_EQ(pointer_events[2].x, 4.0);
  EXPECT_EQ(pointer_events[2].y, 8.0);
  EXPECT_EQ(pointer_events[2].device_kind, kFlutterPointerDeviceKindTouch);
  EXPECT_EQ(pointer_events[2].phase, kCancel);
  EXPECT_EQ(pointer_events[3].phase, kRemove);

  // A new touch is added again.
  event->type = GDK_TOUCH_BEGIN;
  fl_touch_manager_handle_touch_event(manager, event, 1.0);
  EXPECT_EQ(pointer_events.size(), 6u);
  EXPECT_EQ(pointer_events[4].phase, kAdd);
  EXPECT_EQ(pointer_events[5].phase, kDown);
}

TEST_F(FlTouchManagerTest, GrabBroken) {
  StartEngine();

  std::vector<FlutterPointerEvent> pointer_events;
  fl_engine_get_embedder_api(engine)->SendPointerEvent = MOCK_ENGINE_PROC(
      SendPointerEvent,
      ([&pointer_events](auto engine, const FlutterPointerEvent* events,
                         size_t events_count) {
        for (size_t i = 0; i < events_count; i++) {
          pointer_events.push_back(events[i]);
        }

        return kSuccess;
      }));

  g_autoptr(FlTouchManager) manager = fl_touch_manager_new(engine, 0);

  // Nothing to do if no touches are in contact.
  fl_touch_manager_handle_grab_broken(manager, 1);
  EXPECT_EQ(pointer_events.size(), 0u);

  GdkDevice* touchscreen =
      GDK_DEVICE(g_object_new(gdk_wayland_device_get_type(), "input-source",
                              GDK_SOURCE_TOUCHSCREEN, nullptr));
  GdkEventTouch* event =
      reinterpret_cast<GdkEventTouch*>(gdk_event_new(GDK_TOUCH_BEGIN));
  event->time = 1;
  event->x = 4.0;
  event->y = 8.0;
  event->device = touchscreen;
  fl_touch_manager_handle_touch_event(manager, event, 1.0);
  event->type = GDK_TOUCH_UPDATE;
  event->x = 6.0;
  event->y = 10.0;
  fl_touch_manager_handle_touch_event(manager, event, 1.0);
  EXPECT_EQ(pointer_events.size(), 3u);

  // Events are no longer delivered to this view, so the touch is cancelled at
  // its last known location.
  fl_touch_manager_handle_grab_broken(manager, 2);
  EXPECT_EQ(pointer_events.size(), 5u);
  EXPECT_EQ(pointer_events[3].x, 6.0);
  EXPECT_EQ(pointer_events[3].y, 10.0);
  EXPECT_EQ(pointer_events[3].device_kind, kFlutterPointerDeviceKindTouch);
  EXPECT_EQ(pointer_events[3].timestamp,
            2000lu);  // Milliseconds -> Microseconds
  EXPECT_EQ(pointer_events[3].phase, kCancel);
  EXPECT_EQ(pointer_events[4].phase, kRemove);

  // The touch is not cancelled twice.
  fl_touch_manager_handle_grab_broken(manager, 3);
  EXPECT_EQ(pointer_events.size(), 5u);
}
