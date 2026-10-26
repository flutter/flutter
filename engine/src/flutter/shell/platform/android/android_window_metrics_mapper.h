// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_WINDOW_METRICS_MAPPER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_WINDOW_METRICS_MAPPER_H_

#include <cstddef>
#include <cstdint>
#include <functional>
#include <optional>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter::android {

/// Represents a single Android display feature (fold, hinge, or cutout).
struct AndroidDisplayFeature {
  double left = 0.0;
  double top = 0.0;
  double right = 0.0;
  double bottom = 0.0;
  FlutterDisplayFeatureType type = kFlutterDisplayFeatureTypeUnknown;
  FlutterDisplayFeatureState state = kFlutterDisplayFeatureStateUnknown;

  bool operator==(const AndroidDisplayFeature& other) const;
  bool operator!=(const AndroidDisplayFeature& other) const {
    return !(*this == other);
  }
};

/// Represents Android viewport metrics received via
/// `FlutterJNI.nativeSetViewportMetrics`.
struct AndroidViewportMetrics {
  static constexpr float kDefaultDevicePixelRatio = 1.0f;
  static constexpr int32_t kUnsetTouchSlop = -1;
  static constexpr double kUnsetCornerRadius = -1.0;

  float device_pixel_ratio = kDefaultDevicePixelRatio;
  int32_t physical_width = 0;
  int32_t physical_height = 0;
  int32_t physical_padding_top = 0;
  int32_t physical_padding_right = 0;
  int32_t physical_padding_bottom = 0;
  int32_t physical_padding_left = 0;
  int32_t physical_view_inset_top = 0;
  int32_t physical_view_inset_right = 0;
  int32_t physical_view_inset_bottom = 0;
  int32_t physical_view_inset_left = 0;
  int32_t system_gesture_inset_top = 0;
  int32_t system_gesture_inset_right = 0;
  int32_t system_gesture_inset_bottom = 0;
  int32_t system_gesture_inset_left = 0;
  int32_t physical_touch_slop = kUnsetTouchSlop;
  int32_t physical_min_width = 0;
  int32_t physical_max_width = 0;
  int32_t physical_min_height = 0;
  int32_t physical_max_height = 0;
  double physical_display_corner_radius_top_left = kUnsetCornerRadius;
  double physical_display_corner_radius_top_right = kUnsetCornerRadius;
  double physical_display_corner_radius_bottom_right = kUnsetCornerRadius;
  double physical_display_corner_radius_bottom_left = kUnsetCornerRadius;
  std::optional<FlutterDisplayCornerRadii> display_corner_radii;
  std::vector<int32_t> display_features_bounds;
  std::vector<int32_t> display_features_type;
  std::vector<int32_t> display_features_state;
  std::vector<FlutterDisplayFeature> display_features;
  uint64_t display_id = 0;
  int64_t view_id = 0;

  bool operator==(const AndroidViewportMetrics& other) const;
  bool operator!=(const AndroidViewportMetrics& other) const {
    return !(*this == other);
  }
};

/// Represents Android display metrics received via `FlutterJNI`.
struct AndroidDisplayMetrics {
  static constexpr double kDefaultDevicePixelRatio = 1.0;

  FlutterEngineDisplayId display_id = 0;
  bool single_display = true;
  double refresh_rate = 0.0;
  size_t width = 0;
  size_t height = 0;
  double device_pixel_ratio = kDefaultDevicePixelRatio;

  bool operator==(const AndroidDisplayMetrics& other) const;
  bool operator!=(const AndroidDisplayMetrics& other) const {
    return !(*this == other);
  }
};

/// Represents an Android pointer / touch / stylus / mouse / trackpad event
/// including all 11 extended `FlutterPointerEvent` fields.
struct AndroidPointerEvent {
  static constexpr double kDefaultScale = 1.0;
  static constexpr double kDefaultPressureMax = 1.0;

  size_t timestamp = 0;
  FlutterPointerPhase phase = kCancel;
  double x = 0.0;
  double y = 0.0;
  int32_t device = 0;
  FlutterPointerSignalKind signal_kind = kFlutterPointerSignalKindNone;
  double scroll_delta_x = 0.0;
  double scroll_delta_y = 0.0;
  FlutterPointerDeviceKind device_kind = kFlutterPointerDeviceKindTouch;
  int64_t buttons = 0;
  double pan_x = 0.0;
  double pan_y = 0.0;
  double scale = kDefaultScale;
  double rotation = 0.0;
  double pressure = 0.0;
  double pressure_min = 0.0;
  double pressure_max = kDefaultPressureMax;
  double distance = 0.0;
  double distance_max = 0.0;
  double size = 0.0;
  double radius_major = 0.0;
  double radius_minor = 0.0;
  double radius_min = 0.0;
  double radius_max = 0.0;
  double orientation = 0.0;
  double tilt = 0.0;
  int64_t platform_data = 0;
  int64_t embedder_id = 0;
  FlutterViewId view_id = 0;
};

