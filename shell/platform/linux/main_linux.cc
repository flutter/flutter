// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/at_exit.h"
#include "base/basictypes.h"
#include "base/bind.h"
#include "base/command_line.h"
#include "base/logging.h"
#include "base/message_loop/message_loop.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/switches.h"
#include "flutter/shell/platform/linux/message_pump_glfw.h"
#include "flutter/shell/platform/linux/platform_view_glfw.h"
#include "flutter/shell/testing/testing.h"
#include "mojo/edk/embedder/embedder.h"
#include "mojo/edk/embedder/simple_platform_support.h"

namespace {

int RunNonInteractive() {
  base::MessageLoop message_loop;

  mojo::embedder::Init(mojo::embedder::CreateSimplePlatformSupport());
  shell::Shell::InitStandalone();

  if (!shell::InitForTesting()) {
    shell::switches::PrintUsage("sky_shell");
    return 1;
  }

  message_loop.Run();
  return 0;
}

static bool IsDartFile(const std::string& script_uri) {
  std::string dart_extension = ".dart";
  return script_uri.rfind(dart_extension) ==
         (script_uri.size() - dart_extension.size());
}

int RunInteractive() {
  base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();

  base::MessageLoop message_loop(shell::MessagePumpGLFW::Create());

  mojo::embedder::Init(mojo::embedder::CreateSimplePlatformSupport());
  shell::Shell::InitStandalone();

  std::string bundle_path =
      command_line.GetSwitchValueASCII(shell::switches::kFLX);

  if (bundle_path.empty()) {
    // Alternatively, use the first positional argument.
    auto args = command_line.GetArgs();
    if (args.empty())
      return 1;
    bundle_path = args[0];
  }

  if (bundle_path.empty())
    return 1;

  std::unique_ptr<shell::PlatformViewGLFW> platform_view(
      new shell::PlatformViewGLFW());

  platform_view->ConnectToEngineAndSetupServices();

  platform_view->NotifyCreated();

  if (IsDartFile(bundle_path)) {
    // Load directly from source.
    platform_view->EngineProxy()->RunFromFile(bundle_path, "", "");

  } else {
    // Load from a bundle.
    std::string script_uri = std::string("file://") + bundle_path;
    platform_view->EngineProxy()->RunFromBundle(script_uri, bundle_path);
  }

  message_loop.Run();

  platform_view->NotifyDestroyed();

  return 0;
}

}  // namespace

int main(int argc, const char* argv[]) {
  base::AtExitManager exit_manager;
  base::CommandLine::Init(argc, argv);

  base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();

  if (command_line.HasSwitch(shell::switches::kHelp)) {
    shell::switches::PrintUsage("sky_shell");
    return 0;
  }

  if (command_line.HasSwitch(shell::switches::kNonInteractive)) {
    return RunNonInteractive();
  }

  return RunInteractive();
}
