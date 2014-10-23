/*
 * Copyright (C) 2014 Google Inc. All Rights Reserved.
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
 *
 */

#include "config.h"
#include "core/events/TouchEventContext.h"

#include "core/dom/TouchList.h"
#include "core/events/Event.h"
#include "core/events/TouchEvent.h"

namespace blink {

PassRefPtrWillBeRawPtr<TouchEventContext> TouchEventContext::create()
{
    return adoptRefWillBeNoop(new TouchEventContext);
}

TouchEventContext::TouchEventContext()
    : m_touches(TouchList::create())
    , m_targetTouches(TouchList::create())
    , m_changedTouches(TouchList::create())
{
}

DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(TouchEventContext)

void TouchEventContext::handleLocalEvents(Event* event) const
{
    ASSERT(event->isTouchEvent());
    TouchEvent* touchEvent = toTouchEvent(event);
    touchEvent->setTouches(m_touches);
    touchEvent->setTargetTouches(m_targetTouches);
    touchEvent->setChangedTouches(m_changedTouches);
}

void TouchEventContext::trace(Visitor* visitor)
{
    visitor->trace(m_touches);
    visitor->trace(m_targetTouches);
    visitor->trace(m_changedTouches);
}

}
