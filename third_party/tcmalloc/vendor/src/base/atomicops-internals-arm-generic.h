// Copyright (c) 2003, Google Inc.
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
//
// Author: Lei Zhang, Sasha Levitskiy
//
// This file is an internal atomic implementation, use base/atomicops.h instead.
//
// LinuxKernelCmpxchg and Barrier_AtomicIncrement are from Google Gears.

#ifndef BASE_ATOMICOPS_INTERNALS_ARM_GENERIC_H_
#define BASE_ATOMICOPS_INTERNALS_ARM_GENERIC_H_

#include <stdio.h>
#include <stdlib.h>
#include "base/basictypes.h"

typedef int32_t Atomic32;

namespace base {
namespace subtle {

typedef int64_t Atomic64;

// 0xffff0fc0 is the hard coded address of a function provided by
// the kernel which implements an atomic compare-exchange. On older
// ARM architecture revisions (pre-v6) this may be implemented using
// a syscall. This address is stable, and in active use (hard coded)
// by at least glibc-2.7 and the Android C library.
// pLinuxKernelCmpxchg has both acquire and release barrier sematincs.
typedef Atomic32 (*LinuxKernelCmpxchgFunc)(Atomic32 old_value,
                                           Atomic32 new_value,
                                           volatile Atomic32* ptr);
LinuxKernelCmpxchgFunc pLinuxKernelCmpxchg ATTRIBUTE_WEAK =
    (LinuxKernelCmpxchgFunc) 0xffff0fc0;

typedef void (*LinuxKernelMemoryBarrierFunc)(void);
LinuxKernelMemoryBarrierFunc pLinuxKernelMemoryBarrier ATTRIBUTE_WEAK =
    (LinuxKernelMemoryBarrierFunc) 0xffff0fa0;


inline Atomic32 NoBarrier_CompareAndSwap(volatile Atomic32* ptr,
                                         Atomic32 old_value,
                                         Atomic32 new_value) {
  Atomic32 prev_value = *ptr;
  do {
    if (!pLinuxKernelCmpxchg(old_value, new_value,
                             const_cast<Atomic32*>(ptr))) {
      return old_value;
    }
    prev_value = *ptr;
  } while (prev_value == old_value);
  return prev_value;
}

inline Atomic32 NoBarrier_AtomicExchange(volatile Atomic32* ptr,
                                         Atomic32 new_value) {
  Atomic32 old_value;
  do {
    old_value = *ptr;
  } while (pLinuxKernelCmpxchg(old_value, new_value,
                               const_cast<Atomic32*>(ptr)));
  return old_value;
}

inline Atomic32 Barrier_AtomicIncrement(volatile Atomic32* ptr,
                                        Atomic32 increment) {
  for (;;) {
    // Atomic exchange the old value with an incremented one.
    Atomic32 old_value = *ptr;
    Atomic32 new_value = old_value + increment;
    if (pLinuxKernelCmpxchg(old_value, new_value,
                            const_cast<Atomic32*>(ptr)) == 0) {
      // The exchange took place as expected.
      return new_value;
    }
    // Otherwise, *ptr changed mid-loop and we need to retry.
  }
}

inline Atomic32 NoBarrier_AtomicIncrement(volatile Atomic32* ptr,
                                          Atomic32 increment) {
  return Barrier_AtomicIncrement(ptr, increment);
}

inline Atomic32 Acquire_CompareAndSwap(volatile Atomic32* ptr,
                                       Atomic32 old_value,
                                       Atomic32 new_value) {
  return NoBarrier_CompareAndSwap(ptr, old_value, new_value);
}

inline Atomic32 Release_CompareAndSwap(volatile Atomic32* ptr,
                                       Atomic32 old_value,
                                       Atomic32 new_value) {
  return NoBarrier_CompareAndSwap(ptr, old_value, new_value);
}

inline void NoBarrier_Store(volatile Atomic32* ptr, Atomic32 value) {
  *ptr = value;
}

inline void MemoryBarrier() {
  pLinuxKernelMemoryBarrier();
}

inline void Acquire_Store(volatile Atomic32* ptr, Atomic32 value) {
  *ptr = value;
  MemoryBarrier();
}

inline void Release_Store(volatile Atomic32* ptr, Atomic32 value) {
  MemoryBarrier();
  *ptr = value;
}

inline Atomic32 NoBarrier_Load(volatile const Atomic32* ptr) {
  return *ptr;
}

inline Atomic32 Acquire_Load(volatile const Atomic32* ptr) {
  Atomic32 value = *ptr;
  MemoryBarrier();
  return value;
}

inline Atomic32 Release_Load(volatile const Atomic32* ptr) {
  MemoryBarrier();
  return *ptr;
}


// 64-bit versions are not implemented yet.

inline void NotImplementedFatalError(const char *function_name) {
  fprintf(stderr, "64-bit %s() not implemented on this platform\n",
          function_name);
  abort();
}

inline Atomic64 NoBarrier_CompareAndSwap(volatile Atomic64* ptr,
                                         Atomic64 old_value,
                                         Atomic64 new_value) {
  NotImplementedFatalError("NoBarrier_CompareAndSwap");
  return 0;
}

inline Atomic64 NoBarrier_AtomicExchange(volatile Atomic64* ptr,
                                         Atomic64 new_value) {
  NotImplementedFatalError("NoBarrier_AtomicExchange");
  return 0;
}

inline Atomic64 NoBarrier_AtomicIncrement(volatile Atomic64* ptr,
                                          Atomic64 increment) {
  NotImplementedFatalError("NoBarrier_AtomicIncrement");
  return 0;
}

inline Atomic64 Barrier_AtomicIncrement(volatile Atomic64* ptr,
                                        Atomic64 increment) {
  NotImplementedFatalError("Barrier_AtomicIncrement");
  return 0;
}

inline void NoBarrier_Store(volatile Atomic64* ptr, Atomic64 value) {
  NotImplementedFatalError("NoBarrier_Store");
}

inline void Acquire_Store(volatile Atomic64* ptr, Atomic64 value) {
  NotImplementedFatalError("Acquire_Store64");
}

inline void Release_Store(volatile Atomic64* ptr, Atomic64 value) {
  NotImplementedFatalError("Release_Store");
}

inline Atomic64 NoBarrier_Load(volatile const Atomic64* ptr) {
  NotImplementedFatalError("NoBarrier_Load");
  return 0;
}

inline Atomic64 Acquire_Load(volatile const Atomic64* ptr) {
  NotImplementedFatalError("Atomic64 Acquire_Load");
  return 0;
}

inline Atomic64 Release_Load(volatile const Atomic64* ptr) {
  NotImplementedFatalError("Atomic64 Release_Load");
  return 0;
}

inline Atomic64 Acquire_CompareAndSwap(volatile Atomic64* ptr,
                                       Atomic64 old_value,
                                       Atomic64 new_value) {
  NotImplementedFatalError("Atomic64 Acquire_CompareAndSwap");
  return 0;
}

inline Atomic64 Release_CompareAndSwap(volatile Atomic64* ptr,
                                       Atomic64 old_value,
                                       Atomic64 new_value) {
  NotImplementedFatalError("Atomic64 Release_CompareAndSwap");
  return 0;
}

}  // namespace base::subtle
}  // namespace base

#endif  // BASE_ATOMICOPS_INTERNALS_ARM_GENERIC_H_
