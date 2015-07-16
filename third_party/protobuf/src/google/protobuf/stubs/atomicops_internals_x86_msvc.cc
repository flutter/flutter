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

// The compilation of extension_set.cc fails when windows.h is included.
// Therefore we move the code depending on windows.h to this separate cc file.

// Don't compile this file for people not concerned about thread safety.
#ifndef GOOGLE_PROTOBUF_NO_THREAD_SAFETY

#include <google/protobuf/stubs/atomicops.h>

#ifdef GOOGLE_PROTOBUF_ATOMICOPS_INTERNALS_X86_MSVC_H_

#include <windows.h>

namespace google {
namespace protobuf {
namespace internal {

inline void MemoryBarrier() {
  // We use MemoryBarrier from WinNT.h
  ::MemoryBarrier();
}

Atomic32 NoBarrier_CompareAndSwap(volatile Atomic32* ptr,
                                  Atomic32 old_value,
                                  Atomic32 new_value) {
  LONG result = InterlockedCompareExchange(
      reinterpret_cast<volatile LONG*>(ptr),
      static_cast<LONG>(new_value),
      static_cast<LONG>(old_value));
  return static_cast<Atomic32>(result);
}

Atomic32 NoBarrier_AtomicExchange(volatile Atomic32* ptr,
                                  Atomic32 new_value) {
  LONG result = InterlockedExchange(
      reinterpret_cast<volatile LONG*>(ptr),
      static_cast<LONG>(new_value));
  return static_cast<Atomic32>(result);
}

Atomic32 Barrier_AtomicIncrement(volatile Atomic32* ptr,
                                 Atomic32 increment) {
  return InterlockedExchangeAdd(
      reinterpret_cast<volatile LONG*>(ptr),
      static_cast<LONG>(increment)) + increment;
}

#if defined(_WIN64)

// 64-bit low-level operations on 64-bit platform.

Atomic64 NoBarrier_CompareAndSwap(volatile Atomic64* ptr,
                                  Atomic64 old_value,
                                  Atomic64 new_value) {
  PVOID result = InterlockedCompareExchangePointer(
    reinterpret_cast<volatile PVOID*>(ptr),
    reinterpret_cast<PVOID>(new_value), reinterpret_cast<PVOID>(old_value));
  return reinterpret_cast<Atomic64>(result);
}

Atomic64 NoBarrier_AtomicExchange(volatile Atomic64* ptr,
                                  Atomic64 new_value) {
  PVOID result = InterlockedExchangePointer(
    reinterpret_cast<volatile PVOID*>(ptr),
    reinterpret_cast<PVOID>(new_value));
  return reinterpret_cast<Atomic64>(result);
}

Atomic64 Barrier_AtomicIncrement(volatile Atomic64* ptr,
                                 Atomic64 increment) {
  return InterlockedExchangeAdd64(
      reinterpret_cast<volatile LONGLONG*>(ptr),
      static_cast<LONGLONG>(increment)) + increment;
}

#endif  // defined(_WIN64)

}  // namespace internal
}  // namespace protobuf
}  // namespace google

#endif  // GOOGLE_PROTOBUF_ATOMICOPS_INTERNALS_X86_MSVC_H_
#endif  // GOOGLE_PROTOBUF_NO_THREAD_SAFETY
