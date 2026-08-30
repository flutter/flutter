// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <future>
#include <thread>
#include <vector>

#include "flutter/shell/platform/android/android_engine_group.h"
#include "flutter/shell/platform/android/android_platform_views_controller.h"
#include "flutter/shell/platform/android/android_vsync_waiter.h"
#include "flutter/shell/platform/android/android_vulkan_texture.h"
#include "flutter/shell/platform/android/flutter_embedder_native.h"
#include "flutter/shell/platform/android/jni_delegate.h"
#include "flutter/shell/platform/android/jni_router.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/android/os_library_loader.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace android {
namespace testing {

using ::testing::_;
using ::testing::DoAll;
using ::testing::Eq;
using ::testing::NiceMock;
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
              SetApplicationLocale,
              (const std::string& locale),
              (override));

  MOCK_METHOD(bool, OnFirstFrame, (), (override));

  MOCK_METHOD(bool, OnPreEngineRestart, (), (override));

  MOCK_METHOD(bool,
              OnVsync,
              (int64_t frame_time_nanos, int64_t frame_target_time_nanos),
              (override));

  MOCK_METHOD(bool, AsyncWaitForVsync, (intptr_t baton), (override));

  MOCK_METHOD(bool,
              SetViewportMetrics,
              (const AndroidViewportMetrics& metrics),
              (override));

  MOCK_METHOD(bool,
              UpdateDisplayMetrics,
              (const AndroidDisplayMetrics& metrics),
              (override));

  MOCK_METHOD(bool,
              UpdateDisplayMetrics,
              (uint64_t display_id,
               double refresh_rate,
               double width,
               double height,
               double device_pixel_ratio),
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

  MOCK_METHOD(bool, InitVM, (const AndroidVMArgs& args), (override));

  MOCK_METHOD(bool, PrefetchDefaultFontManager, (), (override));

  MOCK_METHOD(bool, SetVmServiceUri, (const std::string& uri), (override));

  MOCK_METHOD(bool,
              RegisterHardwareBufferTexture,
              (int64_t texture_id),
              (override));

  MOCK_METHOD(bool,
              UnregisterHardwareBufferTexture,
              (int64_t texture_id),
              (override));

  MOCK_METHOD(bool,
              SetHardwareBufferFrame,
              (int64_t texture_id,
               std::shared_ptr<AndroidHardwareBuffer> buffer),
              (override));

  MOCK_METHOD(bool,
              SetHardwareBufferFrame,
              (int64_t texture_id,
               const FlutterHardwareBufferExternalTexture& texture),
              (override));

  MOCK_METHOD(bool,
              GetHardwareBufferTextureFrame,
              (int64_t texture_id,
               size_t width,
               size_t height,
               FlutterHardwareBufferExternalTexture* texture_out),
              (override));

  MOCK_METHOD(bool,
              OnHardwareBufferFrameAvailable,
              (int64_t texture_id),
              (override));

  MOCK_METHOD(bool, RegisterVulkanTexture, (int64_t texture_id), (override));

  MOCK_METHOD(bool, UnregisterVulkanTexture, (int64_t texture_id), (override));

  MOCK_METHOD(bool,
              SetVulkanTextureFrame,
              (int64_t texture_id,
               std::shared_ptr<AndroidVulkanExternalTexture> texture),
              (override));

  MOCK_METHOD(bool,
              SetVulkanTextureFrame,
              (int64_t texture_id, const FlutterVulkanExternalTexture& texture),
              (override));

  MOCK_METHOD(bool,
              GetVulkanTextureFrame,
              (int64_t texture_id,
               size_t width,
               size_t height,
               FlutterVulkanExternalTexture* texture_out),
              (override));

  MOCK_METHOD(bool,
              OnVulkanTextureFrameAvailable,
              (int64_t texture_id),
              (override));

  MOCK_METHOD(int64_t,
              SpawnEngine,
              (int64_t parent_engine_id, const AndroidEngineSpawnArgs& args),
              (override));

  MOCK_METHOD(bool, ShutdownSpawnedEngine, (int64_t engine_id), (override));

  MOCK_METHOD(size_t, GetActiveEngineCount, (), (const, override));

  MOCK_METHOD(bool, OnEngineGarbageCollected, (int64_t engine_id), (override));
};

class MockVulkanTextureProvider : public AndroidVulkanTextureProvider {
 public:
  MOCK_METHOD(bool, IsAvailable, (), (const, override));
  MOCK_METHOD(bool,
              IsSupported,
              (const AndroidVulkanImageDesc& desc),
              (const, override));
  MOCK_METHOD(std::unique_ptr<AndroidVulkanExternalTexture>,
              AllocateTexture,
              (const AndroidVulkanImageDesc& desc),
              (override));
  MOCK_METHOD(std::unique_ptr<AndroidVulkanExternalTexture>,
              CreateFromNativeImage,
              (uint64_t image_handle,
               const AndroidVulkanImageDesc& desc,
               bool take_ownership),
              (override));
  MOCK_METHOD(std::unique_ptr<AndroidVulkanExternalTexture>,
              CreateFromAHardwareBuffer,
              (const AndroidHardwareBuffer* hardware_buffer,
               const AndroidVulkanYcbcrConversionDesc* ycbcr_desc),
              (override));
  MOCK_METHOD(void, Acquire, (uint64_t image_handle), (override));
  MOCK_METHOD(void, Release, (uint64_t image_handle), (override));
  MOCK_METHOD(void*, ResolveVulkanSymbol, (const char* name), (override));
};

class MockHardwareBufferProvider : public AndroidHardwareBufferProvider {
 public:
  MOCK_METHOD(bool, IsAvailable, (), (const, override));
  MOCK_METHOD(bool,
              IsSupported,
              (const AndroidHardwareBufferDesc& desc),
              (const, override));
  MOCK_METHOD(std::unique_ptr<AndroidHardwareBuffer>,
              Allocate,
              (const AndroidHardwareBufferDesc& desc),
              (override));
  MOCK_METHOD(std::unique_ptr<AndroidHardwareBuffer>,
              CreateFromNativeHandle,
              (void* handle, bool take_ownership),
              (override));
  MOCK_METHOD(std::unique_ptr<AndroidHardwareBuffer>,
              CreateFromJavaHardwareBuffer,
              (void* env, void* java_hardware_buffer),
              (override));
  MOCK_METHOD(void*,
              ToJavaHardwareBuffer,
              (void* env, void* handle),
              (override));
  MOCK_METHOD(bool,
              Describe,
              (void* handle, AndroidHardwareBufferDesc* out_desc),
              (override));
  MOCK_METHOD(void, Acquire, (void* handle), (override));
  MOCK_METHOD(void, Release, (void* handle), (override));
  MOCK_METHOD(int,
              Lock,
              (void* handle,
               uint64_t usage,
               int32_t fence,
               const AndroidHardwareBufferRect* rect,
               void** out_address),
              (override));
  MOCK_METHOD(int, Unlock, (void* handle, int32_t* fence), (override));
  MOCK_METHOD(uint64_t, GetId, (void* handle), (override));
};

class MockCallbackCacheProvider : public CallbackCacheProvider {
 public:
  MOCK_METHOD(std::optional<DartCallbackInfo>,
              GetCallbackInformation,
              (int64_t handle),
              (override));
};

class MockImageDecoderProvider : public ImageDecoderProvider {
 public:
  MOCK_METHOD(bool,
              DecodeImage,
              (const uint8_t* data, size_t size, int64_t generator_handle),
              (override));

  MOCK_METHOD(void,
              OnImageHeader,
              (int64_t generator_handle, int32_t width, int32_t height),
              (override));

  MOCK_METHOD(std::optional<ImageHeaderInfo>,
              GetImageHeader,
              (int64_t generator_handle),
              (override));
};

class MockSurfaceControlProvider : public AndroidSurfaceControlProvider {
 public:
  MOCK_METHOD(bool, IsAvailable, (), (const, override));
  MOCK_METHOD(std::unique_ptr<AndroidSurfaceControl>,
              CreateFromWindow,
              (void* native_window, const std::string& debug_name),
              (override));
  MOCK_METHOD(std::unique_ptr<AndroidSurfaceControl>,
              Create,
              (AndroidSurfaceControl * parent, const std::string& debug_name),
              (override));
  MOCK_METHOD(std::unique_ptr<AndroidSurfaceControl>,
              CreateFromNativeHandle,
              (void* handle,
               const std::string& debug_name,
               bool take_ownership),
              (override));
  MOCK_METHOD(std::unique_ptr<AndroidSurfaceTransaction>,
              CreateTransaction,
              (),
              (override));
  MOCK_METHOD(std::unique_ptr<AndroidSurfaceTransaction>,
              CreateTransactionFromNativeHandle,
              (void* handle, bool take_ownership),
              (override));
  MOCK_METHOD(void, Acquire, (void* handle), (override));
  MOCK_METHOD(void, Release, (void* handle), (override));
  MOCK_METHOD(void, DeleteTransaction, (void* transaction_handle), (override));
  MOCK_METHOD(bool, ApplyTransaction, (void* transaction_handle), (override));
  MOCK_METHOD(bool,
              Reparent,
              (void* transaction_handle,
               void* surface_control_handle,
               void* new_parent_handle),
              (override));
  MOCK_METHOD(bool,
              SetVisibility,
              (void* transaction_handle,
               void* surface_control_handle,
               int8_t visibility),
              (override));
  MOCK_METHOD(bool,
              SetZOrder,
              (void* transaction_handle,
               void* surface_control_handle,
               int32_t z_order),
              (override));
  MOCK_METHOD(bool,
              SetBuffer,
              (void* transaction_handle,
               void* surface_control_handle,
               void* hardware_buffer,
               int acquire_fence_fd),
              (override));
  MOCK_METHOD(bool,
              SetGeometry,
              (void* transaction_handle,
               void* surface_control_handle,
               const AndroidSurfaceControlRect* source,
               const AndroidSurfaceControlRect* destination,
               int32_t transform),
              (override));
  MOCK_METHOD(bool,
              SetDamageRegion,
              (void* transaction_handle,
               void* surface_control_handle,
               const AndroidSurfaceControlRect* rects,
               uint32_t count),
              (override));
  MOCK_METHOD(bool,
              SetBufferAlpha,
              (void* transaction_handle,
               void* surface_control_handle,
               float alpha),
              (override));
  MOCK_METHOD(bool,
              SetColor,
              (void* transaction_handle,
               void* surface_control_handle,
               float r,
               float g,
               float b,
               float alpha),
              (override));
  MOCK_METHOD(bool,
              SetOnComplete,
              (void* transaction_handle,
               std::function<void(const AndroidSurfaceControlStats&)> callback),
              (override));
};

