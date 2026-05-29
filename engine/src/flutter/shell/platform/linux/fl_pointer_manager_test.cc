// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_pointer_manager.h"
#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"

#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "gtest/gtest.h"

class FlPointerManagerTest : public flutter::testing::LinuxTest {};

TEST_F(FlPointerManagerTest, EnterLeave) {
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

  g_autoptr(FlPointerManager) manager = fl_pointer_manager_new(42, engine);
  fl_pointer_manager_handle_enter(manager, 1234, kFlutterPointerDeviceKindMouse,
                                  1.0, 2.0, {});
  fl_pointer_manager_handle_leave(manager, 1235, kFlutterPointerDeviceKindMouse,
                                  3.0, 4.0, {});

  EXPECT_EQ(pointer_events.size(), 2u);

  EXPECT_EQ(pointer_events[0].timestamp, 1234000u);
  EXPECT_EQ(pointer_events[0].x, 1.0);
  EXPECT_EQ(pointer_events[0].y, 2.0);
  EXPECT_EQ(pointer_events[0].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[0].buttons, 0);
  EXPECT_EQ(pointer_events[0].view_id, 42);

  EXPECT_EQ(pointer_events[1].timestamp, 1235000u);
  EXPECT_EQ(pointer_events[1].x, 3.0);
  EXPECT_EQ(pointer_events[1].y, 4.0);
  EXPECT_EQ(pointer_events[1].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[1].buttons, 0);
  EXPECT_EQ(pointer_events[1].view_id, 42);
}

TEST_F(FlPointerManagerTest, EnterEnter) {
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

  g_autoptr(FlPointerManager) manager = fl_pointer_manager_new(42, engine);
  fl_pointer_manager_handle_enter(manager, 1234, kFlutterPointerDeviceKindMouse,
                                  1.0, 2.0, {});
  // Duplicate enter is ignored
  fl_pointer_manager_handle_enter(manager, 1235, kFlutterPointerDeviceKindMouse,
                                  3.0, 4.0, {});

  EXPECT_EQ(pointer_events.size(), 1u);

  EXPECT_EQ(pointer_events[0].timestamp, 1234000u);
  EXPECT_EQ(pointer_events[0].x, 1.0);
  EXPECT_EQ(pointer_events[0].y, 2.0);
  EXPECT_EQ(pointer_events[0].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[0].buttons, 0);
  EXPECT_EQ(pointer_events[0].view_id, 42);
}

TEST_F(FlPointerManagerTest, EnterLeaveLeave) {
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

  g_autoptr(FlPointerManager) manager = fl_pointer_manager_new(42, engine);
  fl_pointer_manager_handle_enter(manager, 1234, kFlutterPointerDeviceKindMouse,
                                  1.0, 2.0, {});
  fl_pointer_manager_handle_leave(manager, 1235, kFlutterPointerDeviceKindMouse,
                                  3.0, 4.0, {});
  // Duplicate leave is ignored
  fl_pointer_manager_handle_leave(manager, 1235, kFlutterPointerDeviceKindMouse,
                                  5.0, 6.0, {});

  EXPECT_EQ(pointer_events.size(), 2u);

  EXPECT_EQ(pointer_events[0].timestamp, 1234000u);
  EXPECT_EQ(pointer_events[0].x, 1.0);
  EXPECT_EQ(pointer_events[0].y, 2.0);
  EXPECT_EQ(pointer_events[0].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[0].buttons, 0);
  EXPECT_EQ(pointer_events[0].view_id, 42);

  EXPECT_EQ(pointer_events[1].timestamp, 1235000u);
  EXPECT_EQ(pointer_events[1].x, 3.0);
  EXPECT_EQ(pointer_events[1].y, 4.0);
  EXPECT_EQ(pointer_events[1].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[1].buttons, 0);
  EXPECT_EQ(pointer_events[1].view_id, 42);
}

