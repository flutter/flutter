// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/atomicops.h"

#include <stdint.h>
#include <string.h>

#include "testing/gtest/include/gtest/gtest.h"

template <class AtomicType>
static void TestAtomicIncrement() {
  // For now, we just test single threaded execution

  // use a guard value to make sure the NoBarrier_AtomicIncrement doesn't go
  // outside the expected address bounds.  This is in particular to
  // test that some future change to the asm code doesn't cause the
  // 32-bit NoBarrier_AtomicIncrement doesn't do the wrong thing on 64-bit
  // machines.
  struct {
    AtomicType prev_word;
    AtomicType count;
    AtomicType next_word;
  } s;

  AtomicType prev_word_value, next_word_value;
  memset(&prev_word_value, 0xFF, sizeof(AtomicType));
  memset(&next_word_value, 0xEE, sizeof(AtomicType));

  s.prev_word = prev_word_value;
  s.count = 0;
  s.next_word = next_word_value;

  EXPECT_EQ(base::subtle::NoBarrier_AtomicIncrement(&s.count, 1), 1);
  EXPECT_EQ(s.count, 1);
  EXPECT_EQ(s.prev_word, prev_word_value);
  EXPECT_EQ(s.next_word, next_word_value);

  EXPECT_EQ(base::subtle::NoBarrier_AtomicIncrement(&s.count, 2), 3);
  EXPECT_EQ(s.count, 3);
  EXPECT_EQ(s.prev_word, prev_word_value);
  EXPECT_EQ(s.next_word, next_word_value);

  EXPECT_EQ(base::subtle::NoBarrier_AtomicIncrement(&s.count, 3), 6);
  EXPECT_EQ(s.count, 6);
  EXPECT_EQ(s.prev_word, prev_word_value);
  EXPECT_EQ(s.next_word, next_word_value);

  EXPECT_EQ(base::subtle::NoBarrier_AtomicIncrement(&s.count, -3), 3);
  EXPECT_EQ(s.count, 3);
  EXPECT_EQ(s.prev_word, prev_word_value);
  EXPECT_EQ(s.next_word, next_word_value);

  EXPECT_EQ(base::subtle::NoBarrier_AtomicIncrement(&s.count, -2), 1);
  EXPECT_EQ(s.count, 1);
  EXPECT_EQ(s.prev_word, prev_word_value);
  EXPECT_EQ(s.next_word, next_word_value);

  EXPECT_EQ(base::subtle::NoBarrier_AtomicIncrement(&s.count, -1), 0);
  EXPECT_EQ(s.count, 0);
  EXPECT_EQ(s.prev_word, prev_word_value);
  EXPECT_EQ(s.next_word, next_word_value);

  EXPECT_EQ(base::subtle::NoBarrier_AtomicIncrement(&s.count, -1), -1);
  EXPECT_EQ(s.count, -1);
  EXPECT_EQ(s.prev_word, prev_word_value);
  EXPECT_EQ(s.next_word, next_word_value);

  EXPECT_EQ(base::subtle::NoBarrier_AtomicIncrement(&s.count, -4), -5);
  EXPECT_EQ(s.count, -5);
  EXPECT_EQ(s.prev_word, prev_word_value);
  EXPECT_EQ(s.next_word, next_word_value);

  EXPECT_EQ(base::subtle::NoBarrier_AtomicIncrement(&s.count, 5), 0);
  EXPECT_EQ(s.count, 0);
  EXPECT_EQ(s.prev_word, prev_word_value);
  EXPECT_EQ(s.next_word, next_word_value);
}


#define NUM_BITS(T) (sizeof(T) * 8)


template <class AtomicType>
static void TestCompareAndSwap() {
  AtomicType value = 0;
  AtomicType prev = base::subtle::NoBarrier_CompareAndSwap(&value, 0, 1);
  EXPECT_EQ(1, value);
  EXPECT_EQ(0, prev);

  // Use test value that has non-zero bits in both halves, more for testing
  // 64-bit implementation on 32-bit platforms.
  const AtomicType k_test_val = (static_cast<uint64_t>(1) <<
                                 (NUM_BITS(AtomicType) - 2)) + 11;
  value = k_test_val;
  prev = base::subtle::NoBarrier_CompareAndSwap(&value, 0, 5);
  EXPECT_EQ(k_test_val, value);
  EXPECT_EQ(k_test_val, prev);

  value = k_test_val;
  prev = base::subtle::NoBarrier_CompareAndSwap(&value, k_test_val, 5);
  EXPECT_EQ(5, value);
  EXPECT_EQ(k_test_val, prev);
}