// =============================================================================
// Embedder Native Core Tests
// =============================================================================

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
  EXPECT_NE(native_instance->GetLibraryLoader(), nullptr);
  EXPECT_NE(native_instance->GetAssetProvider(), nullptr);
  EXPECT_NE(native_instance->GetCallbackCache(), nullptr);
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
              InvokeVoidMethod("requestDartDeferredLibrary", "(J)V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->RequestDartDeferredLibrary(101));

  // 11. OnAssetManagerChanged
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("onAssetManagerChanged", "()V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->OnAssetManagerChanged());

  // 12. LookupCallbackInformation with injected mock callback cache
  auto mock_cache = std::make_shared<InMemoryCallbackCacheProvider>();
  mock_cache->AddCallback(42L, "myDartCallback", "MyDartClass",
                          "package:app/main.dart");
  delegate->SetCallbackCache(mock_cache);
  EXPECT_EQ(delegate->GetCallbackCache(), mock_cache);

  auto cb_opt = delegate->LookupCallbackInformation(42L);
  ASSERT_TRUE(cb_opt.has_value());
  if (cb_opt.has_value()) {
    EXPECT_EQ(cb_opt->name, "myDartCallback");
    EXPECT_EQ(cb_opt->class_name, "MyDartClass");
    EXPECT_EQ(cb_opt->library_path, "package:app/main.dart");
  }

  EXPECT_FALSE(delegate->LookupCallbackInformation(999L).has_value());
}

TEST(FlutterEmbedderNativeTest, JniRouterRoutingFlip) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto embedder_cache = std::make_shared<InMemoryCallbackCacheProvider>();
  embedder_cache->AddCallback(100L, "embedderCallback", "EmbedderClass",
                              "package:embedder/main.dart");
  auto embedder_delegate =
      std::make_shared<JniDelegate>(mock_invoker, embedder_cache);
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

  // Asset Manager Changed (purged subsystem: routes directly to embedder)
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("onAssetManagerChanged", "()V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteAssetManagerChanged());

  // LookupCallbackInformation (purged subsystem: routes directly to embedder)
  auto direct_cb = router->RouteLookupCallbackInformation(100L);
  ASSERT_TRUE(direct_cb.has_value());
  EXPECT_EQ(direct_cb->name, "embedderCallback");
  EXPECT_EQ(direct_cb->class_name, "EmbedderClass");
  EXPECT_EQ(direct_cb->library_path, "package:embedder/main.dart");

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
              InvokeVoidMethod("requestDartDeferredLibrary", "(J)V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteRequestDartDeferredLibrary(5));

  // Embedder Asset Manager Changed
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("onAssetManagerChanged", "()V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteAssetManagerChanged());

  // Embedder LookupCallbackInformation (routed directly to embedder_delegate)
  auto embedder_cb = router->RouteLookupCallbackInformation(100L);
  ASSERT_TRUE(embedder_cb.has_value());
  EXPECT_EQ(embedder_cb->name, "embedderCallback");
  EXPECT_EQ(embedder_cb->class_name, "EmbedderClass");
  EXPECT_EQ(embedder_cb->library_path, "package:embedder/main.dart");

  // Reset flag back to true for default test hygiene in Phase 5.1
  JniRouter::SetEmbedderEnabled(true);
  EXPECT_TRUE(JniRouter::IsEmbedderEnabled());
}

TEST(FlutterEmbedderNativeTest, TargetFlipDefaultEmbedderEnabled) {
  // Phase 5.1 Target Flip verification: Embedder C-API is enabled by default.
  EXPECT_TRUE(JniRouter::IsEmbedderEnabled());
  EXPECT_TRUE(FlutterEmbedderNative::IsEmbedderEnabled());

  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto legacy_delegate = std::make_shared<MockLegacyJniDelegate>();
  auto router = std::make_unique<JniRouter>(
      std::make_shared<JniDelegate>(mock_invoker), legacy_delegate);

  EXPECT_EQ(router->GetActiveRoutingPath(), JniRouter::RoutingPath::kEmbedder);
  EXPECT_NE(router->GetEmbedderDelegate(), nullptr);
  EXPECT_NE(router->GetLegacyDelegate(), nullptr);
}

TEST(FlutterEmbedderNativeTest, TargetFlipDefaultRouteExecution) {
  // Default execution routes directly to embedder delegate without any manual
  // flag set.
  auto mock_invoker = std::make_shared<StrictMock<MockJvmInvoker>>();
  auto legacy_delegate = std::make_shared<StrictMock<MockLegacyJniDelegate>>();

  FlutterEmbedderNative native(mock_invoker, legacy_delegate);
  ASSERT_NE(native.GetRouter(), nullptr);
  EXPECT_EQ(native.GetRouter()->GetActiveRoutingPath(),
            JniRouter::RoutingPath::kEmbedder);

  std::vector<uint8_t> payload = {'p', 'h', 'a', 's', 'e', '5', '.', '1'};

  // Platform message routing defaults to embedder delegate
  EXPECT_CALL(*legacy_delegate, HandlePlatformMessage(_, _, _)).Times(0);
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("handlePlatformMessage",
                               "(Ljava/lang/String;[BI)V", payload))
      .WillOnce(Return(true));
  EXPECT_TRUE(
      native.GetRouter()->RoutePlatformMessage("flutter/default", payload, 42));

  // First frame routing defaults to embedder delegate
  EXPECT_CALL(*legacy_delegate, OnFirstFrame()).Times(0);
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("onFirstFrame", "()V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(native.GetRouter()->RouteFirstFrame());

  // Vsync routing defaults to embedder delegate
  EXPECT_CALL(*legacy_delegate, OnVsync(_, _)).Times(0);
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("onVsync", "(JJ)V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(native.GetRouter()->RouteVsync(1000000L, 2000000L));

  // Async wait for vsync routing defaults to embedder delegate
  EXPECT_CALL(*legacy_delegate, AsyncWaitForVsync(_)).Times(0);
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("asyncWaitForVsync", "(J)V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(native.GetRouter()->RouteAsyncWaitForVsync(999L));
}

TEST(FlutterEmbedderNativeTest, DynamicInstanceRouterWithCustomInvoker) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto legacy_delegate = std::make_shared<MockLegacyJniDelegate>();

  FlutterEmbedderNative native(mock_invoker, legacy_delegate);
  EXPECT_EQ(native.GetJvmInvoker(), mock_invoker);
  EXPECT_NE(native.GetJniDelegate(), nullptr);
  EXPECT_NE(native.GetRouter(), nullptr);

  EXPECT_TRUE(FlutterEmbedderNative::IsEmbedderEnabled());

  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("onFirstFrame", "()V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(native.GetRouter()->RouteFirstFrame());

  FlutterEmbedderNative::SetEmbedderEnabled(true);
  EXPECT_TRUE(FlutterEmbedderNative::IsEmbedderEnabled());
}

TEST(FlutterEmbedderNativeTest, AssetProviderLifecycleAndResolution) {
  auto native = std::make_unique<FlutterEmbedderNative>();
  EXPECT_NE(native->GetAssetProvider(), nullptr);

  // Inject a custom in-memory provider
  auto custom_provider_impl =
      std::make_shared<InMemoryAPKAssetProviderImpl>("custom_assets");
  custom_provider_impl->AddAsset("kernel_blob.bin", "MockKernelBytes");
  custom_provider_impl->AddAsset("shaders/ink_sparkle.frag", "MockShaderBytes");

  auto custom_provider =
      std::make_shared<APKAssetProvider>(custom_provider_impl);
  native->SetAssetProvider(custom_provider);
  EXPECT_EQ(native->GetAssetProvider(), custom_provider);

  // Resolve single asset
  auto mapping = native->ResolveAsset("kernel_blob.bin");
  ASSERT_NE(mapping, nullptr);
  EXPECT_EQ(mapping->GetSize(), 15u);
  EXPECT_EQ(std::string(reinterpret_cast<const char*>(mapping->GetMapping()),
                        mapping->GetSize()),
            "MockKernelBytes");

  // Resolve multiple asset mappings
  auto shader_mappings =
      native->ResolveAssetMappings("frag", std::string("shaders"));
  EXPECT_EQ(shader_mappings.size(), 1u);
  EXPECT_EQ(std::string(
                reinterpret_cast<const char*>(shader_mappings[0]->GetMapping()),
                shader_mappings[0]->GetSize()),
            "MockShaderBytes");
}

TEST(FlutterEmbedderNativeTest, AssetProviderMultithreadedResolution) {
  auto custom_provider_impl =
      std::make_shared<InMemoryAPKAssetProviderImpl>("flutter_assets");
  for (int i = 0; i < 20; ++i) {
    custom_provider_impl->AddAsset("data_" + std::to_string(i) + ".bin",
                                   "DataPayload_" + std::to_string(i));
  }

  auto custom_provider =
      std::make_shared<APKAssetProvider>(custom_provider_impl);
  auto native = std::make_unique<FlutterEmbedderNative>(
      std::make_shared<DefaultJvmInvoker>(), nullptr, nullptr, custom_provider);

  constexpr size_t kThreadCount = 8;
  constexpr size_t kIterations = 100;
  std::vector<std::future<bool>> futures;
  futures.reserve(kThreadCount);

  for (size_t t = 0; t < kThreadCount; ++t) {
    futures.push_back(std::async(std::launch::async, [&native, t]() {
      for (size_t iter = 0; iter < kIterations; ++iter) {
        int idx = static_cast<int>((t + iter) % 20);
        std::string asset_name = "data_" + std::to_string(idx) + ".bin";
        auto mapping = native->ResolveAsset(asset_name);
        if (!mapping || mapping->GetSize() == 0) {
          return false;
        }
      }
      return true;
    }));
  }

  for (auto& f : futures) {
    EXPECT_TRUE(f.get());
  }
}

TEST(FlutterEmbedderNativeTest, CallbackCacheProviderLifecycleAndResolution) {
  auto native = std::make_unique<FlutterEmbedderNative>();
  EXPECT_NE(native->GetCallbackCache(), nullptr);

  // Default provider with no callbacks loaded returns std::nullopt for unknown
  // handle
  EXPECT_FALSE(native->LookupCallbackInformation(12345678L).has_value());

  // Inject a custom in-memory callback provider
  auto custom_cache = std::make_shared<InMemoryCallbackCacheProvider>();
  custom_cache->AddCallback(1L, "topLevelCallback", "",
                            "package:test/top.dart");
  custom_cache->AddCallback(2L, "instanceCallback", "ServiceHost",
                            "package:test/service.dart");

  native->SetCallbackCache(custom_cache);
  EXPECT_EQ(native->GetCallbackCache(), custom_cache);

  // Lookup top-level callback (class_name empty)
  auto top_cb = native->LookupCallbackInformation(1L);
  ASSERT_TRUE(top_cb.has_value());
  if (top_cb.has_value()) {
    EXPECT_EQ(top_cb->name, "topLevelCallback");
    EXPECT_EQ(top_cb->class_name, "");
    EXPECT_EQ(top_cb->library_path, "package:test/top.dart");
  }

  // Lookup class-scoped callback
  auto class_cb = native->LookupCallbackInformation(2L);
  ASSERT_TRUE(class_cb.has_value());
  if (class_cb.has_value()) {
    EXPECT_EQ(class_cb->name, "instanceCallback");
    EXPECT_EQ(class_cb->class_name, "ServiceHost");
    EXPECT_EQ(class_cb->library_path, "package:test/service.dart");
  }

  // Non-existent handle returns std::nullopt
  EXPECT_FALSE(native->LookupCallbackInformation(9999L).has_value());
}

TEST(FlutterEmbedderNativeTest, CallbackCacheProviderMultithreadedResolution) {
  auto custom_cache = std::make_shared<InMemoryCallbackCacheProvider>();
  for (int i = 0; i < 50; ++i) {
    custom_cache->AddCallback(
        static_cast<int64_t>(1000 + i), "callback_" + std::to_string(i),
        "Class_" + std::to_string(i),
        "package:test/lib_" + std::to_string(i) + ".dart");
  }

  auto native = std::make_unique<FlutterEmbedderNative>(
      std::make_shared<DefaultJvmInvoker>(), nullptr, nullptr, nullptr,
      custom_cache);

  constexpr size_t kThreadCount = 8;
  constexpr size_t kIterations = 200;
  std::vector<std::future<bool>> futures;
  futures.reserve(kThreadCount);

  for (size_t t = 0; t < kThreadCount; ++t) {
    futures.push_back(std::async(std::launch::async, [&native, t]() {
      for (size_t iter = 0; iter < kIterations; ++iter) {
        int idx = static_cast<int>((t + iter) % 50);
        int64_t handle = static_cast<int64_t>(1000 + idx);
        auto cb = native->LookupCallbackInformation(handle);
        if (!cb.has_value()) {
          return false;
        }
        if (cb->name != "callback_" + std::to_string(idx) ||
            cb->class_name != "Class_" + std::to_string(idx) ||
            cb->library_path !=
                "package:test/lib_" + std::to_string(idx) + ".dart") {
          return false;
        }
      }
      return true;
    }));
  }

  for (auto& f : futures) {
    EXPECT_TRUE(f.get());
  }
}

TEST(FlutterEmbedderNativeTest, JniRouterNullDelegateSafety) {
  auto empty_router = std::make_unique<JniRouter>(nullptr, nullptr);

  JniRouter::SetEmbedderEnabled(false);
  EXPECT_FALSE(empty_router->RouteLookupCallbackInformation(42L).has_value());
  EXPECT_FALSE(empty_router->RouteFirstFrame());
  EXPECT_FALSE(empty_router->RoutePreEngineRestart());

  JniRouter::SetEmbedderEnabled(true);
  EXPECT_FALSE(empty_router->RouteLookupCallbackInformation(42L).has_value());
  EXPECT_FALSE(empty_router->RouteFirstFrame());
  EXPECT_FALSE(empty_router->RoutePreEngineRestart());

  JniRouter::SetEmbedderEnabled(false);
}

// =============================================================================
// CallbackCacheProvider Unit Tests
// =============================================================================

TEST(CallbackCacheProviderTest, InMemoryCallbackCacheOperations) {
  auto provider = std::make_shared<InMemoryCallbackCacheProvider>();
  EXPECT_EQ(provider->GetSize(), 0u);

  // Lookup on empty cache returns nullopt
  EXPECT_FALSE(provider->GetCallbackInformation(100L).has_value());

  // Add top-level callback
  provider->AddCallback(101L, "mainEntry", "", "package:flutter_app/main.dart");
  EXPECT_EQ(provider->GetSize(), 1u);

  auto cb101 = provider->GetCallbackInformation(101L);
  ASSERT_TRUE(cb101.has_value());
  if (cb101.has_value()) {
    EXPECT_EQ(cb101->name, "mainEntry");
    EXPECT_EQ(cb101->class_name, "");
    EXPECT_EQ(cb101->library_path, "package:flutter_app/main.dart");
  }

  // Add class-scoped callback
  provider->AddCallback(102L, "handleBackgroundMessage", "FirebasePlugin",
                        "package:firebase_messaging/firebase.dart");
  EXPECT_EQ(provider->GetSize(), 2u);

  auto cb102 = provider->GetCallbackInformation(102L);
  ASSERT_TRUE(cb102.has_value());
  if (cb102.has_value()) {
    EXPECT_EQ(cb102->name, "handleBackgroundMessage");
    EXPECT_EQ(cb102->class_name, "FirebasePlugin");
    EXPECT_EQ(cb102->library_path, "package:firebase_messaging/firebase.dart");
  }

  // Overwrite existing callback
  provider->AddCallback(101L, "mainEntryUpdated", "AppBootstrap",
                        "package:flutter_app/bootstrap.dart");
  EXPECT_EQ(provider->GetSize(), 2u);

  auto cb101_updated = provider->GetCallbackInformation(101L);
  ASSERT_TRUE(cb101_updated.has_value());
  if (cb101_updated.has_value()) {
    EXPECT_EQ(cb101_updated->name, "mainEntryUpdated");
    EXPECT_EQ(cb101_updated->class_name, "AppBootstrap");
  }

  // Remove single callback
  provider->RemoveCallback(101L);
  EXPECT_EQ(provider->GetSize(), 1u);
  EXPECT_FALSE(provider->GetCallbackInformation(101L).has_value());
  EXPECT_TRUE(provider->GetCallbackInformation(102L).has_value());

  // Clear all
  provider->Clear();
  EXPECT_EQ(provider->GetSize(), 0u);
  EXPECT_FALSE(provider->GetCallbackInformation(102L).has_value());
}

TEST(CallbackCacheProviderTest, ThreadSafeConcurrentCacheModifications) {
  auto provider = std::make_shared<InMemoryCallbackCacheProvider>();

  constexpr size_t kThreadCount = 8;
  constexpr size_t kEntriesPerThread = 100;
  std::vector<std::future<bool>> futures;
  futures.reserve(kThreadCount);

  // Concurrent writes
  for (size_t t = 0; t < kThreadCount; ++t) {
    futures.push_back(std::async(std::launch::async, [provider, t]() {
      for (size_t i = 0; i < kEntriesPerThread; ++i) {
        int64_t handle = static_cast<int64_t>(t * 1000 + i);
        provider->AddCallback(
            handle, "fn_" + std::to_string(handle),
            "Class_" + std::to_string(t),
            "package:test/mod_" + std::to_string(t) + ".dart");
      }
      return true;
    }));
  }

  for (auto& f : futures) {
    EXPECT_TRUE(f.get());
  }

  EXPECT_EQ(provider->GetSize(), kThreadCount * kEntriesPerThread);

  // Concurrent reads
  futures.clear();
  futures.reserve(kThreadCount);
  for (size_t t = 0; t < kThreadCount; ++t) {
    futures.push_back(std::async(std::launch::async, [provider, t]() {
      for (size_t i = 0; i < kEntriesPerThread; ++i) {
        int64_t handle = static_cast<int64_t>(t * 1000 + i);
        auto cb = provider->GetCallbackInformation(handle);
        if (!cb.has_value()) {
          return false;
        }
        if (cb->name != "fn_" + std::to_string(handle) ||
            cb->class_name != "Class_" + std::to_string(t)) {
          return false;
        }
      }
      return true;
    }));
  }

  for (auto& f : futures) {
    EXPECT_TRUE(f.get());
  }
}

// =============================================================================
// OSLibraryLoader & Dynamic Virtualization Unit Tests
// =============================================================================

TEST(OSLibraryLoaderTest, DefaultOSLibraryLoaderMissingLibraryFallback) {
  auto loader = std::make_shared<DefaultOSLibraryLoader>();
  EXPECT_NE(loader, nullptr);

  // Attempting to load non-existent library must not crash or segfault.
  auto lib = loader->LoadDynamicLibrary("lib_nonexistent_dummy_android_lib.so");
  EXPECT_EQ(lib, nullptr);

  EXPECT_FALSE(loader->IsLibraryLoaded("lib_nonexistent_dummy_android_lib.so"));

  // Resolving symbol from nonexistent library returns nullptr safely.
  void* sym = loader->ResolveSymbol("lib_nonexistent_dummy_android_lib.so",
                                    "AHardwareBuffer_allocate");
  EXPECT_EQ(sym, nullptr);

  auto fn = loader->ResolveFunction<int (*)(void*)>(
      "lib_nonexistent_dummy_android_lib.so", "AHardwareBuffer_allocate");
  EXPECT_EQ(fn, nullptr);

  // Null input handles safely
  EXPECT_EQ(loader->LoadDynamicLibrary(nullptr), nullptr);
  EXPECT_EQ(loader->ResolveSymbol(nullptr, "symbol"), nullptr);
  EXPECT_EQ(loader->ResolveSymbol("lib.so", nullptr), nullptr);
  EXPECT_FALSE(loader->IsLibraryLoaded(nullptr));
}

TEST(OSLibraryLoaderTest, MockOSLibrarySymbolInjectionAndResolution) {
  auto mock_lib = std::make_shared<MockOSLibrary>("libandroid.so");
  EXPECT_EQ(mock_lib->GetName(), "libandroid.so");
  EXPECT_TRUE(mock_lib->IsValid());

  // Define dummy mock function
  auto dummy_func = [](int a, int b) -> int { return a + b; };
  using DummyFuncType = int (*)(int, int);

  mock_lib->SetSymbol("AddNumbers", reinterpret_cast<void*>(+dummy_func));

  void* sym = mock_lib->ResolveSymbol("AddNumbers");
  EXPECT_NE(sym, nullptr);

  auto resolved_fn = mock_lib->ResolveFunction<DummyFuncType>("AddNumbers");
  EXPECT_NE(resolved_fn, nullptr);
  EXPECT_EQ(resolved_fn(10, 20), 30);

  // Query missing symbol
  EXPECT_EQ(mock_lib->ResolveSymbol("NonExistentSymbol"), nullptr);

  // Remove symbol
  mock_lib->RemoveSymbol("AddNumbers");
  EXPECT_EQ(mock_lib->ResolveSymbol("AddNumbers"), nullptr);

  // Invalidate library
  mock_lib->SetSymbol("AddNumbers", reinterpret_cast<void*>(+dummy_func));
  mock_lib->SetValid(false);
  EXPECT_FALSE(mock_lib->IsValid());
  EXPECT_EQ(mock_lib->ResolveSymbol("AddNumbers"), nullptr);

  // Clear symbols
  mock_lib->SetValid(true);
  mock_lib->ClearSymbols();
  EXPECT_EQ(mock_lib->ResolveSymbol("AddNumbers"), nullptr);
}

// Simulated mock Android API signatures
namespace mock_android_apis {
static int g_ahb_allocate_count = 0;
static int g_ahb_release_count = 0;
static int g_choreographer_post_count = 0;

static int Mock_AHardwareBuffer_allocate(const void* desc, void** out_buffer) {
  g_ahb_allocate_count++;
  if (out_buffer) {
    *out_buffer = reinterpret_cast<void*>(0xBAADF00D);
  }
  return 0;  // OK
}

static void Mock_AHardwareBuffer_release(void* buffer) {
  g_ahb_release_count++;
}

static void Mock_AChoreographer_postFrameCallback64(void* choreographer,
                                                    void* callback,
                                                    void* data) {
  g_choreographer_post_count++;
}
}  // namespace mock_android_apis

TEST(OSLibraryLoaderTest, MockOSLibraryLoaderAndroidApiSimulation) {
  mock_android_apis::g_ahb_allocate_count = 0;
  mock_android_apis::g_ahb_release_count = 0;
  mock_android_apis::g_choreographer_post_count = 0;

  auto loader = std::make_shared<MockOSLibraryLoader>();

  // Register mock libandroid.so with Android C-API functions
  auto libandroid = std::make_shared<MockOSLibrary>("libandroid.so");
  libandroid->SetSymbol("AHardwareBuffer_allocate",
                        reinterpret_cast<void*>(
                            &mock_android_apis::Mock_AHardwareBuffer_allocate));
  libandroid->SetSymbol("AHardwareBuffer_release",
                        reinterpret_cast<void*>(
                            &mock_android_apis::Mock_AHardwareBuffer_release));
  libandroid->SetSymbol(
      "AChoreographer_postFrameCallback64",
      reinterpret_cast<void*>(
          &mock_android_apis::Mock_AChoreographer_postFrameCallback64));

  loader->RegisterLibrary("libandroid.so", libandroid);

  EXPECT_TRUE(loader->IsLibraryLoaded("libandroid.so"));
  EXPECT_FALSE(loader->IsLibraryLoaded("libEGL.so"));

  // Resolve AHardwareBuffer_allocate
  using AHardwareBuffer_allocate_fn = int (*)(const void*, void**);
  auto allocate_fn = loader->ResolveFunction<AHardwareBuffer_allocate_fn>(
      "libandroid.so", "AHardwareBuffer_allocate");
  ASSERT_NE(allocate_fn, nullptr);

  void* created_buffer = nullptr;
  int alloc_result = allocate_fn(nullptr, &created_buffer);
  EXPECT_EQ(alloc_result, 0);
  EXPECT_EQ(created_buffer, reinterpret_cast<void*>(0xBAADF00D));
  EXPECT_EQ(mock_android_apis::g_ahb_allocate_count, 1);

  // Resolve AHardwareBuffer_release
  using AHardwareBuffer_release_fn = void (*)(void*);
  auto release_fn = loader->ResolveFunction<AHardwareBuffer_release_fn>(
      "libandroid.so", "AHardwareBuffer_release");
  ASSERT_NE(release_fn, nullptr);
  release_fn(created_buffer);
  EXPECT_EQ(mock_android_apis::g_ahb_release_count, 1);

  // Resolve AChoreographer_postFrameCallback64
  using AChoreographer_postFrameCallback64_fn = void (*)(void*, void*, void*);
  auto post_vsync_fn =
      loader->ResolveFunction<AChoreographer_postFrameCallback64_fn>(
          "libandroid.so", "AChoreographer_postFrameCallback64");
  ASSERT_NE(post_vsync_fn, nullptr);
  post_vsync_fn(nullptr, nullptr, nullptr);
  EXPECT_EQ(mock_android_apis::g_choreographer_post_count, 1);

  // Unregister library
  loader->UnregisterLibrary("libandroid.so");
  EXPECT_FALSE(loader->IsLibraryLoaded("libandroid.so"));
  EXPECT_EQ(loader->ResolveSymbol("libandroid.so", "AHardwareBuffer_allocate"),
            nullptr);
}

TEST(OSLibraryLoaderTest, MockOSLibraryLoaderConvenienceSetSymbol) {
  auto loader = std::make_shared<MockOSLibraryLoader>();

  auto mock_egl_proc = []() -> void* {
    return reinterpret_cast<void*>(0x1234);
  };
  loader->SetSymbol("libEGL.so", "eglGetCurrentContext",
                    reinterpret_cast<void*>(+mock_egl_proc));

  EXPECT_TRUE(loader->IsLibraryLoaded("libEGL.so"));

  using EglGetCurrentContextFn = void* (*)();
  auto egl_fn = loader->ResolveFunction<EglGetCurrentContextFn>(
      "libEGL.so", "eglGetCurrentContext");
  ASSERT_NE(egl_fn, nullptr);
  EXPECT_EQ(egl_fn(), reinterpret_cast<void*>(0x1234));

  loader->ClearLibraries();
  EXPECT_FALSE(loader->IsLibraryLoaded("libEGL.so"));
}

TEST(OSLibraryLoaderTest, FlutterEmbedderNativeLibraryLoaderIntegration) {
  // Test default loader setup
  auto native_default = std::make_unique<FlutterEmbedderNative>();
  EXPECT_NE(native_default->GetLibraryLoader(), nullptr);
  EXPECT_NE(FlutterEmbedderNative::GetDefaultLibraryLoader(), nullptr);

  // Test custom loader injection into FlutterEmbedderNative
  auto mock_loader = std::make_shared<MockOSLibraryLoader>();
  auto mock_invoker = std::make_shared<MockJvmInvoker>();

  auto dummy_vsync_fn = [](void* c, void* cb, void* d) {};
  mock_loader->SetSymbol("libandroid.so", "AChoreographer_postFrameCallback64",
                         reinterpret_cast<void*>(+dummy_vsync_fn));

  FlutterEmbedderNative native_custom(mock_invoker, nullptr, mock_loader);
  EXPECT_EQ(native_custom.GetLibraryLoader(), mock_loader);

  void* vsync_symbol = native_custom.GetLibraryLoader()->ResolveSymbol(
      "libandroid.so", "AChoreographer_postFrameCallback64");
  EXPECT_NE(vsync_symbol, nullptr);
}

TEST(OSLibraryLoaderTest, ThreadSafeConcurrentSymbolResolution) {
  auto mock_loader = std::make_shared<MockOSLibraryLoader>();

  for (int i = 0; i < 50; ++i) {
    std::string sym_name = "MockSymbol_" + std::to_string(i);
    mock_loader->SetSymbol(
        "libconcurrent.so", sym_name,
        reinterpret_cast<void*>(static_cast<uintptr_t>(i + 1)));
  }

  constexpr size_t kThreadCount = 8;
  constexpr size_t kIterationsPerThread = 500;
  std::vector<std::future<bool>> futures;
  futures.reserve(kThreadCount);

  for (size_t t = 0; t < kThreadCount; ++t) {
    futures.push_back(std::async(std::launch::async, [mock_loader, t]() {
      for (size_t iter = 0; iter < kIterationsPerThread; ++iter) {
        int sym_idx = static_cast<int>((t + iter) % 50);
        std::string sym_name = "MockSymbol_" + std::to_string(sym_idx);
        void* ptr =
            mock_loader->ResolveSymbol("libconcurrent.so", sym_name.c_str());
        if (ptr !=
            reinterpret_cast<void*>(static_cast<uintptr_t>(sym_idx + 1))) {
          return false;
        }
      }
      return true;
    }));
  }

  for (auto& f : futures) {
    EXPECT_TRUE(f.get());
  }
}

// =============================================================================
// Phase 2.3 Image Generators & LRU Cache Unit Tests
// =============================================================================

TEST(ImageDecoderTest, InMemoryImageDecoderProviderOperations) {
  auto provider = std::make_shared<InMemoryImageDecoderProvider>();
  EXPECT_EQ(provider->GetDecodeCount(), 0u);
  EXPECT_EQ(provider->GetLastDecodedSize(), 0u);

  // Set and check image header
  provider->SetHeaderInfo(100L, 800, 600);
  auto header = provider->GetImageHeader(100L);
  ASSERT_TRUE(header.has_value());
  if (header.has_value()) {
    EXPECT_EQ(header->width, 800);
    EXPECT_EQ(header->height, 600);
  }
  EXPECT_FALSE(provider->GetImageHeader(999L).has_value());

  // Decode success
  std::vector<uint8_t> dummy_data = {0xFF, 0xD8, 0xFF, 0xE0};  // JPEG magic
  EXPECT_TRUE(
      provider->DecodeImage(dummy_data.data(), dummy_data.size(), 100L));
  EXPECT_EQ(provider->GetDecodeCount(), 1u);
  EXPECT_EQ(provider->GetLastDecodedSize(), dummy_data.size());

  // OnImageHeader notification
  provider->OnImageHeader(101L, 1920, 1080);
  auto header101 = provider->GetImageHeader(101L);
  ASSERT_TRUE(header101.has_value());
  if (header101.has_value()) {
    EXPECT_EQ(header101->width, 1920);
    EXPECT_EQ(header101->height, 1080);
  }

  // Decode failure simulation
  provider->SetDecodeResult(false);
  EXPECT_FALSE(
      provider->DecodeImage(dummy_data.data(), dummy_data.size(), 100L));
  EXPECT_EQ(provider->GetDecodeCount(), 2u);

  // Clear
  provider->Clear();
  EXPECT_EQ(provider->GetDecodeCount(), 0u);
  EXPECT_EQ(provider->GetLastDecodedSize(), 0u);
  EXPECT_FALSE(provider->GetImageHeader(100L).has_value());
}

TEST(ImageDecoderTest, DefaultImageDecoderProviderWithInvoker) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto provider = std::make_shared<DefaultImageDecoderProvider>(mock_invoker);

  std::vector<uint8_t> test_bytes = {1, 2, 3, 4, 5};
  EXPECT_CALL(
      *mock_invoker,
      InvokeBooleanMethod("decodeImage",
                          "(Ljava/nio/ByteBuffer;J)Landroid/graphics/Bitmap;",
                          test_bytes))
      .WillOnce(Return(true));

  EXPECT_TRUE(provider->DecodeImage(test_bytes.data(), test_bytes.size(), 42L));

  // Invalid data checks
  EXPECT_FALSE(provider->DecodeImage(nullptr, 0, 42L));
  EXPECT_FALSE(provider->DecodeImage(test_bytes.data(), 0, 42L));

  // Header notifications and lookup
  provider->OnImageHeader(42L, 640, 480);
  auto header = provider->GetImageHeader(42L);
  ASSERT_TRUE(header.has_value());
  if (header.has_value()) {
    EXPECT_EQ(header->width, 640);
    EXPECT_EQ(header->height, 480);
  }
  EXPECT_FALSE(provider->GetImageHeader(999L).has_value());
}

TEST(ImageDecoderTest, EmbedderImageLRUOperations) {
  EmbedderImageLRU lru(4);
  EXPECT_EQ(lru.GetSize(), 0u);

  // Query empty cache
  EXPECT_EQ(lru.FindImage(1), 0u);

  // Add items
  EXPECT_EQ(lru.AddImage(0x1000, 1), 0u);
  EXPECT_EQ(lru.GetSize(), 1u);
  EXPECT_EQ(lru.FindImage(1), 0x1000u);

  EXPECT_EQ(lru.AddImage(0x2000, 2), 0u);
  EXPECT_EQ(lru.AddImage(0x3000, 3), 0u);
  EXPECT_EQ(lru.AddImage(0x4000, 4), 0u);
  EXPECT_EQ(lru.GetSize(), 4u);

  // All 4 keys exist
  EXPECT_EQ(lru.FindImage(1), 0x1000u);
  EXPECT_EQ(lru.FindImage(2), 0x2000u);
  EXPECT_EQ(lru.FindImage(3), 0x3000u);
  EXPECT_EQ(lru.FindImage(4), 0x4000u);

  // Access key 1 to make it most recently used.
  EXPECT_EQ(lru.FindImage(1), 0x1000u);

  // Adding 5th item should evict key 2 (the least recently used)
  uint64_t evicted = lru.AddImage(0x5000, 5);
  EXPECT_EQ(evicted, 2u);
  EXPECT_EQ(lru.FindImage(2), 0u);
  EXPECT_EQ(lru.FindImage(1), 0x1000u);
  EXPECT_EQ(lru.FindImage(5), 0x5000u);

  // Clear
  lru.Clear();
  EXPECT_EQ(lru.GetSize(), 0u);
  EXPECT_EQ(lru.FindImage(1), 0u);
  EXPECT_EQ(lru.FindImage(5), 0u);
}

TEST(ImageDecoderTest, EmbedderImageLRUMultithreaded) {
  auto lru = std::make_shared<EmbedderImageLRU>(16);

  constexpr size_t kThreadCount = 8;
  constexpr size_t kIterations = 200;
  std::vector<std::future<bool>> futures;
  futures.reserve(kThreadCount);

  for (size_t t = 0; t < kThreadCount; ++t) {
    futures.push_back(std::async(std::launch::async, [lru, t]() {
      for (size_t iter = 0; iter < kIterations; ++iter) {
        uint64_t key = (t * 100 + iter) % 30 + 1;
        uint64_t handle = 0xAAAA0000 + key;
        lru->AddImage(handle, key);
        uint64_t found = lru->FindImage(key);
        if (found != 0 && found != handle) {
          return false;
        }
      }
      return true;
    }));
  }

  for (auto& f : futures) {
    EXPECT_TRUE(f.get());
  }
}

TEST(ImageDecoderTest, JniDelegateImageDecoderIntegration) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto mock_decoder = std::make_shared<MockImageDecoderProvider>();

  auto delegate =
      std::make_unique<JniDelegate>(mock_invoker, nullptr, mock_decoder);
  EXPECT_EQ(delegate->GetImageDecoderProvider(), mock_decoder);

  std::vector<uint8_t> data = {0x0A, 0x0B, 0x0C};

  // DecodeImage calls mock_decoder
  EXPECT_CALL(*mock_decoder, DecodeImage(data.data(), data.size(), 55L))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->DecodeImage(data.data(), data.size(), 55L));

  // OnNativeImageHeader calls mock_decoder
  EXPECT_CALL(*mock_decoder, OnImageHeader(55L, 300, 200)).Times(1);
  delegate->OnNativeImageHeader(55L, 300, 200);

  // GetImageHeader calls mock_decoder
  EXPECT_CALL(*mock_decoder, GetImageHeader(55L))
      .WillOnce(Return(ImageHeaderInfo{300, 200}));
  auto header = delegate->GetImageHeader(55L);
  ASSERT_TRUE(header.has_value());
  if (header.has_value()) {
    EXPECT_EQ(header->width, 300);
    EXPECT_EQ(header->height, 200);
  }
}

TEST(ImageDecoderTest, JniRouterImageDecoderDirectRouting) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto in_memory_decoder = std::make_shared<InMemoryImageDecoderProvider>();
  in_memory_decoder->SetHeaderInfo(77L, 1024, 768);

  auto embedder_delegate =
      std::make_shared<JniDelegate>(mock_invoker, nullptr, in_memory_decoder);
  auto legacy_delegate = std::make_shared<MockLegacyJniDelegate>();

  auto router = std::make_unique<JniRouter>(embedder_delegate, legacy_delegate);

  std::vector<uint8_t> payload = {10, 20, 30};

  // 1. Even when Embedder flag is disabled, Image Decoder (purged subsystem)
  // routes directly to embedder delegate
  JniRouter::SetEmbedderEnabled(false);
  EXPECT_FALSE(JniRouter::IsEmbedderEnabled());

  EXPECT_TRUE(router->RouteDecodeImage(payload.data(), payload.size(), 77L));
  EXPECT_EQ(in_memory_decoder->GetDecodeCount(), 1u);

  router->RouteNativeImageHeader(77L, 1024, 768);
  auto hdr_disabled = router->RouteGetImageHeader(77L);
  ASSERT_TRUE(hdr_disabled.has_value());
  if (hdr_disabled.has_value()) {
    EXPECT_EQ(hdr_disabled->width, 1024);
    EXPECT_EQ(hdr_disabled->height, 768);
  }

  // 2. When Embedder flag is enabled, routes directly to embedder delegate as
  // well
  JniRouter::SetEmbedderEnabled(true);
  EXPECT_TRUE(JniRouter::IsEmbedderEnabled());

  EXPECT_TRUE(router->RouteDecodeImage(payload.data(), payload.size(), 77L));
  EXPECT_EQ(in_memory_decoder->GetDecodeCount(), 2u);

  router->RouteNativeImageHeader(88L, 500, 400);
  auto embedder_hdr = router->RouteGetImageHeader(88L);
  ASSERT_TRUE(embedder_hdr.has_value());
  if (embedder_hdr.has_value()) {
    EXPECT_EQ(embedder_hdr->width, 500);
    EXPECT_EQ(embedder_hdr->height, 400);
  }

  // Reset flag
  JniRouter::SetEmbedderEnabled(true);
  EXPECT_TRUE(JniRouter::IsEmbedderEnabled());
}

TEST(ImageDecoderTest, FlutterEmbedderNativeImageDecoderAndLRUIntegration) {
  auto custom_decoder = std::make_shared<InMemoryImageDecoderProvider>();
  auto custom_lru = std::make_shared<EmbedderImageLRU>(10);

  FlutterEmbedderNative native(std::make_shared<DefaultJvmInvoker>(), nullptr,
                               nullptr, nullptr, nullptr, custom_decoder,
                               custom_lru);

  EXPECT_EQ(native.GetImageDecoderProvider(), custom_decoder);
  EXPECT_EQ(native.GetImageLRU(), custom_lru);

  // Decode through FlutterEmbedderNative
  std::vector<uint8_t> data = {0x11, 0x22, 0x33};
  EXPECT_TRUE(native.DecodeImage(data.data(), data.size(), 1L));
  EXPECT_EQ(custom_decoder->GetDecodeCount(), 1u);

  native.OnNativeImageHeader(1L, 1280, 720);
  auto hdr = native.GetImageHeader(1L);
  ASSERT_TRUE(hdr.has_value());
  if (hdr.has_value()) {
    EXPECT_EQ(hdr->width, 1280);
    EXPECT_EQ(hdr->height, 720);
  }

  // LRU operations through FlutterEmbedderNative
  EXPECT_EQ(native.GetImageLRU()->AddImage(0xBEEF, 1), 0u);
  EXPECT_EQ(native.GetImageLRU()->FindImage(1), 0xBEEFu);

  // RegisterImageDecoder with null engine returns kInvalidArguments
  EXPECT_EQ(native.RegisterImageDecoder(nullptr), kInvalidArguments);
}

TEST(MutatorTranslationTest, JniDelegatePlatformViewMutatorsPush) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto delegate = std::make_unique<JniDelegate>(mock_invoker);

  AndroidMutatorsStack stack;
  FlutterTransformation ft = {
      .scaleX = 1.0,
      .skewX = 0.0,
      .transX = 50.0,
      .skewY = 0.0,
      .scaleY = 1.0,
      .transY = 75.0,
      .pers0 = 0.0,
      .pers1 = 0.0,
      .pers2 = 1.0,
  };
  stack.PushTransform(ft);
  stack.PushOpacity(0.9f);

  std::vector<uint8_t> expected_payload = stack.Serialize();

  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("onDisplayPlatformView",
                                              "(IIIIIIILjava/nio/ByteBuffer;)V",
                                              expected_payload))
      .WillOnce(Return(true));

  EXPECT_TRUE(
      delegate->PushPlatformViewMutators(101L, 10, 20, 300, 400, stack));
}

