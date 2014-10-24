/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef FocusEvent_h
#define FocusEvent_h

#include "core/events/EventTarget.h"
#include "core/events/UIEvent.h"

namespace blink {

class Node;

struct FocusEventInit : public UIEventInit {
    FocusEventInit();

    RefPtrWillBeMember<EventTarget> relatedTarget;
};

class FocusEvent final : public UIEvent {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtrWillBeRawPtr<FocusEvent> create()
    {
        return adoptRefWillBeNoop(new FocusEvent);
    }

    static PassRefPtrWillBeRawPtr<FocusEvent> create(const AtomicString& type, bool canBubble, bool cancelable, PassRefPtrWillBeRawPtr<AbstractView> view, int detail, EventTarget* relatedTarget)
    {
        return adoptRefWillBeNoop(new FocusEvent(type, canBubble, cancelable, view, detail, relatedTarget));
    }

    static PassRefPtrWillBeRawPtr<FocusEvent> create(const AtomicString& type, const FocusEventInit& initializer)
    {
        return adoptRefWillBeNoop(new FocusEvent(type, initializer));
    }

    EventTarget* relatedTarget() const { return m_relatedTarget.get(); }
    void setRelatedTarget(EventTarget* relatedTarget) { m_relatedTarget = relatedTarget; }

    virtual const AtomicString& interfaceName() const override;
    virtual bool isFocusEvent() const override;

    virtual void trace(Visitor*) override;

private:
    FocusEvent();
    FocusEvent(const AtomicString& type, bool canBubble, bool cancelable, PassRefPtrWillBeRawPtr<AbstractView>, int, EventTarget*);
    FocusEvent(const AtomicString& type, const FocusEventInit&);

    RefPtrWillBeMember<EventTarget> m_relatedTarget;
};

DEFINE_EVENT_TYPE_CASTS(FocusEvent);

class FocusEventDispatchMediator final : public EventDispatchMediator {
public:
    static PassRefPtrWillBeRawPtr<FocusEventDispatchMediator> create(PassRefPtrWillBeRawPtr<FocusEvent>);
private:
    explicit FocusEventDispatchMediator(PassRefPtrWillBeRawPtr<FocusEvent>);
    FocusEvent* event() const { return static_cast<FocusEvent*>(EventDispatchMediator::event()); }
    virtual bool dispatchEvent(EventDispatcher*) const override;
};

class BlurEventDispatchMediator final : public EventDispatchMediator {
public:
    static PassRefPtrWillBeRawPtr<BlurEventDispatchMediator> create(PassRefPtrWillBeRawPtr<FocusEvent>);
private:
    explicit BlurEventDispatchMediator(PassRefPtrWillBeRawPtr<FocusEvent>);
    FocusEvent* event() const { return static_cast<FocusEvent*>(EventDispatchMediator::event()); }
    virtual bool dispatchEvent(EventDispatcher*) const override;
};

class FocusInEventDispatchMediator final : public EventDispatchMediator {
public:
    static PassRefPtrWillBeRawPtr<FocusInEventDispatchMediator> create(PassRefPtrWillBeRawPtr<FocusEvent>);
private:
    explicit FocusInEventDispatchMediator(PassRefPtrWillBeRawPtr<FocusEvent>);
    FocusEvent* event() const { return static_cast<FocusEvent*>(EventDispatchMediator::event()); }
    virtual bool dispatchEvent(EventDispatcher*) const override;
};

class FocusOutEventDispatchMediator final : public EventDispatchMediator {
public:
    static PassRefPtrWillBeRawPtr<FocusOutEventDispatchMediator> create(PassRefPtrWillBeRawPtr<FocusEvent>);
private:
    explicit FocusOutEventDispatchMediator(PassRefPtrWillBeRawPtr<FocusEvent>);
    FocusEvent* event() const { return static_cast<FocusEvent*>(EventDispatchMediator::event()); }
    virtual bool dispatchEvent(EventDispatcher*) const override;
};

} // namespace blink

#endif // FocusEvent_h
