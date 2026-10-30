// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_mutators_mapper.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <limits>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace flutter {

namespace {

bool ClearJniExceptionSafe(JNIEnv* env) {
  if (env == nullptr) {
    return false;
  }
  if (env->ExceptionCheck() == JNI_TRUE) {
    env->ExceptionClear();
    return true;
  }
  return false;
}

/// Epsilon for floating-point equality comparisons on coordinates and matrices.
constexpr float kFloatComparisonEpsilon = 1e-5f;

/// Minimum positive determinant magnitude required to invert a 2x2 matrix when
/// transforming clip rectangles into local platform view space.
constexpr float kMinInvertibleDeterminant = 1e-6f;

/// Minimum valid device pixel ratio; non-positive or non-finite values fall
/// back to 1.0f.
constexpr double kDefaultDevicePixelRatio = 1.0;

/// Minimum clamped opacity (completely transparent).
constexpr float kMinOpacity = 0.0f;

/// Maximum clamped opacity (completely opaque).
constexpr float kMaxOpacity = 1.0f;

/// Default conic weight (1.0 corresponds to a standard quadratic Bézier).
constexpr float kDefaultConicWeight = 1.0f;

/// Number of points consumed by Move and Line path verbs.
constexpr size_t kSinglePointVerbCount = 1;

/// Number of points consumed by Quad and Conic path verbs.
constexpr size_t kQuadraticPointVerbCount = 2;

/// Number of points consumed by Cubic path verbs.
constexpr size_t kCubicPointVerbCount = 3;

/// Number of corners in a rectangle.
constexpr size_t kRectangleCornerCount = 4;

// Indices into the 8-element rounded rectangle radii array:
// [ul_x, ul_y, ur_x, ur_y, lr_x, lr_y, ll_x, ll_y].
constexpr size_t kRadiusUpperLeftX = 0;
constexpr size_t kRadiusUpperLeftY = 1;
constexpr size_t kRadiusUpperRightX = 2;
constexpr size_t kRadiusUpperRightY = 3;
constexpr size_t kRadiusLowerRightX = 4;
constexpr size_t kRadiusLowerRightY = 5;
constexpr size_t kRadiusLowerLeftX = 6;
constexpr size_t kRadiusLowerLeftY = 7;

// Binary serialization header constants for AndroidMutatorsStack.
/// ASCII magic bytes "FMUT" (0x464D5554) identifying a serialized mutator
/// stack payload.
constexpr uint32_t kSerializationMagic = 0x464D5554u;

/// Serialization format version 2 (includes SoA clip path bounds and segments).
constexpr uint32_t kSerializationVersion = 2u;

/// Defensive upper bound on deserialized mutator/segment counts to reject
/// corrupted or adversarial buffers without excessive allocation.
constexpr uint32_t kMaxSerializedCollectionCount = 10000u;

float SanitizeFloat(float value, float fallback = 0.0f) {
  if (std::isnan(value) || std::isinf(value)) {
    return fallback;
  }
  return value;
}

float SanitizeScale(double device_pixel_ratio) {
  if (std::isnan(device_pixel_ratio) || std::isinf(device_pixel_ratio) ||
      device_pixel_ratio <= 0.0) {
    return static_cast<float>(kDefaultDevicePixelRatio);
  }
  return static_cast<float>(device_pixel_ratio);
}

// Cached JNI references for FlutterMutatorsStack and Android graphics classes.
fml::jni::ScopedJavaGlobalRef<jclass>* g_mutators_stack_class = nullptr;
jmethodID g_stack_constructor = nullptr;
jmethodID g_stack_push_transform_method = nullptr;
jmethodID g_stack_push_clip_rect_method = nullptr;
jmethodID g_stack_push_clip_rrect_method = nullptr;
jmethodID g_stack_push_clip_path_method = nullptr;
jmethodID g_stack_push_opacity_method = nullptr;
bool g_stack_clip_rect_takes_float = true;
bool g_stack_clip_rrect_takes_float = true;

fml::jni::ScopedJavaGlobalRef<jclass>* g_path_class = nullptr;
jmethodID g_path_constructor = nullptr;
jmethodID g_path_set_fill_type_method = nullptr;
jmethodID g_path_move_to_method = nullptr;
jmethodID g_path_line_to_method = nullptr;
jmethodID g_path_quad_to_method = nullptr;
jmethodID g_path_conic_to_method = nullptr;
jmethodID g_path_cubic_to_method = nullptr;
jmethodID g_path_close_method = nullptr;

fml::jni::ScopedJavaGlobalRef<jclass>* g_path_fill_type_class = nullptr;
jfieldID g_fill_type_winding_field = nullptr;
jfieldID g_fill_type_even_odd_field = nullptr;

jfloatArray CreateJFloatArraySafe(JNIEnv* env, const float* data, jsize count) {
  if (env == nullptr || env->functions == nullptr ||
      env->functions->NewFloatArray == nullptr) {
    return nullptr;
  }
  jfloatArray array = env->NewFloatArray(count);
  if (array != nullptr && data != nullptr &&
      env->functions->SetFloatArrayRegion != nullptr) {
    env->SetFloatArrayRegion(array, 0, count, data);
  }
  return array;
}

void AppendBytes(std::vector<uint8_t>& out, const void* src, size_t len) {
  const auto* bytes = static_cast<const uint8_t*>(src);
  out.insert(out.end(), bytes, bytes + len);
}

template <typename T>
void AppendScalar(std::vector<uint8_t>& out, const T& val) {
  AppendBytes(out, &val, sizeof(T));
}

template <typename T>
bool ReadScalar(const uint8_t*& cursor, const uint8_t* end, T& out) {
  if (static_cast<size_t>(end - cursor) < sizeof(T)) {
    return false;
  }
  std::memcpy(&out, cursor, sizeof(T));
  cursor += sizeof(T);
  return true;
}

}  // namespace

// =============================================================================
// AndroidMatrix3x3
// =============================================================================

AndroidMatrix3x3 AndroidMatrix3x3::Identity() {
  return AndroidMatrix3x3{};
}

AndroidMatrix3x3 AndroidMatrix3x3::FromFlutterTransformation(
    const FlutterTransformation& transform) {
  AndroidMatrix3x3 m;
  m.values[kMatrixScaleXIndex] =
      SanitizeFloat(static_cast<float>(transform.scaleX), 1.0f);
  m.values[kMatrixSkewXIndex] =
      SanitizeFloat(static_cast<float>(transform.skewX), 0.0f);
  m.values[kMatrixTransXIndex] =
      SanitizeFloat(static_cast<float>(transform.transX), 0.0f);
  m.values[kMatrixSkewYIndex] =
      SanitizeFloat(static_cast<float>(transform.skewY), 0.0f);
  m.values[kMatrixScaleYIndex] =
      SanitizeFloat(static_cast<float>(transform.scaleY), 1.0f);
  m.values[kMatrixTransYIndex] =
      SanitizeFloat(static_cast<float>(transform.transY), 0.0f);
  m.values[kMatrixPersp0Index] =
      SanitizeFloat(static_cast<float>(transform.pers0), 0.0f);
  m.values[kMatrixPersp1Index] =
      SanitizeFloat(static_cast<float>(transform.pers1), 0.0f);
  m.values[kMatrixPersp2Index] =
      SanitizeFloat(static_cast<float>(transform.pers2), 1.0f);
  return m;
}

AndroidMatrix3x3 AndroidMatrix3x3::Multiply(const AndroidMatrix3x3& a,
                                            const AndroidMatrix3x3& b) {
  AndroidMatrix3x3 result;
  for (size_t r = 0; r < kAndroidMatrixDimension; ++r) {
    for (size_t c = 0; c < kAndroidMatrixDimension; ++c) {
      float sum = 0.0f;
      for (size_t k = 0; k < kAndroidMatrixDimension; ++k) {
        sum += a.values[r * kAndroidMatrixDimension + k] *
               b.values[k * kAndroidMatrixDimension + c];
      }
      result.values[r * kAndroidMatrixDimension + c] = sum;
    }
  }
  return result;
}

AndroidMatrix3x3 AndroidMatrix3x3::PreTranslate(const AndroidMatrix3x3& m,
                                                float dx,
                                                float dy) {
  AndroidMatrix3x3 t = Identity();
  t.values[kMatrixTransXIndex] = SanitizeFloat(dx);
  t.values[kMatrixTransYIndex] = SanitizeFloat(dy);
  return Multiply(m, t);
}

AndroidMatrix3x3 AndroidMatrix3x3::PostTranslate(const AndroidMatrix3x3& m,
                                                 float dx,
                                                 float dy) {
  AndroidMatrix3x3 t = Identity();
  t.values[kMatrixTransXIndex] = SanitizeFloat(dx);
  t.values[kMatrixTransYIndex] = SanitizeFloat(dy);
  return Multiply(t, m);
}

bool AndroidMatrix3x3::IsIdentity(float epsilon) const {
  const AndroidMatrix3x3 id = Identity();
  for (size_t i = 0; i < kAndroidMatrixElementCount; ++i) {
    if (std::fabs(values[i] - id.values[i]) > epsilon) {
      return false;
    }
  }
  return true;
}

