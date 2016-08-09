// Copyright (c) 2005, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// ---
// Author: Craig Silverstein
//
// This verifies that GetPC works correctly.  This test uses a minimum
// of Google infrastructure, to make it very easy to port to various
// O/Ses and CPUs and test that GetPC is working.

#include "config.h"
#include "getpc.h"        // should be first to get the _GNU_SOURCE dfn
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <sys/time.h>     // for setitimer

// Needs to be volatile so compiler doesn't try to optimize it away
static volatile void* getpc_retval = NULL;    // what GetPC returns
static volatile bool prof_handler_called = false;

static void prof_handler(int sig, siginfo_t*, void* signal_ucontext) {
  if (!prof_handler_called)
    getpc_retval = GetPC(*reinterpret_cast<ucontext_t*>(signal_ucontext));
  prof_handler_called = true;  // only store the retval once
}

static void RoutineCallingTheSignal() {
  struct sigaction sa;
  sa.sa_sigaction = prof_handler;
  sa.sa_flags = SA_RESTART | SA_SIGINFO;
  sigemptyset(&sa.sa_mask);
  if (sigaction(SIGPROF, &sa, NULL) != 0) {
    perror("sigaction");
    exit(1);
  }

  struct itimerval timer;
  timer.it_interval.tv_sec = 0;
  timer.it_interval.tv_usec = 1000;
  timer.it_value = timer.it_interval;
  setitimer(ITIMER_PROF, &timer, 0);

  // Now we need to do some work for a while, that doesn't call any
  // other functions, so we can be guaranteed that when the SIGPROF
  // fires, we're the routine executing.
  int r = 0;
  for (int i = 0; !prof_handler_called; ++i) {
    for (int j = 0; j < i; j++) {
      r ^= i;
      r <<= 1;
      r ^= j;
      r >>= 1;
    }
  }

  // Now make sure the above loop doesn't get optimized out
  srand(r);
}

// This is an upper bound of how many bytes the instructions for
// RoutineCallingTheSignal might be.  There's probably a more
// principled way to do this, but I don't know how portable it would be.
// (The function is 372 bytes when compiled with -g on Mac OS X 10.4.
// I can imagine it would be even bigger in 64-bit architectures.)
const int kRoutineSize = 512 * sizeof(void*)/4;    // allow 1024 for 64-bit

int main(int argc, char** argv) {
  RoutineCallingTheSignal();

  // Annoyingly, C++ disallows casting pointer-to-function to
  // pointer-to-object, so we use a C-style cast instead.
  char* expected = (char*)&RoutineCallingTheSignal;
  char* actual = (char*)getpc_retval;

  // For ia64, ppc64, and parisc64, the function pointer is actually
  // a struct.  For instance, ia64's dl-fptr.h:
  //   struct fdesc {          /* An FDESC is a function descriptor.  */
  //      ElfW(Addr) ip;      /* code entry point */
  //      ElfW(Addr) gp;      /* global pointer */
  //   };
  // We want the code entry point.
#if defined(__ia64) || defined(__ppc64)     // NOTE: ppc64 is UNTESTED
  expected = ((char**)expected)[0];         // this is "ip"
#endif

  if (actual < expected || actual > expected + kRoutineSize) {
    printf("Test FAILED: actual PC: %p, expected PC: %p\n", actual, expected);
    return 1;
  } else {
    printf("PASS\n");
    return 0;
  }
}
