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

    RefPtr<EventTarget> relatedTarget;
};

class FocusEvent final : public UIEvent {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<FocusEvent> create()
    {
        return adoptRef(new FocusEvent);
    }

    static PassRefPtr<FocusEvent> create(const AtomicString& type, bool canBubble, bool cancelable, PassRefPtr<AbstractView> view, int detail, EventTarget* relatedTarget)
    {
        return adoptRef(new FocusEvent(type, canBubble, cancelable, view, detail, relatedTarget));
    }

    static PassRefPtr<FocusEvent> create(const AtomicString& type, const FocusEventInit& initializer)
    {
        return adoptRef(new FocusEvent(type, initializer));
    }

    EventTarget* relatedTarget() const { return m_relatedTarget.get(); }
    void setRelatedTarget(EventTarget* relatedTarget) { m_relatedTarget = relatedTarget; }

    virtual const AtomicString& interfaceName() const override;
    virtual bool isFocusEvent() const override;

private:
    FocusEvent();
    FocusEvent(const AtomicString& type, bool canBubble, bool cancelable, PassRefPtr<AbstractView>, int, EventTarget*);
    FocusEvent(const AtomicString& type, const FocusEventInit&);

    RefPtr<EventTarget> m_relatedTarget;
};

DEFINE_EVENT_TYPE_CASTS(FocusEvent);

class FocusEventDispatchMediator final : public EventDispatchMediator {
public:
    static PassRefPtr<FocusEventDispatchMediator> create(PassRefPtr<FocusEvent>);
private:
    explicit FocusEventDispatchMediator(PassRefPtr<FocusEvent>);
    FocusEvent* event() const { return static_cast<FocusEvent*>(EventDispatchMediator::event()); }
    virtual bool dispatchEvent(EventDispatcher*) const override;
};

class BlurEventDispatchMediator final : public EventDispatchMediator {
public:
    static PassRefPtr<BlurEventDispatchMediator> create(PassRefPtr<FocusEvent>);
private:
    explicit BlurEventDispatchMediator(PassRefPtr<FocusEvent>);
    FocusEvent* event() const { return static_cast<FocusEvent*>(EventDispatchMediator::event()); }
    virtual bool dispatchEvent(EventDispatcher*) const override;
};

class FocusInEventDispatchMediator final : public EventDispatchMediator {
public:
    static PassRefPtr<FocusInEventDispatchMediator> create(PassRefPtr<FocusEvent>);
private:
    explicit FocusInEventDispatchMediator(PassRefPtr<FocusEvent>);
    FocusEvent* event() const { return static_cast<FocusEvent*>(EventDispatchMediator::event()); }
    virtual bool dispatchEvent(EventDispatcher*) const override;
};

class FocusOutEventDispatchMediator final : public EventDispatchMediator {
public:
    static PassRefPtr<FocusOutEventDispatchMediator> create(PassRefPtr<FocusEvent>);
private:
    explicit FocusOutEventDispatchMediator(PassRefPtr<FocusEvent>);
    FocusEvent* event() const { return static_cast<FocusEvent*>(EventDispatchMediator::event()); }
    virtual bool dispatchEvent(EventDispatcher*) const override;
};

} // namespace blink

#endif // FocusEvent_h