TEST(MutatorTranslationTest, JniRouterPlatformViewMutatorsDirectRouting) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto embedder_delegate = std::make_shared<JniDelegate>(mock_invoker);
  auto legacy_delegate = std::make_shared<MockLegacyJniDelegate>();
  auto router = std::make_unique<JniRouter>(embedder_delegate, legacy_delegate);

  AndroidMutatorsStack stack;
  stack.PushOpacity(0.8f);

  std::vector<uint8_t> payload = stack.Serialize();

  // 1. Even when Embedder is disabled, Mutators (purged subsystem) routes
  // directly to embedder_delegate (mock_invoker)
  JniRouter::SetEmbedderEnabled(false);
  EXPECT_FALSE(JniRouter::IsEmbedderEnabled());

  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("onDisplayPlatformView",
                               "(IIIIIIILjava/nio/ByteBuffer;)V", payload))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RoutePlatformViewMutators(1001L, 0, 0, 100, 200, stack));

  // 2. When Embedder is enabled -> routes to embedder_delegate (mock_invoker)
  JniRouter::SetEmbedderEnabled(true);
  EXPECT_TRUE(JniRouter::IsEmbedderEnabled());

  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("onDisplayPlatformView",
                               "(IIIIIIILjava/nio/ByteBuffer;)V", payload))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RoutePlatformViewMutators(1001L, 0, 0, 100, 200, stack));

  // Reset flag
  JniRouter::SetEmbedderEnabled(true);
  EXPECT_TRUE(JniRouter::IsEmbedderEnabled());
}

TEST(MutatorTranslationTest,
     FlutterEmbedderNativePlatformViewMutatorsIntegration) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  FlutterEmbedderNative native(mock_invoker);

  JniRouter::SetEmbedderEnabled(true);

  FlutterPlatformViewMutation m1 = {
      .type = kFlutterPlatformViewMutationTypeTransformation,
      .transformation =
          {
              .scaleX = 2.0,
              .skewX = 0.0,
              .transX = 10.0,
              .skewY = 0.0,
              .scaleY = 2.0,
              .transY = 20.0,
              .pers0 = 0.0,
              .pers1 = 0.0,
              .pers2 = 1.0,
          },
  };
  const FlutterPlatformViewMutation* mutations[] = {&m1};
  FlutterPlatformView pv = {
      .struct_size = sizeof(FlutterPlatformView),
      .identifier = 555,
      .mutations_count = 1,
      .mutations = mutations,
  };

  AndroidMutatorsStack stack = native.MapPlatformView(pv);
  EXPECT_EQ(stack.GetMutatorsCount(), 1u);

  std::vector<uint8_t> payload = stack.Serialize();
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("onDisplayPlatformView",
                               "(IIIIIIILjava/nio/ByteBuffer;)V", payload))
      .WillOnce(Return(true));

  EXPECT_TRUE(native.PushPlatformViewMutators(pv, 0, 0, 500, 500));

  JniRouter::SetEmbedderEnabled(false);
}

TEST(SemanticsAndAccessibilityTest, JniDelegateSemanticsOperations) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto delegate = std::make_unique<JniDelegate>(mock_invoker);

  // 1. UpdateSemantics with buffer
  std::vector<uint8_t> buffer = {0x01, 0x02, 0x03, 0x04};
  std::vector<std::string> strings = {"Label1"};
  EXPECT_CALL(
      *mock_invoker,
      InvokeVoidMethod("updateSemantics", "([B[Ljava/lang/String;)V", buffer))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->UpdateSemantics(buffer, strings));

  // 2. UpdateCustomAccessibilityActions
  std::vector<uint8_t> actions_buffer = {0x10, 0x20};
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("updateCustomAccessibilityActions",
                               "([B[Ljava/lang/String;)V", actions_buffer))
      .WillOnce(Return(true));
  EXPECT_TRUE(
      delegate->UpdateCustomAccessibilityActions(actions_buffer, {"Action1"}));

  // 3. UpdateSemantics with FlutterSemanticsUpdate2
  FlutterSemanticsFlags flags = {};
  flags.struct_size = sizeof(FlutterSemanticsFlags);
  flags.is_button = true;

  FlutterSemanticsNode2 node = {};
  node.struct_size = sizeof(FlutterSemanticsNode2);
  node.id = 55;
  node.label = "Test Node";
  node.flags2 = &flags;

  FlutterSemanticsCustomAction2 action = {};
  action.struct_size = sizeof(FlutterSemanticsCustomAction2);
  action.id = 1;
  action.label = "Custom Action";

  FlutterSemanticsNode2* node_ptrs[] = {&node};
  FlutterSemanticsCustomAction2* action_ptrs[] = {&action};

  FlutterSemanticsUpdate2 update = {
      .struct_size = sizeof(FlutterSemanticsUpdate2),
      .node_count = 1,
      .nodes = node_ptrs,
      .custom_action_count = 1,
      .custom_actions = action_ptrs,
      .view_id = 0,
  };

  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("updateCustomAccessibilityActions",
                               "([B[Ljava/lang/String;)V", ::testing::_))
      .WillOnce(Return(true));
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("updateSemantics", "([B[Ljava/lang/String;[[B)V",
                               ::testing::_))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->UpdateSemantics(update));

  // 4. SetSemanticsEnabled
  std::vector<uint8_t> enabled_payload = {1};
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("setSemanticsEnabled", "(Z)V", enabled_payload))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->SetSemanticsEnabled(true));

  // 5. DispatchSemanticsAction
  std::vector<uint8_t> action_data = {0xAA, 0xBB};
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("dispatchSemanticsAction",
                                              "(IIJ[B)V", ::testing::_))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->DispatchSemanticsAction(55, kFlutterSemanticsActionTap,
                                                action_data, 0));

  // 6. SetAccessibilityFeatures
  std::vector<uint8_t> features_payload = {0x07, 0x00, 0x00, 0x00};
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("setAccessibilityFeatures",
                                              "(I)V", features_payload))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->SetAccessibilityFeatures(7));
}

TEST(SemanticsAndAccessibilityTest, JniRouterSemanticsDirectRouting) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto embedder_delegate = std::make_shared<JniDelegate>(mock_invoker);
  auto legacy_delegate = std::make_shared<StrictMock<MockLegacyJniDelegate>>();
  auto router = std::make_unique<JniRouter>(embedder_delegate, legacy_delegate);

  std::vector<uint8_t> buffer = {0x11, 0x22};
  std::vector<std::string> strings = {"Hello"};

  // Across both flag states, semantics routes directly to embedder_delegate
  // (mock_invoker)
  for (bool embedder_flag : {false, true}) {
    JniRouter::SetEmbedderEnabled(embedder_flag);

    EXPECT_CALL(*mock_invoker,
                InvokeVoidMethod("updateSemantics",
                                 "([B[Ljava/lang/String;[[B)V", buffer))
        .WillOnce(Return(true));
    EXPECT_TRUE(router->RouteSemanticsUpdate(buffer, strings));

    EXPECT_CALL(*mock_invoker,
                InvokeVoidMethod("updateCustomAccessibilityActions",
                                 "([B[Ljava/lang/String;)V", buffer))
        .WillOnce(Return(true));
    EXPECT_TRUE(router->RouteCustomAccessibilityActions(buffer, strings));

    std::vector<uint8_t> enabled_payload = {1};
    EXPECT_CALL(*mock_invoker, InvokeVoidMethod("setSemanticsEnabled", "(Z)V",
                                                enabled_payload))
        .WillOnce(Return(true));
    EXPECT_TRUE(router->RouteSemanticsEnabled(true));

    EXPECT_CALL(*mock_invoker, InvokeVoidMethod("dispatchSemanticsAction",
                                                "(IIJ[B)V", ::testing::_))
        .WillOnce(Return(true));
    EXPECT_TRUE(router->RouteDispatchSemanticsAction(
        42, kFlutterSemanticsActionTap, buffer, 0));

    std::vector<uint8_t> features_payload = {0x0F, 0x00, 0x00, 0x00};
    EXPECT_CALL(*mock_invoker, InvokeVoidMethod("setAccessibilityFeatures",
                                                "(I)V", features_payload))
        .WillOnce(Return(true));
    EXPECT_TRUE(router->RouteSetAccessibilityFeatures(15));
  }

  // Reset flag
  JniRouter::SetEmbedderEnabled(true);
}

TEST(SemanticsAndAccessibilityTest, FlutterEmbedderNativeSemanticsIntegration) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  FlutterEmbedderNative native(mock_invoker);

  JniRouter::SetEmbedderEnabled(true);

  // Semantics update struct through FlutterEmbedderNative
  FlutterSemanticsNode2 node = {};
  node.struct_size = sizeof(FlutterSemanticsNode2);
  node.id = 100;
  node.label = "Native Semantics Node";

  FlutterSemanticsNode2* nodes[] = {&node};
  FlutterSemanticsUpdate2 update = {
      .struct_size = sizeof(FlutterSemanticsUpdate2),
      .node_count = 1,
      .nodes = nodes,
      .custom_action_count = 0,
      .custom_actions = nullptr,
      .view_id = 0,
  };

  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("updateSemantics", "([B[Ljava/lang/String;[[B)V",
                               ::testing::_))
      .WillOnce(Return(true));

  EXPECT_TRUE(native.UpdateSemantics(update));

  // OnUpdateSemantics2 static callback
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("updateSemantics", "([B[Ljava/lang/String;[[B)V",
                               ::testing::_))
      .WillOnce(Return(true));
  FlutterEmbedderNative::OnUpdateSemantics2(&update, &native);

  // Engine call validity tests with null engine
  EXPECT_EQ(native.UpdateSemanticsEnabled(nullptr, true), kInvalidArguments);
  EXPECT_EQ(native.UpdateAccessibilityFeatures(
                nullptr, kFlutterAccessibilityFeatureBoldText),
            kInvalidArguments);
  EXPECT_EQ(native.SendSemanticsAction(nullptr, nullptr), kInvalidArguments);
  EXPECT_EQ(native.DispatchSemanticsActionToEngine(
                nullptr, 100, kFlutterSemanticsActionTap, nullptr, 0),
            kInvalidArguments);

  JniRouter::SetEmbedderEnabled(false);
}

// =============================================================================
// Phase 2.6: Platform Views Unit Tests
// =============================================================================

TEST(PlatformViewsTest, InMemoryPlatformViewsProviderLifecycle) {
  InMemoryPlatformViewsProvider provider;

  EXPECT_EQ(provider.GetCreatedViewsCount(), 0u);
  EXPECT_FALSE(provider.IsHcppEnabled());

  // 1. Create Texture Layer platform view
  PlatformViewCreationParams params1 = {
      .view_id = 1,
      .view_type = "test.platform.view.text",
      .width = 300.0,
      .height = 200.0,
      .direction = 0,
      .params = {0x01, 0x02, 0x03},
  };
  int64_t texture_id = provider.CreatePlatformView(
      params1, PlatformViewCompositionType::kTextureLayer);
  EXPECT_GT(texture_id, 0);
  EXPECT_EQ(provider.GetCreatedViewsCount(), 1u);
  EXPECT_TRUE(provider.IsViewCreated(1));
  EXPECT_FALSE(provider.IsViewDisposed(1));
  EXPECT_EQ(provider.GetCompositionType(1),
            PlatformViewCompositionType::kTextureLayer);
  auto stored_params1 = provider.GetCreationParams(1);
  ASSERT_TRUE(stored_params1.has_value());
  if (stored_params1.has_value()) {
    EXPECT_EQ(stored_params1->view_type, "test.platform.view.text");
    EXPECT_DOUBLE_EQ(stored_params1->width, 300.0);
    EXPECT_DOUBLE_EQ(stored_params1->height, 200.0);
  }

  // 2. Create Hybrid Composition platform view
  PlatformViewCreationParams params2 = {
      .view_id = 2,
      .view_type = "test.platform.view.map",
      .width = 400.0,
      .height = 400.0,
      .direction = 1,
      .params = {},
  };
  int64_t res2 = provider.CreatePlatformView(
      params2, PlatformViewCompositionType::kHybridComposition);
  EXPECT_EQ(res2, 0);
  EXPECT_EQ(provider.GetCreatedViewsCount(), 2u);
  EXPECT_TRUE(provider.IsViewCreated(2));
  EXPECT_EQ(provider.GetCompositionType(2),
            PlatformViewCompositionType::kHybridComposition);

  // 3. Create Hybrid Composition++ platform view
  provider.SetHcppEnabled(true);
  EXPECT_TRUE(provider.IsHcppEnabled());
  PlatformViewCreationParams params3 = {
      .view_id = 3,
      .view_type = "test.platform.view.video",
      .width = 1920.0,
      .height = 1080.0,
      .direction = 0,
      .params = {0xFF},
  };
  int64_t res3 = provider.CreatePlatformView(
      params3, PlatformViewCompositionType::kHybridCompositionPlusPlus);
  EXPECT_EQ(res3, 0);
  EXPECT_EQ(provider.GetCreatedViewsCount(), 3u);
  EXPECT_TRUE(provider.IsViewCreated(3));

  // 4. Resize platform view
  PlatformViewResizeRequest resize_req = {
      .view_id = 1,
      .width = 500.0,
      .height = 350.0,
  };
  EXPECT_TRUE(provider.ResizePlatformView(resize_req));
  auto last_resize = provider.GetLastResizeRequest();
  ASSERT_TRUE(last_resize.has_value());
  if (last_resize.has_value()) {
    EXPECT_EQ(last_resize->view_id, 1);
    EXPECT_DOUBLE_EQ(last_resize->width, 500.0);
    EXPECT_DOUBLE_EQ(last_resize->height, 350.0);
  }

  // 5. Offset platform view
  EXPECT_TRUE(provider.OffsetPlatformView(1, 15.5, 25.5));
  auto offsets = provider.GetOffsets(1);
  ASSERT_TRUE(offsets.has_value());
  if (offsets.has_value()) {
    EXPECT_DOUBLE_EQ(offsets->first, 15.5);
    EXPECT_DOUBLE_EQ(offsets->second, 25.5);
  }

  // 6. Set direction
  EXPECT_TRUE(provider.SetDirection(2, 1));
  auto direction = provider.GetDirection(2);
  ASSERT_TRUE(direction.has_value());
  if (direction.has_value()) {
    EXPECT_EQ(*direction, 1);
  }

  // 7. Clear focus
  EXPECT_EQ(provider.GetFocusClearedCount(2), 0u);
  EXPECT_TRUE(provider.ClearFocus(2));
  EXPECT_EQ(provider.GetFocusClearedCount(2), 1u);
  EXPECT_TRUE(provider.ClearFocus(2));
  EXPECT_EQ(provider.GetFocusClearedCount(2), 2u);

  // 8. Dispose platform views
  EXPECT_TRUE(provider.DisposePlatformView(1));
  EXPECT_FALSE(provider.IsViewCreated(1));
  EXPECT_TRUE(provider.IsViewDisposed(1));
  EXPECT_FALSE(provider.GetCompositionType(1).has_value());
  EXPECT_FALSE(provider.GetOffsets(1).has_value());
  EXPECT_EQ(provider.GetCreatedViewsCount(), 2u);

  EXPECT_TRUE(provider.DisposePlatformView(2));
  EXPECT_TRUE(provider.DisposePlatformView(3));
  EXPECT_EQ(provider.GetCreatedViewsCount(), 0u);

  // Clear provider
  provider.Clear();
  EXPECT_EQ(provider.GetCreatedViewsCount(), 0u);
}

TEST(PlatformViewsTest, InMemoryPlatformViewsProviderTouchDispatch) {
  InMemoryPlatformViewsProvider provider;

  PlatformViewPointerCoords p1 = {
      .pointer_id = 0,
      .x = 100.0f,
      .y = 200.0f,
      .size = 1.0f,
      .pressure = 0.8f,
      .orientation = 0.0f,
      .tool_type = 1,
  };
  PlatformViewPointerCoords p2 = {
      .pointer_id = 1,
      .x = 150.0f,
      .y = 250.0f,
      .size = 1.0f,
      .pressure = 0.5f,
      .orientation = 0.0f,
      .tool_type = 1,
  };

  PlatformViewTouch touch = {
      .view_id = 42,
      .motion_event_id = 1001,
      .action = 2,  // ACTION_MOVE
      .pointer_count = 2,
      .pointers = {p1, p2},
      .down_time = 5000000,
      .event_time = 5000100,
      .source = 4098,
      .flags = 0,
      .meta_state = 0,
      .button_state = 0,
      .raw_x = 100.0f,
      .raw_y = 200.0f,
  };

  EXPECT_TRUE(provider.DispatchTouchEvent(touch));
  const auto& touches = provider.GetDispatchedTouches();
  ASSERT_EQ(touches.size(), 1u);
  EXPECT_EQ(touches[0].view_id, 42);
  EXPECT_EQ(touches[0].motion_event_id, 1001);
  EXPECT_EQ(touches[0].action, 2);
  EXPECT_EQ(touches[0].pointer_count, 2);
  ASSERT_EQ(touches[0].pointers.size(), 2u);
  EXPECT_FLOAT_EQ(touches[0].pointers[0].x, 100.0f);
  EXPECT_FLOAT_EQ(touches[0].pointers[1].y, 250.0f);
}

TEST(PlatformViewsTest, InMemoryPlatformViewsProviderMutatorsAndGeometry) {
  InMemoryPlatformViewsProvider provider;

  AndroidMutatorsStack stack;
  stack.PushTransform(
      AndroidMatrix3x3{2.0, 0.0, 10.0, 0.0, 2.0, 20.0, 0.0, 0.0, 1.0});
  stack.PushClipRect(AndroidRect{10.0, 10.0, 100.0, 100.0});
  stack.PushOpacity(0.5f);

  PlatformViewGeometry geometry = {
      .view_id = 101,
      .x = 10,
      .y = 20,
      .width = 300,
      .height = 400,
      .view_width = 300,
      .view_height = 400,
      .mutators_stack = stack,
  };

  EXPECT_TRUE(provider.OnDisplayPlatformView(geometry));
  EXPECT_FALSE(provider.IsViewHidden(101));

  auto last_geom = provider.GetLastGeometry(101);
  ASSERT_TRUE(last_geom.has_value());
  if (last_geom.has_value()) {
    EXPECT_EQ(last_geom->view_id, 101);
    EXPECT_EQ(last_geom->x, 10);
    EXPECT_EQ(last_geom->y, 20);
    EXPECT_EQ(last_geom->width, 300);
    EXPECT_EQ(last_geom->height, 400);
    EXPECT_EQ(last_geom->mutators_stack.GetMutatorsCount(), 3u);
  }

  // Hide view
  EXPECT_TRUE(provider.HidePlatformView(101));
  EXPECT_TRUE(provider.IsViewHidden(101));

  // Displaying again clears hidden flag
  EXPECT_TRUE(provider.OnDisplayPlatformView(geometry));
  EXPECT_FALSE(provider.IsViewHidden(101));
}

TEST(PlatformViewsTest, InMemoryPlatformViewsProviderOverlaysAndTransactions) {
  InMemoryPlatformViewsProvider provider;

  // Frame lifecycle
  EXPECT_FALSE(provider.IsInFrame());
  EXPECT_TRUE(provider.OnBeginFrame());
  EXPECT_TRUE(provider.IsInFrame());
  EXPECT_TRUE(provider.OnEndFrame());
  EXPECT_FALSE(provider.IsInFrame());

  // Native view hierarchy sync
  EXPECT_TRUE(provider.GetSynchronizeToNativeViewHierarchy());
  EXPECT_TRUE(provider.SynchronizeToNativeViewHierarchy(false));
  EXPECT_FALSE(provider.GetSynchronizeToNativeViewHierarchy());
  EXPECT_TRUE(provider.SynchronizeToNativeViewHierarchy(true));
  EXPECT_TRUE(provider.GetSynchronizeToNativeViewHierarchy());

  // Overlay surfaces
  EXPECT_EQ(provider.GetOverlaySurfacesCount(), 0u);
  auto overlay1 = provider.CreateOverlaySurface();
  ASSERT_TRUE(overlay1.has_value());
  if (overlay1.has_value()) {
    EXPECT_EQ(*overlay1, 1);
  }
  EXPECT_EQ(provider.GetOverlaySurfacesCount(), 1u);
  EXPECT_TRUE(provider.IsOverlayVisible(1));

  auto overlay2 = provider.CreateOverlaySurface();
  ASSERT_TRUE(overlay2.has_value());
  if (overlay2.has_value()) {
    EXPECT_EQ(*overlay2, 2);
  }
  EXPECT_EQ(provider.GetOverlaySurfacesCount(), 2u);

  // Display overlay
  PlatformViewOverlay pvo = {
      .surface_id = 1,
      .x = 0,
      .y = 0,
      .width = 500,
      .height = 600,
  };
  EXPECT_TRUE(provider.OnDisplayOverlaySurface(pvo));
  const auto& displayed = provider.GetDisplayedOverlays();
  ASSERT_EQ(displayed.size(), 1u);
  EXPECT_EQ(displayed.at(1).width, 500);

  // Hide / Show overlay
  EXPECT_TRUE(provider.HideOverlaySurface(1));
  EXPECT_FALSE(provider.IsOverlayVisible(1));
  EXPECT_TRUE(provider.ShowOverlaySurface(1));
  EXPECT_TRUE(provider.IsOverlayVisible(1));

  // Destroy overlays
  EXPECT_TRUE(provider.DestroyOverlaySurfaces());
  EXPECT_EQ(provider.GetOverlaySurfacesCount(), 0u);
  EXPECT_EQ(provider.GetDisplayedOverlays().size(), 0u);

  // Transactions
  EXPECT_EQ(provider.GetTransactionCount(), 0u);
  EXPECT_TRUE(provider.CreateTransaction());
  EXPECT_EQ(provider.GetTransactionCount(), 1u);
  EXPECT_TRUE(provider.SwapTransactions());
  EXPECT_EQ(provider.GetTransactionCount(), 2u);
  EXPECT_TRUE(provider.ApplyTransactions());
  EXPECT_EQ(provider.GetTransactionCount(), 3u);
}

