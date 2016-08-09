/* Copyright (c) 2006, Google Inc.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ---
 * Author: Sanjay Ghemawat
 */

// For atomic operations on statistics counters, see atomic_stats_counter.h.
// For atomic operations on sequence numbers, see atomic_sequence_num.h.
// For atomic operations on reference counts, see atomic_refcount.h.

// Some fast atomic operations -- typically with machine-dependent
// implementations.  This file may need editing as Google code is
// ported to different architectures.

// The routines exported by this module are subtle.  If you use them, even if
// you get the code right, it will depend on careful reasoning about atomicity
// and memory ordering; it will be less readable, and harder to maintain.  If
// you plan to use these routines, you should have a good reason, such as solid
// evidence that performance would otherwise suffer, or there being no
// alternative.  You should assume only properties explicitly guaranteed by the
// specifications in this file.  You are almost certainly _not_ writing code
// just for the x86; if you assume x86 semantics, x86 hardware bugs and
// implementations on other archtectures will cause your code to break.  If you
// do not know what you are doing, avoid these routines, and use a Mutex.
//
// It is incorrect to make direct assignments to/from an atomic variable.
// You should use one of the Load or Store routines.  The NoBarrier
// versions are provided when no barriers are needed:
//   NoBarrier_Store()
//   NoBarrier_Load()
// Although there are currently no compiler enforcement, you are encouraged
// to use these.  Moreover, if you choose to use base::subtle::Atomic64 type,
// you MUST use one of the Load or Store routines to get correct behavior
// on 32-bit platforms.
//
// The intent is eventually to put all of these routines in namespace
// base::subtle

#ifndef THREAD_ATOMICOPS_H_
#define THREAD_ATOMICOPS_H_

#include <config.h>
#ifdef HAVE_STDINT_H
#include <stdint.h>
#endif

// ------------------------------------------------------------------------
// Include the platform specific implementations of the types
// and operations listed below.  Implementations are to provide Atomic32
// and Atomic64 operations. If there is a mismatch between intptr_t and
// the Atomic32 or Atomic64 types for a platform, the platform-specific header
// should define the macro, AtomicWordCastType in a clause similar to the
// following:
// #if ...pointers are 64 bits...
// # define AtomicWordCastType base::subtle::Atomic64
// #else
// # define AtomicWordCastType Atomic32
// #endif
// TODO(csilvers): figure out ARCH_PIII/ARCH_K8 (perhaps via ./configure?)
// ------------------------------------------------------------------------

#include "base/arm_instruction_set_select.h"

// TODO(csilvers): match piii, not just __i386.  Also, match k8
#if defined(__MACH__) && defined(__APPLE__)
#include "base/atomicops-internals-macosx.h"
#elif defined(__GNUC__) && defined(ARMV6)
#include "base/atomicops-internals-arm-v6plus.h"
#elif defined(ARMV3)
#include "base/atomicops-internals-arm-generic.h"
#elif defined(_WIN32)
#include "base/atomicops-internals-windows.h"
#elif defined(__GNUC__) && (defined(__i386) || defined(__x86_64__))
#include "base/atomicops-internals-x86.h"
#elif defined(__linux__) && defined(__PPC__)
#include "base/atomicops-internals-linuxppc.h"
#else
// Assume x86 for now.  If you need to support a new architecture and
// don't know how to implement atomic ops, you can probably get away
// with using pthreads, since atomicops is only used by spinlock.h/cc
//#error You need to implement atomic operations for this architecture
#include "base/atomicops-internals-x86.h"
#endif

// Signed type that can hold a pointer and supports the atomic ops below, as
// well as atomic loads and stores.  Instances must be naturally-aligned.
typedef intptr_t AtomicWord;

#ifdef AtomicWordCastType
// ------------------------------------------------------------------------
// This section is needed only when explicit type casting is required to
// cast AtomicWord to one of the basic atomic types (Atomic64 or Atomic32).
// It also serves to document the AtomicWord interface.
// ------------------------------------------------------------------------

