// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/platform/darwin/cf_utils.h"
#include "flutter/testing/testing.h"

namespace fml {
namespace testing {

TEST(CFTest, CanCreateRefs) {
  CFRef<CFMutableStringRef> string(CFStringCreateMutable(kCFAllocatorDefault, 100u));
  // Cast
  ASSERT_TRUE(static_cast<bool>(string));
  ASSERT_TRUE(string);

  const auto ref_count = CFGetRetainCount(string);

  // Copy & Reset
  {
    CFRef<CFMutableStringRef> string2 = string;
    ASSERT_TRUE(string2);
    ASSERT_EQ(ref_count + 1u, CFGetRetainCount(string));
    ASSERT_EQ(CFGetRetainCount(string2), CFGetRetainCount(string));

    string2.Reset();
    ASSERT_FALSE(string2);
    ASSERT_EQ(ref_count, CFGetRetainCount(string));
  }

  // Release
  {
    auto string3 = string;
    ASSERT_TRUE(string3);
    ASSERT_EQ(ref_count + 1u, CFGetRetainCount(string));
    auto raw_string3 = string3.Release();
    ASSERT_FALSE(string3);
    ASSERT_EQ(ref_count + 1u, CFGetRetainCount(string));
    CFRelease(raw_string3);
    ASSERT_EQ(ref_count, CFGetRetainCount(string));
  }

  // Move
  {
    auto string_source = string;
    ASSERT_TRUE(string_source);
    auto string_move = std::move(string_source);
    ASSERT_FALSE(string_source);
    ASSERT_EQ(ref_count + 1u, CFGetRetainCount(string));
    string_move.Reset();
    ASSERT_EQ(ref_count, CFGetRetainCount(string));
  }

  // Move assign.
  {
    auto string_move_assign = std::move(string);
    ASSERT_FALSE(string);
    ASSERT_EQ(ref_count, CFGetRetainCount(string_move_assign));
  }
}

}  // namespace testing
}  // namespace fml
