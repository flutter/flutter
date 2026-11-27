// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/common/animator.h"

#include <functional>
#include <future>
#include <memory>

#include "flutter/shell/common/shell_test.h"
#include "flutter/shell/common/shell_test_platform_view.h"
#include "flutter/testing/post_task_sync.h"
#include "flutter/testing/testing.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

// CREATE_FFI_LAMBDA is leaky by design
// NOLINTBEGIN(clang-analyzer-core.StackAddressEscape)

namespace flutter {
namespace testing {

constexpr int64_t kImplicitViewId = 0;

class FakeAnimatorDelegate : public Animator::Delegate {
 public:
  MOCK_METHOD(void,
              OnAnimatorBeginFrame,
              (fml::TimePoint frame_target_time, uint64_t frame_number),
              (override));

  void OnAnimatorNotifyIdle(fml::TimeDelta deadline) override {
    notify_idle_called_ = true;
  }

  MOCK_METHOD(void,
              OnAnimatorUpdateLatestFrameTargetTime,
              (fml::TimePoint frame_target_time),
              (override));

  MOCK_METHOD(void,
              OnAnimatorFrameBuilt,
              (fml::TimePoint build_start, fml::TimePoint build_end),
              (override));

  MOCK_METHOD(void,
              OnAnimatorDraw,
              (std::shared_ptr<FramePipeline> pipeline),
              (override));

  void OnAnimatorDrawLastLayerTrees(
      std::unique_ptr<FrameTimingsRecorder> frame_timings_recorder) override {
    if (on_draw_last_layer_trees_) {
      on_draw_last_layer_trees_();
    }
  }

  bool notify_idle_called_ = false;
  std::function<void()> on_draw_last_layer_trees_;
};

class CountingVsyncWaiter : public VsyncWaiter {
 public:
  explicit CountingVsyncWaiter(const TaskRunners& task_runners)
      : VsyncWaiter(task_runners) {}

  int await_vsync_call_count() const { return await_vsync_call_count_; }

 protected:
  void AwaitVSync() override { await_vsync_call_count_++; }

 private:
  int await_vsync_call_count_ = 0;
};

TEST_F(ShellTest, VSyncTargetTime) {
  // Add native callbacks to listen for window.onBeginFrame
  int64_t target_time;
  fml::AutoResetWaitableEvent on_target_time_latch;
  auto nativeOnBeginFrame = [&on_target_time_latch,
                             &target_time](int64_t microseconds) {
    target_time = microseconds;
    on_target_time_latch.Signal();
  };
  AddFfiNativeCallback("NativeOnBeginFrame",
                       CREATE_FFI_LAMBDA(nativeOnBeginFrame));
  AddFfiNativeCallback("NotifyNative", CREATE_FFI_LAMBDA([&]() {}));

  // Create all te prerequisites for a shell.
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
  auto settings = CreateSettingsForFixture();

  std::unique_ptr<Shell> shell;

  TaskRunners task_runners = GetTaskRunnersForFixture();
  // this is not used as we are not using simulated events.
  const auto vsync_clock = std::make_shared<ShellTestVsyncClock>();
  CreateVsyncWaiter create_vsync_waiter = [&]() {
    return static_cast<std::unique_ptr<VsyncWaiter>>(
        std::make_unique<ConstantFiringVsyncWaiter>(task_runners));
  };

  // create a shell with a constant firing vsync waiter.
  auto platform_task = std::async(std::launch::async, [&]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();

    shell = Shell::Create(
        flutter::PlatformData(), task_runners, settings,
        [vsync_clock, &create_vsync_waiter](Shell& shell) {
          return ShellTestPlatformView::Create(
              ShellTestPlatformView::DefaultBackendType(), shell,
              shell.GetTaskRunners(), vsync_clock, create_vsync_waiter, nullptr,
              shell.GetIsGpuDisabledSyncSwitch());
        },
        [](Shell& shell) { return std::make_unique<Rasterizer>(shell); });
    ASSERT_TRUE(DartVMRef::IsInstanceRunning());

    auto configuration = RunConfiguration::InferFromSettings(settings);
    ASSERT_TRUE(configuration.IsValid());
    configuration.SetEntrypoint("onBeginFrameMain");

    RunEngine(shell.get(), std::move(configuration));
  });
  platform_task.wait();
  on_target_time_latch.Wait();
  const auto vsync_waiter_target_time =
      ConstantFiringVsyncWaiter::kFrameTargetTime;
  ASSERT_EQ(vsync_waiter_target_time.ToEpochDelta().ToMicroseconds(),
            target_time);

