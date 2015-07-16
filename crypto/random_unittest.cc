// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/random.h"

#include "base/strings/string_util.h"
#include "testing/gtest/include/gtest/gtest.h"

// Basic functionality tests. Does NOT test the security of the random data.

// Ensures we don't have all trivial data, i.e. that the data is indeed random.
// Currently, that means the bytes cannot be all the same (e.g. all zeros).
bool IsTrivial(const std::string& bytes) {
  for (size_t i = 0; i < bytes.size(); i++) {
    if (bytes[i] != bytes[0]) {
      return false;
    }
  }
  return true;
}

TEST(RandBytes, RandBytes) {
  std::string bytes(16, '\0');
  crypto::RandBytes(WriteInto(&bytes, bytes.size()), bytes.size());
  EXPECT_TRUE(!IsTrivial(bytes));
}