TEST(PlatformViewsTest, DefaultPlatformViewsProviderWithMockInvoker) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  DefaultPlatformViewsProvider provider(mock_invoker);

  // 1. CreatePlatformView (Texture Layer)
  PlatformViewCreationParams params = {
      .view_id = 42,
      .view_type = "test.view",
      .width = 100.0,
      .height = 100.0,
      .direction = 0,
      .params = {0xAA, 0xBB},
  };
  EXPECT_CALL(*mock_invoker,
              InvokeIntMethod("createForTextureLayer",
                              "(Ljava/lang/String;IDDILjava/nio/ByteBuffer;)J",
                              params.params))
      .WillOnce(Return(777));
  EXPECT_EQ(provider.CreatePlatformView(
                params, PlatformViewCompositionType::kTextureLayer),
            777);

  // 2. CreatePlatformView (Hybrid Composition)
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("createForPlatformViewLayer",
                               "(Ljava/lang/String;IDDILjava/nio/ByteBuffer;)V",
                               params.params))
      .WillOnce(Return(true));
  EXPECT_EQ(provider.CreatePlatformView(
                params, PlatformViewCompositionType::kHybridComposition),
            0);

  // 3. CreatePlatformView (HC++)
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("createPlatformViewHcpp",
                               "(Ljava/lang/String;IDDILjava/nio/ByteBuffer;)V",
                               params.params))
      .WillOnce(Return(true));
  EXPECT_EQ(
      provider.CreatePlatformView(
          params, PlatformViewCompositionType::kHybridCompositionPlusPlus),
      0);

  // 4. DisposePlatformView
  int64_t view_id = 42;
  std::vector<uint8_t> dispose_payload(sizeof(int64_t));
  std::memcpy(dispose_payload.data(), &view_id, sizeof(int64_t));
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("disposePlatformView", "(I)V", dispose_payload))
      .WillOnce(Return(true));
  EXPECT_TRUE(provider.DisposePlatformView(42));

  // 5. ResizePlatformView
  PlatformViewResizeRequest resize_req = {
      .view_id = 42,
      .width = 200.0,
      .height = 300.0,
  };
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("resizePlatformView", "(IDD)V",
                                              std::vector<uint8_t>{}))
      .WillOnce(Return(true));
  EXPECT_TRUE(provider.ResizePlatformView(resize_req));

  // 6. OffsetPlatformView
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("offsetPlatformView", "(IDD)V",
                                              std::vector<uint8_t>{}))
      .WillOnce(Return(true));
  EXPECT_TRUE(provider.OffsetPlatformView(42, 10.0, 20.0));

  // 7. SetDirection
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("setPlatformViewDirection",
                                              "(II)V", std::vector<uint8_t>{}))
      .WillOnce(Return(true));
  EXPECT_TRUE(provider.SetDirection(42, 1));

  // 8. ClearFocus
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("clearPlatformViewFocus", "(I)V",
                                              std::vector<uint8_t>{}))
      .WillOnce(Return(true));
  EXPECT_TRUE(provider.ClearFocus(42));

  // 9. DispatchTouchEvent
  PlatformViewTouch touch = {.view_id = 42};
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("onTouch",
                               "(Lio/flutter/embedding/engine/systemchannels/"
                               "PlatformViewTouch;)V",
                               std::vector<uint8_t>{}))
      .WillOnce(Return(true));
  EXPECT_TRUE(provider.DispatchTouchEvent(touch));

  // 10. OnDisplayPlatformView
  PlatformViewGeometry geom = {.view_id = 42};
  std::vector<uint8_t> geom_payload = geom.mutators_stack.Serialize();
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("onDisplayPlatformView",
                               "(IIIIIIILjava/nio/ByteBuffer;)V", geom_payload))
      .WillOnce(Return(true));
  EXPECT_TRUE(provider.OnDisplayPlatformView(geom));

  // 11. HidePlatformView
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("hidePlatformView", "(I)V",
                                              std::vector<uint8_t>{}))
      .WillOnce(Return(true));
  EXPECT_TRUE(provider.HidePlatformView(42));

  // 12. SynchronizeToNativeViewHierarchy
  std::vector<uint8_t> sync_payload = {1};
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("synchronizeToNativeViewHierarchy", "(Z)V",
                               sync_payload))
      .WillOnce(Return(true));
  EXPECT_TRUE(provider.SynchronizeToNativeViewHierarchy(true));

  // 13. Frame callbacks
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("onBeginFrame", "()V", std::vector<uint8_t>{}))
      .WillOnce(Return(true));
  EXPECT_TRUE(provider.OnBeginFrame());

  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("onEndFrame", "()V", std::vector<uint8_t>{}))
      .WillOnce(Return(true));
  EXPECT_TRUE(provider.OnEndFrame());

  // 14. Overlay surfaces
  EXPECT_CALL(
      *mock_invoker,
      InvokeIntMethod("createOverlaySurface",
                      "()Lio/flutter/embedding/engine/FlutterOverlaySurface;",
                      std::vector<uint8_t>{}))
      .WillOnce(Return(9));
  auto overlay_id = provider.CreateOverlaySurface();
  ASSERT_TRUE(overlay_id.has_value());
  if (overlay_id.has_value()) {
    EXPECT_EQ(*overlay_id, 9);
  }

  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("destroyOverlaySurfaces", "()V",
                                              std::vector<uint8_t>{}))
      .WillOnce(Return(true));
  EXPECT_TRUE(provider.DestroyOverlaySurfaces());

  PlatformViewOverlay overlay_req = {.surface_id = 9};
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("onDisplayOverlaySurface", "(IIIII)V",
                               std::vector<uint8_t>{}))
      .WillOnce(Return(true));
  EXPECT_TRUE(provider.OnDisplayOverlaySurface(overlay_req));

  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("showOverlaySurface", "(I)V",
                                              std::vector<uint8_t>{}))
      .WillOnce(Return(true));
  EXPECT_TRUE(provider.ShowOverlaySurface(9));

  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("hideOverlaySurface", "(I)V",
                                              std::vector<uint8_t>{}))
      .WillOnce(Return(true));
  EXPECT_TRUE(provider.HideOverlaySurface(9));

  // 15. Transactions
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("createTransaction",
                               "()Landroid/view/SurfaceControl$Transaction;",
                               std::vector<uint8_t>{}))
      .WillOnce(Return(true));
  EXPECT_TRUE(provider.CreateTransaction());

  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("swapTransactions", "()V",
                                              std::vector<uint8_t>{}))
      .WillOnce(Return(true));
  EXPECT_TRUE(provider.SwapTransactions());

  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("applyTransactions", "()V",
                                              std::vector<uint8_t>{}))
      .WillOnce(Return(true));
  EXPECT_TRUE(provider.ApplyTransactions());

  // 16. HCPP state
  EXPECT_FALSE(provider.IsHcppEnabled());
  provider.SetHcppEnabled(true);
  EXPECT_TRUE(provider.IsHcppEnabled());
}

TEST(PlatformViewsTest, AndroidPlatformViewsControllerIntegration) {
  auto provider = std::make_shared<InMemoryPlatformViewsProvider>();
  AndroidPlatformViewsController controller(provider);

  EXPECT_EQ(controller.GetActiveViewsCount(), 0u);
  EXPECT_EQ(controller.GetProvider(), provider);

  // Create view
  PlatformViewCreationParams params = {
      .view_id = 10,
      .view_type = "hybrid.view",
      .width = 640.0,
      .height = 480.0,
      .direction = 0,
      .params = {},
  };
  EXPECT_EQ(controller.CreatePlatformView(
                params, PlatformViewCompositionType::kHybridComposition),
            0);
  EXPECT_EQ(controller.GetActiveViewsCount(), 1u);
  EXPECT_TRUE(controller.HasPlatformView(10));
  EXPECT_EQ(controller.GetCompositionType(10),
            PlatformViewCompositionType::kHybridComposition);

  // Mutators and display
  FlutterPlatformViewMutation m1 = {
      .type = kFlutterPlatformViewMutationTypeOpacity,
      .opacity = 0.75,
  };
  const FlutterPlatformViewMutation* mutations[] = {&m1};
  FlutterPlatformView pv = {
      .struct_size = sizeof(FlutterPlatformView),
      .identifier = 10,
      .mutations_count = 1,
      .mutations = mutations,
  };

  EXPECT_TRUE(controller.OnDisplayPlatformView(pv, 0, 0, 640, 480, 640, 480));
  auto geom = controller.GetPlatformViewGeometry(10);
  ASSERT_TRUE(geom.has_value());
  if (geom.has_value()) {
    EXPECT_EQ(geom->view_id, 10);
    EXPECT_EQ(geom->width, 640);
    EXPECT_EQ(geom->height, 480);
    EXPECT_EQ(geom->mutators_stack.GetMutatorsCount(), 1u);

    // PushPlatformViewMutators
    EXPECT_TRUE(controller.PushPlatformViewMutators(pv, 0, 0, 640, 480));
    EXPECT_TRUE(controller.PushPlatformViewMutators(10, 0, 0, 640, 480,
                                                    geom->mutators_stack));
  }

  // Hide view
  EXPECT_TRUE(controller.HidePlatformView(10));
  EXPECT_TRUE(provider->IsViewHidden(10));

  // Overlay operations through controller
  auto overlay_id = controller.CreateOverlaySurface();
  ASSERT_TRUE(overlay_id.has_value());
  if (overlay_id.has_value()) {
    EXPECT_TRUE(
        controller.OnDisplayOverlaySurface(*overlay_id, 0, 0, 640, 480));
    EXPECT_TRUE(controller.ShowOverlaySurface(*overlay_id));
    EXPECT_TRUE(controller.HideOverlaySurface(*overlay_id));
  }
  EXPECT_TRUE(controller.DestroyOverlaySurfaces());

  // Frame and sync
  EXPECT_TRUE(controller.OnBeginFrame());
  EXPECT_TRUE(controller.OnEndFrame());
  EXPECT_TRUE(controller.SynchronizeToNativeViewHierarchy(true));

  // Transactions
  EXPECT_TRUE(controller.CreateTransaction());
  EXPECT_TRUE(controller.SwapTransactions());
  EXPECT_TRUE(controller.ApplyTransactions());

  // Dispose view
  EXPECT_TRUE(controller.DisposePlatformView(10));
  EXPECT_EQ(controller.GetActiveViewsCount(), 0u);
  EXPECT_FALSE(controller.HasPlatformView(10));
}

TEST(PlatformViewsTest, JniDelegatePlatformViewsIntegration) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  JniDelegate delegate(mock_invoker);

  auto mem_provider = std::make_shared<InMemoryPlatformViewsProvider>();
  delegate.SetPlatformViewsProvider(mem_provider);
  EXPECT_EQ(delegate.GetPlatformViewsProvider(), mem_provider);
  EXPECT_NE(delegate.GetPlatformViewsController(), nullptr);

  // Test forwarding through JniDelegate
  PlatformViewCreationParams params = {
      .view_id = 99,
      .view_type = "delegate.view",
      .width = 100.0,
      .height = 100.0,
  };
  EXPECT_EQ(delegate.CreatePlatformView(
                params, PlatformViewCompositionType::kHybridComposition),
            0);
  EXPECT_TRUE(mem_provider->IsViewCreated(99));

  PlatformViewResizeRequest resize_req = {
      .view_id = 99, .width = 200.0, .height = 200.0};
  EXPECT_TRUE(delegate.ResizePlatformView(resize_req));
  EXPECT_TRUE(delegate.OffsetPlatformView(99, 5.0, 10.0));
  EXPECT_TRUE(delegate.SetPlatformViewDirection(99, 1));
  EXPECT_TRUE(delegate.ClearPlatformViewFocus(99));

  PlatformViewTouch touch = {.view_id = 99};
  EXPECT_TRUE(delegate.DispatchPlatformViewTouch(touch));

  PlatformViewGeometry geom = {.view_id = 99, .width = 200, .height = 200};
  EXPECT_TRUE(delegate.OnDisplayPlatformView(geom));
  EXPECT_TRUE(delegate.HidePlatformView(99));
  EXPECT_TRUE(delegate.SynchronizeToNativeViewHierarchy(true));
  EXPECT_TRUE(delegate.OnBeginFrame());
  EXPECT_TRUE(delegate.OnEndFrame());

  auto overlay = delegate.CreateOverlaySurface();
  ASSERT_TRUE(overlay.has_value());
  if (overlay.has_value()) {
    PlatformViewOverlay pvo = {
        .surface_id = *overlay, .width = 200, .height = 200};
    EXPECT_TRUE(delegate.OnDisplayOverlaySurface(pvo));
    EXPECT_TRUE(delegate.ShowOverlaySurface(*overlay));
    EXPECT_TRUE(delegate.HideOverlaySurface(*overlay));
  }
  EXPECT_TRUE(delegate.DestroyOverlaySurfaces());

  EXPECT_TRUE(delegate.CreatePlatformViewTransaction());
  EXPECT_TRUE(delegate.SwapPlatformViewTransactions());
  EXPECT_TRUE(delegate.ApplyPlatformViewTransactions());
  EXPECT_FALSE(delegate.IsHcppEnabled());

  EXPECT_TRUE(delegate.DisposePlatformView(99));
  EXPECT_FALSE(mem_provider->IsViewCreated(99));
}

TEST(PlatformViewsTest, JniRouterPlatformViewsDirectRouting) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto embedder_delegate = std::make_shared<JniDelegate>(mock_invoker);
  auto mem_provider = std::make_shared<InMemoryPlatformViewsProvider>();
  embedder_delegate->SetPlatformViewsProvider(mem_provider);

  auto legacy_delegate = std::make_shared<StrictMock<MockLegacyJniDelegate>>();
  auto router = std::make_unique<JniRouter>(embedder_delegate, legacy_delegate);

  PlatformViewCreationParams params = {
      .view_id = 88,
      .view_type = "routed.view",
      .width = 100.0,
      .height = 100.0,
  };
  PlatformViewResizeRequest resize_req = {
      .view_id = 88, .width = 200.0, .height = 200.0};
  PlatformViewTouch touch = {.view_id = 88};
  PlatformViewGeometry geom = {.view_id = 88};
  AndroidMutatorsStack stack;

  // Across both flag states (false and true), all platform view methods route
  // directly to embedder_delegate
  for (bool embedder_flag : {false, true}) {
    JniRouter::SetEmbedderEnabled(embedder_flag);

    EXPECT_EQ(router->RouteCreatePlatformView(
                  params, PlatformViewCompositionType::kHybridComposition),
              0);
    EXPECT_TRUE(mem_provider->IsViewCreated(88));

    EXPECT_TRUE(router->RouteResizePlatformView(resize_req));
    EXPECT_TRUE(router->RouteOffsetPlatformView(88, 10.0, 20.0));
    EXPECT_TRUE(router->RouteSetPlatformViewDirection(88, 1));
    EXPECT_TRUE(router->RouteClearPlatformViewFocus(88));
    EXPECT_TRUE(router->RouteDispatchPlatformViewTouch(touch));
    EXPECT_TRUE(router->RouteOnDisplayPlatformView(geom));
    EXPECT_TRUE(router->RouteHidePlatformView(88));
    EXPECT_TRUE(router->RouteSynchronizeToNativeViewHierarchy(true));
    EXPECT_TRUE(router->RouteBeginFrame());
    EXPECT_TRUE(router->RouteEndFrame());

    auto created_overlay = router->RouteCreateOverlaySurface();
    ASSERT_TRUE(created_overlay.has_value());
    if (created_overlay.has_value()) {
      PlatformViewOverlay routed_overlay = {.surface_id = *created_overlay};
      EXPECT_TRUE(router->RouteOnDisplayOverlaySurface(routed_overlay));
      EXPECT_TRUE(router->RouteShowOverlaySurface(*created_overlay));
      EXPECT_TRUE(router->RouteHideOverlaySurface(*created_overlay));
    }
    EXPECT_TRUE(router->RouteDestroyOverlaySurfaces());

    EXPECT_TRUE(router->RouteCreatePlatformViewTransaction());
    EXPECT_TRUE(router->RouteSwapPlatformViewTransactions());
    EXPECT_TRUE(router->RouteApplyPlatformViewTransactions());
    EXPECT_FALSE(router->RouteIsHcppEnabled());

    EXPECT_TRUE(router->RoutePlatformViewMutators(88, 0, 0, 100, 100, stack));

    EXPECT_TRUE(router->RouteDisposePlatformView(88));
    EXPECT_FALSE(mem_provider->IsViewCreated(88));
  }

  JniRouter::SetEmbedderEnabled(true);
}

TEST(PlatformViewsTest, FlutterEmbedderNativePlatformViewsIntegration) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  FlutterEmbedderNative native(mock_invoker);
  auto mem_provider = std::make_shared<InMemoryPlatformViewsProvider>();
  native.SetPlatformViewsProvider(mem_provider);

  JniRouter::SetEmbedderEnabled(true);

  EXPECT_EQ(native.GetPlatformViewsProvider(), mem_provider);
  EXPECT_NE(native.GetPlatformViewsController(), nullptr);

  PlatformViewCreationParams params = {
      .view_id = 77,
      .view_type = "embedder.native.view",
      .width = 320.0,
      .height = 240.0,
  };
  EXPECT_EQ(native.CreatePlatformView(
                params, PlatformViewCompositionType::kHybridComposition),
            0);
  EXPECT_TRUE(mem_provider->IsViewCreated(77));

  PlatformViewResizeRequest resize_req = {
      .view_id = 77, .width = 400.0, .height = 300.0};
  EXPECT_TRUE(native.ResizePlatformView(resize_req));
  EXPECT_TRUE(native.OffsetPlatformView(77, 12.0, 14.0));
  EXPECT_TRUE(native.SetPlatformViewDirection(77, 0));
  EXPECT_TRUE(native.ClearPlatformViewFocus(77));

  PlatformViewTouch touch = {.view_id = 77};
  EXPECT_TRUE(native.DispatchPlatformViewTouch(touch));

  FlutterPlatformViewMutation m1 = {
      .type = kFlutterPlatformViewMutationTypeOpacity,
      .opacity = 0.9,
  };
  const FlutterPlatformViewMutation* mutations[] = {&m1};
  FlutterPlatformView pv = {
      .struct_size = sizeof(FlutterPlatformView),
      .identifier = 77,
      .mutations_count = 1,
      .mutations = mutations,
  };
  EXPECT_TRUE(native.OnDisplayPlatformView(pv, 0, 0, 400, 300, 400, 300));
  EXPECT_TRUE(native.PushPlatformViewMutators(pv, 0, 0, 400, 300));

  EXPECT_TRUE(native.HidePlatformView(77));
  EXPECT_TRUE(native.SynchronizeToNativeViewHierarchy(true));
  EXPECT_TRUE(native.OnBeginFrame());
  EXPECT_TRUE(native.OnEndFrame());

  auto overlay = native.CreateOverlaySurface();
  ASSERT_TRUE(overlay.has_value());
  if (overlay.has_value()) {
    PlatformViewOverlay pvo = {
        .surface_id = *overlay, .width = 400, .height = 300};
    EXPECT_TRUE(native.OnDisplayOverlaySurface(pvo));
    EXPECT_TRUE(native.ShowOverlaySurface(*overlay));
    EXPECT_TRUE(native.HideOverlaySurface(*overlay));
  }
  EXPECT_TRUE(native.DestroyOverlaySurfaces());

  EXPECT_TRUE(native.CreatePlatformViewTransaction());
  EXPECT_TRUE(native.SwapPlatformViewTransactions());
  EXPECT_TRUE(native.ApplyPlatformViewTransactions());
  EXPECT_FALSE(native.IsHcppEnabled());

  EXPECT_TRUE(native.DisposePlatformView(77));
  EXPECT_FALSE(mem_provider->IsViewCreated(77));

  JniRouter::SetEmbedderEnabled(false);
}

TEST(PlatformViewsTest, ThreadSafeConcurrentPlatformViewsOperations) {
  auto mem_provider = std::make_shared<InMemoryPlatformViewsProvider>();
  AndroidPlatformViewsController controller(mem_provider);

  constexpr int kNumThreads = 8;
  constexpr int kOpsPerThread = 100;
  std::vector<std::thread> threads;
  threads.reserve(kNumThreads);

  for (int t = 0; t < kNumThreads; ++t) {
    threads.emplace_back([&controller, t]() {
      for (int i = 0; i < kOpsPerThread; ++i) {
        int64_t view_id = (t * 1000) + i;
        PlatformViewCreationParams params = {
            .view_id = view_id,
            .view_type = "thread.safe.view",
            .width = 100.0 + i,
            .height = 100.0 + i,
        };
        controller.CreatePlatformView(
            params, (i % 2 == 0)
                        ? PlatformViewCompositionType::kTextureLayer
                        : PlatformViewCompositionType::kHybridComposition);

        controller.OffsetPlatformView(view_id, i, i);
        controller.SetDirection(view_id, i % 2);
        controller.ClearFocus(view_id);

        PlatformViewTouch touch = {
            .view_id = view_id,
            .motion_event_id = i,
            .action = 0,
        };
        controller.DispatchTouchEvent(touch);

        AndroidMutatorsStack stack;
        stack.PushOpacity(0.5f);
        controller.OnDisplayPlatformView(view_id, 0, 0, 100, 100, 100, 100,
                                         stack);

        controller.HidePlatformView(view_id);
        controller.DisposePlatformView(view_id);
      }
    });
  }

  for (auto& thread : threads) {
    thread.join();
  }

  EXPECT_EQ(controller.GetActiveViewsCount(), 0u);
}

// ---------------------------------------------------------------------------
// WindowMetricsTranslationTest (Phase 2.7)
// ---------------------------------------------------------------------------

TEST(WindowMetricsTranslationTest, JniDelegateWindowMetricsOperations) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto delegate = std::make_shared<JniDelegate>(mock_invoker);

  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("onViewportMetrics", "(IDDD)V", _))
      .Times(2)
      .WillRepeatedly(Return(true));
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("onDisplayMetrics", "(JDDDF)V", _))
      .Times(2)
      .WillRepeatedly(Return(true));

  AndroidViewportMetrics vp;
  vp.view_id = 0;
  vp.physical_width = 1080.0;
  vp.physical_height = 1920.0;
  vp.device_pixel_ratio = 2.625;

  AndroidDisplayMetrics disp;
  disp.display_id = 0;
  disp.refresh_rate = 60.0;
  disp.width = 1080.0;
  disp.height = 1920.0;
  disp.device_pixel_ratio = 2.625;

  EXPECT_TRUE(delegate->SetViewportMetrics(vp));
  EXPECT_TRUE(delegate->UpdateDisplayMetrics(disp));
  EXPECT_TRUE(delegate->UpdateDisplayMetrics(0, 90.0, 1080.0, 1920.0, 2.625));
  EXPECT_TRUE(delegate->DispatchViewportMetrics(0, 1080.0, 1920.0, 2.625));

  auto cached_vp = delegate->GetViewportMetrics(0);
  ASSERT_TRUE(cached_vp.has_value());
  if (cached_vp.has_value()) {
    EXPECT_EQ(cached_vp.value(), vp);
  }

  auto cached_disp = delegate->GetDisplayMetrics(0);
  ASSERT_TRUE(cached_disp.has_value());
  if (cached_disp.has_value()) {
    EXPECT_DOUBLE_EQ(cached_disp->refresh_rate, 90.0);
  }
}

TEST(WindowMetricsTranslationTest, JniRouterWindowMetricsRoutingFlip) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto in_memory_provider = std::make_shared<InMemoryWindowMetricsProvider>();
  auto embedder_delegate = std::make_shared<JniDelegate>(
      mock_invoker, nullptr, nullptr, nullptr, in_memory_provider);
  auto legacy_delegate = std::make_shared<StrictMock<MockLegacyJniDelegate>>();

  JniRouter router(embedder_delegate, legacy_delegate);

  AndroidViewportMetrics vp;
  vp.view_id = 7;
  vp.physical_width = 1440.0;
  vp.physical_height = 3040.0;
  vp.device_pixel_ratio = 3.5;

  AndroidDisplayMetrics disp;
  disp.display_id = 1;
  disp.refresh_rate = 120.0;
  disp.width = 1440.0;
  disp.height = 3040.0;
  disp.device_pixel_ratio = 3.5;

  // 1. Legacy routing
  JniRouter::SetEmbedderEnabled(false);
  EXPECT_EQ(router.GetActiveRoutingPath(), JniRouter::RoutingPath::kLegacy);

  EXPECT_CALL(*legacy_delegate, SetViewportMetrics(vp)).WillOnce(Return(true));
  EXPECT_CALL(*legacy_delegate, UpdateDisplayMetrics(disp))
      .WillOnce(Return(true));
  EXPECT_CALL(*legacy_delegate,
              UpdateDisplayMetrics(1, 120.0, 1440.0, 3040.0, 3.5))
      .WillOnce(Return(true));
  EXPECT_CALL(*legacy_delegate, DispatchViewportMetrics(7, 1440.0, 3040.0, 3.5))
      .WillOnce(Return(true));

  EXPECT_TRUE(router.RouteSetViewportMetrics(vp));
  EXPECT_TRUE(router.RouteUpdateDisplayMetrics(disp));
  EXPECT_TRUE(router.RouteUpdateDisplayMetrics(1, 120.0, 1440.0, 3040.0, 3.5));
  EXPECT_TRUE(router.RouteViewportMetrics(7, 1440.0, 3040.0, 3.5));

  // 2. Embedder routing
  JniRouter::SetEmbedderEnabled(true);
  EXPECT_EQ(router.GetActiveRoutingPath(), JniRouter::RoutingPath::kEmbedder);

  EXPECT_TRUE(router.RouteSetViewportMetrics(vp));
  EXPECT_TRUE(router.RouteUpdateDisplayMetrics(disp));
  EXPECT_TRUE(router.RouteUpdateDisplayMetrics(1, 120.0, 1440.0, 3040.0, 3.5));
  EXPECT_TRUE(router.RouteViewportMetrics(7, 1440.0, 3040.0, 3.5));

  EXPECT_EQ(in_memory_provider->GetSendCount(), 2u);
  EXPECT_EQ(in_memory_provider->GetUpdateCount(), 2u);

  JniRouter::SetEmbedderEnabled(false);
}