TEST_F(FlPointerManagerTest, EnterButtonPress) {
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

  g_autoptr(FlPointerManager) manager = fl_pointer_manager_new(42, engine);
  fl_pointer_manager_handle_enter(manager, 1234, kFlutterPointerDeviceKindMouse,
                                  1.0, 2.0, {});
  fl_pointer_manager_handle_button_press(manager, 1235,
                                         kFlutterPointerDeviceKindMouse, 4.0,
                                         8.0, GDK_BUTTON_PRIMARY, {});

  EXPECT_EQ(pointer_events.size(), 2u);

  EXPECT_EQ(pointer_events[0].timestamp, 1234000u);
  EXPECT_EQ(pointer_events[0].x, 1.0);
  EXPECT_EQ(pointer_events[0].y, 2.0);
  EXPECT_EQ(pointer_events[0].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[0].buttons, 0);
  EXPECT_EQ(pointer_events[0].view_id, 42);

  EXPECT_EQ(pointer_events[1].timestamp, 1235000u);
  EXPECT_EQ(pointer_events[1].x, 4.0);
  EXPECT_EQ(pointer_events[1].y, 8.0);
  EXPECT_EQ(pointer_events[1].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[1].buttons, kFlutterPointerButtonMousePrimary);
  EXPECT_EQ(pointer_events[1].view_id, 42);
}

TEST_F(FlPointerManagerTest, NoEnterButtonPress) {
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

  g_autoptr(FlPointerManager) manager = fl_pointer_manager_new(42, engine);
  fl_pointer_manager_handle_button_press(manager, 1234,
                                         kFlutterPointerDeviceKindMouse, 4.0,
                                         8.0, GDK_BUTTON_PRIMARY, {});

  EXPECT_EQ(pointer_events.size(), 2u);

  // Synthetic enter events
  EXPECT_EQ(pointer_events[0].timestamp, 1234000u);
  EXPECT_EQ(pointer_events[0].x, 4.0);
  EXPECT_EQ(pointer_events[0].y, 8.0);
  EXPECT_EQ(pointer_events[0].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[0].buttons, 0);
  EXPECT_EQ(pointer_events[0].view_id, 42);

  EXPECT_EQ(pointer_events[1].timestamp, 1234000u);
  EXPECT_EQ(pointer_events[1].x, 4.0);
  EXPECT_EQ(pointer_events[1].y, 8.0);
  EXPECT_EQ(pointer_events[1].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[1].buttons, kFlutterPointerButtonMousePrimary);
  EXPECT_EQ(pointer_events[1].view_id, 42);
}

TEST_F(FlPointerManagerTest, ButtonPressButtonReleasePrimary) {
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

  g_autoptr(FlPointerManager) manager = fl_pointer_manager_new(42, engine);
  fl_pointer_manager_handle_button_press(manager, 1234,
                                         kFlutterPointerDeviceKindMouse, 4.0,
                                         8.0, GDK_BUTTON_PRIMARY, {});
  fl_pointer_manager_handle_button_release(manager, 1235,
                                           kFlutterPointerDeviceKindMouse, 5.0,
                                           9.0, GDK_BUTTON_PRIMARY, {});

  EXPECT_EQ(pointer_events.size(), 3u);

  // Ignore first synthetic enter event
  EXPECT_EQ(pointer_events[1].timestamp, 1234000u);
  EXPECT_EQ(pointer_events[1].x, 4.0);
  EXPECT_EQ(pointer_events[1].y, 8.0);
  EXPECT_EQ(pointer_events[1].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[1].buttons, kFlutterPointerButtonMousePrimary);
  EXPECT_EQ(pointer_events[1].view_id, 42);
  EXPECT_EQ(pointer_events[2].timestamp, 1235000u);
  EXPECT_EQ(pointer_events[2].x, 5.0);
  EXPECT_EQ(pointer_events[2].y, 9.0);
  EXPECT_EQ(pointer_events[2].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[2].buttons, 0);
  EXPECT_EQ(pointer_events[2].view_id, 42);
}

