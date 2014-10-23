/*
 * Copyright (C) 2006, 2007, 2008 Apple Inc. All rights reserved.
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

#ifndef OverflowEvent_h
#define OverflowEvent_h

#include "core/events/Event.h"

namespace blink {

struct OverflowEventInit : public EventInit {
    OverflowEventInit();

    unsigned short orient;
    bool horizontalOverflow;
    bool verticalOverflow;
};

class OverflowEvent FINAL : public Event {
    DEFINE_WRAPPERTYPEINFO();
public:
    enum orientType {
        HORIZONTAL = 0,
        VERTICAL   = 1,
        BOTH       = 2
    };

    static PassRefPtrWillBeRawPtr<OverflowEvent> create()
    {
        return adoptRefWillBeNoop(new OverflowEvent);
    }
    static PassRefPtrWillBeRawPtr<OverflowEvent> create(bool horizontalOverflowChanged, bool horizontalOverflow, bool verticalOverflowChanged, bool verticalOverflow)
    {
        return adoptRefWillBeNoop(new OverflowEvent(horizontalOverflowChanged, horizontalOverflow, verticalOverflowChanged, verticalOverflow));
    }
    static PassRefPtrWillBeRawPtr<OverflowEvent> create(const AtomicString& type, const OverflowEventInit& initializer)
    {
        return adoptRefWillBeNoop(new OverflowEvent(type, initializer));
    }

    unsigned short orient() const { return m_orient; }
    bool horizontalOverflow() const { return m_horizontalOverflow; }
    bool verticalOverflow() const { return m_verticalOverflow; }

    virtual const AtomicString& interfaceName() const OVERRIDE;

    virtual void trace(Visitor*) OVERRIDE;

private:
    OverflowEvent();
    OverflowEvent(bool horizontalOverflowChanged, bool horizontalOverflow, bool verticalOverflowChanged, bool verticalOverflow);
    OverflowEvent(const AtomicString&, const OverflowEventInit&);

    unsigned short m_orient;
    bool m_horizontalOverflow;
    bool m_verticalOverflow;
};

} // namespace blink

#endif // OverflowEvent_h
