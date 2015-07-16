// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/interfaces/bindings/tests/test_constants.mojom.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace test {

TEST(ConstantTest, GlobalConstants) {
  // Compile-time constants.
  static_assert(kBoolValue == true, "");
  static_assert(kInt8Value == -2, "");
  static_assert(kUint8Value == 128U, "");
  static_assert(kInt16Value == -233, "");
  static_assert(kUint16Value == 44204U, "");
  static_assert(kInt32Value == -44204, "");
  static_assert(kUint32Value == 4294967295U, "");
  static_assert(kInt64Value == -9223372036854775807, "");
  static_assert(kUint64Value == 9999999999999999999ULL, "");

  EXPECT_DOUBLE_EQ(kDoubleValue, 3.14159);
  EXPECT_FLOAT_EQ(kFloatValue, 2.71828f);
}

TEST(ConstantTest, StructConstants) {
  // Compile-time constants.
  static_assert(StructWithConstants::kInt8Value == 5U, "");

  EXPECT_FLOAT_EQ(StructWithConstants::kFloatValue, 765.432f);
}

TEST(ConstantTest, InterfaceConstants) {
  // Compile-time constants.
  static_assert(InterfaceWithConstants::kUint32Value == 20100722, "");

  EXPECT_DOUBLE_EQ(InterfaceWithConstants::kDoubleValue, 12.34567);
}

}  // namespace test
}  // namespace mojo
