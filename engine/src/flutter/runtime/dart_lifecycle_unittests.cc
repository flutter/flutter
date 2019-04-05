// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/common/task_runners.h"
#include "flutter/fml/paths.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/runtime/dart_vm_lifecycle.h"
#include "flutter/runtime/runtime_test.h"

namespace blink {
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

static void CreateAndRunRootIsolate(
    std::shared_ptr<DartIsolate>& isolate_result,
    const Settings& settings,
    const DartVMData& vm,
    fml::RefPtr<fml::TaskRunner> task_runner,
    std::string entrypoint) {
  FML_CHECK(entrypoint.size() > 0);
  TaskRunners runners("io.flutter.test", task_runner, task_runner, task_runner,
                      task_runner);
  auto isolate_weak = DartIsolate::CreateRootIsolate(
      vm.GetSettings(),         // settings
      vm.GetIsolateSnapshot(),  // isolate_snapshot
      vm.GetSharedSnapshot(),   // shared_snapshot
      runners,                  // task_runners
      {},                       // window
      {},                       // snapshot_delegate
      {},                       // io_manager
      "main.dart",              // advisory_script_uri
      entrypoint.c_str(),       // advisory_script_entrypoint
      nullptr                   // flags
  );

  auto isolate = isolate_weak.lock();

  if (!isolate) {
    FML_LOG(ERROR) << "Could not create valid isolate.";
    return;
  }

  if (DartVM::IsRunningPrecompiledCode()) {
    if (!isolate->PrepareForRunningFromPrecompiledCode()) {
      FML_LOG(ERROR)
          << "Could not prepare to run the isolate from precompiled code.";
      return;
    }

  } else {
    if (!isolate->PrepareForRunningFromKernels(
            settings.application_kernels())) {
      FML_LOG(ERROR) << "Could not prepare isolate from application kernels.";
      return;
    }
  }

  if (isolate->GetPhase() != DartIsolate::Phase::Ready) {
    FML_LOG(ERROR) << "Isolate was not ready.";
    return;
  }

  if (!isolate->Run(entrypoint, settings.root_isolate_create_callback)) {
    FML_LOG(ERROR) << "Could not run entrypoint: " << entrypoint << ".";
    return;
  }

  if (isolate->GetPhase() != DartIsolate::Phase::Running) {
    FML_LOG(ERROR) << "Isolate was not Running.";
    return;
  }

  isolate_result = isolate;
}

static std::shared_ptr<DartIsolate> CreateAndRunRootIsolate(
    const Settings& settings,
    const DartVMData& vm,
    fml::RefPtr<fml::TaskRunner> task_runner,
    std::string entrypoint) {
  fml::AutoResetWaitableEvent latch;
  std::shared_ptr<DartIsolate> isolate;
  fml::TaskRunner::RunNowOrPostTask(task_runner, [&]() {
    CreateAndRunRootIsolate(isolate, settings, vm, task_runner, entrypoint);
    latch.Signal();
  });
  latch.Wait();
  return isolate;
}

TEST_F(DartLifecycleTest, ShuttingDownTheVMShutsDownTheIsolate) {
  auto settings = CreateSettingsForFixture();
  settings.leak_vm = false;
  settings.enable_observatory = false;
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
  {
    auto vm_ref = DartVMRef::Create(settings);
    ASSERT_TRUE(DartVMRef::IsInstanceRunning());
    ASSERT_EQ(vm_ref->GetIsolateCount(), 0u);
    auto isolate =
        CreateAndRunRootIsolate(settings, *vm_ref.GetVMData(),
                                GetThreadTaskRunner(), "testIsolateShutdown");
    ASSERT_TRUE(isolate);
    ASSERT_EQ(vm_ref->GetIsolateCount(), 1u);
    vm_ref->ShutdownAllIsolates();
    ASSERT_EQ(vm_ref->GetIsolateCount(), 0u);
  }
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
}

}  // namespace testing
}  // namespace blink
