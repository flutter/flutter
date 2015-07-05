/*
 * Copyright (C) 2006, 2008, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2012 Nokia Corporation and/or its subsidiary(-ies)
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
 *
*/

#include "sky/engine/core/rendering/HitTestResult.h"

#include "gen/sky/core/HTMLNames.h"
#include "sky/engine/core/dom/DocumentMarkerController.h"
#include "sky/engine/core/dom/NodeRenderingTraversal.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/editing/FrameSelection.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/rendering/RenderBox.h"
#include "sky/engine/core/rendering/RenderObject.h"

namespace blink {

HitTestResult::HitTestResult()
{
}

HitTestResult::HitTestResult(const LayoutPoint& point)
    : m_hitTestLocation(point)
    , m_pointInInnerNodeFrame(point)
{
}

HitTestResult::HitTestResult(const LayoutPoint& centerPoint, unsigned topPadding, unsigned rightPadding, unsigned bottomPadding, unsigned leftPadding)
    : m_hitTestLocation(centerPoint, topPadding, rightPadding, bottomPadding, leftPadding)
    , m_pointInInnerNodeFrame(centerPoint)
{
}

HitTestResult::HitTestResult(const HitTestLocation& other)
    : m_hitTestLocation(other)
    , m_pointInInnerNodeFrame(m_hitTestLocation.point())
{
}

HitTestResult::HitTestResult(const HitTestResult& other)
    : m_hitTestLocation(other.m_hitTestLocation)
    , m_innerNode(other.innerNode())
    , m_innerPossiblyPseudoNode(other.m_innerPossiblyPseudoNode)
    , m_innerNonSharedNode(other.innerNonSharedNode())
    , m_pointInInnerNodeFrame(other.m_pointInInnerNodeFrame)
    , m_localPoint(other.localPoint())
{
    // Only copy the NodeSet in case of rect hit test.
    m_rectBasedTestResult = adoptPtr(other.m_rectBasedTestResult ? new NodeSet(*other.m_rectBasedTestResult) : 0);
}

HitTestResult::~HitTestResult()
{
}

HitTestResult& HitTestResult::operator=(const HitTestResult& other)
{
    m_hitTestLocation = other.m_hitTestLocation;
    m_innerNode = other.innerNode();
    m_innerPossiblyPseudoNode = other.innerPossiblyPseudoNode();
    m_innerNonSharedNode = other.innerNonSharedNode();
    m_pointInInnerNodeFrame = other.m_pointInInnerNodeFrame;
    m_localPoint = other.localPoint();

    // Only copy the NodeSet in case of rect hit test.
    m_rectBasedTestResult = adoptPtr(other.m_rectBasedTestResult ? new NodeSet(*other.m_rectBasedTestResult) : 0);

    return *this;
}

PositionWithAffinity HitTestResult::position() const
{
    if (!m_innerPossiblyPseudoNode)
        return PositionWithAffinity();
    RenderObject* renderer = this->renderer();
    if (!renderer)
        return PositionWithAffinity();
    return renderer->positionForPoint(localPoint());
}

RenderObject* HitTestResult::renderer() const
{
    if (!m_innerNode)
        return 0;
    return m_innerNode->renderer();
}

void HitTestResult::setInnerNode(Node* n)
{
    m_innerPossiblyPseudoNode = n;
    m_innerNode = n;
}

void HitTestResult::setInnerNonSharedNode(Node* n)
{
    m_innerNonSharedNode = n;
}

LocalFrame* HitTestResult::innerNodeFrame() const
{
    if (m_innerNonSharedNode)
        return m_innerNonSharedNode->document().frame();
    if (m_innerNode)
        return m_innerNode->document().frame();
    return 0;
}

bool HitTestResult::isSelected() const
{
    if (!m_innerNonSharedNode)
        return false;

    if (LocalFrame* frame = m_innerNonSharedNode->document().frame())
        return frame->selection().contains(m_hitTestLocation.point());
    return false;
}

Image* HitTestResult::image() const
{
    return 0;
}

IntRect HitTestResult::imageRect() const
{
    if (!image())
        return IntRect();
    return m_innerNonSharedNode->renderBox()->absoluteContentQuad().enclosingBoundingBox();
}

bool HitTestResult::isMisspelled() const
{
    if (!targetNode() || !targetNode()->renderer())
        return false;
    VisiblePosition pos(targetNode()->renderer()->positionForPoint(localPoint()));
    if (pos.isNull())
        return false;
    return m_innerNonSharedNode->document().markers().markersInRange(
        makeRange(pos, pos).get(), DocumentMarker::MisspellingMarkers()).size() > 0;
}

// FIXME: This function needs a better name and may belong in a different class. It's not
// really isContentEditable(); it's more like needsEditingContextMenu(). In many ways, this
// function would make more sense in the ContextMenu class, except that WebElementDictionary
// hooks into it. Anyway, we should architect this better.
bool HitTestResult::isContentEditable() const
{
    if (!m_innerNonSharedNode)
        return false;
    return m_innerNonSharedNode->hasEditableStyle();
}

bool HitTestResult::addNodeToRectBasedTestResult(Node* node, const HitTestRequest& request, const HitTestLocation& locationInContainer, const LayoutRect& rect)
{
    // If it is not a rect-based hit test, this method has to be no-op.
    // Return false, so the hit test stops.
    if (!isRectBasedTest())
        return false;

    // If node is null, return true so the hit test can continue.
    if (!node)
        return true;

    mutableRectBasedTestResult().add(node);

    bool regionFilled = rect.contains(locationInContainer.boundingBox());
    return !regionFilled;
}

bool HitTestResult::addNodeToRectBasedTestResult(Node* node, const HitTestRequest& request, const HitTestLocation& locationInContainer, const FloatRect& rect)
{
    // If it is not a rect-based hit test, this method has to be no-op.
    // Return false, so the hit test stops.
    if (!isRectBasedTest())
        return false;

    // If node is null, return true so the hit test can continue.
    if (!node)
        return true;

    mutableRectBasedTestResult().add(node);

    bool regionFilled = rect.contains(locationInContainer.boundingBox());
    return !regionFilled;
}

void HitTestResult::append(const HitTestResult& other)
{
    ASSERT(isRectBasedTest() && other.isRectBasedTest());

    if (!m_innerNode && other.innerNode()) {
        m_innerNode = other.innerNode();
        m_innerPossiblyPseudoNode = other.innerPossiblyPseudoNode();
        m_innerNonSharedNode = other.innerNonSharedNode();
        m_localPoint = other.localPoint();
        m_pointInInnerNodeFrame = other.m_pointInInnerNodeFrame;
    }

    if (other.m_rectBasedTestResult) {
        NodeSet& set = mutableRectBasedTestResult();
        for (NodeSet::const_iterator it = other.m_rectBasedTestResult->begin(), last = other.m_rectBasedTestResult->end(); it != last; ++it)
            set.add(it->get());
    }
}

const HitTestResult::NodeSet& HitTestResult::rectBasedTestResult() const
{
    if (!m_rectBasedTestResult)
        m_rectBasedTestResult = adoptPtr(new NodeSet);
    return *m_rectBasedTestResult;
}

HitTestResult::NodeSet& HitTestResult::mutableRectBasedTestResult()
{
    if (!m_rectBasedTestResult)
        m_rectBasedTestResult = adoptPtr(new NodeSet);
    return *m_rectBasedTestResult;
}

void HitTestResult::resolveRectBasedTest(Node* resolvedInnerNode, const LayoutPoint& resolvedPointInMainFrame)
{
    // FIXME: For maximum fidelity with point-based hit tests we should probably make use
    // of RenderObject::updateHitTestResult here. See http://crbug.com/398914.
    ASSERT(isRectBasedTest());
    ASSERT(m_hitTestLocation.containsPoint(resolvedPointInMainFrame));
    setInnerNode(resolvedInnerNode);
    setInnerNonSharedNode(resolvedInnerNode);
    m_hitTestLocation = HitTestLocation(resolvedPointInMainFrame);
    m_pointInInnerNodeFrame = resolvedPointInMainFrame;
    m_rectBasedTestResult = nullptr;
    ASSERT(!isRectBasedTest());
}

Element* HitTestResult::innerElement() const
{
    for (Node* node = m_innerNode.get(); node; node = NodeRenderingTraversal::parent(node)) {
        if (node->isElementNode())
            return toElement(node);
    }

    return 0;
}

} // namespace blink
