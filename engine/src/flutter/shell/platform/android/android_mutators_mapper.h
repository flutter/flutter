// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_MUTATORS_MAPPER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_MUTATORS_MAPPER_H_

#include <cmath>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <optional>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {
namespace android {

/// @brief Representation of a 3x3 2D affine / projective matrix matching
/// Android's android.graphics.Matrix.
///
/// Elements are stored in row-major order:
/// [ MSCALE_X (0), MSKEW_X  (1), MTRANS_X (2),
///   MSKEW_Y  (3), MSCALE_Y (4), MTRANS_Y (5),
///   MPERSP_0 (6), MPERSP_1 (7), MPERSP_2 (8) ]
struct AndroidMatrix3x3 {
  float values[9] = {1.0f, 0.0f, 0.0f,  //
                     0.0f, 1.0f, 0.0f,  //
                     0.0f, 0.0f, 1.0f};

  static AndroidMatrix3x3 Identity();
  static AndroidMatrix3x3 MakeTranslation(float tx, float ty);
  static AndroidMatrix3x3 MakeScale(float sx, float sy);
  static AndroidMatrix3x3 FromFlutterTransformation(
      const FlutterTransformation& transform);

  bool IsIdentity() const;

  /// @brief Multiplies this matrix by another matrix: C = this * other.
  AndroidMatrix3x3 Multiply(const AndroidMatrix3x3& other) const;

  /// @brief Pre-concatenates other onto this matrix: this = this * other.
  void PreConcat(const AndroidMatrix3x3& other);

  /// @brief Post-concatenates other onto this matrix: this = other * this.
  void PostConcat(const AndroidMatrix3x3& other);

  /// @brief Pre-scales this matrix by sx and sy: this = this * Scale(sx, sy).
  void PreScale(float sx, float sy);

  /// @brief Post-translates this matrix by tx and ty: this = Translate(tx, ty)
  /// * this.
  void PostTranslate(float tx, float ty);

  /// @brief Transforms a 2D point (x, y) through the 3x3 matrix.
  /// @return True if perspective division succeeded without singularity.
  bool TransformPoint(float x, float y, float* out_x, float* out_y) const;

  bool operator==(const AndroidMatrix3x3& other) const;
  bool operator!=(const AndroidMatrix3x3& other) const {
    return !(*this == other);
  }
};

/// @brief Representation of a 2D rectangle in physical / logical coordinates.
struct AndroidRect {
  float left = 0.0f;
  float top = 0.0f;
  float right = 0.0f;
  float bottom = 0.0f;

  float width() const { return right - left; }
  float height() const { return bottom - top; }
  bool IsEmpty() const { return left >= right || top >= bottom; }

  static AndroidRect FromFlutterRect(const FlutterRect& rect);

  bool operator==(const AndroidRect& other) const;
  bool operator!=(const AndroidRect& other) const { return !(*this == other); }
};

/// @brief Representation of a rounded rectangle with 4 corner radii.
struct AndroidRoundedRect {
  AndroidRect rect;
  /// Radii array matching Android's Path.addRoundRect radii parameter:
  /// [UL_x, UL_y, UR_x, UR_y, LR_x, LR_y, LL_x, LL_y]
  float radii[8] = {0.0f};

  static AndroidRoundedRect FromFlutterRoundedRect(
      const FlutterRoundedRect& rrect);

  bool operator==(const AndroidRoundedRect& other) const;
  bool operator!=(const AndroidRoundedRect& other) const {
    return !(*this == other);
  }
};

/// @brief Type classification of an Android mutator operation.
enum class AndroidMutatorType : uint32_t {
  kClipRect = 0,
  kClipRRect = 1,
  kTransform = 2,
  kOpacity = 3,
};

/// @brief Encapsulates a single mutator entry.
struct AndroidMutator {
  AndroidMutatorType type = AndroidMutatorType::kTransform;
  AndroidRect rect;
  AndroidRoundedRect rrect;
  AndroidMatrix3x3 matrix;
  float opacity = 1.0f;

