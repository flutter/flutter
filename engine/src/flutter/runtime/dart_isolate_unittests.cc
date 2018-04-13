// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/thread.h"
#include "flutter/runtime/dart_isolate.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/testing/testing.h"
#include "flutter/testing/thread_test.h"

#define CURRENT_TEST_NAME                                           \
  std::string {                                                     \
    ::testing::UnitTest::GetInstance()->current_test_info()->name() \
  }

namespace blink {

using DartIsolateTest = ::testing::ThreadTest;

TEST_F(DartIsolateTest, RootIsolateCreationAndShutdown) {
  Settings settings = {};
  settings.task_observer_add = [](intptr_t, fxl::Closure) {};
  settings.task_observer_remove = [](intptr_t) {};
  auto vm = DartVM::ForProcess(settings);
  ASSERT_TRUE(vm);
  TaskRunners task_runners(CURRENT_TEST_NAME,       //
                           GetCurrentTaskRunner(),  //
                           GetCurrentTaskRunner(),  //
                           GetCurrentTaskRunner(),  //
                           GetCurrentTaskRunner()   //
  );
  auto root_isolate = DartIsolate::CreateRootIsolate(
      vm.get(),                  // vm
      vm->GetIsolateSnapshot(),  // isolate snapshot
      std::move(task_runners),   // task runners
      nullptr,                   // window
      {},                        // resource context
      nullptr                    // unref qeueue
  );
  ASSERT_TRUE(root_isolate);
  ASSERT_EQ(root_isolate->GetPhase(), DartIsolate::Phase::LibrariesSetup);
  ASSERT_TRUE(root_isolate->Shutdown());
}

TEST_F(DartIsolateTest, IsolateCanAssociateSnapshot) {
  Settings settings = {};
  settings.task_observer_add = [](intptr_t, fxl::Closure) {};
  settings.task_observer_remove = [](intptr_t) {};
  auto vm = DartVM::ForProcess(settings);
  ASSERT_TRUE(vm);
  TaskRunners task_runners(CURRENT_TEST_NAME,       //
                           GetCurrentTaskRunner(),  //
                           GetCurrentTaskRunner(),  //
                           GetCurrentTaskRunner(),  //
                           GetCurrentTaskRunner()   //
  );
  auto root_isolate = DartIsolate::CreateRootIsolate(
      vm.get(),                  // vm
      vm->GetIsolateSnapshot(),  // isolate snapshot
      std::move(task_runners),   // task runners
      nullptr,                   // window
      {},                        // resource context
      nullptr                    // unref qeueue
  );
  ASSERT_TRUE(root_isolate);
  ASSERT_EQ(root_isolate->GetPhase(), DartIsolate::Phase::LibrariesSetup);
  ASSERT_TRUE(root_isolate->PrepareForRunningFromSource(
      testing::GetFixturesPath() + std::string{"/simple_main.dart"}, ""));
  ASSERT_EQ(root_isolate->GetPhase(), DartIsolate::Phase::Ready);
  ASSERT_TRUE(root_isolate->Shutdown());
}

TEST_F(DartIsolateTest, CanResolveAndInvokeMethod) {
  Settings settings = {};
  settings.task_observer_add = [](intptr_t, fxl::Closure) {};
  settings.task_observer_remove = [](intptr_t) {};
  auto vm = DartVM::ForProcess(settings);
  ASSERT_TRUE(vm);
  TaskRunners task_runners(CURRENT_TEST_NAME,       //
                           GetCurrentTaskRunner(),  //
                           GetCurrentTaskRunner(),  //
                           GetCurrentTaskRunner(),  //
                           GetCurrentTaskRunner()   //
  );
  auto root_isolate = DartIsolate::CreateRootIsolate(
      vm.get(),                  // vm
      vm->GetIsolateSnapshot(),  // isolate snapshot
      std::move(task_runners),   // task runners
      nullptr,                   // window
      {},                        // resource context
      nullptr                    // unref qeueue
  );
  ASSERT_TRUE(root_isolate);
  ASSERT_EQ(root_isolate->GetPhase(), DartIsolate::Phase::LibrariesSetup);
  ASSERT_TRUE(root_isolate->PrepareForRunningFromSource(
      testing::GetFixturesPath() + std::string{"/simple_main.dart"}, ""));
  ASSERT_EQ(root_isolate->GetPhase(), DartIsolate::Phase::Ready);
  ASSERT_TRUE(root_isolate->Run("simple_main"));
  ASSERT_EQ(root_isolate->GetPhase(), DartIsolate::Phase::Running);
  ASSERT_TRUE(root_isolate->Shutdown());
}

}  // namespace blink
