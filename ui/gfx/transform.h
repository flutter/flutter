// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_TRANSFORM_H_
#define UI_GFX_TRANSFORM_H_

#include <iosfwd>
#include <string>

#include "base/compiler_specific.h"
#include "third_party/skia/include/core/SkMatrix44.h"
#include "ui/gfx/gfx_export.h"
#include "ui/gfx/geometry/vector2d_f.h"

namespace gfx {

class BoxF;
class RectF;
class Point;
class Point3F;
class Vector3dF;

// 4x4 transformation matrix. Transform is cheap and explicitly allows
// copy/assign.
class GFX_EXPORT Transform {
 public:

  enum SkipInitialization {
    kSkipInitialization
  };

  Transform() : matrix_(SkMatrix44::kIdentity_Constructor) {}

  // Skips initializing this matrix to avoid overhead, when we know it will be
  // initialized before use.
  Transform(SkipInitialization)
      : matrix_(SkMatrix44::kUninitialized_Constructor) {}
  Transform(const Transform& rhs) : matrix_(rhs.matrix_) {}
  // Initialize with the concatenation of lhs * rhs.
  Transform(const Transform& lhs, const Transform& rhs)
      : matrix_(lhs.matrix_, rhs.matrix_) {}
  // Constructs a transform from explicit 16 matrix elements. Elements
  // should be given in row-major order.
  Transform(SkMScalar col1row1,
            SkMScalar col2row1,
            SkMScalar col3row1,
            SkMScalar col4row1,
            SkMScalar col1row2,
            SkMScalar col2row2,
            SkMScalar col3row2,
            SkMScalar col4row2,
            SkMScalar col1row3,
            SkMScalar col2row3,
            SkMScalar col3row3,
            SkMScalar col4row3,
            SkMScalar col1row4,
            SkMScalar col2row4,
            SkMScalar col3row4,
            SkMScalar col4row4);
  // Constructs a transform from explicit 2d elements. All other matrix
  // elements remain the same as the corresponding elements of an identity
  // matrix.
  Transform(SkMScalar col1row1,
            SkMScalar col2row1,
            SkMScalar col1row2,
            SkMScalar col2row2,
            SkMScalar x_translation,
            SkMScalar y_translation);
  ~Transform() {}

  bool operator==(const Transform& rhs) const { return matrix_ == rhs.matrix_; }
  bool operator!=(const Transform& rhs) const { return matrix_ != rhs.matrix_; }

  // Resets this transform to the identity transform.
  void MakeIdentity() { matrix_.setIdentity(); }

  // Applies the current transformation on a 2d rotation and assigns the result
  // to |this|.
  void Rotate(double degrees) { RotateAboutZAxis(degrees); }

  // Applies the current transformation on an axis-angle rotation and assigns
  // the result to |this|.
  void RotateAboutXAxis(double degrees);
  void RotateAboutYAxis(double degrees);
  void RotateAboutZAxis(double degrees);
  void RotateAbout(const Vector3dF& axis, double degrees);

  // Applies the current transformation on a scaling and assigns the result
  // to |this|.
  void Scale(SkMScalar x, SkMScalar y);
  void Scale3d(SkMScalar x, SkMScalar y, SkMScalar z);
  gfx::Vector2dF Scale2d() const {
    return gfx::Vector2dF(matrix_.get(0, 0), matrix_.get(1, 1));
  }

  // Applies the current transformation on a translation and assigns the result
  // to |this|.
  void Translate(SkMScalar x, SkMScalar y);
  void Translate3d(SkMScalar x, SkMScalar y, SkMScalar z);

  // Applies the current transformation on a skew and assigns the result
  // to |this|.
  void SkewX(double angle_x);
  void SkewY(double angle_y);

  // Applies the current transformation on a perspective transform and assigns
  // the result to |this|.
  void ApplyPerspectiveDepth(SkMScalar depth);

  // Applies a transformation on the current transformation
  // (i.e. 'this = this * transform;').
  void PreconcatTransform(const Transform& transform);

  // Applies a transformation on the current transformation
  // (i.e. 'this = transform * this;').
  void ConcatTransform(const Transform& transform);

  // Returns true if this is the identity matrix.
  bool IsIdentity() const { return matrix_.isIdentity(); }

  // Returns true if the matrix is either identity or pure translation.
  bool IsIdentityOrTranslation() const { return matrix_.isTranslate(); }

  // Returns true if the matrix is either the identity or a 2d translation.
  bool IsIdentityOr2DTranslation() const {
    return matrix_.isTranslate() && matrix_.get(2, 3) == 0;
  }

  // Returns true if the matrix is either identity or pure translation,
  // allowing for an amount of inaccuracy as specified by the parameter.
  bool IsApproximatelyIdentityOrTranslation(SkMScalar tolerance) const;

  // Returns true if the matrix is either a positive scale and/or a translation.
  bool IsPositiveScaleOrTranslation() const {
    if (!IsScaleOrTranslation())
      return false;
    return matrix_.get(0, 0) > 0.0 && matrix_.get(1, 1) > 0.0 &&
           matrix_.get(2, 2) > 0.0;
  }

