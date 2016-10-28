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

static bool IsDartFile(const std::string& path) {
  std::string dart_extension = ".dart";
  return path.rfind(dart_extension) == (path.size() - dart_extension.size());
}

int RunInteractive() {
  base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();

  base::MessageLoop message_loop(shell::MessagePumpGLFW::Create());

  mojo::embedder::Init(mojo::embedder::CreateSimplePlatformSupport());
  shell::Shell::InitStandalone();

  std::string target = command_line.GetSwitchValueASCII(shell::switches::kFLX);

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

  if (command_line.HasSwitch(shell::switches::kHelp)) {
    shell::switches::PrintUsage("sky_shell");
    return 0;
  }

  if (command_line.HasSwitch(shell::switches::kNonInteractive)) {
    return RunNonInteractive();
  }

  return RunInteractive();
}
