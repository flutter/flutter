// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

#include "flutter/flow/frame_timings.h"
#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/runtime/runtime_controller.h"
#include "flutter/shell/common/engine.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/vsync_waiter.h"
#include "flutter/shell/platform/android/android_shell_holder.h"
#include "flutter/shell/platform/android/platform_view_android_delegate/platform_view_android_delegate.h"
#include "flutter/shell/platform/android/testing/looper_test_utils.h"
#include "flutter/shell/platform/embedder/embedder_engine.h"
#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
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
              (const std::string& channel,
               UniquePlatformMessagePayload payload,
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
  MOCK_METHOD((std::array<float, 16>),
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

// How long a test waits for a vsync. At 60 Hz this is 120 frames, so a busy
// emulator does not flake.
constexpr fml::TimeDelta kVsyncTimeout = fml::TimeDelta::FromSeconds(2);

// How long the test thread keeps dispatching after the event it waited for,
// to catch duplicate deliveries. At 60 Hz this is 6 frames.
constexpr fml::TimeDelta kSettleTime = fml::TimeDelta::FromMilliseconds(100);

// Frame interval the vsync waiter reports before Java sets a refresh rate.
// vsync_waiter_android.cc starts at 60 Hz and converts 1e9 ns / 60 to whole
// nanoseconds by truncation.
constexpr fml::TimeDelta kDefaultFrameInterval =
    fml::TimeDelta::FromNanoseconds(16'666'666);

// Creates a holder without calling NotifyCreated: a fake window makes the
// Impeller GLES reactor abort on devices.
std::unique_ptr<AndroidShellHolder> CreateHolderWithoutSurface(
    Settings::MergedPlatformUIThread merged_platform_ui_thread,
    std::shared_ptr<MockPlatformViewAndroidJNI> jni =
        std::make_shared<MockPlatformViewAndroidJNI>()) {
  Settings settings;
  settings.enable_software_rendering = false;
  settings.merged_platform_ui_thread = merged_platform_ui_thread;
  return std::make_unique<AndroidShellHolder>(
      settings, std::move(jni), kFlutterNativeWindowBackendImpellerOpenGLES);
}

// Records the frames a vsync waiter delivers. Frame callbacks run on the UI
// thread, which is not the test thread when threads are not merged. Callbacks
// share ownership of the recorder, so a late frame never reaches a destroyed
// one.
class VsyncFrameRecorder
    : public std::enable_shared_from_this<VsyncFrameRecorder> {
 public:
  struct Frame {
    fml::TimePoint start;
    fml::TimePoint target;
    fml::TimePoint delivered;
    bool on_ui_thread = false;
  };

  explicit VsyncFrameRecorder(fml::RefPtr<fml::TaskRunner> ui_task_runner)
      : ui_task_runner_(std::move(ui_task_runner)) {}

  VsyncWaiter::Callback Callback() {
    return [self = shared_from_this()](
               std::unique_ptr<FrameTimingsRecorder> recorder) {
      Frame frame{
          .start = recorder->GetVsyncStartTime(),
          .target = recorder->GetVsyncTargetTime(),
          .delivered = fml::TimePoint::Now(),
          .on_ui_thread = self->ui_task_runner_->RunsTasksOnCurrentThread(),
      };
      std::scoped_lock lock(self->mutex_);
      self->frames_.push_back(frame);
    };
  }

  std::vector<Frame> frames() const {
    std::scoped_lock lock(mutex_);
    return frames_;
  }

 private:
  const fml::RefPtr<fml::TaskRunner> ui_task_runner_;
  mutable std::mutex mutex_;
  std::vector<Frame> frames_;
};

Shell* GetShellForTesting(const AndroidShellHolder& holder) {
  auto* engine =
      reinterpret_cast<EmbedderEngine*>(holder.GetEngineForTesting());
  return engine ? &engine->GetShell() : nullptr;
}

// Requests one frame from the vsync waiter the platform view creates for the
// shell, from the UI thread like the animator does, and checks how it is
// delivered.
void ExpectOneFrameOnUIThread(
    Settings::MergedPlatformUIThread merged_platform_ui_thread) {
  std::unique_ptr<AndroidShellHolder> holder =
      CreateHolderWithoutSurface(merged_platform_ui_thread);
  ASSERT_TRUE(holder->IsValid());
  fml::RefPtr<fml::TaskRunner> ui_task_runner =
      GetShellForTesting(*holder)->GetTaskRunners().GetUITaskRunner();
  // Through the PlatformView base class, the way the shell calls it.
  PlatformView& platform_view = *holder->GetPlatformView();
  std::shared_ptr<VsyncWaiter> vsync_waiter = platform_view.CreateVSyncWaiter();
  auto recorder = std::make_shared<VsyncFrameRecorder>(ui_task_runner);

  fml::TaskRunner::RunNowOrPostTask(ui_task_runner, [vsync_waiter, recorder] {
    vsync_waiter->AsyncWaitForVsync(recorder->Callback());
  });
  ASSERT_TRUE(PumpLooperUntil([&] { return !recorder->frames().empty(); },
                              kVsyncTimeout));
  PumpLooperFor(kSettleTime);

  std::vector<VsyncFrameRecorder::Frame> frames = recorder->frames();
  ASSERT_EQ(frames.size(), 1u);
  EXPECT_TRUE(frames[0].on_ui_thread);
  EXPECT_LE(frames[0].start, frames[0].delivered);
  EXPECT_EQ(frames[0].target - frames[0].start, kDefaultFrameInterval);
}
}  // namespace

TEST(AndroidShellHolder, Create) {
  Settings settings;
  settings.enable_software_rendering = false;
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, kFlutterNativeWindowBackendImpellerOpenGLES);
  EXPECT_NE(holder.get(), nullptr);
  EXPECT_TRUE(holder->IsValid());
  EXPECT_NE(holder->GetPlatformView().get(), nullptr);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  holder->NotifySurfaceCreated(window);
}

