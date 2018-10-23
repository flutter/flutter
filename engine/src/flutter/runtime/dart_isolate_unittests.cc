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
  settings.task_observer_add = [](intptr_t, fml::closure) {};
  settings.task_observer_remove = [](intptr_t) {};
  auto vm = DartVM::ForProcess(settings);
  ASSERT_TRUE(vm);
  TaskRunners task_runners(CURRENT_TEST_NAME,       //
                           GetCurrentTaskRunner(),  //
                           GetCurrentTaskRunner(),  //
                           GetCurrentTaskRunner(),  //
                           GetCurrentTaskRunner()   //
  );
  auto weak_isolate = DartIsolate::CreateRootIsolate(
      vm.get(),                  // vm
      vm->GetIsolateSnapshot(),  // isolate snapshot
      vm->GetSharedSnapshot(),   // shared snapshot
      std::move(task_runners),   // task runners
      nullptr,                   // window
      {},                        // snapshot delegate
      {},                        // resource context
      nullptr,                   // unref qeueue
      "main.dart",               // advisory uri
      "main"                     // advisory entrypoint
  );
  auto root_isolate = weak_isolate.lock();
  ASSERT_TRUE(root_isolate);
  ASSERT_EQ(root_isolate->GetPhase(), DartIsolate::Phase::LibrariesSetup);
  ASSERT_TRUE(root_isolate->Shutdown());
}

TEST_F(DartIsolateTest, IsolateShutdownCallbackIsInIsolateScope) {
  Settings settings = {};
  settings.task_observer_add = [](intptr_t, fml::closure) {};
  settings.task_observer_remove = [](intptr_t) {};
  auto vm = DartVM::ForProcess(settings);
  ASSERT_TRUE(vm);
  TaskRunners task_runners(CURRENT_TEST_NAME,       //
                           GetCurrentTaskRunner(),  //
                           GetCurrentTaskRunner(),  //
                           GetCurrentTaskRunner(),  //
                           GetCurrentTaskRunner()   //
  );
  auto weak_isolate = DartIsolate::CreateRootIsolate(
      vm.get(),                  // vm
      vm->GetIsolateSnapshot(),  // isolate snapshot
      vm->GetSharedSnapshot(),   // shared snapshot
      std::move(task_runners),   // task runners
      nullptr,                   // window
      {},                        // snapshot delegate
      {},                        // resource context
      nullptr,                   // unref qeueue
      "main.dart",               // advisory uri
      "main"                     // advisory entrypoint
  );
  auto root_isolate = weak_isolate.lock();
  ASSERT_TRUE(root_isolate);
  ASSERT_EQ(root_isolate->GetPhase(), DartIsolate::Phase::LibrariesSetup);
  size_t destruction_callback_count = 0;
  root_isolate->AddIsolateShutdownCallback([&destruction_callback_count]() {
    ASSERT_NE(Dart_CurrentIsolate(), nullptr);
    destruction_callback_count++;
  });
  ASSERT_TRUE(root_isolate->Shutdown());
  ASSERT_EQ(destruction_callback_count, 1u);
}

}  // namespace blink
