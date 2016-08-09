// Copyright (c) 2009, Google Inc.
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
// Author: Andrew Fikes

#include <config.h>
#include "stack_trace_table.h"
#include <string.h>                     // for NULL, memset
#include "base/spinlock.h"              // for SpinLockHolder
#include "common.h"            // for StackTrace
#include "internal_logging.h"  // for ASSERT, Log
#include "page_heap_allocator.h"  // for PageHeapAllocator
#include "static_vars.h"       // for Static

namespace tcmalloc {

bool StackTraceTable::Bucket::KeyEqual(uintptr_t h,
                                       const StackTrace& t) const {
  const bool eq = (this->hash == h && this->trace.depth == t.depth);
  for (int i = 0; eq && i < t.depth; ++i) {
    if (this->trace.stack[i] != t.stack[i]) {
      return false;
    }
  }
  return eq;
}

StackTraceTable::StackTraceTable()
    : error_(false),
      depth_total_(0),
      bucket_total_(0),
      table_(new Bucket*[kHashTableSize]()) {
  memset(table_, 0, kHashTableSize * sizeof(Bucket*));
}

StackTraceTable::~StackTraceTable() {
  delete[] table_;
}

void StackTraceTable::AddTrace(const StackTrace& t) {
  if (error_) {
    return;
  }

  // Hash function borrowed from base/heap-profile-table.cc
  uintptr_t h = 0;
  for (int i = 0; i < t.depth; ++i) {
    h += reinterpret_cast<uintptr_t>(t.stack[i]);
    h += h << 10;
    h ^= h >> 6;
  }
  h += h << 3;
  h ^= h >> 11;

  const int idx = h % kHashTableSize;

  Bucket* b = table_[idx];
  while (b != NULL && !b->KeyEqual(h, t)) {
    b = b->next;
  }
  if (b != NULL) {
    b->count++;
    b->trace.size += t.size;  // keep cumulative size
  } else {
    depth_total_ += t.depth;
    bucket_total_++;
    b = Static::bucket_allocator()->New();
    if (b == NULL) {
      Log(kLog, __FILE__, __LINE__,
          "tcmalloc: could not allocate bucket", sizeof(*b));
      error_ = true;
    } else {
      b->hash = h;
      b->trace = t;
      b->count = 1;
      b->next = table_[idx];
      table_[idx] = b;
    }
  }
}

void** StackTraceTable::ReadStackTracesAndClear() {
  if (error_) {
    return NULL;
  }

  // Allocate output array
  const int out_len = bucket_total_ * 3 + depth_total_ + 1;
  void** out = new void*[out_len];
  if (out == NULL) {
    Log(kLog, __FILE__, __LINE__,
        "tcmalloc: allocation failed for stack traces",
        out_len * sizeof(*out));
    return NULL;
  }

  // Fill output array
  int idx = 0;
  for (int i = 0; i < kHashTableSize; ++i) {
    Bucket* b = table_[i];
    while (b != NULL) {
      out[idx++] = reinterpret_cast<void*>(static_cast<uintptr_t>(b->count));
      out[idx++] = reinterpret_cast<void*>(b->trace.size);  // cumulative size
      out[idx++] = reinterpret_cast<void*>(b->trace.depth);
      for (int d = 0; d < b->trace.depth; ++d) {
        out[idx++] = b->trace.stack[d];
      }
      b = b->next;
    }
  }
  out[idx++] = NULL;
  ASSERT(idx == out_len);

  // Clear state
  error_ = false;
  depth_total_ = 0;
  bucket_total_ = 0;
  SpinLockHolder h(Static::pageheap_lock());
  for (int i = 0; i < kHashTableSize; ++i) {
    Bucket* b = table_[i];
    while (b != NULL) {
      Bucket* next = b->next;
      Static::bucket_allocator()->Delete(b);
      b = next;
    }
    table_[i] = NULL;
  }

  return out;
}

}  // namespace tcmalloc
