// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_MATRIX_H_
#define FLUTTER_LIB_UI_PAINTING_MATRIX_H_

#include "flutter/tonic/float64_list.h"
#include "third_party/skia/include/core/SkMatrix.h"

namespace blink {

SkMatrix ToSkMatrix(const Float64List& matrix4);
Float64List ToMatrix4(const SkMatrix& sk_matrix);

}  // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_MATRIX_H_
