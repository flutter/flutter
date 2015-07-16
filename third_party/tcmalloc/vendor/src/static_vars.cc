// Copyright (c) 2008, Google Inc.
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
// Author: Ken Ashcraft <opensource@google.com>

#include "static_vars.h"
#include <stddef.h>                     // for NULL
#include <new>                          // for operator new
#include "internal_logging.h"  // for CHECK_CONDITION
#include "common.h"
#include "sampler.h"           // for Sampler

namespace tcmalloc {

SpinLock Static::pageheap_lock_(SpinLock::LINKER_INITIALIZED);
SizeMap Static::sizemap_;
CentralFreeListPadded Static::central_cache_[kNumClasses];
PageHeapAllocator<Span> Static::span_allocator_;
PageHeapAllocator<StackTrace> Static::stacktrace_allocator_;
Span Static::sampled_objects_;
PageHeapAllocator<StackTraceTable::Bucket> Static::bucket_allocator_;
StackTrace* Static::growth_stacks_ = NULL;
PageHeap* Static::pageheap_ = NULL;

void Static::InitStaticVars() {
  sizemap_.Init();
  span_allocator_.Init();
  span_allocator_.New(); // Reduce cache conflicts
  span_allocator_.New(); // Reduce cache conflicts
  stacktrace_allocator_.Init();
  bucket_allocator_.Init();
  // Do a bit of sanitizing: make sure central_cache is aligned properly
  CHECK_CONDITION((sizeof(central_cache_[0]) % 64) == 0);
  for (int i = 0; i < kNumClasses; ++i) {
    central_cache_[i].Init(i);
  }
  // It's important to have PageHeap allocated, not in static storage,
  // so that HeapLeakChecker does not consider all the byte patterns stored
  // in is caches as pointers that are sources of heap object liveness,
  // which leads to it missing some memory leaks.
  pageheap_ = new (MetaDataAlloc(sizeof(PageHeap))) PageHeap;
  DLL_Init(&sampled_objects_);
  Sampler::InitStatics();
}

}  // namespace tcmalloc
