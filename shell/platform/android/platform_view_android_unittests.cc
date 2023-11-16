// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/platform_view_android.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "shell/platform/android/context/android_context.h"
#include "third_party/googletest/googlemock/include/gmock/gmock-nice-strict.h"

namespace flutter {
namespace testing {

using ::testing::NiceMock;
using ::testing::ReturnRef;

namespace {
class MockPlatformViewDelegate : public PlatformView::Delegate {
 public:
  MOCK_METHOD(void,
              OnPlatformViewCreated,
              (std::unique_ptr<Surface> surface),
              (override));

  MOCK_METHOD(void, OnPlatformViewDestroyed, (), (override));

  MOCK_METHOD(void, OnPlatformViewScheduleFrame, (), (override));

  MOCK_METHOD(void,
              OnPlatformViewSetNextFrameCallback,
              (const fml::closure& closure),
              (override));

  MOCK_METHOD(void,
              OnPlatformViewSetViewportMetrics,
              (int64_t view_id, const ViewportMetrics& metrics),
              (override));

  MOCK_METHOD(void,
              OnPlatformViewDispatchPlatformMessage,
              (std::unique_ptr<PlatformMessage> message),
              (override));

  MOCK_METHOD(void,
              OnPlatformViewDispatchPointerDataPacket,
              (std::unique_ptr<PointerDataPacket> packet),
              (override));

  MOCK_METHOD(void,
              OnPlatformViewDispatchSemanticsAction,
              (int32_t id, SemanticsAction action, fml::MallocMapping args),
              (override));

  MOCK_METHOD(void,
              OnPlatformViewSetSemanticsEnabled,
              (bool enabled),
              (override));

  MOCK_METHOD(void,
              OnPlatformViewSetAccessibilityFeatures,
              (int32_t flags),
              (override));

  MOCK_METHOD(void,
              OnPlatformViewRegisterTexture,
              (std::shared_ptr<Texture> texture),
              (override));

  MOCK_METHOD(void,
              OnPlatformViewUnregisterTexture,
              (int64_t texture_id),
              (override));

  MOCK_METHOD(void,
              OnPlatformViewMarkTextureFrameAvailable,
              (int64_t texture_id),
              (override));

  MOCK_METHOD(const Settings&,
              OnPlatformViewGetSettings,
              (),
              (const, override));

  MOCK_METHOD(void,
              LoadDartDeferredLibrary,
              (intptr_t loading_unit_id,
               std::unique_ptr<const fml::Mapping> snapshot_data,
               std::unique_ptr<const fml::Mapping> snapshot_instructions),
              (override));

  MOCK_METHOD(void,
              LoadDartDeferredLibraryError,
              (intptr_t loading_unit_id,
               const std::string error_message,
               bool transient),
              (override));

  MOCK_METHOD(void,
              UpdateAssetResolverByType,
              (std::unique_ptr<AssetResolver> updated_asset_resolver,
               AssetResolver::AssetResolverType type),
              (override));
};
}  // namespace

TEST(AndroidPlatformView, SelectsVulkanBasedOnApiLevel) {
  Settings settings;
  settings.enable_software_rendering = false;
  settings.enable_impeller = true;
  settings.impeller_backend = "vulkan";
  NiceMock<MockPlatformViewDelegate> mock_delegate;
  EXPECT_CALL(mock_delegate, OnPlatformViewGetSettings)
      .WillRepeatedly(ReturnRef(settings));

  TaskRunners task_runners("test", nullptr, nullptr, nullptr, nullptr);
  PlatformViewAndroid platform_view(/*delegate=*/mock_delegate,
                                    /*task_runners=*/task_runners,
                                    /*jni_facade=*/nullptr,
                                    /*use_software_rendering=*/false,
                                    /*msaa_samples=*/1);
  auto context = platform_view.GetAndroidContext();
  EXPECT_TRUE(context);
  int api_level = android_get_device_api_level();
  EXPECT_GT(api_level, 0);
  if (api_level >= 29) {
    EXPECT_TRUE(context->RenderingApi() == AndroidRenderingAPI::kVulkan);
  } else {
    EXPECT_TRUE(context->RenderingApi() == AndroidRenderingAPI::kOpenGLES);
  }
}

}  // namespace testing
}  // namespace flutter
