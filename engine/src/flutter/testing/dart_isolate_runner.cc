// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/dart_isolate_runner.h"

#include "flutter/runtime/isolate_configuration.h"

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

std::unique_ptr<AutoIsolateShutdown> RunDartCodeInIsolateOnUITaskRunner(
    DartVMRef& vm_ref,
    const Settings& p_settings,
    const TaskRunners& task_runners,
    std::string entrypoint,
    const std::vector<std::string>& args,
    const std::string& fixtures_path,
    fml::WeakPtr<IOManager> io_manager) {
  FML_CHECK(task_runners.GetUITaskRunner()->RunsTasksOnCurrentThread());

  if (!vm_ref) {
    return nullptr;
  }

  auto vm_data = vm_ref.GetVMData();

  if (!vm_data) {
    return nullptr;
  }

  auto settings = p_settings;

  settings.dart_entrypoint_args = args;

  if (!DartVM::IsRunningPrecompiledCode()) {
    auto kernel_file_path =
        fml::paths::JoinPaths({fixtures_path, "kernel_blob.bin"});

    if (!fml::IsFile(kernel_file_path)) {
      FML_LOG(ERROR) << "Could not locate kernel file.";
      return nullptr;
    }

    auto kernel_file = fml::OpenFile(kernel_file_path.c_str(), false,
                                     fml::FilePermission::kRead);

    if (!kernel_file.is_valid()) {
      FML_LOG(ERROR) << "Kernel file descriptor was invalid.";
      return nullptr;
    }

    auto kernel_mapping = std::make_unique<fml::FileMapping>(kernel_file);

    if (kernel_mapping->GetMapping() == nullptr) {
      FML_LOG(ERROR) << "Could not setup kernel mapping.";
      return nullptr;
    }

    settings.application_kernels = fml::MakeCopyable(
        [kernel_mapping = std::move(kernel_mapping)]() mutable -> Mappings {
          Mappings mappings;
          mappings.emplace_back(std::move(kernel_mapping));
          return mappings;
        });
  }

  auto isolate_configuration =
      IsolateConfiguration::InferFromSettings(settings);

  auto isolate =
      DartIsolate::CreateRunningRootIsolate(
          settings,                            // settings
          vm_data->GetIsolateSnapshot(),       // isolate snapshot
          std::move(task_runners),             // task runners
          nullptr,                             // window
          {},                                  // snapshot delegate
          {},                                  // hint freed delegate
          io_manager,                          // io manager
          {},                                  // unref queue
          {},                                  // image decoder
          "main.dart",                         // advisory uri
          entrypoint.c_str(),                  // advisory entrypoint
          DartIsolate::Flags{},                // flags
          settings.isolate_create_callback,    // isolate create callback
          settings.isolate_shutdown_callback,  // isolate shutdown callback
          entrypoint,                          // entrypoint
          std::nullopt,                        // library
          std::move(isolate_configuration)     // isolate configuration
          )
          .lock();

  if (!isolate) {
    FML_LOG(ERROR) << "Could not create running isolate.";
    return nullptr;
  }

  return std::make_unique<AutoIsolateShutdown>(isolate,
                                               task_runners.GetUITaskRunner());
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
        result = RunDartCodeInIsolateOnUITaskRunner(
            vm_ref, settings, task_runners, entrypoint, args, fixtures_path,
            io_manager);
        latch.Signal();
      }));
  latch.Wait();
  return result;
}

}  // namespace testing
}  // namespace flutter
