// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_WINDOW_METRICS_MAPPER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_WINDOW_METRICS_MAPPER_H_

#include <cstddef>
#include <cstdint>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {
namespace android {

/// @brief Decoupled representation of Android display feature types.
enum class AndroidDisplayFeatureType {
  kUnknown = 0,
  kFold = 1,
  kHinge = 2,
  kCutout = 3,
};

/// @brief Decoupled representation of Android display feature states.
enum class AndroidDisplayFeatureState {
  kUnknown = 0,
  kPostureFlat = 1,
  kPostureHalfOpened = 2,
};

/// @brief Decoupled representation of a single Android display feature
/// rectangle.
struct AndroidDisplayFeature {
  double left = 0.0;
  double top = 0.0;
  double right = 0.0;
  double bottom = 0.0;
  AndroidDisplayFeatureType type = AndroidDisplayFeatureType::kUnknown;
  AndroidDisplayFeatureState state = AndroidDisplayFeatureState::kUnknown;

  bool operator==(const AndroidDisplayFeature& other) const {
    return left == other.left && top == other.top && right == other.right &&
           bottom == other.bottom && type == other.type && state == other.state;
  }
};

/// @brief Decoupled representation of Android viewport and window metrics.
struct AndroidViewportMetrics {
  int64_t view_id = 0;
  double device_pixel_ratio = 1.0;
  double physical_width = 0.0;
  double physical_height = 0.0;
  double physical_padding_top = 0.0;
  double physical_padding_right = 0.0;
  double physical_padding_bottom = 0.0;
  double physical_padding_left = 0.0;
  double physical_view_inset_top = 0.0;
  double physical_view_inset_right = 0.0;
  double physical_view_inset_bottom = 0.0;
  double physical_view_inset_left = 0.0;
  double system_gesture_inset_top = 0.0;
  double system_gesture_inset_right = 0.0;
  double system_gesture_inset_bottom = 0.0;
  double system_gesture_inset_left = 0.0;
  double physical_touch_slop = -1.0;
  std::vector<double> display_features_bounds;
  std::vector<int32_t> display_features_type;
  std::vector<int32_t> display_features_state;
  double physical_min_width = 0.0;
  double physical_max_width = 0.0;
  double physical_min_height = 0.0;
  double physical_max_height = 0.0;
  uint64_t display_id = 0;
  double physical_display_corner_radius_top_left = -1.0;
  double physical_display_corner_radius_top_right = -1.0;
  double physical_display_corner_radius_bottom_right = -1.0;
  double physical_display_corner_radius_bottom_left = -1.0;

  bool operator==(const AndroidViewportMetrics& other) const;
};

/// @brief Decoupled representation of Android display metrics.
struct AndroidDisplayMetrics {
  uint64_t display_id = 0;
  bool single_display = true;
  double refresh_rate = 60.0;
  double width = 0.0;
  double height = 0.0;
  double device_pixel_ratio = 1.0;

  bool operator==(const AndroidDisplayMetrics& other) const {
    return display_id == other.display_id &&
           single_display == other.single_display &&
           refresh_rate == other.refresh_rate && width == other.width &&
           height == other.height &&
           device_pixel_ratio == other.device_pixel_ratio;
  }
};

/// @brief Decoupled cutout insets parsed from display features and view
/// metrics.
struct AndroidCutoutInsets {
  double top = 0.0;
  double right = 0.0;
  double bottom = 0.0;
  double left = 0.0;

  bool operator==(const AndroidCutoutInsets& other) const {
    return top == other.top && right == other.right && bottom == other.bottom &&
           left == other.left;
  }
};

/// @brief Utility mapper converting Android viewport and display metrics to
/// C-API structs (FlutterWindowMetricsEvent, FlutterEngineDisplay).
class AndroidWindowMetricsMapper {
 public:
  /// @brief Maps AndroidViewportMetrics into a C-API FlutterWindowMetricsEvent.
  static FlutterWindowMetricsEvent ToFlutterWindowMetricsEvent(
      const AndroidViewportMetrics& metrics);

  /// @brief Maps AndroidDisplayMetrics into a C-API FlutterEngineDisplay.
  static FlutterEngineDisplay ToFlutterEngineDisplay(
      const AndroidDisplayMetrics& metrics);

