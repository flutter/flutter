// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/dart_vm.h"
#include "flutter/runtime/dart_vm_lifecycle.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/testing/testing.h"
#include "flutter/testing/thread_test.h"
#include "gtest/gtest.h"

namespace blink {

static Settings GetTestSettings() {
  Settings settings;
  settings.verbose_logging = true;
  settings.task_observer_add = [](intptr_t, fml::closure) {};
  settings.task_observer_remove = [](intptr_t) {};
  return settings;
}

TEST(DartVM, SimpleInitialization) {
  auto vm1 = DartVMRef::Create(GetTestSettings());
  ASSERT_TRUE(vm1);

  // Multiple initializations should return the same VM.
  auto vm2 = DartVMRef::Create(GetTestSettings());
  ASSERT_TRUE(vm2);

  ASSERT_EQ(&vm1, &vm2);
  ASSERT_FALSE(DartVM::IsRunningPrecompiledCode());
}

TEST(DartVM, SimpleIsolateNameServer) {
  auto vm = DartVMRef::Create(GetTestSettings());
  auto ns = vm->GetIsolateNameServer();
  ASSERT_EQ(ns->LookupIsolatePortByName("foobar"), ILLEGAL_PORT);
  ASSERT_FALSE(ns->RemoveIsolateNameMapping("foobar"));
  ASSERT_TRUE(ns->RegisterIsolatePortWithName(123, "foobar"));
  ASSERT_FALSE(ns->RegisterIsolatePortWithName(123, "foobar"));
  ASSERT_EQ(ns->LookupIsolatePortByName("foobar"), 123);
  ASSERT_TRUE(ns->RemoveIsolateNameMapping("foobar"));
}

TEST(DartVM, CanReinitializeVMOverAndOver) {
  size_t vm_launch_count = DartVM::GetVMLaunchCount();
  for (size_t i = 0; i < 1000; ++i) {
    FML_LOG(INFO) << "Run " << i + 1;

    // VM should not already be running.
    ASSERT_FALSE(DartVMRef::IsInstanceRunning());

    auto vm = DartVMRef::Create(GetTestSettings());
    ASSERT_TRUE(vm);
    size_t new_vm_launch_count = DartVM::GetVMLaunchCount();
    ASSERT_EQ(vm_launch_count + 1, new_vm_launch_count);
    vm_launch_count = new_vm_launch_count;

    // VM should now be running
    ASSERT_TRUE(DartVMRef::IsInstanceRunning());
  }
}

using DartVMThreadTest = ::testing::ThreadTest;

TEST_F(DartVMThreadTest, CanRunIsolatesInANewVM) {
  for (size_t i = 0; i < 1000; ++i) {
    FML_LOG(INFO) << "Run " << i + 1;
    size_t vm_launch_count = DartVM::GetVMLaunchCount();

    // VM should not already be running.
    ASSERT_FALSE(DartVMRef::IsInstanceRunning());

    auto vm = DartVMRef::Create(GetTestSettings());
    ASSERT_TRUE(vm);

    // VM should not already be running.
    ASSERT_TRUE(DartVMRef::IsInstanceRunning());

    size_t new_vm_launch_count = DartVM::GetVMLaunchCount();
    ASSERT_EQ(vm_launch_count + 1, new_vm_launch_count);

    Settings settings = {};

    settings.task_observer_add = [](intptr_t, fml::closure) {};
    settings.task_observer_remove = [](intptr_t) {};

    auto labels = testing::GetCurrentTestName() + std::to_string(i);
    shell::ThreadHost host(labels, shell::ThreadHost::Type::UI |
                                       shell::ThreadHost::Type::GPU |
                                       shell::ThreadHost::Type::IO);

    TaskRunners task_runners(
        labels,                            // task runner labels
        GetCurrentTaskRunner(),            // platform task runner
        host.gpu_thread->GetTaskRunner(),  // GPU task runner
        host.ui_thread->GetTaskRunner(),   // UI task runner
        host.io_thread->GetTaskRunner()    // IO task runner
    );

    auto weak_isolate = DartIsolate::CreateRootIsolate(
        vm->GetVMData()->GetSettings(),         // settings
        vm->GetVMData()->GetIsolateSnapshot(),  // isolate snapshot
        vm->GetVMData()->GetSharedSnapshot(),   // shared snapshot
        std::move(task_runners),                // task runners
        nullptr,                                // window
        {},                                     // snapshot delegate
        {},                                     // io manager
        "main.dart",                            // advisory uri
        "main"                                  // advisory entrypoint
    );

    auto root_isolate = weak_isolate.lock();
    ASSERT_TRUE(root_isolate);
    ASSERT_EQ(root_isolate->GetPhase(), DartIsolate::Phase::LibrariesSetup);
    ASSERT_TRUE(root_isolate->Shutdown());
  }
}

}  // namespace blink