namespace base {
namespace subtle {

// Atomically execute:
//      result = *ptr;
//      if (*ptr == old_value)
//        *ptr = new_value;
//      return result;
//
// I.e., replace "*ptr" with "new_value" if "*ptr" used to be "old_value".
// Always return the old value of "*ptr"
//
// This routine implies no memory barriers.
inline AtomicWord NoBarrier_CompareAndSwap(volatile AtomicWord* ptr,
                                           AtomicWord old_value,
                                           AtomicWord new_value) {
  return NoBarrier_CompareAndSwap(
      reinterpret_cast<volatile AtomicWordCastType*>(ptr),
      old_value, new_value);
}

// Atomically store new_value into *ptr, returning the previous value held in
// *ptr.  This routine implies no memory barriers.
inline AtomicWord NoBarrier_AtomicExchange(volatile AtomicWord* ptr,
                                           AtomicWord new_value) {
  return NoBarrier_AtomicExchange(
      reinterpret_cast<volatile AtomicWordCastType*>(ptr), new_value);
}

// Atomically increment *ptr by "increment".  Returns the new value of
// *ptr with the increment applied.  This routine implies no memory
// barriers.
inline AtomicWord NoBarrier_AtomicIncrement(volatile AtomicWord* ptr,
                                            AtomicWord increment) {
  return NoBarrier_AtomicIncrement(
      reinterpret_cast<volatile AtomicWordCastType*>(ptr), increment);
}

inline AtomicWord Barrier_AtomicIncrement(volatile AtomicWord* ptr,
                                          AtomicWord increment) {
  return Barrier_AtomicIncrement(
      reinterpret_cast<volatile AtomicWordCastType*>(ptr), increment);
}

// ------------------------------------------------------------------------
// These following lower-level operations are typically useful only to people
// implementing higher-level synchronization operations like spinlocks,
// mutexes, and condition-variables.  They combine CompareAndSwap(), a load, or
// a store with appropriate memory-ordering instructions.  "Acquire" operations
// ensure that no later memory access can be reordered ahead of the operation.
// "Release" operations ensure that no previous memory access can be reordered
// after the operation.  "Barrier" operations have both "Acquire" and "Release"
// semantics.   A MemoryBarrier() has "Barrier" semantics, but does no memory
// access.
// ------------------------------------------------------------------------
inline AtomicWord Acquire_CompareAndSwap(volatile AtomicWord* ptr,
                                         AtomicWord old_value,
                                         AtomicWord new_value) {
  return base::subtle::Acquire_CompareAndSwap(
      reinterpret_cast<volatile AtomicWordCastType*>(ptr),
      old_value, new_value);
}

inline AtomicWord Release_CompareAndSwap(volatile AtomicWord* ptr,
                                         AtomicWord old_value,
                                         AtomicWord new_value) {
  return base::subtle::Release_CompareAndSwap(
      reinterpret_cast<volatile AtomicWordCastType*>(ptr),
      old_value, new_value);
}

inline void NoBarrier_Store(volatile AtomicWord *ptr, AtomicWord value) {
  NoBarrier_Store(
      reinterpret_cast<volatile AtomicWordCastType*>(ptr), value);
}

inline void Acquire_Store(volatile AtomicWord* ptr, AtomicWord value) {
  return base::subtle::Acquire_Store(
      reinterpret_cast<volatile AtomicWordCastType*>(ptr), value);
}

inline void Release_Store(volatile AtomicWord* ptr, AtomicWord value) {
  return base::subtle::Release_Store(
      reinterpret_cast<volatile AtomicWordCastType*>(ptr), value);
}

inline AtomicWord NoBarrier_Load(volatile const AtomicWord *ptr) {
  return NoBarrier_Load(
      reinterpret_cast<volatile const AtomicWordCastType*>(ptr));
}

inline AtomicWord Acquire_Load(volatile const AtomicWord* ptr) {
  return base::subtle::Acquire_Load(
      reinterpret_cast<volatile const AtomicWordCastType*>(ptr));
}

inline AtomicWord Release_Load(volatile const AtomicWord* ptr) {
  return base::subtle::Release_Load(
      reinterpret_cast<volatile const AtomicWordCastType*>(ptr));
}

}  // namespace base::subtle
}  // namespace base
#endif  // AtomicWordCastType

