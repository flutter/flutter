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
//
// Author: Sasha Levitskiy
// based on atomicops-internals by Sanjay Ghemawat
//
// This file is an internal atomic implementation, use base/atomicops.h instead.
//
// This code implements ARM atomics for architectures V6 and  newer.

#ifndef BASE_ATOMICOPS_INTERNALS_ARM_V6PLUS_H_
#define BASE_ATOMICOPS_INTERNALS_ARM_V6PLUS_H_

#include <stdio.h>
#include <stdlib.h>
#include "base/abort.h"
#include "base/basictypes.h"  // For COMPILE_ASSERT

// The LDREXD and STREXD instructions in ARM all v7 variants or above.  In v6,
// only some variants support it.  For simplicity, we only use exclusive
// 64-bit load/store in V7 or above.
#if defined(ARMV7)
# define BASE_ATOMICOPS_HAS_LDREXD_AND_STREXD
#endif

typedef int32_t Atomic32;

namespace base {
namespace subtle {

typedef int64_t Atomic64;

// 32-bit low-level ops

inline Atomic32 NoBarrier_CompareAndSwap(volatile Atomic32* ptr,
                                         Atomic32 old_value,
                                         Atomic32 new_value) {
  Atomic32 oldval, res;
  do {
    __asm__ __volatile__(
    "ldrex   %1, [%3]\n"
    "mov     %0, #0\n"
    "teq     %1, %4\n"
    // The following IT (if-then) instruction is needed for the subsequent
    // conditional instruction STREXEQ when compiling in THUMB mode.
    // In ARM mode, the compiler/assembler will not generate any code for it.
    "it      eq\n"
    "strexeq %0, %5, [%3]\n"
        : "=&r" (res), "=&r" (oldval), "+Qo" (*ptr)
        : "r" (ptr), "Ir" (old_value), "r" (new_value)
        : "cc");
  } while (res);
  return oldval;
}

inline Atomic32 NoBarrier_AtomicExchange(volatile Atomic32* ptr,
                                         Atomic32 new_value) {
  Atomic32 tmp, old;
  __asm__ __volatile__(
      "1:\n"
      "ldrex  %1, [%2]\n"
      "strex  %0, %3, [%2]\n"
      "teq    %0, #0\n"
      "bne    1b"
      : "=&r" (tmp), "=&r" (old)
      : "r" (ptr), "r" (new_value)
      : "cc", "memory");
  return old;
}

inline Atomic32 NoBarrier_AtomicIncrement(volatile Atomic32* ptr,
                                          Atomic32 increment) {
  Atomic32 tmp, res;
  __asm__ __volatile__(
      "1:\n"
      "ldrex  %1, [%2]\n"
      "add    %1, %1, %3\n"
      "strex  %0, %1, [%2]\n"
      "teq    %0, #0\n"
      "bne    1b"
      : "=&r" (tmp), "=&r"(res)
      : "r" (ptr), "r"(increment)
      : "cc", "memory");
  return res;
}

inline void MemoryBarrier() {
  __asm__ __volatile__("dmb" : : : "memory");
}

inline Atomic32 Barrier_AtomicIncrement(volatile Atomic32* ptr,
                                        Atomic32 increment) {
  Atomic32 tmp, res;
  __asm__ __volatile__(
      "1:\n"
      "ldrex  %1, [%2]\n"
      "add    %1, %1, %3\n"
      "dmb\n"
      "strex  %0, %1, [%2]\n"
      "teq    %0, #0\n"
      "bne    1b"
      : "=&r" (tmp), "=&r"(res)
      : "r" (ptr), "r"(increment)
      : "cc", "memory");
  return res;
}

inline Atomic32 Acquire_CompareAndSwap(volatile Atomic32* ptr,
                                       Atomic32 old_value,
                                       Atomic32 new_value) {
  Atomic32 value = NoBarrier_CompareAndSwap(ptr, old_value, new_value);
  MemoryBarrier();
  return value;
}

inline Atomic32 Release_CompareAndSwap(volatile Atomic32* ptr,
                                       Atomic32 old_value,
                                       Atomic32 new_value) {
  MemoryBarrier();
  return NoBarrier_CompareAndSwap(ptr, old_value, new_value);
}

inline void NoBarrier_Store(volatile Atomic32* ptr, Atomic32 value) {
  *ptr = value;
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

// 64-bit versions are only available if LDREXD and STREXD instructions
// are available.
#ifdef BASE_ATOMICOPS_HAS_LDREXD_AND_STREXD

#define BASE_HAS_ATOMIC64 1

inline Atomic64 NoBarrier_CompareAndSwap(volatile Atomic64* ptr,
                                         Atomic64 old_value,
                                         Atomic64 new_value) {
  Atomic64 oldval, res;
  do {
    __asm__ __volatile__(
    "ldrexd   %1, [%3]\n"
    "mov      %0, #0\n"
    "teq      %Q1, %Q4\n"
    // The following IT (if-then) instructions are needed for the subsequent
    // conditional instructions when compiling in THUMB mode.
    // In ARM mode, the compiler/assembler will not generate any code for it.
    "it       eq\n"
    "teqeq    %R1, %R4\n"
    "it       eq\n"
    "strexdeq %0, %5, [%3]\n"
        : "=&r" (res), "=&r" (oldval), "+Q" (*ptr)
        : "r" (ptr), "Ir" (old_value), "r" (new_value)
        : "cc");
  } while (res);
  return oldval;
}

inline Atomic64 NoBarrier_AtomicExchange(volatile Atomic64* ptr,
                                         Atomic64 new_value) {
  int store_failed;
  Atomic64 old;
  __asm__ __volatile__(
      "1:\n"
      "ldrexd  %1, [%2]\n"
      "strexd  %0, %3, [%2]\n"
      "teq     %0, #0\n"
      "bne     1b"
      : "=&r" (store_failed), "=&r" (old)
      : "r" (ptr), "r" (new_value)
      : "cc", "memory");
  return old;
}

inline Atomic64 NoBarrier_AtomicIncrement(volatile Atomic64* ptr,
                                          Atomic64 increment) {
  int store_failed;
  Atomic64 res;
  __asm__ __volatile__(
      "1:\n"
      "ldrexd  %1, [%2]\n"
      "adds    %Q1, %Q1, %Q3\n"
      "adc     %R1, %R1, %R3\n"
      "strexd  %0, %1, [%2]\n"
      "teq     %0, #0\n"
      "bne     1b"
      : "=&r" (store_failed), "=&r"(res)
      : "r" (ptr), "r"(increment)
      : "cc", "memory");
  return res;
}

inline Atomic64 Barrier_AtomicIncrement(volatile Atomic64* ptr,
                                        Atomic64 increment) {
  int store_failed;
  Atomic64 res;
  __asm__ __volatile__(
      "1:\n"
      "ldrexd  %1, [%2]\n"
      "adds    %Q1, %Q1, %Q3\n"
      "adc     %R1, %R1, %R3\n"
      "dmb\n"
      "strexd  %0, %1, [%2]\n"
      "teq     %0, #0\n"
      "bne     1b"
      : "=&r" (store_failed), "=&r"(res)
      : "r" (ptr), "r"(increment)
      : "cc", "memory");
  return res;
}

inline void NoBarrier_Store(volatile Atomic64* ptr, Atomic64 value) {
  int store_failed;
  Atomic64 dummy;
  __asm__ __volatile__(
      "1:\n"
      // Dummy load to lock cache line.
      "ldrexd  %1, [%3]\n"
      "strexd  %0, %2, [%3]\n"
      "teq     %0, #0\n"
      "bne     1b"
      : "=&r" (store_failed), "=&r"(dummy)
      : "r"(value), "r" (ptr)
      : "cc", "memory");
}

inline Atomic64 NoBarrier_Load(volatile const Atomic64* ptr) {
  Atomic64 res;
  __asm__ __volatile__(
  "ldrexd   %0, [%1]\n"
  "clrex\n"
      : "=r" (res)
      : "r"(ptr), "Q"(*ptr));
  return res;
}

#else // BASE_ATOMICOPS_HAS_LDREXD_AND_STREXD

inline void NotImplementedFatalError(const char *function_name) {
  fprintf(stderr, "64-bit %s() not implemented on this platform\n",
          function_name);
  tcmalloc::Abort();
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

inline Atomic64 NoBarrier_Load(volatile const Atomic64* ptr) {
  NotImplementedFatalError("NoBarrier_Load");
  return 0;
}

#endif // BASE_ATOMICOPS_HAS_LDREXD_AND_STREXD

inline void Acquire_Store(volatile Atomic64* ptr, Atomic64 value) {
  NoBarrier_Store(ptr, value);
  MemoryBarrier();
}

inline void Release_Store(volatile Atomic64* ptr, Atomic64 value) {
  MemoryBarrier();
  NoBarrier_Store(ptr, value);
}

inline Atomic64 Acquire_Load(volatile const Atomic64* ptr) {
  Atomic64 value = NoBarrier_Load(ptr);
  MemoryBarrier();
  return value;
}

inline Atomic64 Release_Load(volatile const Atomic64* ptr) {
  MemoryBarrier();
  return NoBarrier_Load(ptr);
}

inline Atomic64 Acquire_CompareAndSwap(volatile Atomic64* ptr,
                                       Atomic64 old_value,
                                       Atomic64 new_value) {
  Atomic64 value = NoBarrier_CompareAndSwap(ptr, old_value, new_value);
  MemoryBarrier();
  return value;
}

inline Atomic64 Release_CompareAndSwap(volatile Atomic64* ptr,
                                       Atomic64 old_value,
                                       Atomic64 new_value) {
  MemoryBarrier();
  return NoBarrier_CompareAndSwap(ptr, old_value, new_value);
}

}  // namespace subtle ends
}  // namespace base ends

#endif  // BASE_ATOMICOPS_INTERNALS_ARM_V6PLUS_H_
