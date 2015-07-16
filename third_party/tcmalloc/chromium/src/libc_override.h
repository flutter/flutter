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
// Author: Craig Silverstein <opensource@google.com>
//
// This .h file imports the code that causes tcmalloc to override libc
// versions of malloc/free/new/delete/etc.  That is, it provides the
// logic that makes it so calls to malloc(10) go through tcmalloc,
// rather than the default (libc) malloc.
//
// This file also provides a method: ReplaceSystemAlloc(), that every
// libc_override_*.h file it #includes is required to provide.  This
// is called when first setting up tcmalloc -- that is, when a global
// constructor in tcmalloc.cc is executed -- to do any initialization
// work that may be required for this OS.  (Note we cannot entirely
// control when tcmalloc is initialized, and the system may do some
// mallocs and frees before this routine is called.)  It may be a
// noop.
//
// Every libc has its own way of doing this, and sometimes the compiler
// matters too, so we have a different file for each libc, and often
// for different compilers and OS's.

#ifndef TCMALLOC_LIBC_OVERRIDE_INL_H_
#define TCMALLOC_LIBC_OVERRIDE_INL_H_

#include <config.h>
#ifdef HAVE_FEATURES_H
#include <features.h>   // for __GLIBC__
#endif
#include <gperftools/tcmalloc.h>

static void ReplaceSystemAlloc();  // defined in the .h files below

// For windows, there are two ways to get tcmalloc.  If we're
// patching, then src/windows/patch_function.cc will do the necessary
// overriding here.  Otherwise, we doing the 'redefine' trick, where
// we remove malloc/new/etc from mscvcrt.dll, and just need to define
// them now.
#if defined(_WIN32) && defined(WIN32_DO_PATCHING)
void PatchWindowsFunctions();   // in src/windows/patch_function.cc
static void ReplaceSystemAlloc() { PatchWindowsFunctions(); }

#elif defined(_WIN32) && !defined(WIN32_DO_PATCHING)
// "libc_override_redefine.h" is included in the original gperftools.  But,
// we define allocator functions in Chromium's base/allocator/allocator_shim.cc
// on Windows.  We don't include libc_override_redefine.h here.
// ReplaceSystemAlloc() is defined here instead.
static void ReplaceSystemAlloc() { }

#elif defined(__APPLE__)
#include "libc_override_osx.h"

#elif defined(__GLIBC__)
#include "libc_override_glibc.h"

// Not all gcc systems necessarily support weak symbols, but all the
// ones I know of do, so for now just assume they all do.
#elif defined(__GNUC__)
#include "libc_override_gcc_and_weak.h"

#else
#error Need to add support for your libc/OS here

#endif

#endif  // TCMALLOC_LIBC_OVERRIDE_INL_H_