TEST(WindowMetricsTranslationTest,
     FlutterEmbedderNativeWindowMetricsIntegration) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto in_memory_provider = std::make_shared<InMemoryWindowMetricsProvider>();

  FlutterEmbedderNative native(mock_invoker, nullptr, nullptr, nullptr, nullptr,
                               nullptr, nullptr, nullptr, in_memory_provider);

  AndroidViewportMetrics vp;
  vp.view_id = 0;
  vp.physical_width = 1080.0;
  vp.physical_height = 2400.0;
  vp.device_pixel_ratio = 2.75;
  vp.physical_min_width = 800.0;
  vp.physical_max_width = 1200.0;

  AndroidDisplayMetrics disp;
  disp.display_id = 0;
  disp.refresh_rate = 90.0;
  disp.width = 1080.0;
  disp.height = 2400.0;
  disp.device_pixel_ratio = 2.75;

  FlutterWindowMetricsEvent c_event = native.TranslateViewportMetrics(vp);
  EXPECT_EQ(c_event.width, 1080u);
  EXPECT_EQ(c_event.height, 2400u);
  EXPECT_TRUE(c_event.has_constraints);
  EXPECT_EQ(c_event.min_width_constraint, 800u);
  EXPECT_EQ(c_event.max_width_constraint, 1200u);

  FlutterEngineDisplay c_disp = native.TranslateDisplayMetrics(disp);
  EXPECT_EQ(c_disp.width, 1080u);
  EXPECT_EQ(c_disp.height, 2400u);
  EXPECT_DOUBLE_EQ(c_disp.refresh_rate, 90.0);

  FlutterEmbedderNative::SetEmbedderEnabled(true);
  EXPECT_TRUE(native.SetViewportMetrics(vp));
  EXPECT_TRUE(native.UpdateDisplayMetrics(disp));
  EXPECT_TRUE(native.UpdateDisplayMetrics(0, 120.0, 1080.0, 2400.0, 2.75));

  EXPECT_EQ(in_memory_provider->GetSendCount(), 1u);
  EXPECT_EQ(in_memory_provider->GetUpdateCount(), 2u);

  EXPECT_EQ(native.SendWindowMetricsEvent(nullptr, &c_event),
            kInvalidArguments);
  EXPECT_EQ(native.SendWindowMetricsEvent(nullptr, vp), kInvalidArguments);
  EXPECT_EQ(native.NotifyDisplayUpdate(
                nullptr, kFlutterEngineDisplaysUpdateTypeStartup, &c_disp, 1),
            kInvalidArguments);
  EXPECT_EQ(native.NotifyDisplayUpdate(nullptr, disp), kInvalidArguments);

  FlutterEmbedderNative::SetEmbedderEnabled(false);
}

// ---------------------------------------------------------------------------
// VsyncRoutingTest (Phase 2.8 AChoreographer VSync Routing)
// ---------------------------------------------------------------------------

TEST(VsyncRoutingTest, JniDelegateVsyncOperations) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto mock_choreographer =
      std::make_shared<InMemoryAndroidChoreographerProvider>();
  auto vsync_waiter =
      std::make_shared<AndroidVsyncWaiter>(mock_choreographer, mock_invoker);
  auto delegate = std::make_shared<JniDelegate>(mock_invoker, nullptr, nullptr,
                                                nullptr, nullptr, vsync_waiter);

  EXPECT_EQ(delegate->GetVsyncWaiter(), vsync_waiter);

  // 1. OnVsync dispatches to JVM
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("onVsync", "(JJ)V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->OnVsync(1000000LL, 2000000LL));

  // 2. AsyncWaitForVsync routes to AndroidVsyncWaiter
  EXPECT_TRUE(delegate->AsyncWaitForVsync(777));
  EXPECT_EQ(vsync_waiter->GetVsyncRequestCount(), 1u);
  EXPECT_TRUE(mock_choreographer->HasPendingCallbacks());

  // 3. Trigger AChoreographer callback
  intptr_t delivered_baton = 0;
  vsync_waiter->SetVsyncResultCallback(
      [&](intptr_t baton, int64_t start, int64_t target) {
        delivered_baton = baton;
      });
  mock_choreographer->TriggerPendingCallbacks(3000000LL);
  EXPECT_EQ(delivered_baton, 777);
  EXPECT_EQ(vsync_waiter->GetVsyncDeliveredCount(), 1u);
}

TEST(VsyncRoutingTest, JniRouterVsyncRoutingFlip) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto mock_choreographer =
      std::make_shared<InMemoryAndroidChoreographerProvider>();
  auto vsync_waiter =
      std::make_shared<AndroidVsyncWaiter>(mock_choreographer, mock_invoker);
  auto embedder_delegate = std::make_shared<JniDelegate>(
      mock_invoker, nullptr, nullptr, nullptr, nullptr, vsync_waiter);
  auto legacy_delegate = std::make_shared<MockLegacyJniDelegate>();

  JniRouter router(embedder_delegate, legacy_delegate);

  // 1. Legacy routing (Embedder disabled)
  JniRouter::SetEmbedderEnabled(false);
  EXPECT_EQ(router.GetActiveRoutingPath(), JniRouter::RoutingPath::kLegacy);

  EXPECT_CALL(*legacy_delegate, OnVsync(5000LL, 10000LL))
      .WillOnce(Return(true));
  EXPECT_CALL(*legacy_delegate, AsyncWaitForVsync(123)).WillOnce(Return(true));

  EXPECT_TRUE(router.RouteVsync(5000LL, 10000LL));
  EXPECT_TRUE(router.RouteAsyncWaitForVsync(123));

  // 2. Embedder routing (Embedder enabled)
  JniRouter::SetEmbedderEnabled(true);
  EXPECT_EQ(router.GetActiveRoutingPath(), JniRouter::RoutingPath::kEmbedder);

  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("onVsync", "(JJ)V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(router.RouteVsync(5000LL, 10000LL));

  EXPECT_TRUE(router.RouteAsyncWaitForVsync(456));
  EXPECT_EQ(vsync_waiter->GetVsyncRequestCount(), 1u);
  EXPECT_TRUE(mock_choreographer->HasPendingCallbacks());

  JniRouter::SetEmbedderEnabled(false);
}

TEST(VsyncRoutingTest, FlutterEmbedderNativeVsyncIntegration) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto mock_choreographer =
      std::make_shared<InMemoryAndroidChoreographerProvider>();
  auto vsync_waiter =
      std::make_shared<AndroidVsyncWaiter>(mock_choreographer, mock_invoker);

  FlutterEmbedderNative native(mock_invoker, nullptr, nullptr, nullptr, nullptr,
                               nullptr, nullptr, nullptr, nullptr,
                               mock_choreographer, vsync_waiter);

  EXPECT_EQ(native.GetChoreographerProvider(), mock_choreographer);
  EXPECT_EQ(native.GetVsyncWaiter(), vsync_waiter);

  FlutterEmbedderNative::SetEmbedderEnabled(true);

  // Test static C-API vsync callback
  intptr_t delivered_baton = 0;
  int64_t delivered_start = 0;
  int64_t delivered_target = 0;
  vsync_waiter->SetVsyncResultCallback(
      [&](intptr_t baton, int64_t start, int64_t target) {
        delivered_baton = baton;
        delivered_start = start;
        delivered_target = target;
      });

  FlutterEmbedderNative::OnVsyncCallback(&native, 8888);
  EXPECT_EQ(vsync_waiter->GetVsyncRequestCount(), 1u);
  EXPECT_TRUE(mock_choreographer->HasPendingCallbacks());

  mock_choreographer->TriggerPendingCallbacks(10000000LL);
  EXPECT_EQ(delivered_baton, 8888);
  EXPECT_EQ(delivered_start, 10000000LL);
  EXPECT_EQ(delivered_target, 10000000LL + 16666666LL);

  // Test direct NotifyVsync
  EXPECT_EQ(native.NotifyVsync(nullptr, 8888, 10000000LL, 26666666LL),
            kInvalidArguments);

  FlutterEmbedderNative::SetEmbedderEnabled(false);
}

TEST(VsyncRoutingTest, FlutterEmbedderNativeVsync120HzPacing) {
  auto mock_choreographer =
      std::make_shared<InMemoryAndroidChoreographerProvider>();
  auto vsync_waiter = std::make_shared<AndroidVsyncWaiter>(mock_choreographer);

  FlutterEmbedderNative native(
      std::make_shared<DefaultJvmInvoker>(), nullptr, nullptr, nullptr, nullptr,
      nullptr, nullptr, nullptr, nullptr, mock_choreographer, vsync_waiter);

  // Set 120Hz display refresh rate
  native.UpdateRefreshRate(120.0);
  EXPECT_DOUBLE_EQ(native.GetRefreshRate(), 120.0);
  EXPECT_EQ(native.GetRefreshPeriodNanos(), 8333333LL);

  auto pacing_info = native.ComputeFramePacing(100000000LL, 120.0);
  EXPECT_DOUBLE_EQ(pacing_info.refresh_rate_hz, 120.0);
  EXPECT_EQ(pacing_info.refresh_period_nanos, 8333333LL);
  EXPECT_EQ(
      pacing_info.frame_target_time_nanos - pacing_info.frame_start_time_nanos,
      8333333LL);

  int64_t result_target = 0;
  vsync_waiter->SetVsyncResultCallback(
      [&](intptr_t baton, int64_t start, int64_t target) {
        result_target = target;
      });

  EXPECT_TRUE(native.AsyncWaitForVsync(120));
  mock_choreographer->TriggerPendingCallbacks(50000000LL);
  EXPECT_EQ(result_target, 50000000LL + 8333333LL);
}

// ---------------------------------------------------------------------------
// GlobalVMInitializationTest (Phase 2.9 Global VM Initialization)
// ---------------------------------------------------------------------------

TEST(GlobalVMInitializationTest, JniDelegateVMOperations) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto font_provider = std::make_shared<InMemoryFontCollectionProvider>();
  auto aot_provider = std::make_shared<InMemoryAndroidAOTProvider>();
  auto vm_init = std::make_shared<AndroidVMInit>(mock_invoker, font_provider,
                                                 aot_provider);

  auto delegate = std::make_shared<JniDelegate>(
      mock_invoker, nullptr, nullptr, nullptr, nullptr, nullptr, vm_init);

  EXPECT_EQ(delegate->GetVMInit(), vm_init);
  EXPECT_FALSE(delegate->IsVMInitialized());
  EXPECT_FALSE(delegate->GetVMArgs().has_value());

  AndroidVMArgs args;
  args.command_line_args = {"--enable-impeller=true", "--verbose-logging"};
  args.aot_library_path = "/data/app/lib/arm64/libapp.so";
  args.icu_data_path = "/data/flutter/icudtl.dat";
  args.engine_caches_path = "/data/user/cache";
  args.api_level = 34;

  EXPECT_TRUE(delegate->InitVM(args));
  EXPECT_TRUE(delegate->IsVMInitialized());
  auto vm_args = delegate->GetVMArgs();
  ASSERT_TRUE(vm_args.has_value());
  if (vm_args.has_value()) {
    EXPECT_EQ(vm_args.value(), args);
  }

  // Prefetch fonts
  EXPECT_TRUE(delegate->PrefetchDefaultFontManager());
  EXPECT_TRUE(font_provider->IsPrefetched());
  EXPECT_EQ(font_provider->GetPrefetchCount(), 1u);

  // Set VM Service URI -> dispatches to JVM
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("setVmServiceUri", "(Ljava/lang/String;)V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->SetVmServiceUri("http://127.0.0.1:54321/auth/"));
  EXPECT_EQ(delegate->GetVmServiceUri(), "http://127.0.0.1:54321/auth/");
}

TEST(GlobalVMInitializationTest, JniRouterVMRoutingFlip) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto font_provider = std::make_shared<InMemoryFontCollectionProvider>();
  auto aot_provider = std::make_shared<InMemoryAndroidAOTProvider>();
  auto vm_init = std::make_shared<AndroidVMInit>(mock_invoker, font_provider,
                                                 aot_provider);

  auto embedder_delegate = std::make_shared<JniDelegate>(
      mock_invoker, nullptr, nullptr, nullptr, nullptr, nullptr, vm_init);
  auto legacy_delegate = std::make_shared<MockLegacyJniDelegate>();

  JniRouter router(embedder_delegate, legacy_delegate);

  AndroidVMArgs args;
  args.command_line_args = {"--test-arg"};
  args.api_level = 34;

  // 1. Legacy routing (Embedder disabled)
  JniRouter::SetEmbedderEnabled(false);
  EXPECT_EQ(router.GetActiveRoutingPath(), JniRouter::RoutingPath::kLegacy);

  EXPECT_CALL(*legacy_delegate, InitVM(args)).WillOnce(Return(true));
  EXPECT_CALL(*legacy_delegate, PrefetchDefaultFontManager())
      .WillOnce(Return(true));
  EXPECT_CALL(*legacy_delegate, SetVmServiceUri("http://legacy:8181/"))
      .WillOnce(Return(true));

  EXPECT_TRUE(router.RouteInitVM(args));
  EXPECT_TRUE(router.RoutePrefetchDefaultFontManager());
  EXPECT_TRUE(router.RouteSetVmServiceUri("http://legacy:8181/"));

  // 2. Embedder routing (Embedder enabled)
  JniRouter::SetEmbedderEnabled(true);
  EXPECT_EQ(router.GetActiveRoutingPath(), JniRouter::RoutingPath::kEmbedder);

  EXPECT_TRUE(router.RouteInitVM(args));
  EXPECT_TRUE(embedder_delegate->IsVMInitialized());

  EXPECT_TRUE(router.RoutePrefetchDefaultFontManager());
  EXPECT_TRUE(font_provider->IsPrefetched());
  EXPECT_EQ(font_provider->GetPrefetchCount(), 1u);

  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("setVmServiceUri", "(Ljava/lang/String;)V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(router.RouteSetVmServiceUri("http://embedder:8181/"));
  EXPECT_EQ(embedder_delegate->GetVmServiceUri(), "http://embedder:8181/");

  JniRouter::SetEmbedderEnabled(false);
}

TEST(GlobalVMInitializationTest, FlutterEmbedderNativeVMIntegration) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto font_provider = std::make_shared<InMemoryFontCollectionProvider>();
  auto aot_provider = std::make_shared<InMemoryAndroidAOTProvider>();
  auto vm_init = std::make_shared<AndroidVMInit>(mock_invoker, font_provider,
                                                 aot_provider);

  FlutterEmbedderNative native(mock_invoker, nullptr, nullptr, nullptr, nullptr,
                               nullptr, nullptr, nullptr, nullptr, nullptr,
                               nullptr, font_provider, aot_provider, vm_init);

  EXPECT_EQ(native.GetVMInit(), vm_init);
  EXPECT_EQ(native.GetFontCollectionProvider(), font_provider);
  EXPECT_EQ(native.GetAOTProvider(), aot_provider);

  FlutterEmbedderNative::SetEmbedderEnabled(true);

  AndroidVMArgs args;
  args.command_line_args = {"--enable-impeller=true"};
  args.aot_library_path = "/data/app/lib/arm64/libapp.so";
  args.icu_data_path = "/data/flutter/icudtl.dat";
  args.engine_caches_path = "/data/user/cache";
  args.api_level = 34;

  EXPECT_TRUE(native.InitVM(args));
  EXPECT_TRUE(native.IsVMInitialized());
  EXPECT_TRUE(native.GetVMArgs().has_value());
  EXPECT_EQ(native.GetSelectedRenderingAPI(),
            AndroidRenderingAPI::kImpellerAutoselect);

  const FlutterProjectArgs* project_args = native.GetProjectArgs();
  ASSERT_NE(project_args, nullptr);
  EXPECT_STREQ(project_args->icu_data_path, "/data/flutter/icudtl.dat");
  EXPECT_NE(project_args->aot_data, nullptr);

  // Font prefetching
  EXPECT_TRUE(native.PrefetchDefaultFontManager());
  EXPECT_TRUE(font_provider->IsPrefetched());
  EXPECT_EQ(font_provider->GetPrefetchCount(), 1u);

  // Set VM Service URI
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("setVmServiceUri", "(Ljava/lang/String;)V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(native.SetVmServiceUri("http://127.0.0.1:4321/auth/"));
  EXPECT_EQ(native.GetVmServiceUri(), "http://127.0.0.1:4321/auth/");

  // Engine initialization error checking
  EXPECT_EQ(native.InitializeEngine(nullptr, nullptr, nullptr, nullptr),
            kInvalidArguments);
  EXPECT_EQ(native.DeinitializeEngine(nullptr), kInvalidArguments);

  // AOT data operations
  FlutterEngineAOTDataSource source = {};
  source.type = kFlutterEngineAOTDataSourceTypeElfPath;
  source.elf_path = "/data/app/lib/arm64/libapp.so";

  FlutterEngineAOTData aot_handle = nullptr;
  EXPECT_EQ(native.CreateAOTData(&source, &aot_handle), kSuccess);
  EXPECT_NE(aot_handle, nullptr);
  EXPECT_EQ(native.CollectAOTData(aot_handle), kSuccess);

  EXPECT_EQ(native.CreateAOTData(nullptr, nullptr), kInvalidArguments);
  EXPECT_EQ(native.CollectAOTData(nullptr), kInvalidArguments);

  FlutterEmbedderNative::SetEmbedderEnabled(false);
}

TEST(GlobalVMInitializationTest,
     FlutterEmbedderNativeAOTAndProjectArgsGeneration) {
  auto aot_provider = std::make_shared<InMemoryAndroidAOTProvider>();
  auto font_provider = std::make_shared<InMemoryFontCollectionProvider>();

  FlutterEmbedderNative native(std::make_shared<DefaultJvmInvoker>(), nullptr,
                               nullptr, nullptr, nullptr, nullptr, nullptr,
                               nullptr, nullptr, nullptr, nullptr,
                               font_provider, aot_provider);

  FlutterEmbedderNative::SetEmbedderEnabled(true);

  const uint8_t vm_data[] = {1, 2, 3};
  const uint8_t vm_instr[] = {4, 5, 6};
  const uint8_t iso_data[] = {7, 8, 9};
  const uint8_t iso_instr[] = {10, 11, 12};

  AndroidVMArgs args;
  args.command_line_args = {"--flag1", "--flag2=value"};
  args.icu_data_path = "/system/etc/icudtl.dat";
  args.engine_caches_path = "/data/user/persistent_cache";
  args.is_persistent_cache_read_only = true;
  args.dart_old_gen_heap_size = 1024;
  args.log_tag = "test_engine_tag";
  args.aot_vm_snapshot_data = vm_data;
  args.aot_vm_snapshot_data_size = sizeof(vm_data);
  args.aot_vm_snapshot_instructions = vm_instr;
  args.aot_vm_snapshot_instructions_size = sizeof(vm_instr);
  args.aot_isolate_snapshot_data = iso_data;
  args.aot_isolate_snapshot_data_size = sizeof(iso_data);
  args.aot_isolate_snapshot_instructions = iso_instr;
  args.aot_isolate_snapshot_instructions_size = sizeof(iso_instr);
  args.api_level = 34;

  EXPECT_TRUE(native.InitVM(args));

  const FlutterProjectArgs* project_args = native.GetProjectArgs();
  ASSERT_NE(project_args, nullptr);
  EXPECT_EQ(project_args->struct_size, sizeof(FlutterProjectArgs));
  EXPECT_STREQ(project_args->icu_data_path, "/system/etc/icudtl.dat");
  EXPECT_STREQ(project_args->persistent_cache_path,
               "/data/user/persistent_cache");
  EXPECT_TRUE(project_args->is_persistent_cache_read_only);
  EXPECT_EQ(project_args->dart_old_gen_heap_size, 1024);
  EXPECT_STREQ(project_args->log_tag, "test_engine_tag");
  EXPECT_EQ(project_args->command_line_argc, 3);
  EXPECT_STREQ(project_args->command_line_argv[0], "flutter");
  EXPECT_STREQ(project_args->command_line_argv[1], "--flag1");
  EXPECT_STREQ(project_args->command_line_argv[2], "--flag2=value");

  EXPECT_EQ(project_args->vm_snapshot_data, vm_data);
  EXPECT_EQ(project_args->vm_snapshot_data_size, sizeof(vm_data));
  EXPECT_EQ(project_args->vm_snapshot_instructions, vm_instr);
  EXPECT_EQ(project_args->vm_snapshot_instructions_size, sizeof(vm_instr));
  EXPECT_EQ(project_args->isolate_snapshot_data, iso_data);
  EXPECT_EQ(project_args->isolate_snapshot_data_size, sizeof(iso_data));
  EXPECT_EQ(project_args->isolate_snapshot_instructions, iso_instr);
  EXPECT_EQ(project_args->isolate_snapshot_instructions_size,
            sizeof(iso_instr));

  FlutterEmbedderNative::SetEmbedderEnabled(false);
}

// =============================================================================
// HardwareBuffer Tests (Phase 3.1)
// =============================================================================

TEST(HardwareBufferTest, JniDelegateHardwareBufferOperations) {
  auto mock_invoker = std::make_shared<StrictMock<MockJvmInvoker>>();
  auto hw_provider = std::make_shared<InMemoryAndroidHardwareBufferProvider>();

  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("registerHardwareBufferTexture", "(J)Z", _))
      .WillOnce(Return(true));
  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("unregisterHardwareBufferTexture", "(J)Z", _))
      .WillOnce(Return(true));
  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("onHardwareBufferFrameAvailable", "(J)Z", _))
      .WillOnce(Return(true));

  JniDelegate delegate(mock_invoker, nullptr, nullptr, nullptr, nullptr,
                       nullptr, nullptr, hw_provider);

  int64_t texture_id = 42;
  EXPECT_TRUE(delegate.RegisterHardwareBufferTexture(texture_id));

  // Allocate buffer and set frame
  auto desc = AndroidHardwareBufferDesc::MakeRGBA8(1280, 720);
  auto buffer = hw_provider->Allocate(desc);
  ASSERT_NE(buffer, nullptr);

  EXPECT_TRUE(delegate.SetHardwareBufferFrame(texture_id, std::move(buffer)));

  FlutterHardwareBufferExternalTexture frame_out = {};
  EXPECT_TRUE(delegate.GetHardwareBufferTextureFrame(texture_id, 1280, 720,
                                                     &frame_out));
  EXPECT_EQ(frame_out.width, 1280u);
  EXPECT_EQ(frame_out.height, 720u);
  EXPECT_EQ(frame_out.format, desc.format);
  EXPECT_NE(frame_out.buffer, nullptr);

  EXPECT_TRUE(delegate.OnHardwareBufferFrameAvailable(texture_id));
  EXPECT_TRUE(delegate.UnregisterHardwareBufferTexture(texture_id));

  // Verify frame is cleared after unregister
  FlutterHardwareBufferExternalTexture cleared_frame = {};
  EXPECT_FALSE(delegate.GetHardwareBufferTextureFrame(texture_id, 1280, 720,
                                                      &cleared_frame));
}