  // Returns true if the matrix is either identity or pure, non-fractional
  // translation.
  bool IsIdentityOrIntegerTranslation() const;

  // Returns true if the matrix had only scaling components.
  bool IsScale2d() const {
    return !(matrix_.getType() & ~SkMatrix44::kScale_Mask);
  }

  // Returns true if the matrix is has only scaling and translation components.
  bool IsScaleOrTranslation() const { return matrix_.isScaleTranslate(); }

  // Returns true if axis-aligned 2d rects will remain axis-aligned after being
  // transformed by this matrix.
  bool Preserves2dAxisAlignment() const;

  // Returns true if the matrix has any perspective component that would
  // change the w-component of a homogeneous point.
  bool HasPerspective() const { return matrix_.hasPerspective(); }

  // Returns true if this transform is non-singular.
  bool IsInvertible() const { return matrix_.invert(NULL); }

  // Returns true if a layer with a forward-facing normal of (0, 0, 1) would
  // have its back side facing frontwards after applying the transform.
  bool IsBackFaceVisible() const;

  // Inverts the transform which is passed in. Returns true if successful.
  bool GetInverse(Transform* transform) const WARN_UNUSED_RESULT;

  // Transposes this transform in place.
  void Transpose();

  // Set 3rd row and 3rd colum to (0, 0, 1, 0). Note that this flattening
  // operation is not quite the same as an orthographic projection and is
  // technically not a linear operation.
  //
  // One useful interpretation of doing this operation:
  //  - For x and y values, the new transform behaves effectively like an
  //    orthographic projection was added to the matrix sequence.
  //  - For z values, the new transform overrides any effect that the transform
  //    had on z, and instead it preserves the z value for any points that are
  //    transformed.
  //  - Because of linearity of transforms, this flattened transform also
  //    preserves the effect that any subsequent (multiplied from the right)
  //    transforms would have on z values.
  //
  void FlattenTo2d();

  // Returns true if the 3rd row and 3rd column are both (0, 0, 1, 0).
  bool IsFlat() const;

  // Returns the x and y translation components of the matrix.
  Vector2dF To2dTranslation() const;

  // Applies the transformation to the point.
  void TransformPoint(Point3F* point) const;

  // Applies the transformation to the point.
  void TransformPoint(Point* point) const;

  // Applies the reverse transformation on the point. Returns true if the
  // transformation can be inverted.
  bool TransformPointReverse(Point3F* point) const;

  // Applies the reverse transformation on the point. Returns true if the
  // transformation can be inverted. Rounds the result to the nearest point.
  bool TransformPointReverse(Point* point) const;

  // Applies transformation on the given rect. After the function completes,
  // |rect| will be the smallest axis aligned bounding rect containing the
  // transformed rect.
  void TransformRect(RectF* rect) const;

  // Applies the reverse transformation on the given rect. After the function
  // completes, |rect| will be the smallest axis aligned bounding rect
  // containing the transformed rect. Returns false if the matrix cannot be
  // inverted.
  bool TransformRectReverse(RectF* rect) const;

  // Applies transformation on the given box. After the function completes,
  // |box| will be the smallest axis aligned bounding box containing the
  // transformed box.
  void TransformBox(BoxF* box) const;

  // Applies the reverse transformation on the given box. After the function
  // completes, |box| will be the smallest axis aligned bounding box
  // containing the transformed box. Returns false if the matrix cannot be
  // inverted.
  bool TransformBoxReverse(BoxF* box) const;

  // Decomposes |this| and |from|, interpolates the decomposed values, and
  // sets |this| to the reconstituted result. Returns false if either matrix
  // can't be decomposed. Uses routines described in this spec:
  // http://www.w3.org/TR/css3-3d-transforms/.
  //
  // Note: this call is expensive since we need to decompose the transform. If
  // you're going to be calling this rapidly (e.g., in an animation) you should
  // decompose once using gfx::DecomposeTransforms and reuse your
  // DecomposedTransform.
  bool Blend(const Transform& from, double progress);

  void RoundTranslationComponents();

  // Returns |this| * |other|.
  Transform operator*(const Transform& other) const {
    return Transform(*this, other);
  }

  // Sets |this| = |this| * |other|
  Transform& operator*=(const Transform& other) {
    PreconcatTransform(other);
    return *this;
  }

  // Returns the underlying matrix.
  const SkMatrix44& matrix() const { return matrix_; }
  SkMatrix44& matrix() { return matrix_; }

  std::string ToString() const;

 private:
  void TransformPointInternal(const SkMatrix44& xform,
                              Point* point) const;

  void TransformPointInternal(const SkMatrix44& xform,
                              Point3F* point) const;

  SkMatrix44 matrix_;

  // copy/assign are allowed.
};

// This is declared here for use in gtest-based unit tests but is defined in
// the gfx_test_support target. Depend on that to use this in your unit test.
// This should not be used in production code - call ToString() instead.
void PrintTo(const Transform& transform, ::std::ostream* os);

}  // namespace gfx

#endif  // UI_GFX_TRANSFORM_H_
