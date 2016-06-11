// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_MATRIX_H_
#define SKY_ENGINE_CORE_PAINTING_MATRIX_H_

#include "sky/engine/tonic/float64_list.h"
#include "third_party/skia/include/core/SkMatrix.h"

namespace blink {

SkMatrix toSkMatrix(const Float64List& matrix4);
Float64List toMatrix4(const SkMatrix& sk_matrix);

}  // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_MATRIX_H_
