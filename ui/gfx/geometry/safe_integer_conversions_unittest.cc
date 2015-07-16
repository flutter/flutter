// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/geometry/safe_integer_conversions.h"

#include <limits>

#include "testing/gtest/include/gtest/gtest.h"

namespace gfx {

TEST(SafeIntegerConversions, ClampToInt) {
  EXPECT_EQ(0, ClampToInt(std::numeric_limits<float>::quiet_NaN()));

  float max = std::numeric_limits<int>::max();
  float min = std::numeric_limits<int>::min();
  float infinity = std::numeric_limits<float>::infinity();

  int int_max = std::numeric_limits<int>::max();
  int int_min = std::numeric_limits<int>::min();

  EXPECT_EQ(int_max, ClampToInt(infinity));
  EXPECT_EQ(int_max, ClampToInt(max));
  EXPECT_EQ(int_max, ClampToInt(max + 100));

  EXPECT_EQ(-100, ClampToInt(-100.5f));
  EXPECT_EQ(0, ClampToInt(0));
  EXPECT_EQ(100, ClampToInt(100.5f));

  EXPECT_EQ(int_min, ClampToInt(-infinity));
  EXPECT_EQ(int_min, ClampToInt(min));
  EXPECT_EQ(int_min, ClampToInt(min - 100));
}

TEST(SafeIntegerConversions, ToFlooredInt) {
  EXPECT_EQ(0, ToFlooredInt(std::numeric_limits<float>::quiet_NaN()));

  float max = std::numeric_limits<int>::max();
  float min = std::numeric_limits<int>::min();
  float infinity = std::numeric_limits<float>::infinity();

  int int_max = std::numeric_limits<int>::max();
  int int_min = std::numeric_limits<int>::min();

  EXPECT_EQ(int_max, ToFlooredInt(infinity));
  EXPECT_EQ(int_max, ToFlooredInt(max));
  EXPECT_EQ(int_max, ToFlooredInt(max + 100));

  EXPECT_EQ(-101, ToFlooredInt(-100.5f));
  EXPECT_EQ(0, ToFlooredInt(0.f));
  EXPECT_EQ(100, ToFlooredInt(100.5f));

  EXPECT_EQ(int_min, ToFlooredInt(-infinity));
  EXPECT_EQ(int_min, ToFlooredInt(min));
  EXPECT_EQ(int_min, ToFlooredInt(min - 100));
}

TEST(SafeIntegerConversions, ToCeiledInt) {
  EXPECT_EQ(0, ToCeiledInt(std::numeric_limits<float>::quiet_NaN()));

  float max = std::numeric_limits<int>::max();
  float min = std::numeric_limits<int>::min();
  float infinity = std::numeric_limits<float>::infinity();

  int int_max = std::numeric_limits<int>::max();
  int int_min = std::numeric_limits<int>::min();

  EXPECT_EQ(int_max, ToCeiledInt(infinity));
  EXPECT_EQ(int_max, ToCeiledInt(max));
  EXPECT_EQ(int_max, ToCeiledInt(max + 100));

  EXPECT_EQ(-100, ToCeiledInt(-100.5f));
  EXPECT_EQ(0, ToCeiledInt(0.f));
  EXPECT_EQ(101, ToCeiledInt(100.5f));

  EXPECT_EQ(int_min, ToCeiledInt(-infinity));
  EXPECT_EQ(int_min, ToCeiledInt(min));
  EXPECT_EQ(int_min, ToCeiledInt(min - 100));
}

TEST(SafeIntegerConversions, ToRoundedInt) {
  EXPECT_EQ(0, ToRoundedInt(std::numeric_limits<float>::quiet_NaN()));

  float max = std::numeric_limits<int>::max();
  float min = std::numeric_limits<int>::min();
  float infinity = std::numeric_limits<float>::infinity();

  int int_max = std::numeric_limits<int>::max();
  int int_min = std::numeric_limits<int>::min();

  EXPECT_EQ(int_max, ToRoundedInt(infinity));
  EXPECT_EQ(int_max, ToRoundedInt(max));
  EXPECT_EQ(int_max, ToRoundedInt(max + 100));

  EXPECT_EQ(-100, ToRoundedInt(-100.1f));
  EXPECT_EQ(-101, ToRoundedInt(-100.5f));
  EXPECT_EQ(-101, ToRoundedInt(-100.9f));
  EXPECT_EQ(0, ToRoundedInt(0));
  EXPECT_EQ(100, ToRoundedInt(100.1f));
  EXPECT_EQ(101, ToRoundedInt(100.5f));
  EXPECT_EQ(101, ToRoundedInt(100.9f));

  EXPECT_EQ(int_min, ToRoundedInt(-infinity));
  EXPECT_EQ(int_min, ToRoundedInt(min));
  EXPECT_EQ(int_min, ToRoundedInt(min - 100));
}

}  // namespace gfx
