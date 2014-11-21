/*
 * Copyright (C) 2007 Apple Inc.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "sky/engine/config.h"
#include "sky/engine/core/frame/History.h"

#include "sky/engine/bindings/core/v8/ExceptionState.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/ExceptionCode.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/platform/weborigin/KURL.h"
#include "sky/engine/wtf/MainThread.h"

namespace blink {

History::History(LocalFrame* frame)
    : DOMWindowProperty(frame)
    , m_lastStateObjectRequested(nullptr)
{
}

unsigned History::length() const
{
    // FIXME(sky): remove
    return 0;
}

SerializedScriptValue* History::state()
{
    m_lastStateObjectRequested = stateInternal();
    return m_lastStateObjectRequested.get();
}

SerializedScriptValue* History::stateInternal() const
{
    if (!m_frame)
        return 0;

    return 0;
}

bool History::stateChanged() const
{
    return m_lastStateObjectRequested != stateInternal();
}

bool History::isSameAsCurrentState(SerializedScriptValue* state) const
{
    return state == stateInternal();
}

void History::back(ExecutionContext* context)
{
    go(context, -1);
}

void History::forward(ExecutionContext* context)
{
    go(context, 1);
}

void History::go(ExecutionContext* context, int distance)
{
    // FIXME(sky): reimplement
}

KURL History::urlForState(const String& urlString)
{
    Document* document = m_frame->document();
    if (urlString.isEmpty())
        return document->url();
    return KURL(document->url(), urlString);
}

void History::stateObjectAdded(PassRefPtr<SerializedScriptValue> data, const String& /* title */, const String& urlString, FrameLoadType type, ExceptionState& exceptionState)
{
    // FIXME(sky): re-implement.
}

} // namespace blink
