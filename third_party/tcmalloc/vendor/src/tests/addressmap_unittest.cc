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
// Author: Sanjay Ghemawat

#include <stdlib.h>   // for rand()
#include <vector>
#include <set>
#include <algorithm>
#include <utility>
#include "addressmap-inl.h"
#include "base/logging.h"
#include "base/commandlineflags.h"

DEFINE_int32(iters, 20, "Number of test iterations");
DEFINE_int32(N, 100000,  "Number of elements to test per iteration");

using std::pair;
using std::make_pair;
using std::vector;
using std::set;
using std::random_shuffle;

struct UniformRandomNumberGenerator {
  size_t Uniform(size_t max_size) {
    if (max_size == 0)
      return 0;
    return rand() % max_size;   // not a great random-number fn, but portable
  }
};
static UniformRandomNumberGenerator rnd;


// pair of associated value and object size
typedef pair<int, size_t> ValueT;

struct PtrAndSize {
  char* ptr;
  size_t size;
  PtrAndSize(char* p, size_t s) : ptr(p), size(s) {}
};

size_t SizeFunc(const ValueT& v) { return v.second; }

static void SetCheckCallback(const void* ptr, ValueT* val,
                             set<pair<const void*, int> >* check_set) {
  check_set->insert(make_pair(ptr, val->first));
}

int main(int argc, char** argv) {
  // Get a bunch of pointers
  const int N = FLAGS_N;
  static const int kMaxRealSize = 49;
  // 100Mb to stress not finding previous object (AddressMap's cluster is 1Mb):
  static const size_t kMaxSize = 100*1000*1000;
  vector<PtrAndSize> ptrs_and_sizes;
  for (int i = 0; i < N; ++i) {
    size_t s = rnd.Uniform(kMaxRealSize);
    ptrs_and_sizes.push_back(PtrAndSize(new char[s], s));
  }

  for (int x = 0; x < FLAGS_iters; ++x) {
    RAW_LOG(INFO, "Iteration %d/%d...\n", x, FLAGS_iters);

    // Permute pointers to get rid of allocation order issues
    random_shuffle(ptrs_and_sizes.begin(), ptrs_and_sizes.end());

    AddressMap<ValueT> map(malloc, free);
    const ValueT* result;
    const void* res_p;

    // Insert a bunch of entries
    for (int i = 0; i < N; ++i) {
      char* p = ptrs_and_sizes[i].ptr;
      CHECK(!map.Find(p));
      int offs = rnd.Uniform(ptrs_and_sizes[i].size);
      CHECK(!map.FindInside(&SizeFunc, kMaxSize, p + offs, &res_p));
      map.Insert(p, make_pair(i, ptrs_and_sizes[i].size));
      CHECK(result = map.Find(p));
      CHECK_EQ(result->first, i);
      CHECK(result = map.FindInside(&SizeFunc, kMaxRealSize, p + offs, &res_p));
      CHECK_EQ(res_p, p);
      CHECK_EQ(result->first, i);
      map.Insert(p, make_pair(i + N, ptrs_and_sizes[i].size));
      CHECK(result = map.Find(p));
      CHECK_EQ(result->first, i + N);
    }

    // Delete the even entries
    for (int i = 0; i < N; i += 2) {
      void* p = ptrs_and_sizes[i].ptr;
      ValueT removed;
      CHECK(map.FindAndRemove(p, &removed));
      CHECK_EQ(removed.first, i + N);
    }

    // Lookup the odd entries and adjust them
    for (int i = 1; i < N; i += 2) {
      char* p = ptrs_and_sizes[i].ptr;
      CHECK(result = map.Find(p));
      CHECK_EQ(result->first, i + N);
      int offs = rnd.Uniform(ptrs_and_sizes[i].size);
      CHECK(result = map.FindInside(&SizeFunc, kMaxRealSize, p + offs, &res_p));
      CHECK_EQ(res_p, p);
      CHECK_EQ(result->first, i + N);
      map.Insert(p, make_pair(i + 2*N, ptrs_and_sizes[i].size));
      CHECK(result = map.Find(p));
      CHECK_EQ(result->first, i + 2*N);
    }

    // Insert even entries back
    for (int i = 0; i < N; i += 2) {
      char* p = ptrs_and_sizes[i].ptr;
      int offs = rnd.Uniform(ptrs_and_sizes[i].size);
      CHECK(!map.FindInside(&SizeFunc, kMaxSize, p + offs, &res_p));
      map.Insert(p, make_pair(i + 2*N, ptrs_and_sizes[i].size));
      CHECK(result = map.Find(p));
      CHECK_EQ(result->first, i + 2*N);
      CHECK(result = map.FindInside(&SizeFunc, kMaxRealSize, p + offs, &res_p));
      CHECK_EQ(res_p, p);
      CHECK_EQ(result->first, i + 2*N);
    }

    // Check all entries
    set<pair<const void*, int> > check_set;
    map.Iterate(SetCheckCallback, &check_set);
    CHECK_EQ(check_set.size(), N);
    for (int i = 0; i < N; ++i) {
      void* p = ptrs_and_sizes[i].ptr;
      check_set.erase(make_pair(p, i + 2*N));
      CHECK(result = map.Find(p));
      CHECK_EQ(result->first, i + 2*N);
    }
    CHECK_EQ(check_set.size(), 0);
  }

  for (int i = 0; i < N; ++i) {
    delete[] ptrs_and_sizes[i].ptr;
  }

  printf("PASS\n");
  return 0;
}
