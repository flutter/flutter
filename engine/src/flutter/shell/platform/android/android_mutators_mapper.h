// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_MUTATORS_MAPPER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_MUTATORS_MAPPER_H_

#include <jni.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <optional>
#include <type_traits>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/embedder/embedder.h"

#ifndef STRUCT_HAS_MEMBER
#define STRUCT_HAS_MEMBER(pointer, member)                           \
  ((offsetof(std::remove_pointer<decltype(pointer)>::type, member) + \
        sizeof(pointer->member) <=                                   \
    pointer->struct_size))
#endif

#ifndef SAFE_ACCESS
#define SAFE_ACCESS(pointer, member, default_value)                 \
  ([=]() {                                                          \
    if (STRUCT_HAS_MEMBER(pointer, member)) {                       \
      return pointer->member;                                       \
    }                                                               \
    return static_cast<decltype(pointer->member)>((default_value)); \
  })()
#endif

namespace flutter {

/// Number of elements in an Android 3x3 2D transformation matrix
/// (`android.graphics.Matrix`).
inline constexpr size_t kAndroidMatrixElementCount = 9;

/// Dimension (rows and columns) of a 3x3 matrix.
inline constexpr size_t kAndroidMatrixDimension = 3;

/// Number of float values representing the 4 corner (x, y) radii of an
/// Android rounded rectangle (`Path.addRoundRect`).
inline constexpr size_t kAndroidRoundedRectRadiiCount = 8;

/// Maximum number of control/end points stored in a single path verb segment
/// (cubic Bézier curves require 3 points).
inline constexpr size_t kMaxPathSegmentPoints = 3;

// Matrix element indices in row-major order matching android.graphics.Matrix.
inline constexpr size_t kMatrixScaleXIndex = 0;
inline constexpr size_t kMatrixSkewXIndex = 1;
inline constexpr size_t kMatrixTransXIndex = 2;
inline constexpr size_t kMatrixSkewYIndex = 3;
inline constexpr size_t kMatrixScaleYIndex = 4;
inline constexpr size_t kMatrixTransYIndex = 5;
inline constexpr size_t kMatrixPersp0Index = 6;
inline constexpr size_t kMatrixPersp1Index = 7;
inline constexpr size_t kMatrixPersp2Index = 8;

/**
 * @brief Represents a 3x3 2D affine/perspective transformation matrix
 * compatible with `android.graphics.Matrix` (row-major order:
 * [scaleX, skewX, transX, skewY, scaleY, transY, persp0, persp1, persp2]).
 */
struct AndroidMatrix3x3 {
  /// Default identity matrix values: 1.0 on the main diagonal, 0.0 elsewhere.
  std::array<float, kAndroidMatrixElementCount> values = {
      1.0f, 0.0f, 0.0f,  // Row 0: scaleX, skewX, transX
      0.0f, 1.0f, 0.0f,  // Row 1: skewY, scaleY, transY
      0.0f, 0.0f, 1.0f   // Row 2: persp0, persp1, persp2
  };

  static AndroidMatrix3x3 Identity();
  static AndroidMatrix3x3 FromFlutterTransformation(
      const FlutterTransformation& transform);
  static AndroidMatrix3x3 Multiply(const AndroidMatrix3x3& a,
                                   const AndroidMatrix3x3& b);
  static AndroidMatrix3x3 PreTranslate(const AndroidMatrix3x3& m,
                                       float dx,
                                       float dy);
  static AndroidMatrix3x3 PostTranslate(const AndroidMatrix3x3& m,
                                        float dx,
                                        float dy);

  bool IsIdentity(float epsilon = 1e-5f) const;
  bool operator==(const AndroidMatrix3x3& other) const;
  bool operator!=(const AndroidMatrix3x3& other) const {
    return !(*this == other);
  }
};

/**
 * @brief Axis-aligned 2D rectangle in float coordinates.
 */
struct AndroidRect {
  float left = 0.0f;
  float top = 0.0f;
  float right = 0.0f;
  float bottom = 0.0f;

