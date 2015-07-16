// Copyright (c) 2007, Google Inc.
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
// Author: Geoff Pike

#include <stdio.h>
#include "base/logging.h"
#include "packed-cache-inl.h"

static const int kHashbits = PackedCache<64, uint64>::kHashbits;

// A basic sanity test.
void PackedCacheTest_basic() {
  PackedCache<32, uint32> cache(0);
  CHECK_EQ(cache.GetOrDefault(0, 1), 0);
  cache.Put(0, 17);
  CHECK(cache.Has(0));
  CHECK_EQ(cache.GetOrDefault(0, 1), 17);
  cache.Put(19, 99);
  CHECK(cache.Has(0) && cache.Has(19));
  CHECK_EQ(cache.GetOrDefault(0, 1), 17);
  CHECK_EQ(cache.GetOrDefault(19, 1), 99);
  // Knock <0, 17> out by using a conflicting key.
  cache.Put(1 << kHashbits, 22);
  CHECK(!cache.Has(0));
  CHECK_EQ(cache.GetOrDefault(0, 1), 1);
  CHECK_EQ(cache.GetOrDefault(1 << kHashbits, 1), 22);
}

int main(int argc, char **argv) {
  PackedCacheTest_basic();

  printf("PASS\n");
  return 0;
}
