/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 * Copyright (C) 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Alexey Proskuryakov (ap@webkit.org)
 * Copyright (C) 2012 Digia Plc. and/or its subsidiary(-ies)
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
 */

#include "sky/engine/config.h"
#include "sky/engine/core/page/AutoscrollController.h"

#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/page/Chrome.h"
#include "sky/engine/core/page/EventHandler.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/core/rendering/HitTestResult.h"
#include "sky/engine/core/rendering/RenderBox.h"
#include "sky/engine/wtf/CurrentTime.h"

namespace blink {

// Delay time in second for start autoscroll if pointer is in border edge of scrollable element.
static double autoscrollDelay = 0.2;

PassOwnPtr<AutoscrollController> AutoscrollController::create(Page& page)
{
    return adoptPtr(new AutoscrollController(page));
}

AutoscrollController::AutoscrollController(Page& page)
    : m_page(page)
    , m_autoscrollRenderer(0)
    , m_autoscrollType(NoAutoscroll)
    , m_dragAndDropAutoscrollStartTime(0)
{
}

bool AutoscrollController::autoscrollInProgress() const
{
    return m_autoscrollType == AutoscrollForSelection;
}

bool AutoscrollController::autoscrollInProgress(const RenderBox* renderer) const
{
    return m_autoscrollRenderer == renderer;
}

void AutoscrollController::startAutoscrollForSelection(RenderObject* renderer)
{
    // We don't want to trigger the autoscroll or the panScroll if it's already active
    if (m_autoscrollType != NoAutoscroll)
        return;
    RenderBox* scrollable = RenderBox::findAutoscrollable(renderer);
    if (!scrollable)
        return;
    m_autoscrollType = AutoscrollForSelection;
    m_autoscrollRenderer = scrollable;
    startAutoscroll();
}

void AutoscrollController::stopAutoscroll()
{
    RenderBox* scrollable = m_autoscrollRenderer;
    m_autoscrollRenderer = 0;

    if (!scrollable)
        return;

    scrollable->stopAutoscroll();

    m_autoscrollType = NoAutoscroll;
}

void AutoscrollController::stopAutoscrollIfNeeded(RenderObject* renderer)
{
    if (m_autoscrollRenderer != renderer)
        return;
    m_autoscrollRenderer = 0;
    m_autoscrollType = NoAutoscroll;
}

void AutoscrollController::updateAutoscrollRenderer()
{
    if (!m_autoscrollRenderer)
        return;

    RenderObject* renderer = m_autoscrollRenderer;

    while (renderer && !(renderer->isBox() && toRenderBox(renderer)->canAutoscroll()))
        renderer = renderer->parent();
    m_autoscrollRenderer = renderer && renderer->isBox() ? toRenderBox(renderer) : 0;
}

void AutoscrollController::updateDragAndDrop(Node* dropTargetNode, const IntPoint& eventPosition, double eventTime)
{
    if (!dropTargetNode || !dropTargetNode->renderer()) {
        stopAutoscroll();
        return;
    }

    if (m_autoscrollRenderer && m_autoscrollRenderer->frame() != dropTargetNode->renderer()->frame())
        return;

    RenderBox* scrollable = RenderBox::findAutoscrollable(dropTargetNode->renderer());
    if (!scrollable) {
        stopAutoscroll();
        return;
    }

    Page* page = scrollable->frame() ? scrollable->frame()->page() : 0;
    if (!page) {
        stopAutoscroll();
        return;
    }

    IntSize offset = scrollable->calculateAutoscrollDirection(eventPosition);
    if (offset.isZero()) {
        stopAutoscroll();
        return;
    }

    m_dragAndDropAutoscrollReferencePosition = eventPosition + offset;

    if (m_autoscrollType == NoAutoscroll) {
        m_autoscrollType = AutoscrollForDragAndDrop;
        m_autoscrollRenderer = scrollable;
        m_dragAndDropAutoscrollStartTime = eventTime;
        startAutoscroll();
    } else if (m_autoscrollRenderer != scrollable) {
        m_dragAndDropAutoscrollStartTime = eventTime;
        m_autoscrollRenderer = scrollable;
    }
}

// FIXME: This would get get better animation fidelity if it used the monotonicFrameBeginTime instead
// of WTF::currentTime().
void AutoscrollController::animate(double)
{
    if (!m_autoscrollRenderer) {
        stopAutoscroll();
        return;
    }

    switch (m_autoscrollType) {
    case AutoscrollForDragAndDrop:
        if (WTF::currentTime() - m_dragAndDropAutoscrollStartTime > autoscrollDelay)
            m_autoscrollRenderer->autoscroll(m_dragAndDropAutoscrollReferencePosition);
        break;
    case AutoscrollForSelection:
    case NoAutoscroll:
        break;
    }
    if (m_autoscrollType != NoAutoscroll)
        m_page.chrome().scheduleAnimation();
}

void AutoscrollController::startAutoscroll()
{
    m_page.chrome().scheduleAnimation();
}

} // namespace blink
