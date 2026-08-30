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
               const std::vector<uint8_t>& message,
               int32_t response_id),
              (override));

  MOCK_METHOD(bool,
              HandlePlatformMessageResponse,
              (int32_t response_id, const std::vector<uint8_t>& data),
              (override));

  MOCK_METHOD(bool,
              UpdateSemantics,
              (const std::vector<uint8_t>& buffer,
               const std::vector<std::string>& strings),
              (override));

  MOCK_METHOD(bool, SetSemanticsEnabled, (bool enabled), (override));

  MOCK_METHOD(bool,
              SetApplicationLocale,
              (const std::string& locale),
              (override));

  MOCK_METHOD(bool, OnFirstFrame, (), (override));

  MOCK_METHOD(bool, OnPreEngineRestart, (), (override));

  MOCK_METHOD(bool,
              OnVsync,
              (int64_t frame_time_nanos, int64_t frame_target_time_nanos),
              (override));

  MOCK_METHOD(
      bool,
      DispatchViewportMetrics,
      (int64_t view_id, double width, double height, double pixel_ratio),
      (override));

  MOCK_METHOD(bool,
              RequestDartDeferredLibrary,
              (int64_t loading_unit_id),
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

  bool task_executed = false;
  EXPECT_TRUE(
      invoker->PostJvmTask([&task_executed]() { task_executed = true; }));
  EXPECT_TRUE(task_executed);

  invoker->DetachFromThread();
}

TEST(FlutterEmbedderNativeTest, JniDelegateWithMockInvoker) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto delegate = std::make_unique<JniDelegate>(mock_invoker);

  EXPECT_EQ(delegate->GetJvmInvoker(), mock_invoker);

  // 1. HandlePlatformMessage
  std::vector<uint8_t> msg = {'h', 'e', 'l', 'l', 'o'};
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("handlePlatformMessage",
                                              "(Ljava/lang/String;[BI)V", msg))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->HandlePlatformMessage("flutter/test", msg, 42));

  // 2. HandlePlatformMessageResponse
  std::vector<uint8_t> resp = {'o', 'k'};
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("handlePlatformMessageResponse", "(I[B)V", resp))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->HandlePlatformMessageResponse(42, resp));

  // 3. UpdateSemantics
  std::vector<uint8_t> semantics_buffer = {0x01, 0x02};
  std::vector<std::string> semantics_strings = {"label1", "label2"};
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("updateSemantics", "([B[Ljava/lang/String;)V",
                               semantics_buffer))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->UpdateSemantics(semantics_buffer, semantics_strings));

  // 4. SetSemanticsEnabled
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("setSemanticsEnabled", "(Z)V",
                                              std::vector<uint8_t>{1}))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->SetSemanticsEnabled(true));

  // 5. SetApplicationLocale
  std::string locale = "en_US";
  std::vector<uint8_t> locale_payload(locale.begin(), locale.end());
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("setApplicationLocale", "(Ljava/lang/String;)V",
                               locale_payload))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->SetApplicationLocale(locale));

  // 6. OnFirstFrame
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("onFirstFrame", "()V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->OnFirstFrame());

  // 7. OnPreEngineRestart
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("onPreEngineRestart", "()V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->OnPreEngineRestart());

  // 8. OnVsync
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("onVsync", "(JJ)V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->OnVsync(1000000L, 2000000L));

  // 9. DispatchViewportMetrics
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("onViewportMetrics", "(IDDD)V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->DispatchViewportMetrics(0, 1080.0, 1920.0, 2.5));

  // 10. RequestDartDeferredLibrary
  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("requestDartDeferredLibrary", "(I)Z", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->RequestDartDeferredLibrary(101));
}

TEST(FlutterEmbedderNativeTest, JniRouterRoutingFlip) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto embedder_delegate = std::make_shared<JniDelegate>(mock_invoker);
  auto legacy_delegate = std::make_shared<MockLegacyJniDelegate>();

  auto router = std::make_unique<JniRouter>(embedder_delegate, legacy_delegate);

  // Initial state: Embedder disabled -> routes to Legacy
  JniRouter::SetEmbedderEnabled(false);
  EXPECT_FALSE(JniRouter::IsEmbedderEnabled());
  EXPECT_EQ(router->GetActiveRoutingPath(), JniRouter::RoutingPath::kLegacy);

  std::vector<uint8_t> payload = {'t', 'e', 's', 't'};

  // Expect legacy delegate call, mock_invoker should not be called
  EXPECT_CALL(*legacy_delegate,
              HandlePlatformMessage("flutter/lifecycle", payload, 1))
      .WillOnce(Return(true));
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod(_, _, _)).Times(0);

  EXPECT_TRUE(router->RoutePlatformMessage("flutter/lifecycle", payload, 1));

  // Legacy OnFirstFrame
  EXPECT_CALL(*legacy_delegate, OnFirstFrame()).WillOnce(Return(true));
  EXPECT_TRUE(router->RouteFirstFrame());

  // Legacy Vsync
  EXPECT_CALL(*legacy_delegate, OnVsync(100L, 200L)).WillOnce(Return(true));
  EXPECT_TRUE(router->RouteVsync(100L, 200L));

  // Legacy Deferred Library
  EXPECT_CALL(*legacy_delegate, RequestDartDeferredLibrary(5))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteRequestDartDeferredLibrary(5));

  // Flip flag to true -> routes to Embedder
  JniRouter::SetEmbedderEnabled(true);
  EXPECT_TRUE(JniRouter::IsEmbedderEnabled());
  EXPECT_EQ(router->GetActiveRoutingPath(), JniRouter::RoutingPath::kEmbedder);

  // Expect mock_invoker call via embedder delegate, legacy should not be called
  EXPECT_CALL(*legacy_delegate, HandlePlatformMessage(_, _, _)).Times(0);
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("handlePlatformMessage",
                               "(Ljava/lang/String;[BI)V", payload))
      .WillOnce(Return(true));

  EXPECT_TRUE(router->RoutePlatformMessage("flutter/lifecycle", payload, 1));

  // Embedder OnFirstFrame
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("onFirstFrame", "()V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteFirstFrame());

  // Embedder Vsync
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("onVsync", "(JJ)V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteVsync(100L, 200L));

  // Embedder Deferred Library
  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("requestDartDeferredLibrary", "(I)Z", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteRequestDartDeferredLibrary(5));

  // Reset flag back to false for test hygiene
  JniRouter::SetEmbedderEnabled(false);
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

  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("onFirstFrame", "()V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(native.GetRouter()->RouteFirstFrame());

  FlutterEmbedderNative::SetEmbedderEnabled(false);
  EXPECT_FALSE(FlutterEmbedderNative::IsEmbedderEnabled());
}

}  // namespace testing
}  // namespace android
}  // namespace flutter

int main(int argc, char* argv[]) {
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
