// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

#include <iostream>

#include "flutter/fml/message_loop.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/switches.h"
#include "flutter/shell/platform/darwin/common/platform_mac.h"
#include "flutter/shell/platform/darwin/desktop/flutter_application.h"
#include "flutter/shell/testing/test_runner.h"
#include "flutter/shell/testing/testing.h"
#include "lib/fxl/command_line.h"
#include "lib/fxl/logging.h"
#include "lib/tonic/dart_microtask_queue.h"

// Exit codes used by the Dart command line tool.
const int kApiErrorExitCode = 253;
const int kCompilationErrorExitCode = 254;
const int kErrorExitCode = 255;

// Checks whether the engine's main Dart isolate has no pending work.  If so,
// then exit the given message loop.
class ScriptCompletionTaskObserver : public fml::TaskObserver {
 public:
  ScriptCompletionTaskObserver(fxl::RefPtr<fxl::TaskRunner> task_runner)
      : main_task_runner_(std::move(task_runner)),
        prev_live_(false),
        last_error_(tonic::kNoError) {}

  void DidProcessTask() override {
    shell::TestRunner& test_runner = shell::TestRunner::Shared();
    shell::Engine& engine = test_runner.platform_view().engine();

    if (engine.GetLoadScriptError() != tonic::kNoError) {
      last_error_ = engine.GetLoadScriptError();
      main_task_runner_->PostTask([]() { fml::MessageLoop::GetCurrent().Terminate(); });
      return;
    }

    bool live = engine.UIIsolateHasLivePorts();
    if (prev_live_ && !live) {
      last_error_ = engine.GetUIIsolateLastError();
      main_task_runner_->PostTask([]() { fml::MessageLoop::GetCurrent().Terminate(); });
    }
    prev_live_ = live;
  }

  tonic::DartErrorHandleType last_error() { return last_error_; }

 private:
  fxl::RefPtr<fxl::TaskRunner> main_task_runner_;
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

static fxl::CommandLine InitializedCommandLine() {
  std::vector<std::string> args_vector;

  for (NSString* arg in [NSProcessInfo processInfo].arguments) {
    args_vector.emplace_back(arg.UTF8String);
  }

  return fxl::CommandLineFromIterators(args_vector.begin(), args_vector.end());
}

int main(int argc, const char* argv[]) {
  [FlutterApplication sharedApplication];

  // Can't use shell::Shell::Shared().GetCommandLine() because it is initialized only
  // in shell::PlatformMacMain call below.
  auto command_line = InitializedCommandLine();

  std::string bundle_path = "";
  command_line.GetOptionValue(FlagForSwitch(shell::Switch::FlutterAssetsDir), &bundle_path);

  shell::PlatformMacMain("", "", bundle_path);

  // Print help.
  if (command_line.HasOption(shell::FlagForSwitch(shell::Switch::Help))) {
    shell::PrintUsage([NSProcessInfo processInfo].processName.UTF8String);
    return EXIT_SUCCESS;
  }

  // Decide between interactive and non-interactive modes.
  if (command_line.HasOption(shell::FlagForSwitch(shell::Switch::NonInteractive))) {
    if (!shell::InitForTesting(std::move(command_line)))
      return 1;

    // Note that this task observer must be added after the observer that drains
    // the microtask queue.
    ScriptCompletionTaskObserver task_observer(fml::MessageLoop::GetCurrent().GetTaskRunner());
    blink::Threads::UI()->PostTask(
        [&task_observer] { fml::MessageLoop::GetCurrent().AddTaskObserver(&task_observer); });

    fml::MessageLoop::GetCurrent().Run();

    shell::TestRunner& test_runner = shell::TestRunner::Shared();
    tonic::DartErrorHandleType error = test_runner.platform_view().engine().GetLoadScriptError();
    if (error == tonic::kNoError)
      error = task_observer.last_error();
    if (error == tonic::kNoError) {
      fxl::AutoResetWaitableEvent latch;
      blink::Threads::UI()->PostTask([&error, &latch] {
        error = tonic::DartMicrotaskQueue::GetForCurrentThread()->GetLastError();
        latch.Signal();
      });
      latch.Wait();
    }

    // The script has completed and the engine may not be in a clean state,
    // so just stop the process.
    exit(ConvertErrorTypeToExitCode(error));
  } else {
    return NSApplicationMain(argc, argv);
  }
}
