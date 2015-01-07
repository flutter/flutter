// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/bind.h"
#include "base/memory/weak_ptr.h"
#include "mojo/application/application_runner_chromium.h"
#include "mojo/public/c/system/main.h"
#include "mojo/public/cpp/application/application_delegate.h"
#include "mojo/public/cpp/application/application_impl.h"
#include "services/tracing/tracing.mojom.h"
#include "sky/tools/debugger/debugger.mojom.h"
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
    app->ConnectToService("mojo:tracing", &tracing_);
    if (app->args().size() > 1)
      url_ = app->args()[1];
    else {
      url_ = "https://raw.githubusercontent.com/domokit/mojo/master/sky/"
          "examples/home.sky";
    }
  }

  virtual bool ConfigureIncomingConnection(
      mojo::ApplicationConnection* connection) override {
    connection->ConnectToService(&debugger_);
    std::cout << "Loading " << url_ << std::endl;
    Reload();
#if !defined(OS_ANDROID)
    // FIXME: To support device-centric development we need to re-write
    // prompt.cc to just be a server and have all the command handling move
    // to python (skydb).  prompt.cc would just run until told to quit.
    // If we don't comment this out then prompt.cc just quits when run headless
    // as it immediately recieves EOF which it treats as quit.
    ScheduleWaitForInput();
#endif
    return true;
  }

  bool ExecuteCommand(const std::string& command) {
    if (command == "help" || command == "h") {
      PrintHelp();
      return true;
    }
    if (command == "trace") {
      ToggleTracing();
      return true;
    }
    if (command == "reload" || command == "r") {
      Reload();
      return true;
    }
    if (command == "inspect") {
      Inspect();
      return true;
    }
    if (command == "quit" || command == "q") {
      Quit();
      return true;
    }
    if (command.size() == 1) {
      std::cout << "Unknown command: " << command << std::endl;
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
      << "Commands: help    -- Help" << std::endl
      << "          trace   -- Capture a trace" << std::endl
      << "          reload  -- Reload the current page" << std::endl
      << "          inspect -- Inspect the current page" << std::endl
      << "          quit    -- Quit" << std::endl;
  }

  void Reload() {
    debugger_->NavigateToURL(url_);
  }

  void Inspect() {
    debugger_->InjectInspector();
    std::cout
      << "Open the following URL in Chrome:" << std::endl
      << "chrome-devtools://devtools/bundled/devtools.html?ws=localhost:9898"
      << std::endl;
  }

  void Quit() {
    std::cout << "quitting" << std::endl;
    debugger_->Shutdown();
  }

  void ToggleTracing() {
    if (is_tracing_) {
      std::cout << "Stopping trace (writing to sky_viewer.trace)" << std::endl;
      tracing_->StopAndFlush();
    } else {
      std::cout << "Starting trace (type 'trace' to stop tracing)" << std::endl;
      tracing_->Start(mojo::String("sky_viewer"), mojo::String("*"));
    }
    is_tracing_ = !is_tracing_;
  }

  bool is_tracing_;
  DebuggerPtr debugger_;
  tracing::TraceCoordinatorPtr tracing_;
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
