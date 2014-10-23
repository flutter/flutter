/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY
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

#ifndef GestureEvent_h
#define GestureEvent_h

#include "core/events/EventDispatcher.h"
#include "core/events/MouseRelatedEvent.h"
#include "platform/PlatformGestureEvent.h"

namespace blink {

class GestureEvent FINAL : public MouseRelatedEvent {
public:
    virtual ~GestureEvent() { }

    static PassRefPtrWillBeRawPtr<GestureEvent> create(PassRefPtrWillBeRawPtr<AbstractView>, const PlatformGestureEvent&);

    virtual bool isGestureEvent() const OVERRIDE;

    virtual const AtomicString& interfaceName() const OVERRIDE;

    float deltaX() const { return m_deltaX; }
    float deltaY() const { return m_deltaY; }

    virtual void trace(Visitor*) OVERRIDE;

private:
    GestureEvent();
    GestureEvent(const AtomicString& type, PassRefPtrWillBeRawPtr<AbstractView>, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, float deltaX, float deltaY);

    float m_deltaX;
    float m_deltaY;
};

class GestureEventDispatchMediator FINAL : public EventDispatchMediator {
public:
    static PassRefPtrWillBeRawPtr<GestureEventDispatchMediator> create(PassRefPtrWillBeRawPtr<GestureEvent> gestureEvent)
    {
        return adoptRefWillBeNoop(new GestureEventDispatchMediator(gestureEvent));
    }

private:
    explicit GestureEventDispatchMediator(PassRefPtrWillBeRawPtr<GestureEvent>);

    GestureEvent* event() const;

    virtual bool dispatchEvent(EventDispatcher*) const OVERRIDE;
};

DEFINE_EVENT_TYPE_CASTS(GestureEvent);

} // namespace blink

#endif // GestureEvent_h
