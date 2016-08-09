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
// Used to override malloc routines on systems that are using glibc.

#ifndef TCMALLOC_LIBC_OVERRIDE_GLIBC_INL_H_
#define TCMALLOC_LIBC_OVERRIDE_GLIBC_INL_H_

// MALLOC_HOOK_MAYBE_VOLATILE is defined at config.h in the original gperftools.
// Chromium does this check with the macro __MALLOC_HOOK_VOLATILE.
// GLibc 2.14+ requires the hook functions be declared volatile, based on the
// value of the define __MALLOC_HOOK_VOLATILE. For compatibility with
// older/non-GLibc implementations, provide an empty definition.
#if !defined(__MALLOC_HOOK_VOLATILE)
#define MALLOC_HOOK_MAYBE_VOLATILE /**/
#else
#define MALLOC_HOOK_MAYBE_VOLATILE __MALLOC_HOOK_VOLATILE
#endif

#include <config.h>
#include <features.h>     // for __GLIBC__
#ifdef HAVE_SYS_CDEFS_H
#include <sys/cdefs.h>    // for __THROW
#endif
#include <gperftools/tcmalloc.h>

#ifndef __GLIBC__
# error libc_override_glibc.h is for glibc distributions only.
#endif

// In glibc, the memory-allocation methods are weak symbols, so we can
// just override them with our own.  If we're using gcc, we can use
// __attribute__((alias)) to do the overriding easily (exception:
// Mach-O, which doesn't support aliases).  Otherwise we have to use a
// function call.
#if !defined(__GNUC__) || defined(__MACH__)

// This also defines ReplaceSystemAlloc().
# include "libc_override_redefine.h"  // defines functions malloc()/etc

#else  // #if !defined(__GNUC__) || defined(__MACH__)

// If we get here, we're a gcc system, so do all the overriding we do
// with gcc.  This does the overriding of all the 'normal' memory
// allocation.  This also defines ReplaceSystemAlloc().
# include "libc_override_gcc_and_weak.h"

// We also have to do some glibc-specific overriding.  Some library
// routines on RedHat 9 allocate memory using malloc() and free it
// using __libc_free() (or vice-versa).  Since we provide our own
// implementations of malloc/free, we need to make sure that the
// __libc_XXX variants (defined as part of glibc) also point to the
// same implementations.  Since it only matters for redhat, we
// do it inside the gcc #ifdef, since redhat uses gcc.
// TODO(csilvers): only do this if we detect we're an old enough glibc?

#define ALIAS(tc_fn)   __attribute__ ((alias (#tc_fn)))
extern "C" {
  void* __libc_malloc(size_t size)                ALIAS(tc_malloc);
  void __libc_free(void* ptr)                     ALIAS(tc_free);
  void* __libc_realloc(void* ptr, size_t size)    ALIAS(tc_realloc);
  void* __libc_calloc(size_t n, size_t size)      ALIAS(tc_calloc);
  void __libc_cfree(void* ptr)                    ALIAS(tc_cfree);
  void* __libc_memalign(size_t align, size_t s)   ALIAS(tc_memalign);
  void* __libc_valloc(size_t size)                ALIAS(tc_valloc);
  void* __libc_pvalloc(size_t size)               ALIAS(tc_pvalloc);
  int __posix_memalign(void** r, size_t a, size_t s)  ALIAS(tc_posix_memalign);
}   // extern "C"
#undef ALIAS

#endif  // #if defined(__GNUC__) && !defined(__MACH__)


// We also have to hook libc malloc.  While our work with weak symbols
// should make sure libc malloc is never called in most situations, it
// can be worked around by shared libraries with the DEEPBIND
// environment variable set.  The below hooks libc to call our malloc
// routines even in that situation.  In other situations, this hook
// should never be called.
extern "C" {
static void* glibc_override_malloc(size_t size, const void *caller) {
  return tc_malloc(size);
}
static void* glibc_override_realloc(void *ptr, size_t size,
                                    const void *caller) {
  return tc_realloc(ptr, size);
}
static void glibc_override_free(void *ptr, const void *caller) {
  tc_free(ptr);
}
static void* glibc_override_memalign(size_t align, size_t size,
                                     const void *caller) {
  return tc_memalign(align, size);
}

// We should be using __malloc_initialize_hook here, like the #if 0
// code below.  (See http://swoolley.org/man.cgi/3/malloc_hook.)
// However, this causes weird linker errors with programs that link
// with -static, so instead we just assign the vars directly at
// static-constructor time.  That should serve the same effect of
// making sure the hooks are set before the first malloc call the
// program makes.
#if 0
#include <malloc.h>  // for __malloc_hook, etc.
void glibc_override_malloc_init_hook(void) {
  __malloc_hook = glibc_override_malloc;
  __realloc_hook = glibc_override_realloc;
  __free_hook = glibc_override_free;
  __memalign_hook = glibc_override_memalign;
}

void (* MALLOC_HOOK_MAYBE_VOLATILE __malloc_initialize_hook)(void)
    = &glibc_override_malloc_init_hook;
#endif

void* (* MALLOC_HOOK_MAYBE_VOLATILE __malloc_hook)(size_t, const void*)
    = &glibc_override_malloc;
void* (* MALLOC_HOOK_MAYBE_VOLATILE __realloc_hook)(void*, size_t, const void*)
    = &glibc_override_realloc;
void (* MALLOC_HOOK_MAYBE_VOLATILE __free_hook)(void*, const void*)
    = &glibc_override_free;
void* (* MALLOC_HOOK_MAYBE_VOLATILE __memalign_hook)(size_t,size_t, const void*)
    = &glibc_override_memalign;

}   // extern "C"

// No need to write ReplaceSystemAlloc(); one of the #includes above
// did it for us.

#endif  // TCMALLOC_LIBC_OVERRIDE_GLIBC_INL_H_
