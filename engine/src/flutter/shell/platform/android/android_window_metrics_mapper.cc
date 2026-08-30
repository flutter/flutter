// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_window_metrics_mapper.h"

#include <algorithm>
#include <cmath>

#include "flutter/fml/trace_event.h"

namespace flutter {
namespace android {

bool AndroidViewportMetrics::operator==(
    const AndroidViewportMetrics& other) const {
  return view_id == other.view_id &&
         device_pixel_ratio == other.device_pixel_ratio &&
         physical_width == other.physical_width &&
         physical_height == other.physical_height &&
         physical_padding_top == other.physical_padding_top &&
         physical_padding_right == other.physical_padding_right &&
         physical_padding_bottom == other.physical_padding_bottom &&
         physical_padding_left == other.physical_padding_left &&
         physical_view_inset_top == other.physical_view_inset_top &&
         physical_view_inset_right == other.physical_view_inset_right &&
         physical_view_inset_bottom == other.physical_view_inset_bottom &&
         physical_view_inset_left == other.physical_view_inset_left &&
         system_gesture_inset_top == other.system_gesture_inset_top &&
         system_gesture_inset_right == other.system_gesture_inset_right &&
         system_gesture_inset_bottom == other.system_gesture_inset_bottom &&
         system_gesture_inset_left == other.system_gesture_inset_left &&
         physical_touch_slop == other.physical_touch_slop &&
         display_features_bounds == other.display_features_bounds &&
         display_features_type == other.display_features_type &&
         display_features_state == other.display_features_state &&
         physical_min_width == other.physical_min_width &&
         physical_max_width == other.physical_max_width &&
         physical_min_height == other.physical_min_height &&
         physical_max_height == other.physical_max_height &&
         display_id == other.display_id &&
         physical_display_corner_radius_top_left ==
             other.physical_display_corner_radius_top_left &&
         physical_display_corner_radius_top_right ==
             other.physical_display_corner_radius_top_right &&
         physical_display_corner_radius_bottom_right ==
             other.physical_display_corner_radius_bottom_right &&
         physical_display_corner_radius_bottom_left ==
             other.physical_display_corner_radius_bottom_left;
}

FlutterWindowMetricsEvent
AndroidWindowMetricsMapper::ToFlutterWindowMetricsEvent(
    const AndroidViewportMetrics& metrics) {
  TRACE_EVENT0("flutter",
               "AndroidWindowMetricsMapper::ToFlutterWindowMetricsEvent");
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(FlutterWindowMetricsEvent);
  event.width = static_cast<size_t>(std::max(0.0, metrics.physical_width));
  event.height = static_cast<size_t>(std::max(0.0, metrics.physical_height));
  event.pixel_ratio =
      metrics.device_pixel_ratio > 0.0 ? metrics.device_pixel_ratio : 1.0;
  event.left = 0;
  event.top = 0;

  // View insets: bounded within physical dimensions.
  double inset_top = std::max(0.0, metrics.physical_view_inset_top);
  double inset_right = std::max(0.0, metrics.physical_view_inset_right);
  double inset_bottom = std::max(0.0, metrics.physical_view_inset_bottom);
  double inset_left = std::max(0.0, metrics.physical_view_inset_left);

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

  bool has_explicit_constraints =
      metrics.physical_min_width > 0.0 || metrics.physical_max_width > 0.0 ||
      metrics.physical_min_height > 0.0 || metrics.physical_max_height > 0.0;

  if (has_explicit_constraints) {
    event.has_constraints = true;
    size_t min_w =
        static_cast<size_t>(std::max(0.0, metrics.physical_min_width));
    size_t max_w =
        static_cast<size_t>(std::max(0.0, metrics.physical_max_width));
    size_t min_h =
        static_cast<size_t>(std::max(0.0, metrics.physical_min_height));
    size_t max_h =
        static_cast<size_t>(std::max(0.0, metrics.physical_max_height));

    if (min_w == 0) {
      min_w = event.width;
    }
    if (max_w == 0 || max_w < event.width) {
      max_w = event.width;
    }
    if (min_h == 0) {
      min_h = event.height;
    }
    if (max_h == 0 || max_h < event.height) {
      max_h = event.height;
    }

    // Invariants: min <= width <= max
    if (min_w > event.width) {
      min_w = event.width;
    }
    if (min_h > event.height) {
      min_h = event.height;
    }
    if (max_w < event.width) {
      max_w = event.width;
    }
    if (max_h < event.height) {
      max_h = event.height;
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
  display.refresh_rate =
      metrics.refresh_rate > 0.0 ? metrics.refresh_rate : 60.0;
  display.width = static_cast<size_t>(std::max(0.0, metrics.width));
  display.height = static_cast<size_t>(std::max(0.0, metrics.height));
  display.device_pixel_ratio =
      metrics.device_pixel_ratio > 0.0 ? metrics.device_pixel_ratio : 1.0;
  return display;
}

std::vector<AndroidDisplayFeature>
AndroidWindowMetricsMapper::ParseDisplayFeatures(
    const std::vector<double>& bounds,
    const std::vector<int32_t>& types,
    const std::vector<int32_t>& states) {
  TRACE_EVENT0("flutter", "AndroidWindowMetricsMapper::ParseDisplayFeatures");
  std::vector<AndroidDisplayFeature> features;
  size_t count = bounds.size() / 4;
  features.reserve(count);
  for (size_t i = 0; i < count; ++i) {
    AndroidDisplayFeature feature;
    feature.left = bounds[i * 4];
    feature.top = bounds[i * 4 + 1];
    feature.right = bounds[i * 4 + 2];
    feature.bottom = bounds[i * 4 + 3];

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
  size_t count = display_features_bounds.size() / 4;
  for (size_t i = 0; i < count; ++i) {
    if (i < display_features_type.size()) {
      int32_t type = display_features_type[i];
      // Only extract cutout insets for display features of type Cutout (type
      // 3).
      if (type != static_cast<int32_t>(AndroidDisplayFeatureType::kCutout)) {
        continue;
      }
    }

    // Cutout or display feature bounds
    double left = display_features_bounds[i * 4];
    double top = display_features_bounds[i * 4 + 1];
    double right = display_features_bounds[i * 4 + 2];
    double bottom = display_features_bounds[i * 4 + 3];

    // Top cutout: touches top edge (top <= 1.0)
    if (top <= 1.0 && bottom > 0.0) {
      insets.top = std::max(insets.top, bottom);
    }
    // Bottom cutout: touches bottom edge (bottom >= screen_height - 1.0)
    if (screen_height > 0.0 && bottom >= screen_height - 1.0 &&
        top < screen_height) {
      insets.bottom = std::max(insets.bottom, screen_height - top);
    }
    // Left cutout: touches left edge (left <= 1.0)
    if (left <= 1.0 && right > 0.0) {
      insets.left = std::max(insets.left, right);
    }
    // Right cutout: touches right edge (right >= screen_width - 1.0)
    if (screen_width > 0.0 && right >= screen_width - 1.0 &&
        left < screen_width) {
      insets.right = std::max(insets.right, screen_width - left);
    }
  }
  return insets;
}

AndroidCutoutInsets AndroidWindowMetricsMapper::ComputeEffectiveInsets(
    const AndroidViewportMetrics& metrics) {
  TRACE_EVENT0("flutter", "AndroidWindowMetricsMapper::ComputeEffectiveInsets");
  AndroidCutoutInsets cutout = ExtractCutoutInsets(
      metrics.display_features_bounds, metrics.display_features_type,
      metrics.physical_width, metrics.physical_height);

  AndroidCutoutInsets effective;
  effective.top = std::max({metrics.physical_padding_top,
                            metrics.physical_view_inset_top, cutout.top});
  effective.right = std::max({metrics.physical_padding_right,
                              metrics.physical_view_inset_right, cutout.right});
  effective.bottom =
      std::max({metrics.physical_padding_bottom,
                metrics.physical_view_inset_bottom, cutout.bottom});
  effective.left = std::max({metrics.physical_padding_left,
                             metrics.physical_view_inset_left, cutout.left});
  return effective;
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

bool DefaultWindowMetricsProvider::SendViewportMetrics(
    const AndroidViewportMetrics& metrics) {
  TRACE_EVENT0("flutter", "DefaultWindowMetricsProvider::SendViewportMetrics");
  {
    std::scoped_lock lock(mutex_);
    viewport_metrics_map_[metrics.view_id] = metrics;
  }
  if (!jvm_invoker_) {
    return true;
  }
  return jvm_invoker_->InvokeVoidMethod("onViewportMetrics", "(IDDD)V");
}

bool DefaultWindowMetricsProvider::UpdateDisplayMetrics(
    const AndroidDisplayMetrics& metrics) {
  TRACE_EVENT0("flutter", "DefaultWindowMetricsProvider::UpdateDisplayMetrics");
  {
    std::scoped_lock lock(mutex_);
    display_metrics_map_[metrics.display_id] = metrics;
  }
  if (!jvm_invoker_) {
    return true;
  }
  return jvm_invoker_->InvokeVoidMethod("onDisplayMetrics", "(JDDDF)V");
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
