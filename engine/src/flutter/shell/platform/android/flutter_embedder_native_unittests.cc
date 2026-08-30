// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/flutter_embedder_native.h"
#include "gtest/gtest.h"

namespace flutter {
namespace android {
namespace testing {

TEST(FlutterEmbedderNativeTest, QuarantineEnforcement) {
  EXPECT_TRUE(FlutterEmbedderNative::IsQuarantineEnforced());
}

TEST(FlutterEmbedderNativeTest, VersionVerification) {
  EXPECT_TRUE(FlutterEmbedderNative::VerifyEmbedderVersion());
  EXPECT_EQ(FlutterEmbedderNative::GetEmbedderVersion(),
            static_cast<size_t>(FLUTTER_ENGINE_VERSION));
}

TEST(FlutterEmbedderNativeTest, LifecycleInstance) {
  auto native_instance = std::make_unique<FlutterEmbedderNative>();
  EXPECT_NE(native_instance, nullptr);
}

TEST(FlutterEmbedderNativeTest, NativeWindowManagement) {
  auto native_instance = std::make_unique<FlutterEmbedderNative>();
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  EXPECT_EQ(native_instance->GetNativeWindow(), nullptr);
#pragma clang diagnostic pop
  EXPECT_EQ(native_instance->AcquireNativeWindow(), nullptr);

  // PresentSoftware should fail cleanly when no window is attached.
  uint32_t dummy_pixels[16] = {0};
  EXPECT_FALSE(native_instance->PresentSoftware(dummy_pixels, 16, 4));

  // PresentSoftware should fail cleanly with invalid arguments.
  EXPECT_FALSE(native_instance->PresentSoftware(nullptr, 16, 4));
  EXPECT_FALSE(native_instance->PresentSoftware(dummy_pixels, 0, 4));
  EXPECT_FALSE(native_instance->PresentSoftware(dummy_pixels, 16, 0));
}

TEST(FlutterEmbedderNativeTest, BlitSoftwareRasterRgba8888Exact) {
  // 2x2 source pixels: Red, Green, Blue, White.
  const uint32_t src[4] = {
      0xFF0000FF,  // Red
      0xFF00FF00,  // Green
      0xFFFF0000,  // Blue
      0xFFFFFFFF,  // White
  };

  uint32_t dst[4] = {0};
  FlutterEmbedderNative::SoftwareBuffer dst_buffer;
  dst_buffer.bits = dst;
  dst_buffer.width = 2;
  dst_buffer.height = 2;
  dst_buffer.stride = 2;
  dst_buffer.format = FlutterEmbedderNative::kFormatRgba8888;

  EXPECT_TRUE(
      FlutterEmbedderNative::BlitSoftwareRaster(src, 2 * 4, 2, dst_buffer));
  EXPECT_EQ(dst[0], 0xFF0000FF);
  EXPECT_EQ(dst[1], 0xFF00FF00);
  EXPECT_EQ(dst[2], 0xFFFF0000);
  EXPECT_EQ(dst[3], 0xFFFFFFFF);
}

TEST(FlutterEmbedderNativeTest, BlitSoftwareRasterRgba8888StrideAndMargins) {
  // 2x2 source in a 4x3 destination buffer (stride = 4).
  const uint32_t src[4] = {
      0xFF111111,
      0xFF222222,
      0xFF333333,
      0xFF444444,
  };

  // Pre-fill destination with junk bytes to verify zeroing of margins.
  std::vector<uint32_t> dst(4 * 3, 0xAAAAAAAA);
  FlutterEmbedderNative::SoftwareBuffer dst_buffer;
  dst_buffer.bits = dst.data();
  dst_buffer.width = 4;
  dst_buffer.height = 3;
  dst_buffer.stride = 4;
  dst_buffer.format = FlutterEmbedderNative::kFormatRgba8888;

  EXPECT_TRUE(
      FlutterEmbedderNative::BlitSoftwareRaster(src, 2 * 4, 2, dst_buffer));

  // Row 0: 2 copied pixels, 2 zeroed margins
  EXPECT_EQ(dst[0], 0xFF111111);
  EXPECT_EQ(dst[1], 0xFF222222);
  EXPECT_EQ(dst[2], 0u);
  EXPECT_EQ(dst[3], 0u);

  // Row 1: 2 copied pixels, 2 zeroed margins
  EXPECT_EQ(dst[4], 0xFF333333);
  EXPECT_EQ(dst[5], 0xFF444444);
  EXPECT_EQ(dst[6], 0u);
  EXPECT_EQ(dst[7], 0u);

  // Row 2: Bottom extra row zeroed
  EXPECT_EQ(dst[8], 0u);
  EXPECT_EQ(dst[9], 0u);
  EXPECT_EQ(dst[10], 0u);
  EXPECT_EQ(dst[11], 0u);
}

TEST(FlutterEmbedderNativeTest, BlitSoftwareRasterRgb565ClampingAndUnpremul) {
  // Little-endian RGBA memory layout: byte0=R, byte1=G, byte2=B, byte3=A
  // Test case 1: Opaque red (R=255, G=0, B=0, A=255) -> 0xF800
  // Test case 2: Half-alpha red (R=128, G=0, B=0, A=128) -> un-premul R=255 ->
  // 0xF800 Test case 3: Out-of-bounds roundoff: (R=100, G=0, B=0, A=99) ->
  // (100*255)/99 = 257 -> clamped to 255 -> 0xF800 Test case 4: Fully
  // transparent (0, 0, 0, 0) -> 0x0000
  const uint8_t src_bytes[16] = {
      255, 0, 0, 255,  // px0
      128, 0, 0, 128,  // px1
      100, 0, 0, 99,   // px2
      0,   0, 0, 0,    // px3
  };

  uint16_t dst[4] = {0};
  FlutterEmbedderNative::SoftwareBuffer dst_buffer;
  dst_buffer.bits = dst;
  dst_buffer.width = 4;
  dst_buffer.height = 1;
  dst_buffer.stride = 4;
  dst_buffer.format = FlutterEmbedderNative::kFormatRgb565;

  EXPECT_TRUE(FlutterEmbedderNative::BlitSoftwareRaster(src_bytes, 4 * 4, 1,
                                                        dst_buffer));
  EXPECT_EQ(dst[0], 0xF800);
  EXPECT_EQ(dst[1], 0xF800);
  EXPECT_EQ(dst[2], 0xF800);  // Must NOT wrap around to near-zero!
  EXPECT_EQ(dst[3], 0x0000);
}

TEST(FlutterEmbedderNativeTest, BlitSoftwareRasterInvalidArguments) {
  uint32_t dummy[4] = {0};
  FlutterEmbedderNative::SoftwareBuffer valid_buf;
  valid_buf.bits = dummy;
  valid_buf.width = 2;
  valid_buf.height = 2;
  valid_buf.stride = 2;
  valid_buf.format = FlutterEmbedderNative::kFormatRgba8888;

  // Null or zero source
  EXPECT_FALSE(
      FlutterEmbedderNative::BlitSoftwareRaster(nullptr, 8, 2, valid_buf));
  EXPECT_FALSE(
      FlutterEmbedderNative::BlitSoftwareRaster(dummy, 0, 2, valid_buf));
  EXPECT_FALSE(
      FlutterEmbedderNative::BlitSoftwareRaster(dummy, 8, 0, valid_buf));

  // Null or invalid destination
  FlutterEmbedderNative::SoftwareBuffer invalid_buf = valid_buf;
  invalid_buf.bits = nullptr;
  EXPECT_FALSE(
      FlutterEmbedderNative::BlitSoftwareRaster(dummy, 8, 2, invalid_buf));

  // Stride < width underflow check
  invalid_buf = valid_buf;
  invalid_buf.stride = 1;  // less than width 2!
  EXPECT_FALSE(
      FlutterEmbedderNative::BlitSoftwareRaster(dummy, 8, 2, invalid_buf));

  // Invalid format
  invalid_buf = valid_buf;
  invalid_buf.format = 999;
  EXPECT_FALSE(
      FlutterEmbedderNative::BlitSoftwareRaster(dummy, 8, 2, invalid_buf));
}

TEST(FlutterEmbedderNativeTest, NativeWindowSelfAssignmentAndLifecycle) {
  auto native_instance = std::make_unique<FlutterEmbedderNative>();
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  EXPECT_EQ(native_instance->GetNativeWindow(), nullptr);
  EXPECT_EQ(native_instance->AcquireNativeWindow(), nullptr);

  // Self assignment of nullptr
  native_instance->SetNativeWindow(nullptr);
  EXPECT_EQ(native_instance->GetNativeWindow(), nullptr);
  EXPECT_EQ(native_instance->AcquireNativeWindow(), nullptr);

#if !defined(__ANDROID__)
  // On host, test pointer storage, self-assignment, and clearing
  auto fake_win = reinterpret_cast<ANativeWindow*>(0x1234);
  native_instance->SetNativeWindow(fake_win);
  EXPECT_EQ(native_instance->GetNativeWindow(), fake_win);

  // Self assignment must be a no-op and not crash
  native_instance->SetNativeWindow(fake_win);
  EXPECT_EQ(native_instance->GetNativeWindow(), fake_win);

  native_instance->SetNativeWindow(nullptr);
  EXPECT_EQ(native_instance->GetNativeWindow(), nullptr);
#endif
#pragma clang diagnostic pop
}

}  // namespace testing
}  // namespace android
}  // namespace flutter

int main(int argc, char* argv[]) {
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
