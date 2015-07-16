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
// MallocExtension::MarkThreadIdle() testing
#include <stdio.h>

#include "config_for_unittests.h"
#include "base/logging.h"
#include <gperftools/malloc_extension.h>
#include "tests/testutil.h"   // for RunThread()

// Helper routine to do lots of allocations
static void TestAllocation() {
  static const int kNum = 100;
  void* ptr[kNum];
  for (int size = 8; size <= 65536; size*=2) {
    for (int i = 0; i < kNum; i++) {
      ptr[i] = malloc(size);
    }
    for (int i = 0; i < kNum; i++) {
      free(ptr[i]);
    }
  }
}

// Routine that does a bunch of MarkThreadIdle() calls in sequence
// without any intervening allocations
static void MultipleIdleCalls() {
  for (int i = 0; i < 4; i++) {
    MallocExtension::instance()->MarkThreadIdle();
  }
}

// Routine that does a bunch of MarkThreadIdle() calls in sequence
// with intervening allocations
static void MultipleIdleNonIdlePhases() {
  for (int i = 0; i < 4; i++) {
    TestAllocation();
    MallocExtension::instance()->MarkThreadIdle();
  }
}

// Get current thread cache usage
static size_t GetTotalThreadCacheSize() {
  size_t result;
  CHECK(MallocExtension::instance()->GetNumericProperty(
            "tcmalloc.current_total_thread_cache_bytes",
            &result));
  return result;
}

// Check that MarkThreadIdle() actually reduces the amount
// of per-thread memory.
static void TestIdleUsage() {
  const size_t original = GetTotalThreadCacheSize();

  TestAllocation();
  const size_t post_allocation = GetTotalThreadCacheSize();
  CHECK_GT(post_allocation, original);

  MallocExtension::instance()->MarkThreadIdle();
  const size_t post_idle = GetTotalThreadCacheSize();
  CHECK_LE(post_idle, original);

  // Log after testing because logging can allocate heap memory.
  VLOG(0, "Original usage: %"PRIuS"\n", original);
  VLOG(0, "Post allocation: %"PRIuS"\n", post_allocation);
  VLOG(0, "Post idle: %"PRIuS"\n", post_idle);
}

int main(int argc, char** argv) {
  RunThread(&TestIdleUsage);
  RunThread(&TestAllocation);
  RunThread(&MultipleIdleCalls);
  RunThread(&MultipleIdleNonIdlePhases);

  printf("PASS\n");
  return 0;
}
