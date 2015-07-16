// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <limits>

#include "mojo/public/cpp/bindings/lib/bindings_serialization.h"
#include "mojo/public/cpp/bindings/lib/bounds_checker.h"
#include "mojo/public/cpp/system/core.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace test {
namespace {

const void* ToPtr(uintptr_t ptr) {
  return reinterpret_cast<const void*>(ptr);
}

#if defined(NDEBUG) && !defined(DCHECK_ALWAYS_ON)
TEST(BoundsCheckerTest, ConstructorRangeOverflow) {
  {
    // Test memory range overflow.
    internal::BoundsChecker checker(
        ToPtr(std::numeric_limits<uintptr_t>::max() - 3000), 5000, 0);

    EXPECT_FALSE(checker.IsValidRange(
        ToPtr(std::numeric_limits<uintptr_t>::max() - 3000), 1));
    EXPECT_FALSE(checker.ClaimMemory(
        ToPtr(std::numeric_limits<uintptr_t>::max() - 3000), 1));
  }

  if (sizeof(size_t) > sizeof(uint32_t)) {
    // Test handle index range overflow.
    size_t num_handles =
        static_cast<size_t>(std::numeric_limits<uint32_t>::max()) + 5;
    internal::BoundsChecker checker(ToPtr(0), 0, num_handles);

    EXPECT_FALSE(checker.ClaimHandle(Handle(0)));
    EXPECT_FALSE(
        checker.ClaimHandle(Handle(std::numeric_limits<uint32_t>::max() - 1)));

    EXPECT_TRUE(
        checker.ClaimHandle(Handle(internal::kEncodedInvalidHandleValue)));
  }
}
#endif

TEST(BoundsCheckerTest, IsValidRange) {
  {
    internal::BoundsChecker checker(ToPtr(1234), 100, 0);

    // Basics.
    EXPECT_FALSE(checker.IsValidRange(ToPtr(100), 5));
    EXPECT_FALSE(checker.IsValidRange(ToPtr(1230), 50));
    EXPECT_TRUE(checker.IsValidRange(ToPtr(1234), 5));
    EXPECT_TRUE(checker.IsValidRange(ToPtr(1240), 50));
    EXPECT_TRUE(checker.IsValidRange(ToPtr(1234), 100));
    EXPECT_FALSE(checker.IsValidRange(ToPtr(1234), 101));
    EXPECT_FALSE(checker.IsValidRange(ToPtr(1240), 100));
    EXPECT_FALSE(checker.IsValidRange(ToPtr(1333), 5));
    EXPECT_FALSE(checker.IsValidRange(ToPtr(2234), 5));

    // ClaimMemory() updates the valid range.
    EXPECT_TRUE(checker.ClaimMemory(ToPtr(1254), 10));

    EXPECT_FALSE(checker.IsValidRange(ToPtr(1234), 1));
    EXPECT_FALSE(checker.IsValidRange(ToPtr(1254), 10));
    EXPECT_FALSE(checker.IsValidRange(ToPtr(1263), 1));
    EXPECT_FALSE(checker.IsValidRange(ToPtr(1263), 10));
    EXPECT_TRUE(checker.IsValidRange(ToPtr(1264), 10));
    EXPECT_TRUE(checker.IsValidRange(ToPtr(1264), 70));
    EXPECT_FALSE(checker.IsValidRange(ToPtr(1264), 71));
  }

  {
    internal::BoundsChecker checker(ToPtr(1234), 100, 0);
    // Should return false for empty ranges.
    EXPECT_FALSE(checker.IsValidRange(ToPtr(0), 0));
    EXPECT_FALSE(checker.IsValidRange(ToPtr(1200), 0));
    EXPECT_FALSE(checker.IsValidRange(ToPtr(1234), 0));
    EXPECT_FALSE(checker.IsValidRange(ToPtr(1240), 0));
    EXPECT_FALSE(checker.IsValidRange(ToPtr(2234), 0));
  }

  {
    // The valid memory range is empty.
    internal::BoundsChecker checker(ToPtr(1234), 0, 0);

    EXPECT_FALSE(checker.IsValidRange(ToPtr(1234), 1));
    EXPECT_FALSE(checker.IsValidRange(ToPtr(1234), 0));
  }

  {
    internal::BoundsChecker checker(
        ToPtr(std::numeric_limits<uintptr_t>::max() - 2000), 1000, 0);

    // Test overflow.
    EXPECT_FALSE(checker.IsValidRange(
        ToPtr(std::numeric_limits<uintptr_t>::max() - 1500), 4000));
    EXPECT_FALSE(checker.IsValidRange(
        ToPtr(std::numeric_limits<uintptr_t>::max() - 1500),
        std::numeric_limits<uint32_t>::max()));

    // This should be fine.
    EXPECT_TRUE(checker.IsValidRange(
        ToPtr(std::numeric_limits<uintptr_t>::max() - 1500), 200));
  }
}

TEST(BoundsCheckerTest, ClaimHandle) {
  {
    internal::BoundsChecker checker(ToPtr(0), 0, 10);

    // Basics.
    EXPECT_TRUE(checker.ClaimHandle(Handle(0)));
    EXPECT_FALSE(checker.ClaimHandle(Handle(0)));

    EXPECT_TRUE(checker.ClaimHandle(Handle(9)));
    EXPECT_FALSE(checker.ClaimHandle(Handle(10)));

    // Should fail because it is smaller than the max index that has been
    // claimed.
    EXPECT_FALSE(checker.ClaimHandle(Handle(8)));

    // Should return true for invalid handle.
    EXPECT_TRUE(
        checker.ClaimHandle(Handle(internal::kEncodedInvalidHandleValue)));
    EXPECT_TRUE(
        checker.ClaimHandle(Handle(internal::kEncodedInvalidHandleValue)));
  }

  {
    // No handle to claim.
    internal::BoundsChecker checker(ToPtr(0), 0, 0);

    EXPECT_FALSE(checker.ClaimHandle(Handle(0)));

    // Should still return true for invalid handle.
    EXPECT_TRUE(
        checker.ClaimHandle(Handle(internal::kEncodedInvalidHandleValue)));
  }

  {
    // Test the case that |num_handles| is the same value as
    // |internal::kEncodedInvalidHandleValue|.
    EXPECT_EQ(internal::kEncodedInvalidHandleValue,
              std::numeric_limits<uint32_t>::max());
    internal::BoundsChecker checker(
        ToPtr(0), 0, std::numeric_limits<uint32_t>::max());

    EXPECT_TRUE(
        checker.ClaimHandle(Handle(std::numeric_limits<uint32_t>::max() - 1)));
    EXPECT_FALSE(
        checker.ClaimHandle(Handle(std::numeric_limits<uint32_t>::max() - 1)));
    EXPECT_FALSE(checker.ClaimHandle(Handle(0)));

    // Should still return true for invalid handle.
    EXPECT_TRUE(
        checker.ClaimHandle(Handle(internal::kEncodedInvalidHandleValue)));
  }
}

TEST(BoundsCheckerTest, ClaimMemory) {
  {
    internal::BoundsChecker checker(ToPtr(1000), 2000, 0);

    // Basics.
    EXPECT_FALSE(checker.ClaimMemory(ToPtr(500), 100));
    EXPECT_FALSE(checker.ClaimMemory(ToPtr(800), 300));
    EXPECT_TRUE(checker.ClaimMemory(ToPtr(1000), 100));
    EXPECT_FALSE(checker.ClaimMemory(ToPtr(1099), 100));
    EXPECT_TRUE(checker.ClaimMemory(ToPtr(1100), 200));
    EXPECT_FALSE(checker.ClaimMemory(ToPtr(2000), 1001));
    EXPECT_TRUE(checker.ClaimMemory(ToPtr(2000), 500));
    EXPECT_FALSE(checker.ClaimMemory(ToPtr(2000), 500));
    EXPECT_FALSE(checker.ClaimMemory(ToPtr(1400), 100));
    EXPECT_FALSE(checker.ClaimMemory(ToPtr(3000), 1));
    EXPECT_TRUE(checker.ClaimMemory(ToPtr(2500), 500));
  }

  {
    // No memory to claim.
    internal::BoundsChecker checker(ToPtr(10000), 0, 0);

    EXPECT_FALSE(checker.ClaimMemory(ToPtr(10000), 1));
    EXPECT_FALSE(checker.ClaimMemory(ToPtr(10000), 0));
  }

  {
    internal::BoundsChecker checker(
        ToPtr(std::numeric_limits<uintptr_t>::max() - 1000), 500, 0);

    // Test overflow.
    EXPECT_FALSE(checker.ClaimMemory(
        ToPtr(std::numeric_limits<uintptr_t>::max() - 750), 4000));
    EXPECT_FALSE(
        checker.ClaimMemory(ToPtr(std::numeric_limits<uintptr_t>::max() - 750),
                            std::numeric_limits<uint32_t>::max()));

    // This should be fine.
    EXPECT_TRUE(checker.ClaimMemory(
        ToPtr(std::numeric_limits<uintptr_t>::max() - 750), 200));
  }
}

}  // namespace
}  // namespace test
}  // namespace mojo
