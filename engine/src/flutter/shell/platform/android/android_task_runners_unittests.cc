// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/platform/android/android_task_runners.h"

#include <future>
#include <memory>
#include <thread>

#include "flutter/fml/synchronization/waitable_event.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(AndroidTaskRunnersTest, DedicatedThreadsCreation) {
  AndroidTaskRunners task_runners("test.dedicated");
  ASSERT_TRUE(task_runners.IsValid());

  auto platform_runner = task_runners.GetPlatformTaskRunner();
  auto ui_runner = task_runners.GetUITaskRunner();
  auto raster_runner = task_runners.GetRasterTaskRunner();

  ASSERT_NE(platform_runner.get(), nullptr);
  ASSERT_NE(ui_runner.get(), nullptr);
  ASSERT_NE(raster_runner.get(), nullptr);

  EXPECT_NE(platform_runner.get(), ui_runner.get());
  EXPECT_NE(platform_runner.get(), raster_runner.get());
  EXPECT_NE(ui_runner.get(), raster_runner.get());

  const auto& custom = task_runners.GetCustomTaskRunners();
  EXPECT_EQ(custom.struct_size, sizeof(FlutterCustomTaskRunners));
  ASSERT_NE(custom.platform_task_runner, nullptr);
  ASSERT_NE(custom.ui_task_runner, nullptr);
  ASSERT_NE(custom.render_task_runner, nullptr);
  EXPECT_EQ(custom.thread_priority_setter, &AndroidThreadPrioritySetter);

  EXPECT_EQ(custom.platform_task_runner->struct_size,
            sizeof(FlutterTaskRunnerDescription));
  EXPECT_EQ(custom.ui_task_runner->struct_size,
            sizeof(FlutterTaskRunnerDescription));
  EXPECT_EQ(custom.render_task_runner->struct_size,
            sizeof(FlutterTaskRunnerDescription));

  EXPECT_NE(custom.platform_task_runner->identifier,
            custom.ui_task_runner->identifier);
  EXPECT_NE(custom.platform_task_runner->identifier,
            custom.render_task_runner->identifier);
  EXPECT_NE(custom.ui_task_runner->identifier,
            custom.render_task_runner->identifier);
}

TEST(AndroidTaskRunnersTest, MergedPlatformUIThreads) {
  AndroidTaskRunners task_runners("test.merged",
                                  /*merged_platform_ui_thread=*/true);
  ASSERT_TRUE(task_runners.IsValid());

  auto platform_runner = task_runners.GetPlatformTaskRunner();
  auto ui_runner = task_runners.GetUITaskRunner();
  auto raster_runner = task_runners.GetRasterTaskRunner();

  ASSERT_NE(platform_runner.get(), nullptr);
  ASSERT_NE(ui_runner.get(), nullptr);
  ASSERT_NE(raster_runner.get(), nullptr);

  EXPECT_EQ(platform_runner.get(), ui_runner.get());
  EXPECT_NE(platform_runner.get(), raster_runner.get());

  const auto& custom = task_runners.GetCustomTaskRunners();
  EXPECT_EQ(custom.struct_size, sizeof(FlutterCustomTaskRunners));
  ASSERT_NE(custom.platform_task_runner, nullptr);
  ASSERT_NE(custom.ui_task_runner, nullptr);

  EXPECT_EQ(custom.platform_task_runner->identifier,
            custom.ui_task_runner->identifier);
  EXPECT_NE(custom.platform_task_runner->identifier,
            custom.render_task_runner->identifier);
}

TEST(AndroidTaskRunnersTest, CustomConstructedRunners) {
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto platform = fml::MessageLoop::GetCurrent().GetTaskRunner();
  auto thread1 = std::make_unique<fml::Thread>("test.custom.ui");
  auto thread2 = std::make_unique<fml::Thread>("test.custom.raster");

  AndroidTaskRunners task_runners("test.custom", platform,
                                  thread1->GetTaskRunner(),
                                  thread2->GetTaskRunner());

  ASSERT_TRUE(task_runners.IsValid());
  EXPECT_EQ(task_runners.GetPlatformTaskRunner(), platform);
  EXPECT_EQ(task_runners.GetUITaskRunner(), thread1->GetTaskRunner());
  EXPECT_EQ(task_runners.GetRasterTaskRunner(), thread2->GetTaskRunner());
}