TEST(HardwareBufferTest, JniRouterHardwareBufferRoutingFlip) {
  auto mock_invoker = std::make_shared<StrictMock<MockJvmInvoker>>();
  auto mock_legacy = std::make_shared<StrictMock<MockLegacyJniDelegate>>();
  auto hw_provider = std::make_shared<InMemoryAndroidHardwareBufferProvider>();

  auto delegate =
      std::make_shared<JniDelegate>(mock_invoker, nullptr, nullptr, nullptr,
                                    nullptr, nullptr, nullptr, hw_provider);
  JniRouter router(delegate, mock_legacy);

  int64_t texture_id = 101;

  // Test with embedder flag = true
  FlutterEmbedderNative::SetEmbedderEnabled(true);
  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("registerHardwareBufferTexture", "(J)Z", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(router.RouteRegisterHardwareBufferTexture(texture_id));

  auto desc = AndroidHardwareBufferDesc::MakeRGBA8(1920, 1080);
  auto buffer = hw_provider->Allocate(desc);
  EXPECT_TRUE(
      router.RouteSetHardwareBufferFrame(texture_id, std::move(buffer)));

  FlutterHardwareBufferExternalTexture out_frame = {};
  EXPECT_TRUE(router.RouteGetHardwareBufferTextureFrame(texture_id, 1920, 1080,
                                                        &out_frame));
  EXPECT_EQ(out_frame.width, 1920u);
  EXPECT_EQ(out_frame.height, 1080u);

  // Test with embedder flag = false (legacy routing)
  FlutterEmbedderNative::SetEmbedderEnabled(false);
  EXPECT_CALL(*mock_legacy, RegisterHardwareBufferTexture(texture_id))
      .WillOnce(Return(true));
  EXPECT_TRUE(router.RouteRegisterHardwareBufferTexture(texture_id));

  EXPECT_CALL(*mock_legacy, OnHardwareBufferFrameAvailable(texture_id))
      .WillOnce(Return(true));
  EXPECT_TRUE(router.RouteOnHardwareBufferFrameAvailable(texture_id));

  EXPECT_CALL(*mock_legacy, UnregisterHardwareBufferTexture(texture_id))
      .WillOnce(Return(true));
  EXPECT_TRUE(router.RouteUnregisterHardwareBufferTexture(texture_id));
}

TEST(HardwareBufferTest, FlutterEmbedderNativeHardwareBufferIntegration) {
  FlutterEmbedderNative::SetEmbedderEnabled(true);

  auto mock_invoker = std::make_shared<StrictMock<MockJvmInvoker>>();
  auto mock_legacy = std::make_shared<StrictMock<MockLegacyJniDelegate>>();
  auto hw_provider = std::make_shared<InMemoryAndroidHardwareBufferProvider>();

  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("registerHardwareBufferTexture", "(J)Z", _))
      .WillOnce(Return(true));
  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("onHardwareBufferFrameAvailable", "(J)Z", _))
      .WillOnce(Return(true));
  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("unregisterHardwareBufferTexture", "(J)Z", _))
      .WillOnce(Return(true));

  FlutterEmbedderNative native(mock_invoker, mock_legacy, nullptr, nullptr,
                               nullptr, nullptr, nullptr, nullptr, nullptr,
                               nullptr, nullptr, nullptr, nullptr, nullptr,
                               hw_provider);

  EXPECT_EQ(native.GetHardwareBufferProvider(), hw_provider);

  int64_t texture_id = 999;
  auto desc = AndroidHardwareBufferDesc::MakeRGBA8(800, 600);
  auto buffer = hw_provider->Allocate(desc);

  EXPECT_TRUE(
      native.RegisterHardwareBufferTexture(texture_id, std::move(buffer)));

  FlutterHardwareBufferExternalTexture frame_out = {};
  EXPECT_TRUE(
      native.GetHardwareBufferTextureFrame(texture_id, 800, 600, &frame_out));
  EXPECT_EQ(frame_out.width, 800u);
  EXPECT_EQ(frame_out.height, 600u);
  EXPECT_EQ(frame_out.struct_size,
            sizeof(FlutterHardwareBufferExternalTexture));

  // Static C-API callback entry point
  FlutterHardwareBufferExternalTexture cb_frame_out = {};
  EXPECT_TRUE(
      FlutterEmbedderNative::OnHardwareBufferExternalTextureFrameCallback(
          &native, texture_id, 800, 600, &cb_frame_out));
  EXPECT_EQ(cb_frame_out.width, 800u);
  EXPECT_EQ(cb_frame_out.height, 600u);

  // Callback function pointer getter
  auto cb_fn = FlutterEmbedderNative::GetHardwareBufferFrameCallback();
  ASSERT_NE(cb_fn, nullptr);
  FlutterHardwareBufferExternalTexture fn_frame_out = {};
  EXPECT_TRUE(cb_fn(&native, texture_id, 800, 600, &fn_frame_out));
  EXPECT_EQ(fn_frame_out.width, 800u);

  EXPECT_TRUE(native.OnHardwareBufferFrameAvailable(texture_id));
  EXPECT_TRUE(native.UnregisterHardwareBufferTexture(texture_id));

  FlutterEmbedderNative::SetEmbedderEnabled(false);
}

TEST(HardwareBufferTest, FlutterEmbedderNativeExternalTextureEngineAPIs) {
  auto mock_invoker = std::make_shared<StrictMock<MockJvmInvoker>>();
  FlutterEmbedderNative native(mock_invoker);

  // Pass nullptr engine to verify argument validation
  EXPECT_EQ(native.MarkExternalTextureFrameAvailable(nullptr, 123),
            kInvalidArguments);
  EXPECT_EQ(native.RegisterExternalTexture(nullptr, 123), kInvalidArguments);
  EXPECT_EQ(native.UnregisterExternalTexture(nullptr, 123), kInvalidArguments);
}

TEST(HardwareBufferTest, DestructionCallbackLifecycle) {
  auto mock_invoker = std::make_shared<StrictMock<MockJvmInvoker>>();
  auto hw_provider = std::make_shared<InMemoryAndroidHardwareBufferProvider>();

  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("registerHardwareBufferTexture", "(J)Z", _))
      .WillOnce(Return(true));
  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("unregisterHardwareBufferTexture", "(J)Z", _))
      .WillOnce(Return(true));

  JniDelegate delegate(mock_invoker, nullptr, nullptr, nullptr, nullptr,
                       nullptr, nullptr, hw_provider);

  int64_t texture_id = 555;
  EXPECT_TRUE(delegate.RegisterHardwareBufferTexture(texture_id));

  static int g_destroyed_count = 0;
  g_destroyed_count = 0;

  auto callback = [](void* user_data) { g_destroyed_count++; };

  FlutterHardwareBufferExternalTexture frame1 = {};
  frame1.struct_size = sizeof(FlutterHardwareBufferExternalTexture);
  frame1.width = 100;
  frame1.height = 100;
  frame1.destruction_callback = callback;
  frame1.user_data = reinterpret_cast<void*>(0x1);

  EXPECT_TRUE(delegate.SetHardwareBufferFrame(texture_id, frame1));
  EXPECT_EQ(g_destroyed_count, 0);

  // Overwriting frame triggers destruction callback on frame1
  FlutterHardwareBufferExternalTexture frame2 = {};
  frame2.struct_size = sizeof(FlutterHardwareBufferExternalTexture);
  frame2.width = 200;
  frame2.height = 200;
  frame2.destruction_callback = callback;
  frame2.user_data = reinterpret_cast<void*>(0x2);

  EXPECT_TRUE(delegate.SetHardwareBufferFrame(texture_id, frame2));
  EXPECT_EQ(g_destroyed_count, 1);

  // Unregistering texture triggers destruction callback on frame2
  EXPECT_TRUE(delegate.UnregisterHardwareBufferTexture(texture_id));
  EXPECT_EQ(g_destroyed_count, 2);
}

TEST(VulkanExternalTextureTest, JniDelegateVulkanOperations) {
  auto mock_invoker = std::make_shared<StrictMock<MockJvmInvoker>>();
  auto vk_provider = std::make_shared<InMemoryAndroidVulkanTextureProvider>();

  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("registerVulkanTexture", "(J)Z", _))
      .WillOnce(Return(true));
  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("onVulkanTextureFrameAvailable", "(J)Z", _))
      .WillOnce(Return(true));
  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("unregisterVulkanTexture", "(J)Z", _))
      .WillOnce(Return(true));

  JniDelegate delegate(mock_invoker, nullptr, nullptr, nullptr, nullptr,
                       nullptr, nullptr, nullptr, vk_provider);

  EXPECT_EQ(delegate.GetVulkanTextureProvider(), vk_provider);

  int64_t texture_id = 999;
  EXPECT_TRUE(delegate.RegisterVulkanTexture(texture_id));

  // 1. Set frame using AndroidVulkanExternalTexture object
  auto desc = AndroidVulkanImageDesc::MakeRGBA8(1920, 1080);
  uint64_t expected_handle = 0;
  {
    auto tex_obj = vk_provider->AllocateTexture(desc);
    ASSERT_NE(tex_obj, nullptr);
    expected_handle = tex_obj->GetImageHandle();
    EXPECT_TRUE(delegate.SetVulkanTextureFrame(texture_id, std::move(tex_obj)));
  }

  FlutterVulkanExternalTexture out_frame = {};
  EXPECT_TRUE(
      delegate.GetVulkanTextureFrame(texture_id, 1920, 1080, &out_frame));
  EXPECT_EQ(out_frame.struct_size, sizeof(FlutterVulkanExternalTexture));
  EXPECT_EQ(out_frame.width, 1920u);
  EXPECT_EQ(out_frame.height, 1080u);
  EXPECT_EQ(out_frame.image, expected_handle);

  // 2. Set frame using FlutterVulkanExternalTexture struct directly
  FlutterVulkanExternalTexture direct_frame = {};
  direct_frame.struct_size = sizeof(FlutterVulkanExternalTexture);
  direct_frame.width = 1280;
  direct_frame.height = 720;
  direct_frame.image = 0x5555;
  direct_frame.format =
      static_cast<uint32_t>(AndroidVulkanFormat::kR8G8B8A8Unorm);
  direct_frame.image_layout =
      static_cast<uint32_t>(AndroidVulkanImageLayout::kShaderReadOnlyOptimal);

  EXPECT_TRUE(delegate.SetVulkanTextureFrame(texture_id, direct_frame));

  FlutterVulkanExternalTexture out_frame2 = {};
  EXPECT_TRUE(
      delegate.GetVulkanTextureFrame(texture_id, 1280, 720, &out_frame2));
  EXPECT_EQ(out_frame2.width, 1280u);
  EXPECT_EQ(out_frame2.height, 720u);
  EXPECT_EQ(out_frame2.image, 0x5555u);

  EXPECT_TRUE(delegate.OnVulkanTextureFrameAvailable(texture_id));
  EXPECT_TRUE(delegate.UnregisterVulkanTexture(texture_id));

  // Verify frame is erased after unregistering
  FlutterVulkanExternalTexture out_frame3 = {};
  EXPECT_FALSE(
      delegate.GetVulkanTextureFrame(texture_id, 1280, 720, &out_frame3));
}

TEST(VulkanExternalTextureTest, JniRouterVulkanRoutingFlip) {
  auto mock_invoker = std::make_shared<StrictMock<MockJvmInvoker>>();
  auto mock_legacy = std::make_shared<StrictMock<MockLegacyJniDelegate>>();
  auto vk_provider = std::make_shared<InMemoryAndroidVulkanTextureProvider>();

  auto embedder_delegate = std::make_shared<JniDelegate>(
      mock_invoker, nullptr, nullptr, nullptr, nullptr, nullptr, nullptr,
      nullptr, vk_provider);

  JniRouter router(embedder_delegate, mock_legacy);

  int64_t texture_id = 777;

  // --- Path 1: Legacy Routing (Flag = false) ---
  FlutterEmbedderNative::SetEmbedderEnabled(false);
  EXPECT_EQ(router.GetActiveRoutingPath(), JniRouter::RoutingPath::kLegacy);

  EXPECT_CALL(*mock_legacy, RegisterVulkanTexture(texture_id))
      .WillOnce(Return(true));
  EXPECT_CALL(*mock_legacy, UnregisterVulkanTexture(texture_id))
      .WillOnce(Return(true));
  EXPECT_CALL(*mock_legacy, OnVulkanTextureFrameAvailable(texture_id))
      .WillOnce(Return(true));

  EXPECT_TRUE(router.RouteRegisterVulkanTexture(texture_id));
  EXPECT_TRUE(router.RouteOnVulkanTextureFrameAvailable(texture_id));
  EXPECT_TRUE(router.RouteUnregisterVulkanTexture(texture_id));

  // --- Path 2: Embedder Routing (Flag = true) ---
  FlutterEmbedderNative::SetEmbedderEnabled(true);
  EXPECT_EQ(router.GetActiveRoutingPath(), JniRouter::RoutingPath::kEmbedder);

  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("registerVulkanTexture", "(J)Z", _))
      .WillOnce(Return(true));
  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("onVulkanTextureFrameAvailable", "(J)Z", _))
      .WillOnce(Return(true));
  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("unregisterVulkanTexture", "(J)Z", _))
      .WillOnce(Return(true));

  EXPECT_TRUE(router.RouteRegisterVulkanTexture(texture_id));

  auto desc = AndroidVulkanImageDesc::MakeRGBA8(800, 600);
  auto tex_obj = vk_provider->AllocateTexture(desc);
  EXPECT_TRUE(
      router.RouteSetVulkanTextureFrame(texture_id, std::move(tex_obj)));

  FlutterVulkanExternalTexture out_tex = {};
  EXPECT_TRUE(
      router.RouteGetVulkanTextureFrame(texture_id, 800, 600, &out_tex));
  EXPECT_EQ(out_tex.width, 800u);
  EXPECT_EQ(out_tex.height, 600u);

  EXPECT_TRUE(router.RouteOnVulkanTextureFrameAvailable(texture_id));
  EXPECT_TRUE(router.RouteUnregisterVulkanTexture(texture_id));

  FlutterEmbedderNative::SetEmbedderEnabled(false);
}

TEST(VulkanExternalTextureTest, FlutterEmbedderNativeVulkanIntegration) {
  FlutterEmbedderNative::SetEmbedderEnabled(true);

  auto mock_invoker = std::make_shared<StrictMock<MockJvmInvoker>>();
  auto vk_provider = std::make_shared<InMemoryAndroidVulkanTextureProvider>();

  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("registerVulkanTexture", "(J)Z", _))
      .WillOnce(Return(true));
  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("onVulkanTextureFrameAvailable", "(J)Z", _))
      .WillOnce(Return(true));
  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("unregisterVulkanTexture", "(J)Z", _))
      .WillOnce(Return(true));

  FlutterEmbedderNative native(mock_invoker, nullptr, nullptr, nullptr, nullptr,
                               nullptr, nullptr, nullptr, nullptr, nullptr,
                               nullptr, nullptr, nullptr, nullptr, nullptr,
                               vk_provider);

  EXPECT_EQ(native.GetVulkanTextureProvider(), vk_provider);

  int64_t texture_id = 888;
  auto desc = AndroidVulkanImageDesc::MakeRGBA8(1920, 1080);
  auto initial_texture = vk_provider->AllocateTexture(desc);
  uint64_t expected_handle = initial_texture->GetImageHandle();

  EXPECT_TRUE(
      native.RegisterVulkanTexture(texture_id, std::move(initial_texture)));

  FlutterVulkanExternalTexture out_frame = {};
  EXPECT_TRUE(native.GetVulkanTextureFrame(texture_id, 1920, 1080, &out_frame));
  EXPECT_EQ(out_frame.width, 1920u);
  EXPECT_EQ(out_frame.height, 1080u);

  // Test static C-API frame callback
  auto cb = FlutterEmbedderNative::GetVulkanExternalTextureFrameCallback();
  ASSERT_NE(cb, nullptr);

  FlutterVulkanExternalTexture cb_out_frame = {};
  EXPECT_TRUE(cb(&native, texture_id, 1920, 1080, &cb_out_frame));
  EXPECT_EQ(cb_out_frame.width, 1920u);
  EXPECT_EQ(cb_out_frame.height, 1080u);
  EXPECT_EQ(cb_out_frame.image, expected_handle);

  EXPECT_TRUE(native.OnVulkanTextureFrameAvailable(texture_id));
  EXPECT_TRUE(native.UnregisterVulkanTexture(texture_id));

  FlutterEmbedderNative::SetEmbedderEnabled(false);
}

TEST(VulkanExternalTextureTest,
     FlutterEmbedderNativeVulkanExternalTextureEngineAPIs) {
  auto mock_invoker = std::make_shared<StrictMock<MockJvmInvoker>>();
  FlutterEmbedderNative native(mock_invoker);

  EXPECT_EQ(native.MarkExternalTextureFrameAvailable(nullptr, 456),
            kInvalidArguments);
  EXPECT_EQ(native.RegisterExternalTexture(nullptr, 456), kInvalidArguments);
  EXPECT_EQ(native.UnregisterExternalTexture(nullptr, 456), kInvalidArguments);
}

TEST(VulkanExternalTextureTest, VulkanDestructionCallbackLifecycle) {
  auto mock_invoker = std::make_shared<StrictMock<MockJvmInvoker>>();
  auto vk_provider = std::make_shared<InMemoryAndroidVulkanTextureProvider>();

  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("registerVulkanTexture", "(J)Z", _))
      .WillOnce(Return(true));
  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("unregisterVulkanTexture", "(J)Z", _))
      .WillOnce(Return(true));

  JniDelegate delegate(mock_invoker, nullptr, nullptr, nullptr, nullptr,
                       nullptr, nullptr, nullptr, vk_provider);

  int64_t texture_id = 444;
  EXPECT_TRUE(delegate.RegisterVulkanTexture(texture_id));

  static int g_vk_destroyed_count = 0;
  g_vk_destroyed_count = 0;

  auto callback = [](void* user_data) { g_vk_destroyed_count++; };

  FlutterVulkanExternalTexture frame1 = {};
  frame1.struct_size = sizeof(FlutterVulkanExternalTexture);
  frame1.width = 100;
  frame1.height = 100;
  frame1.destruction_callback = callback;
  frame1.user_data = reinterpret_cast<void*>(0x1);

  EXPECT_TRUE(delegate.SetVulkanTextureFrame(texture_id, frame1));
  EXPECT_EQ(g_vk_destroyed_count, 0);

  // Overwriting frame triggers destruction callback on frame1
  FlutterVulkanExternalTexture frame2 = {};
  frame2.struct_size = sizeof(FlutterVulkanExternalTexture);
  frame2.width = 200;
  frame2.height = 200;
  frame2.destruction_callback = callback;
  frame2.user_data = reinterpret_cast<void*>(0x2);

  EXPECT_TRUE(delegate.SetVulkanTextureFrame(texture_id, frame2));
  EXPECT_EQ(g_vk_destroyed_count, 1);

  // Unregistering texture triggers destruction callback on frame2
  EXPECT_TRUE(delegate.UnregisterVulkanTexture(texture_id));
  EXPECT_EQ(g_vk_destroyed_count, 2);
}

TEST(VulkanExternalTextureTest, VulkanYCbCrConversionConversionAndSampling) {
  auto mock_invoker = std::make_shared<StrictMock<MockJvmInvoker>>();
  auto vk_provider = std::make_shared<InMemoryAndroidVulkanTextureProvider>();

  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("registerVulkanTexture", "(J)Z", _))
      .WillOnce(Return(true));
  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("unregisterVulkanTexture", "(J)Z", _))
      .WillOnce(Return(true));

  JniDelegate delegate(mock_invoker, nullptr, nullptr, nullptr, nullptr,
                       nullptr, nullptr, nullptr, vk_provider);

  int64_t texture_id = 333;
  EXPECT_TRUE(delegate.RegisterVulkanTexture(texture_id));

  constexpr uint64_t ext_format_id = 0xCAFEBABE1234ULL;
  auto ycbcr = AndroidVulkanYcbcrConversionDesc::MakeExternal(
      ext_format_id, AndroidVulkanYcbcrModel::kYcbcr709,
      AndroidVulkanYcbcrRange::kItuFull,
      AndroidVulkanChromaLocation::kCositedEven, AndroidVulkanFilter::kLinear);

  auto desc = AndroidVulkanImageDesc::MakeYcbcr(1920, 1080, ycbcr);
  auto tex_obj = vk_provider->AllocateTexture(desc);
  ASSERT_NE(tex_obj, nullptr);
  EXPECT_TRUE(tex_obj->HasYcbcrConversion());

  EXPECT_TRUE(delegate.SetVulkanTextureFrame(texture_id, std::move(tex_obj)));

  FlutterVulkanExternalTexture out_frame = {};
  EXPECT_TRUE(
      delegate.GetVulkanTextureFrame(texture_id, 1920, 1080, &out_frame));
  EXPECT_EQ(out_frame.width, 1920u);
  EXPECT_EQ(out_frame.height, 1080u);
  ASSERT_NE(out_frame.ycbcr_conversion_info, nullptr);
  EXPECT_EQ(out_frame.ycbcr_conversion_info->struct_size,
            sizeof(FlutterVulkanYcbcrConversionInfo));
  EXPECT_EQ(out_frame.ycbcr_conversion_info->external_format, ext_format_id);
  EXPECT_EQ(out_frame.ycbcr_conversion_info->ycbcr_model,
            static_cast<uint32_t>(AndroidVulkanYcbcrModel::kYcbcr709));
  EXPECT_EQ(out_frame.ycbcr_conversion_info->ycbcr_range,
            static_cast<uint32_t>(AndroidVulkanYcbcrRange::kItuFull));

  EXPECT_TRUE(delegate.UnregisterVulkanTexture(texture_id));
}

TEST(VulkanExternalTextureTest, ThreadSafeConcurrentVulkanOperations) {
  FlutterEmbedderNative::SetEmbedderEnabled(true);

  auto mock_invoker = std::make_shared<NiceMock<MockJvmInvoker>>();
  ON_CALL(*mock_invoker, InvokeBooleanMethod(_, _, _))
      .WillByDefault(Return(true));
  auto vk_provider = std::make_shared<InMemoryAndroidVulkanTextureProvider>();

  FlutterEmbedderNative native(mock_invoker, nullptr, nullptr, nullptr, nullptr,
                               nullptr, nullptr, nullptr, nullptr, nullptr,
                               nullptr, nullptr, nullptr, nullptr, nullptr,
                               vk_provider);

  constexpr int kThreadCount = 8;
  constexpr int kIterationsPerThread = 25;

  std::vector<std::future<void>> futures;
  futures.reserve(kThreadCount);

  for (int t = 0; t < kThreadCount; ++t) {
    futures.push_back(std::async(std::launch::async, [&native, vk_provider,
                                                      t]() {
      for (int i = 0; i < kIterationsPerThread; ++i) {
        int64_t texture_id = 10000 + (t * 100) + i;
        auto desc = AndroidVulkanImageDesc::MakeRGBA8(800, 600);
        auto tex = vk_provider->AllocateTexture(desc);
        ASSERT_NE(tex, nullptr);

        EXPECT_TRUE(native.RegisterVulkanTexture(texture_id, std::move(tex)));

        FlutterVulkanExternalTexture out_tex = {};
        EXPECT_TRUE(
            native.GetVulkanTextureFrame(texture_id, 800, 600, &out_tex));
        EXPECT_EQ(out_tex.width, 800u);
        EXPECT_EQ(out_tex.height, 600u);

        EXPECT_TRUE(native.OnVulkanTextureFrameAvailable(texture_id));
        EXPECT_TRUE(native.UnregisterVulkanTexture(texture_id));
      }
    }));
  }

  for (auto& f : futures) {
    f.get();
  }

  FlutterEmbedderNative::SetEmbedderEnabled(false);
}

// =============================================================================
// Phase 3.3 SurfaceControl HCPP Tests
// =============================================================================

TEST(SurfaceControlHcppTest, JniDelegateLifecycleAndOperations) {
  auto mock_invoker = std::make_shared<NiceMock<MockJvmInvoker>>();
  ON_CALL(*mock_invoker, InvokeBooleanMethod(_, _, _))
      .WillByDefault(Return(true));
  ON_CALL(*mock_invoker, InvokeVoidMethod(_, _, _)).WillByDefault(Return(true));
  auto sc_provider = std::make_shared<InMemoryAndroidSurfaceControlProvider>();

  JniDelegate delegate(mock_invoker, nullptr, nullptr, nullptr, nullptr,
                       nullptr, nullptr, nullptr, nullptr, sc_provider);

  EXPECT_TRUE(delegate.SetHcppEnabled(true));
  EXPECT_TRUE(delegate.IsHcppEnabled());

  EXPECT_TRUE(delegate.CreatePlatformViewTransaction());

  int64_t parent_id = 100;
  int64_t child_id = 101;
  EXPECT_TRUE(delegate.CreateSurfaceControl(parent_id, "parent_surface"));
  EXPECT_TRUE(delegate.CreateSurfaceControl(child_id, "child_surface"));

  auto parent_sc = delegate.GetSurfaceControl(parent_id);
  auto child_sc = delegate.GetSurfaceControl(child_id);
  ASSERT_NE(parent_sc, nullptr);
  ASSERT_NE(child_sc, nullptr);
  EXPECT_EQ(parent_sc->GetDebugName(), "parent_surface");
  EXPECT_EQ(child_sc->GetDebugName(), "child_surface");

  EXPECT_TRUE(delegate.ReparentSurfaceControl(child_id, parent_id));

  AndroidSurfaceControlRect src = {0, 0, 640, 480};
  AndroidSurfaceControlRect dst = {10, 20, 1280, 720};
  EXPECT_TRUE(delegate.SetSurfaceControlGeometry(child_id, src, dst, 0));

  EXPECT_TRUE(delegate.SetSurfaceControlVisibility(child_id, true));
  EXPECT_TRUE(delegate.SetSurfaceControlZOrder(child_id, 5));

  std::vector<AndroidSurfaceControlRect> damage = {{0, 0, 100, 100},
                                                   {100, 100, 200, 200}};
  EXPECT_TRUE(delegate.SetSurfaceControlDamageRegion(child_id, damage));

  int dummy_buf = 42;
  EXPECT_TRUE(delegate.SetSurfaceControlBuffer(child_id, &dummy_buf, -1));
  EXPECT_TRUE(delegate.SetSurfaceControlBufferAlpha(child_id, 0.75f));
  EXPECT_TRUE(
      delegate.SetSurfaceControlColor(child_id, 1.0f, 0.5f, 0.25f, 0.8f));

  EXPECT_TRUE(delegate.SwapPlatformViewTransactions());
  EXPECT_TRUE(delegate.ApplyPlatformViewTransactions());

  auto state_opt = delegate.GetSurfaceControlState(child_id);
  ASSERT_TRUE(state_opt.has_value());
  if (state_opt.has_value()) {
    EXPECT_EQ(state_opt->visibility, AndroidSurfaceControlVisibility::kShow);
    EXPECT_EQ(state_opt->z_order, 5);
    EXPECT_EQ(state_opt->parent_id, static_cast<uint64_t>(parent_id));
    EXPECT_FLOAT_EQ(state_opt->alpha, 0.75f);
    EXPECT_FLOAT_EQ(state_opt->color.r, 1.0f);
    EXPECT_FLOAT_EQ(state_opt->color.g, 0.5f);
    EXPECT_FLOAT_EQ(state_opt->color.b, 0.25f);
    EXPECT_FLOAT_EQ(state_opt->color.a, 0.8f);
    EXPECT_EQ(state_opt->buffer_handle, &dummy_buf);
    EXPECT_EQ(state_opt->damage_region.size(), 2u);
  }

  EXPECT_TRUE(delegate.DestroySurfaceControl(child_id));
  EXPECT_EQ(delegate.GetSurfaceControl(child_id), nullptr);
  EXPECT_FALSE(delegate.GetSurfaceControlState(child_id).has_value());
}

