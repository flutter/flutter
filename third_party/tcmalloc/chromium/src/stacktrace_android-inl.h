// Copyright (c) 2013, Google Inc.
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
// Author: Marcus Bulach
// This is inspired by Doug Kwan's ARM's stacktrace code and Dai Mikurube's
// stack trace for chromium on android.
//

#ifndef BASE_STACKTRACE_ANDROID_INL_H_
#define BASE_STACKTRACE_ANDROID_INL_H_
// Note: this file is included into stacktrace.cc more than once.
// Anything that should only be defined once should be here:

#include <stdint.h>   // for uintptr_t
// See http://crbug.com/236855, would be better to use Bionic's
// new get_backtrace().
#include <unwind.h>

/* Depends on the system definition for _Unwind_Context */
#ifdef HAVE_UNWIND_CONTEXT_STRUCT
typedef struct _Unwind_Context __unwind_context;
#else
typedef _Unwind_Context __unwind_context;
#endif

struct stack_crawl_state_t {
  uintptr_t* frames;
  size_t frame_count;
  int max_depth;
  int skip_count;
  bool have_skipped_self;

  stack_crawl_state_t(uintptr_t* frames, int max_depth, int skip_count)
      : frames(frames),
        frame_count(0),
        max_depth(max_depth),
        skip_count(skip_count),
        have_skipped_self(false) {
  }
};

static _Unwind_Reason_Code tracer(__unwind_context* context, void* arg) {
  stack_crawl_state_t* state = static_cast<stack_crawl_state_t*>(arg);

#if defined(__clang__)
  // Vanilla Clang's unwind.h doesn't have _Unwind_GetIP for ARM.
  // See http://crbug.com/236855, too.
  uintptr_t ip = 0;
  _Unwind_VRS_Get(context, _UVRSC_CORE, 15, _UVRSD_UINT32, &ip);
  ip &= ~(uintptr_t)0x1;  // remove thumb mode bit
#else
  uintptr_t ip = _Unwind_GetIP(context);
#endif

  // The first stack frame is this function itself.  Skip it.
  if (ip != 0 && !state->have_skipped_self) {
    state->have_skipped_self = true;
    return _URC_NO_REASON;
  }

  if (state->skip_count) {
    --state->skip_count;
    return _URC_NO_REASON;
  }

  state->frames[state->frame_count++] = ip;
  if (state->frame_count >= state->max_depth)
    return _URC_END_OF_STACK;
  else
    return _URC_NO_REASON;
}

#endif  // BASE_STACKTRACE_ANDROID_INL_H_

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
  stack_crawl_state_t state(
      reinterpret_cast<uintptr_t*>(result), max_depth, skip_count);
  _Unwind_Backtrace(tracer, &state);
  return state.frame_count;
}
