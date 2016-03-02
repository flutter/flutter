// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/platform/simple_platform_shared_buffer.h"

#include <limits>

#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace platform {
namespace {

TEST(SimplePlatformSharedBufferTest, Basic) {
  const size_t kNumInts = 100;
  const size_t kNumBytes = kNumInts * sizeof(int);
  // A fudge so that we're not just writing zero bytes 75% of the time.
  const int kFudge = 1234567890;

  // Make some memory.
  auto buffer = CreateSimplePlatformSharedBuffer(kNumBytes);
  ASSERT_TRUE(buffer);

  // Map it all, scribble some stuff, and then unmap it.
  {
    EXPECT_TRUE(buffer->IsValidMap(0, kNumBytes));
    std::unique_ptr<PlatformSharedBufferMapping> mapping(
        buffer->Map(0, kNumBytes));
    ASSERT_TRUE(mapping);
    ASSERT_TRUE(mapping->GetBase());
    int* stuff = static_cast<int*>(mapping->GetBase());
    for (size_t i = 0; i < kNumInts; i++)
      stuff[i] = static_cast<int>(i) + kFudge;
  }

  // Map it all again, check that our scribbling is still there, then do a
  // partial mapping and scribble on that, check that everything is coherent,
  // unmap the first mapping, scribble on some of the second mapping, and then
  // unmap it.
  {
    ASSERT_TRUE(buffer->IsValidMap(0, kNumBytes));
    // Use |MapNoCheck()| this time.
    std::unique_ptr<PlatformSharedBufferMapping> mapping1(
        buffer->MapNoCheck(0, kNumBytes));
    ASSERT_TRUE(mapping1);
    ASSERT_TRUE(mapping1->GetBase());
    int* stuff1 = static_cast<int*>(mapping1->GetBase());
    for (size_t i = 0; i < kNumInts; i++)
      EXPECT_EQ(static_cast<int>(i) + kFudge, stuff1[i]) << i;

    std::unique_ptr<PlatformSharedBufferMapping> mapping2(
        buffer->Map((kNumInts / 2) * sizeof(int), 2 * sizeof(int)));
    ASSERT_TRUE(mapping2);
    ASSERT_TRUE(mapping2->GetBase());
    int* stuff2 = static_cast<int*>(mapping2->GetBase());
    EXPECT_EQ(static_cast<int>(kNumInts / 2) + kFudge, stuff2[0]);
    EXPECT_EQ(static_cast<int>(kNumInts / 2) + 1 + kFudge, stuff2[1]);

    stuff2[0] = 123;
    stuff2[1] = 456;
    EXPECT_EQ(123, stuff1[kNumInts / 2]);
    EXPECT_EQ(456, stuff1[kNumInts / 2 + 1]);

    mapping1.reset();

    EXPECT_EQ(123, stuff2[0]);
    EXPECT_EQ(456, stuff2[1]);
    stuff2[1] = 789;
  }

  // Do another partial mapping and check that everything is the way we expect
  // it to be.
  {
    EXPECT_TRUE(buffer->IsValidMap(sizeof(int), kNumBytes - sizeof(int)));
    std::unique_ptr<PlatformSharedBufferMapping> mapping(
        buffer->Map(sizeof(int), kNumBytes - sizeof(int)));
    ASSERT_TRUE(mapping);
    ASSERT_TRUE(mapping->GetBase());
    int* stuff = static_cast<int*>(mapping->GetBase());

    for (size_t j = 0; j < kNumInts - 1; j++) {
      int i = static_cast<int>(j) + 1;
      if (i == kNumInts / 2) {
        EXPECT_EQ(123, stuff[j]);
      } else if (i == kNumInts / 2 + 1) {
        EXPECT_EQ(789, stuff[j]);
      } else {
        EXPECT_EQ(i + kFudge, stuff[j]) << i;
      }
    }
  }
}

// TODO(vtl): Bigger buffers.

TEST(SimplePlatformSharedBufferTest, InvalidMappings) {
  auto buffer = CreateSimplePlatformSharedBuffer(100);
  ASSERT_TRUE(buffer);

  // Zero length not allowed.
  EXPECT_FALSE(buffer->Map(0, 0));
  EXPECT_FALSE(buffer->IsValidMap(0, 0));

  // Okay:
  EXPECT_TRUE(buffer->Map(0, 100));
  EXPECT_TRUE(buffer->IsValidMap(0, 100));
  // Offset + length too big.
  EXPECT_FALSE(buffer->Map(0, 101));
  EXPECT_FALSE(buffer->IsValidMap(0, 101));
  EXPECT_FALSE(buffer->Map(1, 100));
  EXPECT_FALSE(buffer->IsValidMap(1, 100));

  // Okay:
  EXPECT_TRUE(buffer->Map(50, 50));
  EXPECT_TRUE(buffer->IsValidMap(50, 50));
  // Offset + length too big.
  EXPECT_FALSE(buffer->Map(50, 51));
  EXPECT_FALSE(buffer->IsValidMap(50, 51));
  EXPECT_FALSE(buffer->Map(51, 50));
  EXPECT_FALSE(buffer->IsValidMap(51, 50));
}

TEST(SimplePlatformSharedBufferTest, TooBig) {
  // If |size_t| is 32-bit, it's quite possible/likely that |Create()| succeeds
  // (since it only involves creating a 4 GB file).
  const size_t kMaxSizeT = std::numeric_limits<size_t>::max();
  auto buffer = CreateSimplePlatformSharedBuffer(kMaxSizeT);
  // But, assuming |sizeof(size_t) == sizeof(void*)|, mapping all of it should
  // always fail.
  if (buffer)
    EXPECT_FALSE(buffer->Map(0, kMaxSizeT));
}

// Tests that separate mappings get distinct addresses.
// Note: It's not inconceivable that the OS could ref-count identical mappings
// and reuse the same address, in which case we'd have to be more careful about
// using the address as the key for unmapping.
TEST(SimplePlatformSharedBufferTest, MappingsDistinct) {
  auto buffer = CreateSimplePlatformSharedBuffer(100);
  std::unique_ptr<PlatformSharedBufferMapping> mapping1(buffer->Map(0, 100));
  std::unique_ptr<PlatformSharedBufferMapping> mapping2(buffer->Map(0, 100));
  EXPECT_NE(mapping1->GetBase(), mapping2->GetBase());
}

TEST(SimplePlatformSharedBufferTest, BufferZeroInitialized) {
  static const size_t kSizes[] = {10, 100, 1000, 10000, 100000};
  for (size_t i = 0; i < MOJO_ARRAYSIZE(kSizes); i++) {
    auto buffer = CreateSimplePlatformSharedBuffer(kSizes[i]);
    std::unique_ptr<PlatformSharedBufferMapping> mapping(
        buffer->Map(0, kSizes[i]));
    for (size_t j = 0; j < kSizes[i]; j++) {
      // "Assert" instead of "expect" so we don't spam the output with thousands
      // of failures if we fail.
      ASSERT_EQ('\0', static_cast<char*>(mapping->GetBase())[j])
          << "size " << kSizes[i] << ", offset " << j;
    }
  }
}

TEST(SimplePlatformSharedBufferTest, MappingsOutliveBuffer) {
  std::unique_ptr<PlatformSharedBufferMapping> mapping1;
  std::unique_ptr<PlatformSharedBufferMapping> mapping2;

  {
    auto buffer = CreateSimplePlatformSharedBuffer(100);
    mapping1 = buffer->Map(0, 100);
    mapping2 = buffer->Map(50, 50);
    static_cast<char*>(mapping1->GetBase())[50] = 'x';
  }

  EXPECT_EQ('x', static_cast<char*>(mapping2->GetBase())[0]);

  static_cast<char*>(mapping2->GetBase())[1] = 'y';
  EXPECT_EQ('y', static_cast<char*>(mapping1->GetBase())[51]);
}

}  // namespace
}  // namespace platform
}  // namespace mojo
