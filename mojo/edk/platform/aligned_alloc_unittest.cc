// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/platform/aligned_alloc.h"

#include <stdint.h>
#include <string.h>

#include <array>

#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

#define EXPECT_ALIGNED(ptr, alignment) \
  EXPECT_EQ(0u, reinterpret_cast<uintptr_t>(ptr) % (alignment))

namespace mojo {
namespace platform {
namespace {

TEST(AlignedAllocTest, RawAlignedAlloc) {
  for (size_t alignment = sizeof(void*); alignment <= 4096u; alignment <<= 1u) {
    for (size_t size = 1u; size <= 256u; size <<= 1u) {
      SCOPED_TRACE(testing::Message() << "alignment = " << alignment
                                      << ", size = " << size);
      void* ptr = RawAlignedAlloc(alignment, size);
      EXPECT_TRUE(ptr);
      EXPECT_ALIGNED(ptr, alignment);
      // Check that we can actually write to this memory.
      memset(ptr, 123, size);
      RawAlignedFree(ptr);
    }

    // Check non-power-of-2 sizes.
    for (size_t size = 2u; size <= 64u; size++) {
      SCOPED_TRACE(testing::Message() << "alignment = " << alignment
                                      << ", size = " << size);
      void* ptr = RawAlignedAlloc(alignment, size);
      EXPECT_TRUE(ptr);
      EXPECT_ALIGNED(ptr, alignment);
      // Check that we can actually write to this memory.
      memset(ptr, 123, size);
      RawAlignedFree(ptr);
    }
  }
}

TEST(AlignedAllocTest, AlignedAlloc) {
  for (size_t alignment = sizeof(void*); alignment <= 4096u; alignment <<= 1u) {
    for (size_t n = 1u; n <= 16u; n++) {
      SCOPED_TRACE(testing::Message() << "alignment = " << alignment
                                      << ", n = " << n);

      if (alignment >= alignof(char)) {
        size_t size = n * sizeof(char);
        AlignedUniquePtr<char> ptr = AlignedAlloc<char>(alignment, size);
        EXPECT_ALIGNED(ptr.get(), alignment);
        memset(ptr.get(), 123, size);
      }

      if (alignment >= alignof(uint32_t)) {
        size_t size = n * sizeof(uint32_t);
        AlignedUniquePtr<uint32_t> ptr =
            AlignedAlloc<uint32_t>(alignment, size);
        EXPECT_ALIGNED(ptr.get(), alignment);
        memset(ptr.get(), 123, size);
      }

      if (alignment >= alignof(int64_t)) {
        size_t size = n * sizeof(int64_t);
        AlignedUniquePtr<int64_t> ptr = AlignedAlloc<int64_t>(alignment, size);
        EXPECT_ALIGNED(ptr.get(), alignment);
        memset(ptr.get(), 123, size);
      }

      if (alignment >= alignof(float)) {
        size_t size = n * sizeof(float);
        AlignedUniquePtr<float> ptr = AlignedAlloc<float>(alignment, size);
        EXPECT_ALIGNED(ptr.get(), alignment);
        memset(ptr.get(), 123, size);
      }

      if (alignment >= alignof(double)) {
        size_t size = n * sizeof(double);
        AlignedUniquePtr<double> ptr = AlignedAlloc<double>(alignment, size);
        EXPECT_ALIGNED(ptr.get(), alignment);
        memset(ptr.get(), 123, size);
      }
    }
  }
}

}  // namespace
}  // namespace platform
}  // namespace mojo
