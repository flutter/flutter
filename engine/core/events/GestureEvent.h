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

#ifndef SKY_ENGINE_CORE_EVENTS_GESTUREEVENT_H_
#define SKY_ENGINE_CORE_EVENTS_GESTUREEVENT_H_

#include "sky/engine/core/events/EventDispatcher.h"
#include "sky/engine/core/events/MouseRelatedEvent.h"
#include "sky/engine/platform/PlatformGestureEvent.h"

namespace blink {

struct GestureEventInit : public UIEventInit {
    int screenX = 0;
    int screenY = 0;
    int clientX = 0;
    int clientY = 0;
    bool ctrlKey = false;
    bool altKey = false;
    bool shiftKey = false;
    bool metaKey = false;;
    double deltaX = 0;
    double deltaY = 0;
    double velocityX = 0;
    double velocityY = 0;
};

class GestureEvent final : public MouseRelatedEvent {
    DEFINE_WRAPPERTYPEINFO();
public:
    virtual ~GestureEvent() { }

    static PassRefPtr<GestureEvent> create() { return adoptRef(new GestureEvent); }
    static PassRefPtr<GestureEvent> create(PassRefPtr<AbstractView>, const PlatformGestureEvent&);
    static PassRefPtr<GestureEvent> create(const AtomicString& type, const GestureEventInit&);

    bool isGestureEvent() const override;

    const AtomicString& interfaceName() const override;

    float deltaX() const { return m_deltaX; }
    float deltaY() const { return m_deltaY; }

    float velocityX() const { return m_velocityX; }
    float velocityY() const { return m_velocityY; }

private:
    GestureEvent();
    GestureEvent(const AtomicString& type, const GestureEventInit&);
    GestureEvent(const AtomicString& type, PassRefPtr<AbstractView>, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, float deltaX, float deltaY, float velocityX, float velocityY);

    float m_deltaX;
    float m_deltaY;

    float m_velocityX;
    float m_velocityY;
};

class GestureEventDispatchMediator final : public EventDispatchMediator {
public:
    static PassRefPtr<GestureEventDispatchMediator> create(PassRefPtr<GestureEvent> gestureEvent)
    {
        return adoptRef(new GestureEventDispatchMediator(gestureEvent));
    }

private:
    explicit GestureEventDispatchMediator(PassRefPtr<GestureEvent>);

    GestureEvent* event() const;

    virtual bool dispatchEvent(EventDispatcher*) const override;
};

DEFINE_EVENT_TYPE_CASTS(GestureEvent);

} // namespace blink

#endif  // SKY_ENGINE_CORE_EVENTS_GESTUREEVENT_H_
