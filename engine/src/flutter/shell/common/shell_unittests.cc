// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <functional>
#include <future>
#include <memory>

#include "flutter/fml/message_loop.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/thread_host.h"
#include "gtest/gtest.h"
#include "lib/fxl/synchronization/waitable_event.h"

#define CURRENT_TEST_NAME                                           \
  std::string {                                                     \
    ::testing::UnitTest::GetInstance()->current_test_info()->name() \
  }

namespace shell {

TEST(ShellTest, InitializeWithInvalidThreads) {
  blink::Settings settings = {};
  settings.task_observer_add = [](intptr_t, fxl::Closure) {};
  settings.task_observer_remove = [](intptr_t) {};
  settings.using_blink = false;
  blink::TaskRunners task_runners("test", nullptr, nullptr, nullptr, nullptr);
  auto shell = Shell::Create(
      std::move(task_runners), settings,
      [](Shell& shell) {
        return std::make_unique<PlatformView>(shell, shell.GetTaskRunners());
      },
      [](Shell& shell) {
        return std::make_unique<Rasterizer>(shell.GetTaskRunners());
      });
  ASSERT_FALSE(shell);
}

TEST(ShellTest, InitializeWithDifferentThreads) {
  blink::Settings settings = {};
  settings.task_observer_add = [](intptr_t, fxl::Closure) {};
  settings.task_observer_remove = [](intptr_t) {};
  settings.using_blink = false;
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
        return std::make_unique<PlatformView>(shell, shell.GetTaskRunners());
      },
      [](Shell& shell) {
        return std::make_unique<Rasterizer>(shell.GetTaskRunners());
      });
  ASSERT_TRUE(shell);
}

TEST(ShellTest, InitializeWithSingleThread) {
  blink::Settings settings = {};
  settings.task_observer_add = [](intptr_t, fxl::Closure) {};
  settings.task_observer_remove = [](intptr_t) {};
  settings.using_blink = false;
  ThreadHost thread_host("io.flutter.test." + CURRENT_TEST_NAME + ".",
                         ThreadHost::Type::Platform);
  auto task_runner = thread_host.platform_thread->GetTaskRunner();
  blink::TaskRunners task_runners("test", task_runner, task_runner, task_runner,
                                  task_runner);
  auto shell = Shell::Create(
      std::move(task_runners), settings,
      [](Shell& shell) {
        return std::make_unique<PlatformView>(shell, shell.GetTaskRunners());
      },
      [](Shell& shell) {
        return std::make_unique<Rasterizer>(shell.GetTaskRunners());
      });
  ASSERT_TRUE(shell);
}

TEST(ShellTest, InitializeWithSingleThreadWhichIsTheCallingThread) {
  blink::Settings settings = {};
  settings.task_observer_add = [](intptr_t, fxl::Closure) {};
  settings.task_observer_remove = [](intptr_t) {};
  settings.using_blink = false;
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto task_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();
  blink::TaskRunners task_runners("test", task_runner, task_runner, task_runner,
                                  task_runner);
  auto shell = Shell::Create(
      std::move(task_runners), settings,
      [](Shell& shell) {
        return std::make_unique<PlatformView>(shell, shell.GetTaskRunners());
      },
      [](Shell& shell) {
        return std::make_unique<Rasterizer>(shell.GetTaskRunners());
      });
  ASSERT_TRUE(shell);
}

TEST(ShellTest, InitializeWithMultipleThreadButCallingThreadAsPlatformThread) {
  blink::Settings settings = {};
  settings.task_observer_add = [](intptr_t, fxl::Closure) {};
  settings.task_observer_remove = [](intptr_t) {};
  settings.using_blink = false;
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
        return std::make_unique<PlatformView>(shell, shell.GetTaskRunners());
      },
      [](Shell& shell) {
        return std::make_unique<Rasterizer>(shell.GetTaskRunners());
      });
  ASSERT_TRUE(shell);
}

}  // namespace shell
