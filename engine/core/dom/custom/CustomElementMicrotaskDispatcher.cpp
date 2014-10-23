// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/dom/custom/CustomElementMicrotaskDispatcher.h"

#include "base/bind.h"
#include "core/dom/Microtask.h"
#include "core/dom/custom/CustomElementCallbackQueue.h"
#include "core/dom/custom/CustomElementMicrotaskImportStep.h"
#include "core/dom/custom/CustomElementProcessingStack.h"
#include "core/dom/custom/CustomElementScheduler.h"
#include "wtf/MainThread.h"

namespace blink {

static const CustomElementCallbackQueue::ElementQueueId kMicrotaskQueueId = 0;

CustomElementMicrotaskDispatcher::CustomElementMicrotaskDispatcher()
    : m_hasScheduledMicrotask(false)
    , m_phase(Quiescent)
{
}

DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(CustomElementMicrotaskDispatcher)

CustomElementMicrotaskDispatcher& CustomElementMicrotaskDispatcher::instance()
{
    DEFINE_STATIC_LOCAL(OwnPtrWillBePersistent<CustomElementMicrotaskDispatcher>, instance, (adoptPtrWillBeNoop(new CustomElementMicrotaskDispatcher())));
    return *instance;
}

void CustomElementMicrotaskDispatcher::enqueue(CustomElementCallbackQueue* queue)
{
    ensureMicrotaskScheduledForElementQueue();
    queue->setOwner(kMicrotaskQueueId);
    m_elements.append(queue);
}

void CustomElementMicrotaskDispatcher::ensureMicrotaskScheduledForElementQueue()
{
    ASSERT(m_phase == Quiescent || m_phase == Resolving);
    ensureMicrotaskScheduled();
}

void CustomElementMicrotaskDispatcher::ensureMicrotaskScheduled()
{
    if (!m_hasScheduledMicrotask) {
        Microtask::enqueueMicrotask(base::Bind(&dispatch));
        m_hasScheduledMicrotask = true;
    }
}

void CustomElementMicrotaskDispatcher::dispatch()
{
    instance().doDispatch();
}

void CustomElementMicrotaskDispatcher::doDispatch()
{
    ASSERT(isMainThread());

    ASSERT(m_phase == Quiescent && m_hasScheduledMicrotask);
    m_hasScheduledMicrotask = false;

    // Finishing microtask work deletes all
    // CustomElementCallbackQueues. Being in a callback delivery scope
    // implies those queues could still be in use.
    ASSERT_WITH_SECURITY_IMPLICATION(!CustomElementProcessingStack::inCallbackDeliveryScope());

    m_phase = Resolving;

    m_phase = DispatchingCallbacks;
    for (WillBeHeapVector<RawPtrWillBeMember<CustomElementCallbackQueue> >::iterator it = m_elements.begin(); it != m_elements.end(); ++it) {
        // Created callback may enqueue an attached callback.
        CustomElementProcessingStack::CallbackDeliveryScope scope;
        (*it)->processInElementQueue(kMicrotaskQueueId);
    }

    m_elements.clear();
    CustomElementScheduler::microtaskDispatcherDidFinish();
    m_phase = Quiescent;
}

void CustomElementMicrotaskDispatcher::trace(Visitor* visitor)
{
#if ENABLE(OILPAN)
    visitor->trace(m_elements);
#endif
}

} // namespace blink