namespace {

std::string PayloadString(const UniquePlatformMessagePayload& payload) {
  return std::string(reinterpret_cast<const char*>(payload->data),
                     payload->data_size);
}

std::unique_ptr<PlatformMessage> MessageWithData(
    const std::string& channel,
    const std::string& data,
    fml::RefPtr<PlatformMessageResponse> response) {
  return std::make_unique<PlatformMessage>(
      channel, fml::MallocMapping::Copy(data.data(), data.size()),
      std::move(response));
}

// What the JNI facade received for one platform message from Dart.
struct ForwardedMessage {
  std::string channel;
  UniquePlatformMessagePayload payload;
  int response_id = 0;
  std::thread::id thread;
};

// Records every platform message the holder forwards to Java.
void RecordForwardedMessages(MockPlatformViewAndroidJNI& jni,
                             std::vector<ForwardedMessage>& forwarded) {
  EXPECT_CALL(jni, FlutterViewHandlePlatformMessage(::testing::_, ::testing::_,
                                                    ::testing::_))
      .WillRepeatedly([&forwarded](const std::string& channel,
                                   UniquePlatformMessagePayload payload,
                                   int response_id) {
        forwarded.push_back({channel, std::move(payload), response_id,
                             std::this_thread::get_id()});
      });
}

// The handler the Shell sends platform messages from Dart to.
std::shared_ptr<PlatformMessageHandler> MessageHandlerOf(
    AndroidShellHolder& holder) {
  return holder.GetPlatformView()->GetPlatformMessageHandler();
}

}  // namespace

TEST(AndroidShellHolder,
     PlatformMessageFromDartReachesJavaAndReplyReachesDart) {
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  std::vector<ForwardedMessage> forwarded;
  RecordForwardedMessages(*jni, forwarded);
  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithoutSurface(
      Settings::MergedPlatformUIThread::kEnabled, jni);
  ASSERT_TRUE(holder->IsValid());
  std::shared_ptr<PlatformMessageHandler> handler = MessageHandlerOf(*holder);
  ASSERT_TRUE(handler);
  // Java hands messages to their handlers' threads itself.
  EXPECT_FALSE(handler->DoesHandlePlatformMessageOnPlatformThread());
  fml::RefPtr<MockPlatformMessageResponse> response =
      MockPlatformMessageResponse::Create();

  handler->HandlePlatformMessage(MessageWithData("foo", "abc", response));

  ASSERT_EQ(forwarded.size(), 1u);
  EXPECT_EQ(forwarded[0].channel, "foo");
  ASSERT_TRUE(forwarded[0].payload);
  EXPECT_EQ(PayloadString(forwarded[0].payload), "abc");
  EXPECT_GT(forwarded[0].response_id, 0);

  std::string reply;
  EXPECT_CALL(*response, Complete(::testing::_))
      .WillOnce([&reply](std::unique_ptr<fml::Mapping> data) {
        reply.assign(reinterpret_cast<const char*>(data->GetMapping()),
                     data->GetSize());
      });
  const std::string java_reply = "xyz";
  holder->InvokePlatformMessageResponseCallback(
      forwarded[0].response_id,
      reinterpret_cast<const uint8_t*>(java_reply.data()), java_reply.size());

  EXPECT_EQ(reply, "xyz");
  // Java may still read the payload after it replied.
  EXPECT_EQ(PayloadString(forwarded[0].payload), "abc");
}