TEST_F(FlPointerManagerTest, ButtonPressButtonReleaseSecondary) {
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

  g_autoptr(FlPointerManager) manager = fl_pointer_manager_new(42, engine);
  fl_pointer_manager_handle_button_press(manager, 1234,
                                         kFlutterPointerDeviceKindMouse, 4.0,
                                         8.0, GDK_BUTTON_SECONDARY, {});
  fl_pointer_manager_handle_button_release(manager, 1235,
                                           kFlutterPointerDeviceKindMouse, 5.0,
                                           9.0, GDK_BUTTON_SECONDARY, {});

  EXPECT_EQ(pointer_events.size(), 3u);

  // Ignore first synthetic enter event
  EXPECT_EQ(pointer_events[1].timestamp, 1234000u);
  EXPECT_EQ(pointer_events[1].x, 4.0);
  EXPECT_EQ(pointer_events[1].y, 8.0);
  EXPECT_EQ(pointer_events[1].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[1].buttons, kFlutterPointerButtonMouseSecondary);
  EXPECT_EQ(pointer_events[1].view_id, 42);
  EXPECT_EQ(pointer_events[2].timestamp, 1235000u);
  EXPECT_EQ(pointer_events[2].x, 5.0);
  EXPECT_EQ(pointer_events[2].y, 9.0);
  EXPECT_EQ(pointer_events[2].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[2].buttons, 0);
  EXPECT_EQ(pointer_events[2].view_id, 42);
}

TEST_F(FlPointerManagerTest, ButtonPressButtonReleaseMiddle) {
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

  g_autoptr(FlPointerManager) manager = fl_pointer_manager_new(42, engine);
  fl_pointer_manager_handle_button_press(manager, 1234,
                                         kFlutterPointerDeviceKindMouse, 4.0,
                                         8.0, GDK_BUTTON_MIDDLE, {});
  fl_pointer_manager_handle_button_release(manager, 1235,
                                           kFlutterPointerDeviceKindMouse, 5.0,
                                           9.0, GDK_BUTTON_MIDDLE, {});

  EXPECT_EQ(pointer_events.size(), 3u);

  // Ignore first synthetic enter event
  EXPECT_EQ(pointer_events[1].timestamp, 1234000u);
  EXPECT_EQ(pointer_events[1].x, 4.0);
  EXPECT_EQ(pointer_events[1].y, 8.0);
  EXPECT_EQ(pointer_events[1].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[1].buttons, kFlutterPointerButtonMouseMiddle);
  EXPECT_EQ(pointer_events[1].view_id, 42);
  EXPECT_EQ(pointer_events[2].timestamp, 1235000u);
  EXPECT_EQ(pointer_events[2].x, 5.0);
  EXPECT_EQ(pointer_events[2].y, 9.0);
  EXPECT_EQ(pointer_events[2].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[2].buttons, 0);
  EXPECT_EQ(pointer_events[2].view_id, 42);
}

TEST_F(FlPointerManagerTest, ButtonPressButtonReleaseBack) {
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

  // Forward button is 8 (no GDK define).
  g_autoptr(FlPointerManager) manager = fl_pointer_manager_new(42, engine);
  fl_pointer_manager_handle_button_press(
      manager, 1234, kFlutterPointerDeviceKindMouse, 4.0, 8.0, 8, {});
  fl_pointer_manager_handle_button_release(
      manager, 1235, kFlutterPointerDeviceKindMouse, 5.0, 9.0, 8, {});

  EXPECT_EQ(pointer_events.size(), 3u);

  // Ignore first synthetic enter event
  EXPECT_EQ(pointer_events[1].timestamp, 1234000u);
  EXPECT_EQ(pointer_events[1].x, 4.0);
  EXPECT_EQ(pointer_events[1].y, 8.0);
  EXPECT_EQ(pointer_events[1].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[1].buttons, kFlutterPointerButtonMouseBack);
  EXPECT_EQ(pointer_events[1].view_id, 42);
  EXPECT_EQ(pointer_events[2].timestamp, 1235000u);
  EXPECT_EQ(pointer_events[2].x, 5.0);
  EXPECT_EQ(pointer_events[2].y, 9.0);
  EXPECT_EQ(pointer_events[2].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[2].buttons, 0);
  EXPECT_EQ(pointer_events[2].view_id, 42);
}

