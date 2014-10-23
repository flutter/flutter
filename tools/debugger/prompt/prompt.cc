// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/bind.h"
#include "base/memory/weak_ptr.h"
#include "mojo/application/application_runner_chromium.h"
#include "mojo/public/c/system/main.h"
#include "mojo/public/cpp/application/application_delegate.h"
#include "mojo/public/cpp/application/application_impl.h"
#include "sky/tools/debugger/debugger.mojom.h"
#include "sky/viewer/services/tracing.mojom.h"
#include <iostream>

namespace sky {
namespace debugger {
namespace {

std::string GetCommand() {
  std::cout << "(skydb) ";
  std::cout.flush();

  std::string command;
  std::getline(std::cin, command);
  // Any errors (including eof) just quit the debugger:
  if (!std::cin.good())
    command = 'q';
  return command;
}

}

class Prompt : public mojo::ApplicationDelegate {
 public:
  Prompt()
      : is_tracing_(false),
        weak_ptr_factory_(this) {
  }
  virtual ~Prompt() {
  }

 private:
  // Overridden from mojo::ApplicationDelegate:
  virtual void Initialize(mojo::ApplicationImpl* app) override {
    app->ConnectToService("mojo:sky_viewer", &tracing_);
    ScheduleWaitForInput();
  }

  virtual bool ConfigureIncomingConnection(
      mojo::ApplicationConnection* connection) override {
    connection->ConnectToService(&debugger_);
    return true;
  }

  bool ExecuteCommand(const std::string& command) {
    if (command == "help") {
      PrintHelp();
      return true;
    }
    if (command == "trace") {
      ToggleTracing();
      return true;
    }
    if (command == "reload") {
      Reload();
      return true;
    }
    if (command.size() == 1) {
      char c = command[0];
      if (c == 'h')
        PrintHelp();
      else if (c == 'q')
        Quit();
      else if (c == 'r')
        Reload();
      else
        std::cout << "Unknown command: " << c << std::endl;
      return true;
    }
    return false;
  }

  void WaitForInput() {
    std::string command = GetCommand();

    if (!ExecuteCommand(command)) {
      if (command.size() > 0) {
        url_ = command;
        Reload();
      }
    }

    ScheduleWaitForInput();
  }

  void ScheduleWaitForInput() {
    base::MessageLoop::current()->PostTask(FROM_HERE,
        base::Bind(&Prompt::WaitForInput, weak_ptr_factory_.GetWeakPtr()));
  }

  void PrintHelp() {
    std::cout
      << "Sky Debugger" << std::endl
      << "============" << std::endl
      << "Type a URL to load in the debugger, enter to reload." << std::endl
      << "Commands: help   -- Help" << std::endl
      << "          trace  -- Capture a trace" << std::endl
      << "          reload -- Reload the current page" << std::endl
      << "          q      -- Quit" << std::endl;
  }

  void Reload() {
    debugger_->NavigateToURL(url_);
  }

  void Quit() {
    std::cout << "quitting" << std::endl;
    exit(0);
  }

  void ToggleTracing() {
    if (is_tracing_) {
      std::cout << "Stopping trace (writing to sky_viewer.trace)" << std::endl;
      tracing_->Stop();
    } else {
      std::cout << "Starting trace (type 'trace' to stop tracing)" << std::endl;
      tracing_->Start();
    }
    is_tracing_ = !is_tracing_;
  }

  bool is_tracing_;
  DebuggerPtr debugger_;
  TracingPtr tracing_;
  std::string url_;
  base::WeakPtrFactory<Prompt> weak_ptr_factory_;

  DISALLOW_COPY_AND_ASSIGN(Prompt);
};

}  // namespace debugger
}  // namespace sky

MojoResult MojoMain(MojoHandle shell_handle) {
  mojo::ApplicationRunnerChromium runner(new sky::debugger::Prompt);
  return runner.Run(shell_handle);
}
