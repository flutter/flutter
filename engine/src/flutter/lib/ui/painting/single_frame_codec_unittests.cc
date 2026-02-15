// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/single_frame_codec.h"

#include <memory>

#include "flutter/common/task_runners.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/shell/common/shell_test.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/testing/testing.h"

// CREATE_NATIVE_ENTRY is leaky by design
// NOLINTBEGIN(clang-analyzer-core.StackAddressEscape)

#pragma GCC diagnostic ignored "-Wunreachable-code"

namespace flutter {
namespace testing {

TEST_F(ShellTest, SingleFrameCodecAccuratelyReportsSize) {
  auto message_latch = std::make_shared<fml::AutoResetWaitableEvent>();

  auto validate_codec = [](Dart_NativeArguments args) {
    auto handle = Dart_GetNativeArgument(args, 0);
    intptr_t peer = 0;
    Dart_Handle result = Dart_GetNativeInstanceField(
        handle, tonic::DartWrappable::kPeerIndex, &peer);
    ASSERT_FALSE(Dart_IsError(result));
  };
  auto finish = [message_latch](Dart_NativeArguments args) {
    message_latch->Signal();
  };

  Settings settings = CreateSettingsForFixture();
  TaskRunners task_runners("test",                  // label
                           GetCurrentTaskRunner(),  // platform
                           CreateNewThread(),       // raster
                           CreateNewThread(),       // ui
                           CreateNewThread()        // io
  );

  AddNativeCallback("ValidateCodec", CREATE_NATIVE_ENTRY(validate_codec));
  AddNativeCallback("Finish", CREATE_NATIVE_ENTRY(finish));

  std::unique_ptr<Shell> shell = CreateShell(settings, task_runners);

  ASSERT_TRUE(shell->IsSetup());
  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("createSingleFrameCodec");

  shell->RunEngine(std::move(configuration), [](auto result) {
    ASSERT_EQ(result, Engine::RunStatus::Success);
  });

  message_latch->Wait();
  DestroyShell(std::move(shell), task_runners);
}

TEST_F(ShellTest, SingleFrameCodecHandlesNoGpu) {
#ifndef FML_OS_MACOSX
  GTEST_SKIP() << "Only works on macOS currently.";
#endif

  Settings settings = CreateSettingsForFixture();
  settings.enable_impeller = true;
  TaskRunners task_runners("test",                  // label
                           GetCurrentTaskRunner(),  // platform
                           CreateNewThread(),       // raster
                           CreateNewThread(),       // ui
                           CreateNewThread()        // io
  );
  std::unique_ptr<Shell> shell = CreateShell(settings, task_runners);
  ASSERT_TRUE(shell->IsSetup());

  auto message_latch = std::make_shared<fml::AutoResetWaitableEvent>();
  auto finish = [message_latch](Dart_NativeArguments args) {
    message_latch->Signal();
  };
  AddNativeCallback("Finish", CREATE_NATIVE_ENTRY(finish));

  auto turn_off_gpu = [&](Dart_NativeArguments args) {
    auto handle = Dart_GetNativeArgument(args, 0);
    bool value = true;
    ASSERT_TRUE(Dart_IsBoolean(handle));
    Dart_BooleanValue(handle, &value);
    TurnOffGPU(shell.get(), value);
  };
  AddNativeCallback("TurnOffGPU", CREATE_NATIVE_ENTRY(turn_off_gpu));

  auto flush_awaiting_tasks = [&](Dart_NativeArguments args) {
    fml::WeakPtr io_manager = shell->GetIOManager();
    task_runners.GetIOTaskRunner()->PostTask([io_manager] {
      if (io_manager) {
        std::shared_ptr<impeller::Context> impeller_context =
            io_manager->GetImpellerContext();
        // This will cause the stored tasks to overflow and start throwing them
        // away.
        for (int i = 0; i < impeller::Context::kMaxTasksAwaitingGPU; i++) {
          impeller_context->StoreTaskForGPU([] {}, [] {});
        }
      }
    });
  };
  AddNativeCallback("FlushGpuAwaitingTasks",
                    CREATE_NATIVE_ENTRY(flush_awaiting_tasks));

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("singleFrameCodecHandlesNoGpu");

  shell->RunEngine(std::move(configuration), [](auto result) {
    ASSERT_EQ(result, Engine::RunStatus::Success);
  });

  message_latch->Wait();
  DestroyShell(std::move(shell), task_runners);
}

}  // namespace testing
}  // namespace flutter

// NOLINTEND(clang-analyzer-core.StackAddressEscape)