  static AndroidRect FromFlutterRect(const FlutterRect& rect);

  float Width() const { return std::max(0.0f, right - left); }
  float Height() const { return std::max(0.0f, bottom - top); }
  bool IsEmpty() const { return right <= left || bottom <= top; }

  bool operator==(const AndroidRect& other) const;
  bool operator!=(const AndroidRect& other) const { return !(*this == other); }
};

/**
 * @brief Rounded rectangle with 8 float radii (top-left, top-right,
 * bottom-right, bottom-left x/y pairs), matching `android.graphics.Path`
 * `addRoundRect` convention.
 */
struct AndroidRoundedRect {
  AndroidRect rect;
  std::array<float, kAndroidRoundedRectRadiiCount> radii = {
      0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f};

  static AndroidRoundedRect FromFlutterRoundedRect(
      const FlutterRoundedRect& rrect);

  bool IsRect(float epsilon = 1e-5f) const;
  bool IsUniformCornerRadius(float* out_radius = nullptr,
                             float epsilon = 1e-3f) const;

  bool operator==(const AndroidRoundedRect& other) const;
  bool operator!=(const AndroidRoundedRect& other) const {
    return !(*this == other);
  }
};

/**
 * @brief Fill rule for vector clip paths (`android.graphics.Path.FillType`).
 */
enum class AndroidPathFillType : int32_t {
  kNonZero = 0,  // WINDING
  kEvenOdd = 1,  // EVEN_ODD
};

/**
 * @brief Verb type for a vector path segment (`android.graphics.Path`).
 */
enum class AndroidPathVerb : int32_t {
  kMove = 0,
  kLine = 1,
  kQuad = 2,
  kConic = 3,
  kCubic = 4,
  kClose = 5,
};

/**
 * @brief A single decoded segment in an `AndroidClipPath`.
 */
struct AndroidPathSegment {
  AndroidPathVerb verb = AndroidPathVerb::kMove;
  std::array<FlutterPoint, kMaxPathSegmentPoints> points = {
      FlutterPoint{0.0, 0.0}, FlutterPoint{0.0, 0.0}, FlutterPoint{0.0, 0.0}};
  /// Default conic weight of 1.0 corresponds to a standard quadratic curve.
  float conic_weight = 1.0f;

  bool operator==(const AndroidPathSegment& other) const;
  bool operator!=(const AndroidPathSegment& other) const {
    return !(*this == other);
  }
};

/**
 * @brief Portable representation of a vector clip path decoded from the
 * structure-of-arrays `FlutterPath` C-API struct (`verbs`, `points`,
 * `conic_weights`, `bounds`, `fill_type`).
 */
struct AndroidClipPath {
  AndroidPathFillType fill_type = AndroidPathFillType::kNonZero;
  std::vector<AndroidPathSegment> segments;
  std::vector<FlutterPathVerb> verbs;
  std::vector<FlutterPoint> points;
  std::vector<double> conic_weights;
  AndroidRect bounds;

  static AndroidClipPath FromFlutterPath(const FlutterPath& path,
                                         float scale = 1.0f);

  bool IsEmpty() const { return segments.empty(); }

  bool operator==(const AndroidClipPath& other) const;
  bool operator!=(const AndroidClipPath& other) const {
    return !(*this == other);
  }
};

/**
 * @brief Enumeration of mutator operations in an `AndroidMutatorsStack`.
 */
enum class AndroidMutatorType : int32_t {
  kClipRect = 0,
  kClipRRect = 1,
  kClipPath = 2,
  kTransform = 3,
  kOpacity = 4,
};

/**
 * @brief A single mutator entry in `AndroidMutatorsStack`.
 */
struct AndroidMutator {
  AndroidMutatorType type = AndroidMutatorType::kTransform;
  AndroidRect rect;
  AndroidRoundedRect rrect;
  AndroidClipPath path;
  AndroidMatrix3x3 matrix;
  /// Default full opacity (1.0 = completely opaque).
  float opacity = 1.0f;

