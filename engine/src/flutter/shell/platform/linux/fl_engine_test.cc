// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Included first as it collides with the X11 headers.
#include "gtest/gtest.h"

#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_engine.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_json_message_codec.h"
#include "flutter/shell/platform/linux/testing/fl_test.h"

// MOCK_ENGINE_PROC is leaky by design
// NOLINTBEGIN(clang-analyzer-core.StackAddressEscape)

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

// Checks sending pan/zoom events works.
TEST(FlEngineTest, PointerPanZoom) {
  g_autoptr(FlEngine) engine = make_mock_engine();
  FlutterEngineProcTable* embedder_api = fl_engine_get_embedder_api(engine);

  bool called = false;
  embedder_api->SendPointerEvent = MOCK_ENGINE_PROC(
      SendPointerEvent,
      ([&called](auto engine, const FlutterPointerEvent* events,
                 size_t events_count) {
        called = true;
        EXPECT_EQ(events_count, static_cast<size_t>(1));
        EXPECT_EQ(events[0].phase, kPanZoomUpdate);
        EXPECT_EQ(events[0].timestamp, static_cast<size_t>(1234567890));
        EXPECT_EQ(events[0].x, 800);
        EXPECT_EQ(events[0].y, 600);
        EXPECT_EQ(events[0].device, static_cast<int32_t>(1));
        EXPECT_EQ(events[0].signal_kind, kFlutterPointerSignalKindNone);
        EXPECT_EQ(events[0].pan_x, 1.5);
        EXPECT_EQ(events[0].pan_y, 2.5);
        EXPECT_EQ(events[0].scale, 3.5);
        EXPECT_EQ(events[0].rotation, 4.5);
        EXPECT_EQ(events[0].device_kind, kFlutterPointerDeviceKindTrackpad);
        EXPECT_EQ(events[0].buttons, 0);

        return kSuccess;
      }));

  g_autoptr(GError) error = nullptr;
  EXPECT_TRUE(fl_engine_start(engine, &error));
  EXPECT_EQ(error, nullptr);
  fl_engine_send_pointer_pan_zoom_event(engine, 1234567890, 800, 600,
                                        kPanZoomUpdate, 1.5, 2.5, 3.5, 4.5);

  EXPECT_TRUE(called);
}

// Checks dispatching a semantics action works.
TEST(FlEngineTest, DispatchSemanticsAction) {
  g_autoptr(FlEngine) engine = make_mock_engine();
  FlutterEngineProcTable* embedder_api = fl_engine_get_embedder_api(engine);

  bool called = false;
  embedder_api->DispatchSemanticsAction = MOCK_ENGINE_PROC(
      DispatchSemanticsAction,
      ([&called](auto engine, uint64_t id, FlutterSemanticsAction action,
                 const uint8_t* data, size_t data_length) {
        EXPECT_EQ(id, static_cast<uint64_t>(42));
        EXPECT_EQ(action, kFlutterSemanticsActionTap);
        EXPECT_EQ(data_length, static_cast<size_t>(4));
        EXPECT_EQ(data[0], 't');
        EXPECT_EQ(data[1], 'e');
        EXPECT_EQ(data[2], 's');
        EXPECT_EQ(data[3], 't');
        called = true;

        return kSuccess;
      }));

  g_autoptr(GError) error = nullptr;
  EXPECT_TRUE(fl_engine_start(engine, &error));
  EXPECT_EQ(error, nullptr);
  g_autoptr(GBytes) data = g_bytes_new_static("test", 4);
  fl_engine_dispatch_semantics_action(engine, 42, kFlutterSemanticsActionTap,
                                      data);

  EXPECT_TRUE(called);
}

