// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/flutter_embedder_native.h"
#include "flutter/shell/platform/android/jni_delegate.h"
#include "flutter/shell/platform/android/jni_router.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace android {
namespace testing {

using ::testing::_;
using ::testing::DoAll;
using ::testing::Eq;
using ::testing::Return;
using ::testing::SetArgPointee;
using ::testing::StrictMock;

class MockJvmInvoker : public JvmInvoker {
 public:
  MOCK_METHOD(bool, EnsureAttachedToThread, (), (override));
  MOCK_METHOD(void, DetachFromThread, (), (override));
  MOCK_METHOD(bool, HasPendingException, (), (const, override));
  MOCK_METHOD(void, ClearPendingException, (), (override));

  MOCK_METHOD(bool,
              HandlePlatformMessage,
              (const std::string& channel,
               const uint8_t* message,
               size_t message_size,
               int32_t response_id,
               int64_t message_data),
              (override));

  MOCK_METHOD(bool,
              HandlePlatformMessageResponse,
              (int32_t response_id, const uint8_t* data, size_t data_size),
              (override));

  MOCK_METHOD(bool,
              UpdateSemantics,
              (const std::vector<uint8_t>& buffer,
               const std::vector<std::string>& strings,
               const std::vector<std::vector<uint8_t>>& string_attribute_args),
              (override));

  MOCK_METHOD(bool, SetSemanticsTreeEnabled, (bool enabled), (override));
  MOCK_METHOD(bool,
              SetApplicationLocale,
              (const std::string& locale),
              (override));
  MOCK_METHOD(bool, OnFirstFrame, (), (override));
  MOCK_METHOD(bool, OnPreEngineRestart, (), (override));
  MOCK_METHOD(bool,
              RequestDartDeferredLibrary,
              (int loading_unit_id),
              (override));

