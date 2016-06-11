// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/Matrix.h"

namespace blink {

// Mappings from SkMatrix-index to input-index.
static const int kSkMatrixIndexToMatrix4Index[] = {
    0, 4, 12,
    1, 5, 13,
    3, 7, 15,
};

SkMatrix toSkMatrix(const Float64List& matrix4)
{
    DCHECK(matrix4.data());
    SkMatrix sk_matrix;
    for (int i = 0; i < 9; ++i) {
        int matrix4_index = kSkMatrixIndexToMatrix4Index[i];
        if (matrix4_index < matrix4.num_elements())
            sk_matrix[i] = matrix4[matrix4_index];
        else
            sk_matrix[i] = 0.0;
    }
    return sk_matrix;
}

Float64List toMatrix4(const SkMatrix& sk_matrix)
{
    Float64List matrix4(Dart_NewTypedData(Dart_TypedData_kFloat64, 16));
    for (int i = 0; i < 9; ++i)
        matrix4[kSkMatrixIndexToMatrix4Index[i]] = sk_matrix[i];
    matrix4[10] = 1.0; // Identity along the z axis.
    return matrix4;
}

}  // namespace blink
