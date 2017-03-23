// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/at_exit.h"
#include "base/basictypes.h"
#include "base/bind.h"
#include "base/message_loop/message_loop.h"
#include "dart/runtime/bin/embedded_dart_io.h"
#include "flutter/common/threads.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/switches.h"
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

}  // namespace

int main(int argc, char* argv[]) {
  dart::bin::SetExecutableName(argv[0]);
  dart::bin::SetExecutableArguments(argc - 1, argv);

  base::AtExitManager exit_manager;

  auto command_line = ftl::CommandLineFromArgcArgv(argc, argv);

  if (command_line.HasOption(shell::FlagForSwitch(shell::Switch::Help))) {
    shell::PrintUsage("sky_shell");
    return EXIT_SUCCESS;
  }

  bool run_forever =
      command_line.HasOption(shell::FlagForSwitch(shell::Switch::RunForever));
  RunNonInteractive(std::move(command_line), run_forever);
  return EXIT_SUCCESS;
}
