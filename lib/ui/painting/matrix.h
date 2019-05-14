// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_MATRIX_H_
#define FLUTTER_LIB_UI_PAINTING_MATRIX_H_

#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/tonic/typed_data/typed_list.h"

namespace flutter {

SkMatrix ToSkMatrix(const tonic::Float64List& matrix4);
tonic::Float64List ToMatrix4(const SkMatrix& sk_matrix);

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_MATRIX_H_