TEST(AndroidShellHolder, NullAndZeroLengthRepliesStayDistinct) {
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  std::vector<ForwardedMessage> forwarded;
  RecordForwardedMessages(*jni, forwarded);
  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithoutSurface(
      Settings::MergedPlatformUIThread::kEnabled, jni);
  std::shared_ptr<PlatformMessageHandler> handler = MessageHandlerOf(*holder);
  fml::RefPtr<MockPlatformMessageResponse> null_reply =
      MockPlatformMessageResponse::Create();
  fml::RefPtr<MockPlatformMessageResponse> empty_reply =
      MockPlatformMessageResponse::Create();
  handler->HandlePlatformMessage(MessageWithData("null", "a", null_reply));
  handler->HandlePlatformMessage(MessageWithData("empty", "b", empty_reply));
  ASSERT_EQ(forwarded.size(), 2u);

  EXPECT_CALL(*null_reply, CompleteEmpty());
  holder->InvokePlatformMessageEmptyResponseCallback(forwarded[0].response_id);

  size_t empty_reply_size = 1;
  EXPECT_CALL(*empty_reply, Complete(::testing::_))
      .WillOnce([&empty_reply_size](std::unique_ptr<fml::Mapping> data) {
        empty_reply_size = data->GetSize();
      });
  // Java passes a direct buffer even for a zero-length reply.
  const uint8_t java_buffer[1] = {};
  holder->InvokePlatformMessageResponseCallback(forwarded[1].response_id,
                                                java_buffer, 0);
  EXPECT_EQ(empty_reply_size, 0u);
}

TEST(AndroidShellHolder, PlatformMessageWithoutDataReachesJavaWithoutPayload) {
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  std::vector<ForwardedMessage> forwarded;
  RecordForwardedMessages(*jni, forwarded);
  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithoutSurface(
      Settings::MergedPlatformUIThread::kEnabled, jni);

  MessageHandlerOf(*holder)->HandlePlatformMessage(
      std::make_unique<PlatformMessage>("no-data", nullptr));

  ASSERT_EQ(forwarded.size(), 1u);
  EXPECT_EQ(forwarded[0].channel, "no-data");
  EXPECT_FALSE(forwarded[0].payload);
}

TEST(AndroidShellHolder, PlatformMessageFromBackgroundThreadReachesJavaThere) {
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  std::vector<ForwardedMessage> forwarded;
  RecordForwardedMessages(*jni, forwarded);
  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithoutSurface(
      Settings::MergedPlatformUIThread::kEnabled, jni);
  std::shared_ptr<PlatformMessageHandler> handler = MessageHandlerOf(*holder);
  std::thread::id background_thread;

  // A background isolate sends on its own thread.
  std::thread background([&handler, &background_thread] {
    background_thread = std::this_thread::get_id();
    handler->HandlePlatformMessage(MessageWithData(
        "background", "abc", MockPlatformMessageResponse::Create()));
  });
  background.join();

  ASSERT_EQ(forwarded.size(), 1u);
  EXPECT_EQ(forwarded[0].thread, background_thread);
  EXPECT_NE(forwarded[0].thread, std::this_thread::get_id());
}

TEST(AndroidShellHolder, UnansweredPlatformMessagesAreDroppedWithTheHolder) {
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  std::vector<ForwardedMessage> forwarded;
  RecordForwardedMessages(*jni, forwarded);
  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithoutSurface(
      Settings::MergedPlatformUIThread::kEnabled, jni);
  fml::RefPtr<MockPlatformMessageResponse> response =
      MockPlatformMessageResponse::Create();
  EXPECT_CALL(*response, Complete(::testing::_)).Times(0);
  EXPECT_CALL(*response, CompleteEmpty()).Times(0);
  MessageHandlerOf(*holder)->HandlePlatformMessage(
      MessageWithData("foo", "abc", response));
  ASSERT_EQ(forwarded.size(), 1u);

  holder.reset();

  // Java still owns the payload, and may release it after the engine is gone.
  EXPECT_EQ(PayloadString(forwarded[0].payload), "abc");
  forwarded.clear();
}

TEST(AndroidShellHolder, CreateWithMergedPlatformAndUIThread) {
  Settings settings;
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, kFlutterNativeWindowBackendImpellerOpenGLES);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  holder->NotifySurfaceCreated(window);

  EXPECT_EQ(
      GetShellForTesting(*holder)->GetTaskRunners().GetUITaskRunner(),
      GetShellForTesting(*holder)->GetTaskRunners().GetPlatformTaskRunner());
}

TEST(AndroidShellHolder, CreateWithUnMergedPlatformAndUIThread) {
  Settings settings;
  settings.merged_platform_ui_thread =
      Settings::MergedPlatformUIThread::kDisabled;
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, kFlutterNativeWindowBackendImpellerOpenGLES);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  holder->NotifySurfaceCreated(window);

  EXPECT_NE(
      GetShellForTesting(*holder)->GetTaskRunners().GetUITaskRunner(),
      GetShellForTesting(*holder)->GetTaskRunners().GetPlatformTaskRunner());
}

