/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
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

#ifndef V8RecursionScope_h
#define V8RecursionScope_h

#include "bindings/core/v8/V8PerIsolateData.h"
#include "core/dom/ExecutionContext.h"
#include "platform/ScriptForbiddenScope.h"
#include "wtf/Noncopyable.h"
#include <v8.h>

namespace blink {

// C++ calls into script contexts which are "owned" by WebKit (created in a
// process where WebKit.cpp initializes v8) must declare their type:
//
//   1. Calls into page/author script from a frame
//   2. Calls into page/author script from a worker
//   3. Calls into internal script (typically setup/teardown work)
//
// Debug-time checking of this is enforced via this class.
//
// Calls of type (1) should generally go through ScriptController, as inspector
// instrumentation is needed. ScriptController allocates V8RecursionScope for you.
// Calls of type (2) should always stack-allocate a V8RecursionScope in the same
// block as the call into script. Calls of type (3) should stack allocate a
// V8RecursionScope::MicrotaskSuppression -- this skips work that is spec'd to
// happen at the end of the outer-most script stack frame of calls into page script:
//
// http://www.whatwg.org/specs/web-apps/current-work/#perform-a-microtask-checkpoint
class V8RecursionScope {
    WTF_MAKE_NONCOPYABLE(V8RecursionScope);
public:
    V8RecursionScope(v8::Isolate* isolate, ExecutionContext* context)
        : m_isolate(isolate)
    {
        V8PerIsolateData::from(m_isolate)->incrementRecursionLevel();
        RELEASE_ASSERT(!ScriptForbiddenScope::isScriptForbidden());
        // If you want V8 to autorun microtasks, this class needs to have a
        // v8::Isolate::SuppressMicrotaskExecutionScope member.
        ASSERT(!isolate->WillAutorunMicrotasks());
    }

    ~V8RecursionScope()
    {
        if (!V8PerIsolateData::from(m_isolate)->decrementRecursionLevel())
            didLeaveScriptContext();
    }

    static int recursionLevel(v8::Isolate* isolate)
    {
        return V8PerIsolateData::from(isolate)->recursionLevel();
    }

#if ENABLE(ASSERT)
    static bool properlyUsed(v8::Isolate* isolate)
    {
        return recursionLevel(isolate) > 0 || V8PerIsolateData::from(isolate)->internalScriptRecursionLevel() > 0;
    }
#endif

    class MicrotaskSuppression {
    public:
        MicrotaskSuppression(v8::Isolate* isolate)
#if ENABLE(ASSERT)
            : m_isolate(isolate)
#endif
        {
            ASSERT(!ScriptForbiddenScope::isScriptForbidden());
#if ENABLE(ASSERT)
            V8PerIsolateData::from(m_isolate)->incrementInternalScriptRecursionLevel();
#endif
        }

        ~MicrotaskSuppression()
        {
#if ENABLE(ASSERT)
            V8PerIsolateData::from(m_isolate)->decrementInternalScriptRecursionLevel();
#endif
        }

    private:
#if ENABLE(ASSERT)
        v8::Isolate* m_isolate;
#endif
    };

private:
    void didLeaveScriptContext();

    v8::Isolate* m_isolate;
};

} // namespace blink

#endif // V8RecursionScope_h