// ------------------------------------------------------------------------
// Commented out type definitions and method declarations for documentation
// of the interface provided by this module.
// ------------------------------------------------------------------------

#if 0

// Signed 32-bit type that supports the atomic ops below, as well as atomic
// loads and stores.  Instances must be naturally aligned.  This type differs
// from AtomicWord in 64-bit binaries where AtomicWord is 64-bits.
typedef int32_t Atomic32;

// Corresponding operations on Atomic32
namespace base {
namespace subtle {

// Signed 64-bit type that supports the atomic ops below, as well as atomic
// loads and stores.  Instances must be naturally aligned.  This type differs
// from AtomicWord in 32-bit binaries where AtomicWord is 32-bits.
typedef int64_t Atomic64;

Atomic32 NoBarrier_CompareAndSwap(volatile Atomic32* ptr,
                                  Atomic32 old_value,
                                  Atomic32 new_value);
Atomic32 NoBarrier_AtomicExchange(volatile Atomic32* ptr, Atomic32 new_value);
Atomic32 NoBarrier_AtomicIncrement(volatile Atomic32* ptr, Atomic32 increment);
Atomic32 Barrier_AtomicIncrement(volatile Atomic32* ptr,
                                 Atomic32 increment);
Atomic32 Acquire_CompareAndSwap(volatile Atomic32* ptr,
                                Atomic32 old_value,
                                Atomic32 new_value);
Atomic32 Release_CompareAndSwap(volatile Atomic32* ptr,
                                Atomic32 old_value,
                                Atomic32 new_value);
void NoBarrier_Store(volatile Atomic32* ptr, Atomic32 value);
void Acquire_Store(volatile Atomic32* ptr, Atomic32 value);
void Release_Store(volatile Atomic32* ptr, Atomic32 value);
Atomic32 NoBarrier_Load(volatile const Atomic32* ptr);
Atomic32 Acquire_Load(volatile const Atomic32* ptr);
Atomic32 Release_Load(volatile const Atomic32* ptr);

// Corresponding operations on Atomic64
Atomic64 NoBarrier_CompareAndSwap(volatile Atomic64* ptr,
                                  Atomic64 old_value,
                                  Atomic64 new_value);
Atomic64 NoBarrier_AtomicExchange(volatile Atomic64* ptr, Atomic64 new_value);
Atomic64 NoBarrier_AtomicIncrement(volatile Atomic64* ptr, Atomic64 increment);
Atomic64 Barrier_AtomicIncrement(volatile Atomic64* ptr, Atomic64 increment);

Atomic64 Acquire_CompareAndSwap(volatile Atomic64* ptr,
                                Atomic64 old_value,
                                Atomic64 new_value);
Atomic64 Release_CompareAndSwap(volatile Atomic64* ptr,
                                Atomic64 old_value,
                                Atomic64 new_value);
void NoBarrier_Store(volatile Atomic64* ptr, Atomic64 value);
void Acquire_Store(volatile Atomic64* ptr, Atomic64 value);
void Release_Store(volatile Atomic64* ptr, Atomic64 value);
Atomic64 NoBarrier_Load(volatile const Atomic64* ptr);
Atomic64 Acquire_Load(volatile const Atomic64* ptr);
Atomic64 Release_Load(volatile const Atomic64* ptr);
}  // namespace base::subtle
}  // namespace base

void MemoryBarrier();

#endif  // 0


