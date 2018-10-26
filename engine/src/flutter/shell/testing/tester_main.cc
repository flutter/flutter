// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <cstdlib>

#include "flutter/assets/asset_manager.h"
#include "flutter/assets/directory_asset_bundle.h"
#include "flutter/fml/file.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/paths.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/task_runner.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/switches.h"
#include "flutter/shell/common/thread_host.h"
#include "third_party/dart/runtime/include/bin/dart_io_api.h"

namespace shell {

// Checks whether the engine's main Dart isolate has no pending work.  If so,
// then exit the given message loop.
class ScriptCompletionTaskObserver {
 public:
  ScriptCompletionTaskObserver(Shell& shell,
                               fml::RefPtr<fml::TaskRunner> main_task_runner,
                               bool run_forever)
      : engine_(shell.GetEngine()),
        main_task_runner_(std::move(main_task_runner)),
        run_forever_(run_forever) {}

  int GetExitCodeForLastError() const {
    // Exit codes used by the Dart command line tool.
    const int kApiErrorExitCode = 253;
    const int kCompilationErrorExitCode = 254;
    const int kErrorExitCode = 255;
    switch (last_error_) {
      case tonic::kCompilationErrorType:
        return kCompilationErrorExitCode;
      case tonic::kApiErrorType:
        return kApiErrorExitCode;
      case tonic::kUnknownErrorType:
        return kErrorExitCode;
      default:
        return 0;
    }
  }

  void DidProcessTask() {
    if (engine_) {
      last_error_ = engine_->GetUIIsolateLastError();
      if (engine_->UIIsolateHasLivePorts()) {
        // The UI isolate still has live ports and is running. Nothing to do
        // just yet.
        return;
      }
    }

    if (run_forever_) {
      // We need this script to run forever. We have already recorded the last
      // error. Keep going.
      return;
    }

    if (!has_terminated) {
      // Only try to terminate the loop once.
      has_terminated = true;
      main_task_runner_->PostTask(
          []() { fml::MessageLoop::GetCurrent().Terminate(); });
    }
  }

 private:
  fml::WeakPtr<Engine> engine_;
  fml::RefPtr<fml::TaskRunner> main_task_runner_;
  bool run_forever_ = false;
  tonic::DartErrorHandleType last_error_ = tonic::kUnknownErrorType;
  bool has_terminated = false;

