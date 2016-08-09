// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/at_exit.h"
#include "base/basictypes.h"
#include "base/bind.h"
#include "base/command_line.h"
#include "base/logging.h"
#include "base/message_loop/message_loop.h"
#include "mojo/edk/embedder/embedder.h"
#include "mojo/edk/embedder/simple_platform_support.h"
#include "flutter/sky/shell/shell.h"
#include "flutter/sky/shell/switches.h"
#include "flutter/sky/shell/testing/testing.h"

#if defined(USE_GLFW)
#include "flutter/sky/shell/platform/glfw/init_glfw.h"
#include "flutter/sky/shell/platform/glfw/message_pump_glfw.h"
#endif

namespace {

int RunNonInteractive() {
  base::MessageLoop message_loop;
  mojo::embedder::Init(mojo::embedder::CreateSimplePlatformSupport());
  sky::shell::Shell::InitStandalone();

  if (!sky::shell::InitForTesting()) {
    sky::shell::switches::PrintUsage("sky_shell");
    return 1;
  }

  message_loop.Run();
  return 0;
}

#if defined(USE_GLFW)

int RunInteractive() {
  base::MessageLoop message_loop(sky::shell::MessagePumpGLFW::Create());
  mojo::embedder::Init(mojo::embedder::CreateSimplePlatformSupport());
  sky::shell::Shell::InitStandalone();

  if (!sky::shell::InitInteractive())
    return 1;

  message_loop.Run();
  return 0;
}

#endif // defined(USE_GLFW)

} // namespace

int main(int argc, const char* argv[]) {
  base::AtExitManager exit_manager;
  base::CommandLine::Init(argc, argv);

  base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();

  if (command_line.HasSwitch(sky::shell::switches::kHelp)) {
    sky::shell::switches::PrintUsage("sky_shell");
    return 0;
  }

#if defined(USE_GLFW)
  if (command_line.HasSwitch(sky::shell::switches::kNonInteractive))
    return RunNonInteractive();
  return RunInteractive();
#endif

  return RunNonInteractive();
}
