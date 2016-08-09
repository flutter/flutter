// Copyright (c) 2003, Google Inc.
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
// Author: Sanjay Ghemawat
//
// Test speed of handling fragmented heap

#include "config_for_unittests.h"
#include <stdlib.h>
#include <stdio.h>
#ifdef HAVE_SYS_RESOURCE_H
#include <sys/time.h>           // for struct timeval
#include <sys/resource.h>       // for getrusage
#endif
#ifdef _WIN32
#include <windows.h>            // for GetTickCount()
#endif
#include <vector>
#include "base/logging.h"
#include "common.h"
#include <gperftools/malloc_extension.h>

using std::vector;

int main(int argc, char** argv) {
  // Make kAllocSize one page larger than the maximum small object size.
  static const int kAllocSize = kMaxSize + kPageSize;
  // Allocate 400MB in total.
  static const int kTotalAlloc = 400 << 20;
  static const int kAllocIterations = kTotalAlloc / kAllocSize;

  // Allocate lots of objects
  vector<char*> saved(kAllocIterations);
  for (int i = 0; i < kAllocIterations; i++) {
    saved[i] = new char[kAllocSize];
  }

  // Check the current "slack".
  size_t slack_before;
  MallocExtension::instance()->GetNumericProperty("tcmalloc.slack_bytes",
                                                  &slack_before);

  // Free alternating ones to fragment heap
  size_t free_bytes = 0;
  for (int i = 0; i < saved.size(); i += 2) {
    delete[] saved[i];
    free_bytes += kAllocSize;
  }

  // Check that slack delta is within 10% of expected.
  size_t slack_after;
  MallocExtension::instance()->GetNumericProperty("tcmalloc.slack_bytes",
                                                  &slack_after);
  CHECK_GE(slack_after, slack_before);
  size_t slack = slack_after - slack_before;

  CHECK_GT(double(slack), 0.9*free_bytes);
  CHECK_LT(double(slack), 1.1*free_bytes);

  // Dump malloc stats
  static const int kBufSize = 1<<20;
  char* buffer = new char[kBufSize];
  MallocExtension::instance()->GetStats(buffer, kBufSize);
  VLOG(1, "%s", buffer);
  delete[] buffer;

  // Now do timing tests
  for (int i = 0; i < 5; i++) {
    static const int kIterations = 100000;
#ifdef HAVE_SYS_RESOURCE_H
    struct rusage r;
    getrusage(RUSAGE_SELF, &r);    // figure out user-time spent on this
    struct timeval tv_start = r.ru_utime;
#elif defined(_WIN32)
    long long int tv_start = GetTickCount();
#else
# error No way to calculate time on your system
#endif

    for (int i = 0; i < kIterations; i++) {
      size_t s;
      MallocExtension::instance()->GetNumericProperty("tcmalloc.slack_bytes",
                                                      &s);
    }

#ifdef HAVE_SYS_RESOURCE_H
    getrusage(RUSAGE_SELF, &r);
    struct timeval tv_end = r.ru_utime;
    int64 sumsec = static_cast<int64>(tv_end.tv_sec) - tv_start.tv_sec;
    int64 sumusec = static_cast<int64>(tv_end.tv_usec) - tv_start.tv_usec;
#elif defined(_WIN32)
    long long int tv_end = GetTickCount();
    int64 sumsec = (tv_end - tv_start) / 1000;
    // Resolution in windows is only to the millisecond, alas
    int64 sumusec = ((tv_end - tv_start) % 1000) * 1000;
#else
# error No way to calculate time on your system
#endif
    fprintf(stderr, "getproperty: %6.1f ns/call\n",
            (sumsec * 1e9 + sumusec * 1e3) / kIterations);
  }

  printf("PASS\n");
  return 0;
}
