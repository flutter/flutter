// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <vector>

#include "base/scoped_generic.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

namespace {

struct IntTraits {
  IntTraits(std::vector<int>* freed) : freed_ints(freed) {}

  static int InvalidValue() {
    return -1;
  }
  void Free(int value) {
    freed_ints->push_back(value);
  }

  std::vector<int>* freed_ints;
};

typedef ScopedGeneric<int, IntTraits> ScopedInt;

}  // namespace

TEST(ScopedGenericTest, ScopedGeneric) {
  std::vector<int> values_freed;
  IntTraits traits(&values_freed);

  // Invalid case, delete should not be called.
  {
    ScopedInt a(IntTraits::InvalidValue(), traits);
  }
  EXPECT_TRUE(values_freed.empty());

  // Simple deleting case.
  static const int kFirst = 0;
  {
    ScopedInt a(kFirst, traits);
  }
  ASSERT_EQ(1u, values_freed.size());
  ASSERT_EQ(kFirst, values_freed[0]);
  values_freed.clear();

  // Release should return the right value and leave the object empty.
  {
    ScopedInt a(kFirst, traits);
    EXPECT_EQ(kFirst, a.release());

    ScopedInt b(IntTraits::InvalidValue(), traits);
    EXPECT_EQ(IntTraits::InvalidValue(), b.release());
  }
  ASSERT_TRUE(values_freed.empty());

  // Reset should free the old value, then the new one should go away when
  // it goes out of scope.
  static const int kSecond = 1;
  {
    ScopedInt b(kFirst, traits);
    b.reset(kSecond);
    ASSERT_EQ(1u, values_freed.size());
    ASSERT_EQ(kFirst, values_freed[0]);
  }
  ASSERT_EQ(2u, values_freed.size());
  ASSERT_EQ(kSecond, values_freed[1]);
  values_freed.clear();

  // Swap.
  {
    ScopedInt a(kFirst, traits);
    ScopedInt b(kSecond, traits);
    a.swap(b);
    EXPECT_TRUE(values_freed.empty());  // Nothing should be freed.
    EXPECT_EQ(kSecond, a.get());
    EXPECT_EQ(kFirst, b.get());
  }
  // Values should be deleted in the opposite order.
  ASSERT_EQ(2u, values_freed.size());
  EXPECT_EQ(kFirst, values_freed[0]);
  EXPECT_EQ(kSecond, values_freed[1]);
  values_freed.clear();

  // Pass constructor.
  {
    ScopedInt a(kFirst, traits);
    ScopedInt b(a.Pass());
    EXPECT_TRUE(values_freed.empty());  // Nothing should be freed.
    ASSERT_EQ(IntTraits::InvalidValue(), a.get());
    ASSERT_EQ(kFirst, b.get());
  }

  ASSERT_EQ(1u, values_freed.size());
  ASSERT_EQ(kFirst, values_freed[0]);
  values_freed.clear();

  // Pass assign.
  {
    ScopedInt a(kFirst, traits);
    ScopedInt b(kSecond, traits);
    b = a.Pass();
    ASSERT_EQ(1u, values_freed.size());
    EXPECT_EQ(kSecond, values_freed[0]);
    ASSERT_EQ(IntTraits::InvalidValue(), a.get());
    ASSERT_EQ(kFirst, b.get());
  }

  ASSERT_EQ(2u, values_freed.size());
  EXPECT_EQ(kFirst, values_freed[1]);
  values_freed.clear();
}

TEST(ScopedGenericTest, Operators) {
  std::vector<int> values_freed;
  IntTraits traits(&values_freed);

  static const int kFirst = 0;
  static const int kSecond = 1;
  {
    ScopedInt a(kFirst, traits);
    EXPECT_TRUE(a == kFirst);
    EXPECT_FALSE(a != kFirst);
    EXPECT_FALSE(a == kSecond);
    EXPECT_TRUE(a != kSecond);

    EXPECT_TRUE(kFirst == a);
    EXPECT_FALSE(kFirst != a);
    EXPECT_FALSE(kSecond == a);
    EXPECT_TRUE(kSecond != a);
  }

  // is_valid().
  {
    ScopedInt a(kFirst, traits);
    EXPECT_TRUE(a.is_valid());
    a.reset();
    EXPECT_FALSE(a.is_valid());
  }
}

// Cheesy manual "no compile" test for manually validating changes.
#if 0
TEST(ScopedGenericTest, NoCompile) {
  // Assignment shouldn't work.
  /*{
    ScopedInt a(kFirst, traits);
    ScopedInt b(a);
  }*/

  // Comparison shouldn't work.
  /*{
    ScopedInt a(kFirst, traits);
    ScopedInt b(kFirst, traits);
    if (a == b) {
    }
  }*/

  // Implicit conversion to bool shouldn't work.
  /*{
    ScopedInt a(kFirst, traits);
    bool result = a;
  }*/
}
#endif

}  // namespace base
