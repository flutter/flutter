/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/events/ScopedEventQueue.h"

#include "core/events/Event.h"
#include "core/events/EventDispatchMediator.h"
#include "core/events/EventDispatcher.h"
#include "core/events/EventTarget.h"
#include "wtf/OwnPtr.h"

namespace blink {

ScopedEventQueue* ScopedEventQueue::s_instance = 0;

ScopedEventQueue::ScopedEventQueue()
    : m_scopingLevel(0)
{
}

ScopedEventQueue::~ScopedEventQueue()
{
    ASSERT(!m_scopingLevel);
    ASSERT(!m_queuedEventDispatchMediators.size());
}

void ScopedEventQueue::initialize()
{
    ASSERT(!s_instance);
    OwnPtr<ScopedEventQueue> instance = adoptPtr(new ScopedEventQueue);
    s_instance = instance.leakPtr();
}

void ScopedEventQueue::enqueueEventDispatchMediator(PassRefPtrWillBeRawPtr<EventDispatchMediator> mediator)
{
    if (m_scopingLevel)
        m_queuedEventDispatchMediators.append(mediator);
    else
        dispatchEvent(mediator);
}

void ScopedEventQueue::dispatchAllEvents()
{
    WillBeHeapVector<RefPtrWillBeMember<EventDispatchMediator> > queuedEventDispatchMediators;
    queuedEventDispatchMediators.swap(m_queuedEventDispatchMediators);

    for (size_t i = 0; i < queuedEventDispatchMediators.size(); i++)
        dispatchEvent(queuedEventDispatchMediators[i].release());
}

void ScopedEventQueue::dispatchEvent(PassRefPtrWillBeRawPtr<EventDispatchMediator> mediator) const
{
    ASSERT(mediator->event()->target());
    Node* node = mediator->event()->target()->toNode();
    EventDispatcher::dispatchEvent(node, mediator);
}

ScopedEventQueue* ScopedEventQueue::instance()
{
    if (!s_instance)
        initialize();

    return s_instance;
}

void ScopedEventQueue::incrementScopingLevel()
{
    m_scopingLevel++;
}

void ScopedEventQueue::decrementScopingLevel()
{
    ASSERT(m_scopingLevel);
    m_scopingLevel--;
    if (!m_scopingLevel)
        dispatchAllEvents();
}

}
