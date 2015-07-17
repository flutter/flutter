// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <unistd.h>

// LLVM's demangler is large, and we have no need of it.  Overriding it with
// our own stub version here stops a lot of code being pulled in from libc++.
// More here:
//   https://llvm.org/svn/llvm-project/libcxxabi/trunk/src/cxa_demangle.cpp
extern "C" char* __cxa_demangle(const char* mangled_name,
                                char* buf,
                                size_t* n,
                                int* status) {
  static const int kMemoryAllocFailure = -1;  // LLVM's memory_alloc_failure.
  if (status)
    *status = kMemoryAllocFailure;
  return nullptr;
}