  FML_DISALLOW_COPY_AND_ASSIGN(ScriptCompletionTaskObserver);
};

int RunTester(const blink::Settings& settings, bool run_forever) {
  const auto thread_label = "io.flutter.test";

  fml::MessageLoop::EnsureInitializedForCurrentThread();

  auto current_task_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();

  // Setup a single threaded test runner configuration.
  const blink::TaskRunners task_runners(thread_label,  // dart thread label
                                        current_task_runner,  // platform
                                        current_task_runner,  // gpu
                                        current_task_runner,  // ui
                                        current_task_runner   // io
  );

  Shell::CreateCallback<PlatformView> on_create_platform_view =
      [](Shell& shell) {
        return std::make_unique<PlatformView>(shell, shell.GetTaskRunners());
      };

  Shell::CreateCallback<Rasterizer> on_create_rasterizer = [](Shell& shell) {
    return std::make_unique<Rasterizer>(shell.GetTaskRunners());
  };

  auto shell = Shell::Create(task_runners,             //
                             settings,                 //
                             on_create_platform_view,  //
                             on_create_rasterizer      //
  );

  if (!shell || !shell->IsSetup()) {
    FML_LOG(ERROR) << "Could not setup the shell.";
    return EXIT_FAILURE;
  }

  if (settings.main_dart_file_path.empty()) {
    FML_LOG(ERROR) << "Main dart file not specified.";
    return EXIT_FAILURE;
  }

  std::initializer_list<fml::FileMapping::Protection> protection = {
      fml::FileMapping::Protection::kRead};
  auto main_dart_file_mapping = std::make_unique<fml::FileMapping>(
      fml::OpenFile(
          fml::paths::AbsolutePath(settings.main_dart_file_path).c_str(), false,
          fml::FilePermission::kRead),
      protection);

  auto isolate_configuration =
      IsolateConfiguration::CreateForKernel(std::move(main_dart_file_mapping));

  if (!isolate_configuration) {
    FML_LOG(ERROR) << "Could create isolate configuration.";
    return EXIT_FAILURE;
  }

  auto asset_manager = std::make_shared<blink::AssetManager>();
  asset_manager->PushBack(std::make_unique<blink::DirectoryAssetBundle>(
      fml::Duplicate(settings.assets_dir)));
  asset_manager->PushBack(
      std::make_unique<blink::DirectoryAssetBundle>(fml::OpenDirectory(
          settings.assets_path.c_str(), false, fml::FilePermission::kRead)));

  RunConfiguration run_configuration(std::move(isolate_configuration),
                                     std::move(asset_manager));

  // The script completion task observer that will be installed on the UI thread
  // that watched if the engine has any live ports.
  ScriptCompletionTaskObserver completion_observer(
      *shell,  // a valid shell
      fml::MessageLoop::GetCurrent()
          .GetTaskRunner(),  // the message loop to terminate
      run_forever            // should the exit be ignored
  );

  bool engine_did_run = false;

  fml::AutoResetWaitableEvent sync_run_latch;
  fml::TaskRunner::RunNowOrPostTask(
      shell->GetTaskRunners().GetUITaskRunner(),
      fml::MakeCopyable([&sync_run_latch, &completion_observer,
                         engine = shell->GetEngine(),
                         config = std::move(run_configuration),
                         &engine_did_run]() mutable {
        fml::MessageLoop::GetCurrent().AddTaskObserver(
            reinterpret_cast<intptr_t>(&completion_observer),
            [&completion_observer]() { completion_observer.DidProcessTask(); });
        if (engine->Run(std::move(config)) !=
            shell::Engine::RunStatus::Failure) {
          engine_did_run = true;

          blink::ViewportMetrics metrics;
          metrics.device_pixel_ratio = 3.0;
          metrics.physical_width = 2400;   // 800 at 3x resolution
          metrics.physical_height = 1800;  // 600 at 3x resolution
          engine->SetViewportMetrics(metrics);

        } else {
          FML_DLOG(ERROR) << "Could not launch the engine with configuration.";
        }
        sync_run_latch.Signal();
      }));
  sync_run_latch.Wait();

  // Run the message loop and wait for the script to do its thing.
  fml::MessageLoop::GetCurrent().Run();

  // Cleanup the completion observer synchronously as it is living on the
  // stack.
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      shell->GetTaskRunners().GetUITaskRunner(),
      [&latch, &completion_observer] {
        fml::MessageLoop::GetCurrent().RemoveTaskObserver(
            reinterpret_cast<intptr_t>(&completion_observer));
        latch.Signal();
      });
  latch.Wait();

  if (!engine_did_run) {
    // If the engine itself didn't have a chance to run, there is no point in
    // asking it if there was an error. Signal a failure unconditionally.
    return EXIT_FAILURE;
  }

  return completion_observer.GetExitCodeForLastError();
}

}  // namespace shell

int main(int argc, char* argv[]) {
  dart::bin::SetExecutableName(argv[0]);
  dart::bin::SetExecutableArguments(argc - 1, argv);

  auto command_line = fml::CommandLineFromArgcArgv(argc, argv);

  if (command_line.HasOption(shell::FlagForSwitch(shell::Switch::Help))) {
    shell::PrintUsage("flutter_tester");
    return EXIT_SUCCESS;
  }

  auto settings = shell::SettingsFromCommandLine(command_line);
  if (command_line.positional_args().size() > 0) {
    // The tester may not use the switch for the main dart file path. Specifying
    // it as a positional argument instead.
    settings.main_dart_file_path = command_line.positional_args()[0];
  }

  if (settings.main_dart_file_path.size() == 0) {
    FML_LOG(ERROR) << "Main dart file path not specified.";
    return EXIT_FAILURE;
  }

  settings.icu_data_path = "icudtl.dat";

  // The tools that read logs get confused if there is a log tag specified.
  settings.log_tag = "";

  settings.task_observer_add = [](intptr_t key, fml::closure callback) {
    fml::MessageLoop::GetCurrent().AddTaskObserver(key, std::move(callback));
  };

  settings.task_observer_remove = [](intptr_t key) {
    fml::MessageLoop::GetCurrent().RemoveTaskObserver(key);
  };

  return shell::RunTester(
      settings,
      command_line.HasOption(shell::FlagForSwitch(shell::Switch::RunForever)));
}
