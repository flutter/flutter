// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/platform_view_android.h"

#include <memory>
#include <string>
#include <string_view>

#include "flutter/common/settings.h"
#include "flutter/common/task_runners.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/platform/android/context/android_context.h"
#include "flutter/shell/platform/android/jni/jni_mock.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "impeller/base/promise.h"
#include "impeller/renderer/capabilities.h"
#include "impeller/renderer/testing/mocks.h"
#include "shell/platform/android/flutter_main.h"
#include "third_party/googletest/googlemock/include/gmock/gmock-nice-strict.h"

namespace flutter {
namespace testing {

namespace {

using ::testing::_;
using ::testing::AtLeast;
using ::testing::NiceMock;
using ::testing::Return;
using ::testing::ReturnRef;

class MockPlatformViewDelegate : public PlatformView::Delegate {
 public:
  MOCK_METHOD(void,
              OnPlatformViewCreated,
              (std::unique_ptr<Surface>),
              (override));
  MOCK_METHOD(void, OnPlatformViewDestroyed, (), (override));
  MOCK_METHOD(void, OnPlatformViewScheduleFrame, (), (override));
  MOCK_METHOD(void,
              OnPlatformViewAddView,
              (int64_t view_id,
               const ViewportMetrics& viewport_metrics,
               AddViewCallback callback),
              (override));
  MOCK_METHOD(void,
              OnPlatformViewRemoveView,
              (int64_t view_id, RemoveViewCallback callback),
              (override));
  MOCK_METHOD(void,
              OnPlatformViewSendViewFocusEvent,
              (const ViewFocusEvent& event),
              (override));
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
  MOCK_METHOD(HitTestResponse,
              OnPlatformViewHitTest,
              (int64_t view_id, const flutter::PointData offset),
              (override));
  MOCK_METHOD(void,
              OnPlatformViewDispatchSemanticsAction,
              (int64_t view_id,
               int32_t node_id,
               SemanticsAction action,
               fml::MallocMapping args),
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
  MOCK_METHOD(const Settings&,
              OnPlatformViewGetSettings,
              (),
              (const, override));
  MOCK_METHOD(std::shared_ptr<fml::BasicTaskRunner>,
              OnPlatformViewGetShutdownSafeIOTaskRunner,
              (),
              (const, override));
};

/// An Android context that renders in software, so that a platform view can
/// be created without a GPU, but that hands out the given Impeller context.
class FakeAndroidContext final : public AndroidContext {
 public:
  explicit FakeAndroidContext(
      const std::shared_ptr<impeller::Context>& impeller_context)
      : AndroidContext(AndroidRenderingAPI::kSoftware) {
    SetImpellerContext(impeller_context);
  }
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

  EXPECT_EQ(FlutterMain::SelectedRenderingAPI(settings, 29),
            AndroidRenderingAPI::kImpellerVulkan);
  EXPECT_EQ(FlutterMain::SelectedRenderingAPI(settings, 24),
            AndroidRenderingAPI::kImpellerOpenGLES);
}
#endif  // !SLIMPELLER

// The software backend is needed to create a platform view without a GPU.
#if !SLIMPELLER
TEST(AndroidPlatformView, SetupImpellerContextWarmsDefaultPipelines) {
  // The test calls SetupImpellerContext directly, as the shell would on the
  // raster thread, so the platform view never posts any tasks.
  TaskRunners task_runners("SetupImpellerContextWarmsDefaultPipelines", nullptr,
                           nullptr, nullptr, nullptr);

  // An Impeller context with no GPU behind it, whose shader library resolves
  // every shader.
  std::shared_ptr<const impeller::Capabilities> capabilities =
      impeller::CapabilitiesBuilder()
          .SetDefaultColorFormat(impeller::PixelFormat::kR8G8B8A8UNormInt)
          .SetDefaultDepthStencilFormat(impeller::PixelFormat::kD24UnormS8Uint)
          .SetDefaultGlyphAtlasFormat(impeller::PixelFormat::kA8UNormInt)
          .Build();
  auto shader_library =
      std::make_shared<NiceMock<impeller::testing::MockShaderLibrary>>();
  ON_CALL(*shader_library, GetFunction(_, _))
      .WillByDefault([](std::string_view name, impeller::ShaderStage stage) {
        return std::make_shared<impeller::testing::MockShaderFunction>(
            std::string(name), stage);
      });
  auto pipeline_library =
      std::make_shared<NiceMock<impeller::testing::MockPipelineLibrary>>();
  auto impeller_context =
      std::make_shared<NiceMock<impeller::testing::MockImpellerContext>>();
  ON_CALL(*impeller_context, IsValid()).WillByDefault(Return(true));
  ON_CALL(*impeller_context, GetBackendType())
      .WillByDefault(Return(impeller::Context::BackendType::kOpenGLES));
  ON_CALL(*impeller_context, GetCapabilities())
      .WillByDefault(ReturnRef(capabilities));
  ON_CALL(*impeller_context, GetShaderLibrary())
      .WillByDefault(Return(shader_library));
  ON_CALL(*impeller_context, GetPipelineLibrary())
      .WillByDefault(Return(pipeline_library));

  // The pipelines are requested asynchronously, before any surface exists.
  EXPECT_CALL(*pipeline_library, GetPipeline(_, /*async=*/false, _)).Times(0);
  EXPECT_CALL(*pipeline_library, GetPipeline(_, /*async=*/true, _))
      .Times(AtLeast(1))
      .WillRepeatedly([](impeller::PipelineDescriptor descriptor, bool, bool) {
        return impeller::PipelineFuture<impeller::PipelineDescriptor>{
            std::move(descriptor),
            impeller::RealizedFuture<std::shared_ptr<
                impeller::Pipeline<impeller::PipelineDescriptor>>>(nullptr)};
      });

  Settings settings;
  NiceMock<MockPlatformViewDelegate> delegate;
  ON_CALL(delegate, OnPlatformViewGetSettings())
      .WillByDefault(ReturnRef(settings));
  PlatformViewAndroid platform_view(
      delegate, task_runners, std::make_shared<JNIMock>(),
      std::make_shared<FakeAndroidContext>(impeller_context));

  platform_view.SetupImpellerContext();
}
#endif  // !SLIMPELLER

}  // namespace testing
}  // namespace flutter
