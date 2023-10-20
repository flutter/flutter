// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/lib/ui/window/platform_configuration.h"

#include <memory>

#include "flutter/common/task_runners.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/lib/ui/painting/vertices.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/shell/common/shell_test.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/testing/testing.h"

namespace flutter {
namespace testing {

class PlatformConfigurationTest : public ShellTest {};

TEST_F(PlatformConfigurationTest, Initialization) {
  auto message_latch = std::make_shared<fml::AutoResetWaitableEvent>();

  auto nativeValidateConfiguration =
      [message_latch](Dart_NativeArguments args) {
        PlatformConfiguration* configuration =
            UIDartState::Current()->platform_configuration();
        ASSERT_NE(configuration->GetMetrics(0), nullptr);
        ASSERT_EQ(configuration->GetMetrics(0)->device_pixel_ratio, 1.0);
        ASSERT_EQ(configuration->GetMetrics(0)->physical_width, 0.0);
        ASSERT_EQ(configuration->GetMetrics(0)->physical_height, 0.0);

        message_latch->Signal();
      };

  Settings settings = CreateSettingsForFixture();
  TaskRunners task_runners("test",                  // label
                           GetCurrentTaskRunner(),  // platform
                           CreateNewThread(),       // raster
                           CreateNewThread(),       // ui
                           CreateNewThread()        // io
  );

  AddNativeCallback("ValidateConfiguration",
                    CREATE_NATIVE_ENTRY(nativeValidateConfiguration));

  std::unique_ptr<Shell> shell = CreateShell(settings, task_runners);

  ASSERT_TRUE(shell->IsSetup());
  auto run_configuration = RunConfiguration::InferFromSettings(settings);
  run_configuration.SetEntrypoint("validateConfiguration");

  shell->RunEngine(std::move(run_configuration), [&](auto result) {
    ASSERT_EQ(result, Engine::RunStatus::Success);
  });

  message_latch->Wait();
  DestroyShell(std::move(shell), task_runners);
}

TEST_F(PlatformConfigurationTest, WindowMetricsUpdate) {
  auto message_latch = std::make_shared<fml::AutoResetWaitableEvent>();

  auto nativeValidateConfiguration =
      [message_latch](Dart_NativeArguments args) {
        PlatformConfiguration* configuration =
            UIDartState::Current()->platform_configuration();

        ASSERT_NE(configuration->GetMetrics(0), nullptr);
        bool has_view = configuration->UpdateViewMetrics(
            0, ViewportMetrics{2.0, 10.0, 20.0, 22, 0});
        ASSERT_TRUE(has_view);
        ASSERT_EQ(configuration->GetMetrics(0)->device_pixel_ratio, 2.0);
        ASSERT_EQ(configuration->GetMetrics(0)->physical_width, 10.0);
        ASSERT_EQ(configuration->GetMetrics(0)->physical_height, 20.0);
        ASSERT_EQ(configuration->GetMetrics(0)->physical_touch_slop, 22);

        message_latch->Signal();
      };

  Settings settings = CreateSettingsForFixture();
  TaskRunners task_runners("test",                  // label
                           GetCurrentTaskRunner(),  // platform
                           CreateNewThread(),       // raster
                           CreateNewThread(),       // ui
                           CreateNewThread()        // io
  );

  AddNativeCallback("ValidateConfiguration",
                    CREATE_NATIVE_ENTRY(nativeValidateConfiguration));

  std::unique_ptr<Shell> shell = CreateShell(settings, task_runners);

  ASSERT_TRUE(shell->IsSetup());
  auto run_configuration = RunConfiguration::InferFromSettings(settings);
  run_configuration.SetEntrypoint("validateConfiguration");

  shell->RunEngine(std::move(run_configuration), [&](auto result) {
    ASSERT_EQ(result, Engine::RunStatus::Success);
  });

  message_latch->Wait();
  DestroyShell(std::move(shell), task_runners);
}

TEST_F(PlatformConfigurationTest, GetWindowReturnsNullForNonexistentId) {
  auto message_latch = std::make_shared<fml::AutoResetWaitableEvent>();

  auto nativeValidateConfiguration =
      [message_latch](Dart_NativeArguments args) {
        PlatformConfiguration* configuration =
            UIDartState::Current()->platform_configuration();

        ASSERT_EQ(configuration->GetMetrics(1), nullptr);
        ASSERT_EQ(configuration->GetMetrics(2), nullptr);

        message_latch->Signal();
      };

  Settings settings = CreateSettingsForFixture();
  TaskRunners task_runners("test",                  // label
                           GetCurrentTaskRunner(),  // platform
                           CreateNewThread(),       // raster
                           CreateNewThread(),       // ui
                           CreateNewThread()        // io
  );

  AddNativeCallback("ValidateConfiguration",
                    CREATE_NATIVE_ENTRY(nativeValidateConfiguration));

  std::unique_ptr<Shell> shell = CreateShell(settings, task_runners);

  ASSERT_TRUE(shell->IsSetup());
  auto run_configuration = RunConfiguration::InferFromSettings(settings);
  run_configuration.SetEntrypoint("validateConfiguration");

  shell->RunEngine(std::move(run_configuration), [&](auto result) {
    ASSERT_EQ(result, Engine::RunStatus::Success);
  });

  message_latch->Wait();
  DestroyShell(std::move(shell), task_runners);
}

TEST_F(PlatformConfigurationTest, OnErrorHandlesError) {
  auto message_latch = std::make_shared<fml::AutoResetWaitableEvent>();
  bool did_throw = false;

  auto finish = [message_latch](Dart_NativeArguments args) {
    message_latch->Signal();
  };
  AddNativeCallback("Finish", CREATE_NATIVE_ENTRY(finish));

  Settings settings = CreateSettingsForFixture();
  settings.unhandled_exception_callback =
      [&did_throw](const std::string& exception,
                   const std::string& stack_trace) -> bool {
    did_throw = true;
    return false;
  };

  TaskRunners task_runners("test",                  // label
                           GetCurrentTaskRunner(),  // platform
                           CreateNewThread(),       // raster
                           CreateNewThread(),       // ui
                           CreateNewThread()        // io
  );

  std::unique_ptr<Shell> shell = CreateShell(settings, task_runners);

  ASSERT_TRUE(shell->IsSetup());
  auto run_configuration = RunConfiguration::InferFromSettings(settings);
  run_configuration.SetEntrypoint("customOnErrorTrue");

  shell->RunEngine(std::move(run_configuration), [&](auto result) {
    ASSERT_EQ(result, Engine::RunStatus::Success);
  });

  message_latch->Wait();

  // Flush the UI task runner to make sure errors that were triggered had a turn
  // to propagate.
  task_runners.GetUITaskRunner()->PostTask(
      [&message_latch]() { message_latch->Signal(); });
  message_latch->Wait();

  ASSERT_FALSE(did_throw);
  DestroyShell(std::move(shell), task_runners);
}

TEST_F(PlatformConfigurationTest, OnErrorDoesNotHandleError) {
  auto message_latch = std::make_shared<fml::AutoResetWaitableEvent>();
  std::string ex;
  std::string st;
  size_t throw_count = 0;

  auto finish = [message_latch](Dart_NativeArguments args) {
    message_latch->Signal();
  };
  AddNativeCallback("Finish", CREATE_NATIVE_ENTRY(finish));

  Settings settings = CreateSettingsForFixture();
  settings.unhandled_exception_callback =
      [&ex, &st, &throw_count](const std::string& exception,
                               const std::string& stack_trace) -> bool {
    throw_count += 1;
    ex = exception;
    st = stack_trace;
    return true;
  };

  TaskRunners task_runners("test",                  // label
                           GetCurrentTaskRunner(),  // platform
                           CreateNewThread(),       // raster
                           CreateNewThread(),       // ui
                           CreateNewThread()        // io
  );

  std::unique_ptr<Shell> shell = CreateShell(settings, task_runners);

  ASSERT_TRUE(shell->IsSetup());
  auto run_configuration = RunConfiguration::InferFromSettings(settings);
  run_configuration.SetEntrypoint("customOnErrorFalse");

  shell->RunEngine(std::move(run_configuration), [&](auto result) {
    ASSERT_EQ(result, Engine::RunStatus::Success);
  });

  message_latch->Wait();

  // Flush the UI task runner to make sure errors that were triggered had a turn
  // to propagate.
  task_runners.GetUITaskRunner()->PostTask(
      [&message_latch]() { message_latch->Signal(); });
  message_latch->Wait();

  ASSERT_EQ(throw_count, 1ul);
  ASSERT_EQ(ex, "Exception: false") << ex;
  ASSERT_EQ(st.rfind("#0      customOnErrorFalse", 0), 0ul) << st;
  DestroyShell(std::move(shell), task_runners);
}

TEST_F(PlatformConfigurationTest, OnErrorThrows) {
  auto message_latch = std::make_shared<fml::AutoResetWaitableEvent>();
  std::vector<std::string> errors;
  size_t throw_count = 0;

  auto finish = [message_latch](Dart_NativeArguments args) {
    message_latch->Signal();
  };
  AddNativeCallback("Finish", CREATE_NATIVE_ENTRY(finish));

  Settings settings = CreateSettingsForFixture();
  settings.unhandled_exception_callback =
      [&errors, &throw_count](const std::string& exception,
                              const std::string& stack_trace) -> bool {
    throw_count += 1;
    errors.push_back(exception);
    errors.push_back(stack_trace);
    return true;
  };

  TaskRunners task_runners("test",                  // label
                           GetCurrentTaskRunner(),  // platform
                           CreateNewThread(),       // raster
                           CreateNewThread(),       // ui
                           CreateNewThread()        // io
  );

  std::unique_ptr<Shell> shell = CreateShell(settings, task_runners);

  ASSERT_TRUE(shell->IsSetup());
  auto run_configuration = RunConfiguration::InferFromSettings(settings);
  run_configuration.SetEntrypoint("customOnErrorThrow");

  shell->RunEngine(std::move(run_configuration), [&](auto result) {
    ASSERT_EQ(result, Engine::RunStatus::Success);
  });

  message_latch->Wait();

  // Flush the UI task runner to make sure errors that were triggered had a turn
  // to propagate.
  task_runners.GetUITaskRunner()->PostTask(
      [&message_latch]() { message_latch->Signal(); });
  message_latch->Wait();

  ASSERT_EQ(throw_count, 2ul);
  ASSERT_EQ(errors.size(), 4ul);
  ASSERT_EQ(errors[0], "Exception: throw2") << errors[0];
  ASSERT_EQ(errors[1].rfind("#0      customOnErrorThrow"), 0ul) << errors[1];
  ASSERT_EQ(errors[2], "Exception: throw1") << errors[2];
  ASSERT_EQ(errors[3].rfind("#0      customOnErrorThrow"), 0ul) << errors[3];

  DestroyShell(std::move(shell), task_runners);
}

TEST_F(PlatformConfigurationTest, SetDartPerformanceMode) {
  auto message_latch = std::make_shared<fml::AutoResetWaitableEvent>();
  auto finish = [message_latch](Dart_NativeArguments args) {
    // call needs to happen on the UI thread.
    Dart_PerformanceMode prev =
        Dart_SetPerformanceMode(Dart_PerformanceMode_Default);
    ASSERT_EQ(Dart_PerformanceMode_Latency, prev);
    message_latch->Signal();
  };
  AddNativeCallback("Finish", CREATE_NATIVE_ENTRY(finish));

  Settings settings = CreateSettingsForFixture();

  TaskRunners task_runners("test",                  // label
                           GetCurrentTaskRunner(),  // platform
                           CreateNewThread(),       // raster
                           CreateNewThread(),       // ui
                           CreateNewThread()        // io
  );

  std::unique_ptr<Shell> shell = CreateShell(settings, task_runners);

  ASSERT_TRUE(shell->IsSetup());
  auto run_configuration = RunConfiguration::InferFromSettings(settings);
  run_configuration.SetEntrypoint("setLatencyPerformanceMode");

  shell->RunEngine(std::move(run_configuration), [&](auto result) {
    ASSERT_EQ(result, Engine::RunStatus::Success);
  });

  message_latch->Wait();
  DestroyShell(std::move(shell), task_runners);
}

}  // namespace testing
}  // namespace flutter
