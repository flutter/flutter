// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/platform_view_android.h"

#include <android/api-level.h>
#include <memory>
#include <string>
#include <string_view>

#include "flutter/common/settings.h"
#include "flutter/common/task_runners.h"
#include "flutter/fml/thread.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/platform/android/android_shell_holder.h"
#include "flutter/shell/platform/android/context/android_context.h"
#include "flutter/shell/platform/android/jni/jni_mock.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/testing/post_task_sync.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "impeller/base/promise.h"
#include "impeller/renderer/backend/vulkan/capabilities_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/capabilities.h"
#include "impeller/renderer/testing/mocks.h"
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

using ::testing::_;
using ::testing::AtLeast;
using ::testing::NiceMock;
using ::testing::Return;
using ::testing::ReturnRef;
using ::testing::ReturnRefOfCopy;

class MockPlatformViewDelegate : public PlatformView::Delegate {
 public:
  MOCK_METHOD(void,
              OnPlatformViewCreated,
              (std::unique_ptr<Surface>),
              (override));
  MOCK_METHOD(void,
              OnPlatformViewCreatedDeferred,
              (PlatformView::SurfaceFactory surface_factory),
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

// The software backend is needed to create a platform view without a GPU.
#if !SLIMPELLER
namespace {

/// Creates an Impeller context of the given backend with no GPU behind it,
/// whose shader library resolves every shader.
std::shared_ptr<impeller::testing::MockImpellerContext>
CreateImpellerContextWithoutGPU(
    impeller::Context::BackendType backend_type,
    const std::shared_ptr<impeller::PipelineLibrary>& pipeline_library) {
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
  auto impeller_context =
      std::make_shared<NiceMock<impeller::testing::MockImpellerContext>>();
  ON_CALL(*impeller_context, IsValid()).WillByDefault(Return(true));
  ON_CALL(*impeller_context, GetBackendType())
      .WillByDefault(Return(backend_type));
  ON_CALL(*impeller_context, GetCapabilities())
      .WillByDefault(ReturnRefOfCopy(capabilities));
  ON_CALL(*impeller_context, GetShaderLibrary())
      .WillByDefault(Return(shader_library));
  ON_CALL(*impeller_context, GetPipelineLibrary())
      .WillByDefault(Return(pipeline_library));
  return impeller_context;
}

/// Returns a future for a pipeline that is never created.
impeller::PipelineFuture<impeller::PipelineDescriptor> ReturnNullPipeline(
    impeller::PipelineDescriptor descriptor,
    bool /*async*/,
    bool /*threadsafe*/) {
  return impeller::PipelineFuture<impeller::PipelineDescriptor>{
      std::move(descriptor),
      impeller::RealizedFuture<
          std::shared_ptr<impeller::Pipeline<impeller::PipelineDescriptor>>>(
          nullptr)};
}

}  // namespace

/// Has a real raster thread for the default pipelines to be warmed on.
class DefaultPipelineWarmUpTest : public ::testing::Test {
 protected:
  DefaultPipelineWarmUpTest()
      : raster_thread_("raster"),
        task_runners_("DefaultPipelineWarmUpTest",
                      nullptr,
                      raster_thread_.GetTaskRunner(),
                      nullptr,
                      nullptr) {
    ON_CALL(delegate_, OnPlatformViewGetSettings())
        .WillByDefault(ReturnRef(settings_));
  }

  std::unique_ptr<PlatformViewAndroid> CreatePlatformView(
      const std::shared_ptr<AndroidContext>& android_context) {
    return std::make_unique<PlatformViewAndroid>(
        delegate_, task_runners_, std::make_shared<JNIMock>(), android_context);
  }

  /// Waits for the tasks posted to the raster thread so far to run.
  void FlushRasterThread() {
    PostTaskSync(GetRasterTaskRunner(), []() {});
  }

  fml::RefPtr<fml::TaskRunner> GetRasterTaskRunner() const {
    return task_runners_.GetRasterTaskRunner();
  }

 private:
  fml::Thread raster_thread_;
  TaskRunners task_runners_;
  Settings settings_;
  NiceMock<MockPlatformViewDelegate> delegate_;
};

// Warming the default pipelines from SetupImpellerContext deadlocks startup.
// See |PlatformViewAndroid::CreateResourceContext|.
TEST_F(DefaultPipelineWarmUpTest,
       SetupImpellerContextDoesNotWarmDefaultPipelines) {
  auto pipeline_library =
      std::make_shared<NiceMock<impeller::testing::MockPipelineLibrary>>();
  EXPECT_CALL(*pipeline_library, GetPipeline(_, _, _)).Times(0);
  std::unique_ptr<PlatformViewAndroid> platform_view = CreatePlatformView(
      std::make_shared<FakeAndroidContext>(CreateImpellerContextWithoutGPU(
          impeller::Context::BackendType::kOpenGLES, pipeline_library)));

  PostTaskSync(GetRasterTaskRunner(),
               [&platform_view]() { platform_view->SetupImpellerContext(); });
  FlushRasterThread();
}

TEST_F(DefaultPipelineWarmUpTest, WarmsDefaultPipelinesOnRasterThreadForGLES) {
  auto pipeline_library =
      std::make_shared<NiceMock<impeller::testing::MockPipelineLibrary>>();
  // The pipelines are requested asynchronously on the raster thread.
  EXPECT_CALL(*pipeline_library, GetPipeline(_, /*async=*/false, _)).Times(0);
  EXPECT_CALL(*pipeline_library, GetPipeline(_, /*async=*/true, _))
      .Times(AtLeast(1))
      .WillRepeatedly([this](impeller::PipelineDescriptor descriptor,
                             bool async, bool threadsafe) {
        EXPECT_TRUE(GetRasterTaskRunner()->RunsTasksOnCurrentThread());
        return ReturnNullPipeline(std::move(descriptor), async, threadsafe);
      });
  FakeAndroidContext android_context(CreateImpellerContextWithoutGPU(
      impeller::Context::BackendType::kOpenGLES, pipeline_library));

  // Called on this thread, standing in for the IO thread.
  android_context.StartWarmingDefaultPipelines(GetRasterTaskRunner());
  FlushRasterThread();
}

// Platform views that share an Android context, such as those of spawned
// engines, only warm its default pipelines once.
TEST_F(DefaultPipelineWarmUpTest, WarmsDefaultPipelinesOnlyOnce) {
  auto pipeline_library =
      std::make_shared<NiceMock<impeller::testing::MockPipelineLibrary>>();
  size_t requested_pipelines = 0;
  ON_CALL(*pipeline_library, GetPipeline(_, _, _))
      .WillByDefault(
          [&requested_pipelines](impeller::PipelineDescriptor descriptor,
                                 bool async, bool threadsafe) {
            requested_pipelines++;
            return ReturnNullPipeline(std::move(descriptor), async, threadsafe);
          });
  FakeAndroidContext android_context(CreateImpellerContextWithoutGPU(
      impeller::Context::BackendType::kOpenGLES, pipeline_library));

  android_context.StartWarmingDefaultPipelines(GetRasterTaskRunner());
  FlushRasterThread();
  const size_t requested_by_first_warm_up = requested_pipelines;
  EXPECT_GT(requested_by_first_warm_up, 0u);

  android_context.StartWarmingDefaultPipelines(GetRasterTaskRunner());
  FlushRasterThread();
  EXPECT_EQ(requested_pipelines, requested_by_first_warm_up);
}

TEST_F(DefaultPipelineWarmUpTest, DoesNotWarmDefaultPipelinesForVulkan) {
  auto pipeline_library =
      std::make_shared<NiceMock<impeller::testing::MockPipelineLibrary>>();
  EXPECT_CALL(*pipeline_library, GetPipeline(_, _, _)).Times(0);
  FakeAndroidContext android_context(CreateImpellerContextWithoutGPU(
      impeller::Context::BackendType::kVulkan, pipeline_library));

  android_context.StartWarmingDefaultPipelines(GetRasterTaskRunner());
  FlushRasterThread();
}
#endif  // !SLIMPELLER

}  // namespace testing
}  // namespace flutter
