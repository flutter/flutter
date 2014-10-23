/*
 * Copyright (C) 2001 Peter Kelly (pmk@post.com)
 * Copyright (C) 2001 Tobias Anton (anton@stud.fbi.fh-darmstadt.de)
 * Copyright (C) 2006 Samuel Weinig (sam.weinig@gmail.com)
 * Copyright (C) 2003, 2005, 2006, 2008 Apple Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#include "config.h"
#include "core/events/MouseRelatedEvent.h"

#include "core/dom/Document.h"
#include "core/frame/LocalDOMWindow.h"
#include "core/frame/FrameView.h"
#include "core/frame/LocalFrame.h"
#include "core/rendering/RenderLayer.h"
#include "core/rendering/RenderObject.h"

namespace blink {

MouseRelatedEvent::MouseRelatedEvent()
    : m_isSimulated(false)
    , m_hasCachedRelativePosition(false)
{
}

static LayoutSize contentsScrollOffset(AbstractView* abstractView)
{
    if (!abstractView)
        return LayoutSize();
    LocalFrame* frame = abstractView->frame();
    if (!frame)
        return LayoutSize();
    FrameView* frameView = frame->view();
    if (!frameView)
        return LayoutSize();
    float scaleFactor = frame->pageZoomFactor();
    return LayoutSize(frameView->scrollX() / scaleFactor, frameView->scrollY() / scaleFactor);
}

MouseRelatedEvent::MouseRelatedEvent(const AtomicString& eventType, bool canBubble, bool cancelable, PassRefPtrWillBeRawPtr<AbstractView> abstractView,
                                     int detail, const IntPoint& screenLocation, const IntPoint& windowLocation,
                                     const IntPoint& movementDelta,
                                     bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, bool isSimulated)
    : UIEventWithKeyState(eventType, canBubble, cancelable, abstractView, detail, ctrlKey, altKey, shiftKey, metaKey)
    , m_screenLocation(screenLocation)
    , m_movementDelta(movementDelta)
    , m_isSimulated(isSimulated)
{
    LayoutPoint adjustedPageLocation;
    LayoutPoint scrollPosition;

    LocalFrame* frame = view() ? view()->frame() : 0;
    if (frame && !isSimulated) {
        if (FrameView* frameView = frame->view()) {
            scrollPosition = frameView->scrollPosition();
            adjustedPageLocation = frameView->windowToContents(windowLocation);
            float scaleFactor = 1 / frame->pageZoomFactor();
            if (scaleFactor != 1.0f) {
                adjustedPageLocation.scale(scaleFactor, scaleFactor);
                scrollPosition.scale(scaleFactor, scaleFactor);
            }
        }
    }

    m_clientLocation = adjustedPageLocation - toLayoutSize(scrollPosition);
    m_pageLocation = adjustedPageLocation;

    initCoordinates();
}

void MouseRelatedEvent::initCoordinates()
{
    // Set up initial values for coordinates.
    // Correct values are computed lazily, see computeRelativePosition.
    m_layerLocation = m_pageLocation;
    m_offsetLocation = m_pageLocation;

    computePageLocation();
    m_hasCachedRelativePosition = false;
}

void MouseRelatedEvent::initCoordinates(const LayoutPoint& clientLocation)
{
    // Set up initial values for coordinates.
    // Correct values are computed lazily, see computeRelativePosition.
    m_clientLocation = clientLocation;
    m_pageLocation = clientLocation + contentsScrollOffset(view());

    m_layerLocation = m_pageLocation;
    m_offsetLocation = m_pageLocation;

    computePageLocation();
    m_hasCachedRelativePosition = false;
}

static float pageZoomFactor(const UIEvent* event)
{
    LocalDOMWindow* window = event->view();
    if (!window)
        return 1;
    LocalFrame* frame = window->frame();
    if (!frame)
        return 1;
    return frame->pageZoomFactor();
}

void MouseRelatedEvent::computePageLocation()
{
    float scaleFactor = pageZoomFactor(this);
    setAbsoluteLocation(roundedLayoutPoint(FloatPoint(pageX() * scaleFactor, pageY() * scaleFactor)));
}

void MouseRelatedEvent::receivedTarget()
{
    m_hasCachedRelativePosition = false;
}

void MouseRelatedEvent::computeRelativePosition()
{
    Node* targetNode = target() ? target()->toNode() : 0;
    if (!targetNode)
        return;

    // Compute coordinates that are based on the target.
    m_layerLocation = m_pageLocation;
    m_offsetLocation = m_pageLocation;

    // Must have an updated render tree for this math to work correctly.
    targetNode->document().updateLayoutIgnorePendingStylesheets();

    // Adjust offsetLocation to be relative to the target's position.
    if (RenderObject* r = targetNode->renderer()) {
        FloatPoint localPos = r->absoluteToLocal(absoluteLocation(), UseTransforms);
        m_offsetLocation = roundedLayoutPoint(localPos);
        float scaleFactor = 1 / pageZoomFactor(this);
        if (scaleFactor != 1.0f)
            m_offsetLocation.scale(scaleFactor, scaleFactor);
    }

    // Adjust layerLocation to be relative to the layer.
    // FIXME: event.layerX and event.layerY are poorly defined,
    // and probably don't always correspond to RenderLayer offsets.
    // https://bugs.webkit.org/show_bug.cgi?id=21868
    Node* n = targetNode;
    while (n && !n->renderer())
        n = n->parentNode();

    if (n) {
        // FIXME: This logic is a wrong implementation of convertToLayerCoords.
        for (RenderLayer* layer = n->renderer()->enclosingLayer(); layer; layer = layer->parent())
            m_layerLocation -= toLayoutSize(layer->location());
    }

    m_hasCachedRelativePosition = true;
}

int MouseRelatedEvent::layerX()
{
    if (!m_hasCachedRelativePosition)
        computeRelativePosition();
    return m_layerLocation.x();
}

int MouseRelatedEvent::layerY()
{
    if (!m_hasCachedRelativePosition)
        computeRelativePosition();
    return m_layerLocation.y();
}

int MouseRelatedEvent::offsetX()
{
    if (isSimulated())
        return 0;
    if (!m_hasCachedRelativePosition)
        computeRelativePosition();
    return roundToInt(m_offsetLocation.x());
}

int MouseRelatedEvent::offsetY()
{
    if (isSimulated())
        return 0;
    if (!m_hasCachedRelativePosition)
        computeRelativePosition();
    return roundToInt(m_offsetLocation.y());
}

int MouseRelatedEvent::pageX() const
{
    return m_pageLocation.x();
}

int MouseRelatedEvent::pageY() const
{
    return m_pageLocation.y();
}

int MouseRelatedEvent::x() const
{
    // FIXME: This is not correct.
    // See Microsoft documentation and <http://www.quirksmode.org/dom/w3c_events.html>.
    return m_clientLocation.x();
}

int MouseRelatedEvent::y() const
{
    // FIXME: This is not correct.
    // See Microsoft documentation and <http://www.quirksmode.org/dom/w3c_events.html>.
    return m_clientLocation.y();
}

void MouseRelatedEvent::trace(Visitor* visitor)
{
    UIEventWithKeyState::trace(visitor);
}

} // namespace blink
