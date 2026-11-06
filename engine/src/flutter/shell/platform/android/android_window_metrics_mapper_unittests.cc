// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_window_metrics_mapper.h"

#include <array>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <limits>
#include <string>
#include <vector>

#include "gtest/gtest.h"

namespace flutter::android::testing {

TEST(AndroidWindowMetricsMapperTest,
     ToFlutterWindowMetricsEventMapsPaddingGestureInsetsTouchSlopAndRadii) {
  AndroidViewportMetrics metrics;
  metrics.device_pixel_ratio = 2.5f;
  metrics.physical_width = 1080;
  metrics.physical_height = 2400;
  metrics.physical_padding_top = 80;
  metrics.physical_padding_right = 10;
  metrics.physical_padding_bottom = 40;
  metrics.physical_padding_left = 15;
  metrics.physical_view_inset_top = 0;
  metrics.physical_view_inset_right = 0;
  metrics.physical_view_inset_bottom = 600;
  metrics.physical_view_inset_left = 0;
  metrics.system_gesture_inset_top = 80;
  metrics.system_gesture_inset_right = 48;
  metrics.system_gesture_inset_bottom = 96;
  metrics.system_gesture_inset_left = 48;
  metrics.physical_touch_slop = 24;
  metrics.physical_min_width = 500;
  metrics.physical_max_width = 1080;
  metrics.physical_min_height = 800;
  metrics.physical_max_height = 2400;
  metrics.physical_display_corner_radius_top_left = 32.0;
  metrics.physical_display_corner_radius_top_right = 34.0;
  metrics.physical_display_corner_radius_bottom_right = 36.0;
  metrics.physical_display_corner_radius_bottom_left = 38.0;
  metrics.display_id = 3;
  metrics.view_id = 7;

  FlutterWindowMetricsEvent event =
      AndroidWindowMetricsMapper::ToFlutterWindowMetricsEvent(metrics);

  EXPECT_EQ(event.struct_size, sizeof(FlutterWindowMetricsEvent));
  EXPECT_EQ(event.width, 1080u);
  EXPECT_EQ(event.height, 2400u);
  EXPECT_DOUBLE_EQ(event.pixel_ratio, 2.5);
  EXPECT_EQ(event.top, 80u);
  EXPECT_EQ(event.left, 15u);
  EXPECT_EQ(event.physical_view_inset_bottom, 600u);
  EXPECT_EQ(event.display_id, 3u);
  EXPECT_EQ(event.view_id, 7);
  EXPECT_TRUE(event.has_constraints);
  EXPECT_EQ(event.min_width_constraint, 500u);
  EXPECT_EQ(event.max_width_constraint, 1080u);
  EXPECT_EQ(event.min_height_constraint, 800u);
  EXPECT_EQ(event.max_height_constraint, 2400u);

  // RFC 410.0000 FlutterEdgeInsets physical_padding
  EXPECT_DOUBLE_EQ(event.physical_padding.left, 15.0);
  EXPECT_DOUBLE_EQ(event.physical_padding.top, 80.0);
  EXPECT_DOUBLE_EQ(event.physical_padding.right, 10.0);
  EXPECT_DOUBLE_EQ(event.physical_padding.bottom, 40.0);

  // RFC 410.0000 FlutterEdgeInsets physical_system_gesture_insets
  EXPECT_DOUBLE_EQ(event.physical_system_gesture_insets.left, 48.0);
  EXPECT_DOUBLE_EQ(event.physical_system_gesture_insets.top, 80.0);
  EXPECT_DOUBLE_EQ(event.physical_system_gesture_insets.right, 48.0);
  EXPECT_DOUBLE_EQ(event.physical_system_gesture_insets.bottom, 96.0);

  // RFC 410.0000 physical_touch_slop
  EXPECT_DOUBLE_EQ(event.physical_touch_slop, 24.0);

  // RFC 410.0000 display_corner_radii pointer
  ASSERT_NE(event.display_corner_radii, nullptr);
  EXPECT_EQ(event.display_corner_radii->struct_size,
            sizeof(FlutterDisplayCornerRadii));
  EXPECT_DOUBLE_EQ(event.display_corner_radii->top_left, 32.0);
  EXPECT_DOUBLE_EQ(event.display_corner_radii->top_right, 34.0);
  EXPECT_DOUBLE_EQ(event.display_corner_radii->bottom_right, 36.0);
  EXPECT_DOUBLE_EQ(event.display_corner_radii->bottom_left, 38.0);
}

TEST(AndroidWindowMetricsMapperTest,
     DefaultCornerRadiiAreNullptrAndDisplayFeaturesArePointerArray) {
  AndroidViewportMetrics metrics;
  metrics.physical_width = 800;
  metrics.physical_height = 600;
  metrics.display_features_bounds = {0, 290, 800, 310, 390, 0, 410, 600};
  metrics.display_features_type = {1, 2};   // kFold, kHinge
  metrics.display_features_state = {2, 1};  // kPostureHalfOpened, kPostureFlat

  MappedWindowMetricsEvent mapped =
      AndroidWindowMetricsMapper::MapViewportMetrics(metrics);
  const FlutterWindowMetricsEvent& event = mapped.event;

  // Default corner radii (-1.0) map to nullptr.
  EXPECT_EQ(event.display_corner_radii, nullptr);
  EXPECT_DOUBLE_EQ(event.physical_touch_slop, -1.0);

  // Display features map to const FlutterDisplayFeature** array of length 2.
  ASSERT_EQ(event.display_features_count, 2u);
  ASSERT_NE(event.display_features, nullptr);

  ASSERT_NE(event.display_features[0], nullptr);
  EXPECT_EQ(event.display_features[0]->struct_size,
            sizeof(FlutterDisplayFeature));
  EXPECT_DOUBLE_EQ(event.display_features[0]->bounds.left, 0.0);
  EXPECT_DOUBLE_EQ(event.display_features[0]->bounds.top, 290.0);
  EXPECT_DOUBLE_EQ(event.display_features[0]->bounds.right, 800.0);
  EXPECT_DOUBLE_EQ(event.display_features[0]->bounds.bottom, 310.0);
  EXPECT_EQ(event.display_features[0]->type, kFlutterDisplayFeatureTypeFold);
  EXPECT_EQ(event.display_features[0]->state,
            kFlutterDisplayFeatureStatePostureHalfOpened);

  ASSERT_NE(event.display_features[1], nullptr);
  EXPECT_EQ(event.display_features[1]->struct_size,
            sizeof(FlutterDisplayFeature));
  EXPECT_DOUBLE_EQ(event.display_features[1]->bounds.left, 390.0);
  EXPECT_DOUBLE_EQ(event.display_features[1]->bounds.top, 0.0);
  EXPECT_DOUBLE_EQ(event.display_features[1]->bounds.right, 410.0);
  EXPECT_DOUBLE_EQ(event.display_features[1]->bounds.bottom, 600.0);
  EXPECT_EQ(event.display_features[1]->type, kFlutterDisplayFeatureTypeHinge);
  EXPECT_EQ(event.display_features[1]->state,
            kFlutterDisplayFeatureStatePostureFlat);

  // Verify copy constructor re-binds pointers to the new instance's storage.
  MappedWindowMetricsEvent copy =
      mapped;  // NOLINT(performance-unnecessary-copy-initialization)
  ASSERT_EQ(copy.event.display_features_count, 2u);
  ASSERT_NE(copy.event.display_features, nullptr);
  EXPECT_NE(copy.event.display_features, mapped.event.display_features);
  EXPECT_NE(copy.event.display_features[0], mapped.event.display_features[0]);
  EXPECT_EQ(copy.event.display_features[0]->type,
            kFlutterDisplayFeatureTypeFold);
  copy.features[0].type = kFlutterDisplayFeatureTypeCutout;
  EXPECT_EQ(mapped.event.display_features[0]->type,
            kFlutterDisplayFeatureTypeFold);
}

TEST(AndroidWindowMetricsMapperTest,
     ToFlutterPointerEventPopulatesAll11ExtendedFields) {
  AndroidPointerEvent input;
  input.timestamp = 123456;
  input.phase = kMove;
  input.x = 150.5;
  input.y = 320.25;
  input.device = 4;
  input.signal_kind = kFlutterPointerSignalKindNone;
  input.device_kind = kFlutterPointerDeviceKindStylus;
  input.buttons = 2;
  input.pressure = 0.65;
  input.pressure_min = 0.0;
  input.pressure_max = 1.0;
  input.distance = 3.5;
  input.distance_max = 10.0;
  input.size = 0.4;
  input.radius_major = 8.5;
  input.radius_minor = 6.25;
  input.radius_min = 1.0;
  input.radius_max = 20.0;
  input.orientation = 0.785;
  input.tilt = 0.523;
  input.platform_data = 99;
  input.embedder_id = 777;
  input.view_id = 3;

  FlutterPointerEvent out =
      AndroidWindowMetricsMapper::ToFlutterPointerEvent(input);

  EXPECT_EQ(out.struct_size, sizeof(FlutterPointerEvent));
  EXPECT_EQ(out.phase, kMove);
  EXPECT_EQ(out.timestamp, 123456u);
  EXPECT_DOUBLE_EQ(out.x, 150.5);
  EXPECT_DOUBLE_EQ(out.y, 320.25);
  EXPECT_EQ(out.device, 4);
  EXPECT_EQ(out.device_kind, kFlutterPointerDeviceKindStylus);
  EXPECT_EQ(out.buttons, 2);
  EXPECT_DOUBLE_EQ(out.pressure, 0.65);
  EXPECT_DOUBLE_EQ(out.pressure_min, 0.0);
  EXPECT_DOUBLE_EQ(out.pressure_max, 1.0);
  EXPECT_DOUBLE_EQ(out.distance, 3.5);
  EXPECT_DOUBLE_EQ(out.distance_max, 10.0);
  EXPECT_DOUBLE_EQ(out.size, 0.4);
  EXPECT_DOUBLE_EQ(out.radius_major, 8.5);
  EXPECT_DOUBLE_EQ(out.radius_minor, 6.25);
  EXPECT_DOUBLE_EQ(out.radius_min, 1.0);
  EXPECT_DOUBLE_EQ(out.radius_max, 20.0);
  EXPECT_DOUBLE_EQ(out.orientation, 0.785);
  EXPECT_DOUBLE_EQ(out.tilt, 0.523);
  EXPECT_EQ(out.platform_data, 99);
  EXPECT_EQ(out.embedder_id, 777);
  EXPECT_EQ(out.view_id, 3);
}

TEST(AndroidWindowMetricsMapperTest,
     MapPointerDataPacketUnpacks36FieldBinaryBufferAndDispatches) {
  std::array<int64_t, AndroidWindowMetricsMapper::kPointerDataFieldCount>
      raw_int{};
  auto write_double = [&raw_int](size_t idx, double val) {
    std::memcpy(&raw_int[idx], &val, sizeof(double));
  };

  raw_int[0] = 4242;       // embedder_id
  raw_int[1] = 98765;      // time_stamp
  raw_int[2] = 4;          // change = kDown (4)
  raw_int[3] = 2;          // kind = kStylus (2)
  raw_int[4] = 0;          // signal_kind = kNone (0)
  raw_int[5] = 9;          // device
  raw_int[6] = 1;          // pointer_identifier
  write_double(7, 210.0);  // physical_x
  write_double(8, 420.0);  // physical_y
  write_double(9, 0.0);    // physical_delta_x
  write_double(10, 0.0);   // physical_delta_y
  raw_int[11] = 1;         // buttons
  raw_int[12] = 0;         // obscured
  raw_int[13] = 0;         // synthesized
  write_double(14, 0.8);   // pressure
  write_double(15, 0.0);   // pressure_min
  write_double(16, 1.0);   // pressure_max
  write_double(17, 2.25);  // distance
  write_double(18, 12.0);  // distance_max
  write_double(19, 0.35);  // size
  write_double(20, 9.5);   // radius_major
  write_double(21, 7.5);   // radius_minor
  write_double(22, 0.5);   // radius_min
  write_double(23, 18.0);  // radius_max
  write_double(24, 1.25);  // orientation
  write_double(25, 0.45);  // tilt
  raw_int[26] = 123;       // platformData
  write_double(27, 0.0);   // scroll_delta_x
  write_double(28, 0.0);   // scroll_delta_y
  write_double(29, 10.0);  // pan_x
  write_double(30, 20.0);  // pan_y
  write_double(31, 0.0);   // pan_delta_x
  write_double(32, 0.0);   // pan_delta_y
  write_double(33, 1.5);   // scale
  write_double(34, 0.25);  // rotation
  raw_int[35] = 5;         // view_id

  static std::vector<FlutterPointerEvent> captured_events;
  captured_events.clear();

  FlutterEngineProcTable procs = {};
  procs.struct_size = sizeof(FlutterEngineProcTable);
  procs.SendPointerEvent = [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                              const FlutterPointerEvent* events,
                              size_t events_count) {
    if (events != nullptr && events_count > 0) {
      captured_events.assign(events, events + events_count);
    }
    return kSuccess;
  };

  auto fake_engine =
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0x5678);
  FlutterEngineResult res =
      AndroidWindowMetricsMapper::DispatchPointerDataPacket(
          procs, fake_engine, reinterpret_cast<const uint8_t*>(raw_int.data()),
          sizeof(raw_int));