TEST(AndroidTaskRunnersTest, RunsTasksOnCurrentThreadCallback) {
  AndroidTaskRunners task_runners("test.thread_check");
  ASSERT_TRUE(task_runners.IsValid());

  const auto& custom = task_runners.GetCustomTaskRunners();

  // On the current thread (which initialized the message loop), platform runner
  // runs tasks on current thread, while UI and Raster runners do not.
  EXPECT_TRUE(custom.platform_task_runner->runs_task_on_current_thread_callback(
      custom.platform_task_runner->user_data));
  EXPECT_FALSE(custom.ui_task_runner->runs_task_on_current_thread_callback(
      custom.ui_task_runner->user_data));
  EXPECT_FALSE(custom.render_task_runner->runs_task_on_current_thread_callback(
      custom.render_task_runner->user_data));

  // Check from UI thread.
  fml::AutoResetWaitableEvent ui_latch;
  bool ui_on_ui = false;
  bool platform_on_ui = true;
  task_runners.GetUITaskRunner()->PostTask([&]() {
    ui_on_ui = custom.ui_task_runner->runs_task_on_current_thread_callback(
        custom.ui_task_runner->user_data);
    platform_on_ui =
        custom.platform_task_runner->runs_task_on_current_thread_callback(
            custom.platform_task_runner->user_data);
    ui_latch.Signal();
  });
  ui_latch.Wait();
  EXPECT_TRUE(ui_on_ui);
  EXPECT_FALSE(platform_on_ui);

  // Check from Raster thread.
  fml::AutoResetWaitableEvent raster_latch;
  bool raster_on_raster = false;
  task_runners.GetRasterTaskRunner()->PostTask([&]() {
    raster_on_raster =
        custom.render_task_runner->runs_task_on_current_thread_callback(
            custom.render_task_runner->user_data);
    raster_latch.Signal();
  });
  raster_latch.Wait();
  EXPECT_TRUE(raster_on_raster);
}

TEST(AndroidTaskRunnersTest, PreStartupTaskStagingAndDraining) {
  AndroidTaskRunners task_runners("test.staging");
  ASSERT_TRUE(task_runners.IsValid());

  EXPECT_EQ(task_runners.GetEngine(), nullptr);
  EXPECT_EQ(task_runners.GetPendingTasksCount(), 0u);

  const auto& custom = task_runners.GetCustomTaskRunners();
  ASSERT_NE(custom.ui_task_runner->post_task_callback, nullptr);

  // Post task before SetEngine is called.
  FlutterTask startup_task = {};
  startup_task.runner = reinterpret_cast<FlutterTaskRunner>(0x123);
  startup_task.task = 999;

  custom.ui_task_runner->post_task_callback(
      startup_task, fml::TimePoint::Now().ToEpochDelta().ToNanoseconds(),
      custom.ui_task_runner->user_data);

  // Wait on UI runner to guarantee the post_task closure executed and staged
  // task.
  fml::AutoResetWaitableEvent latch;
  task_runners.GetUITaskRunner()->PostTask([&latch]() { latch.Signal(); });
  latch.Wait();

  EXPECT_EQ(task_runners.GetPendingTasksCount(), 1u);

  // Now set the engine handle and verify pending tasks are drained.
  auto fake_engine = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0x777);
  task_runners.SetEngine(fake_engine);

  EXPECT_EQ(task_runners.GetEngine(), fake_engine);
  EXPECT_EQ(task_runners.GetPendingTasksCount(), 0u);
}

TEST(AndroidTaskRunnersTest, TeardownSafetyWithPendingTasks) {
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto platform = fml::MessageLoop::GetCurrent().GetTaskRunner();

  {
    AndroidTaskRunners task_runners("test.teardown",
                                    /*merged_platform_ui_thread=*/true);
    const auto& custom = task_runners.GetCustomTaskRunners();

    FlutterTask delayed_task = {};
    delayed_task.runner = reinterpret_cast<FlutterTaskRunner>(0x456);
    delayed_task.task = 1234;

    // Post task to platform runner with a small delay.
    custom.platform_task_runner->post_task_callback(
        delayed_task,
        (fml::TimePoint::Now() + fml::TimeDelta::FromMilliseconds(10))
            .ToEpochDelta()
            .ToNanoseconds(),
        custom.platform_task_runner->user_data);

    // Destruct task_runners immediately while task is still scheduled on
    // platform loop.
  }

  // Sleep slightly and run expired tasks on platform loop to verify zero UAF /
  // crashes.
  std::this_thread::sleep_for(std::chrono::milliseconds(20));
  fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
}

TEST(AndroidTaskRunnersTest, NullSafetyChecks) {
  AndroidTaskRunners task_runners("test.null_safety");
  const auto& custom = task_runners.GetCustomTaskRunners();

  EXPECT_FALSE(
      custom.platform_task_runner->runs_task_on_current_thread_callback(
          nullptr));

  FlutterTask dummy_task = {};
  // Calling post_task_callback with nullptr user_data must not crash.
  custom.platform_task_runner->post_task_callback(dummy_task, 0, nullptr);
}

TEST(AndroidTaskRunnersTest, ThreadPrioritySetter) {
  // Test invoking priority setters on a background thread.
  std::thread bg_thread([]() {
    AndroidThreadPrioritySetter(FlutterThreadPriority::kBackground);
    AndroidThreadPrioritySetter(FlutterThreadPriority::kDisplay);
    AndroidThreadPrioritySetter(FlutterThreadPriority::kRaster);
    AndroidThreadPrioritySetter(FlutterThreadPriority::kNormal);

    fml::Thread::ThreadConfig config("io.flutter.test",
                                     fml::Thread::ThreadPriority::kBackground);
    AndroidPlatformThreadConfigSetter(config);
  });
  bg_thread.join();
}

}  // namespace testing
}  // namespace flutter
