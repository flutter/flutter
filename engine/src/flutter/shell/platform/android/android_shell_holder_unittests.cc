// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>

#include "flutter/shell/platform/android/android_shell_holder.h"
#include "flutter/shell/platform/android/embedder_android_engine.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "shell/platform/android/jni/platform_view_android_jni.h"

namespace flutter {
namespace testing {
namespace {
class MockPlatformViewAndroidJNI : public PlatformViewAndroidJNI {
 public:
  MOCK_METHOD(void,
              FlutterViewHandlePlatformMessage,
              (std::unique_ptr<flutter::PlatformMessage> message,
               int responseId),
              (override));
  MOCK_METHOD(void,
              FlutterViewHandlePlatformMessageResponse,
              (int responseId, std::unique_ptr<fml::Mapping> data),
              (override));
  MOCK_METHOD(void,
              FlutterViewUpdateSemantics,
              (std::vector<uint8_t> buffer,
               std::vector<std::string> strings,
               std::vector<std::vector<uint8_t>> string_attribute_args),
              (override));
  MOCK_METHOD(void,
              FlutterViewSetSemanticsTreeEnabled,
              (bool enabled),
              (override));
  MOCK_METHOD(void,
              FlutterViewSetApplicationLocale,
              (const std::string locale),
              (override));
  MOCK_METHOD(void,
              FlutterViewUpdateCustomAccessibilityActions,
              (std::vector<uint8_t> actions_buffer,
               std::vector<std::string> strings),
              (override));
  MOCK_METHOD(void, FlutterViewOnFirstFrame, (), (override));
  MOCK_METHOD(void, FlutterViewOnPreEngineRestart, (), (override));
  MOCK_METHOD(void,
              SurfaceTextureAttachToGLContext,
              (JavaLocalRef surface_texture, int textureId),
              (override));
  MOCK_METHOD(bool,
              SurfaceTextureShouldUpdate,
              (JavaLocalRef surface_texture),
              (override));
  MOCK_METHOD(void,
              SurfaceTextureUpdateTexImage,
              (JavaLocalRef surface_texture),
              (override));
  MOCK_METHOD(SkM44,
              SurfaceTextureGetTransformMatrix,
              (JavaLocalRef surface_texture),
              (override));
  MOCK_METHOD(void,
              SurfaceTextureDetachFromGLContext,
              (JavaLocalRef surface_texture),
              (override));
  MOCK_METHOD(JavaLocalRef,
              ImageProducerTextureEntryAcquireLatestImage,
              (JavaLocalRef image_texture_entry),
              (override));
  MOCK_METHOD(JavaLocalRef,
              ImageGetHardwareBuffer,
              (JavaLocalRef image),
              (override));
  MOCK_METHOD(void, ImageClose, (JavaLocalRef image), (override));
  MOCK_METHOD(void,
              HardwareBufferClose,
              (JavaLocalRef hardware_buffer),
              (override));
  MOCK_METHOD(void,
              FlutterViewOnDisplayPlatformView,
              (int view_id,
               int x,
               int y,
               int width,
               int height,
               int viewWidth,
               int viewHeight,
               MutatorsStack mutators_stack),
              (override));
  MOCK_METHOD(void,
              FlutterViewDisplayOverlaySurface,
              (int surface_id, int x, int y, int width, int height),
              (override));
  MOCK_METHOD(void, FlutterViewBeginFrame, (), (override));
  MOCK_METHOD(void, FlutterViewEndFrame, (), (override));
  MOCK_METHOD(std::unique_ptr<PlatformViewAndroidJNI::OverlayMetadata>,
              FlutterViewCreateOverlaySurface,
              (),
              (override));
  MOCK_METHOD(void, FlutterViewDestroyOverlaySurfaces, (), (override));
  MOCK_METHOD(ASurfaceTransaction*, createTransaction, (), (override));
  MOCK_METHOD(void, swapTransaction, (), (override));
  MOCK_METHOD(void, destroyOverlaySurface2, (), (override));
  MOCK_METHOD(std::unique_ptr<PlatformViewAndroidJNI::OverlayMetadata>,
              createOverlaySurface2,
              (),
              (override));
  MOCK_METHOD(void,
              onDisplayPlatformView2,
              (int32_t view_id,
               int32_t x,
               int32_t y,
               int32_t width,
               int32_t height,
               int32_t viewWidth,
               int32_t viewHeight,
               MutatorsStack mutators_stack),
              (override));
  MOCK_METHOD(void, hidePlatformView2, (int32_t view_id), (override));
  MOCK_METHOD(void, onEndFrame2, (), (override));
  MOCK_METHOD(void, showOverlaySurface2, (), (override));
  MOCK_METHOD(void, hideOverlaySurface2, (), (override));
  MOCK_METHOD(std::unique_ptr<std::vector<std::string>>,
              FlutterViewComputePlatformResolvedLocale,
              (std::vector<std::string> supported_locales_data),
              (override));
  MOCK_METHOD(double, GetDisplayRefreshRate, (), (override));
  MOCK_METHOD(double, GetDisplayWidth, (), (override));
  MOCK_METHOD(double, GetDisplayHeight, (), (override));
  MOCK_METHOD(double, GetDisplayDensity, (), (override));
  MOCK_METHOD(bool,
              RequestDartDeferredLibrary,
              (int loading_unit_id),
              (override));
  MOCK_METHOD(double,
              FlutterViewGetScaledFontSize,
              (double font_size, int configuration_id),
              (const, override));
  MOCK_METHOD(void,
              MaybeResizeSurfaceView,
              (int32_t width, int32_t height),
              (const, override));
};

class MockPlatformMessageResponse : public PlatformMessageResponse {
 public:
  static fml::RefPtr<MockPlatformMessageResponse> Create() {
    return fml::AdoptRef(new MockPlatformMessageResponse());
  }
  MOCK_METHOD(void, Complete, (std::unique_ptr<fml::Mapping> data), (override));
  MOCK_METHOD(void, CompleteEmpty, (), (override));
};
}  // namespace

TEST(AndroidShellHolder, Create) {
  Settings settings;
  settings.enable_software_rendering = false;
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kImpellerOpenGLES);
  EXPECT_NE(holder.get(), nullptr);
  EXPECT_TRUE(holder->IsValid());
  EXPECT_NE(holder->GetPlatformView().get(), nullptr);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  holder->GetPlatformView()->NotifyCreated(window);
}

TEST(AndroidShellHolder, HandlePlatformMessage) {
  Settings settings;
  settings.enable_software_rendering = false;
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kImpellerOpenGLES);
  EXPECT_NE(holder.get(), nullptr);
  EXPECT_TRUE(holder->IsValid());
  EXPECT_NE(holder->GetPlatformView().get(), nullptr);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  holder->GetPlatformView()->NotifyCreated(window);
  EXPECT_TRUE(holder->GetPlatformMessageHandler());
  size_t data_size = 4;
  fml::MallocMapping bytes =
      fml::MallocMapping(static_cast<uint8_t*>(malloc(data_size)), data_size);
  fml::RefPtr<MockPlatformMessageResponse> response =
      MockPlatformMessageResponse::Create();
  auto message = std::make_unique<PlatformMessage>(
      /*channel=*/"foo", /*data=*/std::move(bytes), /*response=*/response);
  int response_id = 1;
  EXPECT_CALL(*jni,
              FlutterViewHandlePlatformMessage(::testing::_, response_id));
  EXPECT_CALL(*response, CompleteEmpty());
  holder->GetPlatformMessageHandler()->HandlePlatformMessage(
      std::move(message));
  holder->GetPlatformMessageHandler()
      ->InvokePlatformMessageEmptyResponseCallback(response_id);
}

