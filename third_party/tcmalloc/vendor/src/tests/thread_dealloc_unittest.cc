// Copyright (c) 2004, Google Inc.
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
// Check that we do not leak memory when cycling through lots of threads.

#include "config_for_unittests.h"
#include <stdio.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>    // for sleep()
#endif
#include "base/logging.h"
#include <gperftools/malloc_extension.h>
#include "tests/testutil.h"   // for RunThread()

// Size/number of objects to allocate per thread (1 MB per thread)
static const int kObjectSize = 1024;
static const int kNumObjects = 1024;

// Number of threads to create and destroy
static const int kNumThreads = 1000;

// Allocate lots of stuff
static void AllocStuff() {
  void** objects = new void*[kNumObjects];
  for (int i = 0; i < kNumObjects; i++) {
    objects[i] = malloc(kObjectSize);
  }
  for (int i = 0; i < kNumObjects; i++) {
    free(objects[i]);
  }
  delete[] objects;
}

int main(int argc, char** argv) {
  static const int kDisplaySize = 1048576;
  char* display = new char[kDisplaySize];

  for (int i = 0; i < kNumThreads; i++) {
    RunThread(&AllocStuff);

    if (((i+1) % 200) == 0) {
      fprintf(stderr, "Iteration: %d of %d\n", (i+1), kNumThreads);
      MallocExtension::instance()->GetStats(display, kDisplaySize);
      fprintf(stderr, "%s\n", display);
    }
  }
  delete[] display;

  printf("PASS\n");
#ifdef HAVE_UNISTD_H
  sleep(1);     // Prevent exit race problem with glibc
#endif
  return 0;
}