TEST_F(FlPointerManagerTest, ButtonPressButtonReleaseForward) {
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

  // Forward button is 9 (no GDK define).
  g_autoptr(FlPointerManager) manager = fl_pointer_manager_new(42, engine);
  fl_pointer_manager_handle_button_press(
      manager, 1234, kFlutterPointerDeviceKindMouse, 4.0, 8.0, 9, {});
  fl_pointer_manager_handle_button_release(
      manager, 1235, kFlutterPointerDeviceKindMouse, 5.0, 9.0, 9, {});

  EXPECT_EQ(pointer_events.size(), 3u);

  // Ignore first synthetic enter event
  EXPECT_EQ(pointer_events[1].timestamp, 1234000u);
  EXPECT_EQ(pointer_events[1].x, 4.0);
  EXPECT_EQ(pointer_events[1].y, 8.0);
  EXPECT_EQ(pointer_events[1].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[1].buttons, kFlutterPointerButtonMouseForward);
  EXPECT_EQ(pointer_events[1].view_id, 42);
  EXPECT_EQ(pointer_events[2].timestamp, 1235000u);
  EXPECT_EQ(pointer_events[2].x, 5.0);
  EXPECT_EQ(pointer_events[2].y, 9.0);
  EXPECT_EQ(pointer_events[2].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[2].buttons, 0);
  EXPECT_EQ(pointer_events[2].view_id, 42);
}

TEST_F(FlPointerManagerTest, ButtonPressButtonReleaseThreeButtons) {
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

  g_autoptr(FlPointerManager) manager = fl_pointer_manager_new(42, engine);
  // Press buttons 1-2-3, release 3-2-1
  fl_pointer_manager_handle_button_press(manager, 1234,
                                         kFlutterPointerDeviceKindMouse, 1.0,
                                         2.0, GDK_BUTTON_PRIMARY, {});
  fl_pointer_manager_handle_button_press(manager, 1235,
                                         kFlutterPointerDeviceKindMouse, 3.0,
                                         4.0, GDK_BUTTON_SECONDARY, {});
  fl_pointer_manager_handle_button_press(manager, 1236,
                                         kFlutterPointerDeviceKindMouse, 5.0,
                                         6.0, GDK_BUTTON_MIDDLE, {});
  fl_pointer_manager_handle_button_release(manager, 1237,
                                           kFlutterPointerDeviceKindMouse, 7.0,
                                           8.0, GDK_BUTTON_MIDDLE, {});
  fl_pointer_manager_handle_button_release(manager, 1238,
                                           kFlutterPointerDeviceKindMouse, 9.0,
                                           10.0, GDK_BUTTON_SECONDARY, {});
  fl_pointer_manager_handle_button_release(
      manager, 1239, kFlutterPointerDeviceKindMouse, 11.0, 12.0,
      kFlutterPointerButtonMousePrimary, {});

  EXPECT_EQ(pointer_events.size(), 7u);

  // Ignore first synthetic enter event
  EXPECT_EQ(pointer_events[1].timestamp, 1234000u);
  EXPECT_EQ(pointer_events[1].x, 1.0);
  EXPECT_EQ(pointer_events[1].y, 2.0);
  EXPECT_EQ(pointer_events[1].buttons, kFlutterPointerButtonMousePrimary);
  EXPECT_EQ(pointer_events[2].timestamp, 1235000u);
  EXPECT_EQ(pointer_events[2].x, 3.0);
  EXPECT_EQ(pointer_events[2].y, 4.0);
  EXPECT_EQ(pointer_events[2].buttons, kFlutterPointerButtonMousePrimary |
                                           kFlutterPointerButtonMouseSecondary);
  EXPECT_EQ(pointer_events[3].timestamp, 1236000u);
  EXPECT_EQ(pointer_events[3].x, 5.0);
  EXPECT_EQ(pointer_events[3].y, 6.0);
  EXPECT_EQ(pointer_events[3].buttons, kFlutterPointerButtonMousePrimary |
                                           kFlutterPointerButtonMouseSecondary |
                                           kFlutterPointerButtonMouseMiddle);
  EXPECT_EQ(pointer_events[4].timestamp, 1237000u);
  EXPECT_EQ(pointer_events[4].x, 7.0);
  EXPECT_EQ(pointer_events[4].y, 8.0);
  EXPECT_EQ(pointer_events[4].buttons, kFlutterPointerButtonMousePrimary |
                                           kFlutterPointerButtonMouseSecondary);
  EXPECT_EQ(pointer_events[5].timestamp, 1238000u);
  EXPECT_EQ(pointer_events[5].x, 9.0);
  EXPECT_EQ(pointer_events[5].y, 10.0);
  EXPECT_EQ(pointer_events[5].buttons, kFlutterPointerButtonMousePrimary);
  EXPECT_EQ(pointer_events[6].timestamp, 1239000u);
  EXPECT_EQ(pointer_events[6].x, 11.0);
  EXPECT_EQ(pointer_events[6].y, 12.0);
  EXPECT_EQ(pointer_events[6].buttons, 0);
}

