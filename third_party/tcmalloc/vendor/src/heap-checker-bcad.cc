// Copyright (c) 2005, Google Inc.
// All rights reserved.
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

// ---
// All Rights Reserved.
//
// Author: Maxim Lifantsev
//
// A file to ensure that components of heap leak checker run before
// all global object constructors and after all global object
// destructors.
//
// This file must be the last library any binary links against.
// Otherwise, the heap checker may not be able to run early enough to
// catalog all the global objects in your program.  If this happens,
// and later in the program you allocate memory and have one of these
// "uncataloged" global objects point to it, the heap checker will
// consider that allocation to be a leak, even though it's not (since
// the allocated object is reachable from global data and hence "live").

#include <stdlib.h>      // for abort()
#include <gperftools/malloc_extension.h>

// A dummy variable to refer from heap-checker.cc.  This is to make
// sure this file is not optimized out by the linker.
bool heap_leak_checker_bcad_variable;

extern void HeapLeakChecker_AfterDestructors();  // in heap-checker.cc

// A helper class to ensure that some components of heap leak checking
// can happen before construction and after destruction
// of all global/static objects.
class HeapLeakCheckerGlobalPrePost {
 public:
  HeapLeakCheckerGlobalPrePost() {
    if (count_ == 0) {
      // The 'new int' will ensure that we have run an initial malloc
      // hook, which will set up the heap checker via
      // MallocHook_InitAtFirstAllocation_HeapLeakChecker.  See malloc_hook.cc.
      // This is done in this roundabout fashion in order to avoid self-deadlock
      // if we directly called HeapLeakChecker_BeforeConstructors here.
      delete new int;
      // This needs to be called before the first allocation of an STL
      // object, but after libc is done setting up threads (because it
      // calls setenv, which requires a thread-aware errno).  By
      // putting it here, we hope it's the first bit of code executed
      // after the libc global-constructor code.
      MallocExtension::Initialize();
    }
    ++count_;
  }
  ~HeapLeakCheckerGlobalPrePost() {
    if (count_ <= 0)  abort();
    --count_;
    if (count_ == 0)  HeapLeakChecker_AfterDestructors();
  }
 private:
  // Counter of constructions/destructions of objects of this class
  // (just in case there are more than one of them).
  static int count_;
};

int HeapLeakCheckerGlobalPrePost::count_ = 0;

// The early-construction/late-destruction global object.
static const HeapLeakCheckerGlobalPrePost heap_leak_checker_global_pre_post;
