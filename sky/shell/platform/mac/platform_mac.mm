// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/mac/platform_mac.h"

#include <asl.h>
#include "base/at_exit.h"
#include "base/command_line.h"
#include "base/i18n/icu_util.h"
#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/mac/scoped_nsautorelease_pool.h"
#include "base/message_loop/message_loop.h"
#include "mojo/edk/embedder/embedder.h"
#include "mojo/edk/embedder/simple_platform_support.h"
#include "sky/shell/shell.h"
#include "sky/shell/switches.h"
#include "sky/shell/tracing_controller.h"
#include "sky/shell/ui_delegate.h"
#include "ui/gl/gl_surface.h"

static void InitializeLogging() {
  logging::LoggingSettings settings;
  settings.logging_dest = logging::LOG_TO_SYSTEM_DEBUG_LOG;
  logging::InitLogging(settings);
  logging::SetLogItems(false,   // Process ID
                       false,   // Thread ID
                       false,   // Timestamp
                       false);  // Tick count
}

static void RedirectIOConnectionsToSyslog() {
#if TARGET_OS_IPHONE
  asl_log_descriptor(NULL, NULL, ASL_LEVEL_INFO, STDOUT_FILENO,
                     ASL_LOG_DESCRIPTOR_WRITE);
  asl_log_descriptor(NULL, NULL, ASL_LEVEL_NOTICE, STDERR_FILENO,
                     ASL_LOG_DESCRIPTOR_WRITE);
#endif
}

int PlatformMacMain(int argc,
                    const char* argv[],
                    PlatformMacMainCallback callback) {
  base::mac::ScopedNSAutoreleasePool pool;

  base::AtExitManager exit_manager;

  RedirectIOConnectionsToSyslog();

  bool result = false;

  result = base::CommandLine::Init(argc, argv);
  DLOG_ASSERT(result);

  InitializeLogging();

  base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();
  if (command_line.HasSwitch(sky::shell::switches::kTraceStartup)) {
    // Usually, all tracing within flutter is managed via the tracing controller
    // The tracing controller is accessed via the shell instance. This means
    // that tracing can only be enabled once that instance is created. Traces
    // early in startup are lost. This enables tracing only in base manually
    // till the tracing controller takes over.
    sky::shell::TracingController::StartBaseTracing();
  }

  scoped_ptr<base::MessageLoopForUI> message_loop(new base::MessageLoopForUI());

#if TARGET_OS_IPHONE
  // One cannot start the message loop on the platform main thread. Instead,
  // we attach to the CFRunLoop
  message_loop->Attach();
#endif

  mojo::embedder::Init(std::unique_ptr<mojo::embedder::PlatformSupport>(
      new mojo::embedder::SimplePlatformSupport()));

  CHECK(gfx::GLSurface::InitializeOneOff());
  sky::shell::Shell::InitStandalone();

  result = callback();

#if !TARGET_OS_IPHONE
  if (result == EXIT_SUCCESS) {
    message_loop->QuitNow();
  }
#endif

  return result;
}
