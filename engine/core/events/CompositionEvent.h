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

#ifndef CompositionEvent_h
#define CompositionEvent_h

#include "core/editing/CompositionUnderline.h"
#include "core/events/UIEvent.h"

namespace blink {

struct CompositionEventInit : UIEventInit {
    CompositionEventInit();

    String data;
};

class CompositionEvent final : public UIEvent {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<CompositionEvent> create()
    {
        return adoptRef(new CompositionEvent);
    }

    static PassRefPtr<CompositionEvent> create(const AtomicString& type, PassRefPtr<AbstractView> view, const String& data, const Vector<CompositionUnderline>& underlines)
    {
        return adoptRef(new CompositionEvent(type, view, data, underlines));
    }

    static PassRefPtr<CompositionEvent> create(const AtomicString& type, const CompositionEventInit& initializer)
    {
        return adoptRef(new CompositionEvent(type, initializer));
    }

    virtual ~CompositionEvent();

    void initCompositionEvent(const AtomicString& type, bool canBubble, bool cancelable, PassRefPtr<AbstractView>, const String& data);

    String data() const { return m_data; }
    int activeSegmentStart() const { return m_activeSegmentStart; }
    int activeSegmentEnd() const { return m_activeSegmentEnd; }
    const Vector<unsigned>& getSegments() const { return m_segments; }

    virtual const AtomicString& interfaceName() const override;

private:
    CompositionEvent();
    CompositionEvent(const AtomicString& type, PassRefPtr<AbstractView>, const String&, const Vector<CompositionUnderline>& underlines);
    CompositionEvent(const AtomicString& type, const CompositionEventInit&);
    void initializeSegments(const Vector<CompositionUnderline>* = 0);

    String m_data;
    int m_activeSegmentStart;
    int m_activeSegmentEnd;
    Vector<unsigned> m_segments;
};

} // namespace blink

#endif // CompositionEvent_h