TEST(AndroidShellHolder, CreateWithMergedPlatformAndUIThread) {
  Settings settings;
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kImpellerOpenGLES);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  holder->GetPlatformView()->NotifyCreated(window);

  EXPECT_EQ(
      holder->GetShellForTesting()->GetTaskRunners().GetUITaskRunner(),
      holder->GetShellForTesting()->GetTaskRunners().GetPlatformTaskRunner());
}

TEST(AndroidShellHolder, CreateWithUnMergedPlatformAndUIThread) {
  Settings settings;
  settings.merged_platform_ui_thread =
      Settings::MergedPlatformUIThread::kDisabled;
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kImpellerOpenGLES);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  holder->GetPlatformView()->NotifyCreated(window);

  EXPECT_NE(
      holder->GetShellForTesting()->GetTaskRunners().GetUITaskRunner(),
      holder->GetShellForTesting()->GetTaskRunners().GetPlatformTaskRunner());
}

TEST(AndroidShellHolder, CreateWithEmbedderAPI) {
  Settings settings;
  settings.enable_software_rendering = false;
  settings.enable_embedder_api = true;
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kImpellerOpenGLES);
  EXPECT_NE(holder.get(), nullptr);
  EXPECT_TRUE(holder->IsValid());
  EXPECT_NE(holder->GetEngineForTesting(), nullptr);
  EXPECT_NE(holder->GetPlatformView().get(), nullptr);

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  holder->GetPlatformView()->NotifyCreated(window);

  ViewportMetrics metrics{1.0, 800, 600, 22.0, 0};
  holder->GetPlatformView()->SetViewportMetrics(0, metrics);
  holder->NotifyLowMemoryWarning();
  holder->GetPlatformView()->SetSemanticsEnabled(true);
  holder->GetPlatformView()->SetAccessibilityFeatures(0);
  holder->GetEngineForTesting()->DispatchSemanticsAction(
      0, 1, SemanticsAction::kTap, fml::MallocMapping());
  holder->GetPlatformView()->MarkTextureFrameAvailable(0);
  holder->GetPlatformView()->UnregisterTexture(0);
  holder->GetPlatformView()->LoadDartDeferredLibrary(
      1, std::make_unique<const fml::NonOwnedMapping>(nullptr, 0),
      std::make_unique<const fml::NonOwnedMapping>(nullptr, 0));
  holder->GetPlatformView()->LoadDartDeferredLibraryError(1, "error", true);

  class FakeAPKAssetProviderInternal : public APKAssetProviderInternal {
   public:
    std::unique_ptr<fml::Mapping> GetAsMapping(
        const std::string& asset_name) const override {
      return nullptr;
    }
  };
  holder->GetEngineForTesting()->UpdateAssetResolverByType(
      std::make_unique<APKAssetProvider>(
          std::make_shared<FakeAPKAssetProviderInternal>()),
      AssetResolver::AssetResolverType::kApkAssetProvider);

  std::vector<std::unique_ptr<Display>> displays;
  displays.push_back(std::make_unique<Display>(0, 60.0, 800.0, 600.0, 1.0));
  holder->GetEngineForTesting()->OnDisplayUpdates(std::move(displays));
  holder->GetEngineForTesting()->SetNextFrameCallback([]() {});
  holder->Screenshot(Rasterizer::ScreenshotType::UncompressedImage, false);
  holder->GetPlatformView()->NotifyDestroyed();
}

