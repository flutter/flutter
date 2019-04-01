// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/make_copyable.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/paths.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/thread.h"
#include "flutter/runtime/dart_isolate.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/runtime/dart_vm_lifecycle.h"
#include "flutter/runtime/runtime_test.h"
#include "flutter/testing/testing.h"
#include "flutter/testing/thread_test.h"
#include "third_party/tonic/scopes/dart_isolate_scope.h"

#define CURRENT_TEST_NAME                                           \
  std::string {                                                     \
    ::testing::UnitTest::GetInstance()->current_test_info()->name() \
  }

namespace blink {
namespace testing {

using DartIsolateTest = RuntimeTest;

TEST_F(DartIsolateTest, RootIsolateCreationAndShutdown) {
  auto settings = CreateSettingsForFixture();
  auto vm_ref = DartVMRef::Create(settings);
  ASSERT_TRUE(vm_ref);
  auto vm_data = vm_ref.GetVMData();
  ASSERT_TRUE(vm_data);
  TaskRunners task_runners(CURRENT_TEST_NAME,       //
                           GetCurrentTaskRunner(),  //
                           GetCurrentTaskRunner(),  //
                           GetCurrentTaskRunner(),  //
                           GetCurrentTaskRunner()   //
  );
  auto weak_isolate = DartIsolate::CreateRootIsolate(
      vm_data->GetSettings(),         // settings
      vm_data->GetIsolateSnapshot(),  // isolate snapshot
      vm_data->GetSharedSnapshot(),   // shared snapshot
      std::move(task_runners),        // task runners
      nullptr,                        // window
      {},                             // snapshot delegate
      {},                             // io manager
      "main.dart",                    // advisory uri
      "main"                          // advisory entrypoint
  );
  auto root_isolate = weak_isolate.lock();
  ASSERT_TRUE(root_isolate);
  ASSERT_EQ(root_isolate->GetPhase(), DartIsolate::Phase::LibrariesSetup);
  ASSERT_TRUE(root_isolate->Shutdown());
}

TEST_F(DartIsolateTest, IsolateShutdownCallbackIsInIsolateScope) {
  auto settings = CreateSettingsForFixture();
  auto vm_ref = DartVMRef::Create(settings);
  ASSERT_TRUE(vm_ref);
  auto vm_data = vm_ref.GetVMData();
  ASSERT_TRUE(vm_data);
  TaskRunners task_runners(CURRENT_TEST_NAME,       //
                           GetCurrentTaskRunner(),  //
                           GetCurrentTaskRunner(),  //
                           GetCurrentTaskRunner(),  //
                           GetCurrentTaskRunner()   //
  );
  auto weak_isolate = DartIsolate::CreateRootIsolate(
      vm_data->GetSettings(),         // settings
      vm_data->GetIsolateSnapshot(),  // isolate snapshot
      vm_data->GetSharedSnapshot(),   // shared snapshot
      std::move(task_runners),        // task runners
      nullptr,                        // window
      {},                             // snapshot delegate
      {},                             // io manager
      "main.dart",                    // advisory uri
      "main"                          // advisory entrypoint
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

class AutoIsolateShutdown {
 public:
  AutoIsolateShutdown() = default;

  AutoIsolateShutdown(std::shared_ptr<blink::DartIsolate> isolate,
                      fml::RefPtr<fml::TaskRunner> runner)
      : isolate_(std::move(isolate)), runner_(std::move(runner)) {}

  ~AutoIsolateShutdown() {
    if (!IsValid()) {
      return;
    }
    fml::AutoResetWaitableEvent latch;
    fml::TaskRunner::RunNowOrPostTask(runner_, [isolate = isolate_, &latch]() {
      FML_LOG(INFO) << "Shutting down isolate.";
      if (!isolate->Shutdown()) {
        FML_LOG(ERROR) << "Could not shutdown isolate.";
        FML_CHECK(false);
      }
      latch.Signal();
    });
    latch.Wait();
  }

  bool IsValid() const { return isolate_ != nullptr && runner_; }

  FML_WARN_UNUSED_RESULT
  bool RunInIsolateScope(std::function<bool(void)> closure) {
    if (!IsValid()) {
      return false;
    }

    bool result = false;
    fml::AutoResetWaitableEvent latch;
    fml::TaskRunner::RunNowOrPostTask(
        runner_, [this, &result, &latch, closure]() {
          tonic::DartIsolateScope scope(isolate_->isolate());
          tonic::DartApiScope api_scope;
          if (closure) {
            result = closure();
          }
          latch.Signal();
        });
    latch.Wait();
    return true;
  }

  blink::DartIsolate* get() {
    FML_CHECK(isolate_);
    return isolate_.get();
  }

 private:
  std::shared_ptr<blink::DartIsolate> isolate_;
  fml::RefPtr<fml::TaskRunner> runner_;

  FML_DISALLOW_COPY_AND_ASSIGN(AutoIsolateShutdown);
};

static void RunDartCodeInIsolate(std::unique_ptr<AutoIsolateShutdown>& result,
                                 const Settings& settings,
                                 fml::RefPtr<fml::TaskRunner> task_runner,
                                 std::string entrypoint) {
  FML_CHECK(task_runner->RunsTasksOnCurrentThread());
  auto vm_ref = DartVMRef::Create(settings);

  if (!vm_ref) {
    return;
  }

  TaskRunners task_runners(CURRENT_TEST_NAME,  //
                           task_runner,        //
                           task_runner,        //
                           task_runner,        //
                           task_runner         //
  );

  auto vm_data = vm_ref.GetVMData();

  if (!vm_data) {
    return;
  }

  auto weak_isolate = DartIsolate::CreateRootIsolate(
      vm_data->GetSettings(),         // settings
      vm_data->GetIsolateSnapshot(),  // isolate snapshot
      vm_data->GetSharedSnapshot(),   // shared snapshot
      std::move(task_runners),        // task runners
      nullptr,                        // window
      {},                             // snapshot delegate
      {},                             // io manager
      "main.dart",                    // advisory uri
      "main"                          // advisory entrypoint
  );

  auto root_isolate =
      std::make_unique<AutoIsolateShutdown>(weak_isolate.lock(), task_runner);

  if (!root_isolate->IsValid()) {
    FML_LOG(ERROR) << "Could not create isolate.";
    return;
  }

  if (root_isolate->get()->GetPhase() != DartIsolate::Phase::LibrariesSetup) {
    FML_LOG(ERROR) << "Created isolate is in unexpected phase.";
    return;
  }

  if (!DartVM::IsRunningPrecompiledCode()) {
    auto kernel_file_path = fml::paths::JoinPaths(
        {::testing::GetFixturesPath(), "kernel_blob.bin"});

    if (!fml::IsFile(kernel_file_path)) {
      FML_LOG(ERROR) << "Could not locate kernel file.";
      return;
    }

    auto kernel_file = fml::OpenFile(kernel_file_path.c_str(), false,
                                     fml::FilePermission::kRead);

    if (!kernel_file.is_valid()) {
      FML_LOG(ERROR) << "Kernel file descriptor was invalid.";
      return;
    }

    auto kernel_mapping = std::make_unique<fml::FileMapping>(kernel_file);

    if (kernel_mapping->GetMapping() == nullptr) {
      FML_LOG(ERROR) << "Could not setup kernel mapping.";
      return;
    }

    if (!root_isolate->get()->PrepareForRunningFromKernel(
            std::move(kernel_mapping))) {
      FML_LOG(ERROR)
          << "Could not prepare to run the isolate from the kernel file.";
      return;
    }
  } else {
    if (!root_isolate->get()->PrepareForRunningFromPrecompiledCode()) {
      FML_LOG(ERROR)
          << "Could not prepare to run the isolate from precompiled code.";
      return;
    }
  }

  if (root_isolate->get()->GetPhase() != DartIsolate::Phase::Ready) {
    FML_LOG(ERROR) << "Isolate is in unexpected phase.";
    return;
  }

  if (!root_isolate->get()->Run(entrypoint,
                                settings.root_isolate_create_callback)) {
    FML_LOG(ERROR) << "Could not run the method \"" << entrypoint
                   << "\" in the isolate.";
    return;
  }

  root_isolate->get()->AddIsolateShutdownCallback(
      settings.root_isolate_shutdown_callback);

  result = std::move(root_isolate);
}

static std::unique_ptr<AutoIsolateShutdown> RunDartCodeInIsolate(
    const Settings& settings,
    fml::RefPtr<fml::TaskRunner> task_runner,
    std::string entrypoint) {
  std::unique_ptr<AutoIsolateShutdown> result;
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      task_runner, fml::MakeCopyable([&]() mutable {
        RunDartCodeInIsolate(result, settings, task_runner, entrypoint);
        latch.Signal();
      }));
  latch.Wait();
  return result;
}

TEST_F(DartIsolateTest, IsolateCanLoadAndRunDartCode) {
  auto isolate = RunDartCodeInIsolate(CreateSettingsForFixture(),
                                      GetCurrentTaskRunner(), "main");
  ASSERT_TRUE(isolate);
  ASSERT_EQ(isolate->get()->GetPhase(), DartIsolate::Phase::Running);
}

TEST_F(DartIsolateTest, IsolateCannotLoadAndRunUnknownDartEntrypoint) {
  auto isolate = RunDartCodeInIsolate(
      CreateSettingsForFixture(), GetCurrentTaskRunner(), "thisShouldNotExist");
  ASSERT_FALSE(isolate);
}

TEST_F(DartIsolateTest, CanRunDartCodeCodeSynchronously) {
  auto isolate = RunDartCodeInIsolate(CreateSettingsForFixture(),
                                      GetCurrentTaskRunner(), "main");

  ASSERT_TRUE(isolate);
  ASSERT_EQ(isolate->get()->GetPhase(), DartIsolate::Phase::Running);
  ASSERT_TRUE(isolate->RunInIsolateScope([]() -> bool {
    if (tonic::LogIfError(::Dart_Invoke(Dart_RootLibrary(),
                                        tonic::ToDart("sayHi"), 0, nullptr))) {
      return false;
    }
    return true;
  }));
}

TEST_F(DartIsolateTest, CanRegisterNativeCallback) {
  fml::AutoResetWaitableEvent latch;
  AddNativeCallback("NotifyNative",
                    CREATE_NATIVE_ENTRY(([&latch](Dart_NativeArguments args) {
                      FML_LOG(ERROR) << "Hello from Dart!";
                      latch.Signal();
                    })));
  auto isolate =
      RunDartCodeInIsolate(CreateSettingsForFixture(), GetThreadTaskRunner(),
                           "canRegisterNativeCallback");
  ASSERT_TRUE(isolate);
  ASSERT_EQ(isolate->get()->GetPhase(), DartIsolate::Phase::Running);
  latch.Wait();
}

}  // namespace testing
}  // namespace blink