bool AndroidMatrix3x3::operator==(const AndroidMatrix3x3& other) const {
  for (size_t i = 0; i < kAndroidMatrixElementCount; ++i) {
    if (std::fabs(values[i] - other.values[i]) > kFloatComparisonEpsilon) {
      return false;
    }
  }
  return true;
}

// =============================================================================
// AndroidRect & AndroidRoundedRect
// =============================================================================

AndroidRect AndroidRect::FromFlutterRect(const FlutterRect& rect) {
  return AndroidRect{
      .left = SanitizeFloat(static_cast<float>(rect.left)),
      .top = SanitizeFloat(static_cast<float>(rect.top)),
      .right = SanitizeFloat(static_cast<float>(rect.right)),
      .bottom = SanitizeFloat(static_cast<float>(rect.bottom)),
  };
}

bool AndroidRect::operator==(const AndroidRect& other) const {
  return std::fabs(left - other.left) <= kFloatComparisonEpsilon &&
         std::fabs(top - other.top) <= kFloatComparisonEpsilon &&
         std::fabs(right - other.right) <= kFloatComparisonEpsilon &&
         std::fabs(bottom - other.bottom) <= kFloatComparisonEpsilon;
}

AndroidRoundedRect AndroidRoundedRect::FromFlutterRoundedRect(
    const FlutterRoundedRect& rrect) {
  AndroidRoundedRect out;
  out.rect = AndroidRect::FromFlutterRect(rrect.rect);
  out.radii[kRadiusUpperLeftX] =
      SanitizeFloat(static_cast<float>(rrect.upper_left_corner_radius.width));
  out.radii[kRadiusUpperLeftY] =
      SanitizeFloat(static_cast<float>(rrect.upper_left_corner_radius.height));
  out.radii[kRadiusUpperRightX] =
      SanitizeFloat(static_cast<float>(rrect.upper_right_corner_radius.width));
  out.radii[kRadiusUpperRightY] =
      SanitizeFloat(static_cast<float>(rrect.upper_right_corner_radius.height));
  out.radii[kRadiusLowerRightX] =
      SanitizeFloat(static_cast<float>(rrect.lower_right_corner_radius.width));
  out.radii[kRadiusLowerRightY] =
      SanitizeFloat(static_cast<float>(rrect.lower_right_corner_radius.height));
  out.radii[kRadiusLowerLeftX] =
      SanitizeFloat(static_cast<float>(rrect.lower_left_corner_radius.width));
  out.radii[kRadiusLowerLeftY] =
      SanitizeFloat(static_cast<float>(rrect.lower_left_corner_radius.height));
  return out;
}

bool AndroidRoundedRect::IsRect(float epsilon) const {
  for (float r : radii) {
    if (std::fabs(r) > epsilon) {
      return false;
    }
  }
  return true;
}

bool AndroidRoundedRect::IsUniformCornerRadius(float* out_radius,
                                               float epsilon) const {
  const float first = radii[0];
  for (size_t i = 1; i < kAndroidRoundedRectRadiiCount; ++i) {
    if (std::fabs(radii[i] - first) > epsilon) {
      return false;
    }
  }
  if (out_radius != nullptr) {
    *out_radius = first;
  }
  return true;
}

bool AndroidRoundedRect::operator==(const AndroidRoundedRect& other) const {
  if (rect != other.rect) {
    return false;
  }
  for (size_t i = 0; i < kAndroidRoundedRectRadiiCount; ++i) {
    if (std::fabs(radii[i] - other.radii[i]) > kFloatComparisonEpsilon) {
      return false;
    }
  }
  return true;
}

// =============================================================================
// AndroidPathSegment & AndroidClipPath (Structure-of-Arrays FlutterPath)
// =============================================================================

bool AndroidPathSegment::operator==(const AndroidPathSegment& other) const {
  if (verb != other.verb) {
    return false;
  }
  size_t point_count = 0;
  switch (verb) {
    case AndroidPathVerb::kMove:
    case AndroidPathVerb::kLine:
      point_count = kSinglePointVerbCount;
      break;
    case AndroidPathVerb::kQuad:
      point_count = kQuadraticPointVerbCount;
      break;
    case AndroidPathVerb::kConic:
      point_count = kQuadraticPointVerbCount;
      if (std::fabs(conic_weight - other.conic_weight) >
          kFloatComparisonEpsilon) {
        return false;
      }
      break;
    case AndroidPathVerb::kCubic:
      point_count = kCubicPointVerbCount;
      break;
    case AndroidPathVerb::kClose:
      point_count = 0;
      break;
  }
  for (size_t i = 0; i < point_count; ++i) {
    if (std::fabs(points[i].x - other.points[i].x) > kFloatComparisonEpsilon ||
        std::fabs(points[i].y - other.points[i].y) > kFloatComparisonEpsilon) {
      return false;
    }
  }
  return true;
}

AndroidClipPath AndroidClipPath::FromFlutterPath(const FlutterPath& path,
                                                 float scale) {
  AndroidClipPath out;
  const FlutterPath* path_ptr = &path;
  if (path_ptr->struct_size == 0) {
    return out;
  }

  const float safe_scale = SanitizeScale(scale);
  const FlutterPathFillType raw_fill_type =
      SAFE_ACCESS(path_ptr, fill_type, kFlutterPathFillTypeNonZero);
  out.fill_type = (raw_fill_type == kFlutterPathFillTypeEvenOdd)
                      ? AndroidPathFillType::kEvenOdd
                      : AndroidPathFillType::kNonZero;

  const FlutterRect empty_bounds = {0.0, 0.0, 0.0, 0.0};
  const FlutterRect raw_bounds = SAFE_ACCESS(path_ptr, bounds, empty_bounds);
  out.bounds = AndroidRect{
      .left = SanitizeFloat(static_cast<float>(raw_bounds.left) * safe_scale),
      .top = SanitizeFloat(static_cast<float>(raw_bounds.top) * safe_scale),
      .right = SanitizeFloat(static_cast<float>(raw_bounds.right) * safe_scale),
      .bottom =
          SanitizeFloat(static_cast<float>(raw_bounds.bottom) * safe_scale),
  };

  const size_t verbs_count = SAFE_ACCESS(path_ptr, verbs_count, 0u);
  const FlutterPathVerb* verbs = SAFE_ACCESS(path_ptr, verbs, nullptr);
  const size_t points_count = SAFE_ACCESS(path_ptr, points_count, 0u);
  const FlutterPoint* points = SAFE_ACCESS(path_ptr, points, nullptr);
  const size_t conic_weights_count =
      SAFE_ACCESS(path_ptr, conic_weights_count, 0u);
  const double* conic_weights = SAFE_ACCESS(path_ptr, conic_weights, nullptr);

  if (verbs == nullptr || verbs_count == 0) {
    return out;
  }

  auto read_scaled_point = [&](size_t idx) -> FlutterPoint {
    const double px =
        SanitizeFloat(static_cast<float>(points[idx].x)) * safe_scale;
    const double py =
        SanitizeFloat(static_cast<float>(points[idx].y)) * safe_scale;
    return FlutterPoint{px, py};
  };

  out.segments.reserve(verbs_count);
  out.verbs.reserve(verbs_count);

  size_t point_idx = 0;
  size_t weight_idx = 0;
  for (size_t i = 0; i < verbs_count; ++i) {
    const FlutterPathVerb v = verbs[i];
    AndroidPathSegment seg;
    switch (v) {
      case kFlutterPathVerbMove: {
        if (points == nullptr ||
            point_idx + kSinglePointVerbCount > points_count) {
          return out;
        }
        seg.verb = AndroidPathVerb::kMove;
        seg.points[0] = read_scaled_point(point_idx);
        out.points.push_back(seg.points[0]);
        point_idx += kSinglePointVerbCount;
        break;
      }
      case kFlutterPathVerbLine: {
        if (points == nullptr ||
            point_idx + kSinglePointVerbCount > points_count) {
          return out;
        }
        seg.verb = AndroidPathVerb::kLine;
        seg.points[0] = read_scaled_point(point_idx);
        out.points.push_back(seg.points[0]);
        point_idx += kSinglePointVerbCount;
        break;
      }
      case kFlutterPathVerbQuad: {
        if (points == nullptr ||
            point_idx + kQuadraticPointVerbCount > points_count) {
          return out;
        }
        seg.verb = AndroidPathVerb::kQuad;
        seg.points[0] = read_scaled_point(point_idx);
        seg.points[1] = read_scaled_point(point_idx + 1);
        out.points.push_back(seg.points[0]);
        out.points.push_back(seg.points[1]);
        point_idx += kQuadraticPointVerbCount;
        break;
      }
      case kFlutterPathVerbConic: {
        if (points == nullptr ||
            point_idx + kQuadraticPointVerbCount > points_count ||
            conic_weights == nullptr || weight_idx >= conic_weights_count) {
          return out;
        }
        seg.verb = AndroidPathVerb::kConic;
        seg.points[0] = read_scaled_point(point_idx);
        seg.points[1] = read_scaled_point(point_idx + 1);
        const float weight = SanitizeFloat(
            static_cast<float>(conic_weights[weight_idx]), kDefaultConicWeight);
        seg.conic_weight = weight;
        out.points.push_back(seg.points[0]);
        out.points.push_back(seg.points[1]);
        out.conic_weights.push_back(static_cast<double>(weight));
        point_idx += kQuadraticPointVerbCount;
        weight_idx += 1;
        break;
      }
      case kFlutterPathVerbCubic: {
        if (points == nullptr ||
            point_idx + kCubicPointVerbCount > points_count) {
          return out;
        }
        seg.verb = AndroidPathVerb::kCubic;
        seg.points[0] = read_scaled_point(point_idx);
        seg.points[1] = read_scaled_point(point_idx + 1);
        seg.points[2] = read_scaled_point(point_idx + 2);
        out.points.push_back(seg.points[0]);
        out.points.push_back(seg.points[1]);
        out.points.push_back(seg.points[2]);
        point_idx += kCubicPointVerbCount;
        break;
      }
      case kFlutterPathVerbClose: {
        seg.verb = AndroidPathVerb::kClose;
        break;
      }
      default:
        return out;
    }
    out.verbs.push_back(v);
    out.segments.push_back(seg);
  }
  return out;
}