// Checks sending platform messages works.
TEST(FlEngineTest, PlatformMessage) {
  g_autoptr(FlEngine) engine = make_mock_engine();
  FlutterEngineProcTable* embedder_api = fl_engine_get_embedder_api(engine);

  bool called = false;
  FlutterEngineSendPlatformMessageFnPtr old_handler =
      embedder_api->SendPlatformMessage;
  embedder_api->SendPlatformMessage = MOCK_ENGINE_PROC(
      SendPlatformMessage,
      ([&called, old_handler](auto engine,
                              const FlutterPlatformMessage* message) {
        if (strcmp(message->channel, "test") != 0) {
          return old_handler(engine, message);
        }

        called = true;

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

// Checks settings plugin sends settings on startup.
TEST(FlEngineTest, SettingsPlugin) {
  g_autoptr(FlEngine) engine = make_mock_engine();
  FlutterEngineProcTable* embedder_api = fl_engine_get_embedder_api(engine);

  bool called = false;
  embedder_api->SendPlatformMessage = MOCK_ENGINE_PROC(
      SendPlatformMessage,
      ([&called](auto engine, const FlutterPlatformMessage* message) {
        called = true;

        EXPECT_STREQ(message->channel, "flutter/settings");

        g_autoptr(FlJsonMessageCodec) codec = fl_json_message_codec_new();
        g_autoptr(GBytes) data =
            g_bytes_new(message->message, message->message_size);
        g_autoptr(GError) error = nullptr;
        g_autoptr(FlValue) settings = fl_message_codec_decode_message(
            FL_MESSAGE_CODEC(codec), data, &error);
        EXPECT_NE(settings, nullptr);
        EXPECT_EQ(error, nullptr);

        FlValue* text_scale_factor =
            fl_value_lookup_string(settings, "textScaleFactor");
        EXPECT_NE(text_scale_factor, nullptr);
        EXPECT_EQ(fl_value_get_type(text_scale_factor), FL_VALUE_TYPE_FLOAT);

        FlValue* always_use_24hr_format =
            fl_value_lookup_string(settings, "alwaysUse24HourFormat");
        EXPECT_NE(always_use_24hr_format, nullptr);
        EXPECT_EQ(fl_value_get_type(always_use_24hr_format),
                  FL_VALUE_TYPE_BOOL);

        FlValue* platform_brightness =
            fl_value_lookup_string(settings, "platformBrightness");
        EXPECT_NE(platform_brightness, nullptr);
        EXPECT_EQ(fl_value_get_type(platform_brightness), FL_VALUE_TYPE_STRING);

        return kSuccess;
      }));

  g_autoptr(GError) error = nullptr;
  EXPECT_TRUE(fl_engine_start(engine, &error));
  EXPECT_EQ(error, nullptr);

  EXPECT_TRUE(called);
}

void on_pre_engine_restart_cb(FlEngine* engine, gpointer user_data) {
  int* count = reinterpret_cast<int*>(user_data);
  *count += 1;
}

void on_pre_engine_restart_destroy_notify(gpointer user_data) {
  int* count = reinterpret_cast<int*>(user_data);
  *count += 10;
}

// Checks restarting the engine invokes the correct callback.
TEST(FlEngineTest, OnPreEngineRestart) {
  FlEngine* engine = make_mock_engine();
  FlutterEngineProcTable* embedder_api = fl_engine_get_embedder_api(engine);

  OnPreEngineRestartCallback callback;
  void* callback_user_data;

  bool called = false;
  embedder_api->Initialize = MOCK_ENGINE_PROC(
      Initialize, ([&callback, &callback_user_data, &called](
                       size_t version, const FlutterRendererConfig* config,
                       const FlutterProjectArgs* args, void* user_data,
                       FLUTTER_API_SYMBOL(FlutterEngine) * engine_out) {
        called = true;
        callback = args->on_pre_engine_restart_callback;
        callback_user_data = user_data;

        return kSuccess;
      }));

  g_autoptr(GError) error = nullptr;
  EXPECT_TRUE(fl_engine_start(engine, &error));
  EXPECT_EQ(error, nullptr);

  EXPECT_TRUE(called);
  EXPECT_NE(callback, nullptr);

  // The following call has no effect but should not crash.
  callback(callback_user_data);

  int count = 0;

  // Set handler so that:
  //
  //  * When the engine restarts, count += 1;
  //  * When the engine is freed, count += 10.
  fl_engine_set_on_pre_engine_restart_handler(
      engine, on_pre_engine_restart_cb, &count,
      on_pre_engine_restart_destroy_notify);

  callback(callback_user_data);
  EXPECT_EQ(count, 1);

  // Disposal should call the destroy notify.
  g_object_unref(engine);
  EXPECT_EQ(count, 11);
}

TEST(FlEngineTest, DartEntrypointArgs) {
  g_autoptr(FlDartProject) project = fl_dart_project_new();

  GPtrArray* args_array = g_ptr_array_new();
  g_ptr_array_add(args_array, const_cast<char*>("arg_one"));
  g_ptr_array_add(args_array, const_cast<char*>("arg_two"));
  g_ptr_array_add(args_array, const_cast<char*>("arg_three"));
  g_ptr_array_add(args_array, nullptr);
  gchar** args = reinterpret_cast<gchar**>(g_ptr_array_free(args_array, false));

  fl_dart_project_set_dart_entrypoint_arguments(project, args);

  g_autoptr(FlEngine) engine = make_mock_engine_with_project(project);
  FlutterEngineProcTable* embedder_api = fl_engine_get_embedder_api(engine);

  bool called = false;
  embedder_api->Initialize = MOCK_ENGINE_PROC(
      Initialize, ([&called, &set_args = args](
                       size_t version, const FlutterRendererConfig* config,
                       const FlutterProjectArgs* args, void* user_data,
                       FLUTTER_API_SYMBOL(FlutterEngine) * engine_out) {
        called = true;
        EXPECT_NE(set_args, args->dart_entrypoint_argv);
        EXPECT_EQ(args->dart_entrypoint_argc, 3);

        return kSuccess;
      }));

  g_autoptr(GError) error = nullptr;
  EXPECT_TRUE(fl_engine_start(engine, &error));
  EXPECT_EQ(error, nullptr);

  EXPECT_TRUE(called);
}

// NOLINTEND(clang-analyzer-core.StackAddressEscape)
