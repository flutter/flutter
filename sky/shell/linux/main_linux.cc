// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/at_exit.h"
#include "base/basictypes.h"
#include "base/bind.h"
#include "base/command_line.h"
#include "base/logging.h"
#include "base/message_loop/message_loop.h"
#include "sky/shell/service_provider.h"
#include "sky/shell/shell.h"
#include "sky/shell/switches.h"
#include "sky/shell/testing/testing.h"

int main(int argc, const char* argv[]) {
  base::AtExitManager exit_manager;
  base::CommandLine::Init(argc, argv);

  base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();

  if (command_line.HasSwitch(sky::shell::switches::kHelp)) {
    sky::shell::switches::PrintUsage("sky_shell");
    return 0;
  }

  base::MessageLoop message_loop;

  sky::shell::Shell::Init(make_scoped_ptr(
      new sky::shell::ServiceProviderContext(message_loop.task_runner())));

  message_loop.PostTask(FROM_HERE, base::Bind(&sky::shell::InitForTesting));
  message_loop.Run();

  return 0;
}
