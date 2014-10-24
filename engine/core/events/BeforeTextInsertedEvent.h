/*
 * Copyright (C) 2006 Apple Computer, Inc.  All rights reserved.
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

#ifndef BeforeTextInsertedEvent_h
#define BeforeTextInsertedEvent_h

#include "core/events/Event.h"

namespace blink {

class BeforeTextInsertedEvent final : public Event {
public:
    virtual ~BeforeTextInsertedEvent();

    static PassRefPtrWillBeRawPtr<BeforeTextInsertedEvent> create(const String& text)
    {
        return adoptRefWillBeNoop(new BeforeTextInsertedEvent(text));
    }

    virtual const AtomicString& interfaceName() const override;
    virtual bool isBeforeTextInsertedEvent() const override { return true; }

    const String& text() const { return m_text; }
    void setText(const String& s) { m_text = s; }

    virtual void trace(Visitor*) override;

private:
    explicit BeforeTextInsertedEvent(const String&);

    String m_text;
};

} // namespace

#endif