TEST(AndroidShellHolder, StartsWithDetachedLifecycleState) {
  Settings settings;
  settings.enable_software_rendering = false;
  // With merged threads the UI thread is the test thread, so the runtime
  // controller can be read directly.
  ASSERT_EQ(settings.merged_platform_ui_thread,
            Settings::MergedPlatformUIThread::kEnabled);
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  auto holder = std::make_unique<AndroidShellHolder>(
      settings, jni, kFlutterNativeWindowBackendImpellerOpenGLES);
  ASSERT_TRUE(holder->IsValid());

  // Frames stay off until Java reports a lifecycle state over
  // flutter/lifecycle.
  EXPECT_EQ(GetShellForTesting(*holder)
                ->GetEngine()
                ->GetRuntimeController()
                ->GetPlatformData()
                .lifecycle_state,
            "AppLifecycleState.detached");
}

TEST(AndroidShellHolder, VsyncFrameOnUIThreadWithMergedThreads) {
  ExpectOneFrameOnUIThread(Settings::MergedPlatformUIThread::kEnabled);
}

TEST(AndroidShellHolder, VsyncFrameOnUIThreadWithUnmergedThreads) {
  ExpectOneFrameOnUIThread(Settings::MergedPlatformUIThread::kDisabled);
}

TEST(AndroidShellHolder, PendingVsyncIsDeliveredOnceAfterHolderIsDestroyed) {
  // With merged threads the UI task runner is the message loop of the test
  // thread, so it outlives the holder.
  std::unique_ptr<AndroidShellHolder> holder =
      CreateHolderWithoutSurface(Settings::MergedPlatformUIThread::kEnabled);
  ASSERT_TRUE(holder->IsValid());
  fml::RefPtr<fml::TaskRunner> ui_task_runner =
      GetShellForTesting(*holder)->GetTaskRunners().GetUITaskRunner();
  ASSERT_TRUE(ui_task_runner->RunsTasksOnCurrentThread());
  PlatformView& platform_view = *holder->GetPlatformView();
  // The test keeps the waiter alive. In an app the shell owns it and it dies
  // with the holder.
  std::shared_ptr<VsyncWaiter> vsync_waiter = platform_view.CreateVSyncWaiter();
  auto recorder = std::make_shared<VsyncFrameRecorder>(ui_task_runner);

  vsync_waiter->AsyncWaitForVsync(recorder->Callback());
  holder.reset();

  ASSERT_TRUE(PumpLooperUntil([&] { return !recorder->frames().empty(); },
                              kVsyncTimeout));
  PumpLooperFor(kSettleTime);

  std::vector<VsyncFrameRecorder::Frame> frames = recorder->frames();
  ASSERT_EQ(frames.size(), 1u);
  EXPECT_TRUE(frames[0].on_ui_thread);
  EXPECT_LE(frames[0].start, frames[0].delivered);
  EXPECT_EQ(frames[0].target - frames[0].start, kDefaultFrameInterval);
}

TEST(AndroidShellHolder, VsyncBatonsReturnThroughFlutterEngineOnVsync) {
  struct OnVsyncCall {
    intptr_t baton;
    uint64_t frame_start_time_nanos;
    uint64_t frame_target_time_nanos;
    bool on_ui_thread;
  };
  // Declared before the holder, which can still return batons while it is
  // destroyed.
  std::vector<OnVsyncCall> calls;
  std::unique_ptr<AndroidShellHolder> holder =
      CreateHolderWithoutSurface(Settings::MergedPlatformUIThread::kEnabled);
  ASSERT_TRUE(holder->IsValid());
  fml::RefPtr<fml::TaskRunner> ui_task_runner =
      GetShellForTesting(*holder)->GetTaskRunners().GetUITaskRunner();
  // With merged threads every call below happens on the test thread.
  ASSERT_TRUE(ui_task_runner->RunsTasksOnCurrentThread());

  FlutterEngineProcTable& embedder_api = holder->GetEmbedderApiForTesting();
  // Forwarding to the real function keeps the frame coming.
  FlutterEngineOnVsyncFnPtr real_on_vsync = embedder_api.OnVsync;
  embedder_api.OnVsync = MOCK_ENGINE_PROC(
      OnVsync,
      ([&calls, ui_task_runner, real_on_vsync](
           FLUTTER_API_SYMBOL(FlutterEngine) engine, intptr_t baton,
           uint64_t frame_start_time_nanos, uint64_t frame_target_time_nanos) {
        calls.push_back({
            .baton = baton,
            .frame_start_time_nanos = frame_start_time_nanos,
            .frame_target_time_nanos = frame_target_time_nanos,
            .on_ui_thread = ui_task_runner->RunsTasksOnCurrentThread(),
        });
        return real_on_vsync(engine, baton, frame_start_time_nanos,
                             frame_target_time_nanos);
      }));

  PlatformView& platform_view = *holder->GetPlatformView();
  std::shared_ptr<VsyncWaiter> vsync_waiter = platform_view.CreateVSyncWaiter();
  auto recorder = std::make_shared<VsyncFrameRecorder>(ui_task_runner);
  vsync_waiter->AsyncWaitForVsync(recorder->Callback());
  ASSERT_TRUE(PumpLooperUntil([&] { return !recorder->frames().empty(); },
                              kVsyncTimeout));
  PumpLooperFor(kSettleTime);

  ASSERT_EQ(calls.size(), 1u);
  EXPECT_NE(calls[0].baton, 0);
  EXPECT_TRUE(calls[0].on_ui_thread);
  EXPECT_EQ(calls[0].frame_target_time_nanos - calls[0].frame_start_time_nanos,
            static_cast<uint64_t>(kDefaultFrameInterval.ToNanoseconds()));
  std::vector<VsyncFrameRecorder::Frame> frames = recorder->frames();
  ASSERT_EQ(frames.size(), 1u);
  EXPECT_EQ(frames[0].start.ToEpochDelta().ToNanoseconds(),
            static_cast<int64_t>(calls[0].frame_start_time_nanos));
}

