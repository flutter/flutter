// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <future>
#include <thread>
#include <vector>

#include "flutter/shell/platform/android/android_platform_views_controller.h"
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

  MOCK_METHOD(bool,
              UpdateSemantics,
              (const std::vector<uint8_t>& buffer,
               const std::vector<std::string>& strings,
               const std::vector<std::vector<uint8_t>>& string_attribute_args),
              (override));

  MOCK_METHOD(bool,
              UpdateCustomAccessibilityActions,
              (const std::vector<uint8_t>& actions_buffer,
               const std::vector<std::string>& action_strings),
              (override));

  MOCK_METHOD(bool,
              UpdateSemantics,
              (const FlutterSemanticsUpdate2& update),
              (override));

  MOCK_METHOD(bool, SetSemanticsEnabled, (bool enabled), (override));

  MOCK_METHOD(bool,
              DispatchSemanticsAction,
              (int32_t node_id,
               FlutterSemanticsAction action,
               const std::vector<uint8_t>& data,
               int64_t view_id),
              (override));

  MOCK_METHOD(bool, SetAccessibilityFeatures, (int32_t flags), (override));

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

  MOCK_METHOD(bool, OnAssetManagerChanged, (), (override));

  MOCK_METHOD(std::optional<DartCallbackInfo>,
              LookupCallbackInformation,
              (int64_t handle),
              (override));

  MOCK_METHOD(bool,
              DecodeImage,
              (const uint8_t* data, size_t size, int64_t generator_handle),
              (override));

  MOCK_METHOD(void,
              OnNativeImageHeader,
              (int64_t generator_handle, int32_t width, int32_t height),
              (override));

  MOCK_METHOD(std::optional<ImageHeaderInfo>,
              GetImageHeader,
              (int64_t generator_handle),
              (override));

  MOCK_METHOD(int64_t,
              CreatePlatformView,
              (const PlatformViewCreationParams& params,
               PlatformViewCompositionType composition_type),
              (override));

  MOCK_METHOD(bool, DisposePlatformView, (int64_t view_id), (override));

  MOCK_METHOD(bool,
              ResizePlatformView,
              (const PlatformViewResizeRequest& request),
              (override));

  MOCK_METHOD(bool,
              OffsetPlatformView,
              (int64_t view_id, double top, double left),
              (override));

  MOCK_METHOD(bool,
              SetPlatformViewDirection,
              (int64_t view_id, int32_t direction),
              (override));

  MOCK_METHOD(bool, ClearPlatformViewFocus, (int64_t view_id), (override));

  MOCK_METHOD(bool,
              DispatchPlatformViewTouch,
              (const PlatformViewTouch& touch),
              (override));

  MOCK_METHOD(bool,
              OnDisplayPlatformView,
              (const PlatformViewGeometry& geometry),
              (override));

  MOCK_METHOD(bool,
              OnDisplayPlatformView,
              (const FlutterPlatformView& platform_view,
               int32_t x,
               int32_t y,
               int32_t width,
               int32_t height,
               int32_t view_width,
               int32_t view_height),
              (override));

  MOCK_METHOD(bool, HidePlatformView, (int64_t view_id), (override));

  MOCK_METHOD(bool,
              SynchronizeToNativeViewHierarchy,
              (bool synchronize),
              (override));

  MOCK_METHOD(bool, OnBeginFrame, (), (override));

  MOCK_METHOD(bool, OnEndFrame, (), (override));

  MOCK_METHOD(std::optional<int32_t>, CreateOverlaySurface, (), (override));

  MOCK_METHOD(bool, DestroyOverlaySurfaces, (), (override));

  MOCK_METHOD(bool,
              OnDisplayOverlaySurface,
              (const PlatformViewOverlay& overlay),
              (override));

  MOCK_METHOD(bool, ShowOverlaySurface, (int32_t surface_id), (override));

  MOCK_METHOD(bool, HideOverlaySurface, (int32_t surface_id), (override));

  MOCK_METHOD(bool, CreatePlatformViewTransaction, (), (override));

  MOCK_METHOD(bool, SwapPlatformViewTransactions, (), (override));

  MOCK_METHOD(bool, ApplyPlatformViewTransactions, (), (override));

  MOCK_METHOD(bool, IsHcppEnabled, (), (const, override));

  MOCK_METHOD(bool,
              PushPlatformViewMutators,
              (int64_t view_id,
               int32_t x,
               int32_t y,
               int32_t width,
               int32_t height,
               const AndroidMutatorsStack& mutators_stack),
              (override));

  MOCK_METHOD(bool,
              PushPlatformViewMutators,
              (const FlutterPlatformView& platform_view,
               int32_t x,
               int32_t y,
               int32_t width,
               int32_t height),
              (override));
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
  EXPECT_CALL(
      *mock_invoker,
      InvokeVoidMethod(
          "updateSemantics",
          "(Ljava/nio/ByteBuffer;[Ljava/lang/String;[Ljava/nio/ByteBuffer;)V",
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

  // Legacy Asset Manager Changed
  EXPECT_CALL(*legacy_delegate, OnAssetManagerChanged()).WillOnce(Return(true));
  EXPECT_TRUE(router->RouteAssetManagerChanged());

  // Legacy LookupCallbackInformation
  EXPECT_CALL(*legacy_delegate, LookupCallbackInformation(100L))
      .WillOnce(Return(DartCallbackInfo{"legacyCallback", "LegacyClass",
                                        "package:legacy/main.dart"}));
  auto legacy_cb = router->RouteLookupCallbackInformation(100L);
  ASSERT_TRUE(legacy_cb.has_value());
  EXPECT_EQ(legacy_cb->name, "legacyCallback");
  EXPECT_EQ(legacy_cb->class_name, "LegacyClass");
  EXPECT_EQ(legacy_cb->library_path, "package:legacy/main.dart");

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

  // Embedder Asset Manager Changed
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("onAssetManagerChanged", "()V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteAssetManagerChanged());

  // Embedder LookupCallbackInformation (routed to embedder_delegate without
  // legacy)
  EXPECT_CALL(*legacy_delegate, LookupCallbackInformation(_)).Times(0);
  auto embedder_cb = router->RouteLookupCallbackInformation(100L);
  ASSERT_TRUE(embedder_cb.has_value());
  EXPECT_EQ(embedder_cb->name, "embedderCallback");
  EXPECT_EQ(embedder_cb->class_name, "EmbedderClass");
  EXPECT_EQ(embedder_cb->library_path, "package:embedder/main.dart");

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

TEST(ImageDecoderTest, JniRouterImageDecoderRoutingFlip) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto in_memory_decoder = std::make_shared<InMemoryImageDecoderProvider>();
  in_memory_decoder->SetHeaderInfo(77L, 1024, 768);

  auto embedder_delegate =
      std::make_shared<JniDelegate>(mock_invoker, nullptr, in_memory_decoder);
  auto legacy_delegate = std::make_shared<MockLegacyJniDelegate>();

  auto router = std::make_unique<JniRouter>(embedder_delegate, legacy_delegate);

  std::vector<uint8_t> payload = {10, 20, 30};

  // 1. When Embedder is disabled -> routes to legacy delegate
  JniRouter::SetEmbedderEnabled(false);
  EXPECT_FALSE(JniRouter::IsEmbedderEnabled());

  EXPECT_CALL(*legacy_delegate,
              DecodeImage(payload.data(), payload.size(), 77L))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteDecodeImage(payload.data(), payload.size(), 77L));

  EXPECT_CALL(*legacy_delegate, OnNativeImageHeader(77L, 1024, 768)).Times(1);
  router->RouteNativeImageHeader(77L, 1024, 768);

  EXPECT_CALL(*legacy_delegate, GetImageHeader(77L))
      .WillOnce(Return(ImageHeaderInfo{1024, 768}));
  auto legacy_hdr = router->RouteGetImageHeader(77L);
  ASSERT_TRUE(legacy_hdr.has_value());
  EXPECT_EQ(legacy_hdr->width, 1024);
  EXPECT_EQ(legacy_hdr->height, 768);

  // 2. When Embedder is enabled -> routes to embedder delegate
  // (in_memory_decoder)
  JniRouter::SetEmbedderEnabled(true);
  EXPECT_TRUE(JniRouter::IsEmbedderEnabled());

  EXPECT_CALL(*legacy_delegate, DecodeImage(_, _, _)).Times(0);
  EXPECT_TRUE(router->RouteDecodeImage(payload.data(), payload.size(), 77L));
  EXPECT_EQ(in_memory_decoder->GetDecodeCount(), 1u);

  router->RouteNativeImageHeader(88L, 500, 400);
  auto embedder_hdr = router->RouteGetImageHeader(88L);
  ASSERT_TRUE(embedder_hdr.has_value());
  if (embedder_hdr.has_value()) {
    EXPECT_EQ(embedder_hdr->width, 500);
    EXPECT_EQ(embedder_hdr->height, 400);
  }

  // Reset flag
  JniRouter::SetEmbedderEnabled(false);
  EXPECT_FALSE(JniRouter::IsEmbedderEnabled());
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

TEST(MutatorTranslationTest, JniRouterPlatformViewMutatorsRoutingFlip) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto embedder_delegate = std::make_shared<JniDelegate>(mock_invoker);
  auto legacy_delegate = std::make_shared<MockLegacyJniDelegate>();
  auto router = std::make_unique<JniRouter>(embedder_delegate, legacy_delegate);

  AndroidMutatorsStack stack;
  stack.PushOpacity(0.8f);

  // 1. When Embedder is disabled -> routes to legacy_delegate
  JniRouter::SetEmbedderEnabled(false);
  EXPECT_FALSE(JniRouter::IsEmbedderEnabled());

  EXPECT_CALL(*legacy_delegate,
              PushPlatformViewMutators(1001L, 0, 0, 100, 200, Eq(stack)))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RoutePlatformViewMutators(1001L, 0, 0, 100, 200, stack));

  // 2. When Embedder is enabled -> routes to embedder_delegate (mock_invoker)
  JniRouter::SetEmbedderEnabled(true);
  EXPECT_TRUE(JniRouter::IsEmbedderEnabled());

  std::vector<uint8_t> payload = stack.Serialize();
  EXPECT_CALL(*legacy_delegate, PushPlatformViewMutators(1001L, _, _, _, _, _))
      .Times(0);
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("onDisplayPlatformView",
                               "(IIIIIIILjava/nio/ByteBuffer;)V", payload))
      .WillOnce(Return(true));

  EXPECT_TRUE(router->RoutePlatformViewMutators(1001L, 0, 0, 100, 200, stack));

  // Reset flag
  JniRouter::SetEmbedderEnabled(false);
  EXPECT_FALSE(JniRouter::IsEmbedderEnabled());
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
      InvokeVoidMethod(
          "updateSemantics",
          "(Ljava/nio/ByteBuffer;[Ljava/lang/String;[Ljava/nio/ByteBuffer;)V",
          buffer))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->UpdateSemantics(buffer, strings));

  // 2. UpdateCustomAccessibilityActions
  std::vector<uint8_t> actions_buffer = {0x10, 0x20};
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("updateCustomAccessibilityActions",
                               "(Ljava/nio/ByteBuffer;[Ljava/lang/String;)V",
                               actions_buffer))
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
                               "(Ljava/nio/ByteBuffer;[Ljava/lang/String;)V",
                               ::testing::_))
      .WillOnce(Return(true));
  EXPECT_CALL(
      *mock_invoker,
      InvokeVoidMethod(
          "updateSemantics",
          "(Ljava/nio/ByteBuffer;[Ljava/lang/String;[Ljava/nio/ByteBuffer;)V",
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
                                              "(II[BI)V", action_data))
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

