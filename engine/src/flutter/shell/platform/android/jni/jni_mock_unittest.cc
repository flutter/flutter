// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/jni/jni_mock.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(JNIMock, FlutterViewHandlePlatformMessage) {
  JNIMock mock;

  auto message = std::make_unique<PlatformMessage>("<channel-name>", nullptr);
  auto response_id = 1;

  EXPECT_CALL(mock,
              FlutterViewHandlePlatformMessage(
                  ::testing::Property(&std::unique_ptr<PlatformMessage>::get,
                                      message.get()),
                  response_id));

  mock.FlutterViewHandlePlatformMessage(std::move(message), response_id);
}

TEST(JNIMock, HybridJavaGlobalRefMoveOnlyAndStateTransitions) {
  constexpr intptr_t kFirstToken = 101;
  constexpr intptr_t kSecondToken = 202;

  HybridJavaGlobalRef empty_ref;
  EXPECT_TRUE(empty_ref.is_null());
  EXPECT_FALSE(static_cast<bool>(empty_ref));
  EXPECT_EQ(empty_ref.token(), 0);

  HybridJavaGlobalRef first = HybridJavaGlobalRef::ForTest(kFirstToken);
  EXPECT_FALSE(first.is_null());
  EXPECT_EQ(first.token(), kFirstToken);

  HybridJavaGlobalRef moved_ctor(std::move(first));
  // Explicitly verify the documented post-move nulled invariant on `first`.
  // NOLINTNEXTLINE(bugprone-use-after-move,clang-analyzer-cplusplus.Move)
  EXPECT_TRUE(first.is_null());
  // NOLINTNEXTLINE(bugprone-use-after-move,clang-analyzer-cplusplus.Move)
  EXPECT_EQ(first.token(), 0);
  EXPECT_EQ(moved_ctor.token(), kFirstToken);

  HybridJavaGlobalRef second = HybridJavaGlobalRef::ForTest(kSecondToken);
  second = std::move(moved_ctor);
  // NOLINTNEXTLINE(bugprone-use-after-move,clang-analyzer-cplusplus.Move)
  EXPECT_TRUE(moved_ctor.is_null());
  EXPECT_EQ(second.token(), kFirstToken);

  second.Reset();
  EXPECT_TRUE(second.is_null());

  HybridCompositionState state;
  EXPECT_FALSE(state.ShouldDeferRootSurface());
  state.hc_views_alive.store(true, std::memory_order_release);
  EXPECT_TRUE(state.ShouldDeferRootSurface());
  state.hc_views_alive.store(false, std::memory_order_release);
  state.hc_session_active.store(true, std::memory_order_release);
  EXPECT_TRUE(state.ShouldDeferRootSurface());
  state.hc_session_active.store(false, std::memory_order_release);
  EXPECT_FALSE(state.ShouldDeferRootSurface());
}

}  // namespace testing
}  // namespace flutter