TEST(AndroidShellHolder, UpdateSemanticsForwardsToJni) {
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithoutSurface(
      Settings::MergedPlatformUIThread::kEnabled, jni);
  ASSERT_TRUE(holder->IsValid());
  // Semantic node ID, custom action IDs, and the implicit view ID (0) used to
  // verify binary encoding.
  constexpr int64_t kImplicitViewId = 0;
  constexpr int32_t kTestNodeId = 42;
  constexpr int32_t kTestActionId = 7;
  constexpr int32_t kTestActionOverrideId = 8;

  SemanticsNode node;
  node.id = kTestNodeId;
  node.label = "Submit";
  SemanticsNodeUpdates updates;
  updates.emplace(kTestNodeId, node);

  CustomAccessibilityAction action;
  action.id = kTestActionId;
  action.overrideId = kTestActionOverrideId;
  action.label = "Activate";
  action.hint = "Double tap";
  CustomAccessibilityActionUpdates actions;
  actions.emplace(kTestActionId, action);

  EXPECT_CALL(
      *jni, FlutterViewUpdateCustomAccessibilityActions(
                ::testing::SizeIs(PlatformViewAndroidDelegate::kBytesPerAction),
                ::testing::ElementsAre("Activate", "Double tap")));
  EXPECT_CALL(*jni,
              FlutterViewUpdateSemantics(
                  ::testing::SizeIs(PlatformViewAndroidDelegate::kBytesPerNode),
                  ::testing::ElementsAre("Submit"), ::testing::IsEmpty()));

  PlatformView& platform_view = *holder->GetPlatformView();
  platform_view.UpdateSemantics(kImplicitViewId, std::move(updates),
                                std::move(actions));
}

TEST(AndroidShellHolder, ComputePlatformResolvedLocalesForwardsToJni) {
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithoutSurface(
      Settings::MergedPlatformUIThread::kEnabled, jni);
  ASSERT_TRUE(holder->IsValid());
  const std::vector<std::string> supported = {"en", "US", "", "fr", "FR", ""};
  EXPECT_CALL(*jni, FlutterViewComputePlatformResolvedLocale(supported))
      .WillOnce([](std::vector<std::string>) {
        return std::make_unique<std::vector<std::string>>(
            std::initializer_list<std::string>{"fr", "FR", ""});
      });

  PlatformView& platform_view = *holder->GetPlatformView();
  std::unique_ptr<std::vector<std::string>> resolved =
      platform_view.ComputePlatformResolvedLocales(supported);
  ASSERT_NE(resolved, nullptr);
  EXPECT_THAT(*resolved, ::testing::ElementsAre("fr", "FR", ""));
}

// java.util.Locale may report legacy language codes ("iw" for Hebrew), so the
// locale Java picks can differ from every supported locale. The engine gets
// Java's codes unchanged, as before the callbacks went through embedder.h.
TEST(AndroidShellHolder, ComputePlatformResolvedLocalesKeepsJavaCodes) {
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithoutSurface(
      Settings::MergedPlatformUIThread::kEnabled, jni);
  ASSERT_TRUE(holder->IsValid());
  const std::vector<std::string> supported = {"en", "US", "", "he", "IL", ""};
  EXPECT_CALL(*jni, FlutterViewComputePlatformResolvedLocale(supported))
      .WillOnce([](std::vector<std::string>) {
        return std::make_unique<std::vector<std::string>>(
            std::initializer_list<std::string>{"iw", "IL", ""});
      });

  PlatformView& platform_view = *holder->GetPlatformView();
  std::unique_ptr<std::vector<std::string>> resolved =
      platform_view.ComputePlatformResolvedLocales(supported);
  ASSERT_NE(resolved, nullptr);
  EXPECT_THAT(*resolved, ::testing::ElementsAre("iw", "IL", ""));
}

