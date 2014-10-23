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

#ifndef WebKitAnimationEvent_h
#define WebKitAnimationEvent_h

#include "core/events/Event.h"

namespace blink {

// FIXME : This class has a WebKit prefix on purpose so we can use the EventAliases system. When the
// runtime flag of unprefixed animation will be removed we can rename that class and do the same as
// the CSS Transitions.
struct WebKitAnimationEventInit : public EventInit {
    WebKitAnimationEventInit();

    String animationName;
    double elapsedTime;
};

class WebKitAnimationEvent FINAL : public Event {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtrWillBeRawPtr<WebKitAnimationEvent> create()
    {
        return adoptRefWillBeNoop(new WebKitAnimationEvent);
    }
    static PassRefPtrWillBeRawPtr<WebKitAnimationEvent> create(const AtomicString& type, const String& animationName, double elapsedTime)
    {
        return adoptRefWillBeNoop(new WebKitAnimationEvent(type, animationName, elapsedTime));
    }
    static PassRefPtrWillBeRawPtr<WebKitAnimationEvent> create(const AtomicString& type, const WebKitAnimationEventInit& initializer)
    {
        return adoptRefWillBeNoop(new WebKitAnimationEvent(type, initializer));
    }

    virtual ~WebKitAnimationEvent();

    const String& animationName() const;
    double elapsedTime() const;

    virtual const AtomicString& interfaceName() const OVERRIDE;

    virtual void trace(Visitor*) OVERRIDE;

private:
    WebKitAnimationEvent();
    WebKitAnimationEvent(const AtomicString& type, const String& animationName, double elapsedTime);
    WebKitAnimationEvent(const AtomicString&, const WebKitAnimationEventInit&);

    String m_animationName;
    double m_elapsedTime;
};

} // namespace blink

#endif // WebKitAnimationEvent_h
