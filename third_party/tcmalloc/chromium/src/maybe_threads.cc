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
// Author: Paul Menage <opensource@google.com>
//
// Some wrappers for pthread functions so that we can be LD_PRELOADed
// against non-pthreads apps.
//
// This module will behave very strangely if some pthreads functions
// exist and others don't.

#include "config.h"
#include <assert.h>
#include <string.h>    // for memcmp
#include <stdio.h>     // for __isthreaded on FreeBSD
// We don't actually need strings. But including this header seems to
// stop the compiler trying to short-circuit our pthreads existence
// tests and claiming that the address of a function is always
// non-zero. I have no idea why ...
#include <string>
#include "maybe_threads.h"
#include "base/basictypes.h"

// __THROW is defined in glibc systems.  It means, counter-intuitively,
// "This function will never throw an exception."  It's an optional
// optimization tool, but we may need to use it to match glibc prototypes.
#ifndef __THROW    // I guess we're not on a glibc system
# define __THROW   // __THROW is just an optimization, so ok to make it ""
#endif

// These are the methods we're going to conditionally include.
extern "C" {
  int pthread_key_create (pthread_key_t*, void (*)(void*))
      __THROW ATTRIBUTE_WEAK;
  void *pthread_getspecific(pthread_key_t)
      __THROW ATTRIBUTE_WEAK;
  int pthread_setspecific(pthread_key_t, const void*)
      __THROW ATTRIBUTE_WEAK;
  int pthread_once(pthread_once_t *, void (*)(void))
      ATTRIBUTE_WEAK;
}

#define MAX_PERTHREAD_VALS 16
static void *perftools_pthread_specific_vals[MAX_PERTHREAD_VALS];
static int next_key;

int perftools_pthread_key_create(pthread_key_t *key,
                                 void (*destr_function) (void *)) {
  if (pthread_key_create) {
    return pthread_key_create(key, destr_function);
  } else {
    assert(next_key < MAX_PERTHREAD_VALS);
    *key = (pthread_key_t)(next_key++);
    return 0;
  }
}

void *perftools_pthread_getspecific(pthread_key_t key) {
  if (pthread_getspecific) {
    return pthread_getspecific(key);
  } else {
    return perftools_pthread_specific_vals[(int)key];
  }
}

int perftools_pthread_setspecific(pthread_key_t key, void *val) {
  if (pthread_setspecific) {
    return pthread_setspecific(key, val);
  } else {
    perftools_pthread_specific_vals[(int)key] = val;
    return 0;
  }
}


static pthread_once_t pthread_once_init = PTHREAD_ONCE_INIT;
int perftools_pthread_once(pthread_once_t *ctl,
                           void  (*init_routine) (void)) {
#ifdef __FreeBSD__
  // On __FreeBSD__, calling pthread_once on a system that is not
  // linked with -pthread is silently a noop. :-( Luckily, we have a
  // workaround: FreeBSD exposes __isthreaded in <stdio.h>, which is
  // set to 1 when the first thread is spawned.  So on those systems,
  // we can use our own separate pthreads-once mechanism, which is
  // used until __isthreaded is 1 (which will never be true if the app
  // is not linked with -pthread).
  static bool pthread_once_ran_before_threads = false;
  if (pthread_once_ran_before_threads) {
    return 0;
  }
  if (!__isthreaded) {
    init_routine();
    pthread_once_ran_before_threads = true;
    return 0;
  }
#elif defined(__ANDROID__)
  // Android >= 2.3 (GB) always implement pthread_once.
  return pthread_once(ctl, init_routine);
#else
  if (pthread_once) {
    return pthread_once(ctl, init_routine);
  } else {
    if (memcmp(ctl, &pthread_once_init, sizeof(*ctl)) == 0) {
      init_routine();
      ++*(char*)(ctl);        // make it so it's no longer equal to init
    }
    return 0;
  }
#endif
}
