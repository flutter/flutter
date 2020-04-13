// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/dart_isolate_runner.h"

namespace flutter {
namespace testing {
AutoIsolateShutdown::AutoIsolateShutdown(std::shared_ptr<DartIsolate> isolate,
                                         fml::RefPtr<fml::TaskRunner> runner)
    : isolate_(std::move(isolate)), runner_(std::move(runner)) {}

AutoIsolateShutdown::~AutoIsolateShutdown() {
  if (!IsValid()) {
    return;
  }
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      runner_, [isolate = std::move(isolate_), &latch]() {
        if (!isolate->Shutdown()) {
          FML_LOG(ERROR) << "Could not shutdown isolate.";
          FML_CHECK(false);
        }
        latch.Signal();
      });
  latch.Wait();
}

[[nodiscard]] bool AutoIsolateShutdown::RunInIsolateScope(
    std::function<bool(void)> closure) {
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

void RunDartCodeInIsolate(DartVMRef& vm_ref,
                          std::unique_ptr<AutoIsolateShutdown>& result,
                          const Settings& settings,
                          const TaskRunners& task_runners,
                          std::string entrypoint,
                          const std::vector<std::string>& args,
                          const std::string& fixtures_path,
                          fml::WeakPtr<IOManager> io_manager) {
  FML_CHECK(task_runners.GetUITaskRunner()->RunsTasksOnCurrentThread());

  if (!vm_ref) {
    return;
  }

  auto vm_data = vm_ref.GetVMData();

  if (!vm_data) {
    return;
  }

  auto weak_isolate = DartIsolate::CreateRootIsolate(
      vm_data->GetSettings(),             // settings
      vm_data->GetIsolateSnapshot(),      // isolate snapshot
      std::move(task_runners),            // task runners
      nullptr,                            // window
      {},                                 // snapshot delegate
      io_manager,                         // io manager
      {},                                 // unref queue
      {},                                 // image decoder
      "main.dart",                        // advisory uri
      "main",                             // advisory entrypoint
      nullptr,                            // flags
      settings.isolate_create_callback,   // isolate create callback
      settings.isolate_shutdown_callback  // isolate shutdown callback
  );

  auto root_isolate = std::make_unique<AutoIsolateShutdown>(
      weak_isolate.lock(), task_runners.GetUITaskRunner());

  if (!root_isolate->IsValid()) {
    FML_LOG(ERROR) << "Could not create isolate.";
    return;
  }

  if (root_isolate->get()->GetPhase() != DartIsolate::Phase::LibrariesSetup) {
    FML_LOG(ERROR) << "Created isolate is in unexpected phase.";
    return;
  }

  if (!DartVM::IsRunningPrecompiledCode()) {
    auto kernel_file_path =
        fml::paths::JoinPaths({fixtures_path, "kernel_blob.bin"});

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

  if (!root_isolate->get()->Run(entrypoint, args,
                                settings.root_isolate_create_callback)) {
    FML_LOG(ERROR) << "Could not run the method \"" << entrypoint
                   << "\" in the isolate.";
    return;
  }

  root_isolate->get()->AddIsolateShutdownCallback(
      settings.root_isolate_shutdown_callback);

  result = std::move(root_isolate);
}

std::unique_ptr<AutoIsolateShutdown> RunDartCodeInIsolate(
    DartVMRef& vm_ref,
    const Settings& settings,
    const TaskRunners& task_runners,
    std::string entrypoint,
    const std::vector<std::string>& args,
    const std::string& fixtures_path,
    fml::WeakPtr<IOManager> io_manager) {
  std::unique_ptr<AutoIsolateShutdown> result;
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      task_runners.GetUITaskRunner(), fml::MakeCopyable([&]() mutable {
        RunDartCodeInIsolate(vm_ref, result, settings, task_runners, entrypoint,
                             args, fixtures_path, io_manager);
        latch.Signal();
      }));
  latch.Wait();
  return result;
}

}  // namespace testing
}  // namespace flutter