TEST_F(FlPointerManagerTest, ButtonPressStylusPrimaryButton) {
  StartEngine();

  constexpr int64_t kStylusContact = 1 << 0;
  constexpr int64_t kStylusPrimary = 1 << 1;

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

  g_autoptr(FlPointerManager) manager = fl_pointer_manager_new(42, engine);
  FlPointerDeviceState device_state = {};
  device_state.pressure = 0.5;
  fl_pointer_manager_handle_button_press(manager, 1234,
                                         kFlutterPointerDeviceKindStylus, 4.0,
                                         8.0, GDK_BUTTON_PRIMARY, device_state);
  fl_pointer_manager_handle_button_press(
      manager, 1235, kFlutterPointerDeviceKindStylus, 4.0, 8.0,
      GDK_BUTTON_SECONDARY, device_state);

  EXPECT_EQ(pointer_events.size(), 3u);
  EXPECT_EQ(pointer_events[2].device_kind, kFlutterPointerDeviceKindStylus);
  EXPECT_EQ(pointer_events[2].buttons, kStylusContact | kStylusPrimary);
}

TEST_F(FlPointerManagerTest, ButtonPressStylusContact) {
  StartEngine();

  constexpr int64_t kStylusContact = 1 << 0;

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

  g_autoptr(FlPointerManager) manager = fl_pointer_manager_new(42, engine);
  FlPointerDeviceState device_state = {};
  device_state.pressure = 0.5;
  fl_pointer_manager_handle_button_press(manager, 1234,
                                         kFlutterPointerDeviceKindStylus, 4.0,
                                         8.0, GDK_BUTTON_PRIMARY, device_state);

  EXPECT_EQ(pointer_events.size(), 2u);
  EXPECT_EQ(pointer_events[1].device_kind, kFlutterPointerDeviceKindStylus);
  EXPECT_EQ(pointer_events[1].buttons, kStylusContact);
}

TEST_F(FlPointerManagerTest, ButtonPressInvertedStylusContact) {
  StartEngine();

  constexpr int64_t kStylusContact = 1 << 0;

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

  g_autoptr(FlPointerManager) manager = fl_pointer_manager_new(42, engine);
  FlPointerDeviceState device_state = {};
  device_state.pressure = 0.5;
  fl_pointer_manager_handle_button_press(
      manager, 1234, kFlutterPointerDeviceKindInvertedStylus, 4.0, 8.0,
      GDK_BUTTON_PRIMARY, device_state);

  EXPECT_EQ(pointer_events.size(), 2u);
  EXPECT_EQ(pointer_events[1].device_kind,
            kFlutterPointerDeviceKindInvertedStylus);
  EXPECT_EQ(pointer_events[1].buttons, kStylusContact);
}

