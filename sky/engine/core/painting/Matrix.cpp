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

SkMatrix toSkMatrix(const Float32List& matrix4, ExceptionState& es)
{
    ASSERT(matrix4.data());
    SkMatrix sk_matrix;
    if (matrix4.num_elements() != 16) {
        es.ThrowTypeError("Incorrect number of elements in matrix.");
        return sk_matrix;
    }

    for (intptr_t i = 0; i < 9; ++i)
        sk_matrix[i] = matrix4[kSkMatrixIndexToMatrix4Index[i]];
    return sk_matrix;
}

Float32List toMatrix4(const SkMatrix& sk_matrix)
{
    Float32List matrix4(Dart_NewTypedData(Dart_TypedData_kFloat32, 16));
    for (intptr_t i = 0; i < 9; ++i)
        matrix4[kSkMatrixIndexToMatrix4Index[i]] = sk_matrix[i];
    matrix4[10] = 1.0; // Identity along the z axis.
    return matrix4;
}

}  // namespace blink
