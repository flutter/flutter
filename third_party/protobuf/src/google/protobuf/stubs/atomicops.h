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

// This header and the implementations for each platform (located in
// atomicops_internals_*) must be kept in sync with the upstream code (V8).

#ifndef GOOGLE_PROTOBUF_ATOMICOPS_H_
#define GOOGLE_PROTOBUF_ATOMICOPS_H_

// Don't include this file for people not concerned about thread safety.
#ifndef GOOGLE_PROTOBUF_NO_THREAD_SAFETY

#include <google/protobuf/stubs/platform_macros.h>

namespace google {
namespace protobuf {
namespace internal {

typedef int32 Atomic32;
#ifdef GOOGLE_PROTOBUF_ARCH_64_BIT
// We need to be able to go between Atomic64 and AtomicWord implicitly.  This
// means Atomic64 and AtomicWord should be the same type on 64-bit.
#if defined(__ILP32__) || defined(GOOGLE_PROTOBUF_OS_NACL)
// NaCl's intptr_t is not actually 64-bits on 64-bit!
// http://code.google.com/p/nativeclient/issues/detail?id=1162
typedef int64 Atomic64;
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
#ifdef GOOGLE_PROTOBUF_ARCH_64_BIT
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
#endif  // GOOGLE_PROTOBUF_ARCH_64_BIT

}  // namespace internal
}  // namespace protobuf
}  // namespace google

// Include our platform specific implementation.
#define GOOGLE_PROTOBUF_ATOMICOPS_ERROR \
#error "Atomic operations are not supported on your platform"

// ThreadSanitizer, http://clang.llvm.org/docs/ThreadSanitizer.html.
#if defined(THREAD_SANITIZER)
#include <google/protobuf/stubs/atomicops_internals_tsan.h>
// MSVC.
#elif defined(_MSC_VER)
#if defined(GOOGLE_PROTOBUF_ARCH_IA32) || defined(GOOGLE_PROTOBUF_ARCH_X64)
#include <google/protobuf/stubs/atomicops_internals_x86_msvc.h>
#else
GOOGLE_PROTOBUF_ATOMICOPS_ERROR
#endif

// Apple.
#elif defined(GOOGLE_PROTOBUF_OS_APPLE)
#include <google/protobuf/stubs/atomicops_internals_macosx.h>

// GCC.
#elif defined(__GNUC__)
#if defined(GOOGLE_PROTOBUF_ARCH_IA32) || defined(GOOGLE_PROTOBUF_ARCH_X64)
#include <google/protobuf/stubs/atomicops_internals_x86_gcc.h>
#elif defined(GOOGLE_PROTOBUF_ARCH_ARM)
#include <google/protobuf/stubs/atomicops_internals_arm_gcc.h>
#elif defined(GOOGLE_PROTOBUF_ARCH_AARCH64)
#include <google/protobuf/stubs/atomicops_internals_arm64_gcc.h>
#elif defined(GOOGLE_PROTOBUF_ARCH_ARM_QNX)
#include <google/protobuf/stubs/atomicops_internals_arm_qnx.h>
#elif defined(GOOGLE_PROTOBUF_ARCH_MIPS) || defined(GOOGLE_PROTOBUF_ARCH_MIPS64)
#include <google/protobuf/stubs/atomicops_internals_mips_gcc.h>
#elif defined(__pnacl__)
#include <google/protobuf/stubs/atomicops_internals_pnacl.h>
#else
GOOGLE_PROTOBUF_ATOMICOPS_ERROR
#endif

// Unknown.
#else
GOOGLE_PROTOBUF_ATOMICOPS_ERROR
#endif

// On some platforms we need additional declarations to make AtomicWord
// compatible with our other Atomic* types.
#if defined(GOOGLE_PROTOBUF_OS_APPLE)
#include <google/protobuf/stubs/atomicops_internals_atomicword_compat.h>
#endif

#undef GOOGLE_PROTOBUF_ATOMICOPS_ERROR

#endif  // GOOGLE_PROTOBUF_NO_THREAD_SAFETY

#endif  // GOOGLE_PROTOBUF_ATOMICOPS_H_
