/*
 * Copyright (C) 2006 Apple Computer, Inc.
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

#ifndef SKY_ENGINE_CORE_RENDERING_HITTESTRESULT_H_
#define SKY_ENGINE_CORE_RENDERING_HITTESTRESULT_H_

#include "sky/engine/core/rendering/HitTestLocation.h"
#include "sky/engine/core/rendering/HitTestRequest.h"
#include "sky/engine/platform/geometry/FloatQuad.h"
#include "sky/engine/platform/geometry/FloatRect.h"
#include "sky/engine/platform/geometry/LayoutRect.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/platform/text/TextDirection.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/ListHashSet.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/RefPtr.h"

namespace blink {

class Element;
class LocalFrame;
class Image;
class KURL;
class Node;
class RenderObject;
class PositionWithAffinity;

class HitTestResult {
    DISALLOW_ALLOCATION();
public:
    typedef ListHashSet<RefPtr<Node> > NodeSet;

    HitTestResult();
    HitTestResult(const LayoutPoint&);
    // Pass non-negative padding values to perform a rect-based hit test.
    HitTestResult(const LayoutPoint& centerPoint, unsigned topPadding, unsigned rightPadding, unsigned bottomPadding, unsigned leftPadding);
    HitTestResult(const HitTestLocation&);
    HitTestResult(const HitTestResult&);
    ~HitTestResult();
    HitTestResult& operator=(const HitTestResult&);

    // For point-based hit tests, these accessors provide information about the node
    // under the point. For rect-based hit tests they are meaningless (reflect the
    // last candidate node observed in the rect).
    // FIXME: Make these less error-prone for rect-based hit tests (center point or fail).
    Node* innerNode() const { return m_innerNode.get(); }
    Node* innerPossiblyPseudoNode() const { return m_innerPossiblyPseudoNode.get(); }
    Element* innerElement() const;
    Node* innerNonSharedNode() const { return m_innerNonSharedNode.get(); }
    bool isOverWidget() const { return m_isOverWidget; }

    // Forwarded from HitTestLocation
    bool isRectBasedTest() const { return m_hitTestLocation.isRectBasedTest(); }

    // The hit-tested point in the coordinates of the main frame.
    const LayoutPoint& pointInMainFrame() const { return m_hitTestLocation.point(); }
    IntPoint roundedPointInMainFrame() const { return roundedIntPoint(pointInMainFrame()); }

    // The hit-tested point in the coordinates of the innerNode frame, the frame containing innerNode.
    const LayoutPoint& pointInInnerNodeFrame() const { return m_pointInInnerNodeFrame; }
    IntPoint roundedPointInInnerNodeFrame() const { return roundedIntPoint(pointInInnerNodeFrame()); }
    LocalFrame* innerNodeFrame() const;

    // The hit-tested point in the coordinates of the inner node.
    const LayoutPoint& localPoint() const { return m_localPoint; }
    void setLocalPoint(const LayoutPoint& p) { m_localPoint = p; }

    PositionWithAffinity position() const;
    RenderObject* renderer() const;

    const HitTestLocation& hitTestLocation() const { return m_hitTestLocation; }

    void setInnerNode(Node*);
    void setInnerNonSharedNode(Node*);

    bool isSelected() const;
    Image* image() const;
    IntRect imageRect() const;
    bool isMisspelled() const;
    bool isContentEditable() const;

    // Returns true if it is rect-based hit test and needs to continue until the rect is fully
    // enclosed by the boundaries of a node.
    bool addNodeToRectBasedTestResult(Node*, const HitTestRequest&, const HitTestLocation& pointInContainer, const LayoutRect& = LayoutRect());
    bool addNodeToRectBasedTestResult(Node*, const HitTestRequest&, const HitTestLocation& pointInContainer, const FloatRect&);
    void append(const HitTestResult&);

    // If m_rectBasedTestResult is 0 then set it to a new NodeSet. Return *m_rectBasedTestResult. Lazy allocation makes
    // sense because the NodeSet is seldom necessary, and it's somewhat expensive to allocate and initialize. This method does
    // the same thing as mutableRectBasedTestResult(), but here the return value is const.
    const NodeSet& rectBasedTestResult() const;

    // Collapse the rect-based test result into a single target at the specified location.
    void resolveRectBasedTest(Node* resolvedInnerNode, const LayoutPoint& resolvedPointInMainFrame);

    // FIXME: Remove this.
    Node* targetNode() const { return innerNode(); }

private:
    NodeSet& mutableRectBasedTestResult(); // See above.

    HitTestLocation m_hitTestLocation;

    RefPtr<Node> m_innerNode;
    RefPtr<Node> m_innerPossiblyPseudoNode;
    RefPtr<Node> m_innerNonSharedNode;
    // FIXME: Nothing changes this to a value different from m_hitTestLocation!
    LayoutPoint m_pointInInnerNodeFrame; // The hit-tested point in innerNode frame coordinates.
    LayoutPoint m_localPoint; // A point in the local coordinate space of m_innerNonSharedNode's renderer. Allows us to efficiently
                              // determine where inside the renderer we hit on subsequent operations.
    bool m_isOverWidget; // Returns true if we are over a widget.

    mutable OwnPtr<NodeSet> m_rectBasedTestResult;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_HITTESTRESULT_H_
