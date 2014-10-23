// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/inspector/ScriptAsyncCallStack.h"

namespace blink {

DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(ScriptAsyncCallStack);

PassRefPtrWillBeRawPtr<ScriptAsyncCallStack> ScriptAsyncCallStack::create(const String& description, PassRefPtrWillBeRawPtr<ScriptCallStack> callStack, PassRefPtrWillBeRawPtr<ScriptAsyncCallStack> asyncStackTrace)
{
    return adoptRefWillBeNoop(new ScriptAsyncCallStack(description, callStack, asyncStackTrace));
}

ScriptAsyncCallStack::ScriptAsyncCallStack(const String& description, PassRefPtrWillBeRawPtr<ScriptCallStack> callStack, PassRefPtrWillBeRawPtr<ScriptAsyncCallStack> asyncStackTrace)
    : m_description(description)
    , m_callStack(callStack)
    , m_asyncStackTrace(asyncStackTrace)
{
    ASSERT(m_callStack);
}

void ScriptAsyncCallStack::trace(Visitor* visitor)
{
    visitor->trace(m_callStack);
    visitor->trace(m_asyncStackTrace);
}

} // namespace blink
