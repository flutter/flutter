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
// Figure out which unwinder to use on a given platform.
//
// Defines STACKTRACE_INL_HEADER to the *-inl.h containing
// actual unwinder implementation.
//
// Defines STACKTRACE_SKIP_CONTEXT_ROUTINES if a separate
// GetStack{Trace,Frames}WithContext should not be provided.
//
// This header is "private" to stacktrace.cc and
// stacktrace_with_context.cc.
//
// DO NOT include it into any other files.

#ifndef BASE_STACKTRACE_CONFIG_H_
#define BASE_STACKTRACE_CONFIG_H_

// First, the i386 and x86_64 case.
#if (defined(__i386__) || defined(__x86_64__)) && __GNUC__ >= 2
# if !defined(NO_FRAME_POINTER)
#   define STACKTRACE_INL_HEADER "stacktrace_x86-inl.h"
#   define STACKTRACE_SKIP_CONTEXT_ROUTINES 1
# elif defined(HAVE_LIBUNWIND_H)  // a proxy for having libunwind installed
#   define STACKTRACE_INL_HEADER "stacktrace_libunwind-inl.h"
#   define STACKTRACE_USES_LIBUNWIND 1
# elif defined(__linux)
#   error Cannnot calculate stack trace: need either libunwind or frame-pointers (see INSTALL file)
# else
#   error Cannnot calculate stack trace: need libunwind (see INSTALL file)
# endif

// The PowerPC case
#elif (defined(__ppc__) || defined(__PPC__)) && __GNUC__ >= 2
# if !defined(NO_FRAME_POINTER)
#   define STACKTRACE_INL_HEADER "stacktrace_powerpc-inl.h"
# else
#   define STACKTRACE_INL_HEADER "stacktrace_generic-inl.h"
# endif

// The Android case
#elif defined(__ANDROID__)
#define STACKTRACE_INL_HEADER "stacktrace_android-inl.h"

// The ARM case
#elif defined(__arm__)  && __GNUC__ >= 2
# if !defined(NO_FRAME_POINTER)
#   define STACKTRACE_INL_HEADER "stacktrace_arm-inl.h"
# else
#   error stacktrace without frame pointer is not supported on ARM
# endif

// The Windows case -- probably cygwin and mingw will use one of the
// x86-includes above, but if not, we can fall back to windows intrinsics.
#elif defined(_WIN32) || defined(__CYGWIN__) || defined(__CYGWIN32__) || defined(__MINGW32__)
# define STACKTRACE_INL_HEADER "stacktrace_win32-inl.h"

#endif  // all the cases
#endif  // BASE_STACKTRACE_CONFIG_H_
