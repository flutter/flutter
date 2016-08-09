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
// Author: Arun Sharma
//
// Produce stack trace using libunwind

#ifndef BASE_STACKTRACE_LIBINWIND_INL_H_
#define BASE_STACKTRACE_LIBINWIND_INL_H_
// Note: this file is included into stacktrace.cc more than once.
// Anything that should only be defined once should be here:

// We only need local unwinder.
#define UNW_LOCAL_ONLY

extern "C" {
#include <assert.h>
#include <string.h>   // for memset()
#include <libunwind.h>
}
#include "gperftools/stacktrace.h"
#include "base/logging.h"

// Sometimes, we can try to get a stack trace from within a stack
// trace, because libunwind can call mmap (maybe indirectly via an
// internal mmap based memory allocator), and that mmap gets trapped
// and causes a stack-trace request.  If were to try to honor that
// recursive request, we'd end up with infinite recursion or deadlock.
// Luckily, it's safe to ignore those subsequent traces.  In such
// cases, we return 0 to indicate the situation.
static __thread int recursive;

#endif  // BASE_STACKTRACE_LIBINWIND_INL_H_

// Note: this part of the file is included several times.
// Do not put globals below.

// The following 4 functions are generated from the code below:
//   GetStack{Trace,Frames}()
//   GetStack{Trace,Frames}WithContext()
//
// These functions take the following args:
//   void** result: the stack-trace, as an array
//   int* sizes: the size of each stack frame, as an array
//               (GetStackFrames* only)
//   int max_depth: the size of the result (and sizes) array(s)
//   int skip_count: how many stack pointers to skip before storing in result
//   void* ucp: a ucontext_t* (GetStack{Trace,Frames}WithContext only)
int GET_STACK_TRACE_OR_FRAMES {
  void *ip;
  int n = 0;
  unw_cursor_t cursor;
  unw_context_t uc;
#if IS_STACK_FRAMES
  unw_word_t sp = 0, next_sp = 0;
#endif

  if (recursive) {
    return 0;
  }
  ++recursive;

  unw_getcontext(&uc);
  int ret = unw_init_local(&cursor, &uc);
  assert(ret >= 0);
  skip_count++;         // Do not include current frame

  while (skip_count--) {
    if (unw_step(&cursor) <= 0) {
      goto out;
    }
#if IS_STACK_FRAMES
    if (unw_get_reg(&cursor, UNW_REG_SP, &next_sp)) {
      goto out;
    }
#endif
  }

  while (n < max_depth) {
    if (unw_get_reg(&cursor, UNW_REG_IP, (unw_word_t *) &ip) < 0) {
      break;
    }
#if IS_STACK_FRAMES
    sizes[n] = 0;
#endif
    result[n++] = ip;
    if (unw_step(&cursor) <= 0) {
      break;
    }
#if IS_STACK_FRAMES
    sp = next_sp;
    if (unw_get_reg(&cursor, UNW_REG_SP, &next_sp) , 0) {
      break;
    }
    sizes[n - 1] = next_sp - sp;
#endif
  }
out:
  --recursive;
  return n;
}
