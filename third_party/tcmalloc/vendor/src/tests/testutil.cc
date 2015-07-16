// Copyright (c) 2007, Google Inc.
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
// A few routines that are useful for multiple tests in this directory.

#include "config_for_unittests.h"
#include <stdlib.h>           // for NULL, abort()
// On FreeBSD, if you #include <sys/resource.h>, you have to get stdint first.
#ifdef HAVE_STDINT_H
#include <stdint.h>
#endif
#ifdef HAVE_SYS_RESOURCE_H
#include <sys/resource.h>
#endif
#include "tests/testutil.h"


// When compiled 64-bit and run on systems with swap several unittests will end
// up trying to consume all of RAM+swap, and that can take quite some time.  By
// limiting the address-space size we get sufficient coverage without blowing
// out job limits.
void SetTestResourceLimit() {
#ifdef HAVE_SYS_RESOURCE_H
  // The actual resource we need to set varies depending on which flavour of
  // unix.  On Linux we need RLIMIT_AS because that covers the use of mmap.
  // Otherwise hopefully RLIMIT_RSS is good enough.  (Unfortunately 64-bit
  // and 32-bit headers disagree on the type of these constants!)
#ifdef RLIMIT_AS
#define USE_RESOURCE RLIMIT_AS
#else
#define USE_RESOURCE RLIMIT_RSS
#endif

  // Restrict the test to 1GiB, which should fit comfortably well on both
  // 32-bit and 64-bit hosts, and executes in ~1s.
  const rlim_t kMaxMem = 1<<30;

  struct rlimit rlim;
  if (getrlimit(USE_RESOURCE, &rlim) == 0) {
    if (rlim.rlim_cur == RLIM_INFINITY || rlim.rlim_cur > kMaxMem) {
      rlim.rlim_cur = kMaxMem;
      setrlimit(USE_RESOURCE, &rlim); // ignore result
    }
  }
#endif  /* HAVE_SYS_RESOURCE_H */
}


struct FunctionAndId {
  void (*ptr_to_function)(int);
  int id;
};

#if defined(NO_THREADS) || !(defined(HAVE_PTHREAD) || defined(_WIN32))

extern "C" void RunThread(void (*fn)()) {
  (*fn)();
}

extern "C" void RunManyThreads(void (*fn)(), int count) {
  // I guess the best we can do is run fn sequentially, 'count' times
  for (int i = 0; i < count; i++)
    (*fn)();
}

extern "C" void RunManyThreadsWithId(void (*fn)(int), int count, int) {
  for (int i = 0; i < count; i++)
    (*fn)(i);    // stacksize doesn't make sense in a non-threaded context
}

#elif defined(_WIN32)

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN  /* We always want minimal includes */
#endif
#include <windows.h>

extern "C" {
  // This helper function has the signature that pthread_create wants.
  DWORD WINAPI RunFunctionInThread(LPVOID ptr_to_ptr_to_fn) {
    (**static_cast<void (**)()>(ptr_to_ptr_to_fn))();    // runs fn
    return 0;
  }

  DWORD WINAPI RunFunctionInThreadWithId(LPVOID ptr_to_fnid) {
    FunctionAndId* fn_and_id = static_cast<FunctionAndId*>(ptr_to_fnid);
    (*fn_and_id->ptr_to_function)(fn_and_id->id);   // runs fn
    return 0;
  }

  void RunManyThreads(void (*fn)(), int count) {
    DWORD dummy;
    HANDLE* hThread = new HANDLE[count];
    for (int i = 0; i < count; i++) {
      hThread[i] = CreateThread(NULL, 0, RunFunctionInThread, &fn, 0, &dummy);
      if (hThread[i] == NULL)  ExitProcess(i);
    }
    WaitForMultipleObjects(count, hThread, TRUE, INFINITE);
    for (int i = 0; i < count; i++) {
      CloseHandle(hThread[i]);
    }
    delete[] hThread;
  }

  void RunThread(void (*fn)()) {
    RunManyThreads(fn, 1);
  }

  void RunManyThreadsWithId(void (*fn)(int), int count, int stacksize) {
    DWORD dummy;
    HANDLE* hThread = new HANDLE[count];
    FunctionAndId* fn_and_ids = new FunctionAndId[count];
    for (int i = 0; i < count; i++) {
      fn_and_ids[i].ptr_to_function = fn;
      fn_and_ids[i].id = i;
      hThread[i] = CreateThread(NULL, stacksize, RunFunctionInThreadWithId,
                                &fn_and_ids[i], 0, &dummy);
      if (hThread[i] == NULL)  ExitProcess(i);
    }
    WaitForMultipleObjects(count, hThread, TRUE, INFINITE);
    for (int i = 0; i < count; i++) {
      CloseHandle(hThread[i]);
    }
    delete[] fn_and_ids;
    delete[] hThread;
  }
}

#else  // not NO_THREADS, not !HAVE_PTHREAD, not _WIN32

#include <pthread.h>

#define SAFE_PTHREAD(fncall)  do { if ((fncall) != 0) abort(); } while (0)

extern "C" {
  // This helper function has the signature that pthread_create wants.
  static void* RunFunctionInThread(void *ptr_to_ptr_to_fn) {
    (**static_cast<void (**)()>(ptr_to_ptr_to_fn))();    // runs fn
    return NULL;
  }

  static void* RunFunctionInThreadWithId(void *ptr_to_fnid) {
    FunctionAndId* fn_and_id = static_cast<FunctionAndId*>(ptr_to_fnid);
    (*fn_and_id->ptr_to_function)(fn_and_id->id);   // runs fn
    return NULL;
  }

  // Run a function in a thread of its own and wait for it to finish.
  // This is useful for tcmalloc testing, because each thread is
  // handled separately in tcmalloc, so there's interesting stuff to
  // test even if the threads are not running concurrently.
  void RunThread(void (*fn)()) {
    pthread_t thr;
    // Even though fn is on the stack, it's safe to pass a pointer to it,
    // because we pthread_join immediately (ie, before RunInThread exits).
    SAFE_PTHREAD(pthread_create(&thr, NULL, RunFunctionInThread, &fn));
    SAFE_PTHREAD(pthread_join(thr, NULL));
  }

  void RunManyThreads(void (*fn)(), int count) {
    pthread_t* thr = new pthread_t[count];
    for (int i = 0; i < count; i++) {
      SAFE_PTHREAD(pthread_create(&thr[i], NULL, RunFunctionInThread, &fn));
    }
    for (int i = 0; i < count; i++) {
      SAFE_PTHREAD(pthread_join(thr[i], NULL));
    }
    delete[] thr;
  }

  void RunManyThreadsWithId(void (*fn)(int), int count, int stacksize) {
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_attr_setstacksize(&attr, stacksize);

    pthread_t* thr = new pthread_t[count];
    FunctionAndId* fn_and_ids = new FunctionAndId[count];
    for (int i = 0; i < count; i++) {
      fn_and_ids[i].ptr_to_function = fn;
      fn_and_ids[i].id = i;
      SAFE_PTHREAD(pthread_create(&thr[i], &attr,
                                  RunFunctionInThreadWithId, &fn_and_ids[i]));
    }
    for (int i = 0; i < count; i++) {
      SAFE_PTHREAD(pthread_join(thr[i], NULL));
    }
    delete[] fn_and_ids;
    delete[] thr;

    pthread_attr_destroy(&attr);
  }
}

#endif
