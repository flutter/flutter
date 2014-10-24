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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef PageTransitionEvent_h
#define PageTransitionEvent_h

#include "core/events/Event.h"

namespace blink {

struct PageTransitionEventInit : public EventInit {
    PageTransitionEventInit();

    bool persisted;
};

class PageTransitionEvent final : public Event {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtrWillBeRawPtr<PageTransitionEvent> create()
    {
        return adoptRefWillBeNoop(new PageTransitionEvent);
    }
    static PassRefPtrWillBeRawPtr<PageTransitionEvent> create(const AtomicString& type, bool persisted)
    {
        return adoptRefWillBeNoop(new PageTransitionEvent(type, persisted));
    }
    static PassRefPtrWillBeRawPtr<PageTransitionEvent> create(const AtomicString& type, const PageTransitionEventInit& initializer)
    {
        return adoptRefWillBeNoop(new PageTransitionEvent(type, initializer));
    }

    virtual ~PageTransitionEvent();

    virtual const AtomicString& interfaceName() const override;

    bool persisted() const { return m_persisted; }

    virtual void trace(Visitor*) override;

private:
    PageTransitionEvent();
    PageTransitionEvent(const AtomicString& type, bool persisted);
    PageTransitionEvent(const AtomicString&, const PageTransitionEventInit&);

    bool m_persisted;
};

} // namespace blink

#endif // PageTransitionEvent_h
