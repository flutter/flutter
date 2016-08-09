// Copyright (c) 2011, Google Inc.
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
// Author: Doug Kwan
// This is inspired by Craig Silverstein's PowerPC stacktrace code.
//

#ifndef BASE_STACKTRACE_ARM_INL_H_
#define BASE_STACKTRACE_ARM_INL_H_
// Note: this file is included into stacktrace.cc more than once.
// Anything that should only be defined once should be here:

#include <stdint.h>   // for uintptr_t
#include "base/basictypes.h"  // for NULL
#include <gperftools/stacktrace.h>

// WARNING:
// This only works if all your code is in either ARM or THUMB mode.  With
// interworking, the frame pointer of the caller can either be in r11 (ARM
// mode) or r7 (THUMB mode).  A callee only saves the frame pointer of its
// mode in a fixed location on its stack frame.  If the caller is a different
// mode, there is no easy way to find the frame pointer.  It can either be
// still in the designated register or saved on stack along with other callee
// saved registers.

// Given a pointer to a stack frame, locate and return the calling
// stackframe, or return NULL if no stackframe can be found. Perform sanity
// checks (the strictness of which is controlled by the boolean parameter
// "STRICT_UNWINDING") to reduce the chance that a bad pointer is returned.
template<bool STRICT_UNWINDING>
static void **NextStackFrame(void **old_sp) {
  void **new_sp = (void**) old_sp[-1];

  // Check that the transition from frame pointer old_sp to frame
  // pointer new_sp isn't clearly bogus
  if (STRICT_UNWINDING) {
    // With the stack growing downwards, older stack frame must be
    // at a greater address that the current one.
    if (new_sp <= old_sp) return NULL;
    // Assume stack frames larger than 100,000 bytes are bogus.
    if ((uintptr_t)new_sp - (uintptr_t)old_sp > 100000) return NULL;
  } else {
    // In the non-strict mode, allow discontiguous stack frames.
    // (alternate-signal-stacks for example).
    if (new_sp == old_sp) return NULL;
    // And allow frames upto about 1MB.
    if ((new_sp > old_sp)
        && ((uintptr_t)new_sp - (uintptr_t)old_sp > 1000000)) return NULL;
  }
  if ((uintptr_t)new_sp & (sizeof(void *) - 1)) return NULL;
  return new_sp;
}

// This ensures that GetStackTrace stes up the Link Register properly.
#ifdef __GNUC__
void StacktraceArmDummyFunction() __attribute__((noinline));
void StacktraceArmDummyFunction() { __asm__ volatile(""); }
#else
# error StacktraceArmDummyFunction() needs to be ported to this platform.
#endif
#endif  // BASE_STACKTRACE_ARM_INL_H_

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
#ifdef __GNUC__
  void **sp = reinterpret_cast<void**>(__builtin_frame_address(0));
#else
# error reading stack point not yet supported on this platform.
#endif

  // On ARM, the return address is stored in the link register (r14).
  // This is not saved on the stack frame of a leaf function.  To
  // simplify code that reads return addresses, we call a dummy
  // function so that the return address of this function is also
  // stored in the stack frame.  This works at least for gcc.
  StacktraceArmDummyFunction();

  int n = 0;
  while (sp && n < max_depth) {
    // The GetStackFrames routine is called when we are in some
    // informational context (the failure signal handler for example).
    // Use the non-strict unwinding rules to produce a stack trace
    // that is as complete as possible (even if it contains a few bogus
    // entries in some rare cases).
    void **next_sp = NextStackFrame<IS_STACK_FRAMES == 0>(sp);

    if (skip_count > 0) {
      skip_count--;
    } else {
      result[n] = *sp;

#if IS_STACK_FRAMES
      if (next_sp > sp) {
        sizes[n] = (uintptr_t)next_sp - (uintptr_t)sp;
      } else {
        // A frame-size of 0 is used to indicate unknown frame size.
        sizes[n] = 0;
      }
#endif
      n++;
    }
    sp = next_sp;
  }
  return n;
}
