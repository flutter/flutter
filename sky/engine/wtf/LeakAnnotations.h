/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 * Copyright (C) 2013 Samsung Electronics. All rights reserved.
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
 */

#ifndef SKY_ENGINE_WTF_LEAKANNOTATIONS_H_
#define SKY_ENGINE_WTF_LEAKANNOTATIONS_H_

// This file defines macros which can be used to annotate intentional memory
// leaks. Support for annotations is implemented in HeapChecker and
// LeakSanitizer. Annotated objects will be treated as a source of live
// pointers, i.e. any heap objects reachable by following pointers from an
// annotated object will not be reported as leaks.
//
// WTF_ANNOTATE_SCOPED_MEMORY_LEAK: all allocations made in the current scope
// will be annotated as leaks.
// WTF_ANNOTATE_LEAKING_OBJECT_PTR(X): the heap object referenced by pointer X
// will be annotated as a leak.
//
// Note that HeapChecker will report a fatal error if an object which has been
// annotated with ANNOTATE_LEAKING_OBJECT_PTR is later deleted (but
// LeakSanitizer won't).

#include "flutter/sky/engine/wtf/Noncopyable.h"

namespace WTF {

#if USE(LEAK_SANITIZER)
extern "C" {
void __lsan_disable();
void __lsan_enable();
void __lsan_ignore_object(const void* p);
}  // extern "C"

class LeakSanitizerDisabler {
  WTF_MAKE_NONCOPYABLE(LeakSanitizerDisabler);

 public:
  LeakSanitizerDisabler() { __lsan_disable(); }

  ~LeakSanitizerDisabler() { __lsan_enable(); }
};

#define WTF_ANNOTATE_SCOPED_MEMORY_LEAK             \
  WTF::LeakSanitizerDisabler leakSanitizerDisabler; \
  static_cast<void>(0)

#define WTF_ANNOTATE_LEAKING_OBJECT_PTR(X) WTF::__lsan_ignore_object(X)

#else  // USE(LEAK_SANITIZER)

// If Leak Sanitizer is not being used, the annotations should be no-ops.
#define WTF_ANNOTATE_SCOPED_MEMORY_LEAK
#define WTF_ANNOTATE_LEAKING_OBJECT_PTR(X)

#endif  // USE(LEAK_SANITIZER)

}  // namespace WTF

#endif  // SKY_ENGINE_WTF_LEAKANNOTATIONS_H_
