// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/common/task_runners.h"
#include "flutter/fml/paths.h"
#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/runtime/dart_vm_lifecycle.h"
#include "flutter/runtime/runtime_test.h"

namespace flutter {
namespace testing {

using DartLifecycleTest = RuntimeTest;

TEST_F(DartLifecycleTest, CanStartAndShutdownVM) {
  auto settings = CreateSettingsForFixture();
  settings.leak_vm = false;
  settings.enable_observatory = false;
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
  {
    auto vm_ref = DartVMRef::Create(settings);
    ASSERT_TRUE(DartVMRef::IsInstanceRunning());
  }
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
}

TEST_F(DartLifecycleTest, CanStartAndShutdownVMOverAndOver) {
  auto settings = CreateSettingsForFixture();
  settings.leak_vm = false;
  settings.enable_observatory = false;
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
  auto count = DartVM::GetVMLaunchCount();
  for (size_t i = 0; i < 10; i++) {
    auto vm_ref = DartVMRef::Create(settings);
    ASSERT_TRUE(DartVMRef::IsInstanceRunning());
    ASSERT_EQ(DartVM::GetVMLaunchCount(), count + 1);
    count = DartVM::GetVMLaunchCount();
  }
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
}

static std::shared_ptr<DartIsolate> CreateAndRunRootIsolate(
    const Settings& settings,
    const DartVMData& vm,
    fml::RefPtr<fml::TaskRunner> task_runner,
    std::string entrypoint) {
  FML_CHECK(entrypoint.size() > 0);
  TaskRunners runners("io.flutter.test", task_runner, task_runner, task_runner,
                      task_runner);
  auto isolate_weak = DartIsolate::CreateRootIsolate(
      vm.GetSettings(),                   // settings
      vm.GetIsolateSnapshot(),            // isolate_snapshot
      vm.GetSharedSnapshot(),             // shared_snapshot
      runners,                            // task_runners
      {},                                 // window
      {},                                 // io_manager
      {},                                 // image_decoder
      "main.dart",                        // advisory_script_uri
      entrypoint.c_str(),                 // advisory_script_entrypoint
      nullptr,                            // flags
      settings.isolate_create_callback,   // isolate create callback
      settings.isolate_shutdown_callback  // isolate shutdown callback
  );

  auto isolate = isolate_weak.lock();

  if (!isolate) {
    FML_LOG(ERROR) << "Could not create valid isolate.";
    return nullptr;
  }

  if (DartVM::IsRunningPrecompiledCode()) {
    if (!isolate->PrepareForRunningFromPrecompiledCode()) {
      FML_LOG(ERROR)
          << "Could not prepare to run the isolate from precompiled code.";
      return nullptr;
    }

  } else {
    if (!isolate->PrepareForRunningFromKernels(
            settings.application_kernels())) {
      FML_LOG(ERROR) << "Could not prepare isolate from application kernels.";
      return nullptr;
    }
  }

  if (isolate->GetPhase() != DartIsolate::Phase::Ready) {
    FML_LOG(ERROR) << "Isolate was not ready.";
    return nullptr;
  }

  if (!isolate->Run(entrypoint, {}, settings.root_isolate_create_callback)) {
    FML_LOG(ERROR) << "Could not run entrypoint: " << entrypoint << ".";
    return nullptr;
  }

  if (isolate->GetPhase() != DartIsolate::Phase::Running) {
    FML_LOG(ERROR) << "Isolate was not Running.";
    return nullptr;
  }

  return isolate;
}

// TODO(chinmaygarde): This unit-test is flaky and indicates thread un-safety
// during shutdown. https://github.com/flutter/flutter/issues/36782
TEST_F(DartLifecycleTest, DISABLED_ShuttingDownTheVMShutsDownAllIsolates) {
  auto settings = CreateSettingsForFixture();
  settings.leak_vm = false;
  // Make sure the service protocol launches
  settings.enable_observatory = true;

  auto thread_task_runner = CreateNewThread();

  for (size_t i = 0; i < 3; i++) {
    ASSERT_FALSE(DartVMRef::IsInstanceRunning());

    const auto last_launch_count = DartVM::GetVMLaunchCount();

    auto vm_ref = DartVMRef::Create(settings);

    ASSERT_TRUE(DartVMRef::IsInstanceRunning());
    ASSERT_EQ(last_launch_count + 1, DartVM::GetVMLaunchCount());

    const size_t isolate_count = 5;

    fml::CountDownLatch latch(isolate_count);
    auto vm_data = vm_ref.GetVMData();
    for (size_t i = 0; i < isolate_count; ++i) {
      thread_task_runner->PostTask(
          [vm_data, &settings, &latch, thread_task_runner]() {
            ASSERT_TRUE(CreateAndRunRootIsolate(settings, *vm_data.get(),
                                                thread_task_runner,
                                                "testIsolateShutdown"));
            latch.CountDown();
          });
    }

    latch.Wait();
  }
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
}

}  // namespace testing
}  // namespace flutter
