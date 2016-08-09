/* Copyright (c) 2008, Google Inc.
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
 */

// Implementation of atomic operations for ppc-linux.  This file should not
// be included directly.  Clients should instead include
// "base/atomicops.h".

#ifndef BASE_ATOMICOPS_INTERNALS_LINUXPPC_H_
#define BASE_ATOMICOPS_INTERNALS_LINUXPPC_H_

typedef int32_t Atomic32;

#ifdef __PPC64__
#define BASE_HAS_ATOMIC64 1
#endif

namespace base {
namespace subtle {

static inline void _sync(void) {
  __asm__ __volatile__("sync": : : "memory");
}

static inline void _lwsync(void) {
  // gcc defines __NO_LWSYNC__ when appropriate; see
  //    http://gcc.gnu.org/ml/gcc-patches/2006-11/msg01238.html
#ifdef __NO_LWSYNC__
  __asm__ __volatile__("msync": : : "memory");
#else
  __asm__ __volatile__("lwsync": : : "memory");
#endif
}

static inline void _isync(void) {
  __asm__ __volatile__("isync": : : "memory");
}

static inline Atomic32 OSAtomicAdd32(Atomic32 amount, Atomic32 *value) {
  Atomic32 t;
  __asm__ __volatile__(
"1:		lwarx   %0,0,%3\n\
		add     %0,%2,%0\n\
		stwcx.  %0,0,%3 \n\
		bne-    1b"
		: "=&r" (t), "+m" (*value)
		: "r" (amount), "r" (value)
                : "cc");
  return t;
}

static inline Atomic32 OSAtomicAdd32Barrier(Atomic32 amount, Atomic32 *value) {
  Atomic32 t;
  _lwsync();
  t = OSAtomicAdd32(amount, value);
  // This is based on the code snippet in the architecture manual (Vol
  // 2, Appendix B).  It's a little tricky: correctness depends on the
  // fact that the code right before this (in OSAtomicAdd32) has a
  // conditional branch with a data dependency on the update.
  // Otherwise, we'd have to use sync.
  _isync();
  return t;
}

static inline bool OSAtomicCompareAndSwap32(Atomic32 old_value,
                                            Atomic32 new_value,
                                            Atomic32 *value) {
  Atomic32 prev;
  __asm__ __volatile__(
"1:		lwarx   %0,0,%2\n\
		cmpw    0,%0,%3\n\
		bne-    2f\n\
		stwcx.  %4,0,%2\n\
		bne-    1b\n\
2:"
                : "=&r" (prev), "+m" (*value)
                : "r" (value), "r" (old_value), "r" (new_value)
                : "cc");
  return prev == old_value;
}

static inline Atomic32 OSAtomicCompareAndSwap32Acquire(Atomic32 old_value,
                                                       Atomic32 new_value,
                                                       Atomic32 *value) {
  Atomic32 t;
  t = OSAtomicCompareAndSwap32(old_value, new_value, value);
  // This is based on the code snippet in the architecture manual (Vol
  // 2, Appendix B).  It's a little tricky: correctness depends on the
  // fact that the code right before this (in
  // OSAtomicCompareAndSwap32) has a conditional branch with a data
  // dependency on the update.  Otherwise, we'd have to use sync.
  _isync();
  return t;
}

static inline Atomic32 OSAtomicCompareAndSwap32Release(Atomic32 old_value,
                                                       Atomic32 new_value,
                                                       Atomic32 *value) {
  _lwsync();
  return OSAtomicCompareAndSwap32(old_value, new_value, value);
}

typedef int64_t Atomic64;

inline void MemoryBarrier() {
  // This can't be _lwsync(); we need to order the immediately
  // preceding stores against any load that may follow, but lwsync
  // doesn't guarantee that.
  _sync();
}

// 32-bit Versions.

inline Atomic32 NoBarrier_CompareAndSwap(volatile Atomic32 *ptr,
                                         Atomic32 old_value,
                                         Atomic32 new_value) {
  Atomic32 prev_value;
  do {
    if (OSAtomicCompareAndSwap32(old_value, new_value,
                                 const_cast<Atomic32*>(ptr))) {
      return old_value;
    }
    prev_value = *ptr;
  } while (prev_value == old_value);
  return prev_value;
}

inline Atomic32 NoBarrier_AtomicExchange(volatile Atomic32 *ptr,
                                         Atomic32 new_value) {
  Atomic32 old_value;
  do {
    old_value = *ptr;
  } while (!OSAtomicCompareAndSwap32(old_value, new_value,
                                     const_cast<Atomic32*>(ptr)));
  return old_value;
}

inline Atomic32 NoBarrier_AtomicIncrement(volatile Atomic32 *ptr,
                                          Atomic32 increment) {
  return OSAtomicAdd32(increment, const_cast<Atomic32*>(ptr));
}

inline Atomic32 Barrier_AtomicIncrement(volatile Atomic32 *ptr,
                                        Atomic32 increment) {
  return OSAtomicAdd32Barrier(increment, const_cast<Atomic32*>(ptr));
}

inline Atomic32 Acquire_CompareAndSwap(volatile Atomic32 *ptr,
                                       Atomic32 old_value,
                                       Atomic32 new_value) {
  Atomic32 prev_value;
  do {
    if (OSAtomicCompareAndSwap32Acquire(old_value, new_value,
                                        const_cast<Atomic32*>(ptr))) {
      return old_value;
    }
    prev_value = *ptr;
  } while (prev_value == old_value);
  return prev_value;
}

inline Atomic32 Release_CompareAndSwap(volatile Atomic32 *ptr,
                                       Atomic32 old_value,
                                       Atomic32 new_value) {
  Atomic32 prev_value;
  do {
    if (OSAtomicCompareAndSwap32Release(old_value, new_value,
                                        const_cast<Atomic32*>(ptr))) {
      return old_value;
    }
    prev_value = *ptr;
  } while (prev_value == old_value);
  return prev_value;
}

#ifdef __PPC64__

// 64-bit Versions.

static inline Atomic64 OSAtomicAdd64(Atomic64 amount, Atomic64 *value) {
  Atomic64 t;
  __asm__ __volatile__(
"1:		ldarx   %0,0,%3\n\
		add     %0,%2,%0\n\
		stdcx.  %0,0,%3 \n\
		bne-    1b"
		: "=&r" (t), "+m" (*value)
		: "r" (amount), "r" (value)
                : "cc");
  return t;
}

static inline Atomic64 OSAtomicAdd64Barrier(Atomic64 amount, Atomic64 *value) {
  Atomic64 t;
  _lwsync();
  t = OSAtomicAdd64(amount, value);
  // This is based on the code snippet in the architecture manual (Vol
  // 2, Appendix B).  It's a little tricky: correctness depends on the
  // fact that the code right before this (in OSAtomicAdd64) has a
  // conditional branch with a data dependency on the update.
  // Otherwise, we'd have to use sync.
  _isync();
  return t;
}

static inline bool OSAtomicCompareAndSwap64(Atomic64 old_value,
                                            Atomic64 new_value,
                                            Atomic64 *value) {
  Atomic64 prev;
  __asm__ __volatile__(
"1:		ldarx   %0,0,%2\n\
		cmpw    0,%0,%3\n\
		bne-    2f\n\
		stdcx.  %4,0,%2\n\
		bne-    1b\n\
2:"
                : "=&r" (prev), "+m" (*value)
                : "r" (value), "r" (old_value), "r" (new_value)
                : "cc");
  return prev == old_value;
}

static inline Atomic64 OSAtomicCompareAndSwap64Acquire(Atomic64 old_value,
                                                       Atomic64 new_value,
                                                       Atomic64 *value) {
  Atomic64 t;
  t = OSAtomicCompareAndSwap64(old_value, new_value, value);
  // This is based on the code snippet in the architecture manual (Vol
  // 2, Appendix B).  It's a little tricky: correctness depends on the
  // fact that the code right before this (in
  // OSAtomicCompareAndSwap64) has a conditional branch with a data
  // dependency on the update.  Otherwise, we'd have to use sync.
  _isync();
  return t;
}

static inline Atomic64 OSAtomicCompareAndSwap64Release(Atomic64 old_value,
                                                       Atomic64 new_value,
                                                       Atomic64 *value) {
  _lwsync();
  return OSAtomicCompareAndSwap64(old_value, new_value, value);
}


inline Atomic64 NoBarrier_CompareAndSwap(volatile Atomic64 *ptr,
                                         Atomic64 old_value,
                                         Atomic64 new_value) {
  Atomic64 prev_value;
  do {
    if (OSAtomicCompareAndSwap64(old_value, new_value,
                                 const_cast<Atomic64*>(ptr))) {
      return old_value;
    }
    prev_value = *ptr;
  } while (prev_value == old_value);
  return prev_value;
}

inline Atomic64 NoBarrier_AtomicExchange(volatile Atomic64 *ptr,
                                         Atomic64 new_value) {
  Atomic64 old_value;
  do {
    old_value = *ptr;
  } while (!OSAtomicCompareAndSwap64(old_value, new_value,
                                     const_cast<Atomic64*>(ptr)));
  return old_value;
}

inline Atomic64 NoBarrier_AtomicIncrement(volatile Atomic64 *ptr,
                                          Atomic64 increment) {
  return OSAtomicAdd64(increment, const_cast<Atomic64*>(ptr));
}

inline Atomic64 Barrier_AtomicIncrement(volatile Atomic64 *ptr,
                                        Atomic64 increment) {
  return OSAtomicAdd64Barrier(increment, const_cast<Atomic64*>(ptr));
}

inline Atomic64 Acquire_CompareAndSwap(volatile Atomic64 *ptr,
                                       Atomic64 old_value,
                                       Atomic64 new_value) {
  Atomic64 prev_value;
  do {
    if (OSAtomicCompareAndSwap64Acquire(old_value, new_value,
                                        const_cast<Atomic64*>(ptr))) {
      return old_value;
    }
    prev_value = *ptr;
  } while (prev_value == old_value);
  return prev_value;
}

inline Atomic64 Release_CompareAndSwap(volatile Atomic64 *ptr,
                                       Atomic64 old_value,
                                       Atomic64 new_value) {
  Atomic64 prev_value;
  do {
    if (OSAtomicCompareAndSwap64Release(old_value, new_value,
                                        const_cast<Atomic64*>(ptr))) {
      return old_value;
    }
    prev_value = *ptr;
  } while (prev_value == old_value);
  return prev_value;
}

#endif

inline void NoBarrier_Store(volatile Atomic32 *ptr, Atomic32 value) {
  *ptr = value;
}

inline void Acquire_Store(volatile Atomic32 *ptr, Atomic32 value) {
  *ptr = value;
  // This can't be _lwsync(); we need to order the immediately
  // preceding stores against any load that may follow, but lwsync
  // doesn't guarantee that.
  _sync();
}

inline void Release_Store(volatile Atomic32 *ptr, Atomic32 value) {
  _lwsync();
  *ptr = value;
}

inline Atomic32 NoBarrier_Load(volatile const Atomic32 *ptr) {
  return *ptr;
}

inline Atomic32 Acquire_Load(volatile const Atomic32 *ptr) {
  Atomic32 value = *ptr;
  _lwsync();
  return value;
}

inline Atomic32 Release_Load(volatile const Atomic32 *ptr) {
  // This can't be _lwsync(); we need to order the immediately
  // preceding stores against any load that may follow, but lwsync
  // doesn't guarantee that.
  _sync();
  return *ptr;
}

#ifdef __PPC64__

// 64-bit Versions.

inline void NoBarrier_Store(volatile Atomic64 *ptr, Atomic64 value) {
  *ptr = value;
}

inline void Acquire_Store(volatile Atomic64 *ptr, Atomic64 value) {
  *ptr = value;
  // This can't be _lwsync(); we need to order the immediately
  // preceding stores against any load that may follow, but lwsync
  // doesn't guarantee that.
  _sync();
}

inline void Release_Store(volatile Atomic64 *ptr, Atomic64 value) {
  _lwsync();
  *ptr = value;
}

inline Atomic64 NoBarrier_Load(volatile const Atomic64 *ptr) {
  return *ptr;
}

inline Atomic64 Acquire_Load(volatile const Atomic64 *ptr) {
  Atomic64 value = *ptr;
  _lwsync();
  return value;
}

inline Atomic64 Release_Load(volatile const Atomic64 *ptr) {
  // This can't be _lwsync(); we need to order the immediately
  // preceding stores against any load that may follow, but lwsync
  // doesn't guarantee that.
  _sync();
  return *ptr;
}

#endif

}   // namespace base::subtle
}   // namespace base

#endif  // BASE_ATOMICOPS_INTERNALS_LINUXPPC_H_