TEST_F(FlPointerManagerTest, ButtonPressStylusSecondaryButton) {
  StartEngine();

  constexpr int64_t kStylusContact = 1 << 0;
  constexpr int64_t kStylusSecondary = 1 << 2;

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

  g_autoptr(FlPointerManager) manager = fl_pointer_manager_new(42, engine);
  FlPointerDeviceState device_state = {};
  device_state.pressure = 0.5;
  fl_pointer_manager_handle_button_press(manager, 1234,
                                         kFlutterPointerDeviceKindStylus, 4.0,
                                         8.0, GDK_BUTTON_PRIMARY, device_state);
  fl_pointer_manager_handle_button_press(manager, 1235,
                                         kFlutterPointerDeviceKindStylus, 4.0,
                                         8.0, GDK_BUTTON_MIDDLE, device_state);

  EXPECT_EQ(pointer_events.size(), 3u);
  EXPECT_EQ(pointer_events[2].device_kind, kFlutterPointerDeviceKindStylus);
  EXPECT_EQ(pointer_events[2].buttons, kStylusContact | kStylusSecondary);
}

TEST_F(FlPointerManagerTest, ButtonPressStylusUnknownButton) {
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

  g_autoptr(FlPointerManager) manager = fl_pointer_manager_new(42, engine);
  FlPointerDeviceState device_state = {};
  fl_pointer_manager_handle_button_press(manager, 1234,
                                         kFlutterPointerDeviceKindStylus, 4.0,
                                         8.0, 8, device_state);

  EXPECT_EQ(pointer_events.size(), 0u);
}

TEST_F(FlPointerManagerTest, ButtonPressButtonPressButtonRelease) {
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

  g_autoptr(FlPointerManager) manager = fl_pointer_manager_new(42, engine);
  fl_pointer_manager_handle_button_press(manager, 1234,
                                         kFlutterPointerDeviceKindMouse, 4.0,
                                         8.0, GDK_BUTTON_PRIMARY, {});
  // Ignore duplicate press
  fl_pointer_manager_handle_button_press(manager, 1234,
                                         kFlutterPointerDeviceKindMouse, 6.0,
                                         10.0, GDK_BUTTON_PRIMARY, {});
  fl_pointer_manager_handle_button_release(manager, 1235,
                                           kFlutterPointerDeviceKindMouse, 5.0,
                                           9.0, GDK_BUTTON_PRIMARY, {});

  EXPECT_EQ(pointer_events.size(), 3u);

  // Ignore first synthetic enter event
  EXPECT_EQ(pointer_events[1].timestamp, 1234000u);
  EXPECT_EQ(pointer_events[1].x, 4.0);
  EXPECT_EQ(pointer_events[1].y, 8.0);
  EXPECT_EQ(pointer_events[1].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[1].buttons, kFlutterPointerButtonMousePrimary);
  EXPECT_EQ(pointer_events[1].view_id, 42);
  EXPECT_EQ(pointer_events[2].timestamp, 1235000u);
  EXPECT_EQ(pointer_events[2].x, 5.0);
  EXPECT_EQ(pointer_events[2].y, 9.0);
  EXPECT_EQ(pointer_events[2].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[2].buttons, 0);
  EXPECT_EQ(pointer_events[2].view_id, 42);
}

