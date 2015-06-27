// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <iostream>

#include "base/at_exit.h"
#include "base/basictypes.h"
#include "base/bind.h"
#include "base/command_line.h"
#include "base/i18n/icu_util.h"
#include "base/logging.h"
#include "base/message_loop/message_loop.h"
#include "sky/shell/platform_view.h"
#include "sky/shell/service_provider.h"
#include "sky/shell/shell.h"
#include "sky/shell/shell_view.h"
#include "sky/shell/switches.h"

namespace sky {
namespace shell {
namespace {

void Usage() {
  std::cerr << "Usage: sky_shell"
            << " [MAIN_DART --" << switches::kPackageRoot << "=PACKAGE_ROOT]"
            << " [--" << switches::kSnapshot << "=SNAPSHOT]" << std::endl;
}

void Init() {
  Shell::Init(make_scoped_ptr(new ServiceProviderContext(
      base::MessageLoop::current()->task_runner())));

  // TODO(abarth): Currently we leak the ShellView.
  ShellView* shell_view = new ShellView(Shell::Shared());

  ViewportObserverPtr viewport_observer;
  shell_view->view()->ConnectToViewportObserver(GetProxy(&viewport_observer));

  base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();

  if (command_line.HasSwitch(switches::kSnapshot)) {
    std::string snapshot =
        command_line.GetSwitchValueASCII(switches::kSnapshot);
    viewport_observer->RunFromSnapshot(snapshot);
    return;
  }

  if (command_line.HasSwitch(switches::kPackageRoot)) {
    std::string main = command_line.GetArgs()[0];
    std::string package_root =
        command_line.GetSwitchValueASCII(switches::kPackageRoot);
    viewport_observer->RunFromFile(main, package_root);
    return;
  }

  std::cerr << "One of --" << switches::kPackageRoot << " or --"
            << switches::kSnapshot << " is required." << std::endl;
}

}  // namespace
} // namespace shell
} // namespace sky

int main(int argc, const char* argv[]) {
  base::AtExitManager exit_manager;
  base::CommandLine::Init(argc, argv);

  base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();

  if (command_line.HasSwitch(sky::shell::switches::kHelp)) {
    sky::shell::Usage();
    return 0;
  }

  base::MessageLoop message_loop;

  base::i18n::InitializeICU();

  message_loop.PostTask(FROM_HERE, base::Bind(&sky::shell::Init));
  message_loop.Run();

  return 0;
}
