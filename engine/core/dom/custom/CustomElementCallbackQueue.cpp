/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer
 *    in the documentation and/or other materials provided with the
 *    distribution.
 * 3. Neither the name of Google Inc. nor the names of its contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
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
#include "core/dom/custom/CustomElementCallbackQueue.h"

namespace blink {

PassOwnPtrWillBeRawPtr<CustomElementCallbackQueue> CustomElementCallbackQueue::create(PassRefPtrWillBeRawPtr<Element> element)
{
    return adoptPtrWillBeNoop(new CustomElementCallbackQueue(element));
}

CustomElementCallbackQueue::CustomElementCallbackQueue(PassRefPtrWillBeRawPtr<Element> element)
    : m_element(element)
    , m_owner(-1)
    , m_index(0)
    , m_inCreatedCallback(false)
{
}

bool CustomElementCallbackQueue::processInElementQueue(ElementQueueId caller)
{
    ASSERT(!m_inCreatedCallback);
    bool didWork = false;

    while (m_index < m_queue.size() && owner() == caller) {
        m_inCreatedCallback = m_queue[m_index]->isCreated();

        // dispatch() may cause recursion which steals this callback
        // queue and reenters processInQueue. owner() == caller
        // detects this recursion and cedes processing.
        m_queue[m_index++]->dispatch(m_element.get());
        m_inCreatedCallback = false;
        didWork = true;
    }

    if (owner() == caller && m_index == m_queue.size()) {
        // This processInQueue exhausted the queue; shrink it.
        m_index = 0;
        m_queue.resize(0);
        m_owner = -1;
    }

    return didWork;
}

void CustomElementCallbackQueue::trace(Visitor* visitor)
{
    visitor->trace(m_element);
}

} // namespace blink
