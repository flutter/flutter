// Copyright (c) 2008, Google Inc.
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
//
// ---
// Produces a stack trace for Windows.  Normally, one could use
// stacktrace_x86-inl.h or stacktrace_x86_64-inl.h -- and indeed, that
// should work for binaries compiled using MSVC in "debug" mode.
// However, in "release" mode, Windows uses frame-pointer
// optimization, which makes getting a stack trace very difficult.
//
// There are several approaches one can take.  One is to use Windows
// intrinsics like StackWalk64.  These can work, but have restrictions
// on how successful they can be.  Another attempt is to write a
// version of stacktrace_x86-inl.h that has heuristic support for
// dealing with FPO, similar to what WinDbg does (see
// http://www.nynaeve.net/?p=97).
//
// The solution we've ended up doing is to call the undocumented
// windows function RtlCaptureStackBackTrace, which probably doesn't
// work with FPO but at least is fast, and doesn't require a symbol
// server.
//
// This code is inspired by a patch from David Vitek:
//   http://code.google.com/p/gperftools/issues/detail?id=83

#ifndef BASE_STACKTRACE_WIN32_INL_H_
#define BASE_STACKTRACE_WIN32_INL_H_
// Note: this file is included into stacktrace.cc more than once.
// Anything that should only be defined once should be here:

#include "config.h"
#include <windows.h>    // for GetProcAddress and GetModuleHandle
#include <assert.h>

typedef USHORT NTAPI RtlCaptureStackBackTrace_Function(
    IN ULONG frames_to_skip,
    IN ULONG frames_to_capture,
    OUT PVOID *backtrace,
    OUT PULONG backtrace_hash);

// Load the function we need at static init time, where we don't have
// to worry about someone else holding the loader's lock.
static RtlCaptureStackBackTrace_Function* const RtlCaptureStackBackTrace_fn =
   (RtlCaptureStackBackTrace_Function*)
   GetProcAddress(GetModuleHandleA("ntdll.dll"), "RtlCaptureStackBackTrace");

PERFTOOLS_DLL_DECL int GetStackTrace(void** result, int max_depth,
                                     int skip_count) {
  if (!RtlCaptureStackBackTrace_fn) {
    // TODO(csilvers): should we log an error here?
    return 0;     // can't find a stacktrace with no function to call
  }
  return (int)RtlCaptureStackBackTrace_fn(skip_count + 2, max_depth,
                                          result, 0);
}

PERFTOOLS_DLL_DECL int GetStackFrames(void** /* pcs */,
                                      int* /* sizes */,
                                      int /* max_depth */,
                                      int /* skip_count */) {
  assert(0 == "Not yet implemented");
  return 0;
}

#endif  // BASE_STACKTRACE_WIN32_INL_H_
