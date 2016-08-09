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
// Author: Michael Chastain
//
// This is a unit test for large allocations in malloc and friends.
// "Large" means "so large that they overflow the address space".
// For 32 bits, this means allocations near 2^32 bytes and 2^31 bytes.
// For 64 bits, this means allocations near 2^64 bytes and 2^63 bytes.

#include <stddef.h>                     // for size_t, NULL
#include <stdlib.h>                     // for malloc, free, realloc
#include <stdio.h>
#include <set>                          // for set, etc

#include "base/logging.h"               // for operator<<, CHECK, etc

using std::set;

// Alloc a size that should always fail.

void TryAllocExpectFail(size_t size) {
  void* p1 = malloc(size);
  CHECK(p1 == NULL);

  void* p2 = malloc(1);
  CHECK(p2 != NULL);

  void* p3 = realloc(p2, size);
  CHECK(p3 == NULL);

  free(p2);
}

// Alloc a size that might work and might fail.
// If it does work, touch some pages.

void TryAllocMightFail(size_t size) {
  unsigned char* p = static_cast<unsigned char*>(malloc(size));
  if ( p != NULL ) {
    unsigned char volatile* vp = p;  // prevent optimizations
    static const size_t kPoints = 1024;

    for ( size_t i = 0; i < kPoints; ++i ) {
      vp[i * (size / kPoints)] = static_cast<unsigned char>(i);
    }

    for ( size_t i = 0; i < kPoints; ++i ) {
      CHECK(vp[i * (size / kPoints)] == static_cast<unsigned char>(i));
    }

    vp[size-1] = 'M';
    CHECK(vp[size-1] == 'M');
  }

  free(p);
}

int main (int argc, char** argv) {
  // Allocate some 0-byte objects.  They better be unique.
  // 0 bytes is not large but it exercises some paths related to
  // large-allocation code.
  {
    static const int kZeroTimes = 1024;
    printf("Test malloc(0) x %d\n", kZeroTimes);
    set<char*> p_set;
    for ( int i = 0; i < kZeroTimes; ++i ) {
      char* p = new char;
      CHECK(p != NULL);
      CHECK(p_set.find(p) == p_set.end());
      p_set.insert(p_set.end(), p);
    }
    // Just leak the memory.
  }

  // Grab some memory so that some later allocations are guaranteed to fail.
  printf("Test small malloc\n");
  void* p_small = malloc(4*1048576);
  CHECK(p_small != NULL);

  // Test sizes up near the maximum size_t.
  // These allocations test the wrap-around code.
  printf("Test malloc(0 - N)\n");
  const size_t zero = 0;
  static const size_t kMinusNTimes = 16384;
  for ( size_t i = 1; i < kMinusNTimes; ++i ) {
    TryAllocExpectFail(zero - i);
  }

  // Test sizes a bit smaller.
  // The small malloc above guarantees that all these return NULL.
  printf("Test malloc(0 - 1048576 - N)\n");
  static const size_t kMinusMBMinusNTimes = 16384;
  for ( size_t i = 0; i < kMinusMBMinusNTimes; ++i) {
    TryAllocExpectFail(zero - 1048576 - i);
  }

  // Test sizes at half of size_t.
  // These might or might not fail to allocate.
  printf("Test malloc(max/2 +- N)\n");
  static const size_t kHalfPlusMinusTimes = 64;
  const size_t half = (zero - 2) / 2 + 1;
  for ( size_t i = 0; i < kHalfPlusMinusTimes; ++i) {
    TryAllocMightFail(half - i);
    TryAllocMightFail(half + i);
  }

  printf("PASS\n");
  return 0;
}