bool AndroidClipPath::operator==(const AndroidClipPath& other) const {
  return fill_type == other.fill_type && bounds == other.bounds &&
         segments == other.segments;
}

// =============================================================================
// AndroidMutator
// =============================================================================

AndroidMutator AndroidMutator::ClipRect(const AndroidRect& rect) {
  AndroidMutator m;
  m.type = AndroidMutatorType::kClipRect;
  m.rect = rect;
  return m;
}

AndroidMutator AndroidMutator::ClipRRect(const AndroidRoundedRect& rrect) {
  AndroidMutator m;
  m.type = AndroidMutatorType::kClipRRect;
  m.rrect = rrect;
  m.rect = rrect.rect;
  return m;
}

AndroidMutator AndroidMutator::ClipPath(const AndroidClipPath& path) {
  AndroidMutator m;
  m.type = AndroidMutatorType::kClipPath;
  m.path = path;
  m.rect = path.bounds;
  return m;
}

AndroidMutator AndroidMutator::Transform(const AndroidMatrix3x3& matrix) {
  AndroidMutator m;
  m.type = AndroidMutatorType::kTransform;
  m.matrix = matrix;
  return m;
}

AndroidMutator AndroidMutator::Opacity(float opacity) {
  AndroidMutator m;
  m.type = AndroidMutatorType::kOpacity;
  m.opacity =
      std::clamp(SanitizeFloat(opacity, kMaxOpacity), kMinOpacity, kMaxOpacity);
  return m;
}

bool AndroidMutator::operator==(const AndroidMutator& other) const {
  if (type != other.type) {
    return false;
  }
  switch (type) {
    case AndroidMutatorType::kClipRect:
      return rect == other.rect;
    case AndroidMutatorType::kClipRRect:
      return rrect == other.rrect;
    case AndroidMutatorType::kClipPath:
      return path == other.path;
    case AndroidMutatorType::kTransform:
      return matrix == other.matrix;
    case AndroidMutatorType::kOpacity:
      return std::fabs(opacity - other.opacity) <= kFloatComparisonEpsilon;
  }
  return false;
}

bool SurfaceControlTransactionTransform::operator==(
    const SurfaceControlTransactionTransform& other) const {
  return std::fabs(position_x - other.position_x) <= kFloatComparisonEpsilon &&
         std::fabs(position_y - other.position_y) <= kFloatComparisonEpsilon &&
         std::fabs(dsdx - other.dsdx) <= kFloatComparisonEpsilon &&
         std::fabs(dtdx - other.dtdx) <= kFloatComparisonEpsilon &&
         std::fabs(dtdy - other.dtdy) <= kFloatComparisonEpsilon &&
         std::fabs(dsdy - other.dsdy) <= kFloatComparisonEpsilon &&
         std::fabs(alpha - other.alpha) <= kFloatComparisonEpsilon &&
         has_crop == other.has_crop && crop_left == other.crop_left &&
         crop_top == other.crop_top && crop_right == other.crop_right &&
         crop_bottom == other.crop_bottom &&
         corner_radius == other.corner_radius;
}

// =============================================================================
// AndroidMutatorsStack
// =============================================================================

AndroidMutatorsStack::AndroidMutatorsStack() = default;
AndroidMutatorsStack::~AndroidMutatorsStack() = default;

namespace {

AndroidRect TransformRectByMatrix(const AndroidMatrix3x3& m,
                                  const AndroidRect& r) {
  auto transform_pt = [&m](float x, float y) -> std::pair<float, float> {
    const float w = m.values[kMatrixPersp0Index] * x +
                    m.values[kMatrixPersp1Index] * y +
                    m.values[kMatrixPersp2Index];
    const float inv_w =
        (std::fabs(w) > kFloatComparisonEpsilon) ? (1.0f / w) : 1.0f;
    const float tx =
        (m.values[kMatrixScaleXIndex] * x + m.values[kMatrixSkewXIndex] * y +
         m.values[kMatrixTransXIndex]) *
        inv_w;
    const float ty =
        (m.values[kMatrixSkewYIndex] * x + m.values[kMatrixScaleYIndex] * y +
         m.values[kMatrixTransYIndex]) *
        inv_w;
    return {tx, ty};
  };

  const std::array<std::pair<float, float>, kRectangleCornerCount> corners = {
      transform_pt(r.left, r.top),
      transform_pt(r.right, r.top),
      transform_pt(r.right, r.bottom),
      transform_pt(r.left, r.bottom),
  };

  float min_x = corners[0].first;
  float max_x = corners[0].first;
  float min_y = corners[0].second;
  float max_y = corners[0].second;
  for (size_t i = 1; i < kRectangleCornerCount; ++i) {
    min_x = std::min(min_x, corners[i].first);
    max_x = std::max(max_x, corners[i].first);
    min_y = std::min(min_y, corners[i].second);
    max_y = std::max(max_y, corners[i].second);
  }
  return AndroidRect{min_x, min_y, max_x, max_y};
}

}  // namespace

void AndroidMutatorsStack::PushTransform(const AndroidMatrix3x3& matrix) {
  mutators_.push_back(AndroidMutator::Transform(matrix));
  final_matrix_ = AndroidMatrix3x3::Multiply(final_matrix_, matrix);
}

void AndroidMutatorsStack::PushClipRect(const AndroidRect& rect) {
  mutators_.push_back(AndroidMutator::ClipRect(rect));
  final_clip_rects_.push_back(TransformRectByMatrix(final_matrix_, rect));
}

void AndroidMutatorsStack::PushClipRRect(const AndroidRoundedRect& rrect) {
  mutators_.push_back(AndroidMutator::ClipRRect(rrect));
  AndroidRoundedRect transformed = rrect;
  transformed.rect = TransformRectByMatrix(final_matrix_, rrect.rect);
  const float sx = std::hypot(final_matrix_.values[kMatrixScaleXIndex],
                              final_matrix_.values[kMatrixSkewYIndex]);
  const float sy = std::hypot(final_matrix_.values[kMatrixSkewXIndex],
                              final_matrix_.values[kMatrixScaleYIndex]);
  for (size_t i = 0; i < kAndroidRoundedRectRadiiCount; i += 2) {
    transformed.radii[i] = rrect.radii[i] * sx;
    transformed.radii[i + 1] = rrect.radii[i + 1] * sy;
  }
  final_clip_rrects_.push_back(transformed);
  final_clip_rects_.push_back(transformed.rect);
}

void AndroidMutatorsStack::PushClipPath(const AndroidClipPath& path) {
  mutators_.push_back(AndroidMutator::ClipPath(path));
  AndroidClipPath transformed = path;
  for (auto& seg : transformed.segments) {
    size_t pt_count = 0;
    switch (seg.verb) {
      case AndroidPathVerb::kMove:
      case AndroidPathVerb::kLine:
        pt_count = kSinglePointVerbCount;
        break;
      case AndroidPathVerb::kQuad:
      case AndroidPathVerb::kConic:
        pt_count = kQuadraticPointVerbCount;
        break;
      case AndroidPathVerb::kCubic:
        pt_count = kCubicPointVerbCount;
        break;
      case AndroidPathVerb::kClose:
        pt_count = 0;
        break;
    }
    for (size_t i = 0; i < pt_count; ++i) {
      const float x = static_cast<float>(seg.points[i].x);
      const float y = static_cast<float>(seg.points[i].y);
      const float w = final_matrix_.values[kMatrixPersp0Index] * x +
                      final_matrix_.values[kMatrixPersp1Index] * y +
                      final_matrix_.values[kMatrixPersp2Index];
      const float inv_w =
          (std::fabs(w) > kFloatComparisonEpsilon) ? (1.0f / w) : 1.0f;
      seg.points[i].x = (final_matrix_.values[kMatrixScaleXIndex] * x +
                         final_matrix_.values[kMatrixSkewXIndex] * y +
                         final_matrix_.values[kMatrixTransXIndex]) *
                        inv_w;
      seg.points[i].y = (final_matrix_.values[kMatrixSkewYIndex] * x +
                         final_matrix_.values[kMatrixScaleYIndex] * y +
                         final_matrix_.values[kMatrixTransYIndex]) *
                        inv_w;
    }
  }
  transformed.bounds = TransformRectByMatrix(final_matrix_, path.bounds);
  final_clip_paths_.push_back(std::move(transformed));
}

