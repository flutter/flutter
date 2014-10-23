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
#include "core/dom/custom/CustomElementProcessingStack.h"

#include "core/dom/custom/CustomElementCallbackQueue.h"
#include "core/dom/custom/CustomElementScheduler.h"
#include "wtf/MainThread.h"

namespace blink {

size_t CustomElementProcessingStack::s_elementQueueStart = 0;

// The base of the stack has a null sentinel value.
size_t CustomElementProcessingStack::s_elementQueueEnd = kNumSentinels;

CustomElementProcessingStack& CustomElementProcessingStack::instance()
{
    DEFINE_STATIC_LOCAL(CustomElementProcessingStack, instance, ());
    return instance;
}

// Dispatches callbacks when popping the processing stack.
void CustomElementProcessingStack::processElementQueueAndPop()
{
    instance().processElementQueueAndPop(s_elementQueueStart, s_elementQueueEnd);
}

void CustomElementProcessingStack::processElementQueueAndPop(size_t start, size_t end)
{
    ASSERT(isMainThread());
    CustomElementCallbackQueue::ElementQueueId thisQueue = currentElementQueue();

    for (size_t i = start; i < end; ++i) {
        {
            // The created callback may schedule entered document
            // callbacks.
            CallbackDeliveryScope deliveryScope;
            m_flattenedProcessingStack[i]->processInElementQueue(thisQueue);
        }

        ASSERT(start == s_elementQueueStart);
        ASSERT(end == s_elementQueueEnd);
    }

    // Pop the element queue from the processing stack
    m_flattenedProcessingStack.resize(start);
    s_elementQueueEnd = start;

    if (s_elementQueueStart == kNumSentinels)
        CustomElementScheduler::callbackDispatcherDidFinish();
}

void CustomElementProcessingStack::enqueue(CustomElementCallbackQueue* callbackQueue)
{
    ASSERT(inCallbackDeliveryScope());

    if (callbackQueue->owner() == currentElementQueue())
        return;

    callbackQueue->setOwner(currentElementQueue());

    m_flattenedProcessingStack.append(callbackQueue);
    ++s_elementQueueEnd;
}

} // namespace blink
