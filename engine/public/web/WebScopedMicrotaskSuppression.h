/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#ifndef WebScopedMicrotaskSuppression_h
#define WebScopedMicrotaskSuppression_h

#include "../platform/WebPrivateOwnPtr.h"

namespace blink {

// This class wraps V8RecursionScope::BypassMicrotaskCheckpoint. Please
// see V8RecursionScope.h for full usage. Short story: Embedder calls into
// script contexts which also host page script must do one of two things:
//
//   1. If the call may cause any page/author script to run, it must be
//      captured for pre/post work (e.g. inspector instrumentation/microtask
//      delivery) and thus be invoked through WebFrame (e.g. executeScript*,
//      callFunction*).
//   2. If the call will not cause any page/author script to run, the call
//      should be made directly via the v8 context, but the callsite must be
//      accompanied by a stack allocated WebScopedMicrotaskSuppression, e.g.:
//
//        ...
//        {
//            blink::WebScopedMicrotaskSuppression suppression;
//            func->Call(global, argv, args);
//        }
//        ...
//
class WebScopedMicrotaskSuppression {
public:
    WebScopedMicrotaskSuppression() { initialize(); }
    ~WebScopedMicrotaskSuppression() { reset(); }

private:
    BLINK_EXPORT void initialize();
    BLINK_EXPORT void reset();

    // Always declare this data member. When assertions are on in
    // Release builds of Blink, this header may be included from
    // Chromium with different preprocessor options than used when
    // building Blink itself.
    class Impl;
    WebPrivateOwnPtr<Impl> m_impl;
};

} // WebKit

#endif