TEST(AndroidShellHolder, LaunchWithEmbedderAPI) {
  Settings settings;
  settings.enable_software_rendering = false;
  settings.enable_embedder_api = true;
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kImpellerOpenGLES);
  EXPECT_NE(holder.get(), nullptr);
  EXPECT_TRUE(holder->IsValid());

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  holder->GetPlatformView()->NotifyCreated(window);

  holder->Launch(nullptr, "main", "", {}, 1);
  EXPECT_TRUE(holder->IsValid());

  holder->GetPlatformView()->NotifyDestroyed();
}

TEST(AndroidShellHolder, RoutesOperationsThroughEmbedderProcTable) {
  Settings settings;
  settings.enable_software_rendering = false;
  settings.enable_embedder_api = true;
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kImpellerOpenGLES);
  ASSERT_NE(holder.get(), nullptr);
  ASSERT_TRUE(holder->IsValid());

  auto* embedder_engine =
      static_cast<EmbedderAndroidEngine*>(holder->GetEngineForTesting());
  ASSERT_NE(embedder_engine, nullptr);
  auto& proc_table = embedder_engine->GetMutableProcTableForTesting();

  static int s_pointer_calls = 0;
  static int s_platform_msg_calls = 0;
  static int s_platform_resp_calls = 0;
  static int s_low_memory_calls = 0;
  static int s_unregister_tex_calls = 0;
  static int s_mark_tex_calls = 0;
  s_pointer_calls = 0;
  s_platform_msg_calls = 0;
  s_platform_resp_calls = 0;
  s_low_memory_calls = 0;
  s_unregister_tex_calls = 0;
  s_mark_tex_calls = 0;

  auto orig_send_pointer = proc_table.SendPointerEvent;
  proc_table.SendPointerEvent = [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                                   const FlutterPointerEvent* events,
                                   size_t events_count) -> FlutterEngineResult {
    s_pointer_calls++;
    return kSuccess;
  };

  auto orig_send_msg = proc_table.SendPlatformMessage;
  proc_table.SendPlatformMessage =
      [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
         const FlutterPlatformMessage* message) -> FlutterEngineResult {
    s_platform_msg_calls++;
    return kSuccess;
  };

  auto orig_send_resp = proc_table.SendPlatformMessageResponse;
  static FlutterEngineSendPlatformMessageResponseFnPtr s_orig_send_resp =
      nullptr;
  s_orig_send_resp = orig_send_resp;
  proc_table.SendPlatformMessageResponse =
      [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
         const FlutterPlatformMessageResponseHandle* handle,
         const uint8_t* data, size_t data_length) -> FlutterEngineResult {
    s_platform_resp_calls++;
    return s_orig_send_resp(engine, handle, data, data_length);
  };

  proc_table.NotifyLowMemoryWarning = [](FLUTTER_API_SYMBOL(FlutterEngine)
                                             engine) -> FlutterEngineResult {
    s_low_memory_calls++;
    return kSuccess;
  };

  proc_table.UnregisterExternalTexture =
      [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
         int64_t texture_identifier) -> FlutterEngineResult {
    s_unregister_tex_calls++;
    return kSuccess;
  };

  proc_table.MarkExternalTextureFrameAvailable =
      [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
         int64_t texture_identifier) -> FlutterEngineResult {
    s_mark_tex_calls++;
    return kSuccess;
  };

  // Re-bind handler with the updated proc_table.
  embedder_engine->SetPlatformMessageHandler(
      holder->GetPlatformMessageHandler());

  // 1. Pointer events via SendPointerEvent
  auto packet = std::make_unique<PointerDataPacket>(1);
  PointerData data = {};
  data.Clear();
  data.change = PointerData::Change::kDown;
  data.kind = PointerData::DeviceKind::kTouch;
  packet->SetPointerData(0, data);
  holder->GetPlatformView()->DispatchPointerDataPacket(std::move(packet));
  EXPECT_EQ(s_pointer_calls, 1);

  // 2. App -> Dart PlatformMessage via SendPlatformMessage
  auto out_msg = std::make_unique<PlatformMessage>("test_channel", nullptr);
  embedder_engine->DispatchPlatformMessage(std::move(out_msg));
  EXPECT_EQ(s_platform_msg_calls, 1);

  // 3. Dart -> App PlatformMessage response via SendPlatformMessageResponse
  fml::RefPtr<MockPlatformMessageResponse> response =
      MockPlatformMessageResponse::Create();
  auto in_msg = std::make_unique<PlatformMessage>("dart_channel", response);
  EXPECT_CALL(*jni, FlutterViewHandlePlatformMessage(::testing::_, 1));
  EXPECT_CALL(*response, CompleteEmpty());
  holder->GetPlatformMessageHandler()->HandlePlatformMessage(std::move(in_msg));
  holder->GetPlatformMessageHandler()
      ->InvokePlatformMessageEmptyResponseCallback(1);
  EXPECT_EQ(s_platform_resp_calls, 1);

  // 4. Low memory & texture operations via proc_table
  holder->NotifyLowMemoryWarning();
  EXPECT_EQ(s_low_memory_calls, 1);
  holder->GetPlatformView()->MarkTextureFrameAvailable(42);
  EXPECT_EQ(s_mark_tex_calls, 1);
  holder->GetPlatformView()->UnregisterTexture(42);
  EXPECT_EQ(s_unregister_tex_calls, 1);

  // 5. UpdateSemantics via EmbedderSemanticsUpdate2
  SemanticsNodeUpdates nodes;
  SemanticsNode node;
  node.id = 0;
  node.label = "hello";
  nodes[0] = node;
  CustomAccessibilityActionUpdates actions;
  EXPECT_CALL(*jni, FlutterViewUpdateSemantics(::testing::_, ::testing::_,
                                               ::testing::_));
  holder->GetPlatformView()->UpdateSemantics(0, nodes, actions);

  proc_table.SendPointerEvent = orig_send_pointer;
  proc_table.SendPlatformMessage = orig_send_msg;
  proc_table.SendPlatformMessageResponse = orig_send_resp;
}

}  // namespace testing
}  // namespace flutter
