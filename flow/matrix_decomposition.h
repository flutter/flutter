// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_MATRIX_DECOMPOSITION_H_
#define FLUTTER_FLOW_MATRIX_DECOMPOSITION_H_

#include "flutter/fml/macros.h"
#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkMatrix44.h"
#include "third_party/skia/include/core/SkPoint3.h"

namespace flow {

/// Decomposes a given non-degenerate transformation matrix into a sequence of
/// operations that produced it. The validity of the decomposition must always
/// be checked before attempting to access any of the decomposed elements.
class MatrixDecomposition {
 public:
  MatrixDecomposition(const SkMatrix& matrix);

  MatrixDecomposition(SkMatrix44 matrix);

  ~MatrixDecomposition();

  bool IsValid() const;

  const SkVector3& translation() const { return translation_; }

  const SkVector3& scale() const { return scale_; }

  const SkVector3& shear() const { return shear_; }

  const SkVector4& perspective() const { return perspective_; }

  const SkVector4& rotation() const { return rotation_; }

 private:
  bool valid_;
  SkVector3 translation_;
  SkVector3 scale_;
  SkVector3 shear_;
  SkVector4 perspective_;
  SkVector4 rotation_;

  FML_DISALLOW_COPY_AND_ASSIGN(MatrixDecomposition);
};

}  // namespace flow

#endif  // FLUTTER_FLOW_MATRIX_DECOMPOSITION_H_
