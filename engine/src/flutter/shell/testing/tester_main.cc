// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// FLUTTER_NOLINT

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
#include "third_party/dart/runtime/include/dart_api.h"

#if defined(OS_POSIX)
#include <signal.h>
#endif  // defined(OS_POSIX)

namespace flutter {

// Checks whether the engine's main Dart isolate has no pending work.  If so,
// then exit the given message loop.
class ScriptCompletionTaskObserver {
 public:
  ScriptCompletionTaskObserver(Shell& shell,
                               fml::RefPtr<fml::TaskRunner> main_task_runner,
                               bool run_forever)
      : shell_(shell),
        main_task_runner_(std::move(main_task_runner)),
        run_forever_(run_forever) {}

  int GetExitCodeForLastError() const {
    return static_cast<int>(last_error_.value_or(DartErrorCode::NoError));
  }

  void DidProcessTask() {
    last_error_ = shell_.GetUIIsolateLastError();
    if (shell_.EngineHasLivePorts()) {
      // The UI isolate still has live ports and is running. Nothing to do
      // just yet.
      return;
    }

    if (run_forever_) {
      // We need this script to run forever. We have already recorded the last
      // error. Keep going.
      return;
    }

    if (!has_terminated) {
      // Only try to terminate the loop once.
      has_terminated = true;
      fml::TaskRunner::RunNowOrPostTask(main_task_runner_, []() {
        fml::MessageLoop::GetCurrent().Terminate();
      });
    }
  }

 private:
  Shell& shell_;
  fml::RefPtr<fml::TaskRunner> main_task_runner_;
  bool run_forever_ = false;
  std::optional<DartErrorCode> last_error_;
  bool has_terminated = false;