  EXPECT_EQ(res, kSuccess);
  ASSERT_EQ(captured_events.size(), 1u);
  const FlutterPointerEvent& ev = captured_events[0];
  EXPECT_EQ(ev.embedder_id, 4242);
  EXPECT_EQ(ev.timestamp, 98765u);
  EXPECT_EQ(ev.phase, kDown);
  EXPECT_EQ(ev.device_kind, kFlutterPointerDeviceKindStylus);
  EXPECT_EQ(ev.device, 9);
  EXPECT_DOUBLE_EQ(ev.x, 210.0);
  EXPECT_DOUBLE_EQ(ev.y, 420.0);
  EXPECT_DOUBLE_EQ(ev.pressure, 0.8);
  EXPECT_DOUBLE_EQ(ev.distance, 2.25);
  EXPECT_DOUBLE_EQ(ev.distance_max, 12.0);
  EXPECT_DOUBLE_EQ(ev.size, 0.35);
  EXPECT_DOUBLE_EQ(ev.radius_major, 9.5);
  EXPECT_DOUBLE_EQ(ev.radius_minor, 7.5);
  EXPECT_DOUBLE_EQ(ev.radius_min, 0.5);
  EXPECT_DOUBLE_EQ(ev.radius_max, 18.0);
  EXPECT_DOUBLE_EQ(ev.orientation, 1.25);
  EXPECT_DOUBLE_EQ(ev.tilt, 0.45);
  EXPECT_EQ(ev.platform_data, 123);
  EXPECT_DOUBLE_EQ(ev.scale, 1.5);
  EXPECT_DOUBLE_EQ(ev.rotation, 0.25);
  EXPECT_EQ(ev.view_id, 5);
}