template <class AtomicType>
static void TestAtomicExchange() {
  AtomicType value = 0;
  AtomicType new_value = base::subtle::NoBarrier_AtomicExchange(&value, 1);
  EXPECT_EQ(1, value);
  EXPECT_EQ(0, new_value);

  // Use test value that has non-zero bits in both halves, more for testing
  // 64-bit implementation on 32-bit platforms.
  const AtomicType k_test_val = (static_cast<uint64_t>(1) <<
                                 (NUM_BITS(AtomicType) - 2)) + 11;
  value = k_test_val;
  new_value = base::subtle::NoBarrier_AtomicExchange(&value, k_test_val);
  EXPECT_EQ(k_test_val, value);
  EXPECT_EQ(k_test_val, new_value);

  value = k_test_val;
  new_value = base::subtle::NoBarrier_AtomicExchange(&value, 5);
  EXPECT_EQ(5, value);
  EXPECT_EQ(k_test_val, new_value);
}


template <class AtomicType>
static void TestAtomicIncrementBounds() {
  // Test at rollover boundary between int_max and int_min
  AtomicType test_val = (static_cast<uint64_t>(1) <<
                         (NUM_BITS(AtomicType) - 1));
  AtomicType value = -1 ^ test_val;
  AtomicType new_value = base::subtle::NoBarrier_AtomicIncrement(&value, 1);
  EXPECT_EQ(test_val, value);
  EXPECT_EQ(value, new_value);

  base::subtle::NoBarrier_AtomicIncrement(&value, -1);
  EXPECT_EQ(-1 ^ test_val, value);

  // Test at 32-bit boundary for 64-bit atomic type.
  test_val = static_cast<uint64_t>(1) << (NUM_BITS(AtomicType) / 2);
  value = test_val - 1;
  new_value = base::subtle::NoBarrier_AtomicIncrement(&value, 1);
  EXPECT_EQ(test_val, value);
  EXPECT_EQ(value, new_value);

  base::subtle::NoBarrier_AtomicIncrement(&value, -1);
  EXPECT_EQ(test_val - 1, value);
}

// Return an AtomicType with the value 0xa5a5a5..
template <class AtomicType>
static AtomicType TestFillValue() {
  AtomicType val = 0;
  memset(&val, 0xa5, sizeof(AtomicType));
  return val;
}

// This is a simple sanity check that values are correct. Not testing
// atomicity
template <class AtomicType>
static void TestStore() {
  const AtomicType kVal1 = TestFillValue<AtomicType>();
  const AtomicType kVal2 = static_cast<AtomicType>(-1);

  AtomicType value;

  base::subtle::NoBarrier_Store(&value, kVal1);
  EXPECT_EQ(kVal1, value);
  base::subtle::NoBarrier_Store(&value, kVal2);
  EXPECT_EQ(kVal2, value);

  base::subtle::Acquire_Store(&value, kVal1);
  EXPECT_EQ(kVal1, value);
  base::subtle::Acquire_Store(&value, kVal2);
  EXPECT_EQ(kVal2, value);

  base::subtle::Release_Store(&value, kVal1);
  EXPECT_EQ(kVal1, value);
  base::subtle::Release_Store(&value, kVal2);
  EXPECT_EQ(kVal2, value);
}

// This is a simple sanity check that values are correct. Not testing
// atomicity
template <class AtomicType>
static void TestLoad() {
  const AtomicType kVal1 = TestFillValue<AtomicType>();
  const AtomicType kVal2 = static_cast<AtomicType>(-1);

  AtomicType value;

  value = kVal1;
  EXPECT_EQ(kVal1, base::subtle::NoBarrier_Load(&value));
  value = kVal2;
  EXPECT_EQ(kVal2, base::subtle::NoBarrier_Load(&value));

  value = kVal1;
  EXPECT_EQ(kVal1, base::subtle::Acquire_Load(&value));
  value = kVal2;
  EXPECT_EQ(kVal2, base::subtle::Acquire_Load(&value));

  value = kVal1;
  EXPECT_EQ(kVal1, base::subtle::Release_Load(&value));
  value = kVal2;
  EXPECT_EQ(kVal2, base::subtle::Release_Load(&value));
}

TEST(AtomicOpsTest, Inc) {
  TestAtomicIncrement<base::subtle::Atomic32>();
  TestAtomicIncrement<base::subtle::AtomicWord>();
}

TEST(AtomicOpsTest, CompareAndSwap) {
  TestCompareAndSwap<base::subtle::Atomic32>();
  TestCompareAndSwap<base::subtle::AtomicWord>();
}

TEST(AtomicOpsTest, Exchange) {
  TestAtomicExchange<base::subtle::Atomic32>();
  TestAtomicExchange<base::subtle::AtomicWord>();
}

TEST(AtomicOpsTest, IncrementBounds) {
  TestAtomicIncrementBounds<base::subtle::Atomic32>();
  TestAtomicIncrementBounds<base::subtle::AtomicWord>();
}

TEST(AtomicOpsTest, Store) {
  TestStore<base::subtle::Atomic32>();
  TestStore<base::subtle::AtomicWord>();
}

TEST(AtomicOpsTest, Load) {
  TestLoad<base::subtle::Atomic32>();
  TestLoad<base::subtle::AtomicWord>();
}
