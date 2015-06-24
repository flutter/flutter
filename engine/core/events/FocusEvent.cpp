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

#include "sky/engine/core/events/FocusEvent.h"

#include "sky/engine/core/events/Event.h"
#include "sky/engine/core/events/EventDispatcher.h"

namespace blink {

FocusEventInit::FocusEventInit()
    : relatedTarget(nullptr)
{
}

const AtomicString& FocusEvent::interfaceName() const
{
    return EventNames::FocusEvent;
}

bool FocusEvent::isFocusEvent() const
{
    return true;
}

FocusEvent::FocusEvent()
{
}

FocusEvent::FocusEvent(const AtomicString& type, bool canBubble, bool cancelable, PassRefPtr<AbstractView> view, int detail, EventTarget* relatedTarget)
    : UIEvent(type, canBubble, cancelable, view, detail)
    , m_relatedTarget(relatedTarget)
{
}

FocusEvent::FocusEvent(const AtomicString& type, const FocusEventInit& initializer)
    : UIEvent(type, initializer)
    , m_relatedTarget(initializer.relatedTarget)
{
}

PassRefPtr<FocusEventDispatchMediator> FocusEventDispatchMediator::create(PassRefPtr<FocusEvent> focusEvent)
{
    return adoptRef(new FocusEventDispatchMediator(focusEvent));
}

FocusEventDispatchMediator::FocusEventDispatchMediator(PassRefPtr<FocusEvent> focusEvent)
    : EventDispatchMediator(focusEvent)
{
}

bool FocusEventDispatchMediator::dispatchEvent(EventDispatcher* dispatcher) const
{
    event()->eventPath().adjustForRelatedTarget(dispatcher->node(), event()->relatedTarget());
    return EventDispatchMediator::dispatchEvent(dispatcher);
}

PassRefPtr<BlurEventDispatchMediator> BlurEventDispatchMediator::create(PassRefPtr<FocusEvent> focusEvent)
{
    return adoptRef(new BlurEventDispatchMediator(focusEvent));
}

BlurEventDispatchMediator::BlurEventDispatchMediator(PassRefPtr<FocusEvent> focusEvent)
    : EventDispatchMediator(focusEvent)
{
}

bool BlurEventDispatchMediator::dispatchEvent(EventDispatcher* dispatcher) const
{
    event()->eventPath().adjustForRelatedTarget(dispatcher->node(), event()->relatedTarget());
    return EventDispatchMediator::dispatchEvent(dispatcher);
}

PassRefPtr<FocusInEventDispatchMediator> FocusInEventDispatchMediator::create(PassRefPtr<FocusEvent> focusEvent)
{
    return adoptRef(new FocusInEventDispatchMediator(focusEvent));
}

FocusInEventDispatchMediator::FocusInEventDispatchMediator(PassRefPtr<FocusEvent> focusEvent)
    : EventDispatchMediator(focusEvent)
{
}

bool FocusInEventDispatchMediator::dispatchEvent(EventDispatcher* dispatcher) const
{
    event()->eventPath().adjustForRelatedTarget(dispatcher->node(), event()->relatedTarget());
    return EventDispatchMediator::dispatchEvent(dispatcher);
}

PassRefPtr<FocusOutEventDispatchMediator> FocusOutEventDispatchMediator::create(PassRefPtr<FocusEvent> focusEvent)
{
    return adoptRef(new FocusOutEventDispatchMediator(focusEvent));
}

FocusOutEventDispatchMediator::FocusOutEventDispatchMediator(PassRefPtr<FocusEvent> focusEvent)
    : EventDispatchMediator(focusEvent)
{
}

bool FocusOutEventDispatchMediator::dispatchEvent(EventDispatcher* dispatcher) const
{
    event()->eventPath().adjustForRelatedTarget(dispatcher->node(), event()->relatedTarget());
    return EventDispatchMediator::dispatchEvent(dispatcher);
}

} // namespace blink
