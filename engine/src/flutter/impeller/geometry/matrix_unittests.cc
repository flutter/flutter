// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include "flutter/impeller/geometry/matrix.h"

#include "flutter/impeller/geometry/geometry_asserts.h"

namespace impeller {
namespace testing {

TEST(MatrixTest, Multiply) {
  Matrix x(0.0, 0.0, 0.0, 1.0,  //
           1.0, 0.0, 0.0, 1.0,  //
           0.0, 1.0, 0.0, 1.0,  //
           1.0, 1.0, 0.0, 1.0);
  Matrix translate = Matrix::MakeTranslation({10, 20, 0});
  Matrix result = translate * x;
  EXPECT_TRUE(MatrixNear(result, Matrix(10.0, 20.0, 0.0, 1.0,  //
                                        11.0, 20.0, 0.0, 1.0,  //
                                        10.0, 21.0, 0.0, 1.0,  //
                                        11.0, 21.0, 0.0, 1.0)));
}

}  // namespace testing
}  // namespace impeller