TEST(AndroidShellHolder, ComputePlatformResolvedLocalesWithoutAnswerIsEmpty) {
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithoutSurface(
      Settings::MergedPlatformUIThread::kEnabled, jni);
  ASSERT_TRUE(holder->IsValid());
  const std::vector<std::string> supported = {"en", "US", ""};
  EXPECT_CALL(*jni, FlutterViewComputePlatformResolvedLocale(supported))
      .WillOnce([](std::vector<std::string>) {
        return std::make_unique<std::vector<std::string>>();
      });

  PlatformView& platform_view = *holder->GetPlatformView();
  std::unique_ptr<std::vector<std::string>> resolved =
      platform_view.ComputePlatformResolvedLocales(supported);
  ASSERT_NE(resolved, nullptr);
  EXPECT_TRUE(resolved->empty());
}

TEST(AndroidShellHolder, OnPreEngineRestartForwardsToJni) {
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithoutSurface(
      Settings::MergedPlatformUIThread::kEnabled, jni);
  ASSERT_TRUE(holder->IsValid());
  EXPECT_CALL(*jni, FlutterViewOnPreEngineRestart());

  PlatformView& platform_view = *holder->GetPlatformView();
  platform_view.OnPreEngineRestart();
}

TEST(AndroidShellHolder,
     DispatchSemanticsActionCallsFlutterEngineSendSemanticsAction) {
  struct RecordedSemanticsAction {
    FlutterViewId view_id;
    uint64_t node_id;
    FlutterSemanticsAction action;
    std::vector<uint8_t> data;
  };
  std::vector<RecordedSemanticsAction> calls;
  std::unique_ptr<AndroidShellHolder> holder =
      CreateHolderWithoutSurface(Settings::MergedPlatformUIThread::kEnabled);
  ASSERT_TRUE(holder->IsValid());

  FlutterEngineProcTable& embedder_api = holder->GetEmbedderApiForTesting();
  FlutterEngineSendSemanticsActionFnPtr real_send_semantics_action =
      embedder_api.SendSemanticsAction;
  embedder_api.SendSemanticsAction = MOCK_ENGINE_PROC(
      SendSemanticsAction, ([&calls, real_send_semantics_action](
                                FLUTTER_API_SYMBOL(FlutterEngine) engine,
                                const FlutterSendSemanticsActionInfo* info) {
        std::vector<uint8_t> payload;
        if (info->data != nullptr && info->data_length > 0) {
          payload.assign(info->data, info->data + info->data_length);
        }
        calls.push_back({
            .view_id = info->view_id,
            .node_id = info->node_id,
            .action = info->action,
            .data = std::move(payload),
        });
        return real_send_semantics_action(engine, info);
      }));

  // Implicit view ID (0), sample node IDs, and payload bytes.
  constexpr FlutterViewId kExpectedImplicitViewId = 0;
  constexpr int32_t kTapNodeId = 11;
  constexpr int32_t kScrollNodeId = 23;
  const std::vector<uint8_t> kPayload = {0x01, 0x02, 0x03, 0x04};

  holder->DispatchSemanticsAction(
      kTapNodeId, static_cast<int32_t>(kFlutterSemanticsActionTap),
      fml::MallocMapping());
  holder->DispatchSemanticsAction(
      kScrollNodeId, static_cast<int32_t>(kFlutterSemanticsActionScrollLeft),
      fml::MallocMapping::Copy(kPayload.data(), kPayload.size()));

  ASSERT_EQ(calls.size(), 2u);
  EXPECT_EQ(calls[0].view_id, kExpectedImplicitViewId);
  EXPECT_EQ(calls[0].node_id, static_cast<uint64_t>(kTapNodeId));
  EXPECT_EQ(calls[0].action, kFlutterSemanticsActionTap);
  EXPECT_TRUE(calls[0].data.empty());

  EXPECT_EQ(calls[1].view_id, kExpectedImplicitViewId);
  EXPECT_EQ(calls[1].node_id, static_cast<uint64_t>(kScrollNodeId));
  EXPECT_EQ(calls[1].action, kFlutterSemanticsActionScrollLeft);
  EXPECT_EQ(calls[1].data, kPayload);
}

TEST(AndroidShellHolder, SetApplicationLocaleForwardsToJni) {
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithoutSurface(
      Settings::MergedPlatformUIThread::kEnabled, jni);
  ASSERT_TRUE(holder->IsValid());
  EXPECT_CALL(*jni, FlutterViewSetApplicationLocale("es-MX"));

  PlatformView& platform_view = *holder->GetPlatformView();
  platform_view.SetApplicationLocale("es-MX");
}

