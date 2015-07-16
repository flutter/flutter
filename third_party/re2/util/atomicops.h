// Copyright 2006-2008 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#ifndef RE2_UTIL_ATOMICOPS_H__
#define RE2_UTIL_ATOMICOPS_H__

#if defined(__i386__)

static inline void WriteMemoryBarrier() {
  int x;
  __asm__ __volatile__("xchgl (%0),%0"  // The lock prefix is implicit for xchg.
                       :: "r" (&x));
}

#elif defined(__x86_64__)

// 64-bit implementations of memory barrier can be simpler, because
// "sfence" is guaranteed to exist.
static inline void WriteMemoryBarrier() {
  __asm__ __volatile__("sfence" : : : "memory");
}

#elif defined(__ppc__)

static inline void WriteMemoryBarrier() {
  __asm__ __volatile__("eieio" : : : "memory");
}

#elif defined(__alpha__)

static inline void WriteMemoryBarrier() {
  __asm__ __volatile__("wmb" : : : "memory");
}

#else

#include "util/mutex.h"

static inline void WriteMemoryBarrier() {
  // Slight overkill, but good enough:
  // any mutex implementation must have
  // a read barrier after the lock operation and
  // a write barrier before the unlock operation.
  //
  // It may be worthwhile to write architecture-specific
  // barriers for the common platforms, as above, but
  // this is a correct fallback.
  re2::Mutex mu;
  re2::MutexLock l(&mu);
}

/*
#error Need WriteMemoryBarrier for architecture.

// Windows
inline void WriteMemoryBarrier() {
  LONG x;
  ::InterlockedExchange(&x, 0);
}
*/

#endif

// Alpha has very weak memory ordering. If relying on WriteBarriers, must one
// use read barriers for the readers too.
#if defined(__alpha__)

static inline void MaybeReadMemoryBarrier() {
  __asm__ __volatile__("mb" : : : "memory");
}

#else

static inline void MaybeReadMemoryBarrier() {}

#endif // __alpha__

#endif  // RE2_UTIL_ATOMICOPS_H__
