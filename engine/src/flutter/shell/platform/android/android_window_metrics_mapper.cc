// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_window_metrics_mapper.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstring>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/platform/embedder/embedder_struct_macros.h"

namespace flutter::android {

namespace {

// Tolerance for floating-point equality comparisons in metrics structs.
constexpr double kFloatComparisonEpsilon = 1e-4;

// Fallback device pixel ratio when Android reports a non-positive or non-finite
// ratio.
constexpr double kFallbackDevicePixelRatio = 1.0;

// Sentinel value for an unspecified physical touch slop or font scale error.
constexpr double kUnspecifiedTouchSlop = -1.0;
constexpr double kInvalidScaledFontSize = -1.0;
constexpr double kMinValidScaledFontSize = 0.0;
constexpr double kDefaultTextScaleFactor = 1.0;

// Maximum number of display features accepted per viewport metrics update.
constexpr size_t kMaxDisplayFeatures = 1024;

// Number of thread-local slots used by ToFlutterWindowMetricsEvent to keep
// backing storage for display_corner_radii and display_features alive across
// value returns.
constexpr size_t kThreadLocalMetricsSlotCount = 16;

// Offsets within each 4-int display feature bounding box tuple.
constexpr size_t kRectLeftOffset = 0;
constexpr size_t kRectTopOffset = 1;
constexpr size_t kRectRightOffset = 2;
constexpr size_t kRectBottomOffset = 3;

// Android display feature type constants (from DisplayFeatureType in Java).
constexpr int32_t kAndroidDisplayFeatureTypeUnknown = 0;
constexpr int32_t kAndroidDisplayFeatureTypeFold = 1;
constexpr int32_t kAndroidDisplayFeatureTypeHinge = 2;
constexpr int32_t kAndroidDisplayFeatureTypeCutout = 3;

// Android display feature state constants (from DisplayFeatureState in Java).
constexpr int32_t kAndroidDisplayFeatureStateUnknown = 0;
constexpr int32_t kAndroidDisplayFeatureStatePostureFlat = 1;
constexpr int32_t kAndroidDisplayFeatureStatePostureHalfOpened = 2;

// Android MotionEvent action constants.
constexpr int32_t kMotionActionDown = 0;
constexpr int32_t kMotionActionUp = 1;
constexpr int32_t kMotionActionMove = 2;
constexpr int32_t kMotionActionCancel = 3;
constexpr int32_t kMotionActionPointerDown = 5;
constexpr int32_t kMotionActionPointerUp = 6;
constexpr int32_t kMotionActionHoverMove = 7;
constexpr int32_t kMotionActionHoverEnter = 9;
constexpr int32_t kMotionActionHoverExit = 10;

// Android MotionEvent tool type constants.
constexpr int32_t kMotionToolTypeUnknown = 0;
constexpr int32_t kMotionToolTypeFinger = 1;
constexpr int32_t kMotionToolTypeStylus = 2;
constexpr int32_t kMotionToolTypeMouse = 3;
constexpr int32_t kMotionToolTypeEraser = 4;

// PointerData::Change enum values serialized by AndroidTouchProcessor.java.
constexpr int64_t kPointerChangeCancel = 0;
constexpr int64_t kPointerChangeAdd = 1;
constexpr int64_t kPointerChangeRemove = 2;
constexpr int64_t kPointerChangeHover = 3;
constexpr int64_t kPointerChangeDown = 4;
constexpr int64_t kPointerChangeMove = 5;
constexpr int64_t kPointerChangeUp = 6;
constexpr int64_t kPointerChangePanZoomStart = 7;
constexpr int64_t kPointerChangePanZoomUpdate = 8;
constexpr int64_t kPointerChangePanZoomEnd = 9;

// PointerData::DeviceKind enum values serialized by AndroidTouchProcessor.java.
constexpr int64_t kPointerDeviceKindTouch = 0;
constexpr int64_t kPointerDeviceKindMouse = 1;
constexpr int64_t kPointerDeviceKindStylus = 2;
constexpr int64_t kPointerDeviceKindInvertedStylus = 3;
constexpr int64_t kPointerDeviceKindTrackpad = 4;

// PointerData::SignalKind enum values serialized by AndroidTouchProcessor.java.
constexpr int64_t kPointerSignalKindNone = 0;
constexpr int64_t kPointerSignalKindScroll = 1;
constexpr int64_t kPointerSignalKindScrollInertiaCancel = 2;
constexpr int64_t kPointerSignalKindScale = 3;

// Field indices in the 36-field (288-byte) binary PointerData packet sent by
// AndroidTouchProcessor.java.
constexpr size_t kPointerFieldEmbedderId = 0;
constexpr size_t kPointerFieldTimeStamp = 1;
constexpr size_t kPointerFieldChange = 2;
constexpr size_t kPointerFieldKind = 3;
constexpr size_t kPointerFieldSignalKind = 4;
constexpr size_t kPointerFieldDevice = 5;
constexpr size_t kPointerFieldPhysicalX = 7;
constexpr size_t kPointerFieldPhysicalY = 8;
constexpr size_t kPointerFieldButtons = 11;
constexpr size_t kPointerFieldPressure = 14;
constexpr size_t kPointerFieldPressureMin = 15;
constexpr size_t kPointerFieldPressureMax = 16;
constexpr size_t kPointerFieldDistance = 17;
constexpr size_t kPointerFieldDistanceMax = 18;
constexpr size_t kPointerFieldSize = 19;
constexpr size_t kPointerFieldRadiusMajor = 20;
constexpr size_t kPointerFieldRadiusMinor = 21;
constexpr size_t kPointerFieldRadiusMin = 22;
constexpr size_t kPointerFieldRadiusMax = 23;
constexpr size_t kPointerFieldOrientation = 24;
constexpr size_t kPointerFieldTilt = 25;
constexpr size_t kPointerFieldPlatformData = 26;
constexpr size_t kPointerFieldScrollDeltaX = 27;
constexpr size_t kPointerFieldScrollDeltaY = 28;
constexpr size_t kPointerFieldPanX = 29;
constexpr size_t kPointerFieldPanY = 30;
constexpr size_t kPointerFieldScale = 33;
constexpr size_t kPointerFieldRotation = 34;
constexpr size_t kPointerFieldViewId = 35;

bool FloatEquals(double a, double b) {
  return std::abs(a - b) < kFloatComparisonEpsilon;
}

bool OptionalCornerRadiiEquals(
    const std::optional<FlutterDisplayCornerRadii>& a,
    const std::optional<FlutterDisplayCornerRadii>& b) {
  if (a.has_value() != b.has_value()) {
    return false;
  }
  if (!a.has_value()) {
    return true;
  }
  return FloatEquals(a->top_left, b->top_left) &&
         FloatEquals(a->top_right, b->top_right) &&
         FloatEquals(a->bottom_right, b->bottom_right) &&
         FloatEquals(a->bottom_left, b->bottom_left);
}

bool DisplayFeatureVectorEquals(const std::vector<FlutterDisplayFeature>& a,
                                const std::vector<FlutterDisplayFeature>& b) {
  if (a.size() != b.size()) {
    return false;
  }
  for (size_t i = 0; i < a.size(); ++i) {
    if (!FloatEquals(a[i].bounds.left, b[i].bounds.left) ||
        !FloatEquals(a[i].bounds.top, b[i].bounds.top) ||
        !FloatEquals(a[i].bounds.right, b[i].bounds.right) ||
        !FloatEquals(a[i].bounds.bottom, b[i].bounds.bottom) ||
        a[i].type != b[i].type || a[i].state != b[i].state) {
      return false;
    }
  }
  return true;
}

size_t ClampToSizeT(int32_t value) {
  return value < 0 ? 0u : static_cast<size_t>(value);
}

double ClampNonNegativeDouble(int32_t value) {
  return value < 0 ? 0.0 : static_cast<double>(value);
}

double SanitizeFiniteDouble(double value, double fallback) {
  return std::isfinite(value) ? value : fallback;
}

double SanitizeCornerRadius(double value) {
  if (!std::isfinite(value) || value < 0.0) {
    return 0.0;
  }
  return value;
}

bool IsValidCornerRadiusValue(double value) {
  return std::isfinite(value) && value >= 0.0;
}

}  // namespace

bool AndroidDisplayFeature::operator==(
    const AndroidDisplayFeature& other) const {
  return FloatEquals(left, other.left) && FloatEquals(top, other.top) &&
         FloatEquals(right, other.right) && FloatEquals(bottom, other.bottom) &&
         type == other.type && state == other.state;
}

bool AndroidViewportMetrics::operator==(
    const AndroidViewportMetrics& other) const {
  return FloatEquals(device_pixel_ratio, other.device_pixel_ratio) &&
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
         physical_min_width == other.physical_min_width &&
         physical_max_width == other.physical_max_width &&
         physical_min_height == other.physical_min_height &&
         physical_max_height == other.physical_max_height &&
         FloatEquals(physical_display_corner_radius_top_left,
                     other.physical_display_corner_radius_top_left) &&
         FloatEquals(physical_display_corner_radius_top_right,
                     other.physical_display_corner_radius_top_right) &&
         FloatEquals(physical_display_corner_radius_bottom_right,
                     other.physical_display_corner_radius_bottom_right) &&
         FloatEquals(physical_display_corner_radius_bottom_left,
                     other.physical_display_corner_radius_bottom_left) &&
         OptionalCornerRadiiEquals(display_corner_radii,
                                   other.display_corner_radii) &&
         display_features_bounds == other.display_features_bounds &&
         display_features_type == other.display_features_type &&
         display_features_state == other.display_features_state &&
         DisplayFeatureVectorEquals(display_features, other.display_features) &&
         display_id == other.display_id && view_id == other.view_id;
}

bool AndroidDisplayMetrics::operator==(
    const AndroidDisplayMetrics& other) const {
  return display_id == other.display_id &&
         single_display == other.single_display &&
         FloatEquals(refresh_rate, other.refresh_rate) &&
         width == other.width && height == other.height &&
         FloatEquals(device_pixel_ratio, other.device_pixel_ratio);
}

MappedWindowMetricsEvent::MappedWindowMetricsEvent(
    const MappedWindowMetricsEvent& other)
    : event(other.event),
      corner_radii(other.corner_radii),
      has_corner_radii(other.has_corner_radii),
      features(other.features) {
  RebindPointers();
}

MappedWindowMetricsEvent& MappedWindowMetricsEvent::operator=(
    const MappedWindowMetricsEvent& other) {
  if (this != &other) {
    event = other.event;
    corner_radii = other.corner_radii;
    has_corner_radii = other.has_corner_radii;
    features = other.features;
    RebindPointers();
  }
  return *this;
}

MappedWindowMetricsEvent::MappedWindowMetricsEvent(
    MappedWindowMetricsEvent&& other) noexcept
    : event(other.event),
      corner_radii(other.corner_radii),
      has_corner_radii(other.has_corner_radii),
      features(std::move(other.features)) {
  RebindPointers();
}

MappedWindowMetricsEvent& MappedWindowMetricsEvent::operator=(
    MappedWindowMetricsEvent&& other) noexcept {
  if (this != &other) {
    event = other.event;
    corner_radii = other.corner_radii;
    has_corner_radii = other.has_corner_radii;
    features = std::move(other.features);
    RebindPointers();
  }
  return *this;
}

void MappedWindowMetricsEvent::RebindPointers() {
  event.display_corner_radii = has_corner_radii ? &corner_radii : nullptr;
  feature_ptrs.clear();
  feature_ptrs.reserve(features.size());
  for (const auto& feature : features) {
    feature_ptrs.push_back(&feature);
  }
  event.display_features_count = feature_ptrs.size();
  event.display_features = feature_ptrs.empty() ? nullptr : feature_ptrs.data();
}

FlutterDisplayFeatureType AndroidWindowMetricsMapper::MapDisplayFeatureType(
    int32_t android_type) {
  switch (android_type) {
    case kAndroidDisplayFeatureTypeFold:
      return kFlutterDisplayFeatureTypeFold;
    case kAndroidDisplayFeatureTypeHinge:
      return kFlutterDisplayFeatureTypeHinge;
    case kAndroidDisplayFeatureTypeCutout:
      return kFlutterDisplayFeatureTypeCutout;
    case kAndroidDisplayFeatureTypeUnknown:
    default:
      return kFlutterDisplayFeatureTypeUnknown;
  }
}

FlutterDisplayFeatureState AndroidWindowMetricsMapper::MapDisplayFeatureState(
    int32_t android_state) {
  switch (android_state) {
    case kAndroidDisplayFeatureStatePostureFlat:
      return kFlutterDisplayFeatureStatePostureFlat;
    case kAndroidDisplayFeatureStatePostureHalfOpened:
      return kFlutterDisplayFeatureStatePostureHalfOpened;
    case kAndroidDisplayFeatureStateUnknown:
    default:
      return kFlutterDisplayFeatureStateUnknown;
  }
}

std::vector<FlutterDisplayFeature>
AndroidWindowMetricsMapper::BuildDisplayFeatures(
    const AndroidViewportMetrics& metrics) {
  TRACE_EVENT0("flutter", "AndroidWindowMetricsMapper::BuildDisplayFeatures");
  std::vector<FlutterDisplayFeature> features;

  if (!metrics.display_features.empty()) {
    size_t count =
        std::min(metrics.display_features.size(), kMaxDisplayFeatures);
    features.reserve(count);
    for (size_t i = 0; i < count; ++i) {
      FlutterDisplayFeature feature = metrics.display_features[i];
      feature.struct_size = sizeof(FlutterDisplayFeature);
      feature.bounds.left = SanitizeFiniteDouble(feature.bounds.left, 0.0);
      feature.bounds.top = SanitizeFiniteDouble(feature.bounds.top, 0.0);
      feature.bounds.right = SanitizeFiniteDouble(feature.bounds.right, 0.0);
      feature.bounds.bottom = SanitizeFiniteDouble(feature.bounds.bottom, 0.0);
      features.push_back(feature);
    }
    return features;
  }

  size_t count = metrics.display_features_type.size();
  if (count == 0 || count > kMaxDisplayFeatures) {
    return features;
  }

  if (metrics.display_features_state.size() != count ||
      metrics.display_features_bounds.size() !=
          count * kCoordsPerDisplayFeatureRect) {
    return features;
  }

  features.reserve(count);
  for (size_t i = 0; i < count; ++i) {
    FlutterDisplayFeature feature = {};
    feature.struct_size = sizeof(FlutterDisplayFeature);
    size_t base_idx = i * kCoordsPerDisplayFeatureRect;
    feature.bounds.left = static_cast<double>(
        metrics.display_features_bounds[base_idx + kRectLeftOffset]);
    feature.bounds.top = static_cast<double>(
        metrics.display_features_bounds[base_idx + kRectTopOffset]);
    feature.bounds.right = static_cast<double>(
        metrics.display_features_bounds[base_idx + kRectRightOffset]);
    feature.bounds.bottom = static_cast<double>(
        metrics.display_features_bounds[base_idx + kRectBottomOffset]);
    feature.type = MapDisplayFeatureType(metrics.display_features_type[i]);
    feature.state = MapDisplayFeatureState(metrics.display_features_state[i]);
    features.push_back(feature);
  }

  return features;
}

std::vector<AndroidDisplayFeature>
AndroidWindowMetricsMapper::ExtractDisplayFeatures(
    const AndroidViewportMetrics& metrics) {
  std::vector<FlutterDisplayFeature> built = BuildDisplayFeatures(metrics);
  std::vector<AndroidDisplayFeature> result;
  result.reserve(built.size());
  for (const auto& feat : built) {
    AndroidDisplayFeature item;
    item.left = feat.bounds.left;
    item.top = feat.bounds.top;
    item.right = feat.bounds.right;
    item.bottom = feat.bounds.bottom;
    item.type = feat.type;
    item.state = feat.state;
    result.push_back(item);
  }
  return result;
}

MappedWindowMetricsEvent AndroidWindowMetricsMapper::MapViewportMetrics(
    const AndroidViewportMetrics& metrics) {
  TRACE_EVENT0("flutter", "AndroidWindowMetricsMapper::MapViewportMetrics");
  MappedWindowMetricsEvent mapped;
  FlutterWindowMetricsEvent& event = mapped.event;
  event.struct_size = sizeof(FlutterWindowMetricsEvent);

  event.width = ClampToSizeT(metrics.physical_width);
  event.height = ClampToSizeT(metrics.physical_height);

  if (std::isnan(metrics.device_pixel_ratio) ||
      std::isinf(metrics.device_pixel_ratio) ||
      metrics.device_pixel_ratio <= 0.0f) {
    event.pixel_ratio = kFallbackDevicePixelRatio;
  } else {
    event.pixel_ratio = static_cast<double>(metrics.device_pixel_ratio);
  }

  // Populate legacy padding fields (top and left) and view insets.
  event.top = ClampToSizeT(metrics.physical_padding_top);
  event.left = ClampToSizeT(metrics.physical_padding_left);
  event.physical_view_inset_top = ClampToSizeT(metrics.physical_view_inset_top);
  event.physical_view_inset_right =
      ClampToSizeT(metrics.physical_view_inset_right);
  event.physical_view_inset_bottom =
      ClampToSizeT(metrics.physical_view_inset_bottom);
  event.physical_view_inset_left =
      ClampToSizeT(metrics.physical_view_inset_left);

  event.display_id = metrics.display_id;
  event.view_id = metrics.view_id;

  bool has_explicit_constraints =
      (metrics.physical_min_width > 0 || metrics.physical_max_width > 0 ||
       metrics.physical_min_height > 0 || metrics.physical_max_height > 0);

  if (has_explicit_constraints) {
    event.has_constraints = true;
    event.min_width_constraint = ClampToSizeT(metrics.physical_min_width);
    event.max_width_constraint = ClampToSizeT(metrics.physical_max_width);
    event.min_height_constraint = ClampToSizeT(metrics.physical_min_height);
    event.max_height_constraint = ClampToSizeT(metrics.physical_max_height);
  } else {
    event.has_constraints = false;
    event.min_width_constraint = event.width;
    event.max_width_constraint = event.width;
    event.min_height_constraint = event.height;
    event.max_height_constraint = event.height;
  }

  // Populate RFC 410.0000 physical_padding (FlutterEdgeInsets).
  event.physical_padding.left =
      ClampNonNegativeDouble(metrics.physical_padding_left);
  event.physical_padding.top =
      ClampNonNegativeDouble(metrics.physical_padding_top);
  event.physical_padding.right =
      ClampNonNegativeDouble(metrics.physical_padding_right);
  event.physical_padding.bottom =
      ClampNonNegativeDouble(metrics.physical_padding_bottom);

  // Populate RFC 410.0000 physical_system_gesture_insets (FlutterEdgeInsets).
  event.physical_system_gesture_insets.left =
      ClampNonNegativeDouble(metrics.system_gesture_inset_left);
  event.physical_system_gesture_insets.top =
      ClampNonNegativeDouble(metrics.system_gesture_inset_top);
  event.physical_system_gesture_insets.right =
      ClampNonNegativeDouble(metrics.system_gesture_inset_right);
  event.physical_system_gesture_insets.bottom =
      ClampNonNegativeDouble(metrics.system_gesture_inset_bottom);

  // Populate RFC 410.0000 physical_touch_slop.
  event.physical_touch_slop =
      metrics.physical_touch_slop < 0
          ? kUnspecifiedTouchSlop
          : static_cast<double>(metrics.physical_touch_slop);

  // Populate RFC 410.0000 display_corner_radii pointer.
  if (metrics.display_corner_radii.has_value()) {
    mapped.has_corner_radii = true;
    mapped.corner_radii.struct_size = sizeof(FlutterDisplayCornerRadii);
    mapped.corner_radii.top_left =
        SanitizeCornerRadius(metrics.display_corner_radii->top_left);
    mapped.corner_radii.top_right =
        SanitizeCornerRadius(metrics.display_corner_radii->top_right);
    mapped.corner_radii.bottom_right =
        SanitizeCornerRadius(metrics.display_corner_radii->bottom_right);
    mapped.corner_radii.bottom_left =
        SanitizeCornerRadius(metrics.display_corner_radii->bottom_left);
  } else if (IsValidCornerRadiusValue(
                 metrics.physical_display_corner_radius_top_left) ||
             IsValidCornerRadiusValue(
                 metrics.physical_display_corner_radius_top_right) ||
             IsValidCornerRadiusValue(
                 metrics.physical_display_corner_radius_bottom_right) ||
             IsValidCornerRadiusValue(
                 metrics.physical_display_corner_radius_bottom_left)) {
    mapped.has_corner_radii = true;
    mapped.corner_radii.struct_size = sizeof(FlutterDisplayCornerRadii);
    mapped.corner_radii.top_left =
        SanitizeCornerRadius(metrics.physical_display_corner_radius_top_left);
    mapped.corner_radii.top_right =
        SanitizeCornerRadius(metrics.physical_display_corner_radius_top_right);
    mapped.corner_radii.bottom_right = SanitizeCornerRadius(
        metrics.physical_display_corner_radius_bottom_right);
    mapped.corner_radii.bottom_left = SanitizeCornerRadius(
        metrics.physical_display_corner_radius_bottom_left);
  } else {
    mapped.has_corner_radii = false;
  }

  // Populate RFC 410.0000 display_features array of pointers.
  mapped.features = BuildDisplayFeatures(metrics);
  mapped.RebindPointers();

  return mapped;
}

FlutterWindowMetricsEvent
AndroidWindowMetricsMapper::ToFlutterWindowMetricsEvent(
    const AndroidViewportMetrics& metrics) {
  TRACE_EVENT0("flutter",
               "AndroidWindowMetricsMapper::ToFlutterWindowMetricsEvent");
  thread_local std::array<MappedWindowMetricsEvent,
                          kThreadLocalMetricsSlotCount>
      s_slots;
  thread_local size_t s_next_slot = 0;

  MappedWindowMetricsEvent& slot = s_slots[s_next_slot];
  s_next_slot = (s_next_slot + 1) % kThreadLocalMetricsSlotCount;
  slot = MapViewportMetrics(metrics);
  return slot.event;
}

FlutterEngineDisplay AndroidWindowMetricsMapper::ToFlutterEngineDisplay(
    const AndroidDisplayMetrics& metrics) {
  TRACE_EVENT0("flutter", "AndroidWindowMetricsMapper::ToFlutterEngineDisplay");
  FlutterEngineDisplay display = {};
  display.struct_size = sizeof(FlutterEngineDisplay);
  display.display_id = metrics.display_id;
  display.single_display = metrics.single_display;

  if (std::isnan(metrics.refresh_rate) || std::isinf(metrics.refresh_rate) ||
      metrics.refresh_rate < 0.0) {
    display.refresh_rate = 0.0;
  } else {
    display.refresh_rate = metrics.refresh_rate;
  }

  display.width = metrics.width;
  display.height = metrics.height;

  if (std::isnan(metrics.device_pixel_ratio) ||
      std::isinf(metrics.device_pixel_ratio) ||
      metrics.device_pixel_ratio <= 0.0) {
    display.device_pixel_ratio = kFallbackDevicePixelRatio;
  } else {
    display.device_pixel_ratio = metrics.device_pixel_ratio;
  }

  return display;
}

FlutterPointerPhase AndroidWindowMetricsMapper::MapAndroidActionToPointerPhase(
    int32_t masked_action,
    bool is_hover,
    bool is_FirstDown,
    bool is_LastUp) {
  (void)is_hover;
  (void)is_FirstDown;
  (void)is_LastUp;
  switch (masked_action) {
    case kMotionActionDown:
    case kMotionActionPointerDown:
      return kDown;
    case kMotionActionUp:
    case kMotionActionPointerUp:
      return kUp;
    case kMotionActionMove:
      return kMove;
    case kMotionActionCancel:
      return kCancel;
    case kMotionActionHoverMove:
      return kHover;
    case kMotionActionHoverEnter:
      return kAdd;
    case kMotionActionHoverExit:
      return kRemove;
    default:
      return kCancel;
  }
}

FlutterPointerDeviceKind
AndroidWindowMetricsMapper::MapAndroidToolTypeToDeviceKind(int32_t tool_type) {
  switch (tool_type) {
    case kMotionToolTypeFinger:
      return kFlutterPointerDeviceKindTouch;
    case kMotionToolTypeStylus:
      return kFlutterPointerDeviceKindStylus;
    case kMotionToolTypeMouse:
      return kFlutterPointerDeviceKindMouse;
    case kMotionToolTypeEraser:
      return kFlutterPointerDeviceKindInvertedStylus;
    case kMotionToolTypeUnknown:
    default:
      return kFlutterPointerDeviceKindTouch;
  }
}

FlutterPointerSignalKind AndroidWindowMetricsMapper::MapPointerSignalKind(
    int64_t signal_kind) {
  switch (signal_kind) {
    case kPointerSignalKindNone:
      return kFlutterPointerSignalKindNone;
    case kPointerSignalKindScroll:
      return kFlutterPointerSignalKindScroll;
    case kPointerSignalKindScrollInertiaCancel:
      return kFlutterPointerSignalKindScrollInertiaCancel;
    case kPointerSignalKindScale:
      return kFlutterPointerSignalKindScale;
    default:
      return kFlutterPointerSignalKindNone;
  }
}

FlutterPointerPhase AndroidWindowMetricsMapper::MapPointerDataChangeToPhase(
    int64_t change) {
  switch (change) {
    case kPointerChangeCancel:
      return kCancel;
    case kPointerChangeAdd:
      return kAdd;
    case kPointerChangeRemove:
      return kRemove;
    case kPointerChangeHover:
      return kHover;
    case kPointerChangeDown:
      return kDown;
    case kPointerChangeMove:
      return kMove;
    case kPointerChangeUp:
      return kUp;
    case kPointerChangePanZoomStart:
      return kPanZoomStart;
    case kPointerChangePanZoomUpdate:
      return kPanZoomUpdate;
    case kPointerChangePanZoomEnd:
      return kPanZoomEnd;
    default:
      return kCancel;
  }
}

FlutterPointerDeviceKind AndroidWindowMetricsMapper::MapPointerDataDeviceKind(
    int64_t kind) {
  switch (kind) {
    case kPointerDeviceKindTouch:
      return kFlutterPointerDeviceKindTouch;
    case kPointerDeviceKindMouse:
      return kFlutterPointerDeviceKindMouse;
    case kPointerDeviceKindStylus:
      return kFlutterPointerDeviceKindStylus;
    case kPointerDeviceKindInvertedStylus:
      return kFlutterPointerDeviceKindInvertedStylus;
    case kPointerDeviceKindTrackpad:
      return kFlutterPointerDeviceKindTrackpad;
    default:
      return kFlutterPointerDeviceKindTouch;
  }
}

FlutterPointerEvent AndroidWindowMetricsMapper::ToFlutterPointerEvent(
    const AndroidPointerEvent& input) {
  TRACE_EVENT0("flutter", "AndroidWindowMetricsMapper::ToFlutterPointerEvent");
  FlutterPointerEvent event = {};
  event.struct_size = sizeof(FlutterPointerEvent);
  event.phase = input.phase;
  event.timestamp = input.timestamp;
  event.x = SanitizeFiniteDouble(input.x, 0.0);
  event.y = SanitizeFiniteDouble(input.y, 0.0);
  event.device = input.device;
  event.signal_kind = input.signal_kind;
  event.scroll_delta_x = SanitizeFiniteDouble(input.scroll_delta_x, 0.0);
  event.scroll_delta_y = SanitizeFiniteDouble(input.scroll_delta_y, 0.0);
  event.device_kind = input.device_kind;
  event.buttons = input.buttons;
  event.pan_x = SanitizeFiniteDouble(input.pan_x, 0.0);
  event.pan_y = SanitizeFiniteDouble(input.pan_y, 0.0);
  event.scale =
      SanitizeFiniteDouble(input.scale, AndroidPointerEvent::kDefaultScale);
  event.rotation = SanitizeFiniteDouble(input.rotation, 0.0);
  event.pressure = SanitizeFiniteDouble(input.pressure, 0.0);
  event.pressure_min = SanitizeFiniteDouble(input.pressure_min, 0.0);
  event.pressure_max = SanitizeFiniteDouble(
      input.pressure_max, AndroidPointerEvent::kDefaultPressureMax);
  event.view_id = input.view_id;

  // Populate all 11 extended FlutterPointerEvent fields (RFC 410.0000).
  event.distance = SanitizeFiniteDouble(input.distance, 0.0);
  event.distance_max = SanitizeFiniteDouble(input.distance_max, 0.0);
  event.size = SanitizeFiniteDouble(input.size, 0.0);
  event.radius_major = SanitizeFiniteDouble(input.radius_major, 0.0);
  event.radius_minor = SanitizeFiniteDouble(input.radius_minor, 0.0);
  event.radius_min = SanitizeFiniteDouble(input.radius_min, 0.0);
  event.radius_max = SanitizeFiniteDouble(input.radius_max, 0.0);
  event.orientation = SanitizeFiniteDouble(input.orientation, 0.0);
  event.tilt = SanitizeFiniteDouble(input.tilt, 0.0);
  event.platform_data = input.platform_data;
  event.embedder_id = input.embedder_id;

  return event;
}

bool AndroidWindowMetricsMapper::MapPointerDataPacket(
    const uint8_t* packet_data,
    size_t packet_size,
    std::vector<FlutterPointerEvent>* out_events) {
  TRACE_EVENT0("flutter", "AndroidWindowMetricsMapper::MapPointerDataPacket");
  if (out_events == nullptr) {
    return false;
  }
  out_events->clear();
  if (packet_data == nullptr || packet_size == 0 ||
      (packet_size % kPointerDataByteSize) != 0) {
    return false;
  }

  size_t event_count = packet_size / kPointerDataByteSize;
  out_events->reserve(event_count);

  for (size_t i = 0; i < event_count; ++i) {
    const uint8_t* entry = packet_data + (i * kPointerDataByteSize);
    std::array<int64_t, kPointerDataFieldCount> int_fields{};
    std::array<double, kPointerDataFieldCount> double_fields{};
    std::memcpy(int_fields.data(), entry, kPointerDataByteSize);
    std::memcpy(double_fields.data(), entry, kPointerDataByteSize);

    AndroidPointerEvent input;
    input.embedder_id = int_fields[kPointerFieldEmbedderId];
    input.timestamp =
        int_fields[kPointerFieldTimeStamp] < 0
            ? 0u
            : static_cast<size_t>(int_fields[kPointerFieldTimeStamp]);
    input.phase = MapPointerDataChangeToPhase(int_fields[kPointerFieldChange]);
    input.device_kind = MapPointerDataDeviceKind(int_fields[kPointerFieldKind]);
    input.signal_kind =
        MapPointerSignalKind(int_fields[kPointerFieldSignalKind]);
    input.device = static_cast<int32_t>(int_fields[kPointerFieldDevice]);
    input.x = double_fields[kPointerFieldPhysicalX];
    input.y = double_fields[kPointerFieldPhysicalY];
    input.buttons = int_fields[kPointerFieldButtons];
    input.pressure = double_fields[kPointerFieldPressure];
    input.pressure_min = double_fields[kPointerFieldPressureMin];
    input.pressure_max = double_fields[kPointerFieldPressureMax];
    input.distance = double_fields[kPointerFieldDistance];
    input.distance_max = double_fields[kPointerFieldDistanceMax];
    input.size = double_fields[kPointerFieldSize];
    input.radius_major = double_fields[kPointerFieldRadiusMajor];
    input.radius_minor = double_fields[kPointerFieldRadiusMinor];
    input.radius_min = double_fields[kPointerFieldRadiusMin];
    input.radius_max = double_fields[kPointerFieldRadiusMax];
    input.orientation = double_fields[kPointerFieldOrientation];
    input.tilt = double_fields[kPointerFieldTilt];
    input.platform_data = int_fields[kPointerFieldPlatformData];
    input.scroll_delta_x = double_fields[kPointerFieldScrollDeltaX];
    input.scroll_delta_y = double_fields[kPointerFieldScrollDeltaY];
    input.pan_x = double_fields[kPointerFieldPanX];
    input.pan_y = double_fields[kPointerFieldPanY];
    input.scale = double_fields[kPointerFieldScale];
    input.rotation = double_fields[kPointerFieldRotation];
    input.view_id = static_cast<FlutterViewId>(int_fields[kPointerFieldViewId]);

    out_events->push_back(ToFlutterPointerEvent(input));
  }

  return true;
}

std::vector<FlutterPointerEvent>
AndroidWindowMetricsMapper::FromPointerDataPacket(const uint8_t* packet_data,
                                                  size_t packet_size) {
  std::vector<FlutterPointerEvent> events;
  MapPointerDataPacket(packet_data, packet_size, &events);
  return events;
}

FlutterEngineResult AndroidWindowMetricsMapper::DispatchPointerDataPacket(
    const FlutterEngineProcTable& proc_table,
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    const uint8_t* packet_data,
    size_t packet_size) {
  TRACE_EVENT0("flutter",
               "AndroidWindowMetricsMapper::DispatchPointerDataPacket");
  if (engine == nullptr) {
    return kInvalidArguments;
  }
  std::vector<FlutterPointerEvent> events;
  if (!MapPointerDataPacket(packet_data, packet_size, &events) ||
      events.empty()) {
    return kInvalidArguments;
  }
  if (proc_table.SendPointerEvent == nullptr) {
    return kInternalInconsistency;
  }
  return proc_table.SendPointerEvent(engine, events.data(), events.size());
}

bool AndroidWindowMetricsMapper::ScaleFontSizeWithFn(
    const FlutterScaleFontSizeInfo* info,
    double* scaled_font_size_out,
    const FontScaleFn& scale_fn) {
  TRACE_EVENT0("flutter", "AndroidWindowMetricsMapper::ScaleFontSizeWithFn");
  if (scaled_font_size_out != nullptr) {
    *scaled_font_size_out = kInvalidScaledFontSize;
  }
  if (info == nullptr || scaled_font_size_out == nullptr || !scale_fn) {
    return false;
  }
  if (info->struct_size == 0 ||
      info->struct_size > sizeof(FlutterScaleFontSizeInfo)) {
    return false;
  }

  double font_size = SAFE_ACCESS(info, font_size, 0.0);
  double text_scale_factor =
      SAFE_ACCESS(info, text_scale_factor, kDefaultTextScaleFactor);
  if (!std::isfinite(font_size) || font_size < 0.0 ||
      !std::isfinite(text_scale_factor)) {
    return false;
  }

  int32_t configuration_id = static_cast<int32_t>(text_scale_factor);
  double scaled = scale_fn(font_size, configuration_id);
  if (!std::isfinite(scaled) || scaled < kMinValidScaledFontSize) {
    return false;
  }

  *scaled_font_size_out = scaled;
  return true;
}

bool AndroidWindowMetricsMapper::ScaleFontSize(
    const FlutterScaleFontSizeInfo* info,
    double* scaled_font_size_out,
    flutter::JvmInvoker* jvm_invoker) {
  TRACE_EVENT0("flutter", "AndroidWindowMetricsMapper::ScaleFontSize");
  if (jvm_invoker == nullptr || !jvm_invoker->IsAttached()) {
    if (scaled_font_size_out != nullptr) {
      *scaled_font_size_out = kInvalidScaledFontSize;
    }
    return false;
  }
  return ScaleFontSizeWithFn(
      info, scaled_font_size_out,
      [jvm_invoker](double font_size, int32_t configuration_id) {
        return jvm_invoker->GetScaledFontSize(font_size, configuration_id);
      });
}

bool AndroidWindowMetricsMapper::ScaleFontSizeCallback(
    const FlutterScaleFontSizeInfo* info,
    double* scaled_font_size_out,
    void* user_data) {
  auto* jvm_invoker = static_cast<flutter::JvmInvoker*>(user_data);
  return ScaleFontSize(info, scaled_font_size_out, jvm_invoker);
}

}  // namespace flutter::android