TEST(AndroidWindowMetricsMapperTest,
     ScaleFontSizeCallbackDelegatesToScaleFnAndJvmInvoker) {
  double captured_font_size = 0.0;
  int32_t captured_config_id = -1;
  int call_count = 0;
  double mock_scaled_result = 21.5;

  FlutterScaleFontSizeInfo info = {};
  info.struct_size = sizeof(FlutterScaleFontSizeInfo);
  info.font_size = 14.0;
  info.text_scale_factor = 3.0;

  double scaled_out = 0.0;
  bool ok = AndroidWindowMetricsMapper::ScaleFontSizeWithFn(
      &info, &scaled_out, [&](double font_size, int32_t config_id) {
        ++call_count;
        captured_font_size = font_size;
        captured_config_id = config_id;
        return mock_scaled_result;
      });

  EXPECT_TRUE(ok);
  EXPECT_EQ(call_count, 1);
  EXPECT_DOUBLE_EQ(captured_font_size, 14.0);
  EXPECT_EQ(captured_config_id, 3);
  EXPECT_NEAR(scaled_out, 21.5, 1e-5);

  // Verify negative return returns false and -1.0.
  mock_scaled_result = -1.0;
  EXPECT_FALSE(AndroidWindowMetricsMapper::ScaleFontSizeWithFn(
      &info, &scaled_out,
      [&](double font_size, int32_t config_id) { return mock_scaled_result; }));
  EXPECT_DOUBLE_EQ(scaled_out, -1.0);

  // Verify detached JvmInvoker (returns -1.0) causes ScaleFontSizeCallback to
  // return false.
  flutter::JvmInvoker detached_invoker;
  EXPECT_FALSE(AndroidWindowMetricsMapper::ScaleFontSizeCallback(
      &info, &scaled_out, &detached_invoker));
  EXPECT_DOUBLE_EQ(scaled_out, -1.0);

  // Verify null info or user_data returns false.
  EXPECT_FALSE(AndroidWindowMetricsMapper::ScaleFontSizeCallback(
      nullptr, &scaled_out, &detached_invoker));
  EXPECT_FALSE(AndroidWindowMetricsMapper::ScaleFontSizeCallback(
      &info, &scaled_out, nullptr));
}

}  // namespace flutter::android::testing
