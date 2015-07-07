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
#include "sky/engine/public/web/WebRuntimeFeatures.h"
#include "sky/shell/platform_view.h"
#include "sky/shell/service_provider.h"
#include "sky/shell/shell.h"
#include "sky/shell/shell_view.h"
#include "sky/shell/switches.h"
#include "sky/shell/testing/test_runner.h"

namespace sky {
namespace shell {
namespace {

void Usage() {
  std::cerr << "Usage: sky_shell"
            << " --" << switches::kNonInteractive
            << " --" << switches::kPackageRoot << "=PACKAGE_ROOT"
            << " [ MAIN_DART ]" << std::endl;
}

void Init() {
  base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();
  blink::WebRuntimeFeatures::enableObservatory(
      !command_line.HasSwitch(switches::kNonInteractive));

  Shell::Init(make_scoped_ptr(new ServiceProviderContext(
      base::MessageLoop::current()->task_runner())));
  // Explicitly boot the shared test runner.
  TestRunner& runner = TestRunner::Shared();

  std::string package_root =
      command_line.GetSwitchValueASCII(switches::kPackageRoot);

  std::string main;
  auto args = command_line.GetArgs();
  if (!args.empty())
    main = args[0];

  runner.set_package_root(package_root);
  runner.Start(main);
}

}  // namespace
} // namespace shell
} // namespace sky

int main(int argc, const char* argv[]) {
  base::AtExitManager exit_manager;
  base::CommandLine::Init(argc, argv);

  base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();

  if (command_line.HasSwitch(sky::shell::switches::kHelp) ||
      !command_line.HasSwitch(sky::shell::switches::kPackageRoot)) {
    sky::shell::Usage();
    return 0;
  }

  base::MessageLoop message_loop;

  base::i18n::InitializeICU();

  message_loop.PostTask(FROM_HERE, base::Bind(&sky::shell::Init));
  message_loop.Run();

  return 0;
}
