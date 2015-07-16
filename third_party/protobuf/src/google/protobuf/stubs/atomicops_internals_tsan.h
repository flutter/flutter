// Protocol Buffers - Google's data interchange format
// Copyright 2013 Google Inc.  All rights reserved.
// http://code.google.com/p/protobuf/
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

// This file is an internal atomic implementation for compiler-based
// ThreadSanitizer (http://clang.llvm.org/docs/ThreadSanitizer.html).
// Use atomicops.h instead.

#ifndef GOOGLE_PROTOBUF_ATOMICOPS_INTERNALS_TSAN_H_
#define GOOGLE_PROTOBUF_ATOMICOPS_INTERNALS_TSAN_H_

#define ATOMICOPS_COMPILER_BARRIER() __asm__ __volatile__("" : : : "memory")

#include <sanitizer/tsan_interface_atomic.h>

namespace google {
namespace protobuf {
namespace internal {

inline Atomic32 NoBarrier_CompareAndSwap(volatile Atomic32 *ptr,
                                         Atomic32 old_value,
                                         Atomic32 new_value) {
  Atomic32 cmp = old_value;
  __tsan_atomic32_compare_exchange_strong(ptr, &cmp, new_value,
      __tsan_memory_order_relaxed, __tsan_memory_order_relaxed);
  return cmp;
}

inline Atomic32 NoBarrier_AtomicExchange(volatile Atomic32 *ptr,
                                         Atomic32 new_value) {
  return __tsan_atomic32_exchange(ptr, new_value,
      __tsan_memory_order_relaxed);
}

inline Atomic32 Acquire_AtomicExchange(volatile Atomic32 *ptr,
                                       Atomic32 new_value) {
  return __tsan_atomic32_exchange(ptr, new_value,
      __tsan_memory_order_acquire);
}

inline Atomic32 Release_AtomicExchange(volatile Atomic32 *ptr,
                                       Atomic32 new_value) {
  return __tsan_atomic32_exchange(ptr, new_value,
      __tsan_memory_order_release);
}

inline Atomic32 NoBarrier_AtomicIncrement(volatile Atomic32 *ptr,
                                          Atomic32 increment) {
  return increment + __tsan_atomic32_fetch_add(ptr, increment,
      __tsan_memory_order_relaxed);
}

inline Atomic32 Barrier_AtomicIncrement(volatile Atomic32 *ptr,
                                        Atomic32 increment) {
  return increment + __tsan_atomic32_fetch_add(ptr, increment,
      __tsan_memory_order_acq_rel);
}

inline Atomic32 Acquire_CompareAndSwap(volatile Atomic32 *ptr,
                                       Atomic32 old_value,
                                       Atomic32 new_value) {
  Atomic32 cmp = old_value;
  __tsan_atomic32_compare_exchange_strong(ptr, &cmp, new_value,
      __tsan_memory_order_acquire, __tsan_memory_order_acquire);
  return cmp;
}

inline Atomic32 Release_CompareAndSwap(volatile Atomic32 *ptr,
                                       Atomic32 old_value,
                                       Atomic32 new_value) {
  Atomic32 cmp = old_value;
  __tsan_atomic32_compare_exchange_strong(ptr, &cmp, new_value,
      __tsan_memory_order_release, __tsan_memory_order_relaxed);
  return cmp;
}

inline void NoBarrier_Store(volatile Atomic32 *ptr, Atomic32 value) {
  __tsan_atomic32_store(ptr, value, __tsan_memory_order_relaxed);
}

inline void Acquire_Store(volatile Atomic32 *ptr, Atomic32 value) {
  __tsan_atomic32_store(ptr, value, __tsan_memory_order_relaxed);
  __tsan_atomic_thread_fence(__tsan_memory_order_seq_cst);
}

inline void Release_Store(volatile Atomic32 *ptr, Atomic32 value) {
  __tsan_atomic32_store(ptr, value, __tsan_memory_order_release);
}

inline Atomic32 NoBarrier_Load(volatile const Atomic32 *ptr) {
  return __tsan_atomic32_load(ptr, __tsan_memory_order_relaxed);
}

inline Atomic32 Acquire_Load(volatile const Atomic32 *ptr) {
  return __tsan_atomic32_load(ptr, __tsan_memory_order_acquire);
}

inline Atomic32 Release_Load(volatile const Atomic32 *ptr) {
  __tsan_atomic_thread_fence(__tsan_memory_order_seq_cst);
  return __tsan_atomic32_load(ptr, __tsan_memory_order_relaxed);
}

inline Atomic64 NoBarrier_CompareAndSwap(volatile Atomic64 *ptr,
                                         Atomic64 old_value,
                                         Atomic64 new_value) {
  Atomic64 cmp = old_value;
  __tsan_atomic64_compare_exchange_strong(ptr, &cmp, new_value,
      __tsan_memory_order_relaxed, __tsan_memory_order_relaxed);
  return cmp;
}

inline Atomic64 NoBarrier_AtomicExchange(volatile Atomic64 *ptr,
                                         Atomic64 new_value) {
  return __tsan_atomic64_exchange(ptr, new_value, __tsan_memory_order_relaxed);
}

inline Atomic64 Acquire_AtomicExchange(volatile Atomic64 *ptr,
                                       Atomic64 new_value) {
  return __tsan_atomic64_exchange(ptr, new_value, __tsan_memory_order_acquire);
}

inline Atomic64 Release_AtomicExchange(volatile Atomic64 *ptr,
                                       Atomic64 new_value) {
  return __tsan_atomic64_exchange(ptr, new_value, __tsan_memory_order_release);
}

inline Atomic64 NoBarrier_AtomicIncrement(volatile Atomic64 *ptr,
                                          Atomic64 increment) {
  return increment + __tsan_atomic64_fetch_add(ptr, increment,
      __tsan_memory_order_relaxed);
}

inline Atomic64 Barrier_AtomicIncrement(volatile Atomic64 *ptr,
                                        Atomic64 increment) {
  return increment + __tsan_atomic64_fetch_add(ptr, increment,
      __tsan_memory_order_acq_rel);
}

inline void NoBarrier_Store(volatile Atomic64 *ptr, Atomic64 value) {
  __tsan_atomic64_store(ptr, value, __tsan_memory_order_relaxed);
}

inline void Acquire_Store(volatile Atomic64 *ptr, Atomic64 value) {
  __tsan_atomic64_store(ptr, value, __tsan_memory_order_relaxed);
  __tsan_atomic_thread_fence(__tsan_memory_order_seq_cst);
}

inline void Release_Store(volatile Atomic64 *ptr, Atomic64 value) {
  __tsan_atomic64_store(ptr, value, __tsan_memory_order_release);
}

inline Atomic64 NoBarrier_Load(volatile const Atomic64 *ptr) {
  return __tsan_atomic64_load(ptr, __tsan_memory_order_relaxed);
}

inline Atomic64 Acquire_Load(volatile const Atomic64 *ptr) {
  return __tsan_atomic64_load(ptr, __tsan_memory_order_acquire);
}

inline Atomic64 Release_Load(volatile const Atomic64 *ptr) {
  __tsan_atomic_thread_fence(__tsan_memory_order_seq_cst);
  return __tsan_atomic64_load(ptr, __tsan_memory_order_relaxed);
}

inline Atomic64 Acquire_CompareAndSwap(volatile Atomic64 *ptr,
                                       Atomic64 old_value,
                                       Atomic64 new_value) {
  Atomic64 cmp = old_value;
  __tsan_atomic64_compare_exchange_strong(ptr, &cmp, new_value,
      __tsan_memory_order_acquire, __tsan_memory_order_acquire);
  return cmp;
}

inline Atomic64 Release_CompareAndSwap(volatile Atomic64 *ptr,
                                       Atomic64 old_value,
                                       Atomic64 new_value) {
  Atomic64 cmp = old_value;
  __tsan_atomic64_compare_exchange_strong(ptr, &cmp, new_value,
      __tsan_memory_order_release, __tsan_memory_order_relaxed);
  return cmp;
}

inline void MemoryBarrier() {
  __tsan_atomic_thread_fence(__tsan_memory_order_seq_cst);
}

}  // namespace internal
}  // namespace protobuf
}  // namespace google

#undef ATOMICOPS_COMPILER_BARRIER

#endif  // GOOGLE_PROTOBUF_ATOMICOPS_INTERNALS_TSAN_H_
