// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <functional>
#include <future>
#include <memory>

#include "flutter/fml/message_loop.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/shell/gpu/gpu_surface_software.h"
#include "gtest/gtest.h"

#define CURRENT_TEST_NAME                                           \
  std::string {                                                     \
    ::testing::UnitTest::GetInstance()->current_test_info()->name() \
  }

namespace shell {

class TestPlatformView : public PlatformView,
                         public GPUSurfaceSoftwareDelegate {
 public:
  TestPlatformView(PlatformView::Delegate& delegate,
                   blink::TaskRunners task_runners)
      : PlatformView(delegate, std::move(task_runners)) {}

 private:
  // |PlatformView|
  std::unique_ptr<Surface> CreateRenderingSurface() override {
    return std::make_unique<GPUSurfaceSoftware>(this);
  }

  // |GPUSurfaceSoftwareDelegate|
  virtual sk_sp<SkSurface> AcquireBackingStore(const SkISize& size) override {
    return SkSurface::MakeRasterN32Premul(size.width(), size.height());
  }

  // |GPUSurfaceSoftwareDelegate|
  virtual bool PresentBackingStore(sk_sp<SkSurface> backing_store) override {
    return true;
  }

  FML_DISALLOW_COPY_AND_ASSIGN(TestPlatformView);
};

static bool ValidateShell(Shell* shell) {
  if (!shell) {
    return false;
  }

  if (!shell->IsSetup()) {
    return false;
  }

  {
    fml::AutoResetWaitableEvent latch;
    fml::TaskRunner::RunNowOrPostTask(
        shell->GetTaskRunners().GetPlatformTaskRunner(), [shell, &latch]() {
          shell->GetPlatformView()->NotifyCreated();
          latch.Signal();
        });
    latch.Wait();
  }

  {
    fml::AutoResetWaitableEvent latch;
    fml::TaskRunner::RunNowOrPostTask(
        shell->GetTaskRunners().GetPlatformTaskRunner(), [shell, &latch]() {
          shell->GetPlatformView()->NotifyDestroyed();
          latch.Signal();
        });
    latch.Wait();
  }

  return true;
}

TEST(ShellTest, InitializeWithInvalidThreads) {
  blink::Settings settings = {};
  settings.task_observer_add = [](intptr_t, fml::closure) {};
  settings.task_observer_remove = [](intptr_t) {};
  blink::TaskRunners task_runners("test", nullptr, nullptr, nullptr, nullptr);
  auto shell = Shell::Create(
      std::move(task_runners), settings,
      [](Shell& shell) {
        return std::make_unique<TestPlatformView>(shell,
                                                  shell.GetTaskRunners());
      },
      [](Shell& shell) {
        return std::make_unique<Rasterizer>(shell.GetTaskRunners());
      });
  ASSERT_FALSE(shell);
}

TEST(ShellTest, InitializeWithDifferentThreads) {
  blink::Settings settings = {};
  settings.task_observer_add = [](intptr_t, fml::closure) {};
  settings.task_observer_remove = [](intptr_t) {};
  ThreadHost thread_host("io.flutter.test." + CURRENT_TEST_NAME + ".",
                         ThreadHost::Type::Platform | ThreadHost::Type::GPU |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  blink::TaskRunners task_runners("test",
                                  thread_host.platform_thread->GetTaskRunner(),
                                  thread_host.gpu_thread->GetTaskRunner(),
                                  thread_host.ui_thread->GetTaskRunner(),
                                  thread_host.io_thread->GetTaskRunner());
  auto shell = Shell::Create(
      std::move(task_runners), settings,
      [](Shell& shell) {
        return std::make_unique<TestPlatformView>(shell,
                                                  shell.GetTaskRunners());
      },
      [](Shell& shell) {
        return std::make_unique<Rasterizer>(shell.GetTaskRunners());
      });
  ASSERT_TRUE(ValidateShell(shell.get()));
}

TEST(ShellTest, InitializeWithSingleThread) {
  blink::Settings settings = {};
  settings.task_observer_add = [](intptr_t, fml::closure) {};
  settings.task_observer_remove = [](intptr_t) {};
  ThreadHost thread_host("io.flutter.test." + CURRENT_TEST_NAME + ".",
                         ThreadHost::Type::Platform);
  auto task_runner = thread_host.platform_thread->GetTaskRunner();
  blink::TaskRunners task_runners("test", task_runner, task_runner, task_runner,
                                  task_runner);
  auto shell = Shell::Create(
      std::move(task_runners), settings,
      [](Shell& shell) {
        return std::make_unique<TestPlatformView>(shell,
                                                  shell.GetTaskRunners());
      },
      [](Shell& shell) {
        return std::make_unique<Rasterizer>(shell.GetTaskRunners());
      });
  ASSERT_TRUE(ValidateShell(shell.get()));
}

TEST(ShellTest, InitializeWithSingleThreadWhichIsTheCallingThread) {
  blink::Settings settings = {};
  settings.task_observer_add = [](intptr_t, fml::closure) {};
  settings.task_observer_remove = [](intptr_t) {};
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto task_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();
  blink::TaskRunners task_runners("test", task_runner, task_runner, task_runner,
                                  task_runner);
  auto shell = Shell::Create(
      std::move(task_runners), settings,
      [](Shell& shell) {
        return std::make_unique<TestPlatformView>(shell,
                                                  shell.GetTaskRunners());
      },
      [](Shell& shell) {
        return std::make_unique<Rasterizer>(shell.GetTaskRunners());
      });
  ASSERT_TRUE(ValidateShell(shell.get()));
}

TEST(ShellTest, InitializeWithMultipleThreadButCallingThreadAsPlatformThread) {
  blink::Settings settings = {};
  settings.task_observer_add = [](intptr_t, fml::closure) {};
  settings.task_observer_remove = [](intptr_t) {};
  ThreadHost thread_host(
      "io.flutter.test." + CURRENT_TEST_NAME + ".",
      ThreadHost::Type::GPU | ThreadHost::Type::IO | ThreadHost::Type::UI);
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  blink::TaskRunners task_runners(
      "test", fml::MessageLoop::GetCurrent().GetTaskRunner(),
      thread_host.gpu_thread->GetTaskRunner(),
      thread_host.ui_thread->GetTaskRunner(),
      thread_host.io_thread->GetTaskRunner());
  auto shell = Shell::Create(
      std::move(task_runners), settings,
      [](Shell& shell) {
        return std::make_unique<TestPlatformView>(shell,
                                                  shell.GetTaskRunners());
      },
      [](Shell& shell) {
        return std::make_unique<Rasterizer>(shell.GetTaskRunners());
      });
  ASSERT_TRUE(ValidateShell(shell.get()));
}

// Reported in Bug: Engine deadlocks when gpu and platforms threads are the same
// #21398 (https://github.com/flutter/flutter/issues/21398)
TEST(ShellTest, DISABLED_InitializeWithGPUAndPlatformThreadsTheSame) {
  blink::Settings settings = {};
  settings.task_observer_add = [](intptr_t, fml::closure) {};
  settings.task_observer_remove = [](intptr_t) {};
  ThreadHost thread_host(
      "io.flutter.test." + CURRENT_TEST_NAME + ".",
      ThreadHost::Type::Platform | ThreadHost::Type::IO | ThreadHost::Type::UI);
  blink::TaskRunners task_runners(
      "test",
      thread_host.platform_thread->GetTaskRunner(),  // platform
      thread_host.platform_thread->GetTaskRunner(),  // gpu
      thread_host.ui_thread->GetTaskRunner(),        // ui
      thread_host.io_thread->GetTaskRunner()         // io
  );
  auto shell = Shell::Create(
      std::move(task_runners), settings,
      [](Shell& shell) {
        return std::make_unique<TestPlatformView>(shell,
                                                  shell.GetTaskRunners());
      },
      [](Shell& shell) {
        return std::make_unique<Rasterizer>(shell.GetTaskRunners());
      });
  ASSERT_TRUE(ValidateShell(shell.get()));
}

}  // namespace shell
