// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/dom/custom/CustomElementMicrotaskRunQueue.h"

#include "base/bind.h"
#include "core/dom/Microtask.h"
#include "core/dom/custom/CustomElementAsyncImportMicrotaskQueue.h"
#include "core/dom/custom/CustomElementSyncMicrotaskQueue.h"
#include "core/html/imports/HTMLImportLoader.h"

#include <stdio.h>

namespace blink {

DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(CustomElementMicrotaskRunQueue)

CustomElementMicrotaskRunQueue::CustomElementMicrotaskRunQueue()
    : m_syncQueue(CustomElementSyncMicrotaskQueue::create())
    , m_asyncQueue(CustomElementAsyncImportMicrotaskQueue::create())
    , m_dispatchIsPending(false)
    , m_weakFactory(this)
{
}

void CustomElementMicrotaskRunQueue::enqueue(HTMLImportLoader* parentLoader, PassOwnPtr<CustomElementMicrotaskStep> step, bool importIsSync)
{
    if (importIsSync) {
        if (parentLoader)
            parentLoader->microtaskQueue()->enqueue(step);
        else
            m_syncQueue->enqueue(step);
    } else {
        m_asyncQueue->enqueue(step);
    }

    requestDispatchIfNeeded();
}

void CustomElementMicrotaskRunQueue::requestDispatchIfNeeded()
{
    if (m_dispatchIsPending || isEmpty())
        return;
    Microtask::enqueueMicrotask(base::Bind(&CustomElementMicrotaskRunQueue::dispatch, m_weakFactory.GetWeakPtr()));
    m_dispatchIsPending = true;
}

void CustomElementMicrotaskRunQueue::trace(Visitor* visitor)
{
    visitor->trace(m_syncQueue);
    visitor->trace(m_asyncQueue);
}

void CustomElementMicrotaskRunQueue::dispatch()
{
    m_dispatchIsPending = false;
    m_syncQueue->dispatch();
    if (m_syncQueue->isEmpty())
        m_asyncQueue->dispatch();
}

bool CustomElementMicrotaskRunQueue::isEmpty() const
{
    return m_syncQueue->isEmpty() && m_asyncQueue->isEmpty();
}

} // namespace blink
