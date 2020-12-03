// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Included first as it collides with the X11 headers.
#include "gtest/gtest.h"

#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_engine.h"
#include "flutter/shell/platform/linux/testing/fl_test.h"

// Checks sending window metrics events works.
TEST(FlEngineTest, WindowMetrics) {
  g_autoptr(FlEngine) engine = make_mock_engine();
  FlutterEngineProcTable* embedder_api = fl_engine_get_embedder_api(engine);

  bool called = false;
  embedder_api->SendWindowMetricsEvent = MOCK_ENGINE_PROC(
      SendWindowMetricsEvent,
      ([&called](auto engine, const FlutterWindowMetricsEvent* event) {
        called = true;
        EXPECT_EQ(event->width, static_cast<size_t>(3840));
        EXPECT_EQ(event->height, static_cast<size_t>(2160));
        EXPECT_EQ(event->pixel_ratio, 2.0);

        return kSuccess;
      }));

  g_autoptr(GError) error = nullptr;
  EXPECT_TRUE(fl_engine_start(engine, &error));
  EXPECT_EQ(error, nullptr);
  fl_engine_send_window_metrics_event(engine, 3840, 2160, 2.0);

  EXPECT_TRUE(called);
}

// Checks sending mouse pointer events works.
TEST(FlEngineTest, MousePointer) {
  g_autoptr(FlEngine) engine = make_mock_engine();
  FlutterEngineProcTable* embedder_api = fl_engine_get_embedder_api(engine);

  bool called = false;
  embedder_api->SendPointerEvent = MOCK_ENGINE_PROC(
      SendPointerEvent,
      ([&called](auto engine, const FlutterPointerEvent* events,
                 size_t events_count) {
        called = true;
        EXPECT_EQ(events_count, static_cast<size_t>(1));
        EXPECT_EQ(events[0].phase, kDown);
        EXPECT_EQ(events[0].timestamp, static_cast<size_t>(1234567890));
        EXPECT_EQ(events[0].x, 800);
        EXPECT_EQ(events[0].y, 600);
        EXPECT_EQ(events[0].device, static_cast<int32_t>(0));
        EXPECT_EQ(events[0].signal_kind, kFlutterPointerSignalKindScroll);
        EXPECT_EQ(events[0].scroll_delta_x, 1.2);
        EXPECT_EQ(events[0].scroll_delta_y, -3.4);
        EXPECT_EQ(events[0].device_kind, kFlutterPointerDeviceKindMouse);
        EXPECT_EQ(events[0].buttons, kFlutterPointerButtonMouseSecondary);

        return kSuccess;
      }));

  g_autoptr(GError) error = nullptr;
  EXPECT_TRUE(fl_engine_start(engine, &error));
  EXPECT_EQ(error, nullptr);
  fl_engine_send_mouse_pointer_event(engine, kDown, 1234567890, 800, 600, 1.2,
                                     -3.4, kFlutterPointerButtonMouseSecondary);

  EXPECT_TRUE(called);
}

// Checks sending platform messages works.
TEST(FlEngineTest, PlatformMessage) {
  g_autoptr(FlEngine) engine = make_mock_engine();
  FlutterEngineProcTable* embedder_api = fl_engine_get_embedder_api(engine);

  bool called = false;
  embedder_api->SendPlatformMessage = MOCK_ENGINE_PROC(
      SendPlatformMessage,
      ([&called](auto engine, const FlutterPlatformMessage* message) {
        called = true;

        EXPECT_STREQ(message->channel, "test");
        EXPECT_EQ(message->message_size, static_cast<size_t>(4));
        EXPECT_EQ(message->message[0], 't');
        EXPECT_EQ(message->message[1], 'e');
        EXPECT_EQ(message->message[2], 's');
        EXPECT_EQ(message->message[3], 't');

        return kSuccess;
      }));

  g_autoptr(GError) error = nullptr;
  EXPECT_TRUE(fl_engine_start(engine, &error));
  EXPECT_EQ(error, nullptr);
  g_autoptr(GBytes) message = g_bytes_new_static("test", 4);
  fl_engine_send_platform_message(engine, "test", message, nullptr, nullptr,
                                  nullptr);

  EXPECT_TRUE(called);
}

// Checks sending platform message responses works.
TEST(FlEngineTest, PlatformMessageResponse) {
  g_autoptr(FlEngine) engine = make_mock_engine();
  FlutterEngineProcTable* embedder_api = fl_engine_get_embedder_api(engine);

  bool called = false;
  embedder_api->SendPlatformMessageResponse = MOCK_ENGINE_PROC(
      SendPlatformMessageResponse,
      ([&called](auto engine,
                 const FlutterPlatformMessageResponseHandle* handle,
                 const uint8_t* data, size_t data_length) {
        called = true;

        EXPECT_EQ(
            handle,
            reinterpret_cast<const FlutterPlatformMessageResponseHandle*>(42));
        EXPECT_EQ(data_length, static_cast<size_t>(4));
        EXPECT_EQ(data[0], 't');
        EXPECT_EQ(data[1], 'e');
        EXPECT_EQ(data[2], 's');
        EXPECT_EQ(data[3], 't');

        return kSuccess;
      }));

  g_autoptr(GError) error = nullptr;
  EXPECT_TRUE(fl_engine_start(engine, &error));
  EXPECT_EQ(error, nullptr);
  g_autoptr(GBytes) response = g_bytes_new_static("test", 4);
  EXPECT_TRUE(fl_engine_send_platform_message_response(
      engine, reinterpret_cast<const FlutterPlatformMessageResponseHandle*>(42),
      response, &error));
  EXPECT_EQ(error, nullptr);

  EXPECT_TRUE(called);
}