void AndroidMutatorsStack::PushOpacity(float opacity) {
  const AndroidMutator m = AndroidMutator::Opacity(opacity);
  mutators_.push_back(m);
  final_opacity_ =
      std::clamp(final_opacity_ * m.opacity, kMinOpacity, kMaxOpacity);
}

AndroidMatrix3x3 AndroidMutatorsStack::GetPlatformViewMatrix(
    float view_x,
    float view_y) const {
  return AndroidMatrix3x3::PreTranslate(final_matrix_, view_x, view_y);
}

SurfaceControlTransactionTransform
AndroidMutatorsStack::GetSurfaceControlTransactionTransform(
    float view_x,
    float view_y,
    float view_width,
    float view_height) const {
  SurfaceControlTransactionTransform out;
  const AndroidMatrix3x3 m = GetPlatformViewMatrix(view_x, view_y);
  out.position_x = m.values[kMatrixTransXIndex];
  out.position_y = m.values[kMatrixTransYIndex];
  out.dsdx = m.values[kMatrixScaleXIndex];
  out.dtdx = m.values[kMatrixSkewYIndex];
  out.dtdy = m.values[kMatrixSkewXIndex];
  out.dsdy = m.values[kMatrixScaleYIndex];
  out.alpha = final_opacity_;

  if (!final_clip_rects_.empty()) {
    out.has_crop = true;
    AndroidRect combined = final_clip_rects_.front();
    for (size_t i = 1; i < final_clip_rects_.size(); ++i) {
      combined.left = std::max(combined.left, final_clip_rects_[i].left);
      combined.top = std::max(combined.top, final_clip_rects_[i].top);
      combined.right = std::min(combined.right, final_clip_rects_[i].right);
      combined.bottom = std::min(combined.bottom, final_clip_rects_[i].bottom);
    }
    const float local_left = std::max(0.0f, combined.left - out.position_x);
    const float local_top = std::max(0.0f, combined.top - out.position_y);
    const float local_right =
        std::min(std::max(0.0f, view_width), combined.right - out.position_x);
    const float local_bottom =
        std::min(std::max(0.0f, view_height), combined.bottom - out.position_y);
    out.crop_left = static_cast<int32_t>(std::round(local_left));
    out.crop_top = static_cast<int32_t>(std::round(local_top));
    out.crop_right =
        static_cast<int32_t>(std::round(std::max(local_left, local_right)));
    out.crop_bottom =
        static_cast<int32_t>(std::round(std::max(local_top, local_bottom)));
  }

  for (const auto& rrect : final_clip_rrects_) {
    float radius = 0.0f;
    if (rrect.IsUniformCornerRadius(&radius) && radius > 0.0f) {
      out.corner_radius = static_cast<int32_t>(std::round(radius));
    }
  }
  return out;
}

std::vector<uint8_t> AndroidMutatorsStack::Serialize() const {
  std::vector<uint8_t> out;
  AppendScalar(out, kSerializationMagic);
  AppendScalar(out, kSerializationVersion);
  const uint32_t count = static_cast<uint32_t>(mutators_.size());
  AppendScalar(out, count);

  for (const auto& m : mutators_) {
    AppendScalar(out, static_cast<int32_t>(m.type));
    switch (m.type) {
      case AndroidMutatorType::kClipRect:
        AppendScalar(out, m.rect.left);
        AppendScalar(out, m.rect.top);
        AppendScalar(out, m.rect.right);
        AppendScalar(out, m.rect.bottom);
        break;
      case AndroidMutatorType::kClipRRect:
        AppendScalar(out, m.rrect.rect.left);
        AppendScalar(out, m.rrect.rect.top);
        AppendScalar(out, m.rrect.rect.right);
        AppendScalar(out, m.rrect.rect.bottom);
        for (float r : m.rrect.radii) {
          AppendScalar(out, r);
        }
        break;
      case AndroidMutatorType::kClipPath: {
        AppendScalar(out, static_cast<int32_t>(m.path.fill_type));
        AppendScalar(out, m.path.bounds.left);
        AppendScalar(out, m.path.bounds.top);
        AppendScalar(out, m.path.bounds.right);
        AppendScalar(out, m.path.bounds.bottom);
        const uint32_t seg_count =
            static_cast<uint32_t>(m.path.segments.size());
        AppendScalar(out, seg_count);
        for (const auto& seg : m.path.segments) {
          AppendScalar(out, static_cast<int32_t>(seg.verb));
          for (size_t i = 0; i < kMaxPathSegmentPoints; ++i) {
            AppendScalar(out, seg.points[i].x);
            AppendScalar(out, seg.points[i].y);
          }
          AppendScalar(out, seg.conic_weight);
        }
        break;
      }
      case AndroidMutatorType::kTransform:
        for (float v : m.matrix.values) {
          AppendScalar(out, v);
        }
        break;
      case AndroidMutatorType::kOpacity:
        AppendScalar(out, m.opacity);
        break;
    }
  }
  return out;
}

std::optional<AndroidMutatorsStack> AndroidMutatorsStack::Deserialize(
    const uint8_t* data,
    size_t size) {
  if (data == nullptr || size < sizeof(uint32_t) * 3) {
    return std::nullopt;
  }
  const uint8_t* cursor = data;
  const uint8_t* end = data + size;

  uint32_t magic = 0;
  uint32_t version = 0;
  uint32_t count = 0;
  if (!ReadScalar(cursor, end, magic) || !ReadScalar(cursor, end, version) ||
      !ReadScalar(cursor, end, count)) {
    return std::nullopt;
  }
  if (magic != kSerializationMagic || version != kSerializationVersion ||
      count > kMaxSerializedCollectionCount) {
    return std::nullopt;
  }

  AndroidMutatorsStack stack;
  for (uint32_t i = 0; i < count; ++i) {
    int32_t raw_type = 0;
    if (!ReadScalar(cursor, end, raw_type)) {
      return std::nullopt;
    }
    switch (static_cast<AndroidMutatorType>(raw_type)) {
      case AndroidMutatorType::kClipRect: {
        AndroidRect r;
        if (!ReadScalar(cursor, end, r.left) ||
            !ReadScalar(cursor, end, r.top) ||
            !ReadScalar(cursor, end, r.right) ||
            !ReadScalar(cursor, end, r.bottom)) {
          return std::nullopt;
        }
        stack.PushClipRect(r);
        break;
      }
      case AndroidMutatorType::kClipRRect: {
        AndroidRoundedRect rr;
        if (!ReadScalar(cursor, end, rr.rect.left) ||
            !ReadScalar(cursor, end, rr.rect.top) ||
            !ReadScalar(cursor, end, rr.rect.right) ||
            !ReadScalar(cursor, end, rr.rect.bottom)) {
          return std::nullopt;
        }
        for (size_t j = 0; j < kAndroidRoundedRectRadiiCount; ++j) {
          if (!ReadScalar(cursor, end, rr.radii[j])) {
            return std::nullopt;
          }
        }
        stack.PushClipRRect(rr);
        break;
      }
      case AndroidMutatorType::kClipPath: {
        AndroidClipPath path;
        int32_t fill_type = 0;
        uint32_t seg_count = 0;
        if (!ReadScalar(cursor, end, fill_type) ||
            !ReadScalar(cursor, end, path.bounds.left) ||
            !ReadScalar(cursor, end, path.bounds.top) ||
            !ReadScalar(cursor, end, path.bounds.right) ||
            !ReadScalar(cursor, end, path.bounds.bottom) ||
            !ReadScalar(cursor, end, seg_count) ||
            seg_count > kMaxSerializedCollectionCount) {
          return std::nullopt;
        }
        path.fill_type = (fill_type == 1) ? AndroidPathFillType::kEvenOdd
                                          : AndroidPathFillType::kNonZero;
        path.segments.reserve(seg_count);
        for (uint32_t s = 0; s < seg_count; ++s) {
          AndroidPathSegment seg;
          int32_t verb = 0;
          if (!ReadScalar(cursor, end, verb)) {
            return std::nullopt;
          }
          if (verb < static_cast<int32_t>(AndroidPathVerb::kMove) ||
              verb > static_cast<int32_t>(AndroidPathVerb::kClose)) {
            return std::nullopt;
          }
          seg.verb = static_cast<AndroidPathVerb>(verb);
          for (size_t p = 0; p < kMaxPathSegmentPoints; ++p) {
            if (!ReadScalar(cursor, end, seg.points[p].x) ||
                !ReadScalar(cursor, end, seg.points[p].y)) {
              return std::nullopt;
            }
          }
          if (!ReadScalar(cursor, end, seg.conic_weight)) {
            return std::nullopt;
          }
          path.segments.push_back(seg);
        }
        stack.PushClipPath(path);
        break;
      }
      case AndroidMutatorType::kTransform: {
        AndroidMatrix3x3 m;
        for (size_t j = 0; j < kAndroidMatrixElementCount; ++j) {
          if (!ReadScalar(cursor, end, m.values[j])) {
            return std::nullopt;
          }
        }
        stack.PushTransform(m);
        break;
      }
      case AndroidMutatorType::kOpacity: {
        float op = 1.0f;
        if (!ReadScalar(cursor, end, op)) {
          return std::nullopt;
        }
        stack.PushOpacity(op);
        break;
      }
      default:
        return std::nullopt;
    }
  }
  return stack;
}

