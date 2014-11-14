// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/inspector/ScriptAsyncCallStack.h"

namespace blink {

DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(ScriptAsyncCallStack);

PassRefPtr<ScriptAsyncCallStack> ScriptAsyncCallStack::create(const String& description, PassRefPtr<ScriptCallStack> callStack, PassRefPtr<ScriptAsyncCallStack> asyncStackTrace)
{
    return adoptRef(new ScriptAsyncCallStack(description, callStack, asyncStackTrace));
}

ScriptAsyncCallStack::ScriptAsyncCallStack(const String& description, PassRefPtr<ScriptCallStack> callStack, PassRefPtr<ScriptAsyncCallStack> asyncStackTrace)
    : m_description(description)
    , m_callStack(callStack)
    , m_asyncStackTrace(asyncStackTrace)
{
    ASSERT(m_callStack);
}

} // namespace blink
