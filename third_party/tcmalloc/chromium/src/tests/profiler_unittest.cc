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
// Does some simple arithmetic and a few libc routines, so we can profile it.
// Define WITH_THREADS to add pthread functionality as well (otherwise, btw,
// the num_threads argument to this program is ingored).

#include "config_for_unittests.h"
#include <stdio.h>
#include <stdlib.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>                 // for fork()
#endif
#include <sys/wait.h>               // for wait()
#include "gperftools/profiler.h"
#include "base/simple_mutex.h"
#include "tests/testutil.h"

static int result = 0;
static int g_iters = 0;   // argv[1]

Mutex mutex(Mutex::LINKER_INITIALIZED);

static void test_other_thread() {
#ifndef NO_THREADS
  ProfilerRegisterThread();

  int i, m;
  char b[128];
  MutexLock ml(&mutex);
  for (m = 0; m < 1000000; ++m) {          // run millions of times
    for (i = 0; i < g_iters; ++i ) {
      result ^= i;
    }
    snprintf(b, sizeof(b), "other: %d", result);  // get some libc action
  }
#endif
}

static void test_main_thread() {
  int i, m;
  char b[128];
  MutexLock ml(&mutex);
  for (m = 0; m < 1000000; ++m) {          // run millions of times
    for (i = 0; i < g_iters; ++i ) {
      result ^= i;
    }
    snprintf(b, sizeof(b), "same: %d", result);  // get some libc action
  }
}

int main(int argc, char** argv) {
  if ( argc <= 1 ) {
    fprintf(stderr, "USAGE: %s <iters> [num_threads] [filename]\n", argv[0]);
    fprintf(stderr, "   iters: How many million times to run the XOR test.\n");
    fprintf(stderr, "   num_threads: how many concurrent threads.\n");
    fprintf(stderr, "                0 or 1 for single-threaded mode,\n");
    fprintf(stderr, "                -# to fork instead of thread.\n");
    fprintf(stderr, "   filename: The name of the output profile.\n");
    fprintf(stderr, ("             If you don't specify, set CPUPROFILE "
                     "in the environment instead!\n"));
    return 1;
  }

  g_iters = atoi(argv[1]);
  int num_threads = 1;
  const char* filename = NULL;
  if (argc > 2) {
    num_threads = atoi(argv[2]);
  }
  if (argc > 3) {
    filename = argv[3];
  }

  if (filename) {
    ProfilerStart(filename);
  }

  test_main_thread();

  ProfilerFlush();                           // just because we can

  // The other threads, if any, will run only half as long as the main thread
  RunManyThreads(test_other_thread, num_threads);

  // Or maybe they asked to fork.  The fork test is only interesting
  // when we use CPUPROFILE to name, so check for that
#ifdef HAVE_UNISTD_H
  for (; num_threads < 0; ++num_threads) {   // -<num_threads> to fork
    if (filename) {
      printf("FORK test only makes sense when no filename is specified.\n");
      return 2;
    }
    switch (fork()) {
      case -1:
        printf("FORK failed!\n");
        return 1;
      case 0:             // child
        return execl(argv[0], argv[0], argv[1], NULL);
      default:
        wait(NULL);       // we'll let the kids run one at a time
    }
  }
#endif

  test_main_thread();

  if (filename) {
    ProfilerStop();
  }

  return 0;
}