  /// @brief Parses raw display feature arrays into structured
  /// AndroidDisplayFeature objects.
  static std::vector<AndroidDisplayFeature> ParseDisplayFeatures(
      const std::vector<double>& bounds,
      const std::vector<int32_t>& types,
      const std::vector<int32_t>& states);

  /// @brief Extracts cutout insets from display feature bounds and types.
  static AndroidCutoutInsets ExtractCutoutInsets(
      const std::vector<double>& display_features_bounds,
      const std::vector<int32_t>& display_features_type,
      double screen_width,
      double screen_height);

  /// @brief Computes combined physical view insets from padding, insets, and
  /// cutouts.
  static AndroidCutoutInsets ComputeEffectiveInsets(
      const AndroidViewportMetrics& metrics);

  FML_DISALLOW_IMPLICIT_CONSTRUCTORS(AndroidWindowMetricsMapper);
};

/// @brief Abstract provider interface for window and display metrics routing.
class WindowMetricsProvider {
 public:
  virtual ~WindowMetricsProvider() = default;

  /// @brief Sends viewport metrics event.
  virtual bool SendViewportMetrics(const AndroidViewportMetrics& metrics) = 0;

  /// @brief Updates display metrics.
  virtual bool UpdateDisplayMetrics(const AndroidDisplayMetrics& metrics) = 0;

  /// @brief Returns the last received viewport metrics for view_id.
  virtual std::optional<AndroidViewportMetrics> GetViewportMetrics(
      int64_t view_id = 0) const = 0;

  /// @brief Returns the last received display metrics for display_id.
  virtual std::optional<AndroidDisplayMetrics> GetDisplayMetrics(
      uint64_t display_id = 0) const = 0;
};

/// @brief Default JNI/C-API backed WindowMetricsProvider.
class DefaultWindowMetricsProvider : public WindowMetricsProvider {
 public:
  explicit DefaultWindowMetricsProvider(
      std::shared_ptr<JvmInvoker> jvm_invoker = nullptr);
  ~DefaultWindowMetricsProvider() override;

  bool SendViewportMetrics(const AndroidViewportMetrics& metrics) override;
  bool UpdateDisplayMetrics(const AndroidDisplayMetrics& metrics) override;

  std::optional<AndroidViewportMetrics> GetViewportMetrics(
      int64_t view_id = 0) const override;
  std::optional<AndroidDisplayMetrics> GetDisplayMetrics(
      uint64_t display_id = 0) const override;

 private:
  std::shared_ptr<JvmInvoker> jvm_invoker_;
  mutable std::mutex mutex_;
  std::map<int64_t, AndroidViewportMetrics> viewport_metrics_map_;
  std::map<uint64_t, AndroidDisplayMetrics> display_metrics_map_;

  FML_DISALLOW_COPY_AND_ASSIGN(DefaultWindowMetricsProvider);
};

/// @brief In-memory mock window metrics provider for unit testing without JVM.
class InMemoryWindowMetricsProvider : public WindowMetricsProvider {
 public:
  InMemoryWindowMetricsProvider();
  ~InMemoryWindowMetricsProvider() override;

  void SetSendResult(bool result);
  void SetUpdateResult(bool result);
  size_t GetSendCount() const;
  size_t GetUpdateCount() const;
  void Clear();

  bool SendViewportMetrics(const AndroidViewportMetrics& metrics) override;
  bool UpdateDisplayMetrics(const AndroidDisplayMetrics& metrics) override;

  std::optional<AndroidViewportMetrics> GetViewportMetrics(
      int64_t view_id = 0) const override;
  std::optional<AndroidDisplayMetrics> GetDisplayMetrics(
      uint64_t display_id = 0) const override;

 private:
  mutable std::mutex mutex_;
  bool send_result_ = true;
  bool update_result_ = true;
  size_t send_count_ = 0;
  size_t update_count_ = 0;
  std::map<int64_t, AndroidViewportMetrics> viewport_metrics_map_;
  std::map<uint64_t, AndroidDisplayMetrics> display_metrics_map_;

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryWindowMetricsProvider);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_WINDOW_METRICS_MAPPER_H_