  FML_DISALLOW_COPY_AND_ASSIGN(ScriptCompletionTaskObserver);
};

// Processes spawned via dart:io inherit their signal handling from the parent
// process. As part of spawning, the spawner blocks signals temporarily, so we
// need to explicitly unblock the signals we care about in the new process. In
// particular, we need to unblock SIGPROF for CPU profiling to work on the
// mutator thread in the main isolate in this process (threads spawned by the VM
// know about this limitation and automatically have this signal unblocked).
static void UnblockSIGPROF() {
#if defined(OS_POSIX)
  sigset_t set;
  sigemptyset(&set);
  sigaddset(&set, SIGPROF);
  pthread_sigmask(SIG_UNBLOCK, &set, NULL);
#endif  // defined(OS_POSIX)
}

int RunTester(const flutter::Settings& settings,
              bool run_forever,
              bool multithreaded) {
  const auto thread_label = "io.flutter.test.";

  // Necessary if we want to use the CPU profiler on the main isolate's mutator
  // thread.
  //
  // OSX WARNING: avoid spawning additional threads before this call due to a
  // kernel bug that may enable SIGPROF on an unintended thread in the process.
  UnblockSIGPROF();

  fml::MessageLoop::EnsureInitializedForCurrentThread();

  auto current_task_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();

  std::unique_ptr<ThreadHost> threadhost;
  fml::RefPtr<fml::TaskRunner> platform_task_runner;
  fml::RefPtr<fml::TaskRunner> raster_task_runner;
  fml::RefPtr<fml::TaskRunner> ui_task_runner;
  fml::RefPtr<fml::TaskRunner> io_task_runner;

  if (multithreaded) {
    threadhost = std::make_unique<ThreadHost>(
        thread_label, ThreadHost::Type::Platform | ThreadHost::Type::IO |
                          ThreadHost::Type::UI | ThreadHost::Type::GPU);
    platform_task_runner = current_task_runner;
    raster_task_runner = threadhost->raster_thread->GetTaskRunner();
    ui_task_runner = threadhost->ui_thread->GetTaskRunner();
    io_task_runner = threadhost->io_thread->GetTaskRunner();
  } else {
    platform_task_runner = raster_task_runner = ui_task_runner =
        io_task_runner = current_task_runner;
  }

  const flutter::TaskRunners task_runners(thread_label,  // dart thread label
                                          platform_task_runner,  // platform
                                          raster_task_runner,    // raster
                                          ui_task_runner,        // ui
                                          io_task_runner         // io
  );

  Shell::CreateCallback<PlatformView> on_create_platform_view =
      [](Shell& shell) {
        return std::make_unique<PlatformView>(shell, shell.GetTaskRunners());
      };

  Shell::CreateCallback<Rasterizer> on_create_rasterizer = [](Shell& shell) {
    return std::make_unique<Rasterizer>(shell);
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

  if (settings.application_kernel_asset.empty()) {
    FML_LOG(ERROR) << "Dart kernel file not specified.";
    return EXIT_FAILURE;
  }

  // Initialize default testing locales. There is no platform to
  // pass locales on the tester, so to retain expected locale behavior,
  // we emulate it in here by passing in 'en_US' and 'zh_CN' as test locales.
  const char* locale_json =
      "{\"method\":\"setLocale\",\"args\":[\"en\",\"US\",\"\",\"\",\"zh\","
      "\"CN\",\"\",\"\"]}";
  std::vector<uint8_t> locale_bytes(locale_json,
                                    locale_json + std::strlen(locale_json));
  fml::RefPtr<flutter::PlatformMessageResponse> response;
  shell->GetPlatformView()->DispatchPlatformMessage(
      fml::MakeRefCounted<flutter::PlatformMessage>("flutter/localization",
                                                    locale_bytes, response));

  std::initializer_list<fml::FileMapping::Protection> protection = {
      fml::FileMapping::Protection::kRead};
  auto main_dart_file_mapping = std::make_unique<fml::FileMapping>(
      fml::OpenFile(
          fml::paths::AbsolutePath(settings.application_kernel_asset).c_str(),
          false, fml::FilePermission::kRead),
      protection);

  auto isolate_configuration =
      IsolateConfiguration::CreateForKernel(std::move(main_dart_file_mapping));

  if (!isolate_configuration) {
    FML_LOG(ERROR) << "Could create isolate configuration.";
    return EXIT_FAILURE;
  }

  auto asset_manager = std::make_shared<flutter::AssetManager>();
  asset_manager->PushBack(std::make_unique<flutter::DirectoryAssetBundle>(
      fml::Duplicate(settings.assets_dir)));
  asset_manager->PushBack(
      std::make_unique<flutter::DirectoryAssetBundle>(fml::OpenDirectory(
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

  fml::AutoResetWaitableEvent latch;
  auto task_observer_add = [&completion_observer]() {
    fml::MessageLoop::GetCurrent().AddTaskObserver(
        reinterpret_cast<intptr_t>(&completion_observer),
        [&completion_observer]() { completion_observer.DidProcessTask(); });
  };

  auto task_observer_remove = [&completion_observer, &latch]() {
    fml::MessageLoop::GetCurrent().RemoveTaskObserver(
        reinterpret_cast<intptr_t>(&completion_observer));
    latch.Signal();
  };

  shell->RunEngine(std::move(run_configuration),
                   [&engine_did_run, &ui_task_runner,
                    &task_observer_add](Engine::RunStatus run_status) mutable {
                     if (run_status != flutter::Engine::RunStatus::Failure) {
                       engine_did_run = true;
                       // Now that our engine is initialized we can install the
                       // ScriptCompletionTaskObserver
                       fml::TaskRunner::RunNowOrPostTask(ui_task_runner,
                                                         task_observer_add);
                     }
                   });

  flutter::ViewportMetrics metrics{};
  metrics.device_pixel_ratio = 3.0;
  metrics.physical_width = 2400.0;   // 800 at 3x resolution.
  metrics.physical_height = 1800.0;  // 600 at 3x resolution.
  shell->GetPlatformView()->SetViewportMetrics(metrics);

  // Run the message loop and wait for the script to do its thing.
  fml::MessageLoop::GetCurrent().Run();

  // Cleanup the completion observer synchronously as it is living on the
  // stack.
  fml::TaskRunner::RunNowOrPostTask(ui_task_runner, task_observer_remove);
  latch.Wait();

  if (!engine_did_run) {
    // If the engine itself didn't have a chance to run, there is no point in
    // asking it if there was an error. Signal a failure unconditionally.
    return EXIT_FAILURE;
  }

  return completion_observer.GetExitCodeForLastError();
}

}  // namespace flutter

int main(int argc, char* argv[]) {
  dart::bin::SetExecutableName(argv[0]);
  dart::bin::SetExecutableArguments(argc - 1, argv);

  auto command_line = fml::CommandLineFromArgcArgv(argc, argv);

  if (command_line.HasOption(flutter::FlagForSwitch(flutter::Switch::Help))) {
    flutter::PrintUsage("flutter_tester");
    return EXIT_SUCCESS;
  }

  auto settings = flutter::SettingsFromCommandLine(command_line);
  if (command_line.positional_args().size() > 0) {
    // The tester may not use the switch for the main dart file path. Specifying
    // it as a positional argument instead.
    settings.application_kernel_asset = command_line.positional_args()[0];
  }

  if (settings.application_kernel_asset.size() == 0) {
    FML_LOG(ERROR) << "Dart kernel file not specified.";
    return EXIT_FAILURE;
  }

  if (settings.icu_data_path.size() == 0) {
    settings.icu_data_path = "icudtl.dat";
  }

  // The tools that read logs get confused if there is a log tag specified.
  settings.log_tag = "";

  settings.task_observer_add = [](intptr_t key, fml::closure callback) {
    fml::MessageLoop::GetCurrent().AddTaskObserver(key, std::move(callback));
  };

  settings.task_observer_remove = [](intptr_t key) {
    fml::MessageLoop::GetCurrent().RemoveTaskObserver(key);
  };

  settings.unhandled_exception_callback = [](const std::string& error,
                                             const std::string& stack_trace) {
    FML_LOG(ERROR) << "Unhandled exception" << std::endl
                   << "Exception: " << error << std::endl
                   << "Stack trace: " << stack_trace;
    ::exit(1);
    return true;
  };

  return flutter::RunTester(settings,
                            command_line.HasOption(flutter::FlagForSwitch(
                                flutter::Switch::RunForever)),
                            command_line.HasOption(flutter::FlagForSwitch(
                                flutter::Switch::ForceMultithreading)));
}
