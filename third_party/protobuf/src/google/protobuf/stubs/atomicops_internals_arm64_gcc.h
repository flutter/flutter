// Protocol Buffers - Google's data interchange format
// Copyright 2012 Google Inc.  All rights reserved.
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

// This file is an internal atomic implementation, use atomicops.h instead.

#ifndef GOOGLE_PROTOBUF_ATOMICOPS_INTERNALS_ARM64_GCC_H_
#define GOOGLE_PROTOBUF_ATOMICOPS_INTERNALS_ARM64_GCC_H_

namespace google {
namespace protobuf {
namespace internal {

inline void MemoryBarrier() {
  __asm__ __volatile__ ("dmb ish" ::: "memory");  // NOLINT
}

// NoBarrier versions of the operation include "memory" in the clobber list.
// This is not required for direct usage of the NoBarrier versions of the
// operations. However this is required for correctness when they are used as
// part of the Acquire or Release versions, to ensure that nothing from outside
// the call is reordered between the operation and the memory barrier. This does
// not change the code generated, so has no or minimal impact on the
// NoBarrier operations.

inline Atomic32 NoBarrier_CompareAndSwap(volatile Atomic32* ptr,
                                         Atomic32 old_value,
                                         Atomic32 new_value) {
  Atomic32 prev;
  int32_t temp;

  __asm__ __volatile__ (  // NOLINT
    "0:                                    \n\t"
    "ldxr %w[prev], %[ptr]                 \n\t"  // Load the previous value.
    "cmp %w[prev], %w[old_value]           \n\t"
    "bne 1f                                \n\t"
    "stxr %w[temp], %w[new_value], %[ptr]  \n\t"  // Try to store the new value.
    "cbnz %w[temp], 0b                     \n\t"  // Retry if it did not work.
    "1:                                    \n\t"
    : [prev]"=&r" (prev),
      [temp]"=&r" (temp),
      [ptr]"+Q" (*ptr)
    : [old_value]"IJr" (old_value),
      [new_value]"r" (new_value)
    : "cc", "memory"
  );  // NOLINT

  return prev;
}

inline Atomic32 NoBarrier_AtomicExchange(volatile Atomic32* ptr,
                                         Atomic32 new_value) {
  Atomic32 result;
  int32_t temp;

  __asm__ __volatile__ (  // NOLINT
    "0:                                    \n\t"
    "ldxr %w[result], %[ptr]               \n\t"  // Load the previous value.
    "stxr %w[temp], %w[new_value], %[ptr]  \n\t"  // Try to store the new value.
    "cbnz %w[temp], 0b                     \n\t"  // Retry if it did not work.
    : [result]"=&r" (result),
      [temp]"=&r" (temp),
      [ptr]"+Q" (*ptr)
    : [new_value]"r" (new_value)
    : "memory"
  );  // NOLINT

  return result;
}

inline Atomic32 NoBarrier_AtomicIncrement(volatile Atomic32* ptr,
                                          Atomic32 increment) {
  Atomic32 result;
  int32_t temp;

  __asm__ __volatile__ (  // NOLINT
    "0:                                       \n\t"
    "ldxr %w[result], %[ptr]                  \n\t"  // Load the previous value.
    "add %w[result], %w[result], %w[increment]\n\t"
    "stxr %w[temp], %w[result], %[ptr]        \n\t"  // Try to store the result.
    "cbnz %w[temp], 0b                        \n\t"  // Retry on failure.
    : [result]"=&r" (result),
      [temp]"=&r" (temp),
      [ptr]"+Q" (*ptr)
    : [increment]"IJr" (increment)
    : "memory"
  );  // NOLINT

  return result;
}

inline Atomic32 Barrier_AtomicIncrement(volatile Atomic32* ptr,
                                        Atomic32 increment) {
  MemoryBarrier();
  Atomic32 result = NoBarrier_AtomicIncrement(ptr, increment);
  MemoryBarrier();

  return result;
}

inline Atomic32 Acquire_CompareAndSwap(volatile Atomic32* ptr,
                                       Atomic32 old_value,
                                       Atomic32 new_value) {
  Atomic32 prev = NoBarrier_CompareAndSwap(ptr, old_value, new_value);
  MemoryBarrier();

  return prev;
}

inline Atomic32 Release_CompareAndSwap(volatile Atomic32* ptr,
                                       Atomic32 old_value,
                                       Atomic32 new_value) {
  MemoryBarrier();
  Atomic32 prev = NoBarrier_CompareAndSwap(ptr, old_value, new_value);

  return prev;
}

inline void NoBarrier_Store(volatile Atomic32* ptr, Atomic32 value) {
  *ptr = value;
}

inline void Acquire_Store(volatile Atomic32* ptr, Atomic32 value) {
  *ptr = value;
  MemoryBarrier();
}

inline void Release_Store(volatile Atomic32* ptr, Atomic32 value) {
  __asm__ __volatile__ (  // NOLINT
    "stlr %w[value], %[ptr]  \n\t"
    : [ptr]"=Q" (*ptr)
    : [value]"r" (value)
    : "memory"
  );  // NOLINT
}

inline Atomic32 NoBarrier_Load(volatile const Atomic32* ptr) {
  return *ptr;
}

inline Atomic32 Acquire_Load(volatile const Atomic32* ptr) {
  Atomic32 value;

  __asm__ __volatile__ (  // NOLINT
    "ldar %w[value], %[ptr]  \n\t"
    : [value]"=r" (value)
    : [ptr]"Q" (*ptr)
    : "memory"
  );  // NOLINT

  return value;
}

inline Atomic32 Release_Load(volatile const Atomic32* ptr) {
  MemoryBarrier();
  return *ptr;
}

// 64-bit versions of the operations.
// See the 32-bit versions for comments.

inline Atomic64 NoBarrier_CompareAndSwap(volatile Atomic64* ptr,
                                         Atomic64 old_value,
                                         Atomic64 new_value) {
  Atomic64 prev;
  int32_t temp;

  __asm__ __volatile__ (  // NOLINT
    "0:                                    \n\t"
    "ldxr %[prev], %[ptr]                  \n\t"
    "cmp %[prev], %[old_value]             \n\t"
    "bne 1f                                \n\t"
    "stxr %w[temp], %[new_value], %[ptr]   \n\t"
    "cbnz %w[temp], 0b                     \n\t"
    "1:                                    \n\t"
    : [prev]"=&r" (prev),
      [temp]"=&r" (temp),
      [ptr]"+Q" (*ptr)
    : [old_value]"IJr" (old_value),
      [new_value]"r" (new_value)
    : "cc", "memory"
  );  // NOLINT

  return prev;
}

inline Atomic64 NoBarrier_AtomicExchange(volatile Atomic64* ptr,
                                         Atomic64 new_value) {
  Atomic64 result;
  int32_t temp;

  __asm__ __volatile__ (  // NOLINT
    "0:                                    \n\t"
    "ldxr %[result], %[ptr]                \n\t"
    "stxr %w[temp], %[new_value], %[ptr]   \n\t"
    "cbnz %w[temp], 0b                     \n\t"
    : [result]"=&r" (result),
      [temp]"=&r" (temp),
      [ptr]"+Q" (*ptr)
    : [new_value]"r" (new_value)
    : "memory"
  );  // NOLINT

  return result;
}

inline Atomic64 NoBarrier_AtomicIncrement(volatile Atomic64* ptr,
                                          Atomic64 increment) {
  Atomic64 result;
  int32_t temp;

  __asm__ __volatile__ (  // NOLINT
    "0:                                     \n\t"
    "ldxr %[result], %[ptr]                 \n\t"
    "add %[result], %[result], %[increment] \n\t"
    "stxr %w[temp], %[result], %[ptr]       \n\t"
    "cbnz %w[temp], 0b                      \n\t"
    : [result]"=&r" (result),
      [temp]"=&r" (temp),
      [ptr]"+Q" (*ptr)
    : [increment]"IJr" (increment)
    : "memory"
  );  // NOLINT

  return result;
}

inline Atomic64 Barrier_AtomicIncrement(volatile Atomic64* ptr,
                                        Atomic64 increment) {
  MemoryBarrier();
  Atomic64 result = NoBarrier_AtomicIncrement(ptr, increment);
  MemoryBarrier();

  return result;
}

inline Atomic64 Acquire_CompareAndSwap(volatile Atomic64* ptr,
                                       Atomic64 old_value,
                                       Atomic64 new_value) {
  Atomic64 prev = NoBarrier_CompareAndSwap(ptr, old_value, new_value);
  MemoryBarrier();

  return prev;
}

inline Atomic64 Release_CompareAndSwap(volatile Atomic64* ptr,
                                       Atomic64 old_value,
                                       Atomic64 new_value) {
  MemoryBarrier();
  Atomic64 prev = NoBarrier_CompareAndSwap(ptr, old_value, new_value);

  return prev;
}

inline void NoBarrier_Store(volatile Atomic64* ptr, Atomic64 value) {
  *ptr = value;
}

inline void Acquire_Store(volatile Atomic64* ptr, Atomic64 value) {
  *ptr = value;
  MemoryBarrier();
}

inline void Release_Store(volatile Atomic64* ptr, Atomic64 value) {
  __asm__ __volatile__ (  // NOLINT
    "stlr %x[value], %[ptr]  \n\t"
    : [ptr]"=Q" (*ptr)
    : [value]"r" (value)
    : "memory"
  );  // NOLINT
}

inline Atomic64 NoBarrier_Load(volatile const Atomic64* ptr) {
  return *ptr;
}

inline Atomic64 Acquire_Load(volatile const Atomic64* ptr) {
  Atomic64 value;

  __asm__ __volatile__ (  // NOLINT
    "ldar %x[value], %[ptr]  \n\t"
    : [value]"=r" (value)
    : [ptr]"Q" (*ptr)
    : "memory"
  );  // NOLINT

  return value;
}

inline Atomic64 Release_Load(volatile const Atomic64* ptr) {
  MemoryBarrier();
  return *ptr;
}

}  // namespace internal
}  // namespace protobuf
}  // namespace google

#endif  // GOOGLE_PROTOBUF_ATOMICOPS_INTERNALS_ARM64_GCC_H_
