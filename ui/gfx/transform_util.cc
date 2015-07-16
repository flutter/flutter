// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/transform_util.h"

#include <algorithm>
#include <cmath>

#include "base/logging.h"
#include "base/strings/stringprintf.h"
#include "ui/gfx/point.h"
#include "ui/gfx/point3_f.h"
#include "ui/gfx/rect.h"

namespace gfx {

namespace {

SkMScalar Length3(SkMScalar v[3]) {
  double vd[3] = {SkMScalarToDouble(v[0]), SkMScalarToDouble(v[1]),
                  SkMScalarToDouble(v[2])};
  return SkDoubleToMScalar(
      std::sqrt(vd[0] * vd[0] + vd[1] * vd[1] + vd[2] * vd[2]));
}

void Scale3(SkMScalar v[3], SkMScalar scale) {
  for (int i = 0; i < 3; ++i)
    v[i] *= scale;
}

template <int n>
SkMScalar Dot(const SkMScalar* a, const SkMScalar* b) {
  double total = 0.0;
  for (int i = 0; i < n; ++i)
    total += a[i] * b[i];
  return SkDoubleToMScalar(total);
}

template <int n>
void Combine(SkMScalar* out,
             const SkMScalar* a,
             const SkMScalar* b,
             double scale_a,
             double scale_b) {
  for (int i = 0; i < n; ++i)
    out[i] = SkDoubleToMScalar(a[i] * scale_a + b[i] * scale_b);
}

void Cross3(SkMScalar out[3], SkMScalar a[3], SkMScalar b[3]) {
  SkMScalar x = a[1] * b[2] - a[2] * b[1];
  SkMScalar y = a[2] * b[0] - a[0] * b[2];
  SkMScalar z = a[0] * b[1] - a[1] * b[0];
  out[0] = x;
  out[1] = y;
  out[2] = z;
}

SkMScalar Round(SkMScalar n) {
  return SkDoubleToMScalar(std::floor(SkMScalarToDouble(n) + 0.5));
}

// Taken from http://www.w3.org/TR/css3-transforms/.
bool Slerp(SkMScalar out[4],
           const SkMScalar q1[4],
           const SkMScalar q2[4],
           double progress) {
  double product = Dot<4>(q1, q2);

  // Clamp product to -1.0 <= product <= 1.0.
  product = std::min(std::max(product, -1.0), 1.0);

  // Interpolate angles along the shortest path. For example, to interpolate
  // between a 175 degree angle and a 185 degree angle, interpolate along the
  // 10 degree path from 175 to 185, rather than along the 350 degree path in
  // the opposite direction. This matches WebKit's implementation but not
  // the current W3C spec. Fixing the spec to match this approach is discussed
  // at:
  // http://lists.w3.org/Archives/Public/www-style/2013May/0131.html
  double scale1 = 1.0;
  if (product < 0) {
    product = -product;
    scale1 = -1.0;
  }

  const double epsilon = 1e-5;
  if (std::abs(product - 1.0) < epsilon) {
    for (int i = 0; i < 4; ++i)
      out[i] = q1[i];
    return true;
  }

  double denom = std::sqrt(1.0 - product * product);
  double theta = std::acos(product);
  double w = std::sin(progress * theta) * (1.0 / denom);

  scale1 *= std::cos(progress * theta) - product * w;
  double scale2 = w;
  Combine<4>(out, q1, q2, scale1, scale2);

  return true;
}

// Returns false if the matrix cannot be normalized.
bool Normalize(SkMatrix44& m) {
  if (m.get(3, 3) == 0.0)
    // Cannot normalize.
    return false;

  SkMScalar scale = 1.0 / m.get(3, 3);
  for (int i = 0; i < 4; i++)
    for (int j = 0; j < 4; j++)
      m.set(i, j, m.get(i, j) * scale);

  return true;
}

SkMatrix44 BuildPerspectiveMatrix(const DecomposedTransform& decomp) {
  SkMatrix44 matrix(SkMatrix44::kIdentity_Constructor);

  for (int i = 0; i < 4; i++)
    matrix.setDouble(3, i, decomp.perspective[i]);
  return matrix;
}

SkMatrix44 BuildTranslationMatrix(const DecomposedTransform& decomp) {
  SkMatrix44 matrix(SkMatrix44::kUninitialized_Constructor);
  // Implicitly calls matrix.setIdentity()
  matrix.setTranslate(SkDoubleToMScalar(decomp.translate[0]),
                      SkDoubleToMScalar(decomp.translate[1]),
                      SkDoubleToMScalar(decomp.translate[2]));
  return matrix;
}

SkMatrix44 BuildSnappedTranslationMatrix(DecomposedTransform decomp) {
  decomp.translate[0] = Round(decomp.translate[0]);
  decomp.translate[1] = Round(decomp.translate[1]);
  decomp.translate[2] = Round(decomp.translate[2]);
  return BuildTranslationMatrix(decomp);
}

SkMatrix44 BuildRotationMatrix(const DecomposedTransform& decomp) {
  double x = decomp.quaternion[0];
  double y = decomp.quaternion[1];
  double z = decomp.quaternion[2];
  double w = decomp.quaternion[3];

  SkMatrix44 matrix(SkMatrix44::kUninitialized_Constructor);

  // Implicitly calls matrix.setIdentity()
  matrix.set3x3(1.0 - 2.0 * (y * y + z * z),
                2.0 * (x * y + z * w),
                2.0 * (x * z - y * w),
                2.0 * (x * y - z * w),
                1.0 - 2.0 * (x * x + z * z),
                2.0 * (y * z + x * w),
                2.0 * (x * z + y * w),
                2.0 * (y * z - x * w),
                1.0 - 2.0 * (x * x + y * y));
  return matrix;
}

SkMatrix44 BuildSnappedRotationMatrix(const DecomposedTransform& decomp) {
  // Create snapped rotation.
  SkMatrix44 rotation_matrix = BuildRotationMatrix(decomp);
  for (int i = 0; i < 3; ++i) {
    for (int j = 0; j < 3; ++j) {
      SkMScalar value = rotation_matrix.get(i, j);
      // Snap values to -1, 0 or 1.
      if (value < -0.5f) {
        value = -1.0f;
      } else if (value > 0.5f) {
        value = 1.0f;
      } else {
        value = 0.0f;
      }
      rotation_matrix.set(i, j, value);
    }
  }
  return rotation_matrix;
}

SkMatrix44 BuildSkewMatrix(const DecomposedTransform& decomp) {
  SkMatrix44 matrix(SkMatrix44::kIdentity_Constructor);

  SkMatrix44 temp(SkMatrix44::kIdentity_Constructor);
  if (decomp.skew[2]) {
    temp.setDouble(1, 2, decomp.skew[2]);
    matrix.preConcat(temp);
  }

  if (decomp.skew[1]) {
    temp.setDouble(1, 2, 0);
    temp.setDouble(0, 2, decomp.skew[1]);
    matrix.preConcat(temp);
  }

  if (decomp.skew[0]) {
    temp.setDouble(0, 2, 0);
    temp.setDouble(0, 1, decomp.skew[0]);
    matrix.preConcat(temp);
  }
  return matrix;
}

SkMatrix44 BuildScaleMatrix(const DecomposedTransform& decomp) {
  SkMatrix44 matrix(SkMatrix44::kUninitialized_Constructor);
  matrix.setScale(SkDoubleToMScalar(decomp.scale[0]),
                  SkDoubleToMScalar(decomp.scale[1]),
                  SkDoubleToMScalar(decomp.scale[2]));
  return matrix;
}

SkMatrix44 BuildSnappedScaleMatrix(DecomposedTransform decomp) {
  decomp.scale[0] = Round(decomp.scale[0]);
  decomp.scale[1] = Round(decomp.scale[1]);
  decomp.scale[2] = Round(decomp.scale[2]);
  return BuildScaleMatrix(decomp);
}

Transform ComposeTransform(const SkMatrix44& perspective,
                           const SkMatrix44& translation,
                           const SkMatrix44& rotation,
                           const SkMatrix44& skew,
                           const SkMatrix44& scale) {
  SkMatrix44 matrix(SkMatrix44::kIdentity_Constructor);

  matrix.preConcat(perspective);
  matrix.preConcat(translation);
  matrix.preConcat(rotation);
  matrix.preConcat(skew);
  matrix.preConcat(scale);

  Transform to_return;
  to_return.matrix() = matrix;
  return to_return;
}

bool CheckViewportPointMapsWithinOnePixel(const Point& point,
                                          const Transform& transform) {
  Point3F point_original(point);
  Point3F point_transformed(point);

  // Can't use TransformRect here since it would give us the axis-aligned
  // bounding rect of the 4 points in the initial rectable which is not what we
  // want.
  transform.TransformPoint(&point_transformed);

  if ((point_transformed - point_original).Length() > 1.f) {
    // The changed distance should not be more than 1 pixel.
    return false;
  }
  return true;
}

bool CheckTransformsMapsIntViewportWithinOnePixel(const Rect& viewport,
                                                  const Transform& original,
                                                  const Transform& snapped) {

  Transform original_inv(Transform::kSkipInitialization);
  bool invertible = true;
  invertible &= original.GetInverse(&original_inv);
  DCHECK(invertible) << "Non-invertible transform, cannot snap.";

  Transform combined = snapped * original_inv;

  return CheckViewportPointMapsWithinOnePixel(viewport.origin(), combined) &&
         CheckViewportPointMapsWithinOnePixel(viewport.top_right(), combined) &&
         CheckViewportPointMapsWithinOnePixel(viewport.bottom_left(),
                                              combined) &&
         CheckViewportPointMapsWithinOnePixel(viewport.bottom_right(),
                                              combined);
}

}  // namespace

Transform GetScaleTransform(const Point& anchor, float scale) {
  Transform transform;
  transform.Translate(anchor.x() * (1 - scale),
                      anchor.y() * (1 - scale));
  transform.Scale(scale, scale);
  return transform;
}

DecomposedTransform::DecomposedTransform() {
  translate[0] = translate[1] = translate[2] = 0.0;
  scale[0] = scale[1] = scale[2] = 1.0;
  skew[0] = skew[1] = skew[2] = 0.0;
  perspective[0] = perspective[1] = perspective[2] = 0.0;
  quaternion[0] = quaternion[1] = quaternion[2] = 0.0;
  perspective[3] = quaternion[3] = 1.0;
}

bool BlendDecomposedTransforms(DecomposedTransform* out,
                               const DecomposedTransform& to,
                               const DecomposedTransform& from,
                               double progress) {
  double scalea = progress;
  double scaleb = 1.0 - progress;
  Combine<3>(out->translate, to.translate, from.translate, scalea, scaleb);
  Combine<3>(out->scale, to.scale, from.scale, scalea, scaleb);
  Combine<3>(out->skew, to.skew, from.skew, scalea, scaleb);
  Combine<4>(
      out->perspective, to.perspective, from.perspective, scalea, scaleb);
  return Slerp(out->quaternion, from.quaternion, to.quaternion, progress);
}

// Taken from http://www.w3.org/TR/css3-transforms/.
bool DecomposeTransform(DecomposedTransform* decomp,
                        const Transform& transform) {
  if (!decomp)
    return false;

  // We'll operate on a copy of the matrix.
  SkMatrix44 matrix = transform.matrix();

  // If we cannot normalize the matrix, then bail early as we cannot decompose.
  if (!Normalize(matrix))
    return false;

  SkMatrix44 perspectiveMatrix = matrix;

  for (int i = 0; i < 3; ++i)
    perspectiveMatrix.set(3, i, 0.0);

  perspectiveMatrix.set(3, 3, 1.0);

  // If the perspective matrix is not invertible, we are also unable to
  // decompose, so we'll bail early. Constant taken from SkMatrix44::invert.
  if (std::abs(perspectiveMatrix.determinant()) < 1e-8)
    return false;

  if (matrix.get(3, 0) != 0.0 || matrix.get(3, 1) != 0.0 ||
      matrix.get(3, 2) != 0.0) {
    // rhs is the right hand side of the equation.
    SkMScalar rhs[4] = {
      matrix.get(3, 0),
      matrix.get(3, 1),
      matrix.get(3, 2),
      matrix.get(3, 3)
    };

    // Solve the equation by inverting perspectiveMatrix and multiplying
    // rhs by the inverse.
    SkMatrix44 inversePerspectiveMatrix(SkMatrix44::kUninitialized_Constructor);
    if (!perspectiveMatrix.invert(&inversePerspectiveMatrix))
      return false;

    SkMatrix44 transposedInversePerspectiveMatrix =
        inversePerspectiveMatrix;

    transposedInversePerspectiveMatrix.transpose();
    transposedInversePerspectiveMatrix.mapMScalars(rhs);

    for (int i = 0; i < 4; ++i)
      decomp->perspective[i] = rhs[i];

  } else {
    // No perspective.
    for (int i = 0; i < 3; ++i)
      decomp->perspective[i] = 0.0;
    decomp->perspective[3] = 1.0;
  }

  for (int i = 0; i < 3; i++)
    decomp->translate[i] = matrix.get(i, 3);

  SkMScalar row[3][3];
  for (int i = 0; i < 3; i++)
    for (int j = 0; j < 3; ++j)
      row[i][j] = matrix.get(j, i);

  // Compute X scale factor and normalize first row.
  decomp->scale[0] = Length3(row[0]);
  if (decomp->scale[0] != 0.0)
    Scale3(row[0], 1.0 / decomp->scale[0]);

  // Compute XY shear factor and make 2nd row orthogonal to 1st.
  decomp->skew[0] = Dot<3>(row[0], row[1]);
  Combine<3>(row[1], row[1], row[0], 1.0, -decomp->skew[0]);

  // Now, compute Y scale and normalize 2nd row.
  decomp->scale[1] = Length3(row[1]);
  if (decomp->scale[1] != 0.0)
    Scale3(row[1], 1.0 / decomp->scale[1]);

  decomp->skew[0] /= decomp->scale[1];

  // Compute XZ and YZ shears, orthogonalize 3rd row
  decomp->skew[1] = Dot<3>(row[0], row[2]);
  Combine<3>(row[2], row[2], row[0], 1.0, -decomp->skew[1]);
  decomp->skew[2] = Dot<3>(row[1], row[2]);
  Combine<3>(row[2], row[2], row[1], 1.0, -decomp->skew[2]);

  // Next, get Z scale and normalize 3rd row.
  decomp->scale[2] = Length3(row[2]);
  if (decomp->scale[2] != 0.0)
    Scale3(row[2], 1.0 / decomp->scale[2]);

  decomp->skew[1] /= decomp->scale[2];
  decomp->skew[2] /= decomp->scale[2];

  // At this point, the matrix (in rows) is orthonormal.
  // Check for a coordinate system flip.  If the determinant
  // is -1, then negate the matrix and the scaling factors.
  SkMScalar pdum3[3];
  Cross3(pdum3, row[1], row[2]);
  if (Dot<3>(row[0], pdum3) < 0) {
    for (int i = 0; i < 3; i++) {
      decomp->scale[i] *= -1.0;
      for (int j = 0; j < 3; ++j)
        row[i][j] *= -1.0;
    }
  }

  decomp->quaternion[0] =
      0.5 * std::sqrt(std::max(1.0 + row[0][0] - row[1][1] - row[2][2], 0.0));
  decomp->quaternion[1] =
      0.5 * std::sqrt(std::max(1.0 - row[0][0] + row[1][1] - row[2][2], 0.0));
  decomp->quaternion[2] =
      0.5 * std::sqrt(std::max(1.0 - row[0][0] - row[1][1] + row[2][2], 0.0));
  decomp->quaternion[3] =
      0.5 * std::sqrt(std::max(1.0 + row[0][0] + row[1][1] + row[2][2], 0.0));

  if (row[2][1] > row[1][2])
      decomp->quaternion[0] = -decomp->quaternion[0];
  if (row[0][2] > row[2][0])
      decomp->quaternion[1] = -decomp->quaternion[1];
  if (row[1][0] > row[0][1])
      decomp->quaternion[2] = -decomp->quaternion[2];

  return true;
}

// Taken from http://www.w3.org/TR/css3-transforms/.
Transform ComposeTransform(const DecomposedTransform& decomp) {
  SkMatrix44 perspective = BuildPerspectiveMatrix(decomp);
  SkMatrix44 translation = BuildTranslationMatrix(decomp);
  SkMatrix44 rotation = BuildRotationMatrix(decomp);
  SkMatrix44 skew = BuildSkewMatrix(decomp);
  SkMatrix44 scale = BuildScaleMatrix(decomp);

  return ComposeTransform(perspective, translation, rotation, skew, scale);
}

bool SnapTransform(Transform* out,
                   const Transform& transform,
                   const Rect& viewport) {
  DecomposedTransform decomp;
  DecomposeTransform(&decomp, transform);

  SkMatrix44 rotation_matrix = BuildSnappedRotationMatrix(decomp);
  SkMatrix44 translation = BuildSnappedTranslationMatrix(decomp);
  SkMatrix44 scale = BuildSnappedScaleMatrix(decomp);

  // Rebuild matrices for other unchanged components.
  SkMatrix44 perspective = BuildPerspectiveMatrix(decomp);

  // Completely ignore the skew.
  SkMatrix44 skew(SkMatrix44::kIdentity_Constructor);

  // Get full tranform
  Transform snapped =
      ComposeTransform(perspective, translation, rotation_matrix, skew, scale);

  // Verify that viewport is not moved unnaturally.
  bool snappable =
    CheckTransformsMapsIntViewportWithinOnePixel(viewport, transform, snapped);
  if (snappable) {
    *out = snapped;
  }
  return snappable;
}

std::string DecomposedTransform::ToString() const {
  return base::StringPrintf(
      "translate: %+0.4f %+0.4f %+0.4f\n"
      "scale: %+0.4f %+0.4f %+0.4f\n"
      "skew: %+0.4f %+0.4f %+0.4f\n"
      "perspective: %+0.4f %+0.4f %+0.4f %+0.4f\n"
      "quaternion: %+0.4f %+0.4f %+0.4f %+0.4f\n",
      translate[0],
      translate[1],
      translate[2],
      scale[0],
      scale[1],
      scale[2],
      skew[0],
      skew[1],
      skew[2],
      perspective[0],
      perspective[1],
      perspective[2],
      perspective[3],
      quaternion[0],
      quaternion[1],
      quaternion[2],
      quaternion[3]);
}

float MatrixDistance(const Transform& a, const Transform& b) {
  double sum = 0.0;

  const SkMatrix44& a_data = a.matrix();
  const SkMatrix44& b_data = b.matrix();

  for (int row = 0; row < 4; ++row) {
    for (int col = 0; col < 4; ++col) {
      double diff = a_data.get(row, col) - b_data.get(row, col);
      sum += diff * diff;
    }
  }

  return static_cast<float>(std::sqrt(sum));
}


}  // namespace ui