bool AndroidMutatorsStack::operator==(const AndroidMutatorsStack& other) const {
  return mutators_ == other.mutators_;
}

// =============================================================================
// AndroidMutatorsMapper
// =============================================================================

AndroidMutatorsMapper::AndroidMutatorsMapper() {
  TRACE_EVENT0("flutter", "AndroidMutatorsMapper::AndroidMutatorsMapper");
}

AndroidMutatorsMapper::~AndroidMutatorsMapper() {
  TRACE_EVENT0("flutter", "AndroidMutatorsMapper::~AndroidMutatorsMapper");
}

bool AndroidMutatorsMapper::RegisterJNI(JNIEnv* env) {
  TRACE_EVENT0("flutter", "AndroidMutatorsMapper::RegisterJNI");
  if (env == nullptr) {
    return false;
  }

  jclass stack_clazz = env->FindClass(
      "io/flutter/embedding/engine/mutatorsstack/FlutterMutatorsStack");
  if (ClearJniExceptionSafe(env) || stack_clazz == nullptr) {
    FML_LOG(ERROR) << "Could not locate FlutterMutatorsStack class";
    return false;
  }
  g_mutators_stack_class =
      new fml::jni::ScopedJavaGlobalRef<jclass>(env, stack_clazz);
  env->DeleteLocalRef(stack_clazz);

  g_stack_constructor =
      env->GetMethodID(g_mutators_stack_class->obj(), "<init>", "()V");
  ClearJniExceptionSafe(env);
  g_stack_push_transform_method =
      env->GetMethodID(g_mutators_stack_class->obj(), "pushTransform", "([F)V");
  ClearJniExceptionSafe(env);
  g_stack_clip_rect_takes_float = true;
  g_stack_push_clip_rect_method = env->GetMethodID(
      g_mutators_stack_class->obj(), "pushClipRect", "(FFFF)V");
  if (ClearJniExceptionSafe(env) || g_stack_push_clip_rect_method == nullptr) {
    g_stack_clip_rect_takes_float = false;
    g_stack_push_clip_rect_method = env->GetMethodID(
        g_mutators_stack_class->obj(), "pushClipRect", "(IIII)V");
    ClearJniExceptionSafe(env);
  }
  g_stack_clip_rrect_takes_float = true;
  g_stack_push_clip_rrect_method = env->GetMethodID(
      g_mutators_stack_class->obj(), "pushClipRRect", "(FFFF[F)V");
  if (ClearJniExceptionSafe(env) || g_stack_push_clip_rrect_method == nullptr) {
    g_stack_clip_rrect_takes_float = false;
    g_stack_push_clip_rrect_method = env->GetMethodID(
        g_mutators_stack_class->obj(), "pushClipRRect", "(IIII[F)V");
    ClearJniExceptionSafe(env);
  }
  g_stack_push_clip_path_method =
      env->GetMethodID(g_mutators_stack_class->obj(), "pushClipPath",
                       "(Landroid/graphics/Path;)V");
  ClearJniExceptionSafe(env);
  g_stack_push_opacity_method =
      env->GetMethodID(g_mutators_stack_class->obj(), "pushOpacity", "(F)V");

  if (ClearJniExceptionSafe(env) || g_stack_constructor == nullptr ||
      g_stack_push_transform_method == nullptr ||
      g_stack_push_clip_rect_method == nullptr ||
      g_stack_push_clip_rrect_method == nullptr ||
      g_stack_push_clip_path_method == nullptr ||
      g_stack_push_opacity_method == nullptr) {
    FML_LOG(ERROR) << "Could not locate FlutterMutatorsStack methods";
    return false;
  }

  jclass path_clazz = env->FindClass("android/graphics/Path");
  if (ClearJniExceptionSafe(env) || path_clazz == nullptr) {
    FML_LOG(ERROR) << "Could not locate android.graphics.Path class";
    return false;
  }
  g_path_class = new fml::jni::ScopedJavaGlobalRef<jclass>(env, path_clazz);
  env->DeleteLocalRef(path_clazz);

  g_path_constructor = env->GetMethodID(g_path_class->obj(), "<init>", "()V");
  ClearJniExceptionSafe(env);
  g_path_set_fill_type_method =
      env->GetMethodID(g_path_class->obj(), "setFillType",
                       "(Landroid/graphics/Path$FillType;)V");
  ClearJniExceptionSafe(env);
  g_path_move_to_method =
      env->GetMethodID(g_path_class->obj(), "moveTo", "(FF)V");
  ClearJniExceptionSafe(env);
  g_path_line_to_method =
      env->GetMethodID(g_path_class->obj(), "lineTo", "(FF)V");
  ClearJniExceptionSafe(env);
  g_path_quad_to_method =
      env->GetMethodID(g_path_class->obj(), "quadTo", "(FFFF)V");
  ClearJniExceptionSafe(env);
  g_path_cubic_to_method =
      env->GetMethodID(g_path_class->obj(), "cubicTo", "(FFFFFF)V");
  ClearJniExceptionSafe(env);
  g_path_close_method = env->GetMethodID(g_path_class->obj(), "close", "()V");

  if (ClearJniExceptionSafe(env) || g_path_constructor == nullptr ||
      g_path_set_fill_type_method == nullptr ||
      g_path_move_to_method == nullptr || g_path_line_to_method == nullptr ||
      g_path_quad_to_method == nullptr || g_path_cubic_to_method == nullptr ||
      g_path_close_method == nullptr) {
    FML_LOG(ERROR) << "Could not locate android.graphics.Path methods";
    return false;
  }

  // Path.conicTo(float, float, float, float, float) was added in API 34.
  // Clear any NoSuchMethodError immediately so CheckJNI remains clean on API
  // < 34.
  g_path_conic_to_method =
      env->GetMethodID(g_path_class->obj(), "conicTo", "(FFFFF)V");
  if (ClearJniExceptionSafe(env)) {
    g_path_conic_to_method = nullptr;
  }

  jclass fill_type_clazz = env->FindClass("android/graphics/Path$FillType");
  if (ClearJniExceptionSafe(env) || fill_type_clazz == nullptr) {
    FML_LOG(ERROR) << "Could not locate android.graphics.Path$FillType class";
    return false;
  }
  g_path_fill_type_class =
      new fml::jni::ScopedJavaGlobalRef<jclass>(env, fill_type_clazz);
  env->DeleteLocalRef(fill_type_clazz);

  g_fill_type_winding_field =
      env->GetStaticFieldID(g_path_fill_type_class->obj(), "WINDING",
                            "Landroid/graphics/Path$FillType;");
  ClearJniExceptionSafe(env);
  g_fill_type_even_odd_field =
      env->GetStaticFieldID(g_path_fill_type_class->obj(), "EVEN_ODD",
                            "Landroid/graphics/Path$FillType;");
  if (ClearJniExceptionSafe(env) || g_fill_type_winding_field == nullptr ||
      g_fill_type_even_odd_field == nullptr) {
    FML_LOG(ERROR) << "Could not locate Path.FillType static fields";
    return false;
  }

  return true;
}

bool AndroidMutatorsMapper::EnsureJniRegistered(JNIEnv* env) {
  if (g_mutators_stack_class != nullptr && g_stack_constructor != nullptr) {
    return true;
  }
  return RegisterJNI(env);
}

std::optional<AndroidMutator> AndroidMutatorsMapper::MapMutation(
    const FlutterPlatformViewMutation& mutation) {
  TRACE_EVENT0("flutter", "AndroidMutatorsMapper::MapMutation");
  switch (mutation.type) {
    case kFlutterPlatformViewMutationTypeOpacity:
      return AndroidMutator::Opacity(static_cast<float>(mutation.opacity));
    case kFlutterPlatformViewMutationTypeClipRect:
      return AndroidMutator::ClipRect(
          AndroidRect::FromFlutterRect(mutation.clip_rect));
    case kFlutterPlatformViewMutationTypeClipRoundedRect:
      return AndroidMutator::ClipRRect(
          AndroidRoundedRect::FromFlutterRoundedRect(
              mutation.clip_rounded_rect));
    case kFlutterPlatformViewMutationTypeTransformation:
      return AndroidMutator::Transform(
          AndroidMatrix3x3::FromFlutterTransformation(mutation.transformation));
    case kFlutterPlatformViewMutationTypeClipPath:
      return AndroidMutator::ClipPath(
          AndroidClipPath::FromFlutterPath(mutation.clip_path));
    default:
      return std::nullopt;
  }
}

