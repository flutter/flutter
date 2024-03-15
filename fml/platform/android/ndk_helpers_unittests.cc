// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fml/message_loop.h"
#include "fml/platform/android/ndk_helpers.h"

#include "gtest/gtest.h"

namespace flutter {
namespace testing {
namespace android {

class NdkHelpersTest : public ::testing::Test {
 public:
  void SetUp() override { NDKHelpers::Init(); }

  static void OnVsync(int64_t frame_nanos, void* data) {}
  static void OnVsync32(
      long frame_nanos,  // NOLINT - compat for deprecated call
      void* data) {}
};

TEST_F(NdkHelpersTest, ATrace) {
  ASSERT_GT(android_get_device_api_level(), 22);
  EXPECT_FALSE(NDKHelpers::ATrace_isEnabled());
}

#if FML_ARCH_CPU_64_BITS
TEST_F(NdkHelpersTest, AChoreographer32) {
  if (android_get_device_api_level() >= 29) {
    GTEST_SKIP() << "This test is for less than API 29.";
  }

  EXPECT_EQ(NDKHelpers::ChoreographerSupported(),
            ChoreographerSupportStatus::kSupported32);

  EXPECT_FALSE(NDKHelpers::AChoreographer_getInstance());

  fml::MessageLoop::EnsureInitializedForCurrentThread();

  EXPECT_TRUE(NDKHelpers::AChoreographer_getInstance());

  NDKHelpers::AChoreographer_postFrameCallback(
      NDKHelpers::AChoreographer_getInstance(), &OnVsync32, nullptr);
}
#else
TEST_F(NdkHelpersTest, AChoreographer32NotSupported) {
  if (android_get_device_api_level() >= 29) {
    GTEST_SKIP() << "This test is for less than API 29.";
  }

  // The 32 bit framecallback on 32 bit architectures does not deliver
  // sufficient resolution. See
  // https://github.com/flutter/engine/pull/31859#discussion_r822072987
  EXPECT_EQ(NDKHelpers::ChoreographerSupported(),
            ChoreographerSupportStatus::kUnsupported);
}
#endif  // FML_ARCH_CPU_64_BITS

TEST_F(NdkHelpersTest, AChoreographer64) {
  if (android_get_device_api_level() < 29) {
    GTEST_SKIP() << "This test is for API 29 and above.";
  }

  EXPECT_EQ(NDKHelpers::ChoreographerSupported(),
            ChoreographerSupportStatus::kSupported64);

  EXPECT_FALSE(NDKHelpers::AChoreographer_getInstance());

  fml::MessageLoop::EnsureInitializedForCurrentThread();

  EXPECT_TRUE(NDKHelpers::AChoreographer_getInstance());

  NDKHelpers::AChoreographer_postFrameCallback64(
      NDKHelpers::AChoreographer_getInstance(), &OnVsync, nullptr);
}

TEST_F(NdkHelpersTest, HardwareBuffer) {
  if (android_get_device_api_level() < 26) {
    GTEST_SKIP() << "Test requires at least API 26.";
  }

  ASSERT_TRUE(NDKHelpers::HardwareBufferSupported());

  AHardwareBuffer_Desc desc{
      .width = 4,
      .height = 4,
      .layers = 1,
      .format = AHardwareBuffer_Format::AHARDWAREBUFFER_FORMAT_R8G8B8A8_UNORM,
  };
  if (android_get_device_api_level() >= 29) {
    EXPECT_TRUE(NDKHelpers::AHardwareBuffer_isSupported(&desc));
  }

  AHardwareBuffer* buffer = nullptr;
  // AHardwareBuffer_allocate returns 0 on success.
  EXPECT_EQ(NDKHelpers::AHardwareBuffer_allocate(&desc, &buffer), 0);
  EXPECT_TRUE(buffer);

  AHardwareBuffer_Desc out_desc = {};
  NDKHelpers::AHardwareBuffer_describe(buffer, &out_desc);
  EXPECT_EQ(desc.width, out_desc.width);
  EXPECT_EQ(desc.height, out_desc.height);
  EXPECT_EQ(desc.layers, out_desc.layers);
  EXPECT_EQ(desc.format, out_desc.format);

  auto id = NDKHelpers::AHardwareBuffer_getId(buffer);
  if (android_get_device_api_level() >= 31) {
    EXPECT_TRUE(id.has_value());
  } else {
    EXPECT_FALSE(id.has_value());
  }

  NDKHelpers::AHardwareBuffer_release(buffer);
}

TEST_F(NdkHelpersTest, SurfaceTransaction) {
  if (android_get_device_api_level() < 29) {
    GTEST_SKIP() << "Test requires at least API 29.";
  }
  EXPECT_TRUE(NDKHelpers::SurfaceControlAndTransactionSupported());

  // Need ANativeWindow to create ASurfaceControl and set a buffer to the
  // transaction. Just create/apply/delete as a smoke test.

  ASurfaceTransaction* transaction = NDKHelpers::ASurfaceTransaction_create();
  EXPECT_TRUE(transaction);
  NDKHelpers::ASurfaceTransaction_apply(transaction);
  NDKHelpers::ASurfaceTransaction_delete(transaction);
}

}  // namespace android
}  // namespace testing
}  // namespace flutter
