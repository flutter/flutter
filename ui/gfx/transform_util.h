// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_TRANSFORM_UTIL_H_
#define UI_GFX_TRANSFORM_UTIL_H_

#include "ui/gfx/gfx_export.h"
#include "ui/gfx/transform.h"

namespace gfx {

class Point;
class Rect;

// Returns a scale transform at |anchor| point.
GFX_EXPORT Transform GetScaleTransform(const Point& anchor, float scale);

// Contains the components of a factored transform. These components may be
// blended and recomposed.
struct GFX_EXPORT DecomposedTransform {
  // The default constructor initializes the components in such a way that
  // if used with Compose below, will produce the identity transform.
  DecomposedTransform();

  SkMScalar translate[3];
  SkMScalar scale[3];
  SkMScalar skew[3];
  SkMScalar perspective[4];
  SkMScalar quaternion[4];

  std::string ToString() const;

  // Copy and assign are allowed.
};

// Interpolates the decomposed components |to| with |from| using the
// routines described in http://www.w3.org/TR/css3-3d-transform/.
// |progress| is in the range [0, 1] (0 leaves |out| unchanged, and 1
// assigns |from| to |out|).
GFX_EXPORT bool BlendDecomposedTransforms(DecomposedTransform* out,
                                          const DecomposedTransform& to,
                                          const DecomposedTransform& from,
                                          double progress);

// Decomposes this transform into its translation, scale, skew, perspective,
// and rotation components following the routines detailed in this spec:
// http://www.w3.org/TR/css3-3d-transforms/.
GFX_EXPORT bool DecomposeTransform(DecomposedTransform* out,
                                   const Transform& transform);

// Composes a transform from the given translation, scale, skew, prespective,
// and rotation components following the routines detailed in this spec:
// http://www.w3.org/TR/css3-3d-transforms/.
GFX_EXPORT Transform ComposeTransform(const DecomposedTransform& decomp);

GFX_EXPORT bool SnapTransform(Transform* out,
                              const Transform& transform,
                              const Rect& viewport);

// Computes the Frobenius norm of (a - b).
GFX_EXPORT float MatrixDistance(const Transform& a, const Transform& b);

}  // namespace gfx

#endif  // UI_GFX_TRANSFORM_UTIL_H_
