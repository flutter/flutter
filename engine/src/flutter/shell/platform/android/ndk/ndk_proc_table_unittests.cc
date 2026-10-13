// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <android/api-level.h>

#include "flutter/fml/build_config.h"
#include "flutter/fml/native_library.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/shell/platform/android/ndk/choreographer.h"
#include "flutter/shell/platform/android/ndk/ndk_proc_table.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

// API levels that introduced the functions in NDKProcTable.
constexpr int kATraceApiLevel = 23;
constexpr int kChoreographerApiLevel = 24;
constexpr int kPostFrameCallback64ApiLevel = 29;
constexpr int kSurfaceTransactionFromJavaApiLevel = 34;

NDKProcTable LoadTable() {
  return NDKProcTable(fml::NativeLibrary::Create("libandroid.so"));
}

}  // namespace

TEST(NDKProcTableTest, ResolvesFunctionsForThisApiLevel) {
  const int api_level = android_get_device_api_level();
  NDKProcTable table = LoadTable();

  EXPECT_EQ(table.ATrace_isEnabled != nullptr, api_level >= kATraceApiLevel);
  EXPECT_EQ(table.AChoreographer_getInstance != nullptr,
            api_level >= kChoreographerApiLevel);
  EXPECT_EQ(table.AChoreographer_postFrameCallback64 != nullptr,
            api_level >= kPostFrameCallback64ApiLevel);
  EXPECT_EQ(table.ASurfaceTransaction_fromJava != nullptr,
            api_level >= kSurfaceTransactionFromJavaApiLevel);
}

TEST(NDKProcTableTest, UsesOnlyOneChoreographerPostFunction) {
  NDKProcTable table = LoadTable();

  if (table.AChoreographer_postFrameCallback64) {
    EXPECT_EQ(table.AChoreographer_postFrameCallback, nullptr);
  }
#if FML_ARCH_CPU_32_BITS
  // The `long` frame time overflows on 32-bit devices.
  EXPECT_EQ(table.AChoreographer_postFrameCallback, nullptr);
#endif  // FML_ARCH_CPU_32_BITS
}

TEST(NDKProcTableTest, WithoutLibraryEveryFunctionIsNull) {
  NDKProcTable table(nullptr);

  EXPECT_EQ(table.AChoreographer_getInstance, nullptr);
  EXPECT_EQ(table.AChoreographer_postFrameCallback, nullptr);
  EXPECT_EQ(table.AChoreographer_postFrameCallback64, nullptr);
  EXPECT_EQ(table.ASurfaceTransaction_fromJava, nullptr);
  EXPECT_EQ(table.ATrace_isEnabled, nullptr);
  EXPECT_FALSE(table.TraceIsEnabled());
}

TEST(NDKProcTableTest, TraceIsEnabledAsksATrace) {
  NDKProcTable table(nullptr);

  table.ATrace_isEnabled = []() { return true; };
  EXPECT_TRUE(table.TraceIsEnabled());

  table.ATrace_isEnabled = []() { return false; };
  EXPECT_FALSE(table.TraceIsEnabled());
}

TEST(NDKProcTableTest, ChoreographerIsAvailable) {
  if (!Choreographer::IsAvailableOnPlatform()) {
    GTEST_SKIP() << "Choreographer is not supported on this platform.";
  }
  ASSERT_TRUE(Choreographer::IsAvailableOnPlatform());
}

TEST(NDKProcTableTest, CanPostAndNotWaitForFrameCallbacks) {
  if (!Choreographer::IsAvailableOnPlatform()) {
    GTEST_SKIP() << "Choreographer is not supported on this platform.";
  }
  const auto& choreographer = Choreographer::GetInstance();
  ASSERT_TRUE(choreographer.IsValid());
  ASSERT_TRUE(choreographer.PostFrameCallback([](auto) {}));
}

TEST(NDKProcTableTest, CanPostAndWaitForFrameCallbacks) {
  if (!Choreographer::IsAvailableOnPlatform()) {
    GTEST_SKIP() << "Choreographer is not supported on this platform.";
  }
  if ((true)) {
    GTEST_SKIP()
        << "Disabled till the test harness is in an Android activity. "
           "Running it without one will hang because the choreographer "
           "frame callback will never execute.";
  }
  const auto& choreographer = Choreographer::GetInstance();
  ASSERT_TRUE(choreographer.IsValid());
  fml::AutoResetWaitableEvent event;
  ASSERT_TRUE(choreographer.PostFrameCallback(
      [&event](auto point) { event.Signal(); }));
  event.Wait();
}

}  // namespace testing
}  // namespace flutter