  MOCK_METHOD(bool,
              InvokeVoidMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(bool,
              InvokeBooleanMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(int64_t,
              InvokeIntMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(double,
              InvokeDoubleMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(std::string,
              InvokeStringMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(std::vector<uint8_t>,
              InvokeBytesMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(bool, PostJvmTask, (std::function<void()> task), (override));
};

class MockLegacyJniDelegate : public LegacyJniDelegate {
 public:
  MOCK_METHOD(bool,
              HandlePlatformMessage,
              (const std::string& channel,
               const uint8_t* message,
               size_t message_size,
               int32_t response_id,
               int64_t message_data),
              (override));

  MOCK_METHOD(bool,
              HandlePlatformMessageResponse,
              (int32_t response_id, const uint8_t* data, size_t data_size),
              (override));

  MOCK_METHOD(bool,
              UpdateSemantics,
              (const std::vector<uint8_t>& buffer,
               const std::vector<std::string>& strings,
               const std::vector<std::vector<uint8_t>>& string_attribute_args),
              (override));

  MOCK_METHOD(bool, SetSemanticsTreeEnabled, (bool enabled), (override));

  MOCK_METHOD(bool,
              SetApplicationLocale,
              (const std::string& locale),
              (override));

  MOCK_METHOD(bool, OnFirstFrame, (), (override));

  MOCK_METHOD(bool, OnPreEngineRestart, (), (override));

  MOCK_METHOD(bool,
              RequestDartDeferredLibrary,
              (int loading_unit_id),
              (override));
};

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
  EXPECT_NE(native_instance->GetRouter(), nullptr);
  EXPECT_NE(native_instance->GetJniDelegate(), nullptr);
  EXPECT_NE(native_instance->GetJvmInvoker(), nullptr);
}

TEST(FlutterEmbedderNativeTest, DefaultJvmInvokerOperations) {
  auto invoker = std::make_shared<DefaultJvmInvoker>();
  EXPECT_TRUE(invoker->EnsureAttachedToThread());
  EXPECT_FALSE(invoker->HasPendingException());

  std::vector<uint8_t> payload = {1, 2, 3};
  EXPECT_TRUE(invoker->InvokeVoidMethod("testVoid", "()V", payload));
  EXPECT_TRUE(invoker->InvokeBooleanMethod("testBool", "()Z"));
  EXPECT_EQ(invoker->InvokeIntMethod("testInt", "()I"), 0);
  EXPECT_DOUBLE_EQ(invoker->InvokeDoubleMethod("testDouble", "()D"), 0.0);
  EXPECT_EQ(invoker->InvokeStringMethod("testString", "()Ljava/lang/String;"),
            "");
  EXPECT_TRUE(invoker->InvokeBytesMethod("testBytes", "()[B").empty());

  // PostJvmTask fails safely when no task runner is configured.
  bool task_executed = false;
  EXPECT_FALSE(
      invoker->PostJvmTask([&task_executed]() { task_executed = true; }));
  EXPECT_FALSE(task_executed);

  invoker->DetachFromThread();
}

TEST(FlutterEmbedderNativeTest, JniDelegateWithMockInvoker) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto delegate = std::make_unique<JniDelegate>(mock_invoker);

  EXPECT_EQ(delegate->GetJvmInvoker(), mock_invoker);

  // 1. HandlePlatformMessage (preserves all typed parameters)
  std::vector<uint8_t> msg = {'h', 'e', 'l', 'l', 'o'};
  EXPECT_CALL(*mock_invoker, HandlePlatformMessage("flutter/test", msg.data(),
                                                   msg.size(), 42, 1001L))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->HandlePlatformMessage("flutter/test", msg, 42, 1001L));

  // 2. HandlePlatformMessageResponse
  std::vector<uint8_t> resp = {'o', 'k'};
  EXPECT_CALL(*mock_invoker,
              HandlePlatformMessageResponse(42, resp.data(), resp.size()))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->HandlePlatformMessageResponse(42, resp));

  // 3. UpdateSemantics
  std::vector<uint8_t> semantics_buffer = {0x01, 0x02};
  std::vector<std::string> semantics_strings = {"label1", "label2"};
  std::vector<std::vector<uint8_t>> string_attributes = {{0xAA}};
  EXPECT_CALL(
      *mock_invoker,
      UpdateSemantics(semantics_buffer, semantics_strings, string_attributes))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->UpdateSemantics(semantics_buffer, semantics_strings,
                                        string_attributes));

  // 4. SetSemanticsTreeEnabled
  EXPECT_CALL(*mock_invoker, SetSemanticsTreeEnabled(true))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->SetSemanticsTreeEnabled(true));

  // 5. SetApplicationLocale
  std::string locale = "en_US";
  EXPECT_CALL(*mock_invoker, SetApplicationLocale(locale))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->SetApplicationLocale(locale));

  // 6. OnFirstFrame
  EXPECT_CALL(*mock_invoker, OnFirstFrame()).WillOnce(Return(true));
  EXPECT_TRUE(delegate->OnFirstFrame());

  // 7. OnPreEngineRestart
  EXPECT_CALL(*mock_invoker, OnPreEngineRestart()).WillOnce(Return(true));
  EXPECT_TRUE(delegate->OnPreEngineRestart());

  // 8. RequestDartDeferredLibrary
  EXPECT_CALL(*mock_invoker, RequestDartDeferredLibrary(101))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->RequestDartDeferredLibrary(101));
}

