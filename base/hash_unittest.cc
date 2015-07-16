// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/hash.h"

#include <string>
#include <vector>

#include "testing/gtest/include/gtest/gtest.h"

namespace base {

TEST(HashTest, String) {
  std::string str;
  // Empty string (should hash to 0).
  str = "";
  EXPECT_EQ(0u, Hash(str));

  // Simple test.
  str = "hello world";
  EXPECT_EQ(2794219650u, Hash(str));

  // Change one bit.
  str = "helmo world";
  EXPECT_EQ(1006697176u, Hash(str));

  // Insert a null byte.
  str = "hello  world";
  str[5] = '\0';
  EXPECT_EQ(2319902537u, Hash(str));

  // Test that the bytes after the null contribute to the hash.
  str = "hello  worle";
  str[5] = '\0';
  EXPECT_EQ(553904462u, Hash(str));

  // Extremely long string.
  // Also tests strings with high bit set, and null byte.
  std::vector<char> long_string_buffer;
  for (int i = 0; i < 4096; ++i)
    long_string_buffer.push_back((i % 256) - 128);
  str.assign(&long_string_buffer.front(), long_string_buffer.size());
  EXPECT_EQ(2797962408u, Hash(str));

  // All possible lengths (mod 4). Tests separate code paths. Also test with
  // final byte high bit set (regression test for http://crbug.com/90659).
  // Note that the 1 and 3 cases have a weird bug where the final byte is
  // treated as a signed char. It was decided on the above bug discussion to
  // enshrine that behaviour as "correct" to avoid invalidating existing hashes.

  // Length mod 4 == 0.
  str = "hello w\xab";
  EXPECT_EQ(615571198u, Hash(str));
  // Length mod 4 == 1.
  str = "hello wo\xab";
  EXPECT_EQ(623474296u, Hash(str));
  // Length mod 4 == 2.
  str = "hello wor\xab";
  EXPECT_EQ(4278562408u, Hash(str));
  // Length mod 4 == 3.
  str = "hello worl\xab";
  EXPECT_EQ(3224633008u, Hash(str));
}

TEST(HashTest, CString) {
  const char* str;
  // Empty string (should hash to 0).
  str = "";
  EXPECT_EQ(0u, Hash(str, strlen(str)));

  // Simple test.
  str = "hello world";
  EXPECT_EQ(2794219650u, Hash(str, strlen(str)));

  // Ensure that it stops reading after the given length, and does not expect a
  // null byte.
  str = "hello world; don't read this part";
  EXPECT_EQ(2794219650u, Hash(str, strlen("hello world")));
}

}  // namespace base
