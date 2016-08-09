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
// Author: Paul Pluzhnikov
//
// This code logically belongs in stacktrace.cc, but
// it is moved into (this) separate file in order to
// prevent inlining of routines defined here.
//
// Inlining causes skip_count to be incorrect, and there
// is no portable way to prevent it.
//
// Eventually LTO (link-time optimization) and/or LLVM
// may inline this code anyway. Let's hope they respect
// ATTRIBUTE_NOINLINE.

#include <config.h>
#include <gperftools/stacktrace.h>
#include "stacktrace_config.h"
#include "base/basictypes.h"

#if !defined(STACKTRACE_SKIP_CONTEXT_ROUTINES)
ATTRIBUTE_NOINLINE PERFTOOLS_DLL_DECL
int GetStackFramesWithContext(void** pcs, int* sizes, int max_depth,
                              int skip_count, const void * /* uc */) {
  return GetStackFrames(pcs, sizes, max_depth, skip_count + 1);
}

ATTRIBUTE_NOINLINE PERFTOOLS_DLL_DECL
int GetStackTraceWithContext(void** result, int max_depth,
                             int skip_count, const void * /* uc */) {
  return GetStackTrace(result, max_depth, skip_count + 1);
}
#endif
