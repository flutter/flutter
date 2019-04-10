// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <functional>
#include <future>
#include <memory>

#include "flutter/fml/make_copyable.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/shell_test.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/shell/gpu/gpu_surface_software.h"
#include "flutter/testing/testing.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

class TestPlatformView : public PlatformView,
                         public GPUSurfaceSoftwareDelegate {
 public:
  TestPlatformView(PlatformView::Delegate& delegate,
                   flutter::TaskRunners task_runners)
      : PlatformView(delegate, std::move(task_runners)) {}

 private:
  // |PlatformView|
  std::unique_ptr<Surface> CreateRenderingSurface() override {
    return std::make_unique<GPUSurfaceSoftware>(this);
  }

  // |GPUSurfaceSoftwareDelegate|
  virtual sk_sp<SkSurface> AcquireBackingStore(const SkISize& size) override {
    SkImageInfo image_info = SkImageInfo::MakeN32Premul(
        size.width(), size.height(), SkColorSpace::MakeSRGB());
    return SkSurface::MakeRaster(image_info);
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

TEST_F(ShellTest, InitializeWithInvalidThreads) {
  flutter::Settings settings = CreateSettingsForFixture();
  flutter::TaskRunners task_runners("test", nullptr, nullptr, nullptr, nullptr);
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

TEST_F(ShellTest, InitializeWithDifferentThreads) {
  flutter::Settings settings = CreateSettingsForFixture();
  ThreadHost thread_host(
      "io.flutter.test." + ::testing::GetCurrentTestName() + ".",
      ThreadHost::Type::Platform | ThreadHost::Type::GPU |
          ThreadHost::Type::IO | ThreadHost::Type::UI);
  flutter::TaskRunners task_runners(
      "test", thread_host.platform_thread->GetTaskRunner(),
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

TEST_F(ShellTest, InitializeWithSingleThread) {
  flutter::Settings settings = CreateSettingsForFixture();
  ThreadHost thread_host(
      "io.flutter.test." + ::testing::GetCurrentTestName() + ".",
      ThreadHost::Type::Platform);
  auto task_runner = thread_host.platform_thread->GetTaskRunner();
  flutter::TaskRunners task_runners("test", task_runner, task_runner,
                                    task_runner, task_runner);
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

TEST_F(ShellTest, InitializeWithSingleThreadWhichIsTheCallingThread) {
  flutter::Settings settings = CreateSettingsForFixture();
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto task_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();
  flutter::TaskRunners task_runners("test", task_runner, task_runner,
                                    task_runner, task_runner);
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

TEST_F(ShellTest,
       InitializeWithMultipleThreadButCallingThreadAsPlatformThread) {
  flutter::Settings settings = CreateSettingsForFixture();
  ThreadHost thread_host(
      "io.flutter.test." + ::testing::GetCurrentTestName() + ".",
      ThreadHost::Type::GPU | ThreadHost::Type::IO | ThreadHost::Type::UI);
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  flutter::TaskRunners task_runners(
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

TEST_F(ShellTest, InitializeWithGPUAndPlatformThreadsTheSame) {
  flutter::Settings settings = CreateSettingsForFixture();
  ThreadHost thread_host(
      "io.flutter.test." + ::testing::GetCurrentTestName() + ".",
      ThreadHost::Type::Platform | ThreadHost::Type::IO | ThreadHost::Type::UI);
  flutter::TaskRunners task_runners(
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

TEST_F(ShellTest, FixturesAreFunctional) {
  const auto settings = CreateSettingsForFixture();
  auto shell = Shell::Create(
      GetTaskRunnersForFixture(), settings,
      [](Shell& shell) {
        return std::make_unique<TestPlatformView>(shell,
                                                  shell.GetTaskRunners());
      },
      [](Shell& shell) {
        return std::make_unique<Rasterizer>(shell.GetTaskRunners());
      });
  ASSERT_TRUE(ValidateShell(shell.get()));

  auto configuration = RunConfiguration::InferFromSettings(settings);
  ASSERT_TRUE(configuration.IsValid());
  configuration.SetEntrypoint("fixturesAreFunctionalMain");

  fml::AutoResetWaitableEvent main_latch;
  AddNativeCallback(
      "SayHiFromFixturesAreFunctionalMain",
      CREATE_NATIVE_ENTRY([&main_latch](auto args) { main_latch.Signal(); }));

  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      shell->GetTaskRunners().GetUITaskRunner(),
      fml::MakeCopyable([&latch, config = std::move(configuration),
                         engine = shell->GetEngine()]() mutable {
        ASSERT_TRUE(engine);
        ASSERT_EQ(engine->Run(std::move(config)), Engine::RunStatus::Success);
        latch.Signal();
      }));

  latch.Wait();
  main_latch.Wait();
}

}  // namespace testing
}  // namespace flutter
