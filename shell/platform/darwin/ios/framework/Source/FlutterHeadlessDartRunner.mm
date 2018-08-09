// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterHeadlessDartRunner.h"

#include <functional>
#include <memory>
#include <sstream>

#include "flutter/fml/make_copyable.h"
#include "flutter/fml/message_loop.h"
#include "flutter/shell/common/engine.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/run_configuration.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/switches.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/shell/platform/darwin/common/command_line.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPlugin.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterDartProject_Internal.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/platform_message_response_darwin.h"
#include "flutter/shell/platform/darwin/ios/headless_platform_view_ios.h"
#include "flutter/shell/platform/darwin/ios/platform_view_ios.h"

static std::unique_ptr<shell::HeadlessPlatformViewIOS> CreateHeadlessPlatformView(
    shell::Shell& shell) {
  return std::make_unique<shell::HeadlessPlatformViewIOS>(shell, shell.GetTaskRunners());
}

static std::unique_ptr<shell::Rasterizer> CreateHeadlessRasterizer(shell::Shell& shell) {
  return std::make_unique<shell::Rasterizer>(shell.GetTaskRunners());
}

static std::string CreateShellLabel() {
  static size_t count = 1;
  std::stringstream stream;
  stream << "io.flutter.headless.";
  stream << count++;
  return stream.str();
}

@implementation FlutterHeadlessDartRunner {
  shell::ThreadHost _threadHost;
  std::unique_ptr<shell::Shell> _shell;
}

- (void)runWithEntrypointAndLibraryUri:(NSString*)entrypoint libraryUri:(NSString*)uri {
  if (_shell != nullptr || entrypoint.length == 0) {
    FML_LOG(ERROR) << "This headless dart runner was already used to run some code.";
    return;
  }

  const auto label = CreateShellLabel();

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

  // These values set the name of the isolate for debugging.
  settings.advisory_script_entrypoint = entrypoint.UTF8String;
  settings.advisory_script_uri = uri.UTF8String;

  // Create the shell. This is a blocking operation.
  _shell = shell::Shell::Create(
      std::move(task_runners),                                        // task runners
      std::move(settings),                                            // settings
      std::bind(&CreateHeadlessPlatformView, std::placeholders::_1),  // platform view creation
      std::bind(&CreateHeadlessRasterizer, std::placeholders::_1)     // rasterzier creation
  );

  if (_shell == nullptr) {
    FML_LOG(ERROR) << "Could not start a shell for the headless dart runner with entrypoint: "
                   << entrypoint.UTF8String;
    return;
  }

  FlutterDartProject* project = [[[FlutterDartProject alloc] init] autorelease];

  auto config = project.runConfiguration;
  config.SetEntrypointAndLibrary(entrypoint.UTF8String, uri.UTF8String);

  // Override the default run configuration with the specified entrypoint.
  _shell->GetTaskRunners().GetUITaskRunner()->PostTask(
      fml::MakeCopyable([engine = _shell->GetEngine(), config = std::move(config)]() mutable {
        BOOL success = NO;
        FML_LOG(INFO) << "Attempting to launch background engine configuration...";
        if (!engine || !engine->Run(std::move(config))) {
          FML_LOG(ERROR) << "Could not launch engine with configuration.";
        } else {
          FML_LOG(INFO) << "Background Isolate successfully started and run.";
          success = YES;
        }
      }));
}

- (void)runWithEntrypoint:(NSString*)entrypoint {
  [self runWithEntrypointAndLibraryUri:entrypoint libraryUri:nil];
}

#pragma mark - FlutterBinaryMessenger

- (void)sendOnChannel:(NSString*)channel message:(NSData*)message {
  [self sendOnChannel:channel message:message binaryReply:nil];
}

- (void)sendOnChannel:(NSString*)channel
              message:(NSData*)message
          binaryReply:(FlutterBinaryReply)callback {
  NSAssert(channel, @"The channel must not be null");
  fml::RefPtr<shell::PlatformMessageResponseDarwin> response =
      (callback == nil) ? nullptr
                        : fml::MakeRefCounted<shell::PlatformMessageResponseDarwin>(
                              ^(NSData* reply) {
                                callback(reply);
                              },
                              _shell->GetTaskRunners().GetPlatformTaskRunner());
  fml::RefPtr<blink::PlatformMessage> platformMessage =
      (message == nil) ? fml::MakeRefCounted<blink::PlatformMessage>(channel.UTF8String, response)
                       : fml::MakeRefCounted<blink::PlatformMessage>(
                             channel.UTF8String, shell::GetVectorFromNSData(message), response);

  _shell->GetPlatformView()->DispatchPlatformMessage(platformMessage);
}

- (void)setMessageHandlerOnChannel:(NSString*)channel
              binaryMessageHandler:(FlutterBinaryMessageHandler)handler {
  reinterpret_cast<shell::HeadlessPlatformViewIOS*>(_shell->GetPlatformView().get())
      ->GetPlatformMessageRouter()
      .SetMessageHandler(channel.UTF8String, handler);
}

@end
