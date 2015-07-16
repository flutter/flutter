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

// Implementation of atomic operations for x86.  This file should not
// be included directly.  Clients should instead include
// "base/atomicops.h".

#ifndef BASE_ATOMICOPS_INTERNALS_X86_H_
#define BASE_ATOMICOPS_INTERNALS_X86_H_

typedef int32_t Atomic32;
#define BASE_HAS_ATOMIC64 1  // Use only in tests and base/atomic*


// NOTE(vchen): x86 does not need to define AtomicWordCastType, because it
// already matches Atomic32 or Atomic64, depending on the platform.


// This struct is not part of the public API of this module; clients may not
// use it.
// Features of this x86.  Values may not be correct before main() is run,
// but are set conservatively.
struct AtomicOps_x86CPUFeatureStruct {
  bool has_amd_lock_mb_bug; // Processor has AMD memory-barrier bug; do lfence
                            // after acquire compare-and-swap.
  bool has_sse2;            // Processor has SSE2.
  bool has_cmpxchg16b;      // Processor supports cmpxchg16b instruction.
};
extern struct AtomicOps_x86CPUFeatureStruct AtomicOps_Internalx86CPUFeatures;


#define ATOMICOPS_COMPILER_BARRIER() __asm__ __volatile__("" : : : "memory")