TEST(FlutterEmbedderNativeTest, JniRouterRoutingFlip) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto embedder_delegate = std::make_shared<JniDelegate>(mock_invoker);
  auto legacy_delegate = std::make_shared<MockLegacyJniDelegate>();

  auto router = std::make_unique<JniRouter>(embedder_delegate, legacy_delegate);

  // Initial state: Embedder disabled globally -> routes to Legacy
  JniRouter::SetGlobalEmbedderEnabled(false);
  EXPECT_FALSE(JniRouter::IsEmbedderEnabled());
  EXPECT_EQ(router->GetActiveRoutingPath(), JniRouter::RoutingPath::kLegacy);

  std::vector<uint8_t> payload = {'t', 'e', 's', 't'};

  // Expect legacy delegate call, mock_invoker should not be called
  EXPECT_CALL(*legacy_delegate,
              HandlePlatformMessage("flutter/lifecycle", payload.data(),
                                    payload.size(), 1, 0))
      .WillOnce(Return(true));
  EXPECT_CALL(*mock_invoker, HandlePlatformMessage(_, _, _, _, _)).Times(0);

  EXPECT_TRUE(router->RoutePlatformMessage("flutter/lifecycle", payload, 1));

  // Legacy OnFirstFrame
  EXPECT_CALL(*legacy_delegate, OnFirstFrame()).WillOnce(Return(true));
  EXPECT_TRUE(router->RouteFirstFrame());

  // Legacy Deferred Library
  EXPECT_CALL(*legacy_delegate, RequestDartDeferredLibrary(5))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteRequestDartDeferredLibrary(5));

  // Flip global flag to true -> routes to Embedder
  JniRouter::SetGlobalEmbedderEnabled(true);
  EXPECT_TRUE(JniRouter::IsEmbedderEnabled());
  EXPECT_EQ(router->GetActiveRoutingPath(), JniRouter::RoutingPath::kEmbedder);

  // Expect mock_invoker call via embedder delegate, legacy should not be called
  EXPECT_CALL(*legacy_delegate, HandlePlatformMessage(_, _, _, _, _)).Times(0);
  EXPECT_CALL(*mock_invoker,
              HandlePlatformMessage("flutter/lifecycle", payload.data(),
                                    payload.size(), 1, 0))
      .WillOnce(Return(true));

  EXPECT_TRUE(router->RoutePlatformMessage("flutter/lifecycle", payload, 1));

  // Embedder OnFirstFrame
  EXPECT_CALL(*mock_invoker, OnFirstFrame()).WillOnce(Return(true));
  EXPECT_TRUE(router->RouteFirstFrame());

  // Embedder Deferred Library
  EXPECT_CALL(*mock_invoker, RequestDartDeferredLibrary(5))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteRequestDartDeferredLibrary(5));

  // Instance override: override global true with instance false
  router->SetInstanceEmbedderEnabled(false);
  EXPECT_FALSE(router->IsInstanceEmbedderEnabled());
  EXPECT_EQ(router->GetActiveRoutingPath(), JniRouter::RoutingPath::kLegacy);

  EXPECT_CALL(*legacy_delegate, OnFirstFrame()).WillOnce(Return(true));
  EXPECT_TRUE(router->RouteFirstFrame());

  // Reset instance override
  router->SetInstanceEmbedderEnabled(std::nullopt);
  EXPECT_TRUE(router->IsInstanceEmbedderEnabled());

  // Reset global flag back to false for test hygiene
  JniRouter::SetGlobalEmbedderEnabled(false);
  EXPECT_FALSE(JniRouter::IsEmbedderEnabled());
}

TEST(FlutterEmbedderNativeTest, DynamicInstanceRouterWithCustomInvoker) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto legacy_delegate = std::make_shared<MockLegacyJniDelegate>();

  FlutterEmbedderNative native(mock_invoker, legacy_delegate);
  EXPECT_EQ(native.GetJvmInvoker(), mock_invoker);
  EXPECT_NE(native.GetJniDelegate(), nullptr);
  EXPECT_NE(native.GetRouter(), nullptr);

  FlutterEmbedderNative::SetEmbedderEnabled(true);
  EXPECT_TRUE(FlutterEmbedderNative::IsEmbedderEnabled());

  EXPECT_CALL(*mock_invoker, OnFirstFrame()).WillOnce(Return(true));
  EXPECT_TRUE(native.GetRouter()->RouteFirstFrame());

  FlutterEmbedderNative::SetEmbedderEnabled(false);
  EXPECT_FALSE(FlutterEmbedderNative::IsEmbedderEnabled());
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
