// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <iostream>
#include "fidl/examples/echo/cpp/fidl.h"
#include "lib/async-loop/cpp/loop.h"
#include "lib/fidl/cpp/binding_set.h"
#include "src/lib/fxl/command_line.h"
#include "lib/sys/cpp/component_context.h"

static constexpr char kCmdHelp[] = "help";
static constexpr char kCmdEcho[] = "echo";
static constexpr char kCmdKill[] = "kill";
static constexpr char kCmdCout[] = "cout";
static constexpr char kCmdCerr[] = "cerr";

static constexpr char kUsage[] = R"(
  Usage: helper_proc [-e] [-k kill_string]

Arguments:
  --help: Shows this help page and exits
  --echo: Exposes an echo service (fidl.examples.echo.Echo)
  --kill=kill_string: will kill the process after echoing a string that equals to kill_string
  --cout=what: Prints argument to standard output
  --cerr=what: Prints argument to standard err
)";

// This helper process can be used in lib component's unittest. You can control
// what it'll do by passing different command-line arguments

class EchoServer : public fidl::examples::echo::Echo {
 public:
  void EchoString(::fidl::StringPtr value,
                  EchoStringCallback callback) override {
    std::string intercept = value;
    callback(std::move(value));
    if (listener_) {
      listener_(std::move(intercept));
    }
  }

  fidl::InterfaceRequestHandler<fidl::examples::echo::Echo> GetHandler() {
    return bindings_.GetHandler(this);
  }

  void SetListener(fit::function<void(std::string)> list) {
    listener_ = std::move(list);
  }

 private:
  fidl::BindingSet<fidl::examples::echo::Echo> bindings_;
  fit::function<void(std::string)> listener_;
};

int main(int argc, const char** argv) {
  std::cout << "Hello from helper proc." << std::endl;
  async::Loop loop(&kAsyncLoopConfigAttachToThread);
  auto cmdline = fxl::CommandLineFromArgcArgv(argc, argv);
  if (cmdline.HasOption(kCmdHelp)) {
    std::cout << kUsage;
    return 0;
  }
  auto startup = sys::ComponentContext::Create();
  std::unique_ptr<EchoServer> echo_server;

  if (cmdline.HasOption(kCmdCout)) {
    std::string cout;
    cmdline.GetOptionValue(kCmdCout, &cout);
    std::cout << cout << std::endl;
  }

  if (cmdline.HasOption(kCmdCerr)) {
    std::string cerr;
    cmdline.GetOptionValue(kCmdCerr, &cerr);
    std::cerr << cerr << std::endl;
  }

  if (cmdline.HasOption(kCmdEcho)) {
    echo_server = std::make_unique<EchoServer>();
    startup->outgoing()->AddPublicService(echo_server->GetHandler());
  }

  if (echo_server && cmdline.HasOption(kCmdKill)) {
    std::string kill_str;
    cmdline.GetOptionValue(kCmdKill, &kill_str);
    echo_server->SetListener(
        [&loop, kill_str = std::move(kill_str)](std::string str) {
          if (str == kill_str) {
            loop.Quit();
          }
        });
  }

  if (echo_server) {
    loop.Run();
  }

  std::cout << "Goodbye from helper proc" << std::endl;
  return 0;
}
