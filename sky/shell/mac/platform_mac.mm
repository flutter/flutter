// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/mac/platform_mac.h"

#include <asl.h>
#include "base/at_exit.h"
#include "base/logging.h"
#include "base/i18n/icu_util.h"
#include "base/command_line.h"
#include "base/mac/scoped_nsautorelease_pool.h"
#include "ui/gl/gl_surface.h"
#include "sky/shell/shell.h"
#include "sky/shell/service_provider.h"
#include "sky/shell/ui_delegate.h"
#include "base/lazy_instance.h"
#include "base/message_loop/message_loop.h"

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
  
int PlatformMacMain(int argc, const char *argv[],
    PlatformMacMainCallback callback) {

  base::mac::ScopedNSAutoreleasePool pool;

  base::AtExitManager exit_manager;

  RedirectIOConnectionsToSyslog();

  auto result = false;

  result = base::CommandLine::Init(argc, argv);
  DLOG_ASSERT(result);

  InitializeLogging();

  result = base::i18n::InitializeICU();
  DLOG_ASSERT(result);

  result = gfx::GLSurface::InitializeOneOff();
  DLOG_ASSERT(result);

  scoped_ptr<base::MessageLoopForUI> main_message_loop(
    new base::MessageLoopForUI());

#if TARGET_OS_IPHONE
  // One cannot start the message loop on the platform main thread. Instead,
  // we attach to the CFRunLoop
  main_message_loop->Attach();
#endif

  auto service_provider_context =
    make_scoped_ptr(new sky::shell::ServiceProviderContext(
        main_message_loop->task_runner()));

  sky::shell::Shell::Init(service_provider_context.Pass());

  result = callback();

#if !TARGET_OS_IPHONE
  if (result == EXIT_SUCCESS) {
    main_message_loop->QuitNow();
  }
#endif

  return result;
}
