// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/view/View.h"

namespace blink {

PassRefPtr<View> View::create(const base::Closure& scheduleFrameCallback)
{
    return adoptRef(new View(scheduleFrameCallback));
}

View::View(const base::Closure& scheduleFrameCallback)
    : m_scheduleFrameCallback(scheduleFrameCallback)
{
}

View::~View()
{
}

double View::width() const
{
    double w = m_displayMetrics.physical_size.width;
    return w / m_displayMetrics.device_pixel_ratio;
}

double View::height() const
{
    double h = m_displayMetrics.physical_size.height;
    return h / m_displayMetrics.device_pixel_ratio;
}

void View::setEventCallback(PassOwnPtr<EventCallback> callback)
{
    m_eventCallback = callback;
}

void View::setMetricsChangedCallback(PassOwnPtr<VoidCallback> callback)
{
    m_metricsChangedCallback = callback;
}

void View::setBeginFrameCallback(PassOwnPtr<BeginFrameCallback> callback)
{
    m_beginFrameCallback = callback;
}

void View::scheduleFrame()
{
    m_scheduleFrameCallback.Run();
}

void View::setDisplayMetrics(const SkyDisplayMetrics& metrics)
{
    m_displayMetrics = metrics;
    if (m_metricsChangedCallback)
        m_metricsChangedCallback->handleEvent();
}

void View::handleInputEvent(PassRefPtr<Event> event)
{
    if (m_eventCallback)
        m_eventCallback->handleEvent(event.get());
}

void View::beginFrame(base::TimeTicks frameTime)
{
    if (!m_beginFrameCallback)
        return;
    double frameTimeMS = (frameTime - base::TimeTicks()).InMillisecondsF();
    m_beginFrameCallback->handleEvent(frameTimeMS);
}

} // namespace blink
