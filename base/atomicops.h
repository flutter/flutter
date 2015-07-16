// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// For atomic operations on reference counts, see atomic_refcount.h.
// For atomic operations on sequence numbers, see atomic_sequence_num.h.

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
// to use these.
//

#ifndef BASE_ATOMICOPS_H_
#define BASE_ATOMICOPS_H_

#include <stdint.h>

// Small C++ header which defines implementation specific macros used to
// identify the STL implementation.
// - libc++: captures __config for _LIBCPP_VERSION
// - libstdc++: captures bits/c++config.h for __GLIBCXX__
#include <cstddef>

#include "base/base_export.h"
#include "build/build_config.h"

#if defined(OS_WIN) && defined(ARCH_CPU_64_BITS)
// windows.h #defines this (only on x64). This causes problems because the
// public API also uses MemoryBarrier at the public name for this fence. So, on
// X64, undef it, and call its documented
// (http://msdn.microsoft.com/en-us/library/windows/desktop/ms684208.aspx)
// implementation directly.
#undef MemoryBarrier
#endif

namespace base {
namespace subtle {

typedef int32_t Atomic32;
#ifdef ARCH_CPU_64_BITS
// We need to be able to go between Atomic64 and AtomicWord implicitly.  This
// means Atomic64 and AtomicWord should be the same type on 64-bit.
#if defined(__ILP32__) || defined(OS_NACL)
// NaCl's intptr_t is not actually 64-bits on 64-bit!
// http://code.google.com/p/nativeclient/issues/detail?id=1162
typedef int64_t Atomic64;
#else
typedef intptr_t Atomic64;
#endif
#endif

// Use AtomicWord for a machine-sized pointer.  It will use the Atomic32 or
// Atomic64 routines below, depending on your architecture.
typedef intptr_t AtomicWord;

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
Atomic32 NoBarrier_CompareAndSwap(volatile Atomic32* ptr,
                                  Atomic32 old_value,
                                  Atomic32 new_value);

// Atomically store new_value into *ptr, returning the previous value held in
// *ptr.  This routine implies no memory barriers.
Atomic32 NoBarrier_AtomicExchange(volatile Atomic32* ptr, Atomic32 new_value);

// Atomically increment *ptr by "increment".  Returns the new value of
// *ptr with the increment applied.  This routine implies no memory barriers.
Atomic32 NoBarrier_AtomicIncrement(volatile Atomic32* ptr, Atomic32 increment);

Atomic32 Barrier_AtomicIncrement(volatile Atomic32* ptr,
                                 Atomic32 increment);

// These following lower-level operations are typically useful only to people
// implementing higher-level synchronization operations like spinlocks,
// mutexes, and condition-variables.  They combine CompareAndSwap(), a load, or
// a store with appropriate memory-ordering instructions.  "Acquire" operations
// ensure that no later memory access can be reordered ahead of the operation.
// "Release" operations ensure that no previous memory access can be reordered
// after the operation.  "Barrier" operations have both "Acquire" and "Release"
// semantics.   A MemoryBarrier() has "Barrier" semantics, but does no memory
// access.
Atomic32 Acquire_CompareAndSwap(volatile Atomic32* ptr,
                                Atomic32 old_value,
                                Atomic32 new_value);
Atomic32 Release_CompareAndSwap(volatile Atomic32* ptr,
                                Atomic32 old_value,
                                Atomic32 new_value);

void MemoryBarrier();
void NoBarrier_Store(volatile Atomic32* ptr, Atomic32 value);
void Acquire_Store(volatile Atomic32* ptr, Atomic32 value);
void Release_Store(volatile Atomic32* ptr, Atomic32 value);

Atomic32 NoBarrier_Load(volatile const Atomic32* ptr);
Atomic32 Acquire_Load(volatile const Atomic32* ptr);
Atomic32 Release_Load(volatile const Atomic32* ptr);

// 64-bit atomic operations (only available on 64-bit processors).
#ifdef ARCH_CPU_64_BITS
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
#endif  // ARCH_CPU_64_BITS

}  // namespace subtle
}  // namespace base

// The following x86 CPU features are used in atomicops_internals_x86_gcc.h, but
// this file is duplicated inside of Chrome: protobuf and tcmalloc rely on the
// struct being present at link time. Some parts of Chrome can currently use the
// portable interface whereas others still use GCC one. The include guards are
// the same as in atomicops_internals_x86_gcc.cc.
#if defined(__i386__) || defined(__x86_64__)
// This struct is not part of the public API of this module; clients may not
// use it.  (However, it's exported via BASE_EXPORT because clients implicitly
// do use it at link time by inlining these functions.)
// Features of this x86.  Values may not be correct before main() is run,
// but are set conservatively.
struct AtomicOps_x86CPUFeatureStruct {
  bool has_amd_lock_mb_bug; // Processor has AMD memory-barrier bug; do lfence
                            // after acquire compare-and-swap.
  // The following fields are unused by Chrome's base implementation but are
  // still used by copies of the same code in other parts of the code base. This
  // causes an ODR violation, and the other code is likely reading invalid
  // memory.
  // TODO(jfb) Delete these fields once the rest of the Chrome code base doesn't
  //           depend on them.
  bool has_sse2;            // Processor has SSE2.
  bool has_cmpxchg16b;      // Processor supports cmpxchg16b instruction.
};
BASE_EXPORT extern struct AtomicOps_x86CPUFeatureStruct
    AtomicOps_Internalx86CPUFeatures;
#endif

// Try to use a portable implementation based on C++11 atomics.
//
// Some toolchains support C++11 language features without supporting library
// features (recent compiler, older STL). Whitelist libstdc++ and libc++ that we
// know will have <atomic> when compiling C++11.
#if ((__cplusplus >= 201103L) &&                            \
     ((defined(__GLIBCXX__) && (__GLIBCXX__ > 20110216)) || \
      (defined(_LIBCPP_VERSION) && (_LIBCPP_STD_VER >= 11))))
#  include "base/atomicops_internals_portable.h"
#else  // Otherwise use a platform specific implementation.
#  if defined(THREAD_SANITIZER)
#    error "Thread sanitizer must use the portable atomic operations"
#  elif (defined(OS_WIN) && defined(COMPILER_MSVC) && \
         defined(ARCH_CPU_X86_FAMILY))
#    include "base/atomicops_internals_x86_msvc.h"
#  elif defined(OS_MACOSX)
#    include "base/atomicops_internals_mac.h"
#  elif defined(OS_NACL)
#    include "base/atomicops_internals_gcc.h"
#  elif defined(COMPILER_GCC) && defined(ARCH_CPU_ARMEL)
#    include "base/atomicops_internals_arm_gcc.h"
#  elif defined(COMPILER_GCC) && defined(ARCH_CPU_ARM64)
#    include "base/atomicops_internals_arm64_gcc.h"
#  elif defined(COMPILER_GCC) && defined(ARCH_CPU_X86_FAMILY)
#    include "base/atomicops_internals_x86_gcc.h"
#  elif (defined(COMPILER_GCC) && \
         (defined(ARCH_CPU_MIPS_FAMILY) || defined(ARCH_CPU_MIPS64_FAMILY)))
#    include "base/atomicops_internals_mips_gcc.h"
#  else
#    error "Atomic operations are not supported on your platform"
#  endif
#endif   // Portable / non-portable includes.

// On some platforms we need additional declarations to make
// AtomicWord compatible with our other Atomic* types.
#if defined(OS_MACOSX) || defined(OS_OPENBSD)
#include "base/atomicops_internals_atomicword_compat.h"
#endif

#endif  // BASE_ATOMICOPS_H_