  // validate that the latest target time has also been updated.
  ASSERT_EQ(GetLatestFrameTargetTime(shell.get()), vsync_waiter_target_time);

  // teardown.
  DestroyShell(std::move(shell), task_runners);
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
}

TEST_F(ShellTest, RequestFrameAwaitsVsyncSynchronously) {
  FakeAnimatorDelegate delegate;

  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto task_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();
  TaskRunners task_runners("test", task_runner, task_runner, task_runner,
                           task_runner);

  auto vsync_waiter = std::make_unique<CountingVsyncWaiter>(task_runners);
  const auto* counting_vsync_waiter = vsync_waiter.get();
  Animator animator(delegate, task_runners, std::move(vsync_waiter));

  animator.RequestFrame(/*regenerate_layer_trees=*/false);

  EXPECT_EQ(counting_vsync_waiter->await_vsync_call_count(), 1);
}

TEST_F(ShellTest, AnimatorDoesNotNotifyIdleBeforeRender) {
  FakeAnimatorDelegate delegate;
  TaskRunners task_runners = {
      "test",
      CreateNewThread(),  // platform
      CreateNewThread(),  // raster
      CreateNewThread(),  // ui
      CreateNewThread()   // io
  };

  auto clock = std::make_shared<ShellTestVsyncClock>();
  fml::AutoResetWaitableEvent latch;
  std::shared_ptr<Animator> animator;

  auto flush_vsync_task = [&] {
    fml::AutoResetWaitableEvent ui_latch;
    task_runners.GetUITaskRunner()->PostTask([&] { ui_latch.Signal(); });
    do {
      clock->SimulateVSync();
    } while (ui_latch.WaitWithTimeout(fml::TimeDelta::FromMilliseconds(1)));
    latch.Signal();
  };

  // Create the animator on the UI task runner.
  task_runners.GetUITaskRunner()->PostTask([&] {
    auto vsync_waiter = static_cast<std::unique_ptr<VsyncWaiter>>(
        std::make_unique<ShellTestVsyncWaiter>(task_runners, clock));
    animator = std::make_unique<Animator>(delegate, task_runners,
                                          std::move(vsync_waiter));
    latch.Signal();
  });
  latch.Wait();

  // Validate it has not notified idle and start it. This will request a frame.
  task_runners.GetUITaskRunner()->PostTask([&] {
    ASSERT_FALSE(delegate.notify_idle_called_);
    // Immediately request a frame saying it can reuse the last layer tree to
    // avoid more calls to BeginFrame by the animator.
    animator->RequestFrame(false);
    task_runners.GetPlatformTaskRunner()->PostTask(flush_vsync_task);
  });
  latch.Wait();
  ASSERT_FALSE(delegate.notify_idle_called_);

  fml::AutoResetWaitableEvent render_latch;
  // Validate it has not notified idle and try to render.
  task_runners.GetUITaskRunner()->PostDelayedTask(
      [&] {
        ASSERT_FALSE(delegate.notify_idle_called_);
        EXPECT_CALL(delegate, OnAnimatorBeginFrame).WillOnce([&] {
          auto layer_tree =
              std::make_unique<LayerTree>(nullptr, DlISize(600, 800));
          animator->Render(kImplicitViewId, std::move(layer_tree), 1.0);
          render_latch.Signal();
        });
        // Request a frame that builds a layer tree and renders a frame.
        // When the frame is rendered, render_latch will be signaled.
        animator->RequestFrame(true);
        task_runners.GetPlatformTaskRunner()->PostTask(flush_vsync_task);
      },
      // See kNotifyIdleTaskWaitTime in animator.cc.
      fml::TimeDelta::FromMilliseconds(60));
  latch.Wait();
  render_latch.Wait();

  // A frame has been rendered, and the next frame request will notify idle.
  // But at the moment there isn't another frame request, therefore it still
  // hasn't notified idle.
  task_runners.GetUITaskRunner()->PostTask([&] {
    ASSERT_FALSE(delegate.notify_idle_called_);
    // False to avoid getting cals to BeginFrame that will request more frames
    // before we are ready.
    animator->RequestFrame(false);
    task_runners.GetPlatformTaskRunner()->PostTask(flush_vsync_task);
  });
  latch.Wait();

  // Now it should notify idle. Make sure it is destroyed on the UI thread.
  ASSERT_TRUE(delegate.notify_idle_called_);

  task_runners.GetPlatformTaskRunner()->PostTask(flush_vsync_task);
  latch.Wait();

  task_runners.GetUITaskRunner()->PostTask([&] {
    animator.reset();
    latch.Signal();
  });
  latch.Wait();
}

TEST_F(ShellTest, AnimatorDoesNotNotifyDelegateIfPipelineIsNotEmpty) {
  FakeAnimatorDelegate delegate;
  TaskRunners task_runners = {
      "test",
      CreateNewThread(),  // platform
      CreateNewThread(),  // raster
      CreateNewThread(),  // ui
      CreateNewThread()   // io
  };

  auto clock = std::make_shared<ShellTestVsyncClock>();
  std::shared_ptr<Animator> animator;

  auto flush_vsync_task = [&] {
    fml::AutoResetWaitableEvent ui_latch;
    task_runners.GetUITaskRunner()->PostTask([&] { ui_latch.Signal(); });
    do {
      clock->SimulateVSync();
    } while (ui_latch.WaitWithTimeout(fml::TimeDelta::FromMilliseconds(1)));
  };

  // Create the animator on the UI task runner.
  PostTaskSync(task_runners.GetUITaskRunner(), [&] {
    auto vsync_waiter = static_cast<std::unique_ptr<VsyncWaiter>>(
        std::make_unique<ShellTestVsyncWaiter>(task_runners, clock));
    animator = std::make_unique<Animator>(delegate, task_runners,
                                          std::move(vsync_waiter));
  });

  fml::AutoResetWaitableEvent begin_frame_latch;
  // It must always be called when the method 'Animator::Render' is called,
  // regardless of whether the pipeline is empty or not.
  EXPECT_CALL(delegate, OnAnimatorUpdateLatestFrameTargetTime).Times(2);
  EXPECT_CALL(delegate, OnAnimatorFrameBuilt).Times(2);
  // It will only be called once even though we call the method
  // 'Animator::Render' twice. because it will only be called when the pipeline
  // is empty.
  EXPECT_CALL(delegate, OnAnimatorDraw).Times(1);

  for (int i = 0; i < 2; i++) {
    task_runners.GetUITaskRunner()->PostTask([&] {
      EXPECT_CALL(delegate, OnAnimatorBeginFrame).WillOnce([&] {
        auto layer_tree =
            std::make_unique<LayerTree>(nullptr, DlISize(600, 800));
        animator->Render(kImplicitViewId, std::move(layer_tree), 1.0);
        begin_frame_latch.Signal();
      });
      animator->RequestFrame();
      task_runners.GetPlatformTaskRunner()->PostTask(flush_vsync_task);
    });
    begin_frame_latch.Wait();
  }

  PostTaskSync(task_runners.GetUITaskRunner(), [&] { animator.reset(); });
}

TEST_F(ShellTest, AnimatorNotifiesFrameBuiltAfterDraw) {
  FakeAnimatorDelegate delegate;
  TaskRunners task_runners = {
      "test",
      CreateNewThread(),  // platform
      CreateNewThread(),  // raster
      CreateNewThread(),  // ui
      CreateNewThread()   // io
  };

  auto clock = std::make_shared<ShellTestVsyncClock>();
  std::shared_ptr<Animator> animator;

  PostTaskSync(task_runners.GetUITaskRunner(), [&] {
    auto vsync_waiter = static_cast<std::unique_ptr<VsyncWaiter>>(
        std::make_unique<ShellTestVsyncWaiter>(task_runners, clock));
    animator = std::make_unique<Animator>(delegate, task_runners,
                                          std::move(vsync_waiter));
  });

  fml::AutoResetWaitableEvent frame_built_latch;
  fml::TimePoint build_start;
  fml::TimePoint build_end;
  EXPECT_CALL(delegate, OnAnimatorUpdateLatestFrameTargetTime);
  {
    ::testing::InSequence seq;
    EXPECT_CALL(delegate, OnAnimatorBeginFrame).WillOnce([&] {
      auto layer_tree = std::make_unique<LayerTree>(nullptr, DlISize(600, 800));
      animator->Render(kImplicitViewId, std::move(layer_tree), 1.0);
    });
    EXPECT_CALL(delegate, OnAnimatorDraw);
    EXPECT_CALL(delegate, OnAnimatorFrameBuilt)
        .WillOnce([&](fml::TimePoint start, fml::TimePoint end) {
          build_start = start;
          build_end = end;
          frame_built_latch.Signal();
        });
  }

  const fml::TimePoint before = fml::TimePoint::Now();
  PostTaskSync(task_runners.GetUITaskRunner(),
               [&] { animator->RequestFrame(); });
  clock->SimulateVSync();
  frame_built_latch.Wait();
  const fml::TimePoint after = fml::TimePoint::Now();

  EXPECT_GE(build_start, before);
  EXPECT_LE(build_start, build_end);
  EXPECT_LE(build_end, after);

  PostTaskSync(task_runners.GetUITaskRunner(), [&] { animator.reset(); });
}

TEST_F(ShellTest, AnimatorDoesNotNotifyFrameBuiltWhenNotRendered) {
  FakeAnimatorDelegate delegate;
  TaskRunners task_runners = {
      "test",
      CreateNewThread(),  // platform
      CreateNewThread(),  // raster
      CreateNewThread(),  // ui
      CreateNewThread()   // io
  };

  auto clock = std::make_shared<ShellTestVsyncClock>();
  std::shared_ptr<Animator> animator;

  PostTaskSync(task_runners.GetUITaskRunner(), [&] {
    auto vsync_waiter = static_cast<std::unique_ptr<VsyncWaiter>>(
        std::make_unique<ShellTestVsyncWaiter>(task_runners, clock));
    animator = std::make_unique<Animator>(delegate, task_runners,
                                          std::move(vsync_waiter));
  });

  EXPECT_CALL(delegate, OnAnimatorFrameBuilt).Times(0);

  // Case 1: BeginFrame does not call Render (empty layer_trees_tasks_).
  fml::AutoResetWaitableEvent begin_frame_latch;
  EXPECT_CALL(delegate, OnAnimatorBeginFrame).WillOnce([&] {
    begin_frame_latch.Signal();
  });
  PostTaskSync(task_runners.GetUITaskRunner(), [&] {
    animator->RequestFrame(/*regenerate_layer_trees=*/true);
  });
  clock->SimulateVSync();
  begin_frame_latch.Wait();
  // Wait for EndFrame() to finish on the UI thread.
  PostTaskSync(task_runners.GetUITaskRunner(), [] {});

  // Case 2: Reusing the last layer trees (DrawLastLayerTrees).
  fml::AutoResetWaitableEvent draw_last_latch;
  delegate.on_draw_last_layer_trees_ = [&] { draw_last_latch.Signal(); };
  PostTaskSync(task_runners.GetUITaskRunner(), [&] {
    animator->RequestFrame(/*regenerate_layer_trees=*/false);
  });
  clock->SimulateVSync();
  draw_last_latch.Wait();

  PostTaskSync(task_runners.GetUITaskRunner(), [&] { animator.reset(); });
}

TEST_F(ShellTest, AnimatorDoesNotNotifyFrameBuiltWhenCommitFails) {
  FakeAnimatorDelegate delegate;

  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto task_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();
  TaskRunners task_runners("test", task_runner, task_runner, task_runner,
                           task_runner);

  auto vsync_waiter = std::make_unique<CountingVsyncWaiter>(task_runners);
  Animator animator(delegate, task_runners, std::move(vsync_waiter));

  EXPECT_CALL(delegate, OnAnimatorUpdateLatestFrameTargetTime).Times(1);
  EXPECT_CALL(delegate, OnAnimatorDraw).Times(0);
  EXPECT_CALL(delegate, OnAnimatorFrameBuilt).Times(0);

  // Render and end the frame without a preceding BeginFrame, so there is no
  // active pipeline continuation and committing to the pipeline fails.
  auto layer_tree = std::make_unique<LayerTree>(nullptr, DlISize(600, 800));
  animator.Render(kImplicitViewId, std::move(layer_tree), 1.0);
  animator.OnAllViewsRendered();
}

}  // namespace testing
}  // namespace flutter

// NOLINTEND(clang-analyzer-core.StackAddressEscape)