  static AndroidMutator MakeClipRect(const AndroidRect& r);
  static AndroidMutator MakeClipRRect(const AndroidRoundedRect& rr);
  static AndroidMutator MakeTransform(const AndroidMatrix3x3& mat);
  static AndroidMutator MakeOpacity(float op);

  bool operator==(const AndroidMutator& other) const;
  bool operator!=(const AndroidMutator& other) const {
    return !(*this == other);
  }
};

/// @brief Decoupled, C-ABI compliant representation of an Android Platform View
/// Mutator Stack.
class AndroidMutatorsStack {
 public:
  AndroidMutatorsStack();
  ~AndroidMutatorsStack();

  void PushTransform(const AndroidMatrix3x3& matrix);
  void PushTransform(const FlutterTransformation& transform);
  void PushClipRect(const AndroidRect& rect);
  void PushClipRect(const FlutterRect& rect);
  void PushClipRRect(const AndroidRoundedRect& rrect);
  void PushClipRRect(const FlutterRoundedRect& rrect);
  void PushOpacity(float opacity);

  const std::vector<AndroidMutator>& GetMutators() const { return mutators_; }
  const AndroidMatrix3x3& GetFinalMatrix() const { return final_matrix_; }
  float GetFinalOpacity() const { return final_opacity_; }
  const std::vector<AndroidRect>& GetFinalClipRects() const {
    return final_clip_rects_;
  }
  const std::vector<AndroidRoundedRect>& GetFinalClipRRects() const {
    return final_clip_rrects_;
  }

  void Clear();
  size_t GetMutatorsCount() const { return mutators_.size(); }

  /// @brief Returns the transformed matrix adjusted for Android screen density
  /// and view offsets, matching FlutterMutatorView.java
  /// getPlatformViewMatrix():
  /// 1. matrix = finalMatrix
  /// 2. matrix.preScale(1 / screen_density, 1 / screen_density)
  /// 3. matrix.postTranslate(-left, -top)
  AndroidMatrix3x3 GetPlatformViewMatrix(float screen_density,
                                         float left,
                                         float top) const;

  /// @brief Serializes the stack into a portable binary buffer.
  std::vector<uint8_t> Serialize() const;

  /// @brief Deserializes a binary buffer into an AndroidMutatorsStack.
  static std::optional<AndroidMutatorsStack> Deserialize(const uint8_t* data,
                                                         size_t size);

  bool operator==(const AndroidMutatorsStack& other) const;
  bool operator!=(const AndroidMutatorsStack& other) const {
    return !(*this == other);
  }

 private:
  std::vector<AndroidMutator> mutators_;
  AndroidMatrix3x3 final_matrix_;
  float final_opacity_ = 1.0f;
  std::vector<AndroidRect> final_clip_rects_;
  std::vector<AndroidRoundedRect> final_clip_rrects_;
};

/// @brief Utility translator converting Flutter Embedder C-API mutations into
/// decoupled Android mutator representations.
class AndroidMutatorsMapper {
 public:
  AndroidMutatorsMapper();
  ~AndroidMutatorsMapper();

  /// @brief Maps an array of FlutterPlatformViewMutation pointers into an
  /// AndroidMutatorsStack.
  static AndroidMutatorsStack MapMutations(
      const FlutterPlatformViewMutation** mutations,
      size_t count);

  /// @brief Maps a FlutterPlatformView struct into an AndroidMutatorsStack.
  static AndroidMutatorsStack MapPlatformView(
      const FlutterPlatformView& platform_view);

  /// @brief Maps a single FlutterPlatformViewMutation into an AndroidMutator.
  static std::optional<AndroidMutator> MapMutation(
      const FlutterPlatformViewMutation& mutation);

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(AndroidMutatorsMapper);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_MUTATORS_MAPPER_H_
