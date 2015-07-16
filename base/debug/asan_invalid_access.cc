// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#if defined(OS_WIN)
#include <windows.h>
#endif

#include "base/debug/alias.h"
#include "base/debug/asan_invalid_access.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"

namespace base {
namespace debug {

namespace {

#if defined(SYZYASAN) && defined(COMPILER_MSVC)
// Disable warning C4530: "C++ exception handler used, but unwind semantics are
// not enabled". We don't want to change the compilation flags just for this
// test, and no exception should be triggered here, so this warning has no value
// here.
#pragma warning(push)
#pragma warning(disable: 4530)
// Corrupt a memory block and make sure that the corruption gets detected either
// when we free it or when another crash happens (if |induce_crash| is set to
// true).
NOINLINE void CorruptMemoryBlock(bool induce_crash) {
  // NOTE(sebmarchand): We intentionally corrupt a memory block here in order to
  //     trigger an Address Sanitizer (ASAN) error report.
  static const int kArraySize = 5;
  int* array = new int[kArraySize];
  // Encapsulate the invalid memory access into a try-catch statement to prevent
  // this function from being instrumented. This way the underflow won't be
  // detected but the corruption will (as the allocator will still be hooked).
  try {
    // Declares the dummy value as volatile to make sure it doesn't get
    // optimized away.
    int volatile dummy = array[-1]--;
    base::debug::Alias(const_cast<int*>(&dummy));
  } catch (...) {
  }
  if (induce_crash)
    CHECK(false);
  delete[] array;
}
#pragma warning(pop)
#endif  // SYZYASAN && COMPILER_MSVC

}  // namespace

#if defined(ADDRESS_SANITIZER) || defined(SYZYASAN)
// NOTE(sebmarchand): We intentionally perform some invalid heap access here in
//     order to trigger an AddressSanitizer (ASan) error report.

static const size_t kArraySize = 5;

void AsanHeapOverflow() {
  scoped_ptr<int[]> array(new int[kArraySize]);
  // Declares the dummy value as volatile to make sure it doesn't get optimized
  // away.
  int volatile dummy = 0;
  dummy = array[kArraySize];
  base::debug::Alias(const_cast<int*>(&dummy));
}

void AsanHeapUnderflow() {
  scoped_ptr<int[]> array(new int[kArraySize]);
  // Declares the dummy value as volatile to make sure it doesn't get optimized
  // away.
  int volatile dummy = 0;
  // We need to store the underflow address in a temporary variable as trying to
  // access array[-1] will trigger a warning C4245: "conversion from 'int' to
  // 'size_t', signed/unsigned mismatch".
  int* underflow_address = &array[0] - 1;
  dummy = *underflow_address;
  base::debug::Alias(const_cast<int*>(&dummy));
}

void AsanHeapUseAfterFree() {
  scoped_ptr<int[]> array(new int[kArraySize]);
  // Declares the dummy value as volatile to make sure it doesn't get optimized
  // away.
  int volatile dummy = 0;
  int* dangling = array.get();
  array.reset();
  dummy = dangling[kArraySize / 2];
  base::debug::Alias(const_cast<int*>(&dummy));
}

#endif  // ADDRESS_SANITIZER || SYZYASAN

#if defined(SYZYASAN) && defined(COMPILER_MSVC)
void AsanCorruptHeapBlock() {
  CorruptMemoryBlock(false);
}

void AsanCorruptHeap() {
  CorruptMemoryBlock(true);
}
#endif  // SYZYASAN && COMPILER_MSVC

}  // namespace debug
}  // namespace base
