// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/at_exit.h"
#include "base/basictypes.h"
#include "base/bind.h"
#include "base/command_line.h"
#include "base/logging.h"
#include "base/message_loop/message_loop.h"
#include "flutter/common/threads.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/switches.h"
#include "flutter/shell/gpu/gpu_surface_gl.h"
#include "flutter/shell/platform/linux/message_pump_glfw.h"
#include "flutter/shell/platform/linux/platform_view_glfw.h"
#include "flutter/shell/testing/test_runner.h"
#include "flutter/shell/testing/testing.h"
#include "flutter/sky/engine/public/web/Sky.h"

namespace {

// Checks whether the engine's main Dart isolate has no pending work.  If so,
// then exit the given message loop.
class ScriptCompletionTaskObserver : public base::MessageLoop::TaskObserver {
 public:
  ScriptCompletionTaskObserver(base::MessageLoop& main_message_loop)
      : main_message_loop_(main_message_loop), prev_live_(false) {}

  void WillProcessTask(const base::PendingTask& pending_task) override {}

  void DidProcessTask(const base::PendingTask& pending_task) override {
    shell::TestRunner& test_runner = shell::TestRunner::Shared();
    bool live = test_runner.platform_view().engine().UIIsolateHasLivePorts();
    if (prev_live_ && !live)
      main_message_loop_.PostTask(FROM_HERE,
                                  main_message_loop_.QuitWhenIdleClosure());
    prev_live_ = live;
  }

 private:
  base::MessageLoop& main_message_loop_;
  bool prev_live_;
};

void RunNonInteractive(bool run_forever) {
  base::MessageLoop message_loop;

  shell::Shell::InitStandalone();

  // Note that this task observer must be added after the observer that drains
  // the microtask queue.
  ScriptCompletionTaskObserver task_observer(message_loop);
  if (!run_forever) {
    blink::Threads::UI()->PostTask([&task_observer] {
      base::MessageLoop::current()->AddTaskObserver(&task_observer);
    });
  }

  if (!shell::InitForTesting()) {
    shell::PrintUsage("sky_shell");
    exit(1);
  }

  message_loop.Run();

  // The script has completed and the engine may not be in a clean state,
  // so just stop the process.
  exit(0);
}

static bool IsDartFile(const std::string& path) {
  std::string dart_extension = ".dart";
  return path.rfind(dart_extension) == (path.size() - dart_extension.size());
}

int RunInteractive() {
  base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();

  base::MessageLoop message_loop(shell::MessagePumpGLFW::Create());

  shell::Shell::InitStandalone();

  std::string target = command_line.GetSwitchValueASCII(
      shell::FlagForSwitch(shell::Switch::FLX));

  if (target.empty()) {
    // Alternatively, use the first positional argument.
    auto args = command_line.GetArgs();
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

int main(int argc, const char* argv[]) {
  base::AtExitManager exit_manager;
  base::CommandLine::Init(argc, argv);

  base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();

  if (command_line.HasSwitch(shell::FlagForSwitch(shell::Switch::Help))) {
    shell::PrintUsage("sky_shell");
    return 0;
  }

  if (command_line.HasSwitch(
          shell::FlagForSwitch(shell::Switch::NonInteractive))) {
    bool run_forever = command_line.HasSwitch(
        shell::FlagForSwitch(shell::Switch::RunForever));
    RunNonInteractive(run_forever);
    return 0;
  }

  return RunInteractive();
}
