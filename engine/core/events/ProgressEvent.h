/*
 * Copyright (C) 2007, 2008 Apple Inc. All rights reserved.
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

#ifndef ProgressEvent_h
#define ProgressEvent_h

#include "core/events/Event.h"

namespace blink {

struct ProgressEventInit : public EventInit {
    ProgressEventInit();

    bool lengthComputable;
    unsigned long long loaded;
    unsigned long long total;
};

class ProgressEvent : public Event {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtrWillBeRawPtr<ProgressEvent> create()
    {
        return adoptRefWillBeNoop(new ProgressEvent);
    }
    static PassRefPtrWillBeRawPtr<ProgressEvent> create(const AtomicString& type, bool lengthComputable, unsigned long long loaded, unsigned long long total)
    {
        return adoptRefWillBeNoop(new ProgressEvent(type, lengthComputable, loaded, total));
    }
    static PassRefPtrWillBeRawPtr<ProgressEvent> create(const AtomicString& type, const ProgressEventInit& initializer)
    {
        return adoptRefWillBeNoop(new ProgressEvent(type, initializer));
    }

    bool lengthComputable() const { return m_lengthComputable; }
    unsigned long long loaded() const { return m_loaded; }
    unsigned long long total() const { return m_total; }

    virtual const AtomicString& interfaceName() const override;

    virtual void trace(Visitor*) override;

protected:
    ProgressEvent();
    ProgressEvent(const AtomicString& type, bool lengthComputable, unsigned long long loaded, unsigned long long total);
    ProgressEvent(const AtomicString&, const ProgressEventInit&);

private:
    bool m_lengthComputable;
    unsigned long long m_loaded;
    unsigned long long m_total;
};

} // namespace blink

#endif // ProgressEvent_h