AndroidMutatorsStack AndroidMutatorsMapper::MapMutations(
    const FlutterPlatformViewMutation* const* mutations,
    size_t mutations_count) {
  TRACE_EVENT0("flutter", "AndroidMutatorsMapper::MapMutations");
  AndroidMutatorsStack stack;
  if (mutations == nullptr || mutations_count == 0) {
    return stack;
  }

  for (size_t i = 0; i < mutations_count; ++i) {
    const FlutterPlatformViewMutation* mutation = mutations[i];
    if (mutation == nullptr) {
      continue;
    }
    switch (mutation->type) {
      case kFlutterPlatformViewMutationTypeOpacity:
        stack.PushOpacity(static_cast<float>(mutation->opacity));
        break;
      case kFlutterPlatformViewMutationTypeClipRect:
        stack.PushClipRect(AndroidRect::FromFlutterRect(mutation->clip_rect));
        break;
      case kFlutterPlatformViewMutationTypeClipRoundedRect:
        stack.PushClipRRect(AndroidRoundedRect::FromFlutterRoundedRect(
            mutation->clip_rounded_rect));
        break;
      case kFlutterPlatformViewMutationTypeTransformation:
        stack.PushTransform(AndroidMatrix3x3::FromFlutterTransformation(
            mutation->transformation));
        break;
      case kFlutterPlatformViewMutationTypeClipPath:
        stack.PushClipPath(
            AndroidClipPath::FromFlutterPath(mutation->clip_path));
        break;
      default:
        break;
    }
  }
  return stack;
}

AndroidMutatorsStack AndroidMutatorsMapper::MapPlatformView(
    const FlutterPlatformView& platform_view) {
  TRACE_EVENT0("flutter", "AndroidMutatorsMapper::MapPlatformView");
  const FlutterPlatformView* view_ptr = &platform_view;
  if (view_ptr->struct_size < sizeof(FlutterPlatformView)) {
    return AndroidMutatorsStack{};
  }
  const size_t mutations_count = SAFE_ACCESS(view_ptr, mutations_count, 0u);
  const FlutterPlatformViewMutation* const* mutations =
      SAFE_ACCESS(view_ptr, mutations, nullptr);
  return MapMutations(mutations, mutations_count);
}

std::vector<float> AndroidMutatorsMapper::TransformToAndroidMatrix(
    const FlutterTransformation& transform,
    double device_pixel_ratio) {
  const float scale = SanitizeScale(device_pixel_ratio);
  return {
      SanitizeFloat(static_cast<float>(transform.scaleX), 1.0f),
      SanitizeFloat(static_cast<float>(transform.skewX), 0.0f),
      SanitizeFloat(static_cast<float>(transform.transX) * scale, 0.0f),
      SanitizeFloat(static_cast<float>(transform.skewY), 0.0f),
      SanitizeFloat(static_cast<float>(transform.scaleY), 1.0f),
      SanitizeFloat(static_cast<float>(transform.transY) * scale, 0.0f),
      SanitizeFloat(static_cast<float>(transform.pers0), 0.0f),
      SanitizeFloat(static_cast<float>(transform.pers1), 0.0f),
      SanitizeFloat(static_cast<float>(transform.pers2), 1.0f),
  };
}

std::vector<float> AndroidMutatorsMapper::RadiiToAndroidArray(
    const FlutterSize& upper_left,
    const FlutterSize& upper_right,
    const FlutterSize& lower_right,
    const FlutterSize& lower_left,
    double device_pixel_ratio) {
  const float scale = SanitizeScale(device_pixel_ratio);
  return {
      SanitizeFloat(static_cast<float>(upper_left.width) * scale),
      SanitizeFloat(static_cast<float>(upper_left.height) * scale),
      SanitizeFloat(static_cast<float>(upper_right.width) * scale),
      SanitizeFloat(static_cast<float>(upper_right.height) * scale),
      SanitizeFloat(static_cast<float>(lower_right.width) * scale),
      SanitizeFloat(static_cast<float>(lower_right.height) * scale),
      SanitizeFloat(static_cast<float>(lower_left.width) * scale),
      SanitizeFloat(static_cast<float>(lower_left.height) * scale),
  };
}

std::vector<AndroidMutatorRecord> AndroidMutatorsMapper::ParseMutations(
    size_t mutations_count,
    const FlutterPlatformViewMutation* const* mutations,
    double device_pixel_ratio) {
  TRACE_EVENT0("flutter", "AndroidMutatorsMapper::ParseMutations");
  std::vector<AndroidMutatorRecord> records;
  if (mutations == nullptr || mutations_count == 0) {
    return records;
  }

  const float scale = SanitizeScale(device_pixel_ratio);
  records.reserve(mutations_count);

  for (size_t i = 0; i < mutations_count; ++i) {
    const FlutterPlatformViewMutation* mutation = mutations[i];
    if (mutation == nullptr) {
      continue;
    }

    AndroidMutatorRecord record;
    record.type = mutation->type;

    switch (mutation->type) {
      case kFlutterPlatformViewMutationTypeOpacity: {
        const float op =
            SanitizeFloat(static_cast<float>(mutation->opacity), kMaxOpacity);
        record.opacity = std::clamp(op, kMinOpacity, kMaxOpacity);
        records.push_back(std::move(record));
        break;
      }
      case kFlutterPlatformViewMutationTypeClipRect: {
        const FlutterRect& r = mutation->clip_rect;
        record.rect_left_f = SanitizeFloat(static_cast<float>(r.left)) * scale;
        record.rect_top_f = SanitizeFloat(static_cast<float>(r.top)) * scale;
        record.rect_right_f =
            SanitizeFloat(static_cast<float>(r.right)) * scale;
        record.rect_bottom_f =
            SanitizeFloat(static_cast<float>(r.bottom)) * scale;
        record.has_float_rect = true;
        record.rect_left = static_cast<int32_t>(std::round(record.rect_left_f));
        record.rect_top = static_cast<int32_t>(std::round(record.rect_top_f));
        record.rect_right =
            static_cast<int32_t>(std::round(record.rect_right_f));
        record.rect_bottom =
            static_cast<int32_t>(std::round(record.rect_bottom_f));
        records.push_back(std::move(record));
        break;
      }
      case kFlutterPlatformViewMutationTypeClipRoundedRect: {
        const FlutterRoundedRect& rr = mutation->clip_rounded_rect;
        record.rect_left_f =
            SanitizeFloat(static_cast<float>(rr.rect.left)) * scale;
        record.rect_top_f =
            SanitizeFloat(static_cast<float>(rr.rect.top)) * scale;
        record.rect_right_f =
            SanitizeFloat(static_cast<float>(rr.rect.right)) * scale;
        record.rect_bottom_f =
            SanitizeFloat(static_cast<float>(rr.rect.bottom)) * scale;
        record.has_float_rect = true;
        record.rect_left = static_cast<int32_t>(std::round(record.rect_left_f));
        record.rect_top = static_cast<int32_t>(std::round(record.rect_top_f));
        record.rect_right =
            static_cast<int32_t>(std::round(record.rect_right_f));
        record.rect_bottom =
            static_cast<int32_t>(std::round(record.rect_bottom_f));
        record.radii = RadiiToAndroidArray(
            rr.upper_left_corner_radius, rr.upper_right_corner_radius,
            rr.lower_right_corner_radius, rr.lower_left_corner_radius,
            device_pixel_ratio);
        records.push_back(std::move(record));
        break;
      }
      case kFlutterPlatformViewMutationTypeTransformation: {
        record.matrix = TransformToAndroidMatrix(mutation->transformation,
                                                 device_pixel_ratio);
        records.push_back(std::move(record));
        break;
      }
      case kFlutterPlatformViewMutationTypeClipPath: {
        const AndroidClipPath clip_path =
            AndroidClipPath::FromFlutterPath(mutation->clip_path, scale);
        record.path_fill_type =
            (clip_path.fill_type == AndroidPathFillType::kEvenOdd)
                ? kFlutterPathFillTypeEvenOdd
                : kFlutterPathFillTypeNonZero;
        record.path_segments = clip_path.segments;
        record.path_verbs = clip_path.verbs;
        record.path_points = clip_path.points;
        record.path_conic_weights = clip_path.conic_weights;
        record.path_bounds = clip_path.bounds;
        record.rect_left_f = clip_path.bounds.left;
        record.rect_top_f = clip_path.bounds.top;
        record.rect_right_f = clip_path.bounds.right;
        record.rect_bottom_f = clip_path.bounds.bottom;
        record.has_float_rect = true;
        record.rect_left =
            static_cast<int32_t>(std::round(clip_path.bounds.left));
        record.rect_top =
            static_cast<int32_t>(std::round(clip_path.bounds.top));
        record.rect_right =
            static_cast<int32_t>(std::round(clip_path.bounds.right));
        record.rect_bottom =
            static_cast<int32_t>(std::round(clip_path.bounds.bottom));
        records.push_back(std::move(record));
        break;
      }
      default:
        break;
    }
  }
  return records;
}

