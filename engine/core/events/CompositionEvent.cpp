/*
 * Copyright (C) 2009 Apple Inc. All rights reserved.
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
 *
 */

#include "config.h"
#include "core/events/CompositionEvent.h"

namespace blink {

CompositionEventInit::CompositionEventInit()
{
}

CompositionEvent::CompositionEvent()
    : m_activeSegmentStart(0)
    , m_activeSegmentEnd(0)
{
    ScriptWrappable::init(this);
    initializeSegments();
}

CompositionEvent::CompositionEvent(const AtomicString& type, PassRefPtrWillBeRawPtr<AbstractView> view, const String& data, const Vector<CompositionUnderline>& underlines)
    : UIEvent(type, true, true, view, 0)
    , m_data(data)
    , m_activeSegmentStart(0)
    , m_activeSegmentEnd(0)
{
    ScriptWrappable::init(this);
    initializeSegments(&underlines);
}

CompositionEvent::CompositionEvent(const AtomicString& type, const CompositionEventInit& initializer)
    : UIEvent(type, initializer)
    , m_data(initializer.data)
    , m_activeSegmentStart(0)
    , m_activeSegmentEnd(0)
{
    ScriptWrappable::init(this);
    initializeSegments();
}

CompositionEvent::~CompositionEvent()
{
}

void CompositionEvent::initCompositionEvent(const AtomicString& type, bool canBubble, bool cancelable, PassRefPtrWillBeRawPtr<AbstractView> view, const String& data)
{
    if (dispatched())
        return;

    initUIEvent(type, canBubble, cancelable, view, 0);

    m_data = data;
    initializeSegments();
}

void CompositionEvent::initializeSegments(const Vector<CompositionUnderline>* underlines)
{
    m_activeSegmentStart = 0;
    m_activeSegmentEnd = m_data.length();

    if (!underlines || !underlines->size()) {
        m_segments.append(0);
        return;
    }

    for (size_t i = 0; i < underlines->size(); ++i) {
        if (underlines->at(i).thick) {
            m_activeSegmentStart = underlines->at(i).startOffset;
            m_activeSegmentEnd = underlines->at(i).endOffset;
            break;
        }
    }

    for (size_t i = 0; i < underlines->size(); ++i)
        m_segments.append(underlines->at(i).startOffset);
}

const AtomicString& CompositionEvent::interfaceName() const
{
    return EventNames::CompositionEvent;
}

void CompositionEvent::trace(Visitor* visitor)
{
    UIEvent::trace(visitor);
}

} // namespace blink
