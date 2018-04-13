// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterHeadlessDartRunner.h"

#include <functional>
#include <memory>

#include "flutter/fml/message_loop.h"
#include "flutter/shell/common/engine.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/run_configuration.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/switches.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/shell/platform/darwin/common/command_line.h"
#include "lib/fxl/functional/make_copyable.h"

static std::unique_ptr<shell::PlatformView> CreateHeadlessPlatformView(shell::Shell& shell) {
  return std::make_unique<shell::PlatformView>(shell, shell.GetTaskRunners());
}

static std::unique_ptr<shell::Rasterizer> CreateHeadlessRasterizer(shell::Shell& shell) {
  return std::make_unique<shell::Rasterizer>(shell.GetTaskRunners());
}

@implementation FlutterHeadlessDartRunner {
  shell::ThreadHost _threadHost;
  std::unique_ptr<shell::Shell> _shell;
}

- (void)runWithEntrypoint:(NSString*)entrypoint {
  if (_shell != nullptr || entrypoint.length == 0) {
    FXL_LOG(ERROR) << "This headless dart runner was already used to run some code.";
    return;
  }

  const auto label = "io.flutter.headless";

  // Create the threads to run the shell on.
  _threadHost = {
      label,                       // native thread label
      shell::ThreadHost::Type::UI  // managed threads to create
  };

  // Configure shell task runners.
  auto current_task_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();
  auto single_task_runner = _threadHost.ui_thread->GetTaskRunner();
  blink::TaskRunners task_runners(label,                // dart thread label
                                  current_task_runner,  // platform
                                  single_task_runner,   // gpu
                                  single_task_runner,   // ui
                                  single_task_runner    // io
  );

  auto settings = shell::SettingsFromCommandLine(shell::CommandLineFromNSProcessInfo());

  // Create the shell. This is a blocking operation.
  _shell = shell::Shell::Create(
      std::move(task_runners),                                        // task runners
      std::move(settings),                                            // settings
      std::bind(&CreateHeadlessPlatformView, std::placeholders::_1),  // platform view creation
      std::bind(&CreateHeadlessRasterizer, std::placeholders::_1)     // rasterzier creation
  );

  if (_shell == nullptr) {
    FXL_LOG(ERROR) << "Could not start a shell for the headless dart runner with entrypoint: "
                   << entrypoint.UTF8String;
    return;
  }

  // Override the default run configuration with the specified entrypoint.
  _shell->GetTaskRunners().GetUITaskRunner()->PostTask(
      fxl::MakeCopyable([engine = _shell->GetEngine(),
                         config = shell::RunConfiguration::InferFromSettings(settings)]() mutable {
        if (!engine || !engine->Run(std::move(config))) {
          FXL_LOG(ERROR) << "Could not launch engine with configuration.";
        }
      }));
}

@end
