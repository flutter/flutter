// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/frame/PlatformEventController.h"

#include "core/page/Page.h"

namespace blink {

PlatformEventController::PlatformEventController(Page* page)
    : PageLifecycleObserver(page)
    , m_hasEventListener(false)
    , m_isActive(false)
    , m_timer(this, &PlatformEventController::oneShotCallback)
{
}

PlatformEventController::~PlatformEventController()
{
}

void PlatformEventController::oneShotCallback(Timer<PlatformEventController>* timer)
{
    ASSERT_UNUSED(timer, timer == &m_timer);
    ASSERT(hasLastData());
    ASSERT(!m_timer.isActive());

    didUpdateData();
}

void PlatformEventController::startUpdating()
{
    if (m_isActive)
        return;

    if (hasLastData() && !m_timer.isActive()) {
        // Make sure to fire the data as soon as possible.
        m_timer.startOneShot(0, FROM_HERE);
    }

    registerWithDispatcher();
    m_isActive = true;
}

void PlatformEventController::stopUpdating()
{
    if (!m_isActive)
        return;

    if (m_timer.isActive())
        m_timer.stop();

    unregisterWithDispatcher();
    m_isActive = false;
}

void PlatformEventController::pageVisibilityChanged()
{
    if (!m_hasEventListener)
        return;

    if (page()->visibilityState() == PageVisibilityStateVisible)
        startUpdating();
    else
        stopUpdating();
}

} // namespace blink
