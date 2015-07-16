// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/mac/os_crash_dumps.h"

#include <signal.h>
#include <unistd.h>

#include "base/basictypes.h"
#include "base/logging.h"

namespace base {
namespace mac {

namespace {

void ExitSignalHandler(int sig) {
  // A call to exit() can call atexit() handlers.  If we SIGSEGV due
  // to a corrupt heap, and if we have an atexit handler that
  // allocates or frees memory, we are in trouble if we do not _exit.
  _exit(128 + sig);
}

}  // namespace

void DisableOSCrashDumps() {
  // These are the POSIX signals corresponding to the Mach exceptions that
  // Apple Crash Reporter handles.  See ux_exception() in xnu's
  // bsd/uxkern/ux_exception.c and machine_exception() in xnu's
  // bsd/dev/*/unix_signal.c.
  const int signals_to_intercept[] = {
    // Hardware faults
    SIGILL,   // EXC_BAD_INSTRUCTION
    SIGTRAP,  // EXC_BREAKPOINT
    SIGFPE,   // EXC_ARITHMETIC
    SIGBUS,   // EXC_BAD_ACCESS
    SIGSEGV,  // EXC_BAD_ACCESS
    // Not a hardware fault
    SIGABRT
  };

  // For all these signals, just wire things up so we exit immediately.
  for (size_t i = 0; i < arraysize(signals_to_intercept); ++i) {
    struct sigaction act = {};
    act.sa_handler = ExitSignalHandler;

    // It is better to allow the signal handler to run on the stack
    // registered with sigaltstack(), if one is present.
    act.sa_flags = SA_ONSTACK;

    if (sigemptyset(&act.sa_mask) != 0)
      DPLOG(FATAL) << "sigemptyset() failed";
    if (sigaction(signals_to_intercept[i], &act, NULL) != 0)
      DPLOG(FATAL) << "sigaction() failed";
  }
}

}  // namespace mac
}  // namespace base