  static AndroidMutator ClipRect(const AndroidRect& rect);
  static AndroidMutator ClipRRect(const AndroidRoundedRect& rrect);
  static AndroidMutator ClipPath(const AndroidClipPath& path);
  static AndroidMutator Transform(const AndroidMatrix3x3& matrix);
  static AndroidMutator Opacity(float opacity);

  bool operator==(const AndroidMutator& other) const;
  bool operator!=(const AndroidMutator& other) const {
    return !(*this == other);
  }
};

/**
 * @brief Computed transform, crop, corner radius, and alpha values ready to
 * apply to an Android `SurfaceControl.Transaction` or `ASurfaceTransaction`.
 */
struct SurfaceControlTransactionTransform {
  float position_x = 0.0f;
  float position_y = 0.0f;
  /// Identity 2x2 scale/skew matrix components (`dsdx = 1`, `dsdy = 1`).
  float dsdx = 1.0f;
  float dtdx = 0.0f;
  float dtdy = 0.0f;
  float dsdy = 1.0f;
  /// Accumulated alpha in [0.0, 1.0].
  float alpha = 1.0f;
  bool has_crop = false;
  int32_t crop_left = 0;
  int32_t crop_top = 0;
  int32_t crop_right = 0;
  int32_t crop_bottom = 0;
  int32_t corner_radius = 0;

  bool operator==(const SurfaceControlTransactionTransform& other) const;
  bool operator!=(const SurfaceControlTransactionTransform& other) const {
    return !(*this == other);
  }
};

/**
 * @brief Represents the ordered stack of mutators applied to an Android
 * Platform View, mirroring Java's `FlutterMutatorsStack` (`FlutterMutatorView`)
 * and computing combined matrices/crops for `SurfaceControl.Transaction`.
 */
class AndroidMutatorsStack {
 public:
  AndroidMutatorsStack();
  ~AndroidMutatorsStack();

  AndroidMutatorsStack(const AndroidMutatorsStack&) = default;
  AndroidMutatorsStack& operator=(const AndroidMutatorsStack&) = default;
  AndroidMutatorsStack(AndroidMutatorsStack&&) noexcept = default;
  AndroidMutatorsStack& operator=(AndroidMutatorsStack&&) noexcept = default;

  void PushTransform(const AndroidMatrix3x3& matrix);
  void PushClipRect(const AndroidRect& rect);
  void PushClipRRect(const AndroidRoundedRect& rrect);
  void PushClipPath(const AndroidClipPath& path);
  void PushOpacity(float opacity);

  const std::vector<AndroidMutator>& GetMutators() const { return mutators_; }
  size_t GetMutatorsCount() const { return mutators_.size(); }
  bool IsEmpty() const { return mutators_.empty(); }

  const AndroidMatrix3x3& GetFinalMatrix() const { return final_matrix_; }
  float GetFinalOpacity() const { return final_opacity_; }
  const std::vector<AndroidRect>& GetFinalClippingRects() const {
    return final_clip_rects_;
  }
  const std::vector<AndroidRoundedRect>& GetFinalClippingRRects() const {
    return final_clip_rrects_;
  }
  const std::vector<AndroidClipPath>& GetFinalClippingPaths() const {
    return final_clip_paths_;
  }

  /**
   * @brief Computes the combined 3x3 matrix for positioning a PlatformView
   * at logical/physical offset `(view_x, view_y)` (`final_matrix * Translate`).
   */
  AndroidMatrix3x3 GetPlatformViewMatrix(float view_x, float view_y) const;

  /**
   * @brief Computes the `SurfaceControl.Transaction` parameters (position,
   * 2x2 scale/skew matrix, alpha, local crop, and corner radius) for a
   * platform view at `(view_x, view_y)` with dimensions `(view_width,
   * view_height)`.
   */
  SurfaceControlTransactionTransform GetSurfaceControlTransactionTransform(
      float view_x,
      float view_y,
      float view_width,
      float view_height) const;

  std::vector<uint8_t> Serialize() const;
  static std::optional<AndroidMutatorsStack> Deserialize(const uint8_t* data,
                                                         size_t size);

