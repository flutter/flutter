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
//
// Produce stack trace.
//
// There are three different ways we can try to get the stack trace:
//
// 1) Our hand-coded stack-unwinder.  This depends on a certain stack
//    layout, which is used by gcc (and those systems using a
//    gcc-compatible ABI) on x86 systems, at least since gcc 2.95.
//    It uses the frame pointer to do its work.
//
// 2) The libunwind library.  This is still in development, and as a
//    separate library adds a new dependency, abut doesn't need a frame
//    pointer.  It also doesn't call malloc.
//
// 3) The gdb unwinder -- also the one used by the c++ exception code.
//    It's obviously well-tested, but has a fatal flaw: it can call
//    malloc() from the unwinder.  This is a problem because we're
//    trying to use the unwinder to instrument malloc().
//
// Note: if you add a new implementation here, make sure it works
// correctly when GetStackTrace() is called with max_depth == 0.
// Some code may do that.

#include <config.h>
#include <gperftools/stacktrace.h>
#include "stacktrace_config.h"

#if defined(STACKTRACE_INL_HEADER)

#define IS_STACK_FRAMES 0
#define IS_WITH_CONTEXT 0
#define GET_STACK_TRACE_OR_FRAMES \
   GetStackTrace(void **result, int max_depth, int skip_count)
#include STACKTRACE_INL_HEADER
#undef IS_STACK_FRAMES
#undef IS_WITH_CONTEXT
#undef GET_STACK_TRACE_OR_FRAMES

#define IS_STACK_FRAMES 1
#define IS_WITH_CONTEXT 0
#define GET_STACK_TRACE_OR_FRAMES \
  GetStackFrames(void **result, int *sizes, int max_depth, int skip_count)
#include STACKTRACE_INL_HEADER
#undef IS_STACK_FRAMES
#undef IS_WITH_CONTEXT
#undef GET_STACK_TRACE_OR_FRAMES

#define IS_STACK_FRAMES 0
#define IS_WITH_CONTEXT 1
#define GET_STACK_TRACE_OR_FRAMES \
  GetStackTraceWithContext(void **result, int max_depth, \
                           int skip_count, const void *ucp)
#include STACKTRACE_INL_HEADER
#undef IS_STACK_FRAMES
#undef IS_WITH_CONTEXT
#undef GET_STACK_TRACE_OR_FRAMES

#define IS_STACK_FRAMES 1
#define IS_WITH_CONTEXT 1
#define GET_STACK_TRACE_OR_FRAMES \
  GetStackFramesWithContext(void **result, int *sizes, int max_depth, \
                            int skip_count, const void *ucp)
#include STACKTRACE_INL_HEADER
#undef IS_STACK_FRAMES
#undef IS_WITH_CONTEXT
#undef GET_STACK_TRACE_OR_FRAMES

#elif 0
// This is for the benefit of code analysis tools that may have
// trouble with the computed #include above.
# include "stacktrace_x86-inl.h"
# include "stacktrace_libunwind-inl.h"
# include "stacktrace_generic-inl.h"
# include "stacktrace_powerpc-inl.h"
# include "stacktrace_win32-inl.h"
# include "stacktrace_arm-inl.h"
#else
# error Cannot calculate stack trace: will need to write for your environment
#endif