TEST_F(FlPointerManagerTest, ButtonPressButtonReleaseButtonRelease) {
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

  g_autoptr(FlPointerManager) manager = fl_pointer_manager_new(42, engine);
  fl_pointer_manager_handle_button_press(manager, 1234,
                                         kFlutterPointerDeviceKindMouse, 4.0,
                                         8.0, GDK_BUTTON_PRIMARY, {});
  fl_pointer_manager_handle_button_release(manager, 1235,
                                           kFlutterPointerDeviceKindMouse, 5.0,
                                           9.0, GDK_BUTTON_PRIMARY, {});
  // Ignore duplicate release
  fl_pointer_manager_handle_button_release(manager, 1235,
                                           kFlutterPointerDeviceKindMouse, 6.0,
                                           10.0, GDK_BUTTON_PRIMARY, {});

  EXPECT_EQ(pointer_events.size(), 3u);

  // Ignore first synthetic enter event
  EXPECT_EQ(pointer_events[1].timestamp, 1234000u);
  EXPECT_EQ(pointer_events[1].x, 4.0);
  EXPECT_EQ(pointer_events[1].y, 8.0);
  EXPECT_EQ(pointer_events[1].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[1].buttons, kFlutterPointerButtonMousePrimary);
  EXPECT_EQ(pointer_events[1].view_id, 42);
  EXPECT_EQ(pointer_events[2].timestamp, 1235000u);
  EXPECT_EQ(pointer_events[2].x, 5.0);
  EXPECT_EQ(pointer_events[2].y, 9.0);
  EXPECT_EQ(pointer_events[2].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[2].buttons, 0);
  EXPECT_EQ(pointer_events[2].view_id, 42);
}

TEST_F(FlPointerManagerTest, NoButtonPressButtonRelease) {
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

  g_autoptr(FlPointerManager) manager = fl_pointer_manager_new(42, engine);
  // Release without associated press, will be ignored
  fl_pointer_manager_handle_button_release(manager, 1235,
                                           kFlutterPointerDeviceKindMouse, 5.0,
                                           9.0, GDK_BUTTON_PRIMARY, {});

  EXPECT_EQ(pointer_events.size(), 0u);
}

TEST_F(FlPointerManagerTest, Motion) {
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

  g_autoptr(FlPointerManager) manager = fl_pointer_manager_new(42, engine);
  fl_pointer_manager_handle_motion(
      manager, 1234, kFlutterPointerDeviceKindMouse, 1.0, 2.0, {});
  fl_pointer_manager_handle_motion(
      manager, 1235, kFlutterPointerDeviceKindMouse, 3.0, 4.0, {});
  fl_pointer_manager_handle_motion(
      manager, 1236, kFlutterPointerDeviceKindMouse, 5.0, 6.0, {});

  EXPECT_EQ(pointer_events.size(), 4u);

  // Ignore first synthetic enter event
  EXPECT_EQ(pointer_events[1].timestamp, 1234000u);
  EXPECT_EQ(pointer_events[1].x, 1.0);
  EXPECT_EQ(pointer_events[1].y, 2.0);
  EXPECT_EQ(pointer_events[1].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[1].buttons, 0);
  EXPECT_EQ(pointer_events[1].view_id, 42);
  EXPECT_EQ(pointer_events[2].timestamp, 1235000u);
  EXPECT_EQ(pointer_events[2].x, 3.0);
  EXPECT_EQ(pointer_events[2].y, 4.0);
  EXPECT_EQ(pointer_events[2].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[2].buttons, 0);
  EXPECT_EQ(pointer_events[2].view_id, 42);
  EXPECT_EQ(pointer_events[3].timestamp, 1236000u);
  EXPECT_EQ(pointer_events[3].x, 5.0);
  EXPECT_EQ(pointer_events[3].y, 6.0);
  EXPECT_EQ(pointer_events[3].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[3].buttons, 0);
  EXPECT_EQ(pointer_events[3].view_id, 42);
}