  bool operator==(const AndroidMutatorsStack& other) const;
  bool operator!=(const AndroidMutatorsStack& other) const {
    return !(*this == other);
  }

 private:
  std::vector<AndroidMutator> mutators_;
  AndroidMatrix3x3 final_matrix_ = AndroidMatrix3x3::Identity();
  /// Initial accumulated opacity before any opacity mutators are pushed.
  float final_opacity_ = 1.0f;
  std::vector<AndroidRect> final_clip_rects_;
  std::vector<AndroidRoundedRect> final_clip_rrects_;
  std::vector<AndroidClipPath> final_clip_paths_;
};

/**
 * @brief Portable C++ representation of a parsed platform view mutation scaled
 * by device pixel ratio, suitable for unit testing without an active JVM and
 * for constructing Java `FlutterMutatorsStack` objects.
 */
struct AndroidMutatorRecord {
  FlutterPlatformViewMutationType type =
      kFlutterPlatformViewMutationTypeTransformation;
  /// 9-element float array for `android.graphics.Matrix`.
  std::vector<float> matrix;
  int32_t rect_left = 0;
  int32_t rect_top = 0;
  int32_t rect_right = 0;
  int32_t rect_bottom = 0;
  float rect_left_f = 0.0f;
  float rect_top_f = 0.0f;
  float rect_right_f = 0.0f;
  float rect_bottom_f = 0.0f;
  bool has_float_rect = false;
  /// 8-element float array for rounded rect corner radii.
  std::vector<float> radii;
  /// Clamped opacity in [0.0, 1.0].
  float opacity = 1.0f;
  FlutterPathFillType path_fill_type = kFlutterPathFillTypeNonZero;
  std::vector<AndroidPathSegment> path_segments;
  std::vector<FlutterPathVerb> path_verbs;
  std::vector<FlutterPoint> path_points;
  std::vector<double> path_conic_weights;
  AndroidRect path_bounds;
};

/**
 * @brief Maps C-API `FlutterPlatformViewMutation` arrays (including
 * structure-of-arrays `FlutterPath` with `verbs`, `points`, `conic_weights`,
 * and `bounds`) to `AndroidMutatorsStack`, Java `FlutterMutatorsStack`
 * (`FlutterMutatorView`), and `SurfaceControl.Transaction` transforms.
 */
class AndroidMutatorsMapper {
 public:
  AndroidMutatorsMapper();
  ~AndroidMutatorsMapper();

  /**
   * @brief Registers and caches JNI class/method references for
   * `FlutterMutatorsStack`, `Matrix`, `Rect`, `Path`, and `Path.FillType`.
   */
  static bool RegisterJNI(JNIEnv* env);

  /**
   * @brief Lazily ensures JNI bindings are registered if not already cached.
   */
  static bool EnsureJniRegistered(JNIEnv* env);

  /**
   * @brief Maps a single C-API `FlutterPlatformViewMutation` into an
   * `AndroidMutator`. Returns `std::nullopt` if the mutation type is unknown.
   */
  static std::optional<AndroidMutator> MapMutation(
      const FlutterPlatformViewMutation& mutation);

  /**
   * @brief Maps an array of C-API `FlutterPlatformViewMutation` pointers into
   * an `AndroidMutatorsStack`.
   */
  static AndroidMutatorsStack MapMutations(
      const FlutterPlatformViewMutation* const* mutations,
      size_t mutations_count);

  /**
   * @brief Maps the mutations on a `FlutterPlatformView` struct into an
   * `AndroidMutatorsStack`.
   */
  static AndroidMutatorsStack MapPlatformView(
      const FlutterPlatformView& platform_view);

  /**
   * @brief Parses C-API `FlutterPlatformViewMutation` pointers into scaled
   * `AndroidMutatorRecord` structs without requiring a JNI environment.
   */
  static std::vector<AndroidMutatorRecord> ParseMutations(
      size_t mutations_count,
      const FlutterPlatformViewMutation* const* mutations,
      double device_pixel_ratio = 1.0);