jobject AndroidMutatorsMapper::CreateJavaMutatorsStack(
    JNIEnv* env,
    size_t mutations_count,
    const FlutterPlatformViewMutation* const* mutations,
    double device_pixel_ratio) {
  const auto records =
      ParseMutations(mutations_count, mutations, device_pixel_ratio);
  return CreateJavaMutatorsStackFromRecords(env, records);
}

jobject AndroidMutatorsMapper::CreateJavaMutatorsStack(
    JNIEnv* env,
    const AndroidMutatorsStack& stack,
    double device_pixel_ratio) {
  const float scale = SanitizeScale(device_pixel_ratio);
  std::vector<AndroidMutatorRecord> records;
  records.reserve(stack.GetMutatorsCount());

  for (const auto& mutator : stack.GetMutators()) {
    AndroidMutatorRecord rec;
    switch (mutator.type) {
      case AndroidMutatorType::kTransform: {
        rec.type = kFlutterPlatformViewMutationTypeTransformation;
        rec.matrix.assign(mutator.matrix.values.begin(),
                          mutator.matrix.values.end());
        rec.matrix[kMatrixTransXIndex] *= scale;
        rec.matrix[kMatrixTransYIndex] *= scale;
        break;
      }
      case AndroidMutatorType::kClipRect: {
        rec.type = kFlutterPlatformViewMutationTypeClipRect;
        rec.rect_left_f = mutator.rect.left * scale;
        rec.rect_top_f = mutator.rect.top * scale;
        rec.rect_right_f = mutator.rect.right * scale;
        rec.rect_bottom_f = mutator.rect.bottom * scale;
        rec.has_float_rect = true;
        rec.rect_left = static_cast<int32_t>(std::round(rec.rect_left_f));
        rec.rect_top = static_cast<int32_t>(std::round(rec.rect_top_f));
        rec.rect_right = static_cast<int32_t>(std::round(rec.rect_right_f));
        rec.rect_bottom = static_cast<int32_t>(std::round(rec.rect_bottom_f));
        break;
      }
      case AndroidMutatorType::kClipRRect: {
        rec.type = kFlutterPlatformViewMutationTypeClipRoundedRect;
        rec.rect_left_f = mutator.rrect.rect.left * scale;
        rec.rect_top_f = mutator.rrect.rect.top * scale;
        rec.rect_right_f = mutator.rrect.rect.right * scale;
        rec.rect_bottom_f = mutator.rrect.rect.bottom * scale;
        rec.has_float_rect = true;
        rec.rect_left = static_cast<int32_t>(std::round(rec.rect_left_f));
        rec.rect_top = static_cast<int32_t>(std::round(rec.rect_top_f));
        rec.rect_right = static_cast<int32_t>(std::round(rec.rect_right_f));
        rec.rect_bottom = static_cast<int32_t>(std::round(rec.rect_bottom_f));
        rec.radii.resize(kAndroidRoundedRectRadiiCount);
        for (size_t i = 0; i < kAndroidRoundedRectRadiiCount; ++i) {
          rec.radii[i] = mutator.rrect.radii[i] * scale;
        }
        break;
      }
      case AndroidMutatorType::kClipPath: {
        rec.type = kFlutterPlatformViewMutationTypeClipPath;
        rec.path_fill_type =
            (mutator.path.fill_type == AndroidPathFillType::kEvenOdd)
                ? kFlutterPathFillTypeEvenOdd
                : kFlutterPathFillTypeNonZero;
        rec.path_segments = mutator.path.segments;
        for (auto& seg : rec.path_segments) {
          for (size_t i = 0; i < kMaxPathSegmentPoints; ++i) {
            seg.points[i].x *= scale;
            seg.points[i].y *= scale;
          }
        }
        rec.path_bounds = AndroidRect{
            mutator.path.bounds.left * scale,
            mutator.path.bounds.top * scale,
            mutator.path.bounds.right * scale,
            mutator.path.bounds.bottom * scale,
        };
        break;
      }
      case AndroidMutatorType::kOpacity: {
        rec.type = kFlutterPlatformViewMutationTypeOpacity;
        rec.opacity = mutator.opacity;
        break;
      }
    }
    records.push_back(std::move(rec));
  }

  return CreateJavaMutatorsStackFromRecords(env, records);
}

