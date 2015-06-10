// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#include <asl.h>
#import "sky_app_delegate.h"
#include "base/at_exit.h"
#include "base/logging.h"
#include "base/i18n/icu_util.h"
#include "base/command_line.h"
#include "base/mac/scoped_nsautorelease_pool.h"
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
  asl_log_descriptor(NULL, NULL, ASL_LEVEL_INFO, STDOUT_FILENO,
                     ASL_LOG_DESCRIPTOR_WRITE);
  asl_log_descriptor(NULL, NULL, ASL_LEVEL_NOTICE, STDERR_FILENO,
                     ASL_LOG_DESCRIPTOR_WRITE);
}

#ifndef NDEBUG

static void SkyDebuggerHookMain(void) {
  // By default, LLDB breaks way too early. This is before libraries have been
  // loaded and __attribute__((constructor)) methods have been called. In most
  // situations, this is unnecessary. Also, breakpoint resolution is not
  // immediate. So we provide this hook to break on.
}

#endif

int main(int argc, char* argv[]) {
#ifndef NDEBUG
  SkyDebuggerHookMain();
#endif
  base::mac::ScopedNSAutoreleasePool pool;
  base::AtExitManager exit_manager;
  RedirectIOConnectionsToSyslog();
  auto result = false;
  result = base::CommandLine::Init(0, nullptr);
  DLOG_ASSERT(result);
  InitializeLogging();
  result = base::i18n::InitializeICU();
  DLOG_ASSERT(result);
  result = gfx::GLSurface::InitializeOneOff();
  DLOG_ASSERT(result);
  return UIApplicationMain(argc, argv, nil,
                           NSStringFromClass([SkyAppDelegate class]));
}
