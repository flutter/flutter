// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Tests for the bitfield helper class.

#include "testing/gtest/include/gtest/gtest.h"
#include "gpu/command_buffer/common/bitfield_helpers.h"

namespace gpu {

// Tests that BitField<>::Get returns the right bits.
TEST(BitFieldTest, TestGet) {
  unsigned int value = 0x12345678u;
  EXPECT_EQ(0x8u, (BitField<0, 4>::Get(value)));
  EXPECT_EQ(0x45u, (BitField<12, 8>::Get(value)));
  EXPECT_EQ(0x12345678u, (BitField<0, 32>::Get(value)));
}

// Tests that BitField<>::MakeValue generates the right bits.
TEST(BitFieldTest, TestMakeValue) {
  EXPECT_EQ(0x00000003u, (BitField<0, 4>::MakeValue(0x3)));
  EXPECT_EQ(0x00023000u, (BitField<12, 8>::MakeValue(0x123)));
  EXPECT_EQ(0x87654321u, (BitField<0, 32>::MakeValue(0x87654321)));
}

// Tests that BitField<>::Set modifies the right bits.
TEST(BitFieldTest, TestSet) {
  unsigned int value = 0x12345678u;
  BitField<0, 4>::Set(&value, 0x9);
  EXPECT_EQ(0x12345679u, value);
  BitField<12, 8>::Set(&value, 0x123);
  EXPECT_EQ(0x12323679u, value);
  BitField<0, 32>::Set(&value, 0x87654321);
  EXPECT_EQ(0x87654321u, value);
}

}  // namespace gpu
