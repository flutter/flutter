/*
 * Copyright 2008, The Android Open Source Project
 * Copyright (C) 2012 Research In Motion Limited. All rights reserved.
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

#ifndef TouchEvent_h
#define TouchEvent_h

#include "core/events/EventDispatchMediator.h"
#include "core/events/MouseRelatedEvent.h"
#include "core/dom/TouchList.h"

namespace blink {

class TouchEvent final : public UIEventWithKeyState {
    DEFINE_WRAPPERTYPEINFO();
public:
    virtual ~TouchEvent();

    static PassRefPtrWillBeRawPtr<TouchEvent> create()
    {
        return adoptRefWillBeNoop(new TouchEvent);
    }
    static PassRefPtrWillBeRawPtr<TouchEvent> create(TouchList* touches,
        TouchList* targetTouches, TouchList* changedTouches,
        const AtomicString& type, PassRefPtrWillBeRawPtr<AbstractView> view,
        bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, bool cancelable)
    {
        return adoptRefWillBeNoop(new TouchEvent(touches, targetTouches, changedTouches, type, view,
            ctrlKey, altKey, shiftKey, metaKey, cancelable));
    }

    void initTouchEvent(TouchList* touches, TouchList* targetTouches,
        TouchList* changedTouches, const AtomicString& type,
        PassRefPtrWillBeRawPtr<AbstractView>,
        int, int, int, int, // unused useless members of web exposed API
        bool ctrlKey, bool altKey, bool shiftKey, bool metaKey);

    TouchList* touches() const { return m_touches.get(); }
    TouchList* targetTouches() const { return m_targetTouches.get(); }
    TouchList* changedTouches() const { return m_changedTouches.get(); }

    void setTouches(PassRefPtrWillBeRawPtr<TouchList> touches) { m_touches = touches; }
    void setTargetTouches(PassRefPtrWillBeRawPtr<TouchList> targetTouches) { m_targetTouches = targetTouches; }
    void setChangedTouches(PassRefPtrWillBeRawPtr<TouchList> changedTouches) { m_changedTouches = changedTouches; }

    virtual bool isTouchEvent() const override;

    virtual const AtomicString& interfaceName() const override;

    virtual void preventDefault() override;

    virtual void trace(Visitor*) override;

private:
    TouchEvent();
    TouchEvent(TouchList* touches, TouchList* targetTouches,
            TouchList* changedTouches, const AtomicString& type,
            PassRefPtrWillBeRawPtr<AbstractView>,
            bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, bool cancelable);

    RefPtrWillBeMember<TouchList> m_touches;
    RefPtrWillBeMember<TouchList> m_targetTouches;
    RefPtrWillBeMember<TouchList> m_changedTouches;
};

class TouchEventDispatchMediator final : public EventDispatchMediator {
public:
    static PassRefPtrWillBeRawPtr<TouchEventDispatchMediator> create(PassRefPtrWillBeRawPtr<TouchEvent>);

private:
    explicit TouchEventDispatchMediator(PassRefPtrWillBeRawPtr<TouchEvent>);
    TouchEvent* event() const;
    virtual bool dispatchEvent(EventDispatcher*) const override;
};

DEFINE_EVENT_TYPE_CASTS(TouchEvent);

} // namespace blink

#endif // TouchEvent_h
