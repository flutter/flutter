// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cstring>
#include <limits>

#include "flutter/testing/testing.h"
#include "impeller/base/allocation.h"

namespace impeller {
namespace testing {

TEST(AllocationTest, ReserveNPOTPotentialOverflow) {
  std::vector<uint8_t> data(64, 0xff);

  auto allocate_and_write = [&](uint64_t size) {
    Allocation allocation;

    // Allocate a buffer with the size rounded up to the next power of two.
    if (!allocation.Truncate(Bytes{size})) {
      // Not enough memory available.
      return;
    }

    // If the allocation succeeded, then check that writes are safe.
    memcpy(allocation.GetBuffer(), data.data(), data.size());
    EXPECT_EQ(memcmp(allocation.GetBuffer(), data.data(), data.size()), 0);
  };

  // Try allocations with sizes around the maximum 32-bit value.
  allocate_and_write((1ULL << 32) + 1);
  allocate_and_write((1ULL << 32) - 1);
}

TEST(AllocationTest, NextPowerOfTwoSize) {
  EXPECT_EQ(*Allocation::NextPowerOfTwoSize((1ULL << 32) - 1), 1ULL << 32);
  EXPECT_EQ(*Allocation::NextPowerOfTwoSize((1ULL << 32) + 1), 1ULL << 33);
  EXPECT_EQ(*Allocation::NextPowerOfTwoSize(1ULL << 63), 1ULL << 63);
  EXPECT_EQ(Allocation::NextPowerOfTwoSize((1ULL << 63) + 1).status().code(),
            absl::StatusCode::kInvalidArgument);
  EXPECT_EQ(Allocation::NextPowerOfTwoSize(std::numeric_limits<uint64_t>::max())
                .status()
                .code(),
            absl::StatusCode::kInvalidArgument);
}

}  // namespace testing
}  // namespace impeller