jobject AndroidMutatorsMapper::CreateJavaMutatorsStackFromRecords(
    JNIEnv* env,
    const std::vector<AndroidMutatorRecord>& records) {
  TRACE_EVENT0("flutter",
               "AndroidMutatorsMapper::CreateJavaMutatorsStackFromRecords");
  if (env == nullptr) {
    return nullptr;
  }
  if ((g_mutators_stack_class == nullptr || g_stack_constructor == nullptr) &&
      env->functions != nullptr && env->functions->GetJavaVM != nullptr) {
    EnsureJniRegistered(env);
  }
  if (g_mutators_stack_class == nullptr || g_stack_constructor == nullptr) {
    return nullptr;
  }

  jobject raw_stack =
      env->NewObject(g_mutators_stack_class->obj(), g_stack_constructor);
  if (ClearJniExceptionSafe(env) || raw_stack == nullptr) {
    return nullptr;
  }

  for (const auto& record : records) {
    switch (record.type) {
      case kFlutterPlatformViewMutationTypeTransformation: {
        if (record.matrix.size() == kAndroidMatrixElementCount &&
            g_stack_push_transform_method != nullptr) {
          jfloatArray matrix_array = CreateJFloatArraySafe(
              env, record.matrix.data(),
              static_cast<jsize>(kAndroidMatrixElementCount));
          env->CallVoidMethod(raw_stack, g_stack_push_transform_method,
                              matrix_array);
          if (matrix_array != nullptr) {
            env->DeleteLocalRef(matrix_array);
          }
          ClearJniExceptionSafe(env);
        }
        break;
      }
      case kFlutterPlatformViewMutationTypeClipRect: {
        if (g_stack_push_clip_rect_method != nullptr) {
          if (g_stack_clip_rect_takes_float) {
            const float left_f = record.has_float_rect
                                     ? record.rect_left_f
                                     : static_cast<float>(record.rect_left);
            const float top_f = record.has_float_rect
                                    ? record.rect_top_f
                                    : static_cast<float>(record.rect_top);
            const float right_f = record.has_float_rect
                                      ? record.rect_right_f
                                      : static_cast<float>(record.rect_right);
            const float bottom_f = record.has_float_rect
                                       ? record.rect_bottom_f
                                       : static_cast<float>(record.rect_bottom);
            env->CallVoidMethod(
                raw_stack, g_stack_push_clip_rect_method,
                static_cast<jfloat>(left_f), static_cast<jfloat>(top_f),
                static_cast<jfloat>(right_f), static_cast<jfloat>(bottom_f));
          } else {
            env->CallVoidMethod(raw_stack, g_stack_push_clip_rect_method,
                                static_cast<jint>(record.rect_left),
                                static_cast<jint>(record.rect_top),
                                static_cast<jint>(record.rect_right),
                                static_cast<jint>(record.rect_bottom));
          }
          ClearJniExceptionSafe(env);
        }
        break;
      }
      case kFlutterPlatformViewMutationTypeClipRoundedRect: {
        if (record.radii.size() == kAndroidRoundedRectRadiiCount &&
            g_stack_push_clip_rrect_method != nullptr) {
          jfloatArray radii_array = CreateJFloatArraySafe(
              env, record.radii.data(),
              static_cast<jsize>(kAndroidRoundedRectRadiiCount));
          if (g_stack_clip_rrect_takes_float) {
            const float left_f = record.has_float_rect
                                     ? record.rect_left_f
                                     : static_cast<float>(record.rect_left);
            const float top_f = record.has_float_rect
                                    ? record.rect_top_f
                                    : static_cast<float>(record.rect_top);
            const float right_f = record.has_float_rect
                                      ? record.rect_right_f
                                      : static_cast<float>(record.rect_right);
            const float bottom_f = record.has_float_rect
                                       ? record.rect_bottom_f
                                       : static_cast<float>(record.rect_bottom);
            env->CallVoidMethod(raw_stack, g_stack_push_clip_rrect_method,
                                static_cast<jfloat>(left_f),
                                static_cast<jfloat>(top_f),
                                static_cast<jfloat>(right_f),
                                static_cast<jfloat>(bottom_f), radii_array);
          } else {
            env->CallVoidMethod(raw_stack, g_stack_push_clip_rrect_method,
                                static_cast<jint>(record.rect_left),
                                static_cast<jint>(record.rect_top),
                                static_cast<jint>(record.rect_right),
                                static_cast<jint>(record.rect_bottom),
                                radii_array);
          }
          if (radii_array != nullptr) {
            env->DeleteLocalRef(radii_array);
          }
          ClearJniExceptionSafe(env);
        }
        break;
      }
      case kFlutterPlatformViewMutationTypeClipPath: {
        if (g_path_class == nullptr || g_path_constructor == nullptr ||
            g_stack_push_clip_path_method == nullptr) {
          break;
        }
        jobject path_obj =
            env->NewObject(g_path_class->obj(), g_path_constructor);
        if (ClearJniExceptionSafe(env) || path_obj == nullptr) {
          break;
        }

        if (g_path_fill_type_class != nullptr &&
            g_path_set_fill_type_method != nullptr) {
          jfieldID fill_field =
              (record.path_fill_type == kFlutterPathFillTypeEvenOdd)
                  ? g_fill_type_even_odd_field
                  : g_fill_type_winding_field;
          if (fill_field != nullptr) {
            jobject fill_type_obj = env->GetStaticObjectField(
                g_path_fill_type_class->obj(), fill_field);
            if (!ClearJniExceptionSafe(env) && fill_type_obj != nullptr) {
              env->CallVoidMethod(path_obj, g_path_set_fill_type_method,
                                  fill_type_obj);
              ClearJniExceptionSafe(env);
              env->DeleteLocalRef(fill_type_obj);
            }
          }
        }

        for (const auto& seg : record.path_segments) {
          switch (seg.verb) {
            case AndroidPathVerb::kMove:
              env->CallVoidMethod(path_obj, g_path_move_to_method,
                                  static_cast<jfloat>(seg.points[0].x),
                                  static_cast<jfloat>(seg.points[0].y));
              break;
            case AndroidPathVerb::kLine:
              env->CallVoidMethod(path_obj, g_path_line_to_method,
                                  static_cast<jfloat>(seg.points[0].x),
                                  static_cast<jfloat>(seg.points[0].y));
              break;
            case AndroidPathVerb::kQuad:
              env->CallVoidMethod(path_obj, g_path_quad_to_method,
                                  static_cast<jfloat>(seg.points[0].x),
                                  static_cast<jfloat>(seg.points[0].y),
                                  static_cast<jfloat>(seg.points[1].x),
                                  static_cast<jfloat>(seg.points[1].y));
              break;
            case AndroidPathVerb::kConic:
              if (g_path_conic_to_method != nullptr) {
                env->CallVoidMethod(path_obj, g_path_conic_to_method,
                                    static_cast<jfloat>(seg.points[0].x),
                                    static_cast<jfloat>(seg.points[0].y),
                                    static_cast<jfloat>(seg.points[1].x),
                                    static_cast<jfloat>(seg.points[1].y),
                                    static_cast<jfloat>(seg.conic_weight));
              } else {
                env->CallVoidMethod(path_obj, g_path_quad_to_method,
                                    static_cast<jfloat>(seg.points[0].x),
                                    static_cast<jfloat>(seg.points[0].y),
                                    static_cast<jfloat>(seg.points[1].x),
                                    static_cast<jfloat>(seg.points[1].y));
              }
              break;
            case AndroidPathVerb::kCubic:
              env->CallVoidMethod(path_obj, g_path_cubic_to_method,
                                  static_cast<jfloat>(seg.points[0].x),
                                  static_cast<jfloat>(seg.points[0].y),
                                  static_cast<jfloat>(seg.points[1].x),
                                  static_cast<jfloat>(seg.points[1].y),
                                  static_cast<jfloat>(seg.points[2].x),
                                  static_cast<jfloat>(seg.points[2].y));
              break;
            case AndroidPathVerb::kClose:
              env->CallVoidMethod(path_obj, g_path_close_method);
              break;
          }
          ClearJniExceptionSafe(env);
        }

        env->CallVoidMethod(raw_stack, g_stack_push_clip_path_method, path_obj);
        env->DeleteLocalRef(path_obj);
        ClearJniExceptionSafe(env);
        break;
      }
      case kFlutterPlatformViewMutationTypeOpacity: {
        if (g_stack_push_opacity_method != nullptr) {
          env->CallVoidMethod(raw_stack, g_stack_push_opacity_method,
                              static_cast<jfloat>(record.opacity));
          ClearJniExceptionSafe(env);
        }
        break;
      }
      default:
        break;
    }
  }

  return raw_stack;
}

SurfaceControlTransactionTransform
AndroidMutatorsMapper::ComputeSurfaceControlTransactionTransform(
    const std::vector<AndroidMutatorRecord>& records,
    float device_pixel_ratio) {
  TRACE_EVENT0(
      "flutter",
      "AndroidMutatorsMapper::ComputeSurfaceControlTransactionTransform");
  (void)device_pixel_ratio;

  SurfaceControlTransactionTransform result;
  AndroidMatrix3x3 combined = AndroidMatrix3x3::Identity();
  float accumulated_opacity = kMaxOpacity;
  bool has_clip = false;
  int32_t clip_left = std::numeric_limits<int32_t>::min();
  int32_t clip_top = std::numeric_limits<int32_t>::min();
  int32_t clip_right = std::numeric_limits<int32_t>::max();
  int32_t clip_bottom = std::numeric_limits<int32_t>::max();
  int32_t corner_radius = 0;

  for (const auto& record : records) {
    switch (record.type) {
      case kFlutterPlatformViewMutationTypeTransformation: {
        if (record.matrix.size() == kAndroidMatrixElementCount) {
          AndroidMatrix3x3 m;
          std::copy(record.matrix.begin(), record.matrix.end(),
                    m.values.begin());
          combined = AndroidMatrix3x3::Multiply(combined, m);
        }
        break;
      }
      case kFlutterPlatformViewMutationTypeOpacity: {
        accumulated_opacity = std::clamp(accumulated_opacity * record.opacity,
                                         kMinOpacity, kMaxOpacity);
        break;
      }
      case kFlutterPlatformViewMutationTypeClipRect:
      case kFlutterPlatformViewMutationTypeClipRoundedRect: {
        has_clip = true;
        int32_t l = record.rect_left;
        int32_t t = record.rect_top;
        int32_t r = record.rect_right;
        int32_t b = record.rect_bottom;

        const float a = combined.values[kMatrixScaleXIndex];
        const float b_mat = combined.values[kMatrixSkewXIndex];
        const float c = combined.values[kMatrixSkewYIndex];
        const float d = combined.values[kMatrixScaleYIndex];
        const float det = a * d - b_mat * c;
        if (std::fabs(det) > kMinInvertibleDeterminant) {
          const float inv_det = 1.0f / det;
          const float x0 =
              (d * static_cast<float>(l) - b_mat * static_cast<float>(t)) *
              inv_det;
          const float y0 =
              (-c * static_cast<float>(l) + a * static_cast<float>(t)) *
              inv_det;
          const float x1 =
              (d * static_cast<float>(r) - b_mat * static_cast<float>(b)) *
              inv_det;
          const float y1 =
              (-c * static_cast<float>(r) + a * static_cast<float>(b)) *
              inv_det;
          l = static_cast<int32_t>(std::round(std::min(x0, x1)));
          t = static_cast<int32_t>(std::round(std::min(y0, y1)));
          r = static_cast<int32_t>(std::round(std::max(x0, x1)));
          b = static_cast<int32_t>(std::round(std::max(y0, y1)));
        }
        clip_left = std::max(clip_left, l);
        clip_top = std::max(clip_top, t);
        clip_right = std::min(clip_right, r);
        clip_bottom = std::min(clip_bottom, b);

        if (record.type == kFlutterPlatformViewMutationTypeClipRoundedRect &&
            record.radii.size() == kAndroidRoundedRectRadiiCount) {
          const float first = record.radii[0];
          bool uniform = true;
          for (size_t i = 1; i < kAndroidRoundedRectRadiiCount; ++i) {
            if (std::fabs(record.radii[i] - first) > 1e-3f) {
              uniform = false;
              break;
            }
          }
          if (uniform && first > 0.0f) {
            corner_radius = static_cast<int32_t>(std::round(first));
          }
        }
        break;
      }
      default:
        break;
    }
  }

  result.position_x = combined.values[kMatrixTransXIndex];
  result.position_y = combined.values[kMatrixTransYIndex];
  result.dsdx = combined.values[kMatrixScaleXIndex];
  result.dtdx = combined.values[kMatrixSkewYIndex];
  result.dtdy = combined.values[kMatrixSkewXIndex];
  result.dsdy = combined.values[kMatrixScaleYIndex];
  result.alpha = accumulated_opacity;
  result.has_crop = has_clip;
  if (has_clip) {
    result.crop_left = clip_left;
    result.crop_top = clip_top;
    result.crop_right = std::max(clip_left, clip_right);
    result.crop_bottom = std::max(clip_top, clip_bottom);
  }
  result.corner_radius = corner_radius;
  return result;
}

}  // namespace flutter
