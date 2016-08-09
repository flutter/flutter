// Copyright (c) 2012, Google Inc.
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
// Author: Craig Silverstein
//
// This just verifies that we can compile code that #includes stuff
// via the backwards-compatibility 'google/' #include-dir.  It does
// not include config.h on purpose, to better simulate a perftools
// client.

#include <stddef.h>
#include <stdio.h>
#include <google/heap-checker.h>
#include <google/heap-profiler.h>
#include <google/malloc_extension.h>
#include <google/malloc_extension_c.h>
#include <google/malloc_hook.h>
#include <google/malloc_hook_c.h>
#include <google/profiler.h>
#include <google/stacktrace.h>
#include <google/tcmalloc.h>

// We don't link in -lprofiler for this test, so be sure not to make
// any function calls that require the cpu-profiler code.  The
// heap-profiler is ok.

HeapLeakChecker::Disabler* heap_checker_h;
void (*heap_profiler_h)(const char*) = &HeapProfilerStart;
MallocExtension::Ownership malloc_extension_h;
MallocExtension_Ownership malloc_extension_c_h;
MallocHook::NewHook* malloc_hook_h;
MallocHook_NewHook* malloc_hook_c_h;
ProfilerOptions* profiler_h;
int (*stacktrace_h)(void**, int, int) = &GetStackTrace;
void* (*tcmalloc_h)(size_t) = &tc_new;

int main(int argc, char** argv) {
  printf("PASS\n");
  return 0;
}
