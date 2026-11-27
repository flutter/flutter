// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <utility>
#include <vector>

#include "flutter/fml/message_loop_task_queues.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/platform/android/android_shell_holder.h"
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

namespace {

// Probes whether `Rasterizer::Setup` has populated `surface_` without invoking
// `Surface::AcquireFrame` (requires viewport metrics on view 0 that exclude
// `DlISize(1, 1)` so `ShouldDiscardLayerTree` discards the task once `surface_`
// is present, returning `kDone`, whereas a null `surface_` returns
// `kNotSetUp`).
DrawStatus ProbeRasterizerSetupStatus(Rasterizer& rasterizer) {
  auto pipeline = std::make_shared<FramePipeline>(1);
  auto recorder = std::make_unique<FrameTimingsRecorder>();
  const fml::TimePoint now = fml::TimePoint::Now();
  recorder->RecordVsync(now, now + fml::TimeDelta::FromSeconds(3600));
  recorder->RecordBuildStart(now);
  recorder->RecordBuildEnd(now);
  std::vector<std::unique_ptr<LayerTreeTask>> tasks;
  tasks.push_back(std::make_unique<LayerTreeTask>(
      /*view_id=*/0,
      std::make_unique<LayerTree>(/*root_layer=*/nullptr, DlISize(1, 1)),
      /*device_pixel_ratio=*/1.0f));
  auto continuation = pipeline->Produce();
  PipelineProduceResult produce_result = continuation.Complete(
      std::make_unique<FrameItem>(std::move(tasks), std::move(recorder)));
  EXPECT_TRUE(produce_result.success);
  return rasterizer.Draw(pipeline);
}

}  // namespace

TEST(AndroidShellHolder, NotifyCreatedAndChangedDoNotBlockPlatformThread) {
  Settings settings;
  settings.enable_software_rendering = false;
#if defined(NDEBUG) || SLIMPELLER
  constexpr AndroidRenderingAPI kRenderingApi =
      AndroidRenderingAPI::kImpellerOpenGLES;
#else
  // In `--unoptimized` (`!NDEBUG`) builds, `AndroidContextGLImpeller` does not
  // create a pbuffer fallback for fake windows, so `CreateGPUSurface` hits a
  // pre-existing `FML_DCHECK(CanReactOnCurrentThread())` in `ReactorGLES`.
  constexpr AndroidRenderingAPI kRenderingApi =
      AndroidRenderingAPI::kSkiaOpenGLES;
  settings.enable_impeller = false;
#endif
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  auto holder =
      std::make_unique<AndroidShellHolder>(settings, jni, kRenderingApi);
  ASSERT_NE(holder, nullptr);
  ASSERT_TRUE(holder->IsValid());
  holder->GetPlatformView()->SetViewportMetrics(
      0, ViewportMetrics{1.0, 100, 100, 22, 0});

  auto raster_runner =
      holder->GetShellForTesting()->GetTaskRunners().GetRasterTaskRunner();
  fml::AutoResetWaitableEvent raster_entered;
  fml::AutoResetWaitableEvent unblock_raster;
  raster_runner->PostTask([&raster_entered, &unblock_raster]() {
    raster_entered.Signal();
    unblock_raster.Wait();
  });
  raster_entered.Wait();

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  holder->GetPlatformView()->NotifyCreated(window);
  holder->GetPlatformView()->NotifyChanged(DlISize(1080, 1920));

  unblock_raster.Signal();

  DrawStatus status_after_create = DrawStatus::kNotSetUp;
  fml::AutoResetWaitableEvent raster_done;
  raster_runner->PostTask([shell_ptr = holder->GetShellForTesting().get(),
                           &status_after_create, &raster_done]() {
    status_after_create =
        ProbeRasterizerSetupStatus(*shell_ptr->GetRasterizer());
    raster_done.Signal();
  });
  ASSERT_FALSE(raster_done.WaitWithTimeout(fml::TimeDelta::FromSeconds(10)));
  EXPECT_EQ(status_after_create, DrawStatus::kDone);
}

