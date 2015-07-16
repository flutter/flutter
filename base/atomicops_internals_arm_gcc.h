// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is an internal atomic implementation, use base/atomicops.h instead.
//
// LinuxKernelCmpxchg and Barrier_AtomicIncrement are from Google Gears.

#ifndef BASE_ATOMICOPS_INTERNALS_ARM_GCC_H_
#define BASE_ATOMICOPS_INTERNALS_ARM_GCC_H_

#if defined(OS_QNX)
#include <sys/cpuinline.h>
#endif

namespace base {
namespace subtle {

// Memory barriers on ARM are funky, but the kernel is here to help:
//
// * ARMv5 didn't support SMP, there is no memory barrier instruction at
//   all on this architecture, or when targeting its machine code.
//
// * Some ARMv6 CPUs support SMP. A full memory barrier can be produced by
//   writing a random value to a very specific coprocessor register.
//
// * On ARMv7, the "dmb" instruction is used to perform a full memory
//   barrier (though writing to the co-processor will still work).
//   However, on single core devices (e.g. Nexus One, or Nexus S),
//   this instruction will take up to 200 ns, which is huge, even though
//   it's completely un-needed on these devices.
//
// * There is no easy way to determine at runtime if the device is
//   single or multi-core. However, the kernel provides a useful helper
//   function at a fixed memory address (0xffff0fa0), which will always
//   perform a memory barrier in the most efficient way. I.e. on single
//   core devices, this is an empty function that exits immediately.
//   On multi-core devices, it implements a full memory barrier.
//
// * This source could be compiled to ARMv5 machine code that runs on a
//   multi-core ARMv6 or ARMv7 device. In this case, memory barriers
//   are needed for correct execution. Always call the kernel helper, even
//   when targeting ARMv5TE.
//

inline void MemoryBarrier() {
#if defined(OS_LINUX) || defined(OS_ANDROID)
  // Note: This is a function call, which is also an implicit compiler barrier.
  typedef void (*KernelMemoryBarrierFunc)();
  ((KernelMemoryBarrierFunc)0xffff0fa0)();
#elif defined(OS_QNX)
  __cpu_membarrier();
#else
#error MemoryBarrier() is not implemented on this platform.
#endif
}

// An ARM toolchain would only define one of these depending on which
// variant of the target architecture is being used. This tests against
// any known ARMv6 or ARMv7 variant, where it is possible to directly
// use ldrex/strex instructions to implement fast atomic operations.
#if defined(__ARM_ARCH_7__) || defined(__ARM_ARCH_7A__) || \
    defined(__ARM_ARCH_7R__) || defined(__ARM_ARCH_7M__) || \
    defined(__ARM_ARCH_6__) || defined(__ARM_ARCH_6J__) || \
    defined(__ARM_ARCH_6K__) || defined(__ARM_ARCH_6Z__) || \
    defined(__ARM_ARCH_6ZK__) || defined(__ARM_ARCH_6T2__)

inline Atomic32 NoBarrier_CompareAndSwap(volatile Atomic32* ptr,
                                         Atomic32 old_value,
                                         Atomic32 new_value) {
  Atomic32 prev_value;
  int reloop;
  do {
    // The following is equivalent to:
    //
    //   prev_value = LDREX(ptr)
    //   reloop = 0
    //   if (prev_value != old_value)
    //      reloop = STREX(ptr, new_value)
    __asm__ __volatile__("    ldrex %0, [%3]\n"
                         "    mov %1, #0\n"
                         "    cmp %0, %4\n"
#ifdef __thumb2__
                         "    it eq\n"
#endif
                         "    strexeq %1, %5, [%3]\n"
                         : "=&r"(prev_value), "=&r"(reloop), "+m"(*ptr)
                         : "r"(ptr), "r"(old_value), "r"(new_value)
                         : "cc", "memory");
  } while (reloop != 0);
  return prev_value;
}

inline Atomic32 Acquire_CompareAndSwap(volatile Atomic32* ptr,
                                       Atomic32 old_value,
                                       Atomic32 new_value) {
  Atomic32 result = NoBarrier_CompareAndSwap(ptr, old_value, new_value);
  MemoryBarrier();
  return result;
}

inline Atomic32 Release_CompareAndSwap(volatile Atomic32* ptr,
                                       Atomic32 old_value,
                                       Atomic32 new_value) {
  MemoryBarrier();
  return NoBarrier_CompareAndSwap(ptr, old_value, new_value);
}

inline Atomic32 NoBarrier_AtomicIncrement(volatile Atomic32* ptr,
                                          Atomic32 increment) {
  Atomic32 value;
  int reloop;
  do {
    // Equivalent to:
    //
    //  value = LDREX(ptr)
    //  value += increment
    //  reloop = STREX(ptr, value)
    //
    __asm__ __volatile__("    ldrex %0, [%3]\n"
                         "    add %0, %0, %4\n"
                         "    strex %1, %0, [%3]\n"
                         : "=&r"(value), "=&r"(reloop), "+m"(*ptr)
                         : "r"(ptr), "r"(increment)
                         : "cc", "memory");
  } while (reloop);
  return value;
}

inline Atomic32 Barrier_AtomicIncrement(volatile Atomic32* ptr,
                                        Atomic32 increment) {
  // TODO(digit): Investigate if it's possible to implement this with
  // a single MemoryBarrier() operation between the LDREX and STREX.
  // See http://crbug.com/246514
  MemoryBarrier();
  Atomic32 result = NoBarrier_AtomicIncrement(ptr, increment);
  MemoryBarrier();
  return result;
}

inline Atomic32 NoBarrier_AtomicExchange(volatile Atomic32* ptr,
                                         Atomic32 new_value) {
  Atomic32 old_value;
  int reloop;
  do {
    // old_value = LDREX(ptr)
    // reloop = STREX(ptr, new_value)
    __asm__ __volatile__("   ldrex %0, [%3]\n"
                         "   strex %1, %4, [%3]\n"
                         : "=&r"(old_value), "=&r"(reloop), "+m"(*ptr)
                         : "r"(ptr), "r"(new_value)
                         : "cc", "memory");
  } while (reloop != 0);
  return old_value;
}

// This tests against any known ARMv5 variant.
#elif defined(__ARM_ARCH_5__) || defined(__ARM_ARCH_5T__) || \
      defined(__ARM_ARCH_5TE__) || defined(__ARM_ARCH_5TEJ__)

// The kernel also provides a helper function to perform an atomic
// compare-and-swap operation at the hard-wired address 0xffff0fc0.
// On ARMv5, this is implemented by a special code path that the kernel
// detects and treats specially when thread pre-emption happens.
// On ARMv6 and higher, it uses LDREX/STREX instructions instead.
//
// Note that this always perform a full memory barrier, there is no
// need to add calls MemoryBarrier() before or after it. It also
// returns 0 on success, and 1 on exit.
//
// Available and reliable since Linux 2.6.24. Both Android and ChromeOS
// use newer kernel revisions, so this should not be a concern.
namespace {

inline int LinuxKernelCmpxchg(Atomic32 old_value,
                              Atomic32 new_value,
                              volatile Atomic32* ptr) {
  typedef int (*KernelCmpxchgFunc)(Atomic32, Atomic32, volatile Atomic32*);
  return ((KernelCmpxchgFunc)0xffff0fc0)(old_value, new_value, ptr);
}

}  // namespace

inline Atomic32 NoBarrier_CompareAndSwap(volatile Atomic32* ptr,
                                         Atomic32 old_value,
                                         Atomic32 new_value) {
  Atomic32 prev_value;
  for (;;) {
    prev_value = *ptr;
    if (prev_value != old_value)
      return prev_value;
    if (!LinuxKernelCmpxchg(old_value, new_value, ptr))
      return old_value;
  }
}

inline Atomic32 NoBarrier_AtomicExchange(volatile Atomic32* ptr,
                                         Atomic32 new_value) {
  Atomic32 old_value;
  do {
    old_value = *ptr;
  } while (LinuxKernelCmpxchg(old_value, new_value, ptr));
  return old_value;
}

inline Atomic32 NoBarrier_AtomicIncrement(volatile Atomic32* ptr,
                                          Atomic32 increment) {
  return Barrier_AtomicIncrement(ptr, increment);
}

inline Atomic32 Barrier_AtomicIncrement(volatile Atomic32* ptr,
                                        Atomic32 increment) {
  for (;;) {
    // Atomic exchange the old value with an incremented one.
    Atomic32 old_value = *ptr;
    Atomic32 new_value = old_value + increment;
    if (!LinuxKernelCmpxchg(old_value, new_value, ptr)) {
      // The exchange took place as expected.
      return new_value;
    }
    // Otherwise, *ptr changed mid-loop and we need to retry.
  }
}

inline Atomic32 Acquire_CompareAndSwap(volatile Atomic32* ptr,
                                       Atomic32 old_value,
                                       Atomic32 new_value) {
  Atomic32 prev_value;
  for (;;) {
    prev_value = *ptr;
    if (prev_value != old_value) {
      // Always ensure acquire semantics.
      MemoryBarrier();
      return prev_value;
    }
    if (!LinuxKernelCmpxchg(old_value, new_value, ptr))
      return old_value;
  }
}

inline Atomic32 Release_CompareAndSwap(volatile Atomic32* ptr,
                                       Atomic32 old_value,
                                       Atomic32 new_value) {
  // This could be implemented as:
  //    MemoryBarrier();
  //    return NoBarrier_CompareAndSwap();
  //
  // But would use 3 barriers per succesful CAS. To save performance,
  // use Acquire_CompareAndSwap(). Its implementation guarantees that:
  // - A succesful swap uses only 2 barriers (in the kernel helper).
  // - An early return due to (prev_value != old_value) performs
  //   a memory barrier with no store, which is equivalent to the
  //   generic implementation above.
  return Acquire_CompareAndSwap(ptr, old_value, new_value);
}

#else
#  error "Your CPU's ARM architecture is not supported yet"
#endif

// NOTE: Atomicity of the following load and store operations is only
// guaranteed in case of 32-bit alignement of |ptr| values.

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

inline Atomic32 NoBarrier_Load(volatile const Atomic32* ptr) { return *ptr; }

inline Atomic32 Acquire_Load(volatile const Atomic32* ptr) {
  Atomic32 value = *ptr;
  MemoryBarrier();
  return value;
}

inline Atomic32 Release_Load(volatile const Atomic32* ptr) {
  MemoryBarrier();
  return *ptr;
}

}  // namespace subtle
}  // namespace base

#endif  // BASE_ATOMICOPS_INTERNALS_ARM_GCC_H_