/// Self-contained carrier for a `FlutterWindowMetricsEvent` and the backing
/// storage for its `display_corner_radii` and `display_features` pointer
/// fields. Copy and move operations automatically re-bind the internal pointers
/// in `event`.
struct MappedWindowMetricsEvent {
  FlutterWindowMetricsEvent event = {};
  FlutterDisplayCornerRadii corner_radii = {};
  bool has_corner_radii = false;
  std::vector<FlutterDisplayFeature> features;
  std::vector<const FlutterDisplayFeature*> feature_ptrs;

  MappedWindowMetricsEvent() = default;
  ~MappedWindowMetricsEvent() = default;

  MappedWindowMetricsEvent(const MappedWindowMetricsEvent& other);
  MappedWindowMetricsEvent& operator=(const MappedWindowMetricsEvent& other);
  MappedWindowMetricsEvent(MappedWindowMetricsEvent&& other) noexcept;
  MappedWindowMetricsEvent& operator=(
      MappedWindowMetricsEvent&& other) noexcept;

  void RebindPointers();
};

/// Maps Android window metrics, display metrics, pointer events (including
/// 36-field `PointerData` binary buffers), and non-linear font scaling requests
/// to and from the Flutter Embedder C-API structs.
class AndroidWindowMetricsMapper {
 public:
  // Number of 64-bit fields per PointerData entry in
  // AndroidTouchProcessor.java.
  static constexpr size_t kPointerDataFieldCount = 36;
  static constexpr size_t kBytesPerPointerDataField = sizeof(int64_t);
  static constexpr size_t kPointerDataByteSize =
      kPointerDataFieldCount * kBytesPerPointerDataField;

  // Number of coordinates per display feature bounding box (left, top, right,
  // bottom).
  static constexpr size_t kCoordsPerDisplayFeatureRect = 4;

  static MappedWindowMetricsEvent MapViewportMetrics(
      const AndroidViewportMetrics& metrics);

  static FlutterWindowMetricsEvent ToFlutterWindowMetricsEvent(
      const AndroidViewportMetrics& metrics);

  static FlutterEngineDisplay ToFlutterEngineDisplay(
      const AndroidDisplayMetrics& metrics);

  static FlutterDisplayFeatureType MapDisplayFeatureType(int32_t android_type);

  static FlutterDisplayFeatureState MapDisplayFeatureState(
      int32_t android_state);

  static std::vector<FlutterDisplayFeature> BuildDisplayFeatures(
      const AndroidViewportMetrics& metrics);

  static std::vector<AndroidDisplayFeature> ExtractDisplayFeatures(
      const AndroidViewportMetrics& metrics);

  static FlutterPointerPhase MapAndroidActionToPointerPhase(
      int32_t masked_action,
      bool is_hover = false,
      bool is_FirstDown = false,
      bool is_LastUp = false);

  static FlutterPointerDeviceKind MapAndroidToolTypeToDeviceKind(
      int32_t tool_type);

  static FlutterPointerSignalKind MapPointerSignalKind(int64_t signal_kind);

  static FlutterPointerPhase MapPointerDataChangeToPhase(int64_t change);

  static FlutterPointerDeviceKind MapPointerDataDeviceKind(int64_t kind);

  static FlutterPointerEvent ToFlutterPointerEvent(
      const AndroidPointerEvent& input);

  static bool MapPointerDataPacket(
      const uint8_t* packet_data,
      size_t packet_size,
      std::vector<FlutterPointerEvent>* out_events);

  static std::vector<FlutterPointerEvent> FromPointerDataPacket(
      const uint8_t* packet_data,
      size_t packet_size);

  static FlutterEngineResult DispatchPointerDataPacket(
      const FlutterEngineProcTable& proc_table,
      FLUTTER_API_SYMBOL(FlutterEngine) engine,
      const uint8_t* packet_data,
      size_t packet_size);

  using FontScaleFn =
      std::function<double(double font_size, int32_t configuration_id)>;

  static bool ScaleFontSizeWithFn(const FlutterScaleFontSizeInfo* info,
                                  double* scaled_font_size_out,
                                  const FontScaleFn& scale_fn);

  static bool ScaleFontSize(const FlutterScaleFontSizeInfo* info,
                            double* scaled_font_size_out,
                            flutter::JvmInvoker* jvm_invoker);

  static bool ScaleFontSizeCallback(const FlutterScaleFontSizeInfo* info,
                                    double* scaled_font_size_out,
                                    void* user_data);

 private:
  FML_DISALLOW_IMPLICIT_CONSTRUCTORS(AndroidWindowMetricsMapper);
};

}  // namespace flutter::android

namespace flutter {

using AndroidDisplayFeature = android::AndroidDisplayFeature;
using AndroidViewportMetrics = android::AndroidViewportMetrics;
using AndroidDisplayMetrics = android::AndroidDisplayMetrics;
using AndroidPointerEvent = android::AndroidPointerEvent;
using MappedWindowMetricsEvent = android::MappedWindowMetricsEvent;
using AndroidWindowMetricsMapper = android::AndroidWindowMetricsMapper;

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_WINDOW_METRICS_MAPPER_H_
