// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <limits>

#include "mojo/public/cpp/bindings/lib/bindings_serialization.h"
#include "mojo/public/cpp/bindings/lib/fixed_buffer.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace test {
namespace {

bool IsZero(void* p_buf, size_t size) {
  char* buf = reinterpret_cast<char*>(p_buf);
  for (size_t i = 0; i < size; ++i) {
    if (buf[i] != 0)
      return false;
  }
  return true;
}

// Tests that FixedBuffer allocates memory aligned to 8 byte boundaries.
TEST(FixedBufferTest, Alignment) {
  internal::FixedBuffer buf(internal::Align(10) * 2);
  ASSERT_EQ(buf.size(), 16u * 2);

  void* a = buf.Allocate(10);
  ASSERT_TRUE(a);
  EXPECT_TRUE(IsZero(a, 10));
  EXPECT_EQ(0, reinterpret_cast<ptrdiff_t>(a) % 8);

  void* b = buf.Allocate(10);
  ASSERT_TRUE(b);
  EXPECT_TRUE(IsZero(b, 10));
  EXPECT_EQ(0, reinterpret_cast<ptrdiff_t>(b) % 8);

  // Any more allocations would result in an assert, but we can't test that.
}

// Tests that FixedBuffer::Leak passes ownership to the caller.
TEST(FixedBufferTest, Leak) {
  void* ptr = nullptr;
  void* buf_ptr = nullptr;
  {
    internal::FixedBuffer buf(8);
    ASSERT_EQ(8u, buf.size());

    ptr = buf.Allocate(8);
    ASSERT_TRUE(ptr);
    buf_ptr = buf.Leak();

    // The buffer should point to the first element allocated.
    // TODO(mpcomplete): Is this a reasonable expectation?
    EXPECT_EQ(ptr, buf_ptr);

    // The FixedBuffer should be empty now.
    EXPECT_EQ(0u, buf.size());
    EXPECT_FALSE(buf.Leak());
  }

  // Since we called Leak, ptr is still writable after FixedBuffer went out of
  // scope.
  memset(ptr, 1, 8);
  free(buf_ptr);
}

#if defined(NDEBUG) && !defined(DCHECK_ALWAYS_ON)
TEST(FixedBufferTest, TooBig) {
  internal::FixedBuffer buf(24);

  // A little bit too large.
  EXPECT_EQ(reinterpret_cast<void*>(0), buf.Allocate(32));

  // Move the cursor forward.
  EXPECT_NE(reinterpret_cast<void*>(0), buf.Allocate(16));

  // A lot too large.
  EXPECT_EQ(reinterpret_cast<void*>(0),
            buf.Allocate(std::numeric_limits<size_t>::max() - 1024u));

  // A lot too large, leading to possible integer overflow.
  EXPECT_EQ(reinterpret_cast<void*>(0),
            buf.Allocate(std::numeric_limits<size_t>::max() - 8u));
}
#endif

}  // namespace
}  // namespace test
}  // namespace mojo
