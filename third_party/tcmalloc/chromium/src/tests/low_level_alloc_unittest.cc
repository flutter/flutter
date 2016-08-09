/* Copyright (c) 2006, Google Inc.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// A test for low_level_alloc.cc

#include <stdio.h>
#include <map>
#include "base/low_level_alloc.h"
#include "base/logging.h"
#include <gperftools/malloc_hook.h>

using std::map;

// a block of memory obtained from the allocator
struct BlockDesc {
  char *ptr;      // pointer to memory
  int len;        // number of bytes
  int fill;       // filled with data starting with this
};

// Check that the pattern placed in the block d
// by RandomizeBlockDesc is still there.
static void CheckBlockDesc(const BlockDesc &d) {
  for (int i = 0; i != d.len; i++) {
    CHECK((d.ptr[i] & 0xff) == ((d.fill + i) & 0xff));
  }
}

// Fill the block "*d" with a pattern
// starting with a random byte.
static void RandomizeBlockDesc(BlockDesc *d) {
  d->fill = rand() & 0xff;
  for (int i = 0; i != d->len; i++) {
    d->ptr[i] = (d->fill + i) & 0xff;
  }
}

// Use to indicate to the malloc hooks that
// this calls is from LowLevelAlloc.
static bool using_low_level_alloc = false;

// n times, toss a coin, and based on the outcome
// either allocate a new block or deallocate an old block.
// New blocks are placed in a map with a random key
// and initialized with RandomizeBlockDesc().
// If keys conflict, the older block is freed.
// Old blocks are always checked with CheckBlockDesc()
// before being freed.  At the end of the run,
// all remaining allocated blocks are freed.
// If use_new_arena is true, use a fresh arena, and then delete it.
// If call_malloc_hook is true and user_arena is true,
// allocations and deallocations are reported via the MallocHook
// interface.
static void Test(bool use_new_arena, bool call_malloc_hook, int n) {
  typedef map<int, BlockDesc> AllocMap;
  AllocMap allocated;
  AllocMap::iterator it;
  BlockDesc block_desc;
  int rnd;
  LowLevelAlloc::Arena *arena = 0;
  if (use_new_arena) {
    int32 flags = call_malloc_hook?  LowLevelAlloc::kCallMallocHook :  0;
    arena = LowLevelAlloc::NewArena(flags, LowLevelAlloc::DefaultArena());
  }
  for (int i = 0; i != n; i++) {
    if (i != 0 && i % 10000 == 0) {
      printf(".");
      fflush(stdout);
    }

    switch(rand() & 1) {      // toss a coin
    case 0:     // coin came up heads: add a block
      using_low_level_alloc = true;
      block_desc.len = rand() & 0x3fff;
      block_desc.ptr =
        reinterpret_cast<char *>(
                        arena == 0
                        ? LowLevelAlloc::Alloc(block_desc.len)
                        : LowLevelAlloc::AllocWithArena(block_desc.len, arena));
      using_low_level_alloc = false;
      RandomizeBlockDesc(&block_desc);
      rnd = rand();
      it = allocated.find(rnd);
      if (it != allocated.end()) {
        CheckBlockDesc(it->second);
        using_low_level_alloc = true;
        LowLevelAlloc::Free(it->second.ptr);
        using_low_level_alloc = false;
        it->second = block_desc;
      } else {
        allocated[rnd] = block_desc;
      }
      break;
    case 1:     // coin came up tails: remove a block
      it = allocated.begin();
      if (it != allocated.end()) {
        CheckBlockDesc(it->second);
        using_low_level_alloc = true;
        LowLevelAlloc::Free(it->second.ptr);
        using_low_level_alloc = false;
        allocated.erase(it);
      }
      break;
    }
  }
  // remove all remaniing blocks
  while ((it = allocated.begin()) != allocated.end()) {
    CheckBlockDesc(it->second);
    using_low_level_alloc = true;
    LowLevelAlloc::Free(it->second.ptr);
    using_low_level_alloc = false;
    allocated.erase(it);
  }
  if (use_new_arena) {
    CHECK(LowLevelAlloc::DeleteArena(arena));
  }
}

// used for counting allocates and frees
static int32 allocates;
static int32 frees;

// called on each alloc if kCallMallocHook specified
static void AllocHook(const void *p, size_t size) {
  if (using_low_level_alloc) {
    allocates++;
  }
}

// called on each free if kCallMallocHook specified
static void FreeHook(const void *p) {
  if (using_low_level_alloc) {
    frees++;
  }
}

int main(int argc, char *argv[]) {
  // This is needed by maybe_threads_unittest.sh, which parses argv[0]
  // to figure out what directory low_level_alloc_unittest is in.
  if (argc != 1) {
    fprintf(stderr, "USAGE: %s\n", argv[0]);
    return 1;
  }

  CHECK(MallocHook::AddNewHook(&AllocHook));
  CHECK(MallocHook::AddDeleteHook(&FreeHook));
  CHECK_EQ(allocates, 0);
  CHECK_EQ(frees, 0);
  Test(false, false, 50000);
  CHECK_NE(allocates, 0);   // default arena calls hooks
  CHECK_NE(frees, 0);
  for (int i = 0; i != 16; i++) {
    bool call_hooks = ((i & 1) == 1);
    allocates = 0;
    frees = 0;
    Test(true, call_hooks, 15000);
    if (call_hooks) {
      CHECK_GT(allocates, 5000); // arena calls hooks
      CHECK_GT(frees, 5000);
    } else {
      CHECK_EQ(allocates, 0);    // arena doesn't call hooks
      CHECK_EQ(frees, 0);
    }
  }
  printf("\nPASS\n");
  CHECK(MallocHook::RemoveNewHook(&AllocHook));
  CHECK(MallocHook::RemoveDeleteHook(&FreeHook));
  return 0;
}
