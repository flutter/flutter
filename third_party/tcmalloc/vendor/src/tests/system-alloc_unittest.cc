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
// Author: Arun Sharma

#include "config_for_unittests.h"
#include "system-alloc.h"
#include <stdio.h>
#if defined HAVE_STDINT_H
#include <stdint.h>             // to get uintptr_t
#elif defined HAVE_INTTYPES_H
#include <inttypes.h>           // another place uintptr_t might be defined
#endif
#include <sys/types.h>
#include <algorithm>
#include <limits>
#include "base/logging.h"               // for Check_GEImpl, Check_LTImpl, etc
#include <gperftools/malloc_extension.h>    // for MallocExtension::instance
#include "common.h"                     // for kAddressBits

class ArraySysAllocator : public SysAllocator {
public:
  // Was this allocator invoked at least once?
  bool invoked_;

  ArraySysAllocator() : SysAllocator() {
    ptr_ = 0;
    invoked_ = false;
  }

  void* Alloc(size_t size, size_t *actual_size, size_t alignment) {
    invoked_ = true;

    if (size > kArraySize) {
      return NULL;
    }

    void *result = &array_[ptr_];
    uintptr_t ptr = reinterpret_cast<uintptr_t>(result);

    if (actual_size) {
      *actual_size = size;
    }

    // Try to get more memory for alignment
    size_t extra = alignment - (ptr & (alignment-1));
    size += extra;
    CHECK_LT(ptr_ + size, kArraySize);

    if ((ptr & (alignment-1)) != 0) {
      ptr += alignment - (ptr & (alignment-1));
    }

    ptr_ += size;
    return reinterpret_cast<void *>(ptr);
  }

  void DumpStats() {
  }

private:
  static const int kArraySize = 8 * 1024 * 1024;
  char array_[kArraySize];
  // We allocate the next chunk from here
  int ptr_;

};
const int ArraySysAllocator::kArraySize;
ArraySysAllocator a;

static void TestBasicInvoked() {
  MallocExtension::instance()->SetSystemAllocator(&a);

  // An allocation size that is likely to trigger the system allocator.
  // XXX: this is implementation specific.
  char *p = new char[1024 * 1024];
  delete [] p;

  // Make sure that our allocator was invoked.
  CHECK(a.invoked_);
}

#if 0  // could port this to various OSs, but won't bother for now
TEST(AddressBits, CpuVirtualBits) {
  // Check that kAddressBits is as least as large as either the number of bits
  // in a pointer or as the number of virtual bits handled by the processor.
  // To be effective this test must be run on each processor model.
  const int kPointerBits = 8 * sizeof(void*);
  const int kImplementedVirtualBits = NumImplementedVirtualBits();

  CHECK_GE(kAddressBits, std::min(kImplementedVirtualBits, kPointerBits));
}
#endif

static void TestBasicRetryFailTest() {
  // Check with the allocator still works after a failed allocation.
  //
  // There is no way to call malloc and guarantee it will fail.  malloc takes a
  // size_t parameter and the C++ standard does not constrain the size of
  // size_t.  For example, consider an implementation where size_t is 32 bits
  // and pointers are 64 bits.
  //
  // It is likely, though, that sizeof(size_t) == sizeof(void*).  In that case,
  // the first allocation here might succeed but the second allocation must
  // fail.
  //
  // If the second allocation succeeds, you will have to rewrite or
  // disable this test.
  // The weird parens are to avoid macro-expansion of 'max' on windows.
  const size_t kHugeSize = (std::numeric_limits<size_t>::max)() / 2;
  void* p1 = malloc(kHugeSize);
  void* p2 = malloc(kHugeSize);
  CHECK(p2 == NULL);
  if (p1 != NULL) free(p1);

  char* q = new char[1024];
  CHECK(q != NULL);
  delete [] q;
}

int main(int argc, char** argv) {
  TestBasicInvoked();
  TestBasicRetryFailTest();

  printf("PASS\n");
  return 0;
}
