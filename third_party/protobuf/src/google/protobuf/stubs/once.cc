// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.  All rights reserved.
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

// Author: kenton@google.com (Kenton Varda)
//
// emulates google3/base/once.h
//
// This header is intended to be included only by internal .cc files and
// generated .pb.cc files.  Users should not use this directly.

#include <google/protobuf/stubs/once.h>

#ifndef GOOGLE_PROTOBUF_NO_THREAD_SAFETY

#ifdef _WIN32
#include <windows.h>
#else
#include <sched.h>
#endif

#include <google/protobuf/stubs/atomicops.h>

namespace google {
namespace protobuf {

namespace {

void SchedYield() {
#ifdef _WIN32
  Sleep(0);
#else  // POSIX
  sched_yield();
#endif
}

}  // namespace

void GoogleOnceInitImpl(ProtobufOnceType* once, Closure* closure) {
  internal::AtomicWord state = internal::Acquire_Load(once);
  // Fast path. The provided closure was already executed.
  if (state == ONCE_STATE_DONE) {
    return;
  }
  // The closure execution did not complete yet. The once object can be in one
  // of the two following states:
  //   - UNINITIALIZED: We are the first thread calling this function.
  //   - EXECUTING_CLOSURE: Another thread is already executing the closure.
  //
  // First, try to change the state from UNINITIALIZED to EXECUTING_CLOSURE
  // atomically.
  state = internal::Acquire_CompareAndSwap(
      once, ONCE_STATE_UNINITIALIZED, ONCE_STATE_EXECUTING_CLOSURE);
  if (state == ONCE_STATE_UNINITIALIZED) {
    // We are the first thread to call this function, so we have to call the
    // closure.
    closure->Run();
    internal::Release_Store(once, ONCE_STATE_DONE);
  } else {
    // Another thread has already started executing the closure. We need to
    // wait until it completes the initialization.
    while (state == ONCE_STATE_EXECUTING_CLOSURE) {
      // Note that futex() could be used here on Linux as an improvement.
      SchedYield();
      state = internal::Acquire_Load(once);
    }
  }
}

void GoogleOnceInit(ProtobufOnceType* once, void (*init_func)()) {
  if (internal::Acquire_Load(once) != ONCE_STATE_DONE) {
    internal::FunctionClosure0 func(init_func, false);
    GoogleOnceInitImpl(once, &func);
  }
}

}  // namespace protobuf
}  // namespace google

#endif  // GOOGLE_PROTOBUF_NO_THREAD_SAFETY
