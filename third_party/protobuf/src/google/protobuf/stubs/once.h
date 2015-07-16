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
//
// This is basically a portable version of pthread_once().
//
// This header declares:
// * A type called ProtobufOnceType.
// * A macro GOOGLE_PROTOBUF_DECLARE_ONCE() which declares a variable of type
//   ProtobufOnceType.  This is the only legal way to declare such a variable.
//   The macro may only be used at the global scope (you cannot create local or
//   class member variables of this type).
// * A function GoogleOnceInit(ProtobufOnceType* once, void (*init_func)()).
//   This function, when invoked multiple times given the same ProtobufOnceType
//   object, will invoke init_func on the first call only, and will make sure
//   none of the calls return before that first call to init_func has finished.
// * The user can provide a parameter which GoogleOnceInit() forwards to the
//   user-provided function when it is called. Usage example:
//     int a = 10;
//     GoogleOnceInit(&my_once, &MyFunctionExpectingIntArgument, &a);
// * This implementation guarantees that ProtobufOnceType is a POD (i.e. no
//   static initializer generated).
//
// This implements a way to perform lazy initialization.  It's more efficient
// than using mutexes as no lock is needed if initialization has already
// happened.
//
// Example usage:
//   void Init();
//   GOOGLE_PROTOBUF_DECLARE_ONCE(once_init);
//
//   // Calls Init() exactly once.
//   void InitOnce() {
//     GoogleOnceInit(&once_init, &Init);
//   }
//
// Note that if GoogleOnceInit() is called before main() has begun, it must
// only be called by the thread that will eventually call main() -- that is,
// the thread that performs dynamic initialization.  In general this is a safe
// assumption since people don't usually construct threads before main() starts,
// but it is technically not guaranteed.  Unfortunately, Win32 provides no way
// whatsoever to statically-initialize its synchronization primitives, so our
// only choice is to assume that dynamic initialization is single-threaded.

#ifndef GOOGLE_PROTOBUF_STUBS_ONCE_H__
#define GOOGLE_PROTOBUF_STUBS_ONCE_H__

#include <google/protobuf/stubs/atomicops.h>
#include <google/protobuf/stubs/common.h>

namespace google {
namespace protobuf {

#ifdef GOOGLE_PROTOBUF_NO_THREAD_SAFETY

typedef bool ProtobufOnceType;

#define GOOGLE_PROTOBUF_ONCE_INIT false

inline void GoogleOnceInit(ProtobufOnceType* once, void (*init_func)()) {
  if (!*once) {
    *once = true;
    init_func();
  }
}

template <typename Arg>
inline void GoogleOnceInit(ProtobufOnceType* once, void (*init_func)(Arg),
    Arg arg) {
  if (!*once) {
    *once = true;
    init_func(arg);
  }
}

#else

enum {
  ONCE_STATE_UNINITIALIZED = 0,
  ONCE_STATE_EXECUTING_CLOSURE = 1,
  ONCE_STATE_DONE = 2
};

typedef internal::AtomicWord ProtobufOnceType;

#define GOOGLE_PROTOBUF_ONCE_INIT ::google::protobuf::ONCE_STATE_UNINITIALIZED

LIBPROTOBUF_EXPORT
void GoogleOnceInitImpl(ProtobufOnceType* once, Closure* closure);

LIBPROTOBUF_EXPORT
void GoogleOnceInit(ProtobufOnceType* once, void (*init_func)());

template <typename Arg>
inline void GoogleOnceInit(ProtobufOnceType* once, void (*init_func)(Arg*),
    Arg* arg) {
  if (internal::Acquire_Load(once) != ONCE_STATE_DONE) {
    internal::FunctionClosure1<Arg*> func(init_func, false, arg);
    GoogleOnceInitImpl(once, &func);
  }
}

#endif  // GOOGLE_PROTOBUF_NO_THREAD_SAFETY

#define GOOGLE_PROTOBUF_DECLARE_ONCE(NAME) \
  ::google::protobuf::ProtobufOnceType NAME = GOOGLE_PROTOBUF_ONCE_INIT

}  // namespace protobuf
}  // namespace google

#endif  // GOOGLE_PROTOBUF_STUBS_ONCE_H__