  /**
   * @brief Converts a `FlutterTransformation` to a 9-element row-major float
   * vector compatible with `android.graphics.Matrix.setValues(float[])`,
   * scaling translation components by `device_pixel_ratio`.
   */
  static std::vector<float> TransformToAndroidMatrix(
      const FlutterTransformation& transform,
      double device_pixel_ratio = 1.0);

  /**
   * @brief Converts 4 corner `FlutterSize` radii into an 8-element float vector
   * scaled by `device_pixel_ratio`.
   */
  static std::vector<float> RadiiToAndroidArray(
      const FlutterSize& upper_left,
      const FlutterSize& upper_right,
      const FlutterSize& lower_right,
      const FlutterSize& lower_left,
      double device_pixel_ratio = 1.0);

  /**
   * @brief Constructs a Java `FlutterMutatorsStack` object from C-API
   * mutations. Caller is responsible for deleting the returned local reference
   * (or wrapping it in `ScopedJavaLocalRef`).
   */
  static jobject CreateJavaMutatorsStack(
      JNIEnv* env,
      size_t mutations_count,
      const FlutterPlatformViewMutation* const* mutations,
      double device_pixel_ratio = 1.0);

  /**
   * @brief Constructs a Java `FlutterMutatorsStack` object from an
   * `AndroidMutatorsStack`.
   */
  static jobject CreateJavaMutatorsStack(JNIEnv* env,
                                         const AndroidMutatorsStack& stack,
                                         double device_pixel_ratio = 1.0);

  /**
   * @brief Constructs a Java `FlutterMutatorsStack` object from pre-parsed
   * `AndroidMutatorRecord` structs.
   */
  static jobject CreateJavaMutatorsStackFromRecords(
      JNIEnv* env,
      const std::vector<AndroidMutatorRecord>& records);

  /**
   * @brief Computes the combined `SurfaceControl.Transaction` parameters from
   * parsed `AndroidMutatorRecord` structs.
   */
  static SurfaceControlTransactionTransform
  ComputeSurfaceControlTransactionTransform(
      const std::vector<AndroidMutatorRecord>& records,
      float device_pixel_ratio = 1.0f);

  /**
   * @brief Applies the accumulated 2D affine matrix, position, alpha, and crop
   * from `records` onto a `SurfaceControl.Transaction`-compatible object.
   */
  template <typename SurfaceControlHandle, typename TransactionType>
  static bool ApplySurfaceControlTransaction(
      const std::vector<AndroidMutatorRecord>& records,
      float device_pixel_ratio,
      SurfaceControlHandle surface_control,
      TransactionType& transaction) {
    if (surface_control == nullptr) {
      return false;
    }
    const SurfaceControlTransactionTransform transform =
        ComputeSurfaceControlTransactionTransform(records, device_pixel_ratio);
    transaction.SetPosition(surface_control, transform.position_x,
                            transform.position_y);
    transaction.SetMatrix(surface_control, transform.dsdx, transform.dtdx,
                          transform.dtdy, transform.dsdy);
    transaction.SetAlpha(surface_control, transform.alpha);
    if (transform.has_crop) {
      transaction.SetCrop(surface_control, transform.crop_left,
                          transform.crop_top, transform.crop_right,
                          transform.crop_bottom);
    }
    return true;
  }

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(AndroidMutatorsMapper);
};

namespace android {
using ::flutter::AndroidClipPath;
using ::flutter::AndroidMatrix3x3;
using ::flutter::AndroidMutator;
using ::flutter::AndroidMutatorRecord;
using ::flutter::AndroidMutatorsMapper;
using ::flutter::AndroidMutatorsStack;
using ::flutter::AndroidMutatorType;
using ::flutter::AndroidPathFillType;
using ::flutter::AndroidPathSegment;
using ::flutter::AndroidPathVerb;
using ::flutter::AndroidRect;
using ::flutter::AndroidRoundedRect;
using ::flutter::SurfaceControlTransactionTransform;
}  // namespace android

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_MUTATORS_MAPPER_H_
