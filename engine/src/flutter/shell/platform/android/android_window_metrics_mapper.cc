// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_window_metrics_mapper.h"

#include <algorithm>
#include <cmath>
#include <cstring>

#include "flutter/fml/trace_event.h"

namespace flutter {
namespace android {

namespace {

constexpr size_t kMaxDisplayFeatures = 256;
constexpr double kMaxSafeDimension = 65536.0;

inline double SafeDimension(double value) {
  if (!std::isfinite(value) || value <= 0.0) {
    return 0.0;
  }
  return std::min(value, kMaxSafeDimension);
}

inline double SafePixelRatio(double value) {
  return (std::isfinite(value) && value > 0.0) ? value : 1.0;
}

inline double SafeRefreshRate(double value) {
  return (std::isfinite(value) && value > 0.0) ? value : 60.0;
}

inline bool FloatEquals(double a, double b) {
  if (std::isnan(a) && std::isnan(b)) {
    return true;
  }
  return a == b;
}

}  // namespace

bool AndroidViewportMetrics::operator==(
    const AndroidViewportMetrics& other) const {
  return view_id == other.view_id &&
         FloatEquals(device_pixel_ratio, other.device_pixel_ratio) &&
         FloatEquals(physical_width, other.physical_width) &&
         FloatEquals(physical_height, other.physical_height) &&
         FloatEquals(physical_padding_top, other.physical_padding_top) &&
         FloatEquals(physical_padding_right, other.physical_padding_right) &&
         FloatEquals(physical_padding_bottom, other.physical_padding_bottom) &&
         FloatEquals(physical_padding_left, other.physical_padding_left) &&
         FloatEquals(physical_view_inset_top, other.physical_view_inset_top) &&
         FloatEquals(physical_view_inset_right,
                     other.physical_view_inset_right) &&
         FloatEquals(physical_view_inset_bottom,
                     other.physical_view_inset_bottom) &&
         FloatEquals(physical_view_inset_left,
                     other.physical_view_inset_left) &&
         FloatEquals(system_gesture_inset_top,
                     other.system_gesture_inset_top) &&
         FloatEquals(system_gesture_inset_right,
                     other.system_gesture_inset_right) &&
         FloatEquals(system_gesture_inset_bottom,
                     other.system_gesture_inset_bottom) &&
         FloatEquals(system_gesture_inset_left,
                     other.system_gesture_inset_left) &&
         FloatEquals(physical_touch_slop, other.physical_touch_slop) &&
         display_features_bounds == other.display_features_bounds &&
         display_features_type == other.display_features_type &&
         display_features_state == other.display_features_state &&
         FloatEquals(physical_min_width, other.physical_min_width) &&
         FloatEquals(physical_max_width, other.physical_max_width) &&
         FloatEquals(physical_min_height, other.physical_min_height) &&
         FloatEquals(physical_max_height, other.physical_max_height) &&
         display_id == other.display_id &&
         FloatEquals(physical_display_corner_radius_top_left,
                     other.physical_display_corner_radius_top_left) &&
         FloatEquals(physical_display_corner_radius_top_right,
                     other.physical_display_corner_radius_top_right) &&
         FloatEquals(physical_display_corner_radius_bottom_right,
                     other.physical_display_corner_radius_bottom_right) &&
         FloatEquals(physical_display_corner_radius_bottom_left,
                     other.physical_display_corner_radius_bottom_left);
}

FlutterWindowMetricsEvent
AndroidWindowMetricsMapper::ToFlutterWindowMetricsEvent(
    const AndroidViewportMetrics& metrics) {
  TRACE_EVENT0("flutter",
               "AndroidWindowMetricsMapper::ToFlutterWindowMetricsEvent");
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(FlutterWindowMetricsEvent);
  event.width = static_cast<size_t>(SafeDimension(metrics.physical_width));
  event.height = static_cast<size_t>(SafeDimension(metrics.physical_height));
  event.pixel_ratio = SafePixelRatio(metrics.device_pixel_ratio);
  event.left = 0;
  event.top = 0;

  // View insets: bounded within physical dimensions.
  double inset_top = SafeDimension(metrics.physical_view_inset_top);
  double inset_right = SafeDimension(metrics.physical_view_inset_right);
  double inset_bottom = SafeDimension(metrics.physical_view_inset_bottom);
  double inset_left = SafeDimension(metrics.physical_view_inset_left);

  event.physical_view_inset_top =
      std::min(inset_top, static_cast<double>(event.height));
  event.physical_view_inset_right =
      std::min(inset_right, static_cast<double>(event.width));
  event.physical_view_inset_bottom =
      std::min(inset_bottom, static_cast<double>(event.height));
  event.physical_view_inset_left =
      std::min(inset_left, static_cast<double>(event.width));

  event.display_id = metrics.display_id;
  event.view_id = metrics.view_id;

  bool has_explicit_constraints = (std::isfinite(metrics.physical_min_width) &&
                                   metrics.physical_min_width > 0.0) ||
                                  (std::isfinite(metrics.physical_max_width) &&
                                   metrics.physical_max_width > 0.0) ||
                                  (std::isfinite(metrics.physical_min_height) &&
                                   metrics.physical_min_height > 0.0) ||
                                  (std::isfinite(metrics.physical_max_height) &&
                                   metrics.physical_max_height > 0.0);

  if (has_explicit_constraints) {
    event.has_constraints = true;
    size_t min_w =
        static_cast<size_t>(SafeDimension(metrics.physical_min_width));
    size_t max_w =
        static_cast<size_t>(SafeDimension(metrics.physical_max_width));
    size_t min_h =
        static_cast<size_t>(SafeDimension(metrics.physical_min_height));
    size_t max_h =
        static_cast<size_t>(SafeDimension(metrics.physical_max_height));

    if (max_w == 0 || max_w < event.width) {
      max_w = event.width;
    }
    if (min_w > event.width) {
      min_w = event.width;
    }
    if (max_w < min_w) {
      max_w = min_w;
    }

    if (max_h == 0 || max_h < event.height) {
      max_h = event.height;
    }
    if (min_h > event.height) {
      min_h = event.height;
    }
    if (max_h < min_h) {
      max_h = min_h;
    }

    event.min_width_constraint = min_w;
    event.max_width_constraint = max_w;
    event.min_height_constraint = min_h;
    event.max_height_constraint = max_h;
  } else {
    event.has_constraints = false;
    event.min_width_constraint = event.width;
    event.max_width_constraint = event.width;
    event.min_height_constraint = event.height;
    event.max_height_constraint = event.height;
  }

  return event;
}

FlutterEngineDisplay AndroidWindowMetricsMapper::ToFlutterEngineDisplay(
    const AndroidDisplayMetrics& metrics) {
  TRACE_EVENT0("flutter", "AndroidWindowMetricsMapper::ToFlutterEngineDisplay");
  FlutterEngineDisplay display = {};
  display.struct_size = sizeof(FlutterEngineDisplay);
  display.display_id = metrics.display_id;
  display.single_display = metrics.single_display;
  display.refresh_rate = SafeRefreshRate(metrics.refresh_rate);
  display.width = static_cast<size_t>(SafeDimension(metrics.width));
  display.height = static_cast<size_t>(SafeDimension(metrics.height));
  display.device_pixel_ratio = SafePixelRatio(metrics.device_pixel_ratio);
  return display;
}

std::vector<AndroidDisplayFeature>
AndroidWindowMetricsMapper::ParseDisplayFeatures(
    const std::vector<double>& bounds,
    const std::vector<int32_t>& types,
    const std::vector<int32_t>& states) {
  TRACE_EVENT0("flutter", "AndroidWindowMetricsMapper::ParseDisplayFeatures");
  std::vector<AndroidDisplayFeature> features;
  size_t count = std::min(bounds.size() / 4, kMaxDisplayFeatures);
  features.reserve(count);
  for (size_t i = 0; i < count; ++i) {
    AndroidDisplayFeature feature;
    feature.left = std::isfinite(bounds[i * 4]) ? bounds[i * 4] : 0.0;
    feature.top = std::isfinite(bounds[i * 4 + 1]) ? bounds[i * 4 + 1] : 0.0;
    feature.right = std::isfinite(bounds[i * 4 + 2]) ? bounds[i * 4 + 2] : 0.0;
    feature.bottom = std::isfinite(bounds[i * 4 + 3]) ? bounds[i * 4 + 3] : 0.0;

    int32_t type_val = (i < types.size()) ? types[i] : 0;
    switch (type_val) {
      case 1:
        feature.type = AndroidDisplayFeatureType::kFold;
        break;
      case 2:
        feature.type = AndroidDisplayFeatureType::kHinge;
        break;
      case 3:
        feature.type = AndroidDisplayFeatureType::kCutout;
        break;
      default:
        feature.type = AndroidDisplayFeatureType::kUnknown;
        break;
    }

    int32_t state_val = (i < states.size()) ? states[i] : 0;
    switch (state_val) {
      case 1:
        feature.state = AndroidDisplayFeatureState::kPostureFlat;
        break;
      case 2:
        feature.state = AndroidDisplayFeatureState::kPostureHalfOpened;
        break;
      default:
        feature.state = AndroidDisplayFeatureState::kUnknown;
        break;
    }
    features.push_back(feature);
  }
  return features;
}

AndroidCutoutInsets AndroidWindowMetricsMapper::ExtractCutoutInsets(
    const std::vector<double>& display_features_bounds,
    const std::vector<int32_t>& display_features_type,
    double screen_width,
    double screen_height) {
  TRACE_EVENT0("flutter", "AndroidWindowMetricsMapper::ExtractCutoutInsets");
  AndroidCutoutInsets insets;
  if (!std::isfinite(screen_width) || !std::isfinite(screen_height) ||
      screen_width <= 0.0 || screen_height <= 0.0) {
    return insets;
  }
  size_t count = std::min({display_features_bounds.size() / 4,
                           display_features_type.size(), kMaxDisplayFeatures});
  for (size_t i = 0; i < count; ++i) {
    int32_t type = display_features_type[i];
    // Only extract cutout insets for display features of type Cutout (type 3).
    if (type != static_cast<int32_t>(AndroidDisplayFeatureType::kCutout)) {
      continue;
    }

    // Cutout or display feature bounds
    double left = display_features_bounds[i * 4];
    double top = display_features_bounds[i * 4 + 1];
    double right = display_features_bounds[i * 4 + 2];
    double bottom = display_features_bounds[i * 4 + 3];

    if (!std::isfinite(left) || !std::isfinite(top) || !std::isfinite(right) ||
        !std::isfinite(bottom)) {
      continue;
    }
    if (left > right || top > bottom) {
      continue;
    }

    double cutout_w = right - left;
    double cutout_h = bottom - top;
    if (cutout_w <= 0.0 || cutout_h <= 0.0) {
      continue;
    }

    bool touches_top = (top <= 1.0);
    bool touches_bottom = (bottom >= screen_height - 1.0);
    bool touches_left = (left <= 1.0);
    bool touches_right = (right >= screen_width - 1.0);

    if (touches_top && touches_left) {
      if (cutout_h >= cutout_w) {
        insets.top = std::max(insets.top, bottom);
      } else {
        insets.left = std::max(insets.left, right);
      }
    } else if (touches_top && touches_right) {
      if (cutout_h >= cutout_w) {
        insets.top = std::max(insets.top, bottom);
      } else {
        insets.right = std::max(insets.right, screen_width - left);
      }
    } else if (touches_bottom && touches_left) {
      if (cutout_h >= cutout_w) {
        insets.bottom = std::max(insets.bottom, screen_height - top);
      } else {
        insets.left = std::max(insets.left, right);
      }
    } else if (touches_bottom && touches_right) {
      if (cutout_h >= cutout_w) {
        insets.bottom = std::max(insets.bottom, screen_height - top);
      } else {
        insets.right = std::max(insets.right, screen_width - left);
      }
    } else if (touches_top) {
      insets.top = std::max(insets.top, bottom);
    } else if (touches_bottom) {
      insets.bottom = std::max(insets.bottom, screen_height - top);
    } else if (touches_left) {
      insets.left = std::max(insets.left, right);
    } else if (touches_right) {
      insets.right = std::max(insets.right, screen_width - left);
    }
  }
  return insets;
}

DefaultWindowMetricsProvider::DefaultWindowMetricsProvider(
    std::shared_ptr<JvmInvoker> jvm_invoker)
    : jvm_invoker_(std::move(jvm_invoker)) {
  TRACE_EVENT0("flutter",
               "DefaultWindowMetricsProvider::DefaultWindowMetricsProvider");
}

DefaultWindowMetricsProvider::~DefaultWindowMetricsProvider() {
  TRACE_EVENT0("flutter",
               "DefaultWindowMetricsProvider::~DefaultWindowMetricsProvider");
}

void DefaultWindowMetricsProvider::SetMetricsCallback(
    MetricsCallback callback) {
  std::scoped_lock lock(mutex_);
  metrics_callback_ = std::move(callback);
}

void DefaultWindowMetricsProvider::SetDisplayUpdateCallback(
    DisplayUpdateCallback callback) {
  std::scoped_lock lock(mutex_);
  display_update_callback_ = std::move(callback);
}

bool DefaultWindowMetricsProvider::SendViewportMetrics(
    const AndroidViewportMetrics& metrics) {
  TRACE_EVENT0("flutter", "DefaultWindowMetricsProvider::SendViewportMetrics");
  MetricsCallback callback;
  {
    std::scoped_lock lock(mutex_);
    viewport_metrics_map_[metrics.view_id] = metrics;
    callback = metrics_callback_;
  }
  bool engine_result = true;
  if (callback) {
    engine_result = callback(metrics);
  }
  if (!jvm_invoker_) {
    return engine_result;
  }
  PackedViewportMetrics payload_data = {
      metrics.view_id,
      metrics.physical_width,
      metrics.physical_height,
      metrics.device_pixel_ratio,
  };
  std::vector<uint8_t> payload(sizeof(PackedViewportMetrics));
  std::memcpy(payload.data(), &payload_data, sizeof(PackedViewportMetrics));
  bool jvm_result =
      jvm_invoker_->InvokeVoidMethod("onViewportMetrics", "(JDDD)V", payload);
  return engine_result && jvm_result;
}

bool DefaultWindowMetricsProvider::UpdateDisplayMetrics(
    const AndroidDisplayMetrics& metrics) {
  TRACE_EVENT0("flutter", "DefaultWindowMetricsProvider::UpdateDisplayMetrics");
  AndroidDisplayMetrics updated_metrics = metrics;
  DisplayUpdateCallback callback;
  {
    std::scoped_lock lock(mutex_);
    display_metrics_map_[metrics.display_id] = metrics;
    if (display_metrics_map_.size() > 1) {
      updated_metrics.single_display = false;
      for (auto& [id, m] : display_metrics_map_) {
        m.single_display = false;
      }
    }
    callback = display_update_callback_;
  }
  bool engine_result = true;
  if (callback) {
    engine_result = callback(updated_metrics);
  }
  if (!jvm_invoker_) {
    return engine_result;
  }
  PackedDisplayMetrics payload_data = {
      static_cast<int64_t>(updated_metrics.display_id),
      updated_metrics.refresh_rate,
      updated_metrics.width,
      updated_metrics.height,
      updated_metrics.device_pixel_ratio,
  };
  std::vector<uint8_t> payload(sizeof(PackedDisplayMetrics));
  std::memcpy(payload.data(), &payload_data, sizeof(PackedDisplayMetrics));
  bool jvm_result =
      jvm_invoker_->InvokeVoidMethod("onDisplayMetrics", "(JDDDD)V", payload);
  return engine_result && jvm_result;
}

std::optional<AndroidViewportMetrics>
DefaultWindowMetricsProvider::GetViewportMetrics(int64_t view_id) const {
  TRACE_EVENT0("flutter", "DefaultWindowMetricsProvider::GetViewportMetrics");
  std::scoped_lock lock(mutex_);
  auto it = viewport_metrics_map_.find(view_id);
  if (it != viewport_metrics_map_.end()) {
    return it->second;
  }
  return std::nullopt;
}

std::optional<AndroidDisplayMetrics>
DefaultWindowMetricsProvider::GetDisplayMetrics(uint64_t display_id) const {
  TRACE_EVENT0("flutter", "DefaultWindowMetricsProvider::GetDisplayMetrics");
  std::scoped_lock lock(mutex_);
  auto it = display_metrics_map_.find(display_id);
  if (it != display_metrics_map_.end()) {
    return it->second;
  }
  return std::nullopt;
}

InMemoryWindowMetricsProvider::InMemoryWindowMetricsProvider() {
  TRACE_EVENT0("flutter",
               "InMemoryWindowMetricsProvider::InMemoryWindowMetricsProvider");
}

InMemoryWindowMetricsProvider::~InMemoryWindowMetricsProvider() {
  TRACE_EVENT0("flutter",
               "InMemoryWindowMetricsProvider::~InMemoryWindowMetricsProvider");
}

void InMemoryWindowMetricsProvider::SetSendResult(bool result) {
  TRACE_EVENT0("flutter", "InMemoryWindowMetricsProvider::SetSendResult");
  std::scoped_lock lock(mutex_);
  send_result_ = result;
}

void InMemoryWindowMetricsProvider::SetUpdateResult(bool result) {
  TRACE_EVENT0("flutter", "InMemoryWindowMetricsProvider::SetUpdateResult");
  std::scoped_lock lock(mutex_);
  update_result_ = result;
}

size_t InMemoryWindowMetricsProvider::GetSendCount() const {
  std::scoped_lock lock(mutex_);
  return send_count_;
}

size_t InMemoryWindowMetricsProvider::GetUpdateCount() const {
  std::scoped_lock lock(mutex_);
  return update_count_;
}

void InMemoryWindowMetricsProvider::Clear() {
  TRACE_EVENT0("flutter", "InMemoryWindowMetricsProvider::Clear");
  std::scoped_lock lock(mutex_);
  send_count_ = 0;
  update_count_ = 0;
  viewport_metrics_map_.clear();
  display_metrics_map_.clear();
}

bool InMemoryWindowMetricsProvider::SendViewportMetrics(
    const AndroidViewportMetrics& metrics) {
  TRACE_EVENT0("flutter", "InMemoryWindowMetricsProvider::SendViewportMetrics");
  std::scoped_lock lock(mutex_);
  send_count_++;
  viewport_metrics_map_[metrics.view_id] = metrics;
  return send_result_;
}

bool InMemoryWindowMetricsProvider::UpdateDisplayMetrics(
    const AndroidDisplayMetrics& metrics) {
  TRACE_EVENT0("flutter",
               "InMemoryWindowMetricsProvider::UpdateDisplayMetrics");
  std::scoped_lock lock(mutex_);
  update_count_++;
  display_metrics_map_[metrics.display_id] = metrics;
  return update_result_;
}

std::optional<AndroidViewportMetrics>
InMemoryWindowMetricsProvider::GetViewportMetrics(int64_t view_id) const {
  TRACE_EVENT0("flutter", "InMemoryWindowMetricsProvider::GetViewportMetrics");
  std::scoped_lock lock(mutex_);
  auto it = viewport_metrics_map_.find(view_id);
  if (it != viewport_metrics_map_.end()) {
    return it->second;
  }
  return std::nullopt;
}

std::optional<AndroidDisplayMetrics>
InMemoryWindowMetricsProvider::GetDisplayMetrics(uint64_t display_id) const {
  TRACE_EVENT0("flutter", "InMemoryWindowMetricsProvider::GetDisplayMetrics");
  std::scoped_lock lock(mutex_);
  auto it = display_metrics_map_.find(display_id);
  if (it != display_metrics_map_.end()) {
    return it->second;
  }
  return std::nullopt;
}

}  // namespace android
}  // namespace flutter
