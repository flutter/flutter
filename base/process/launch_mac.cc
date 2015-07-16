// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/launch.h"

#include <mach/mach.h>
#include <servers/bootstrap.h>

#include "base/logging.h"

namespace base {

void RestoreDefaultExceptionHandler() {
  // This function is tailored to remove the Breakpad exception handler.
  // exception_mask matches s_exception_mask in
  // breakpad/src/client/mac/handler/exception_handler.cc
  const exception_mask_t exception_mask = EXC_MASK_BAD_ACCESS |
                                          EXC_MASK_BAD_INSTRUCTION |
                                          EXC_MASK_ARITHMETIC |
                                          EXC_MASK_BREAKPOINT;

  // Setting the exception port to MACH_PORT_NULL may not be entirely
  // kosher to restore the default exception handler, but in practice,
  // it results in the exception port being set to Apple Crash Reporter,
  // the desired behavior.
  task_set_exception_ports(mach_task_self(), exception_mask, MACH_PORT_NULL,
                           EXCEPTION_DEFAULT, THREAD_STATE_NONE);
}

void ReplaceBootstrapPort(const std::string& new_bootstrap_name) {
  // This function is called between fork() and exec(), so it should take care
  // to run properly in that situation.

  mach_port_t port = MACH_PORT_NULL;
  kern_return_t kr = bootstrap_look_up(bootstrap_port,
      new_bootstrap_name.c_str(), &port);
  if (kr != KERN_SUCCESS) {
    RAW_LOG(FATAL, "Failed to look up replacement bootstrap port.");
  }

  kr = task_set_bootstrap_port(mach_task_self(), port);
  if (kr != KERN_SUCCESS) {
    RAW_LOG(FATAL, "Failed to replace bootstrap port.");
  }
}

}  // namespace base