TEST_F(FlPointerManagerTest, Drag) {
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

  g_autoptr(FlPointerManager) manager = fl_pointer_manager_new(42, engine);
  fl_pointer_manager_handle_motion(
      manager, 1234, kFlutterPointerDeviceKindMouse, 1.0, 2.0, {});
  fl_pointer_manager_handle_button_press(manager, 1235,
                                         kFlutterPointerDeviceKindMouse, 3.0,
                                         4.0, GDK_BUTTON_PRIMARY, {});
  fl_pointer_manager_handle_motion(
      manager, 1236, kFlutterPointerDeviceKindMouse, 5.0, 6.0, {});
  fl_pointer_manager_handle_button_release(manager, 1237,
                                           kFlutterPointerDeviceKindMouse, 7.0,
                                           8.0, GDK_BUTTON_PRIMARY, {});
  fl_pointer_manager_handle_motion(
      manager, 1238, kFlutterPointerDeviceKindMouse, 9.0, 10.0, {});

  EXPECT_EQ(pointer_events.size(), 6u);

  // Ignore first synthetic enter event
  EXPECT_EQ(pointer_events[1].timestamp, 1234000u);
  EXPECT_EQ(pointer_events[1].x, 1.0);
  EXPECT_EQ(pointer_events[1].y, 2.0);
  EXPECT_EQ(pointer_events[1].buttons, 0);
  EXPECT_EQ(pointer_events[1].view_id, 42);
  EXPECT_EQ(pointer_events[2].timestamp, 1235000u);
  EXPECT_EQ(pointer_events[2].x, 3.0);
  EXPECT_EQ(pointer_events[2].y, 4.0);
  EXPECT_EQ(pointer_events[2].buttons, kFlutterPointerButtonMousePrimary);
  EXPECT_EQ(pointer_events[2].view_id, 42);
  EXPECT_EQ(pointer_events[3].timestamp, 1236000u);
  EXPECT_EQ(pointer_events[3].x, 5.0);
  EXPECT_EQ(pointer_events[3].y, 6.0);
  EXPECT_EQ(pointer_events[3].buttons, kFlutterPointerButtonMousePrimary);
  EXPECT_EQ(pointer_events[3].view_id, 42);
  EXPECT_EQ(pointer_events[4].timestamp, 1237000u);
  EXPECT_EQ(pointer_events[4].x, 7.0);
  EXPECT_EQ(pointer_events[4].y, 8.0);
  EXPECT_EQ(pointer_events[4].buttons, 0);
  EXPECT_EQ(pointer_events[4].view_id, 42);
  EXPECT_EQ(pointer_events[5].timestamp, 1238000u);
  EXPECT_EQ(pointer_events[5].x, 9.0);
  EXPECT_EQ(pointer_events[5].y, 10.0);
  EXPECT_EQ(pointer_events[5].buttons, 0);
  EXPECT_EQ(pointer_events[5].view_id, 42);
}

TEST_F(FlPointerManagerTest, DeviceKind) {
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

  g_autoptr(FlPointerManager) manager = fl_pointer_manager_new(42, engine);
  fl_pointer_manager_handle_enter(
      manager, 1234, kFlutterPointerDeviceKindTrackpad, 1.0, 2.0, {});
  fl_pointer_manager_handle_button_press(manager, 1235,
                                         kFlutterPointerDeviceKindTrackpad, 1.0,
                                         2.0, GDK_BUTTON_PRIMARY, {});
  fl_pointer_manager_handle_motion(
      manager, 1238, kFlutterPointerDeviceKindTrackpad, 3.0, 4.0, {});
  fl_pointer_manager_handle_button_release(manager, 1237,
                                           kFlutterPointerDeviceKindTrackpad,
                                           3.0, 4.0, GDK_BUTTON_PRIMARY, {});
  fl_pointer_manager_handle_leave(
      manager, 1235, kFlutterPointerDeviceKindTrackpad, 3.0, 4.0, {});

  EXPECT_EQ(pointer_events.size(), 5u);

  EXPECT_EQ(pointer_events[0].device_kind, kFlutterPointerDeviceKindTrackpad);
  EXPECT_EQ(pointer_events[1].device_kind, kFlutterPointerDeviceKindTrackpad);
  EXPECT_EQ(pointer_events[2].device_kind, kFlutterPointerDeviceKindTrackpad);
  EXPECT_EQ(pointer_events[3].device_kind, kFlutterPointerDeviceKindTrackpad);
  EXPECT_EQ(pointer_events[4].device_kind, kFlutterPointerDeviceKindTrackpad);
}
