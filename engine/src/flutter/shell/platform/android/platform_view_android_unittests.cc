// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/platform_view_android.h"

#include <android/api-level.h>
#include <memory>
#include <string>

#include "flutter/common/settings.h"
#include "flutter/shell/platform/android/android_shell_holder.h"
#include "flutter/shell/platform/android/context/android_context.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "impeller/renderer/backend/vulkan/capabilities_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "shell/platform/android/flutter_main.h"

#include "third_party/googletest/googlemock/include/gmock/gmock-nice-strict.h"

namespace flutter {
namespace testing {

namespace {

// Android 10 (API 29): minimum SDK version where Impeller Vulkan and NDK
// ASurfaceControl exist, where enabling AHB swapchain crashes (#155877).
constexpr int kApiLevelAndroid10 = 29;
// Android 11 (API 30) and Android 13 (API 33): pre-HCPP SDK versions where
// SurfaceControl swapchains must remain disabled.
constexpr int kApiLevelAndroid11 = 30;
constexpr int kApiLevelAndroid13 = 33;
// Android 14 (API 34): minimum SDK version supporting HCPP and
// ASurfaceTransaction_fromJava.
constexpr int kApiLevelAndroid14 = 34;
// Android 15 (API 35): post-Android 14 SDK version.
constexpr int kApiLevelAndroid15 = 35;

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
  MOCK_METHOD(ASurfaceTransaction*,
              createTransaction,
              (std::function<void()>&),
              (override));
  MOCK_METHOD(void, sealFrameTransactions, (), (override));
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

}  // namespace

// TODO(matanlurey): Re-enable.
//
// This test (and the entire suite) was skipped on CI (see
// https://github.com/flutter/flutter/issues/163742) and has since bit rotted
// (we fallback to OpenGLES on emulators for performance reasons); either fix
// the test, or remove it.
#if !SLIMPELLER
TEST(AndroidPlatformView, DISABLED_SelectsVulkanBasedOnApiLevel) {
  Settings settings;
  settings.enable_software_rendering = false;
  settings.enable_impeller = true;

  EXPECT_EQ(FlutterMain::SelectedRenderingAPI(settings, kApiLevelAndroid10),
            AndroidRenderingAPI::kImpellerVulkan);
  EXPECT_EQ(FlutterMain::SelectedRenderingAPI(settings, 24),
            AndroidRenderingAPI::kImpellerOpenGLES);
}
#endif  // !SLIMPELLER

TEST(AndroidPlatformView, CreateContextSettingsGatesSurfaceControlOnApi34) {
  Settings settings;
  settings.enable_surface_control = true;
  settings.enable_vulkan_gpu_tracing = true;
  settings.enable_vulkan_validation = true;

  // Below API 34, SurfaceControl swapchains must remain disabled even when
  // EnableHcpp / enable_surface_control is true.
  for (int api_level :
       {kApiLevelAndroid10, kApiLevelAndroid11, kApiLevelAndroid13}) {
    AndroidContext::ContextSettings context_settings =
        PlatformViewAndroid::CreateContextSettings(settings, api_level);
    EXPECT_FALSE(context_settings.enable_surface_control)
        << "Expected enable_surface_control to be false on API " << api_level;
    EXPECT_TRUE(context_settings.enable_gpu_tracing);
    EXPECT_TRUE(context_settings.enable_validation);
  }

  // On API 34+, enable_surface_control reflects
  // Settings::enable_surface_control.
  for (int api_level : {kApiLevelAndroid14, kApiLevelAndroid15}) {
    AndroidContext::ContextSettings context_settings =
        PlatformViewAndroid::CreateContextSettings(settings, api_level);
    EXPECT_TRUE(context_settings.enable_surface_control)
        << "Expected enable_surface_control to be true on API " << api_level;
  }

  settings.enable_surface_control = false;
  EXPECT_FALSE(
      PlatformViewAndroid::CreateContextSettings(settings, kApiLevelAndroid14)
          .enable_surface_control);
}

TEST(AndroidPlatformView,
     ShellHolderDoesNotEnableSurfaceControlSwapchainBelowApi34) {
  Settings settings;
  settings.enable_software_rendering = false;
  settings.enable_impeller = true;
  settings.enable_surface_control = true;

  auto jni =
      std::make_shared<::testing::NiceMock<MockPlatformViewAndroidJNI>>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kImpellerAutoselect);
  ASSERT_NE(holder.get(), nullptr);
  ASSERT_TRUE(holder->IsValid());
  ASSERT_NE(holder->GetPlatformView().get(), nullptr);

  holder->GetPlatformView()->SetupImpellerContext();

  const int device_api_level = android_get_device_api_level();
  const auto& android_context = holder->GetPlatformView()->GetAndroidContext();
  ASSERT_NE(android_context, nullptr);

  if (device_api_level < kApiLevelAndroid14) {
    EXPECT_FALSE(holder->IsSurfaceControlEnabled());
    if (android_context->RenderingApi() ==
        AndroidRenderingAPI::kImpellerVulkan) {
      const auto& vk_context =
          impeller::ContextVK::Cast(*android_context->GetImpellerContext());
      EXPECT_FALSE(vk_context.GetShouldEnableSurfaceControlSwapchain());
    }
  } else if (android_context->RenderingApi() ==
             AndroidRenderingAPI::kImpellerVulkan) {
    const auto& vk_context =
        impeller::ContextVK::Cast(*android_context->GetImpellerContext());
    const bool supports_external_semaphore =
        impeller::CapabilitiesVK::Cast(*vk_context.GetCapabilities())
            .SupportsExternalSemaphoreExtensions();
    EXPECT_EQ(vk_context.GetShouldEnableSurfaceControlSwapchain(),
              supports_external_semaphore);
    EXPECT_EQ(holder->IsSurfaceControlEnabled(), supports_external_semaphore);
  }
}

}  // namespace testing
}  // namespace flutter
