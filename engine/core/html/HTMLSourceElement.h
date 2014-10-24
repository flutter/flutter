/*
 * Copyright (C) 2007, 2008, 2010 Apple Inc. All rights reserved.
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

#ifndef HTMLSourceElement_h
#define HTMLSourceElement_h

#include "core/css/MediaQueryListListener.h"
#include "core/html/HTMLElement.h"
#include "platform/Timer.h"

namespace blink {

template<typename T> class EventSender;
typedef EventSender<HTMLSourceElement> SourceEventSender;

class HTMLSourceElement final : public HTMLElement {
    DEFINE_WRAPPERTYPEINFO();
public:
    class Listener;

    DECLARE_NODE_FACTORY(HTMLSourceElement);
    virtual ~HTMLSourceElement();

    const AtomicString& type() const;
    void setSrc(const String&);
    void setType(const AtomicString&);

    void scheduleErrorEvent();
    void cancelPendingErrorEvent();

    void dispatchPendingEvent(SourceEventSender*);

    bool mediaQueryMatches() const;

    virtual void trace(Visitor*) override;

private:
    explicit HTMLSourceElement(Document&);

    virtual InsertionNotificationRequest insertedInto(ContainerNode*) override;
    virtual void removedFrom(ContainerNode*) override;
    virtual bool isURLAttribute(const Attribute&) const override;
    virtual void parseAttribute(const QualifiedName&, const AtomicString&) override;

    void notifyMediaQueryChanged();

    RefPtrWillBeMember<MediaQueryList> m_mediaQueryList;
    RefPtrWillBeMember<Listener> m_listener;
};

} // namespace blink

#endif // HTMLSourceElement_h