TEST(AndroidShellHolder, SetSemanticsTreeEnabledForwardsToJni) {
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithoutSurface(
      Settings::MergedPlatformUIThread::kEnabled, jni);
  ASSERT_TRUE(holder->IsValid());
  EXPECT_CALL(*jni, FlutterViewSetSemanticsTreeEnabled(true));
  EXPECT_CALL(*jni, FlutterViewSetSemanticsTreeEnabled(false));

  PlatformView& platform_view = *holder->GetPlatformView();
  platform_view.SetSemanticsTreeEnabled(true);
  platform_view.SetSemanticsTreeEnabled(false);
}

TEST(AndroidShellHolder, RequestDartDeferredLibraryForwardsToJni) {
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithoutSurface(
      Settings::MergedPlatformUIThread::kEnabled, jni);
  ASSERT_TRUE(holder->IsValid());
  // Arbitrary deferred library loading unit ID to verify argument forwarding.
  constexpr int kTestLoadingUnitId = 5;
  EXPECT_CALL(*jni, RequestDartDeferredLibrary(kTestLoadingUnitId))
      .WillOnce(::testing::Return(true));

  PlatformView& platform_view = *holder->GetPlatformView();
  platform_view.RequestDartDeferredLibrary(kTestLoadingUnitId);
}

TEST(AndroidShellHolder, GetScaledFontSizeForwardsToJni) {
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithoutSurface(
      Settings::MergedPlatformUIThread::kEnabled, jni);
  ASSERT_TRUE(holder->IsValid());
  // Sample unscaled font size (14 sp), configuration ID (3), and non-linearly
  // scaled font size (17.5 px) returned by the platform.
  constexpr double kUnscaledFontSize = 14.0;
  constexpr int kConfigurationId = 3;
  constexpr double kExpectedScaledFontSize = 17.5;
  EXPECT_CALL(*jni,
              FlutterViewGetScaledFontSize(kUnscaledFontSize, kConfigurationId))
      .WillOnce(::testing::Return(kExpectedScaledFontSize));

  const PlatformView& platform_view = *holder->GetPlatformView();
  EXPECT_DOUBLE_EQ(
      platform_view.GetScaledFontSize(kUnscaledFontSize, kConfigurationId),
      kExpectedScaledFontSize);
}

TEST(AndroidShellHolder,
     PlatformViewAndroidRoutesRenderingAndContextCallbacksThroughEmbedder) {
  std::unique_ptr<AndroidShellHolder> holder =
      CreateHolderWithoutSurface(Settings::MergedPlatformUIThread::kEnabled);
  ASSERT_TRUE(holder->IsValid());

  PlatformView& platform_view = *holder->GetPlatformView();
  const PlatformView& const_platform_view = *holder->GetPlatformView();

  EXPECT_NE(const_platform_view.GetImpellerContext(), nullptr);
  EXPECT_NE(platform_view.CreateExternalViewEmbedder(), nullptr);
  EXPECT_NE(platform_view.CreateSnapshotSurfaceProducer(), nullptr);
  const_platform_view.ReleaseResourceContext();
}

TEST(AndroidShellHolder, SpawnReturnsNullWhenKernelBlobUnreadable) {
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  std::unique_ptr<AndroidShellHolder> holder = CreateHolderWithoutSurface(
      Settings::MergedPlatformUIThread::kEnabled, jni);
  ASSERT_TRUE(holder->IsValid());

  if (!holder->GetEmbedderApiForTesting().RunsAOTCompiledDartCode()) {
    // Sample engine ID (1) passed to Spawn when kernel_blob_path is unset.
    constexpr int64_t kSpawnedEngineId = 1;
    std::unique_ptr<AndroidShellHolder> spawned = holder->Spawn(
        jni, /*entrypoint=*/"main", /*libraryUrl=*/"",
        /*initial_route=*/"/", /*entrypoint_args=*/{}, kSpawnedEngineId);
    EXPECT_EQ(spawned, nullptr);
  }
}