TEST(SurfaceControlHcppTest, JniRouterSurfaceControlDirectRouting) {
  auto mock_invoker = std::make_shared<NiceMock<MockJvmInvoker>>();
  ON_CALL(*mock_invoker, InvokeBooleanMethod(_, _, _))
      .WillByDefault(Return(true));
  ON_CALL(*mock_invoker, InvokeVoidMethod(_, _, _)).WillByDefault(Return(true));
  auto sc_provider = std::make_shared<InMemoryAndroidSurfaceControlProvider>();
  auto jni_delegate = std::make_shared<JniDelegate>(
      mock_invoker, nullptr, nullptr, nullptr, nullptr, nullptr, nullptr,
      nullptr, nullptr, sc_provider);
  auto mock_legacy = std::make_shared<StrictMock<MockLegacyJniDelegate>>();
  auto router = std::make_shared<JniRouter>(jni_delegate, mock_legacy);

  // Across both flag states (false and true), all SurfaceControl methods route
  // directly to jni_delegate
  for (bool embedder_flag : {false, true}) {
    FlutterEmbedderNative::SetEmbedderEnabled(embedder_flag);

    EXPECT_TRUE(router->RouteSetHcppEnabled(true));
    EXPECT_TRUE(router->RouteIsHcppEnabled());
    EXPECT_TRUE(router->RouteCreatePlatformViewTransaction());

    int64_t sc_id = embedder_flag ? 300 : 200;
    EXPECT_TRUE(router->RouteCreateSurfaceControl(sc_id, "direct_sc"));
    EXPECT_TRUE(router->RouteReparentSurfaceControl(sc_id, 100));

    AndroidSurfaceControlRect src = {0, 0, 100, 100};
    AndroidSurfaceControlRect dst = {0, 0, 200, 200};
    EXPECT_TRUE(router->RouteSetSurfaceControlGeometry(sc_id, src, dst, 0));
    EXPECT_TRUE(router->RouteSetSurfaceControlVisibility(sc_id, true));
    EXPECT_TRUE(router->RouteSetSurfaceControlZOrder(sc_id, 10));

    std::vector<AndroidSurfaceControlRect> rects = {{0, 0, 50, 50}};
    EXPECT_TRUE(router->RouteSetSurfaceControlDamageRegion(sc_id, rects));

    int dummy_buf = 99;
    EXPECT_TRUE(router->RouteSetSurfaceControlBuffer(sc_id, &dummy_buf, -1));
    EXPECT_TRUE(router->RouteSetSurfaceControlBufferAlpha(sc_id, 0.5f));
    EXPECT_TRUE(
        router->RouteSetSurfaceControlColor(sc_id, 0.1f, 0.2f, 0.3f, 1.0f));

    EXPECT_TRUE(router->RouteSwapPlatformViewTransactions());
    EXPECT_TRUE(router->RouteApplyPlatformViewTransactions());

    auto state = router->RouteGetSurfaceControlState(sc_id);
    ASSERT_TRUE(state.has_value());
    EXPECT_EQ(state->visibility, AndroidSurfaceControlVisibility::kShow);
    EXPECT_EQ(state->z_order, 10);
    EXPECT_TRUE(router->RouteDestroySurfaceControl(sc_id));
  }

  FlutterEmbedderNative::SetEmbedderEnabled(true);
}

TEST(SurfaceControlHcppTest, FlutterEmbedderNativeIntegration) {
  FlutterEmbedderNative::SetEmbedderEnabled(true);

  auto mock_invoker = std::make_shared<NiceMock<MockJvmInvoker>>();
  ON_CALL(*mock_invoker, InvokeBooleanMethod(_, _, _))
      .WillByDefault(Return(true));
  ON_CALL(*mock_invoker, InvokeVoidMethod(_, _, _)).WillByDefault(Return(true));
  auto sc_provider = std::make_shared<InMemoryAndroidSurfaceControlProvider>();

  FlutterEmbedderNative native(mock_invoker, nullptr, nullptr, nullptr, nullptr,
                               nullptr, nullptr, nullptr, nullptr, nullptr,
                               nullptr, nullptr, nullptr, nullptr, nullptr,
                               nullptr, sc_provider);

  EXPECT_EQ(native.GetSurfaceControlProvider(), sc_provider);

  EXPECT_TRUE(native.SetHcppEnabled(true));
  EXPECT_TRUE(native.IsHcppEnabled());

  EXPECT_TRUE(native.CreatePlatformViewTransaction());
  EXPECT_TRUE(native.CreateSurfaceControl(500, "native_surface"));

  auto sc = native.GetSurfaceControl(500);
  ASSERT_NE(sc, nullptr);
  EXPECT_EQ(sc->GetDebugName(), "native_surface");

  EXPECT_TRUE(native.SetSurfaceControlVisibility(500, true));
  EXPECT_TRUE(native.SetSurfaceControlZOrder(500, 7));
  EXPECT_TRUE(native.SetSurfaceControlBufferAlpha(500, 0.9f));
  EXPECT_TRUE(native.SetSurfaceControlColor(500, 0.0f, 1.0f, 0.0f, 1.0f));

  EXPECT_TRUE(native.SwapPlatformViewTransactions());
  EXPECT_TRUE(native.ApplyPlatformViewTransactions());

  auto state = native.GetSurfaceControlState(500);
  ASSERT_TRUE(state.has_value());
  if (state.has_value()) {
    EXPECT_EQ(state->visibility, AndroidSurfaceControlVisibility::kShow);
    EXPECT_EQ(state->z_order, 7);
    EXPECT_FLOAT_EQ(state->alpha, 0.9f);
    EXPECT_FLOAT_EQ(state->color.g, 1.0f);
  }

  EXPECT_TRUE(native.DestroySurfaceControl(500));
  EXPECT_EQ(native.GetSurfaceControl(500), nullptr);

  // Test replacing provider dynamically
  auto new_sc_provider =
      std::make_shared<InMemoryAndroidSurfaceControlProvider>();
  native.SetSurfaceControlProvider(new_sc_provider);
  EXPECT_EQ(native.GetSurfaceControlProvider(), new_sc_provider);

  FlutterEmbedderNative::SetEmbedderEnabled(false);
}

TEST(SurfaceControlHcppTest, ThreadSafeConcurrentSurfaceOperations) {
  FlutterEmbedderNative::SetEmbedderEnabled(true);

  auto mock_invoker = std::make_shared<NiceMock<MockJvmInvoker>>();
  ON_CALL(*mock_invoker, InvokeBooleanMethod(_, _, _))
      .WillByDefault(Return(true));
  ON_CALL(*mock_invoker, InvokeVoidMethod(_, _, _)).WillByDefault(Return(true));
  auto sc_provider = std::make_shared<InMemoryAndroidSurfaceControlProvider>();

  FlutterEmbedderNative native(mock_invoker, nullptr, nullptr, nullptr, nullptr,
                               nullptr, nullptr, nullptr, nullptr, nullptr,
                               nullptr, nullptr, nullptr, nullptr, nullptr,
                               nullptr, sc_provider);

  constexpr int kThreadCount = 8;
  constexpr int kIterationsPerThread = 25;

  std::vector<std::future<void>> futures;
  futures.reserve(kThreadCount);

  for (int t = 0; t < kThreadCount; ++t) {
    futures.push_back(std::async(std::launch::async, [&native, t]() {
      for (int i = 0; i < kIterationsPerThread; ++i) {
        int64_t surface_id = 50000 + (t * 100) + i;
        std::string name = "surface_" + std::to_string(surface_id);

        EXPECT_TRUE(native.CreatePlatformViewTransaction());
        EXPECT_TRUE(native.CreateSurfaceControl(surface_id, name));
        EXPECT_TRUE(native.SetSurfaceControlVisibility(surface_id, true));
        EXPECT_TRUE(native.SetSurfaceControlZOrder(surface_id, t));

        AndroidSurfaceControlRect src = {0, 0, 100, 100};
        AndroidSurfaceControlRect dst = {0, 0, 200, 200};
        EXPECT_TRUE(native.SetSurfaceControlGeometry(surface_id, src, dst, 0));

        EXPECT_TRUE(native.SwapPlatformViewTransactions());
        EXPECT_TRUE(native.ApplyPlatformViewTransactions());

        auto state = native.GetSurfaceControlState(surface_id);
        ASSERT_TRUE(state.has_value());
        EXPECT_EQ(state->visibility, AndroidSurfaceControlVisibility::kShow);
        EXPECT_EQ(state->z_order, t);

        EXPECT_TRUE(native.DestroySurfaceControl(surface_id));
      }
    }));
  }

  for (auto& f : futures) {
    f.get();
  }

  FlutterEmbedderNative::SetEmbedderEnabled(false);
}

TEST(MultiEngineAndAddToAppTest, JniDelegateEngineGroupOperations) {
  auto mock_invoker = std::make_shared<NiceMock<MockJvmInvoker>>();
  ON_CALL(*mock_invoker, InvokeBooleanMethod(_, _, _))
      .WillByDefault(Return(true));
  ON_CALL(*mock_invoker, InvokeVoidMethod(_, _, _)).WillByDefault(Return(true));

  auto provider = std::make_shared<InMemoryAndroidEngineGroupProvider>();
  auto engine_group =
      std::make_shared<AndroidEngineGroup>(provider, mock_invoker);
  JniDelegate delegate(mock_invoker, nullptr, nullptr, nullptr, nullptr,
                       nullptr, nullptr, nullptr, nullptr, nullptr, provider,
                       engine_group);

  EXPECT_EQ(delegate.GetEngineGroup(), engine_group);
  EXPECT_EQ(delegate.GetEngineGroupProvider(), provider);
  EXPECT_EQ(delegate.GetActiveEngineCount(), 0u);

  // Initialize group with a parent engine
  auto parent_handle =
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0x1000);
  EXPECT_TRUE(engine_group->RegisterEngine(1, parent_handle));
  EXPECT_EQ(delegate.GetActiveEngineCount(), 1u);

  // Spawn a child engine
  AndroidEngineSpawnArgs args;
  args.entrypoint = "main";
  args.initial_route = "/child_route";
  int64_t spawned_id = delegate.SpawnEngine(1, args);
  EXPECT_GT(spawned_id, 0);
  EXPECT_EQ(delegate.GetActiveEngineCount(), 2u);

  // Shut down spawned engine
  EXPECT_TRUE(delegate.ShutdownSpawnedEngine(spawned_id));
  EXPECT_EQ(delegate.GetActiveEngineCount(), 1u);

  // GC Cleaner trigger on remaining engine
  EXPECT_TRUE(delegate.OnEngineGarbageCollected(1));
  EXPECT_EQ(delegate.GetActiveEngineCount(), 0u);

  // Replacing provider and engine group
  auto new_provider = std::make_shared<InMemoryAndroidEngineGroupProvider>();
  auto new_group =
      std::make_shared<AndroidEngineGroup>(new_provider, mock_invoker);
  delegate.SetEngineGroupProvider(new_provider);
  delegate.SetEngineGroup(new_group);
  EXPECT_EQ(delegate.GetEngineGroupProvider(), new_provider);
  EXPECT_EQ(delegate.GetEngineGroup(), new_group);
}

TEST(MultiEngineAndAddToAppTest, JniRouterEngineGroupRoutingFlip) {
  auto mock_invoker = std::make_shared<NiceMock<MockJvmInvoker>>();
  ON_CALL(*mock_invoker, InvokeBooleanMethod(_, _, _))
      .WillByDefault(Return(true));
  ON_CALL(*mock_invoker, InvokeVoidMethod(_, _, _)).WillByDefault(Return(true));

  auto mock_legacy = std::make_shared<StrictMock<MockLegacyJniDelegate>>();
  auto provider = std::make_shared<InMemoryAndroidEngineGroupProvider>();
  auto engine_group =
      std::make_shared<AndroidEngineGroup>(provider, mock_invoker);

  auto jni_delegate = std::make_shared<JniDelegate>(
      mock_invoker, nullptr, nullptr, nullptr, nullptr, nullptr, nullptr,
      nullptr, nullptr, nullptr, provider, engine_group);

  JniRouter router(jni_delegate, mock_legacy);

  AndroidEngineSpawnArgs args;
  args.entrypoint = "custom_entry";

  // When embedder is disabled -> routes to legacy delegate
  FlutterEmbedderNative::SetEmbedderEnabled(false);
  EXPECT_CALL(*mock_legacy, SpawnEngine(100, Eq(args))).WillOnce(Return(200));
  EXPECT_CALL(*mock_legacy, ShutdownSpawnedEngine(200)).WillOnce(Return(true));
  EXPECT_CALL(*mock_legacy, GetActiveEngineCount()).WillOnce(Return(1u));
  EXPECT_CALL(*mock_legacy, OnEngineGarbageCollected(200))
      .WillOnce(Return(true));

  EXPECT_EQ(router.RouteSpawnEngine(100, args), 200);
  EXPECT_TRUE(router.RouteShutdownSpawnedEngine(200));
  EXPECT_EQ(router.RouteGetActiveEngineCount(), 1u);
  EXPECT_TRUE(router.RouteOnEngineGarbageCollected(200));

  // When embedder is enabled -> routes to jni_delegate / engine_group
  FlutterEmbedderNative::SetEmbedderEnabled(true);
  auto parent_handle =
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0x2000);
  EXPECT_TRUE(engine_group->RegisterEngine(10, parent_handle));
  EXPECT_EQ(router.RouteGetActiveEngineCount(), 1u);

  auto new_spawned_id = router.RouteSpawnEngine(10, args);
  EXPECT_GT(new_spawned_id, 0);
  EXPECT_EQ(router.RouteGetActiveEngineCount(), 2u);

  EXPECT_TRUE(router.RouteShutdownSpawnedEngine(new_spawned_id));
  EXPECT_EQ(router.RouteGetActiveEngineCount(), 1u);

  EXPECT_TRUE(router.RouteOnEngineGarbageCollected(10));
  EXPECT_EQ(router.RouteGetActiveEngineCount(), 0u);

  FlutterEmbedderNative::SetEmbedderEnabled(false);
}

TEST(MultiEngineAndAddToAppTest, FlutterEmbedderNativeEngineGroupIntegration) {
  FlutterEmbedderNative::SetEmbedderEnabled(true);

  auto mock_invoker = std::make_shared<NiceMock<MockJvmInvoker>>();
  ON_CALL(*mock_invoker, InvokeBooleanMethod(_, _, _))
      .WillByDefault(Return(true));
  ON_CALL(*mock_invoker, InvokeVoidMethod(_, _, _)).WillByDefault(Return(true));

  auto provider = std::make_shared<InMemoryAndroidEngineGroupProvider>();
  FlutterEmbedderNative native(mock_invoker, nullptr, nullptr, nullptr, nullptr,
                               nullptr, nullptr, nullptr, nullptr, nullptr,
                               nullptr, nullptr, nullptr, nullptr, nullptr,
                               nullptr, nullptr, provider);

  EXPECT_NE(native.GetEngineGroup(), nullptr);
  EXPECT_EQ(native.GetEngineGroupProvider(), provider);
  EXPECT_EQ(native.GetActiveEngineCount(), 0u);

  auto parent_handle =
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0x3000);
  EXPECT_TRUE(native.GetEngineGroup()->RegisterEngine(100, parent_handle));
  EXPECT_EQ(native.GetActiveEngineCount(), 1u);

  // Spawn with AndroidEngineSpawnArgs
  AndroidEngineSpawnArgs args;
  args.entrypoint = "worker_main";
  args.initial_route = "/worker";
  auto spawned = native.SpawnEngine(parent_handle, args);
  EXPECT_NE(spawned, nullptr);
  EXPECT_EQ(native.GetActiveEngineCount(), 2u);

  // Spawn with raw FlutterEngineSpawnConfig
  FlutterEngineSpawnConfig raw_config = {};
  raw_config.struct_size = sizeof(FlutterEngineSpawnConfig);
  raw_config.initial_route = "/raw_route";
  auto raw_spawned = native.SpawnEngine(parent_handle, &raw_config, 102);
  EXPECT_NE(raw_spawned, nullptr);
  EXPECT_EQ(native.GetActiveEngineCount(), 3u);

  // Direct C-API FlutterEngineSpawn
  FLUTTER_API_SYMBOL(FlutterEngine) direct_spawned = nullptr;
  EXPECT_EQ(native.SpawnEngine(parent_handle, &raw_config, &direct_spawned),
            kSuccess);
  EXPECT_NE(direct_spawned, nullptr);

  // Direct C-API FlutterEngineShutdown
  EXPECT_EQ(native.ShutdownEngine(direct_spawned), kSuccess);

  // Shutdown spawned by id
  EXPECT_TRUE(native.ShutdownSpawnedEngine(102));
  EXPECT_EQ(native.GetActiveEngineCount(), 2u);

  // GC Cleaner trigger
  auto spawned_id = native.GetEngineGroup()->GetEngineId(spawned);
  ASSERT_TRUE(spawned_id.has_value());
  if (spawned_id.has_value()) {
    EXPECT_TRUE(native.OnEngineGarbageCollected(*spawned_id));
  }
  EXPECT_EQ(native.GetActiveEngineCount(), 1u);

  EXPECT_TRUE(native.OnEngineGarbageCollected(100));
  EXPECT_EQ(native.GetActiveEngineCount(), 0u);

  // Test replacing provider dynamically
  auto new_provider = std::make_shared<InMemoryAndroidEngineGroupProvider>();
  native.SetEngineGroupProvider(new_provider);
  EXPECT_EQ(native.GetEngineGroupProvider(), new_provider);

  FlutterEmbedderNative::SetEmbedderEnabled(false);
}

TEST(MultiEngineAndAddToAppTest, ThreadSafeConcurrentMultiEngineOperations) {
  FlutterEmbedderNative::SetEmbedderEnabled(true);

  auto mock_invoker = std::make_shared<NiceMock<MockJvmInvoker>>();
  ON_CALL(*mock_invoker, InvokeBooleanMethod(_, _, _))
      .WillByDefault(Return(true));
  ON_CALL(*mock_invoker, InvokeVoidMethod(_, _, _)).WillByDefault(Return(true));

  auto provider = std::make_shared<InMemoryAndroidEngineGroupProvider>();
  FlutterEmbedderNative native(mock_invoker, nullptr, nullptr, nullptr, nullptr,
                               nullptr, nullptr, nullptr, nullptr, nullptr,
                               nullptr, nullptr, nullptr, nullptr, nullptr,
                               nullptr, nullptr, provider);

  auto parent_handle =
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0x5000);
  EXPECT_TRUE(native.GetEngineGroup()->RegisterEngine(5000, parent_handle));

  constexpr int kThreadCount = 8;
  constexpr int kIterationsPerThread = 25;

  std::vector<std::future<void>> futures;
  futures.reserve(kThreadCount);

  for (int t = 0; t < kThreadCount; ++t) {
    futures.push_back(
        std::async(std::launch::async, [&native, parent_handle, t]() {
          for (int i = 0; i < kIterationsPerThread; ++i) {
            int64_t engine_id = 10000 + (t * 100) + i;
            AndroidEngineSpawnArgs args;
            args.entrypoint = "thread_" + std::to_string(t) + "_entry";
            args.initial_route = "/route_" + std::to_string(engine_id);

            auto spawned = native.SpawnEngine(parent_handle, args);
            EXPECT_NE(spawned, nullptr);

            auto id = native.GetEngineGroup()->GetEngineId(spawned);
            ASSERT_TRUE(id.has_value());

            if (i % 2 == 0) {
              EXPECT_TRUE(native.ShutdownSpawnedEngine(*id));
            } else {
              EXPECT_TRUE(native.OnEngineGarbageCollected(*id));
            }
          }
        }));
  }

  for (auto& f : futures) {
    f.get();
  }

  EXPECT_EQ(native.GetActiveEngineCount(), 1u);
  EXPECT_TRUE(native.ShutdownSpawnedEngine(5000));
  EXPECT_EQ(native.GetActiveEngineCount(), 0u);

  FlutterEmbedderNative::SetEmbedderEnabled(false);
}

TEST(MultiEngineAndAddToAppTest,
     FlutterEmbedderNativeDefaultConstructorEngineGroup) {
  FlutterEmbedderNative native;
  EXPECT_NE(native.GetEngineGroup(), nullptr);
  EXPECT_NE(native.GetEngineGroupProvider(), nullptr);
  EXPECT_EQ(native.GetJniDelegate()->GetEngineGroup(), native.GetEngineGroup());
  EXPECT_EQ(native.GetJniDelegate()->GetEngineGroupProvider(),
            native.GetEngineGroupProvider());
}

TEST(Phase52LegacyDeletionSubsystemsTest,
     LegacySubsystemsPurgedAndDirectlyRouted) {
  auto mock_invoker = std::make_shared<StrictMock<MockJvmInvoker>>();
  auto callback_cache = std::make_shared<InMemoryCallbackCacheProvider>();
  callback_cache->AddCallback(42L, "phase52Callback", "Phase52Class",
                              "package:flutter/subsystems.dart");

  auto image_decoder = std::make_shared<InMemoryImageDecoderProvider>();
  image_decoder->SetHeaderInfo(99L, 1920, 1080);

  auto embedder_delegate = std::make_shared<JniDelegate>(
      mock_invoker, callback_cache, image_decoder);
  auto legacy_delegate = std::make_shared<StrictMock<MockLegacyJniDelegate>>();

  auto router = std::make_unique<JniRouter>(embedder_delegate, legacy_delegate);

  // Test across both flag states: Subsystem calls MUST NEVER touch
  // legacy_delegate
  for (bool embedder_flag : {false, true}) {
    JniRouter::SetEmbedderEnabled(embedder_flag);

    // 1. Assets Subsystem: RouteAssetManagerChanged routes directly to
    // JvmInvoker
    EXPECT_CALL(*mock_invoker,
                InvokeVoidMethod("onAssetManagerChanged", "()V", _))
        .WillOnce(Return(true));
    EXPECT_TRUE(router->RouteAssetManagerChanged());

    // 2. Callbacks Subsystem: RouteLookupCallbackInformation routes directly to
    // CallbackCacheProvider
    auto cb = router->RouteLookupCallbackInformation(42L);
    ASSERT_TRUE(cb.has_value());
    if (cb.has_value()) {
      EXPECT_EQ(cb->name, "phase52Callback");
      EXPECT_EQ(cb->class_name, "Phase52Class");
      EXPECT_EQ(cb->library_path, "package:flutter/subsystems.dart");
    }
    EXPECT_FALSE(router->RouteLookupCallbackInformation(999L).has_value());

    // 3. Images Subsystem: RouteDecodeImage, RouteNativeImageHeader,
    // RouteGetImageHeader route directly
    std::vector<uint8_t> img_data = {0xFF, 0xD8, 0xFF, 0xE0};
    EXPECT_TRUE(
        router->RouteDecodeImage(img_data.data(), img_data.size(), 99L));
    EXPECT_EQ(image_decoder->GetDecodeCount(), embedder_flag ? 2u : 1u);

    router->RouteNativeImageHeader(101L, 800, 600);
    auto hdr = router->RouteGetImageHeader(101L);
    ASSERT_TRUE(hdr.has_value());
    if (hdr.has_value()) {
      EXPECT_EQ(hdr->width, 800);
      EXPECT_EQ(hdr->height, 600);
    }

    // 4. Mutators Subsystem: RoutePlatformViewMutators routes directly to
    // JvmInvoker
    AndroidMutatorsStack stack;
    stack.PushOpacity(0.5f);
    std::vector<uint8_t> stack_bytes = stack.Serialize();

    EXPECT_CALL(
        *mock_invoker,
        InvokeVoidMethod("onDisplayPlatformView",
                         "(IIIIIIILjava/nio/ByteBuffer;)V", stack_bytes))
        .WillOnce(Return(true));
    EXPECT_TRUE(
        router->RoutePlatformViewMutators(777L, 10, 20, 300, 400, stack));

    FlutterPlatformViewMutation m = {
        .type = kFlutterPlatformViewMutationTypeOpacity,
        .opacity = 0.5,
    };
    const FlutterPlatformViewMutation* mutations[] = {&m};
    FlutterPlatformView pv = {
        .struct_size = sizeof(FlutterPlatformView),
        .identifier = 777,
        .mutations_count = 1,
        .mutations = mutations,
    };
    EXPECT_CALL(
        *mock_invoker,
        InvokeVoidMethod("onDisplayPlatformView",
                         "(IIIIIIILjava/nio/ByteBuffer;)V", stack_bytes))
        .WillOnce(Return(true));
    EXPECT_TRUE(router->RoutePlatformViewMutators(pv, 10, 20, 300, 400));
  }

  // Verify graceful handling when embedder_delegate is null
  auto null_router = std::make_unique<JniRouter>(nullptr, legacy_delegate);
  EXPECT_FALSE(null_router->RouteAssetManagerChanged());
  EXPECT_FALSE(null_router->RouteLookupCallbackInformation(42L).has_value());
  EXPECT_FALSE(null_router->RouteDecodeImage(nullptr, 0, 1L));
  null_router->RouteNativeImageHeader(1L, 100, 100);
  EXPECT_FALSE(null_router->RouteGetImageHeader(1L).has_value());
  AndroidMutatorsStack empty_stack;
  EXPECT_FALSE(
      null_router->RoutePlatformViewMutators(1L, 0, 0, 10, 10, empty_stack));

  JniRouter::SetEmbedderEnabled(true);
}

