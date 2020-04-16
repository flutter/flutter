// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_MATRIX_DECOMPOSITION_H_
#define FLUTTER_FLOW_MATRIX_DECOMPOSITION_H_

#include "flutter/fml/macros.h"
#include "third_party/skia/include/core/SkM44.h"
#include "third_party/skia/include/core/SkMatrix.h"

namespace flutter {

/// Decomposes a given non-degenerate transformation matrix into a sequence of
/// operations that produced it. The validity of the decomposition must always
/// be checked before attempting to access any of the decomposed elements.
class MatrixDecomposition {
 public:
  MatrixDecomposition(const SkMatrix& matrix);

  MatrixDecomposition(SkM44 matrix);

  ~MatrixDecomposition();

  bool IsValid() const;

  const SkV3& translation() const { return translation_; }

  const SkV3& scale() const { return scale_; }

  const SkV3& shear() const { return shear_; }

  const SkV4& perspective() const { return perspective_; }

  const SkV4& rotation() const { return rotation_; }

 private:
  bool valid_;
  SkV3 translation_;
  SkV3 scale_;
  SkV3 shear_;
  SkV4 perspective_;
  SkV4 rotation_;

  FML_DISALLOW_COPY_AND_ASSIGN(MatrixDecomposition);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_MATRIX_DECOMPOSITION_H_