TEST(AndroidShellHolder,
     SurfaceLifecycleAndRendererInfoRouteThroughNativeWindowEmbedderProcs) {
  std::unique_ptr<AndroidShellHolder> holder =
      CreateHolderWithoutSurface(Settings::MergedPlatformUIThread::kEnabled);
  ASSERT_TRUE(holder->IsValid());

  std::vector<FlutterNativeWindowInfo> set_window_calls;
  std::vector<FlutterNativeWindowResizeInfo> resize_calls;
  int next_frame_calls = 0;
  int notify_created_calls = 0;
  int schedule_frame_calls = 0;
  int notify_destroyed_calls = 0;
  int renderer_info_calls = 0;

  FlutterEngineProcTable& embedder_api = holder->GetEmbedderApiForTesting();
  embedder_api.SetNativeWindow = MOCK_ENGINE_PROC(
      SetNativeWindow, ([&](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                            const FlutterNativeWindowInfo* info) {
        EXPECT_NE(engine, nullptr);
        EXPECT_NE(info, nullptr);
        if (info != nullptr) {
          EXPECT_EQ(info->struct_size, sizeof(FlutterNativeWindowInfo));
          set_window_calls.push_back(*info);
        }
        return kSuccess;
      }));
  embedder_api.SetNextFrameCallback = MOCK_ENGINE_PROC(
      SetNextFrameCallback, ([&](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                                 VoidCallback callback, void* user_data) {
        EXPECT_NE(engine, nullptr);
        EXPECT_NE(callback, nullptr);
        next_frame_calls++;
        return kSuccess;
      }));
  embedder_api.NotifyCreated = MOCK_ENGINE_PROC(
      NotifyCreated, ([&](FLUTTER_API_SYMBOL(FlutterEngine) engine) {
        EXPECT_NE(engine, nullptr);
        notify_created_calls++;
        return kSuccess;
      }));
  embedder_api.ScheduleFrame = MOCK_ENGINE_PROC(
      ScheduleFrame, ([&](FLUTTER_API_SYMBOL(FlutterEngine) engine) {
        EXPECT_NE(engine, nullptr);
        schedule_frame_calls++;
        return kSuccess;
      }));
  embedder_api.ResizeNativeWindow = MOCK_ENGINE_PROC(
      ResizeNativeWindow, ([&](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                               const FlutterNativeWindowResizeInfo* info) {
        EXPECT_NE(engine, nullptr);
        EXPECT_NE(info, nullptr);
        if (info != nullptr) {
          EXPECT_EQ(info->struct_size, sizeof(FlutterNativeWindowResizeInfo));
          resize_calls.push_back(*info);
        }
        return kSuccess;
      }));
  embedder_api.NotifyDestroyed = MOCK_ENGINE_PROC(
      NotifyDestroyed, ([&](FLUTTER_API_SYMBOL(FlutterEngine) engine) {
        EXPECT_NE(engine, nullptr);
        notify_destroyed_calls++;
        return kSuccess;
      }));
  embedder_api.GetNativeWindowRendererInfo = MOCK_ENGINE_PROC(
      GetNativeWindowRendererInfo,
      ([&](FLUTTER_API_SYMBOL(FlutterEngine) engine,
           FlutterNativeWindowRendererInfo* info_out) {
        EXPECT_NE(engine, nullptr);
        EXPECT_NE(info_out, nullptr);
        if (info_out != nullptr) {
          EXPECT_EQ(info_out->struct_size,
                    sizeof(FlutterNativeWindowRendererInfo));
          info_out->backend = kFlutterNativeWindowBackendImpellerVulkan;
          info_out->surface_control_enabled = true;
        }
        renderer_info_calls++;
        return kSuccess;
      }));

  auto fake_window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  holder->NotifySurfaceCreated(fake_window);
  ASSERT_EQ(set_window_calls.size(), 1u);
  EXPECT_EQ(set_window_calls[0].window, nullptr);
  EXPECT_TRUE(set_window_calls[0].is_fake_window);
  EXPECT_EQ(next_frame_calls, 1);
  EXPECT_EQ(notify_created_calls, 1);

  holder->NotifySurfaceWindowChanged(fake_window);
  ASSERT_EQ(set_window_calls.size(), 2u);
  EXPECT_EQ(set_window_calls[1].window, nullptr);
  EXPECT_TRUE(set_window_calls[1].is_fake_window);
  EXPECT_EQ(schedule_frame_calls, 1);

  // Sample positive dimensions and negative sentinel to verify resize guard.
  constexpr int kResizeWidth = 1080;
  constexpr int kResizeHeight = 2400;
  constexpr int kNegativeDimension = -1;
  holder->NotifySurfaceChanged(kNegativeDimension, kResizeHeight);
  EXPECT_TRUE(resize_calls.empty());
  holder->NotifySurfaceChanged(kResizeWidth, kResizeHeight);
  ASSERT_EQ(resize_calls.size(), 1u);
  EXPECT_EQ(resize_calls[0].width, static_cast<size_t>(kResizeWidth));
  EXPECT_EQ(resize_calls[0].height, static_cast<size_t>(kResizeHeight));

  holder->NotifySurfaceDestroyed();
  EXPECT_EQ(notify_destroyed_calls, 1);
  ASSERT_EQ(set_window_calls.size(), 3u);
  EXPECT_EQ(set_window_calls[2].window, nullptr);
  EXPECT_FALSE(set_window_calls[2].is_fake_window);

  EXPECT_TRUE(holder->IsSurfaceControlEnabled());
  EXPECT_EQ(renderer_info_calls, 1);
}

}  // namespace testing
}  // namespace flutter
