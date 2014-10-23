// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/frame/PlatformEventDispatcher.h"

#include "core/frame/PlatformEventController.h"
#include "wtf/TemporaryChange.h"

namespace blink {

PlatformEventDispatcher::PlatformEventDispatcher()
    : m_needsPurge(false)
    , m_isDispatching(false)
{
}

PlatformEventDispatcher::~PlatformEventDispatcher()
{
}

void PlatformEventDispatcher::addController(PlatformEventController* controller)
{
    bool wasEmpty = m_controllers.isEmpty();
    if (!m_controllers.contains(controller))
        m_controllers.append(controller);
    if (wasEmpty)
        startListening();
}

void PlatformEventDispatcher::removeController(PlatformEventController* controller)
{
    // Do not actually remove the controller from the vector, instead zero them out.
    // The zeros are removed in these two cases:
    // 1. either immediately if we are not dispatching any events,
    // 2. or after events to all controllers have dispatched (see notifyControllers()).
    // This is to correctly handle the re-entrancy case when a controller is destroyed
    // while the events are still being dispatched.
    size_t index = m_controllers.find(controller);
    if (index == kNotFound)
        return;

    m_controllers[index] = 0;
    m_needsPurge = true;

    if (!m_isDispatching)
        purgeControllers();
}

void PlatformEventDispatcher::purgeControllers()
{
    ASSERT(m_needsPurge);

    size_t i = 0;
    while (i < m_controllers.size()) {
        if (!m_controllers[i]) {
            m_controllers[i] = m_controllers.last();
            m_controllers.removeLast();
        } else {
            ++i;
        }
    }

    m_needsPurge = false;

    if (m_controllers.isEmpty())
        stopListening();
}

void PlatformEventDispatcher::notifyControllers()
{
    {
        TemporaryChange<bool> changeIsDispatching(m_isDispatching, true);
        // Don't notify controllers removed or added during event dispatch.
        size_t size = m_controllers.size();
        for (size_t i = 0; i < size; ++i) {
            if (m_controllers[i])
                m_controllers[i]->didUpdateData();
        }
    }

    if (m_needsPurge)
        purgeControllers();
}

} // namespace blink
