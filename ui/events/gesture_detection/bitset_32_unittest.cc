// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/basictypes.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/events/gesture_detection/bitset_32.h"

namespace ui {

class BitSet32Test : public testing::Test {};

TEST_F(BitSet32Test, Basic) {
  BitSet32 bits;

  // Test the empty set.
  EXPECT_EQ(0U, bits.count());
  EXPECT_TRUE(bits.is_empty());
  EXPECT_FALSE(bits.is_full());
  EXPECT_FALSE(bits.has_bit(0));
  EXPECT_FALSE(bits.has_bit(31));

  // Mark the first bit.
  bits.mark_bit(0);
  EXPECT_EQ(1U, bits.count());
  EXPECT_FALSE(bits.is_empty());
  EXPECT_FALSE(bits.is_full());
  EXPECT_TRUE(bits.has_bit(0));
  EXPECT_FALSE(bits.has_bit(31));
  EXPECT_EQ(0U, bits.first_marked_bit());
  EXPECT_EQ(0U, bits.last_marked_bit());
  EXPECT_EQ(1U, bits.first_unmarked_bit());

  // Mark the last bit.
  bits.mark_bit(31);
  EXPECT_EQ(2U, bits.count());
  EXPECT_FALSE(bits.is_empty());
  EXPECT_FALSE(bits.is_full());
  EXPECT_TRUE(bits.has_bit(0));
  EXPECT_TRUE(bits.has_bit(31));
  EXPECT_FALSE(bits.has_bit(15));
  EXPECT_EQ(0U, bits.first_marked_bit());
  EXPECT_EQ(31U, bits.last_marked_bit());
  EXPECT_EQ(1U, bits.first_unmarked_bit());
  EXPECT_EQ(0U, bits.get_index_of_bit(0));
  EXPECT_EQ(1U, bits.get_index_of_bit(1));
  EXPECT_EQ(1U, bits.get_index_of_bit(2));
  EXPECT_EQ(1U, bits.get_index_of_bit(31));

  // Clear the first bit.
  bits.clear_first_marked_bit();
  EXPECT_EQ(1U, bits.count());
  EXPECT_FALSE(bits.is_empty());
  EXPECT_FALSE(bits.is_full());
  EXPECT_FALSE(bits.has_bit(0));
  EXPECT_TRUE(bits.has_bit(31));
  EXPECT_EQ(31U, bits.first_marked_bit());
  EXPECT_EQ(31U, bits.last_marked_bit());
  EXPECT_EQ(0U, bits.first_unmarked_bit());
  EXPECT_EQ(0U, bits.get_index_of_bit(0));
  EXPECT_EQ(0U, bits.get_index_of_bit(1));
  EXPECT_EQ(0U, bits.get_index_of_bit(31));

  // Clear the last bit (the set should be empty).
  bits.clear_last_marked_bit();
  EXPECT_EQ(0U, bits.count());
  EXPECT_TRUE(bits.is_empty());
  EXPECT_FALSE(bits.is_full());
  EXPECT_FALSE(bits.has_bit(0));
  EXPECT_FALSE(bits.has_bit(31));
  EXPECT_EQ(0U, bits.get_index_of_bit(0));
  EXPECT_EQ(0U, bits.get_index_of_bit(31));
  EXPECT_EQ(BitSet32(), bits);

  // Mark the first unmarked bit (bit 0).
  bits.mark_first_unmarked_bit();
  EXPECT_EQ(1U, bits.count());
  EXPECT_FALSE(bits.is_empty());
  EXPECT_FALSE(bits.is_full());
  EXPECT_TRUE(bits.has_bit(0));
  EXPECT_EQ(0U, bits.first_marked_bit());
  EXPECT_EQ(0U, bits.last_marked_bit());
  EXPECT_EQ(1U, bits.first_unmarked_bit());

  // Mark the next unmarked bit (bit 1).
  bits.mark_first_unmarked_bit();
  EXPECT_EQ(2U, bits.count());
  EXPECT_FALSE(bits.is_empty());
  EXPECT_FALSE(bits.is_full());
  EXPECT_TRUE(bits.has_bit(0));
  EXPECT_TRUE(bits.has_bit(1));
  EXPECT_EQ(0U, bits.first_marked_bit());
  EXPECT_EQ(1U, bits.last_marked_bit());
  EXPECT_EQ(2U, bits.first_unmarked_bit());
  EXPECT_EQ(0U, bits.get_index_of_bit(0));
  EXPECT_EQ(1U, bits.get_index_of_bit(1));
  EXPECT_EQ(2U, bits.get_index_of_bit(2));
}

}  // namespace ui