TEST(Phase52LegacyDeletionSubsystemsTest,
     ConcurrentMultithreadedSubsystemsExecution) {
  auto mock_invoker = std::make_shared<NiceMock<MockJvmInvoker>>();
  ON_CALL(*mock_invoker, InvokeVoidMethod(_, _, _))
      .WillByDefault(::testing::Return(true));
  auto callback_cache = std::make_shared<InMemoryCallbackCacheProvider>();
  auto image_decoder = std::make_shared<InMemoryImageDecoderProvider>();
  auto image_lru = std::make_shared<EmbedderImageLRU>(20);
  auto in_memory_assets =
      std::make_shared<InMemoryAPKAssetProviderImpl>("flutter_assets");

  for (int i = 0; i < 50; ++i) {
    in_memory_assets->AddAsset("asset_" + std::to_string(i) + ".json",
                               "{\"index\":" + std::to_string(i) + "}");
    callback_cache->AddCallback(
        i, "callback_" + std::to_string(i), "Class_" + std::to_string(i),
        "package:lib/cb_" + std::to_string(i) + ".dart");
  }

  auto asset_provider = std::make_shared<APKAssetProvider>(in_memory_assets);
  auto platform_views_provider =
      std::make_shared<InMemoryPlatformViewsProvider>();

  FlutterEmbedderNative native(mock_invoker, nullptr, nullptr, asset_provider,
                               callback_cache, image_decoder, image_lru,
                               platform_views_provider);

  constexpr size_t kWorkers = 8;
  constexpr size_t kIterations = 100;
  std::vector<std::future<bool>> futures;
  futures.reserve(kWorkers);

  for (size_t worker = 0; worker < kWorkers; ++worker) {
    futures.push_back(std::async(std::launch::async, [&native, worker]() {
      for (size_t iter = 0; iter < kIterations; ++iter) {
        int idx = static_cast<int>((worker * kIterations + iter) % 50);

        // Subsystem 1: Assets resolution
        std::string asset_name = "asset_" + std::to_string(idx) + ".json";
        auto mapping = native.ResolveAsset(asset_name);
        if (!mapping || mapping->GetSize() == 0) {
          return false;
        }

        // Subsystem 2: Dart Callbacks lookup
        auto cb = native.LookupCallbackInformation(idx);
        if (!cb.has_value() || cb->name != "callback_" + std::to_string(idx)) {
          return false;
        }

        // Subsystem 3: Image decoding & headers & LRU
        int64_t gen_handle = static_cast<int64_t>(worker * 1000 + iter + 1);
        std::vector<uint8_t> dummy_bytes = {0x01, 0x02, 0x03, 0x04};
        if (!native.DecodeImage(dummy_bytes.data(), dummy_bytes.size(),
                                gen_handle)) {
          return false;
        }
        native.OnNativeImageHeader(gen_handle, 100 + idx, 200 + idx);
        auto hdr = native.GetImageHeader(gen_handle);
        if (!hdr.has_value() || hdr->width != 100 + idx ||
            hdr->height != 200 + idx) {
          return false;
        }
        native.GetImageLRU()->AddImage(gen_handle * 10, gen_handle);
        if (native.GetImageLRU()->GetSize() == 0) {
          return false;
        }

        // Subsystem 4: Mutator translation & routing
        FlutterPlatformViewMutation mut = {
            .type = kFlutterPlatformViewMutationTypeTransformation,
            .transformation =
                {
                    .scaleX = 1.0 + idx * 0.1,
                    .skewX = 0.0,
                    .transX = static_cast<double>(idx * 5),
                    .skewY = 0.0,
                    .scaleY = 1.0 + idx * 0.1,
                    .transY = static_cast<double>(idx * 10),
                    .pers0 = 0.0,
                    .pers1 = 0.0,
                    .pers2 = 1.0,
                },
        };
        const FlutterPlatformViewMutation* mutations[] = {&mut};
        FlutterPlatformView pv = {
            .struct_size = sizeof(FlutterPlatformView),
            .identifier = static_cast<FlutterPlatformViewIdentifier>(idx),
            .mutations_count = 1,
            .mutations = mutations,
        };
        AndroidMutatorsStack stack = native.MapPlatformView(pv);
        if (stack.GetMutatorsCount() != 1) {
          return false;
        }
        if (!native.PushPlatformViewMutators(pv, 0, 0, 100, 100)) {
          return false;
        }
      }
      return true;
    }));
  }

  for (auto& f : futures) {
    EXPECT_TRUE(f.get());
  }
}

TEST(Phase53LegacyDeletionPlatformViewsSemanticsTest,
     PlatformViewsAndSemanticsPurgedAndDirectlyRouted) {
  auto mock_invoker = std::make_shared<NiceMock<MockJvmInvoker>>();
  ON_CALL(*mock_invoker, InvokeVoidMethod(_, _, _))
      .WillByDefault(::testing::Return(true));
  ON_CALL(*mock_invoker, InvokeBooleanMethod(_, _, _))
      .WillByDefault(::testing::Return(true));

  auto platform_views_provider =
      std::make_shared<InMemoryPlatformViewsProvider>();
  auto sc_provider = std::make_shared<InMemoryAndroidSurfaceControlProvider>();

  auto embedder_delegate = std::make_shared<JniDelegate>(
      mock_invoker, nullptr, nullptr, platform_views_provider, nullptr, nullptr,
      nullptr, nullptr, nullptr, sc_provider);
  auto legacy_delegate = std::make_shared<StrictMock<MockLegacyJniDelegate>>();

  auto router = std::make_unique<JniRouter>(embedder_delegate, legacy_delegate);

  for (bool embedder_flag : {false, true}) {
    JniRouter::SetEmbedderEnabled(embedder_flag);

    // 1. Semantics Subsystem Direct Routing
    std::vector<uint8_t> buffer = {0x01, 0x02, 0x03};
    std::vector<std::string> strings = {"SemanticsLabel"};
    std::vector<std::vector<uint8_t>> string_attrs = {{0xAA}};

    EXPECT_CALL(*mock_invoker,
                InvokeVoidMethod("updateSemantics",
                                 "([B[Ljava/lang/String;[[B)V", buffer))
        .WillOnce(Return(true));
    EXPECT_TRUE(router->RouteSemanticsUpdate(buffer, strings, string_attrs));

    EXPECT_CALL(*mock_invoker,
                InvokeVoidMethod("updateCustomAccessibilityActions",
                                 "([B[Ljava/lang/String;)V", buffer))
        .WillOnce(Return(true));
    EXPECT_TRUE(router->RouteCustomAccessibilityActions(buffer, strings));

    FlutterSemanticsNode2 node = {};
    node.struct_size = sizeof(FlutterSemanticsNode2);
    node.id = 55;
    node.label = "TestNode";
    FlutterSemanticsNode2* nodes[] = {&node};
    FlutterSemanticsUpdate2 sem_update = {
        .struct_size = sizeof(FlutterSemanticsUpdate2),
        .node_count = 1,
        .nodes = nodes,
        .custom_action_count = 0,
        .custom_actions = nullptr,
        .view_id = 0,
    };
    EXPECT_CALL(
        *mock_invoker,
        InvokeVoidMethod("updateSemantics", "([B[Ljava/lang/String;[[B)V", _))
        .WillOnce(Return(true));
    EXPECT_TRUE(router->RouteSemanticsUpdate(sem_update));

    std::vector<uint8_t> enabled_payload = {1};
    EXPECT_CALL(*mock_invoker, InvokeVoidMethod("setSemanticsEnabled", "(Z)V",
                                                enabled_payload))
        .WillOnce(Return(true));
    EXPECT_TRUE(router->RouteSemanticsEnabled(true));

    EXPECT_CALL(*mock_invoker,
                InvokeVoidMethod("dispatchSemanticsAction", "(IIJ[B)V", _))
        .WillOnce(Return(true));
    EXPECT_TRUE(router->RouteDispatchSemanticsAction(
        55, kFlutterSemanticsActionTap, buffer, 0));

    std::vector<uint8_t> features_payload = {0x03, 0x00, 0x00, 0x00};
    EXPECT_CALL(*mock_invoker, InvokeVoidMethod("setAccessibilityFeatures",
                                                "(I)V", features_payload))
        .WillOnce(Return(true));
    EXPECT_TRUE(router->RouteSetAccessibilityFeatures(3));

    // 2. Platform Views Subsystem Direct Routing
    int64_t view_id = embedder_flag ? 201 : 101;
    PlatformViewCreationParams params = {
        .view_id = view_id,
        .view_type = "phase53.view",
        .width = 400.0,
        .height = 300.0,
    };
    EXPECT_EQ(router->RouteCreatePlatformView(
                  params, PlatformViewCompositionType::kHybridComposition),
              0);
    EXPECT_TRUE(platform_views_provider->IsViewCreated(view_id));

    PlatformViewResizeRequest resize_req = {
        .view_id = view_id, .width = 500.0, .height = 350.0};
    EXPECT_TRUE(router->RouteResizePlatformView(resize_req));
    EXPECT_TRUE(router->RouteOffsetPlatformView(view_id, 15.0, 25.0));
    EXPECT_TRUE(router->RouteSetPlatformViewDirection(view_id, 2));
    EXPECT_TRUE(router->RouteClearPlatformViewFocus(view_id));

    PlatformViewTouch touch = {.view_id = view_id};
    EXPECT_TRUE(router->RouteDispatchPlatformViewTouch(touch));

    PlatformViewGeometry geom = {.view_id = view_id};
    EXPECT_TRUE(router->RouteOnDisplayPlatformView(geom));

    FlutterPlatformView pv_struct = {
        .struct_size = sizeof(FlutterPlatformView),
        .identifier = static_cast<FlutterPlatformViewIdentifier>(view_id),
        .mutations_count = 0,
        .mutations = nullptr,
    };
    EXPECT_TRUE(router->RouteOnDisplayPlatformView(pv_struct, 10, 20, 500, 350,
                                                   500, 350));

    EXPECT_TRUE(router->RouteHidePlatformView(view_id));
    EXPECT_TRUE(router->RouteSynchronizeToNativeViewHierarchy(true));
    EXPECT_TRUE(router->RouteBeginFrame());
    EXPECT_TRUE(router->RouteEndFrame());

    auto overlay_id = router->RouteCreateOverlaySurface();
    ASSERT_TRUE(overlay_id.has_value());
    PlatformViewOverlay overlay_struct = {.surface_id = *overlay_id};
    EXPECT_TRUE(router->RouteOnDisplayOverlaySurface(overlay_struct));
    EXPECT_TRUE(router->RouteShowOverlaySurface(*overlay_id));
    EXPECT_TRUE(router->RouteHideOverlaySurface(*overlay_id));
    EXPECT_TRUE(router->RouteDestroyOverlaySurfaces());

    EXPECT_TRUE(router->RouteCreatePlatformViewTransaction());
    EXPECT_TRUE(router->RouteSwapPlatformViewTransactions());
    EXPECT_TRUE(router->RouteApplyPlatformViewTransactions());
    EXPECT_CALL(*mock_invoker, InvokeVoidMethod("setHcppEnabled", "(Z)V", _))
        .WillOnce(Return(true));
    EXPECT_TRUE(router->RouteSetHcppEnabled(true));
    EXPECT_TRUE(router->RouteIsHcppEnabled());

    EXPECT_TRUE(router->RouteDisposePlatformView(view_id));
    EXPECT_FALSE(platform_views_provider->IsViewCreated(view_id));

    // 3. SurfaceControl Subsystem Direct Routing
    int64_t sc_id = embedder_flag ? 801 : 701;
    EXPECT_CALL(*mock_invoker, InvokeVoidMethod("createSurfaceControl",
                                                "(JLjava/lang/String;)V", _))
        .WillOnce(Return(true));
    EXPECT_TRUE(router->RouteCreateSurfaceControl(sc_id, "phase53_sc"));
    EXPECT_TRUE(router->RouteReparentSurfaceControl(sc_id, 0));

    AndroidSurfaceControlRect src = {0, 0, 100, 100};
    AndroidSurfaceControlRect dst = {0, 0, 200, 200};
    EXPECT_TRUE(router->RouteSetSurfaceControlGeometry(sc_id, src, dst, 0));
    EXPECT_TRUE(router->RouteSetSurfaceControlVisibility(sc_id, true));
    EXPECT_TRUE(router->RouteSetSurfaceControlZOrder(sc_id, 5));

    std::vector<AndroidSurfaceControlRect> damage = {{0, 0, 80, 80}};
    EXPECT_TRUE(router->RouteSetSurfaceControlDamageRegion(sc_id, damage));

    int dummy_buf = 42;
    EXPECT_TRUE(router->RouteSetSurfaceControlBuffer(sc_id, &dummy_buf, -1));
    EXPECT_TRUE(router->RouteSetSurfaceControlBufferAlpha(sc_id, 0.8f));
    EXPECT_TRUE(
        router->RouteSetSurfaceControlColor(sc_id, 1.0f, 0.5f, 0.0f, 1.0f));

    auto sc_state = router->RouteGetSurfaceControlState(sc_id);
    ASSERT_TRUE(sc_state.has_value());
    EXPECT_EQ(sc_state->visibility, AndroidSurfaceControlVisibility::kShow);
    EXPECT_EQ(sc_state->z_order, 5);

    auto sc_obj = router->RouteGetSurfaceControl(sc_id);
    ASSERT_NE(sc_obj, nullptr);
    EXPECT_EQ(sc_obj->GetDebugName(), "phase53_sc");

    EXPECT_CALL(*mock_invoker,
                InvokeVoidMethod("destroySurfaceControl", "(J)V", _))
        .WillOnce(Return(true));
    EXPECT_TRUE(router->RouteDestroySurfaceControl(sc_id));
  }

  // Verify graceful handling when embedder_delegate is null
  auto null_router = std::make_unique<JniRouter>(nullptr, legacy_delegate);
  EXPECT_FALSE(null_router->RouteSemanticsUpdate({}, {}));
  EXPECT_FALSE(null_router->RouteCustomAccessibilityActions({}, {}));
  EXPECT_FALSE(null_router->RouteSemanticsEnabled(true));
  EXPECT_FALSE(null_router->RouteDispatchSemanticsAction(
      1, kFlutterSemanticsActionTap, {}));
  EXPECT_FALSE(null_router->RouteSetAccessibilityFeatures(1));

  PlatformViewCreationParams null_params = {.view_id = 1};
  EXPECT_EQ(null_router->RouteCreatePlatformView(
                null_params, PlatformViewCompositionType::kHybridComposition),
            -1);
  EXPECT_FALSE(null_router->RouteDisposePlatformView(1));
  PlatformViewResizeRequest null_resize = {.view_id = 1};
  EXPECT_FALSE(null_router->RouteResizePlatformView(null_resize));
  EXPECT_FALSE(null_router->RouteOffsetPlatformView(1, 0, 0));
  EXPECT_FALSE(null_router->RouteSetPlatformViewDirection(1, 0));
  EXPECT_FALSE(null_router->RouteClearPlatformViewFocus(1));
  PlatformViewTouch null_touch = {.view_id = 1};
  EXPECT_FALSE(null_router->RouteDispatchPlatformViewTouch(null_touch));
  PlatformViewGeometry null_geom = {.view_id = 1};
  EXPECT_FALSE(null_router->RouteOnDisplayPlatformView(null_geom));
  EXPECT_FALSE(null_router->RouteHidePlatformView(1));
  EXPECT_FALSE(null_router->RouteSynchronizeToNativeViewHierarchy(true));
  EXPECT_FALSE(null_router->RouteBeginFrame());
  EXPECT_FALSE(null_router->RouteEndFrame());
  EXPECT_FALSE(null_router->RouteCreateOverlaySurface().has_value());
  EXPECT_FALSE(null_router->RouteDestroyOverlaySurfaces());
  PlatformViewOverlay null_overlay = {.surface_id = 1};
  EXPECT_FALSE(null_router->RouteOnDisplayOverlaySurface(null_overlay));
  EXPECT_FALSE(null_router->RouteShowOverlaySurface(1));
  EXPECT_FALSE(null_router->RouteHideOverlaySurface(1));
  EXPECT_FALSE(null_router->RouteCreatePlatformViewTransaction());
  EXPECT_FALSE(null_router->RouteSwapPlatformViewTransactions());
  EXPECT_FALSE(null_router->RouteApplyPlatformViewTransactions());
  EXPECT_FALSE(null_router->RouteSetHcppEnabled(true));
  EXPECT_FALSE(null_router->RouteIsHcppEnabled());

  EXPECT_FALSE(null_router->RouteCreateSurfaceControl(1, ""));
  EXPECT_FALSE(null_router->RouteDestroySurfaceControl(1));
  EXPECT_FALSE(null_router->RouteReparentSurfaceControl(1, 0));
  AndroidSurfaceControlRect rect = {0, 0, 10, 10};
  EXPECT_FALSE(null_router->RouteSetSurfaceControlGeometry(1, rect, rect, 0));
  EXPECT_FALSE(null_router->RouteSetSurfaceControlVisibility(1, true));
  EXPECT_FALSE(null_router->RouteSetSurfaceControlZOrder(1, 1));
  EXPECT_FALSE(null_router->RouteSetSurfaceControlDamageRegion(1, {rect}));
  EXPECT_FALSE(null_router->RouteSetSurfaceControlBuffer(1, nullptr, -1));
  EXPECT_FALSE(null_router->RouteSetSurfaceControlBufferAlpha(1, 1.0f));
  EXPECT_FALSE(
      null_router->RouteSetSurfaceControlColor(1, 1.0f, 1.0f, 1.0f, 1.0f));
  EXPECT_FALSE(null_router->RouteGetSurfaceControlState(1).has_value());
  EXPECT_EQ(null_router->RouteGetSurfaceControl(1), nullptr);

  JniRouter::SetEmbedderEnabled(true);
}

TEST(Phase53LegacyDeletionPlatformViewsSemanticsTest,
     ConcurrentMultithreadedPlatformViewsAndSemanticsExecution) {
  auto mock_invoker = std::make_shared<NiceMock<MockJvmInvoker>>();
  ON_CALL(*mock_invoker, InvokeVoidMethod(_, _, _))
      .WillByDefault(::testing::Return(true));
  ON_CALL(*mock_invoker, InvokeBooleanMethod(_, _, _))
      .WillByDefault(::testing::Return(true));

  auto platform_views_provider =
      std::make_shared<InMemoryPlatformViewsProvider>();
  auto sc_provider = std::make_shared<InMemoryAndroidSurfaceControlProvider>();

  FlutterEmbedderNative native(mock_invoker, nullptr, nullptr, nullptr, nullptr,
                               nullptr, nullptr, platform_views_provider,
                               nullptr, nullptr, nullptr, nullptr, nullptr,
                               nullptr, nullptr, nullptr, sc_provider);

  constexpr size_t kWorkers = 8;
  constexpr size_t kIterations = 50;
  std::vector<std::future<bool>> futures;
  futures.reserve(kWorkers);

  for (size_t worker = 0; worker < kWorkers; ++worker) {
    futures.push_back(std::async(std::launch::async, [&native, worker]() {
      for (size_t iter = 0; iter < kIterations; ++iter) {
        int64_t view_id = static_cast<int64_t>(worker * 1000 + iter + 1);
        int64_t sc_id = static_cast<int64_t>(worker * 2000 + iter + 1);

        // 1. Semantics operations
        FlutterSemanticsNode2 node = {};
        node.struct_size = sizeof(FlutterSemanticsNode2);
        node.id = static_cast<int32_t>(view_id);
        node.label = "ConcurrentSemantics";
        FlutterSemanticsNode2* nodes[] = {&node};
        FlutterSemanticsUpdate2 sem_update = {
            .struct_size = sizeof(FlutterSemanticsUpdate2),
            .node_count = 1,
            .nodes = nodes,
            .custom_action_count = 0,
            .custom_actions = nullptr,
            .view_id = 0,
        };
        if (!native.UpdateSemantics(sem_update)) {
          return false;
        }
        if (!native.DispatchSemanticsAction(static_cast<int32_t>(view_id),
                                            kFlutterSemanticsActionTap, {},
                                            0)) {
          return false;
        }

        // 2. Platform view lifecycle operations
        PlatformViewCreationParams params = {
            .view_id = view_id,
            .view_type = "concurrent.pv",
            .width = 300.0 + iter,
            .height = 200.0 + iter,
        };
        if (native.CreatePlatformView(
                params, PlatformViewCompositionType::kHybridComposition) != 0) {
          return false;
        }

        PlatformViewResizeRequest resize_req = {
            .view_id = view_id, .width = 350.0 + iter, .height = 250.0 + iter};
        if (!native.ResizePlatformView(resize_req)) {
          return false;
        }
        if (!native.OffsetPlatformView(view_id, 10.0, 20.0)) {
          return false;
        }
        if (!native.SetPlatformViewDirection(view_id, 1)) {
          return false;
        }
        PlatformViewTouch touch = {.view_id = view_id};
        if (!native.DispatchPlatformViewTouch(touch)) {
          return false;
        }

        PlatformViewGeometry geom = {.view_id = view_id};
        if (!native.OnDisplayPlatformView(geom)) {
          return false;
        }
        if (!native.HidePlatformView(view_id)) {
          return false;
        }
        if (!native.DisposePlatformView(view_id)) {
          return false;
        }

        // 3. Overlay operations
        auto overlay_opt = native.CreateOverlaySurface();
        if (!overlay_opt.has_value()) {
          return false;
        }
        PlatformViewOverlay overlay_geom = {.surface_id = *overlay_opt};
        if (!native.OnDisplayOverlaySurface(overlay_geom)) {
          return false;
        }
        if (!native.ShowOverlaySurface(*overlay_opt)) {
          return false;
        }
        if (!native.HideOverlaySurface(*overlay_opt)) {
          return false;
        }
        if (!native.DestroyOverlaySurfaces()) {
          return false;
        }

        // 4. SurfaceControl operations
        if (!native.CreateSurfaceControl(sc_id,
                                         "sc_" + std::to_string(sc_id))) {
          return false;
        }
        AndroidSurfaceControlRect src = {0, 0, 100, 100};
        AndroidSurfaceControlRect dst = {0, 0, 200, 200};
        if (!native.SetSurfaceControlGeometry(sc_id, src, dst, 0)) {
          return false;
        }
        if (!native.SetSurfaceControlVisibility(sc_id, true)) {
          return false;
        }
        if (!native.SetSurfaceControlZOrder(sc_id,
                                            static_cast<int32_t>(iter))) {
          return false;
        }
        if (!native.SetSurfaceControlBufferAlpha(sc_id, 0.95f)) {
          return false;
        }
        if (!native.SetSurfaceControlColor(sc_id, 0.2f, 0.4f, 0.6f, 1.0f)) {
          return false;
        }
        if (!native.CreatePlatformViewTransaction()) {
          return false;
        }
        if (!native.SwapPlatformViewTransactions()) {
          return false;
        }
        if (!native.ApplyPlatformViewTransactions()) {
          return false;
        }
        auto sc_state = native.GetSurfaceControlState(sc_id);
        if (!sc_state.has_value() ||
            sc_state->z_order != static_cast<int32_t>(iter)) {
          return false;
        }
        if (!native.DestroySurfaceControl(sc_id)) {
          return false;
        }
      }
      return true;
    }));
  }

  for (auto& f : futures) {
    EXPECT_TRUE(f.get());
  }
}

class EmbedderTestListener : public ::testing::EmptyTestEventListener {
 public:
  void OnTestStart(const ::testing::TestInfo&) override {
    JniRouter::SetEmbedderEnabled(true);
  }
  void OnTestEnd(const ::testing::TestInfo&) override {
    JniRouter::SetEmbedderEnabled(true);
  }
};

}  // namespace testing
}  // namespace android
}  // namespace flutter

int main(int argc, char* argv[]) {
  ::testing::InitGoogleTest(&argc, argv);
  ::testing::UnitTest::GetInstance()->listeners().Append(
      new flutter::android::testing::EmbedderTestListener());
  return RUN_ALL_TESTS();
}
