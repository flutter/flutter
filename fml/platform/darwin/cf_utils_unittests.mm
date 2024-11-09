// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/platform/darwin/cf_utils.h"

#include "flutter/testing/testing.h"

namespace fml {

// Template specialization used in CFTest.SupportsCustomRetainRelease.
template <>
struct CFRefTraits<int64_t> {
  static bool retain_called;
  static bool release_called;

  static constexpr int64_t kNullValue = 0;
  static void Retain(int64_t instance) { retain_called = true; }
  static void Release(int64_t instance) { release_called = true; }
};
bool CFRefTraits<int64_t>::retain_called = false;
bool CFRefTraits<int64_t>::release_called = false;

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
    ASSERT_FALSE(string_source);  // NOLINT(bugprone-use-after-move)
    ASSERT_EQ(ref_count + 1u, CFGetRetainCount(string));
    string_move.Reset();
    ASSERT_EQ(ref_count, CFGetRetainCount(string));
  }

  // Move assign.
  {
    auto string_move_assign = std::move(string);
    ASSERT_FALSE(string);  // NOLINT(bugprone-use-after-move)
    ASSERT_EQ(ref_count, CFGetRetainCount(string_move_assign));
  }
}

TEST(CFTest, GetReturnsUnderlyingObject) {
  CFMutableStringRef cf_string = CFStringCreateMutable(kCFAllocatorDefault, 100u);
  const CFIndex ref_count_before = CFGetRetainCount(cf_string);
  CFRef<CFMutableStringRef> string_ref(cf_string);

  CFMutableStringRef returned_string = string_ref.Get();
  const CFIndex ref_count_after = CFGetRetainCount(cf_string);
  EXPECT_EQ(cf_string, returned_string);
  EXPECT_EQ(ref_count_before, ref_count_after);
}

TEST(CFTest, RetainSharesOwnership) {
  CFMutableStringRef cf_string = CFStringCreateMutable(kCFAllocatorDefault, 100u);
  const CFIndex ref_count_before = CFGetRetainCount(cf_string);

  CFRef<CFMutableStringRef> string_ref;
  string_ref.Retain(cf_string);
  const CFIndex ref_count_after = CFGetRetainCount(cf_string);

  EXPECT_EQ(cf_string, string_ref);
  EXPECT_EQ(ref_count_before + 1u, ref_count_after);
}

TEST(CFTest, SupportsCustomRetainRelease) {
  CFRef<int64_t> ref(1);
  ASSERT_EQ(ref.Get(), 1);
  ASSERT_FALSE(CFRefTraits<int64_t>::retain_called);
  ASSERT_FALSE(CFRefTraits<int64_t>::release_called);
  ref.Reset();
  ASSERT_EQ(ref.Get(), 0);
  ASSERT_TRUE(CFRefTraits<int64_t>::release_called);
  ref.Retain(2);
  ASSERT_EQ(ref.Get(), 2);
  ASSERT_TRUE(CFRefTraits<int64_t>::retain_called);
  CFRefTraits<int64_t>::retain_called = false;
  CFRefTraits<int64_t>::release_called = false;
}

}  // namespace testing
}  // namespace fml