TEST(SemanticsAndAccessibilityTest, JniRouterSemanticsRoutingFlip) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto embedder_delegate = std::make_shared<JniDelegate>(mock_invoker);
  auto legacy_delegate = std::make_shared<MockLegacyJniDelegate>();
  auto router = std::make_unique<JniRouter>(embedder_delegate, legacy_delegate);

  std::vector<uint8_t> buffer = {0x11, 0x22};
  std::vector<std::string> strings = {"Hello"};

  // 1. When Embedder is disabled -> routes to legacy_delegate
  JniRouter::SetEmbedderEnabled(false);
  EXPECT_FALSE(JniRouter::IsEmbedderEnabled());

  EXPECT_CALL(
      *legacy_delegate,
      UpdateSemantics(buffer, strings, std::vector<std::vector<uint8_t>>{}))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteSemanticsUpdate(buffer, strings));

  EXPECT_CALL(*legacy_delegate,
              UpdateCustomAccessibilityActions(buffer, strings))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteCustomAccessibilityActions(buffer, strings));

  EXPECT_CALL(*legacy_delegate, SetSemanticsEnabled(true))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteSemanticsEnabled(true));

  EXPECT_CALL(*legacy_delegate, DispatchSemanticsAction(
                                    42, kFlutterSemanticsActionTap, buffer, 0))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteDispatchSemanticsAction(
      42, kFlutterSemanticsActionTap, buffer, 0));

  EXPECT_CALL(*legacy_delegate, SetAccessibilityFeatures(15))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteSetAccessibilityFeatures(15));

  // 2. When Embedder is enabled -> routes to embedder_delegate (mock_invoker)
  JniRouter::SetEmbedderEnabled(true);
  EXPECT_TRUE(JniRouter::IsEmbedderEnabled());

  EXPECT_CALL(*legacy_delegate, UpdateSemantics(_, _, _)).Times(0);
  EXPECT_CALL(
      *mock_invoker,
      InvokeVoidMethod("updateSemantics",
                       "(Ljava/nio/ByteBuffer;[Ljava/lang/String;[Ljava/nio/"
                       "ByteBuffer;)V",
                       buffer))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteSemanticsUpdate(buffer, strings));

  EXPECT_CALL(*legacy_delegate, UpdateCustomAccessibilityActions(_, _))
      .Times(0);
  EXPECT_CALL(
      *mock_invoker,
      InvokeVoidMethod("updateCustomAccessibilityActions",
                       "(Ljava/nio/ByteBuffer;[Ljava/lang/String;)V", buffer))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteCustomAccessibilityActions(buffer, strings));

  EXPECT_CALL(*legacy_delegate, SetSemanticsEnabled(_)).Times(0);
  std::vector<uint8_t> enabled_payload = {1};
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("setSemanticsEnabled", "(Z)V", enabled_payload))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteSemanticsEnabled(true));

  EXPECT_CALL(*legacy_delegate, DispatchSemanticsAction(_, _, _, _)).Times(0);
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("dispatchSemanticsAction", "(II[BI)V", buffer))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteDispatchSemanticsAction(
      42, kFlutterSemanticsActionTap, buffer, 0));

  EXPECT_CALL(*legacy_delegate, SetAccessibilityFeatures(_)).Times(0);
  std::vector<uint8_t> features_payload = {0x0F, 0x00, 0x00, 0x00};
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("setAccessibilityFeatures",
                                              "(I)V", features_payload))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteSetAccessibilityFeatures(15));

  // Reset flag
  JniRouter::SetEmbedderEnabled(false);
  EXPECT_FALSE(JniRouter::IsEmbedderEnabled());
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

  EXPECT_CALL(
      *mock_invoker,
      InvokeVoidMethod(
          "updateSemantics",
          "(Ljava/nio/ByteBuffer;[Ljava/lang/String;[Ljava/nio/ByteBuffer;)V",
          ::testing::_))
      .WillOnce(Return(true));

  EXPECT_TRUE(native.UpdateSemantics(update));

  // OnUpdateSemantics2 static callback
  EXPECT_CALL(
      *mock_invoker,
      InvokeVoidMethod(
          "updateSemantics",
          "(Ljava/nio/ByteBuffer;[Ljava/lang/String;[Ljava/nio/ByteBuffer;)V",
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

TEST(PlatformViewsTest, JniRouterPlatformViewsRoutingFlip) {
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
  PlatformViewOverlay overlay = {.surface_id = 1};
  AndroidMutatorsStack stack;

  // 1. When Embedder is disabled -> routes to legacy_delegate
  JniRouter::SetEmbedderEnabled(false);
  EXPECT_FALSE(JniRouter::IsEmbedderEnabled());

  EXPECT_CALL(*legacy_delegate,
              CreatePlatformView(
                  params, PlatformViewCompositionType::kHybridComposition))
      .WillOnce(Return(0));
  EXPECT_EQ(router->RouteCreatePlatformView(
                params, PlatformViewCompositionType::kHybridComposition),
            0);

  EXPECT_CALL(*legacy_delegate, ResizePlatformView(resize_req))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteResizePlatformView(resize_req));

  EXPECT_CALL(*legacy_delegate, OffsetPlatformView(88, 10.0, 20.0))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteOffsetPlatformView(88, 10.0, 20.0));

  EXPECT_CALL(*legacy_delegate, SetPlatformViewDirection(88, 1))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteSetPlatformViewDirection(88, 1));

  EXPECT_CALL(*legacy_delegate, ClearPlatformViewFocus(88))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteClearPlatformViewFocus(88));

  EXPECT_CALL(*legacy_delegate, DispatchPlatformViewTouch(touch))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteDispatchPlatformViewTouch(touch));

  EXPECT_CALL(*legacy_delegate, OnDisplayPlatformView(geom))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteOnDisplayPlatformView(geom));

  EXPECT_CALL(*legacy_delegate, HidePlatformView(88)).WillOnce(Return(true));
  EXPECT_TRUE(router->RouteHidePlatformView(88));

  EXPECT_CALL(*legacy_delegate, SynchronizeToNativeViewHierarchy(true))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteSynchronizeToNativeViewHierarchy(true));

  EXPECT_CALL(*legacy_delegate, OnBeginFrame()).WillOnce(Return(true));
  EXPECT_TRUE(router->RouteBeginFrame());

  EXPECT_CALL(*legacy_delegate, OnEndFrame()).WillOnce(Return(true));
  EXPECT_TRUE(router->RouteEndFrame());

  EXPECT_CALL(*legacy_delegate, CreateOverlaySurface()).WillOnce(Return(5));
  EXPECT_EQ(router->RouteCreateOverlaySurface(), 5);

  EXPECT_CALL(*legacy_delegate, OnDisplayOverlaySurface(overlay))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteOnDisplayOverlaySurface(overlay));

  EXPECT_CALL(*legacy_delegate, ShowOverlaySurface(5)).WillOnce(Return(true));
  EXPECT_TRUE(router->RouteShowOverlaySurface(5));

  EXPECT_CALL(*legacy_delegate, HideOverlaySurface(5)).WillOnce(Return(true));
  EXPECT_TRUE(router->RouteHideOverlaySurface(5));

  EXPECT_CALL(*legacy_delegate, DestroyOverlaySurfaces())
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteDestroyOverlaySurfaces());

  EXPECT_CALL(*legacy_delegate, CreatePlatformViewTransaction())
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteCreatePlatformViewTransaction());

  EXPECT_CALL(*legacy_delegate, SwapPlatformViewTransactions())
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteSwapPlatformViewTransactions());

  EXPECT_CALL(*legacy_delegate, ApplyPlatformViewTransactions())
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteApplyPlatformViewTransactions());

  EXPECT_CALL(*legacy_delegate, IsHcppEnabled()).WillOnce(Return(true));
  EXPECT_TRUE(router->RouteIsHcppEnabled());

  EXPECT_CALL(*legacy_delegate,
              PushPlatformViewMutators(88, 0, 0, 100, 100, stack))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RoutePlatformViewMutators(88, 0, 0, 100, 100, stack));

  EXPECT_CALL(*legacy_delegate, DisposePlatformView(88)).WillOnce(Return(true));
  EXPECT_TRUE(router->RouteDisposePlatformView(88));

  // 2. When Embedder is enabled -> routes to embedder_delegate (mem_provider)
  JniRouter::SetEmbedderEnabled(true);
  EXPECT_TRUE(JniRouter::IsEmbedderEnabled());

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
  PlatformViewOverlay routed_overlay = {.surface_id = *created_overlay};
  EXPECT_TRUE(router->RouteOnDisplayOverlaySurface(routed_overlay));
  EXPECT_TRUE(router->RouteShowOverlaySurface(*created_overlay));
  EXPECT_TRUE(router->RouteHideOverlaySurface(*created_overlay));
  EXPECT_TRUE(router->RouteDestroyOverlaySurfaces());

  EXPECT_TRUE(router->RouteCreatePlatformViewTransaction());
  EXPECT_TRUE(router->RouteSwapPlatformViewTransactions());
  EXPECT_TRUE(router->RouteApplyPlatformViewTransactions());
  EXPECT_FALSE(router->RouteIsHcppEnabled());

  EXPECT_TRUE(router->RoutePlatformViewMutators(88, 0, 0, 100, 100, stack));

  EXPECT_TRUE(router->RouteDisposePlatformView(88));
  EXPECT_FALSE(mem_provider->IsViewCreated(88));

  JniRouter::SetEmbedderEnabled(false);
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

}  // namespace testing
}  // namespace android
}  // namespace flutter

int main(int argc, char* argv[]) {
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
