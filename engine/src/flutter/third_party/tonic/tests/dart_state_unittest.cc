// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/common/task_runners.h"
#include "flutter/runtime/dart_vm_lifecycle.h"
#include "flutter/runtime/isolate_configuration.h"
#include "flutter/testing/fixture_test.h"

namespace flutter {
namespace testing {

using DartState = FixtureTest;

TEST_F(DartState, IsShuttingDown) {
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
  auto settings = CreateSettingsForFixture();
  auto vm_ref = DartVMRef::Create(settings);
  ASSERT_TRUE(vm_ref);
  auto vm_data = vm_ref.GetVMData();
  ASSERT_TRUE(vm_data);
  TaskRunners task_runners(GetCurrentTestName(),    //
                           GetCurrentTaskRunner(),  //
                           GetCurrentTaskRunner(),  //
                           GetCurrentTaskRunner(),  //
                           GetCurrentTaskRunner()   //
  );
  auto isolate_configuration =
      IsolateConfiguration::InferFromSettings(settings);
  auto weak_isolate = DartIsolate::CreateRunningRootIsolate(
      vm_data->GetSettings(),              // settings
      vm_data->GetIsolateSnapshot(),       // isolate snapshot
      std::move(task_runners),             // task runners
      nullptr,                             // window
      {},                                  // snapshot delegate
      {},                                  // hint freed delegate
      {},                                  // io manager
      {},                                  // unref queue
      {},                                  // image decoder
      "main.dart",                         // advisory uri
      "main",                              // advisory entrypoint
      DartIsolate::Flags{},                // flags
      settings.isolate_create_callback,    // isolate create callback
      settings.isolate_shutdown_callback,  // isolate shutdown callback
      "main",                              // dart entrypoint
      std::nullopt,                        // dart entrypoint library
      std::move(isolate_configuration)     // isolate configuration
  );
  auto root_isolate = weak_isolate.lock();
  ASSERT_TRUE(root_isolate);

  tonic::DartState* dart_state = root_isolate.get();
  ASSERT_FALSE(dart_state->IsShuttingDown());

  ASSERT_TRUE(root_isolate->Shutdown());

  ASSERT_TRUE(dart_state->IsShuttingDown());
}

}  // namespace testing
}  // namespace flutter
