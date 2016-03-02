// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/platform/random.h"

#include <string.h>

#include <algorithm>

#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace platform {
namespace {

TEST(RandomTest, GetCryptoRandomBytes) {
  static const size_t kBufferSize = 50;

  // Check that two calls to |GetCryptoRandomBytes()| yield different bytes.
  {
    char buffer[kBufferSize] = {};
    GetCryptoRandomBytes(buffer, kBufferSize);

    char buffer2[kBufferSize] = {};
    GetCryptoRandomBytes(buffer2, kBufferSize);

    EXPECT_FALSE(memcmp(buffer, buffer2, kBufferSize) == 0);
  }

  // Check that the bytes in |buffer| "look" random. The probability of having
  // fewer than 25 unique bytes in 50 random bytes is below 10^-25.
  {
    char buffer[kBufferSize] = {};
    GetCryptoRandomBytes(buffer, kBufferSize);
    std::sort(buffer, buffer + kBufferSize);
    EXPECT_GT(std::unique(buffer, buffer + kBufferSize) - buffer, 25);
  }

  // Do the same, but generating one byte at a time.
  {
    char buffer[kBufferSize] = {};
    for (size_t i = 0; i < kBufferSize; i++)
      GetCryptoRandomBytes(buffer + i, 1u);
    std::sort(buffer, buffer + kBufferSize);
    EXPECT_GT(std::unique(buffer, buffer + kBufferSize) - buffer, 25);
  }
}

}  // namespace
}  // namespace platform
}  // namespace mojo