// ------------------------------------------------------------------------
// The following are to be deprecated when all uses have been changed to
// use the base::subtle namespace.
// ------------------------------------------------------------------------

#ifdef AtomicWordCastType
// AtomicWord versions to be deprecated
inline AtomicWord Acquire_CompareAndSwap(volatile AtomicWord* ptr,
                                         AtomicWord old_value,
                                         AtomicWord new_value) {
  return base::subtle::Acquire_CompareAndSwap(ptr, old_value, new_value);
}

inline AtomicWord Release_CompareAndSwap(volatile AtomicWord* ptr,
                                         AtomicWord old_value,
                                         AtomicWord new_value) {
  return base::subtle::Release_CompareAndSwap(ptr, old_value, new_value);
}

inline void Acquire_Store(volatile AtomicWord* ptr, AtomicWord value) {
  return base::subtle::Acquire_Store(ptr, value);
}

inline void Release_Store(volatile AtomicWord* ptr, AtomicWord value) {
  return base::subtle::Release_Store(ptr, value);
}

inline AtomicWord Acquire_Load(volatile const AtomicWord* ptr) {
  return base::subtle::Acquire_Load(ptr);
}

inline AtomicWord Release_Load(volatile const AtomicWord* ptr) {
  return base::subtle::Release_Load(ptr);
}
#endif  // AtomicWordCastType

// 32-bit Acquire/Release operations to be deprecated.

inline Atomic32 Acquire_CompareAndSwap(volatile Atomic32* ptr,
                                       Atomic32 old_value,
                                       Atomic32 new_value) {
  return base::subtle::Acquire_CompareAndSwap(ptr, old_value, new_value);
}
inline Atomic32 Release_CompareAndSwap(volatile Atomic32* ptr,
                                       Atomic32 old_value,
                                       Atomic32 new_value) {
  return base::subtle::Release_CompareAndSwap(ptr, old_value, new_value);
}
inline void Acquire_Store(volatile Atomic32* ptr, Atomic32 value) {
  base::subtle::Acquire_Store(ptr, value);
}
inline void Release_Store(volatile Atomic32* ptr, Atomic32 value) {
  return base::subtle::Release_Store(ptr, value);
}
inline Atomic32 Acquire_Load(volatile const Atomic32* ptr) {
  return base::subtle::Acquire_Load(ptr);
}
inline Atomic32 Release_Load(volatile const Atomic32* ptr) {
  return base::subtle::Release_Load(ptr);
}

#ifdef BASE_HAS_ATOMIC64

// 64-bit Acquire/Release operations to be deprecated.

inline base::subtle::Atomic64 Acquire_CompareAndSwap(
    volatile base::subtle::Atomic64* ptr,
    base::subtle::Atomic64 old_value, base::subtle::Atomic64 new_value) {
  return base::subtle::Acquire_CompareAndSwap(ptr, old_value, new_value);
}
inline base::subtle::Atomic64 Release_CompareAndSwap(
    volatile base::subtle::Atomic64* ptr,
    base::subtle::Atomic64 old_value, base::subtle::Atomic64 new_value) {
  return base::subtle::Release_CompareAndSwap(ptr, old_value, new_value);
}
inline void Acquire_Store(
    volatile base::subtle::Atomic64* ptr, base::subtle::Atomic64 value) {
  base::subtle::Acquire_Store(ptr, value);
}
inline void Release_Store(
    volatile base::subtle::Atomic64* ptr, base::subtle::Atomic64 value) {
  return base::subtle::Release_Store(ptr, value);
}
inline base::subtle::Atomic64 Acquire_Load(
    volatile const base::subtle::Atomic64* ptr) {
  return base::subtle::Acquire_Load(ptr);
}
inline base::subtle::Atomic64 Release_Load(
    volatile const base::subtle::Atomic64* ptr) {
  return base::subtle::Release_Load(ptr);
}

#endif  // BASE_HAS_ATOMIC64

#endif  // THREAD_ATOMICOPS_H_