#if !SLIMPELLER
TEST(AndroidShellHolder, SupersededNotifyCreatedAndNotifyChangedAreSkipped) {
  Settings settings;
  settings.enable_software_rendering = false;
  settings.enable_impeller = false;
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kSkiaOpenGLES);
  ASSERT_NE(holder, nullptr);
  ASSERT_TRUE(holder->IsValid());

  auto raster_runner =
      holder->GetShellForTesting()->GetTaskRunners().GetRasterTaskRunner();
  fml::AutoResetWaitableEvent raster_entered;
  fml::AutoResetWaitableEvent unblock_raster;
  raster_runner->PostTask([&raster_entered, &unblock_raster]() {
    raster_entered.Signal();
    unblock_raster.Wait();
  });
  raster_entered.Wait();

  // `AndroidContextGLSkia` backs fake windows with a valid pbuffer surface, so
  // the first `NotifyCreated` would populate `GetGrContext()` if it were not
  // superseded before running on the raster thread.
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  holder->GetPlatformView()->NotifyCreated(window);
  holder->GetPlatformView()->NotifyChanged(DlISize(1080, 1920));

  bool setup_ran_for_superseded_generation = true;
  raster_runner->PostTask([shell_ptr = holder->GetShellForTesting().get(),
                           &setup_ran_for_superseded_generation]() {
    setup_ran_for_superseded_generation =
        shell_ptr->GetRasterizer()->GetGrContext() != nullptr;
  });

  holder->GetPlatformView()->NotifyCreated(window);
  unblock_raster.Signal();

  bool setup_ran_for_active_generation = false;
  fml::AutoResetWaitableEvent raster_done;
  raster_runner->PostTask([shell_ptr = holder->GetShellForTesting().get(),
                           &setup_ran_for_active_generation, &raster_done]() {
    setup_ran_for_active_generation =
        shell_ptr->GetRasterizer()->GetGrContext() != nullptr;
    raster_done.Signal();
  });
  ASSERT_FALSE(raster_done.WaitWithTimeout(fml::TimeDelta::FromSeconds(10)));
  EXPECT_FALSE(setup_ran_for_superseded_generation);
  EXPECT_TRUE(setup_ran_for_active_generation);

  holder->GetPlatformView()->NotifyDestroyed();
}

// With hybrid composition the raster task queue can be merged onto the platform
// thread while surface setup or an earlier resize is still queued. A resize
// requested on the platform thread at that point must queue behind them rather
// than run inline.
TEST(AndroidShellHolder, NotifyChangedStaysBehindQueuedSetupWhenThreadsMerge) {
  // Declared before `holder` so they outlive the raster thread on every exit
  // path.
  fml::AutoResetWaitableEvent raster_entered;
  fml::AutoResetWaitableEvent unblock_raster;
  fml::AutoResetWaitableEvent raster_done;
  bool setup_ran_before_resize = false;

  Settings settings;
  settings.enable_software_rendering = false;
  settings.enable_impeller = false;
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kSkiaOpenGLES);
  ASSERT_NE(holder, nullptr);
  ASSERT_TRUE(holder->IsValid());

  const TaskRunners& task_runners =
      holder->GetShellForTesting()->GetTaskRunners();
  auto raster_runner = task_runners.GetRasterTaskRunner();
  const fml::TaskQueueId platform_queue_id =
      task_runners.GetPlatformTaskRunner()->GetTaskQueueId();
  const fml::TaskQueueId raster_queue_id = raster_runner->GetTaskQueueId();
  auto* task_queues = fml::MessageLoopTaskQueues::GetInstance();

  raster_runner->PostTask([&raster_entered, &unblock_raster]() {
    raster_entered.Signal();
    unblock_raster.Wait();
  });
  raster_entered.Wait();

  // Surface setup is now queued behind the blocked raster task.
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  holder->GetPlatformView()->NotifyCreated(window);

  // While merged, the raster task runner reports that it runs tasks on this
  // thread, so a run-now-or-post resize would execute here, ahead of setup.
  // `AndroidSurfaceGLSkia::OnScreenSurfaceResize` requires the onscreen surface
  // that setup creates, so a resize that runs first crashes the test.
  const bool merged = task_queues->Merge(platform_queue_id, raster_queue_id);
  const bool raster_runs_on_platform =
      raster_runner->RunsTasksOnCurrentThread();
  holder->GetPlatformView()->NotifyChanged(DlISize(1080, 1920));
  const bool unmerged =
      task_queues->Unmerge(platform_queue_id, raster_queue_id);

  raster_runner->PostTask([shell_ptr = holder->GetShellForTesting().get(),
                           &setup_ran_before_resize, &raster_done]() {
    setup_ran_before_resize =
        shell_ptr->GetRasterizer()->GetGrContext() != nullptr;
    raster_done.Signal();
  });
  unblock_raster.Signal();

  EXPECT_TRUE(merged);
  EXPECT_TRUE(raster_runs_on_platform);
  EXPECT_TRUE(unmerged);
  EXPECT_FALSE(raster_done.WaitWithTimeout(fml::TimeDelta::FromSeconds(10)));
  EXPECT_TRUE(setup_ran_before_resize);

  holder->GetPlatformView()->NotifyDestroyed();
}