namespace base {
namespace subtle {

typedef int64_t Atomic64;

// 32-bit low-level operations on any platform.

inline Atomic32 NoBarrier_CompareAndSwap(volatile Atomic32* ptr,
                                         Atomic32 old_value,
                                         Atomic32 new_value) {
  Atomic32 prev;
  __asm__ __volatile__("lock; cmpxchgl %1,%2"
                       : "=a" (prev)
                       : "q" (new_value), "m" (*ptr), "0" (old_value)
                       : "memory");
  return prev;
}

inline Atomic32 NoBarrier_AtomicExchange(volatile Atomic32* ptr,
                                         Atomic32 new_value) {
  __asm__ __volatile__("xchgl %1,%0"  // The lock prefix is implicit for xchg.
                       : "=r" (new_value)
                       : "m" (*ptr), "0" (new_value)
                       : "memory");
  return new_value;  // Now it's the previous value.
}

inline Atomic32 NoBarrier_AtomicIncrement(volatile Atomic32* ptr,
                                          Atomic32 increment) {
  Atomic32 temp = increment;
  __asm__ __volatile__("lock; xaddl %0,%1"
                       : "+r" (temp), "+m" (*ptr)
                       : : "memory");
  // temp now holds the old value of *ptr
  return temp + increment;
}

inline Atomic32 Barrier_AtomicIncrement(volatile Atomic32* ptr,
                                        Atomic32 increment) {
  Atomic32 temp = increment;
  __asm__ __volatile__("lock; xaddl %0,%1"
                       : "+r" (temp), "+m" (*ptr)
                       : : "memory");
  // temp now holds the old value of *ptr
  if (AtomicOps_Internalx86CPUFeatures.has_amd_lock_mb_bug) {
    __asm__ __volatile__("lfence" : : : "memory");
  }
  return temp + increment;
}

inline Atomic32 Acquire_CompareAndSwap(volatile Atomic32* ptr,
                                       Atomic32 old_value,
                                       Atomic32 new_value) {
  Atomic32 x = NoBarrier_CompareAndSwap(ptr, old_value, new_value);
  if (AtomicOps_Internalx86CPUFeatures.has_amd_lock_mb_bug) {
    __asm__ __volatile__("lfence" : : : "memory");
  }
  return x;
}

inline Atomic32 Release_CompareAndSwap(volatile Atomic32* ptr,
                                       Atomic32 old_value,
                                       Atomic32 new_value) {
  return NoBarrier_CompareAndSwap(ptr, old_value, new_value);
}

inline void NoBarrier_Store(volatile Atomic32* ptr, Atomic32 value) {
  *ptr = value;
}

#if defined(__x86_64__)

// 64-bit implementations of memory barrier can be simpler, because it
// "mfence" is guaranteed to exist.
inline void MemoryBarrier() {
  __asm__ __volatile__("mfence" : : : "memory");
}

inline void Acquire_Store(volatile Atomic32* ptr, Atomic32 value) {
  *ptr = value;
  MemoryBarrier();
}

#else

inline void MemoryBarrier() {
  if (AtomicOps_Internalx86CPUFeatures.has_sse2) {
    __asm__ __volatile__("mfence" : : : "memory");
  } else { // mfence is faster but not present on PIII
    Atomic32 x = 0;
    NoBarrier_AtomicExchange(&x, 0);  // acts as a barrier on PIII
  }
}

inline void Acquire_Store(volatile Atomic32* ptr, Atomic32 value) {
  if (AtomicOps_Internalx86CPUFeatures.has_sse2) {
    *ptr = value;
    __asm__ __volatile__("mfence" : : : "memory");
  } else {
    NoBarrier_AtomicExchange(ptr, value);
                          // acts as a barrier on PIII
  }
}
#endif

inline void Release_Store(volatile Atomic32* ptr, Atomic32 value) {
  ATOMICOPS_COMPILER_BARRIER();
  *ptr = value; // An x86 store acts as a release barrier.
  // See comments in Atomic64 version of Release_Store(), below.
}

inline Atomic32 NoBarrier_Load(volatile const Atomic32* ptr) {
  return *ptr;
}

inline Atomic32 Acquire_Load(volatile const Atomic32* ptr) {
  Atomic32 value = *ptr; // An x86 load acts as a acquire barrier.
  // See comments in Atomic64 version of Release_Store(), below.
  ATOMICOPS_COMPILER_BARRIER();
  return value;
}

inline Atomic32 Release_Load(volatile const Atomic32* ptr) {
  MemoryBarrier();
  return *ptr;
}

#if defined(__x86_64__)

// 64-bit low-level operations on 64-bit platform.

inline Atomic64 NoBarrier_CompareAndSwap(volatile Atomic64* ptr,
                                         Atomic64 old_value,
                                         Atomic64 new_value) {
  Atomic64 prev;
  __asm__ __volatile__("lock; cmpxchgq %1,%2"
                       : "=a" (prev)
                       : "q" (new_value), "m" (*ptr), "0" (old_value)
                       : "memory");
  return prev;
}

inline Atomic64 NoBarrier_AtomicExchange(volatile Atomic64* ptr,
                                         Atomic64 new_value) {
  __asm__ __volatile__("xchgq %1,%0"  // The lock prefix is implicit for xchg.
                       : "=r" (new_value)
                       : "m" (*ptr), "0" (new_value)
                       : "memory");
  return new_value;  // Now it's the previous value.
}

inline Atomic64 NoBarrier_AtomicIncrement(volatile Atomic64* ptr,
                                          Atomic64 increment) {
  Atomic64 temp = increment;
  __asm__ __volatile__("lock; xaddq %0,%1"
                       : "+r" (temp), "+m" (*ptr)
                       : : "memory");
  // temp now contains the previous value of *ptr
  return temp + increment;
}

inline Atomic64 Barrier_AtomicIncrement(volatile Atomic64* ptr,
                                        Atomic64 increment) {
  Atomic64 temp = increment;
  __asm__ __volatile__("lock; xaddq %0,%1"
                       : "+r" (temp), "+m" (*ptr)
                       : : "memory");
  // temp now contains the previous value of *ptr
  if (AtomicOps_Internalx86CPUFeatures.has_amd_lock_mb_bug) {
    __asm__ __volatile__("lfence" : : : "memory");
  }
  return temp + increment;
}

inline void NoBarrier_Store(volatile Atomic64* ptr, Atomic64 value) {
  *ptr = value;
}

inline void Acquire_Store(volatile Atomic64* ptr, Atomic64 value) {
  *ptr = value;
  MemoryBarrier();
}

inline void Release_Store(volatile Atomic64* ptr, Atomic64 value) {
  ATOMICOPS_COMPILER_BARRIER();

  *ptr = value; // An x86 store acts as a release barrier
                // for current AMD/Intel chips as of Jan 2008.
                // See also Acquire_Load(), below.

  // When new chips come out, check:
  //  IA-32 Intel Architecture Software Developer's Manual, Volume 3:
  //  System Programming Guide, Chatper 7: Multiple-processor management,
  //  Section 7.2, Memory Ordering.
  // Last seen at:
  //   http://developer.intel.com/design/pentium4/manuals/index_new.htm
  //
  // x86 stores/loads fail to act as barriers for a few instructions (clflush
  // maskmovdqu maskmovq movntdq movnti movntpd movntps movntq) but these are
  // not generated by the compiler, and are rare.  Users of these instructions
  // need to know about cache behaviour in any case since all of these involve
  // either flushing cache lines or non-temporal cache hints.
}

inline Atomic64 NoBarrier_Load(volatile const Atomic64* ptr) {
  return *ptr;
}

inline Atomic64 Acquire_Load(volatile const Atomic64* ptr) {
  Atomic64 value = *ptr; // An x86 load acts as a acquire barrier,
                         // for current AMD/Intel chips as of Jan 2008.
                         // See also Release_Store(), above.
  ATOMICOPS_COMPILER_BARRIER();
  return value;
}

inline Atomic64 Release_Load(volatile const Atomic64* ptr) {
  MemoryBarrier();
  return *ptr;
}

#else // defined(__x86_64__)

// 64-bit low-level operations on 32-bit platform.

#if !((__GNUC__ > 4) || (__GNUC__ == 4 && __GNUC_MINOR__ >= 1))
// For compilers older than gcc 4.1, we use inline asm.
//
// Potential pitfalls:
//
// 1. %ebx points to Global offset table (GOT) with -fPIC.
//    We need to preserve this register.
// 2. When explicit registers are used in inline asm, the
//    compiler may not be aware of it and might try to reuse
//    the same register for another argument which has constraints
//    that allow it ("r" for example).

inline Atomic64 __sync_val_compare_and_swap(volatile Atomic64* ptr,
                                            Atomic64 old_value,
                                            Atomic64 new_value) {
  Atomic64 prev;
  __asm__ __volatile__("push %%ebx\n\t"
                       "movl (%3), %%ebx\n\t"    // Move 64-bit new_value into
                       "movl 4(%3), %%ecx\n\t"   // ecx:ebx
                       "lock; cmpxchg8b (%1)\n\t"// If edx:eax (old_value) same
                       "pop %%ebx\n\t"
                       : "=A" (prev)             // as contents of ptr:
                       : "D" (ptr),              //   ecx:ebx => ptr
                         "0" (old_value),        // else:
                         "S" (&new_value)        //   old *ptr => edx:eax
                       : "memory", "%ecx");
  return prev;
}
#endif  // Compiler < gcc-4.1

inline Atomic64 NoBarrier_CompareAndSwap(volatile Atomic64* ptr,
                                         Atomic64 old_val,
                                         Atomic64 new_val) {
  return __sync_val_compare_and_swap(ptr, old_val, new_val);
}

inline Atomic64 NoBarrier_AtomicExchange(volatile Atomic64* ptr,
                                         Atomic64 new_val) {
  Atomic64 old_val;

  do {
    old_val = *ptr;
  } while (__sync_val_compare_and_swap(ptr, old_val, new_val) != old_val);

  return old_val;
}

inline Atomic64 NoBarrier_AtomicIncrement(volatile Atomic64* ptr,
                                          Atomic64 increment) {
  Atomic64 old_val, new_val;

  do {
    old_val = *ptr;
    new_val = old_val + increment;
  } while (__sync_val_compare_and_swap(ptr, old_val, new_val) != old_val);

  return old_val + increment;
}

inline Atomic64 Barrier_AtomicIncrement(volatile Atomic64* ptr,
                                        Atomic64 increment) {
  Atomic64 new_val = NoBarrier_AtomicIncrement(ptr, increment);
  if (AtomicOps_Internalx86CPUFeatures.has_amd_lock_mb_bug) {
    __asm__ __volatile__("lfence" : : : "memory");
  }
  return new_val;
}

inline void NoBarrier_Store(volatile Atomic64* ptr, Atomic64 value) {
  __asm__ __volatile__("movq %1, %%mm0\n\t"  // Use mmx reg for 64-bit atomic
                       "movq %%mm0, %0\n\t"  // moves (ptr could be read-only)
                       "emms\n\t"            // Empty mmx state/Reset FP regs
                       : "=m" (*ptr)
                       : "m" (value)
                       : // mark the FP stack and mmx registers as clobbered
			 "st", "st(1)", "st(2)", "st(3)", "st(4)",
                         "st(5)", "st(6)", "st(7)", "mm0", "mm1",
                         "mm2", "mm3", "mm4", "mm5", "mm6", "mm7");
}

inline void Acquire_Store(volatile Atomic64* ptr, Atomic64 value) {
  NoBarrier_Store(ptr, value);
  MemoryBarrier();
}

inline void Release_Store(volatile Atomic64* ptr, Atomic64 value) {
  ATOMICOPS_COMPILER_BARRIER();
  NoBarrier_Store(ptr, value);
}

inline Atomic64 NoBarrier_Load(volatile const Atomic64* ptr) {
  Atomic64 value;
  __asm__ __volatile__("movq %1, %%mm0\n\t"  // Use mmx reg for 64-bit atomic
                       "movq %%mm0, %0\n\t"  // moves (ptr could be read-only)
                       "emms\n\t"            // Empty mmx state/Reset FP regs
                       : "=m" (value)
                       : "m" (*ptr)
                       : // mark the FP stack and mmx registers as clobbered
                         "st", "st(1)", "st(2)", "st(3)", "st(4)",
                         "st(5)", "st(6)", "st(7)", "mm0", "mm1",
                         "mm2", "mm3", "mm4", "mm5", "mm6", "mm7");
  return value;
}

inline Atomic64 Acquire_Load(volatile const Atomic64* ptr) {
  Atomic64 value = NoBarrier_Load(ptr);
  ATOMICOPS_COMPILER_BARRIER();
  return value;
}

inline Atomic64 Release_Load(volatile const Atomic64* ptr) {
  MemoryBarrier();
  return NoBarrier_Load(ptr);
}

#endif // defined(__x86_64__)

inline Atomic64 Acquire_CompareAndSwap(volatile Atomic64* ptr,
                                       Atomic64 old_value,
                                       Atomic64 new_value) {
  Atomic64 x = NoBarrier_CompareAndSwap(ptr, old_value, new_value);
  if (AtomicOps_Internalx86CPUFeatures.has_amd_lock_mb_bug) {
    __asm__ __volatile__("lfence" : : : "memory");
  }
  return x;
}

inline Atomic64 Release_CompareAndSwap(volatile Atomic64* ptr,
                                       Atomic64 old_value,
                                       Atomic64 new_value) {
  return NoBarrier_CompareAndSwap(ptr, old_value, new_value);
}

} // namespace base::subtle
} // namespace base

#undef ATOMICOPS_COMPILER_BARRIER

#endif  // BASE_ATOMICOPS_INTERNALS_X86_H_
