/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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
#include "web/ViewportAnchor.h"

#include "core/dom/ContainerNode.h"
#include "core/dom/Node.h"
#include "core/page/EventHandler.h"
#include "core/rendering/HitTestResult.h"

namespace blink {

namespace {

static const float viewportAnchorRelativeEpsilon = 0.1f;
static const int viewportToNodeMaxRelativeArea = 2;

template <typename RectType>
int area(const RectType& rect) {
    return rect.width() * rect.height();
}

Node* findNonEmptyAnchorNode(const IntPoint& point, const IntRect& viewRect, EventHandler* eventHandler)
{
    Node* node = eventHandler->hitTestResultAtPoint(point, HitTestRequest::ReadOnly | HitTestRequest::Active).innerNode();

    // If the node bounding box is sufficiently large, make a single attempt to
    // find a smaller node; the larger the node bounds, the greater the
    // variability under resize.
    const int maxNodeArea = area(viewRect) * viewportToNodeMaxRelativeArea;
    if (node && area(node->boundingBox()) > maxNodeArea) {
        IntSize pointOffset = viewRect.size();
        pointOffset.scale(viewportAnchorRelativeEpsilon);
        node = eventHandler->hitTestResultAtPoint(point + pointOffset, HitTestRequest::ReadOnly | HitTestRequest::Active).innerNode();
    }

    while (node && node->boundingBox().isEmpty())
        node = node->parentNode();

    return node;
}

} // namespace

ViewportAnchor::ViewportAnchor(EventHandler* eventHandler)
    : m_eventHandler(eventHandler) { }

void ViewportAnchor::setAnchor(const IntRect& viewRect, const FloatSize& anchorInViewCoords)
{
    m_viewRect = viewRect;
    m_anchorNode.clear();
    m_anchorNodeBounds = LayoutRect();
    m_anchorInNodeCoords = FloatSize();
    m_anchorInViewCoords = anchorInViewCoords;

    if (viewRect.isEmpty())
        return;

    // Preserve origins at the absolute screen origin
    if (viewRect.location() == IntPoint::zero())
        return;

    FloatSize anchorOffset = viewRect.size();
    anchorOffset.scale(anchorInViewCoords.width(), anchorInViewCoords.height());
    const FloatPoint anchorPoint = FloatPoint(viewRect.location()) + anchorOffset;

    Node* node = findNonEmptyAnchorNode(flooredIntPoint(anchorPoint), viewRect, m_eventHandler);
    if (!node)
        return;

    m_anchorNode = node;
    m_anchorNodeBounds = node->boundingBox();
    m_anchorInNodeCoords = anchorPoint - m_anchorNodeBounds.location();
    m_anchorInNodeCoords.scale(1.f / m_anchorNodeBounds.width(), 1.f / m_anchorNodeBounds.height());
}

IntPoint ViewportAnchor::computeOrigin(const IntSize& currentViewSize) const
{
    if (!m_anchorNode || !m_anchorNode->inDocument())
        return m_viewRect.location();

    const LayoutRect currentNodeBounds = m_anchorNode->boundingBox();
    if (m_anchorNodeBounds == currentNodeBounds)
        return m_viewRect.location();

    // Compute the new anchor point relative to the node position
    FloatSize anchorOffsetFromNode = currentNodeBounds.size();
    anchorOffsetFromNode.scale(m_anchorInNodeCoords.width(), m_anchorInNodeCoords.height());
    FloatPoint anchorPoint = currentNodeBounds.location() + anchorOffsetFromNode;

    // Compute the new origin point relative to the new anchor point
    FloatSize anchorOffsetFromOrigin = currentViewSize;
    anchorOffsetFromOrigin.scale(m_anchorInViewCoords.width(), m_anchorInViewCoords.height());
    return flooredIntPoint(anchorPoint - anchorOffsetFromOrigin);
}

} // namespace blink