TEST(AndroidShellHolder,
     NotifyCreatedRunsSetupWhenSetNativeWindowFailsButSurfaceIsValid) {
  Settings settings;
  settings.enable_software_rendering = true;
  settings.enable_impeller = false;
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, AndroidRenderingAPI::kSoftware);
  ASSERT_NE(holder, nullptr);
  ASSERT_TRUE(holder->IsValid());
  holder->GetPlatformView()->SetViewportMetrics(
      0, ViewportMetrics{1.0, 100, 100, 22, 0});

  auto raster_runner =
      holder->GetShellForTesting()->GetTaskRunners().GetRasterTaskRunner();
  DrawStatus status_before_create = DrawStatus::kDone;
  fml::AutoResetWaitableEvent initial_probe_done;
  raster_runner->PostTask([shell_ptr = holder->GetShellForTesting().get(),
                           &status_before_create, &initial_probe_done]() {
    status_before_create =
        ProbeRasterizerSetupStatus(*shell_ptr->GetRasterizer());
    initial_probe_done.Signal();
  });
  ASSERT_FALSE(
      initial_probe_done.WaitWithTimeout(fml::TimeDelta::FromSeconds(10)));
  EXPECT_EQ(status_before_create, DrawStatus::kNotSetUp);

  // `AndroidSurfaceSoftware::SetNativeWindow` returns false for a fake window,
  // yet `CreateRenderingSurface` returns a valid `GPUSurfaceSoftware` so
  // `Rasterizer::Setup` must still run (preserving attempt-and-validate
  // semantics).
  auto invalid_window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  holder->GetPlatformView()->NotifyCreated(invalid_window);
  holder->GetPlatformView()->NotifyChanged(DlISize(1080, 1920));

  DrawStatus status_after_create = DrawStatus::kNotSetUp;
  fml::AutoResetWaitableEvent raster_done;
  raster_runner->PostTask([shell_ptr = holder->GetShellForTesting().get(),
                           &status_after_create, &raster_done]() {
    status_after_create =
        ProbeRasterizerSetupStatus(*shell_ptr->GetRasterizer());
    raster_done.Signal();
  });
  ASSERT_FALSE(raster_done.WaitWithTimeout(fml::TimeDelta::FromSeconds(10)));
  EXPECT_EQ(status_after_create, DrawStatus::kDone);
}
#endif  // !SLIMPELLER

}  // namespace testing
}  // namespace flutter
