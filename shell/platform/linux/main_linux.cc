// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/at_exit.h"
#include "base/basictypes.h"
#include "base/bind.h"
#include "base/message_loop/message_loop.h"
#include "dart/runtime/bin/embedded_dart_io.h"
#include "flutter/common/threads.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/switches.h"
#include "flutter/shell/gpu/gpu_surface_gl.h"
#include "flutter/shell/platform/linux/message_pump_glfw.h"
#include "flutter/shell/platform/linux/platform_view_glfw.h"
#include "flutter/shell/testing/test_runner.h"
#include "flutter/shell/testing/testing.h"
#include "flutter/sky/engine/public/web/Sky.h"
#include "lib/ftl/command_line.h"
#include "lib/tonic/dart_microtask_queue.h"

namespace {

// Exit codes used by the Dart command line tool.
const int kApiErrorExitCode = 253;
const int kCompilationErrorExitCode = 254;
const int kErrorExitCode = 255;

// Checks whether the engine's main Dart isolate has no pending work.  If so,
// then exit the given message loop.
class ScriptCompletionTaskObserver : public base::MessageLoop::TaskObserver {
 public:
  ScriptCompletionTaskObserver(base::MessageLoop& main_message_loop)
      : main_message_loop_(main_message_loop),
        prev_live_(false),
        last_error_(tonic::kNoError) {}

  void WillProcessTask(const base::PendingTask& pending_task) override {}

  void DidProcessTask(const base::PendingTask& pending_task) override {
    shell::TestRunner& test_runner = shell::TestRunner::Shared();
    shell::Engine& engine = test_runner.platform_view().engine();

    if (engine.GetLoadScriptError() != tonic::kNoError) {
      last_error_ = engine.GetLoadScriptError();
      main_message_loop_.PostTask(FROM_HERE,
                                  main_message_loop_.QuitWhenIdleClosure());
      return;
    }

    bool live = engine.UIIsolateHasLivePorts();
    if (prev_live_ && !live) {
      last_error_ = engine.GetUIIsolateLastError();
      main_message_loop_.PostTask(FROM_HERE,
                                  main_message_loop_.QuitWhenIdleClosure());
    }
    prev_live_ = live;
  }

  tonic::DartErrorHandleType last_error() { return last_error_; }

 private:
  base::MessageLoop& main_message_loop_;
  bool prev_live_;
  tonic::DartErrorHandleType last_error_;
};

int ConvertErrorTypeToExitCode(tonic::DartErrorHandleType error) {
  switch (error) {
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

void RunNonInteractive(ftl::CommandLine initial_command_line,
                       bool run_forever) {
  base::MessageLoop message_loop;

  shell::Shell::InitStandalone(initial_command_line);

  // Note that this task observer must be added after the observer that drains
  // the microtask queue.
  ScriptCompletionTaskObserver task_observer(message_loop);
  if (!run_forever) {
    blink::Threads::UI()->PostTask([&task_observer] {
      base::MessageLoop::current()->AddTaskObserver(&task_observer);
    });
  }

  if (!shell::InitForTesting(std::move(initial_command_line))) {
    shell::PrintUsage("sky_shell");
    exit(1);
  }

  message_loop.Run();

  shell::TestRunner& test_runner = shell::TestRunner::Shared();
  tonic::DartErrorHandleType error =
      test_runner.platform_view().engine().GetLoadScriptError();
  if (error == tonic::kNoError)
    error = task_observer.last_error();
  if (error == tonic::kNoError)
    error = tonic::DartMicrotaskQueue::GetLastError();

  // The script has completed and the engine may not be in a clean state,
  // so just stop the process.
  exit(ConvertErrorTypeToExitCode(error));
}

static bool IsDartFile(const std::string& path) {
  std::string dart_extension = ".dart";
  return path.rfind(dart_extension) == (path.size() - dart_extension.size());
}

int RunInteractive(ftl::CommandLine initial_command_line) {
  base::MessageLoop message_loop(shell::MessagePumpGLFW::Create());

  shell::Shell::InitStandalone(std::move(initial_command_line));

  const auto& command_line = shell::Shell::Shared().GetCommandLine();

  std::string target = command_line.GetOptionValueWithDefault(
      shell::FlagForSwitch(shell::Switch::FLX), "");

  if (target.empty()) {
    // Alternatively, use the first positional argument.
    auto args = command_line.positional_args();
    if (args.empty())
      return 1;
    target = args[0];
  }

  if (target.empty())
    return 1;

  std::unique_ptr<shell::PlatformViewGLFW> platform_view(
      new shell::PlatformViewGLFW());

  platform_view->NotifyCreated(
      std::make_unique<shell::GPUSurfaceGL>(platform_view.get()));

  blink::Threads::UI()->PostTask(
      [ engine = platform_view->engine().GetWeakPtr(), target ] {
        if (engine) {
          if (IsDartFile(target)) {
            engine->RunBundleAndSource(std::string(), target, std::string());

          } else {
            engine->RunBundle(target);
          }
        }
      });

  message_loop.Run();

  platform_view->NotifyDestroyed();

  return 0;
}

}  // namespace

int main(int argc, char* argv[]) {
  dart::bin::SetExecutableName(argv[0]);
  dart::bin::SetExecutableArguments(argc - 1, argv);

  base::AtExitManager exit_manager;

  auto command_line = ftl::CommandLineFromArgcArgv(argc, argv);

  if (command_line.HasOption(shell::FlagForSwitch(shell::Switch::Help))) {
    shell::PrintUsage("sky_shell");
    return 0;
  }

  if (command_line.HasOption(
          shell::FlagForSwitch(shell::Switch::NonInteractive))) {
    bool run_forever =
        command_line.HasOption(shell::FlagForSwitch(shell::Switch::RunForever));
    RunNonInteractive(std::move(command_line), run_forever);
    return 0;
  }

  return RunInteractive(std::move(command_line));
}
