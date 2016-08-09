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
// A small program that just exercises our heap profiler by allocating
// memory and letting the heap-profiler emit a profile.  We don't test
// threads (TODO).  By itself, this unittest tests that the heap-profiler
// doesn't crash on simple programs, but its output can be analyzed by
// another testing script to actually verify correctness.  See, eg,
// heap-profiler_unittest.sh.

#include "config_for_unittests.h"
#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>                  // for mkdir()
#include <sys/stat.h>               // for mkdir() on freebsd and os x
#ifdef HAVE_UNISTD_H
#include <unistd.h>                 // for fork()
#endif
#include <sys/wait.h>               // for wait()
#include <string>
#include "base/basictypes.h"
#include "base/logging.h"
#include <gperftools/heap-profiler.h>

using std::string;

static const int kMaxCount = 100000;
int* g_array[kMaxCount];              // an array of int-vectors

static ATTRIBUTE_NOINLINE void Allocate(int start, int end, int size) {
  for (int i = start; i < end; ++i) {
    if (i < kMaxCount)
      g_array[i] = new int[size];
  }
}

static ATTRIBUTE_NOINLINE void Allocate2(int start, int end, int size) {
  for (int i = start; i < end; ++i) {
    if (i < kMaxCount)
      g_array[i] = new int[size];
  }
}

static void Deallocate(int start, int end) {
  for (int i = start; i < end; ++i) {
    delete[] g_array[i];
    g_array[i] = 0;
  }
}

static void TestHeapProfilerStartStopIsRunning() {
  // If you run this with whole-program heap-profiling on, than
  // IsHeapProfilerRunning should return true.
  if (!IsHeapProfilerRunning()) {
    const char* tmpdir = getenv("TMPDIR");
    if (tmpdir == NULL)
      tmpdir = "/tmp";
    mkdir(tmpdir, 0755);     // if necessary
    HeapProfilerStart((string(tmpdir) + "/start_stop").c_str());
    CHECK(IsHeapProfilerRunning());

    Allocate(0, 40, 100);
    Deallocate(0, 40);

    HeapProfilerStop();
    CHECK(!IsHeapProfilerRunning());
  }
}

static void TestDumpHeapProfiler() {
  // If you run this with whole-program heap-profiling on, than
  // IsHeapProfilerRunning should return true.
  if (!IsHeapProfilerRunning()) {
    const char* tmpdir = getenv("TMPDIR");
    if (tmpdir == NULL)
      tmpdir = "/tmp";
    mkdir(tmpdir, 0755);     // if necessary
    HeapProfilerStart((string(tmpdir) + "/dump").c_str());
    CHECK(IsHeapProfilerRunning());

    Allocate(0, 40, 100);
    Deallocate(0, 40);

    char* output = GetHeapProfile();
    free(output);
    HeapProfilerStop();
  }
}


int main(int argc, char** argv) {
  if (argc > 2 || (argc == 2 && argv[1][0] == '-')) {
    printf("USAGE: %s [number of children to fork]\n", argv[0]);
    exit(0);
  }
  int num_forks = 0;
  if (argc == 2) {
    num_forks = atoi(argv[1]);
  }

  TestHeapProfilerStartStopIsRunning();
  TestDumpHeapProfiler();

  Allocate(0, 40, 100);
  Deallocate(0, 40);

  Allocate(0, 40, 100);
  Allocate(0, 40, 100);
  Allocate2(40, 400, 1000);
  Allocate2(400, 1000, 10000);
  Deallocate(0, 1000);

  Allocate(0, 100, 100000);
  Deallocate(0, 10);
  Deallocate(10, 20);
  Deallocate(90, 100);
  Deallocate(20, 90);

  while (num_forks-- > 0) {
    switch (fork()) {
      case -1:
        printf("FORK failed!\n");
        return 1;
      case 0:             // child
        return execl(argv[0], argv[0], NULL);   // run child with no args
      default:
        wait(NULL);       // we'll let the kids run one at a time
    }
  }

  printf("DONE.\n");

  return 0;
}
