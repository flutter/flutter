/*
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
 */

#include "config.h"

#include "core/page/TouchAdjustment.h"

#include "core/dom/ContainerNode.h"
#include "core/dom/Node.h"
#include "core/dom/NodeRenderStyle.h"
#include "core/dom/Text.h"
#include "core/editing/Editor.h"
#include "core/frame/FrameView.h"
#include "core/frame/LocalFrame.h"
#include "core/rendering/RenderBox.h"
#include "core/rendering/RenderObject.h"
#include "core/rendering/RenderText.h"
#include "core/rendering/style/RenderStyle.h"
#include "platform/geometry/FloatPoint.h"
#include "platform/geometry/FloatQuad.h"
#include "platform/geometry/IntSize.h"
#include "platform/text/TextBreakIterator.h"

namespace blink {

namespace TouchAdjustment {

const float zeroTolerance = 1e-6f;

// Class for remembering absolute quads of a target node and what node they represent.
class SubtargetGeometry {
    ALLOW_ONLY_INLINE_ALLOCATION();
public:
    SubtargetGeometry(Node* node, const FloatQuad& quad)
        : m_node(node)
        , m_quad(quad)
    { }
    void trace(Visitor* visitor) { visitor->trace(m_node); }

    Node* node() const { return m_node; }
    FloatQuad quad() const { return m_quad; }
    IntRect boundingBox() const { return m_quad.enclosingBoundingBox(); }

private:
    RawPtrWillBeMember<Node> m_node;
    FloatQuad m_quad;
};

}

}

WTF_ALLOW_MOVE_INIT_AND_COMPARE_WITH_MEM_FUNCTIONS(blink::TouchAdjustment::SubtargetGeometry)

namespace blink {

namespace TouchAdjustment {

typedef WillBeHeapVector<SubtargetGeometry> SubtargetGeometryList;
typedef bool (*NodeFilter)(Node*);
typedef void (*AppendSubtargetsForNode)(Node*, SubtargetGeometryList&);
typedef float (*DistanceFunction)(const IntPoint&, const IntRect&, const SubtargetGeometry&);

// Takes non-const Node* because isContentEditable is a non-const function.
bool nodeRespondsToTapGesture(Node* node)
{
    if (node->willRespondToMouseClickEvents() || node->willRespondToMouseMoveEvents())
        return true;
    if (node->isElementNode()) {
        Element* element = toElement(node);
        // Tapping on a text field or other focusable item should trigger adjustment, except
        // that iframe elements are hard-coded to support focus but the effect is often invisible
        // so they should be excluded.
        if (element->isMouseFocusable())
            return true;
    }
    if (RenderStyle* renderStyle = node->renderStyle()) {
        if (renderStyle->affectedByActive() || renderStyle->affectedByHover())
            return true;
    }
    return false;
}

bool nodeIsZoomTarget(Node* node)
{
    if (node->isTextNode() || node->isShadowRoot())
        return false;

    ASSERT(node->renderer());
    return node->renderer()->isBox();
}

bool providesContextMenuItems(Node* node)
{
    // This function tries to match the nodes that receive special context-menu items in
    // ContextMenuController::populate(), and should be kept uptodate with those.
    ASSERT(node->renderer() || node->isShadowRoot());
    if (!node->renderer())
        return false;
    if (node->isContentEditable())
        return true;
    if (node->isLink())
        return true;
    if (node->renderer()->isImage())
        return true;
    if (node->renderer()->isMedia())
        return true;
    if (node->renderer()->canBeSelectionLeaf()) {
        // If the context menu gesture will trigger a selection all selectable nodes are valid targets.
        if (node->renderer()->frame()->editor().behavior().shouldSelectOnContextualMenuClick())
            return true;
        // Only the selected part of the renderer is a valid target, but this will be corrected in
        // appendContextSubtargetsForNode.
        if (node->renderer()->selectionState() != RenderObject::SelectionNone)
            return true;
    }
    return false;
}

static inline void appendQuadsToSubtargetList(Vector<FloatQuad>& quads, Node* node, SubtargetGeometryList& subtargets)
{
    Vector<FloatQuad>::const_iterator it = quads.begin();
    const Vector<FloatQuad>::const_iterator end = quads.end();
    for (; it != end; ++it)
        subtargets.append(SubtargetGeometry(node, *it));
}

static inline void appendBasicSubtargetsForNode(Node* node, SubtargetGeometryList& subtargets)
{
    // Node guaranteed to have renderer due to check in node filter.
    ASSERT(node->renderer());

    Vector<FloatQuad> quads;
    node->renderer()->absoluteQuads(quads);

    appendQuadsToSubtargetList(quads, node, subtargets);
}

static inline void appendContextSubtargetsForNode(Node* node, SubtargetGeometryList& subtargets)
{
    // This is a variant of appendBasicSubtargetsForNode that adds special subtargets for
    // selected or auto-selectable parts of text nodes.
    ASSERT(node->renderer());

    if (!node->isTextNode())
        return appendBasicSubtargetsForNode(node, subtargets);

    Text* textNode = toText(node);
    RenderText* textRenderer = textNode->renderer();

    if (textRenderer->frame()->editor().behavior().shouldSelectOnContextualMenuClick()) {
        // Make subtargets out of every word.
        String textValue = textNode->data();
        TextBreakIterator* wordIterator = wordBreakIterator(textValue, 0, textValue.length());
        int lastOffset = wordIterator->first();
        if (lastOffset == -1)
            return;
        int offset;
        while ((offset = wordIterator->next()) != -1) {
            if (isWordTextBreak(wordIterator)) {
                Vector<FloatQuad> quads;
                textRenderer->absoluteQuadsForRange(quads, lastOffset, offset);
                appendQuadsToSubtargetList(quads, textNode, subtargets);
            }
            lastOffset = offset;
        }
    } else {
        if (textRenderer->selectionState() == RenderObject::SelectionNone)
            return appendBasicSubtargetsForNode(node, subtargets);
        // If selected, make subtargets out of only the selected part of the text.
        int startPos, endPos;
        switch (textRenderer->selectionState()) {
        case RenderObject::SelectionInside:
            startPos = 0;
            endPos = textRenderer->textLength();
            break;
        case RenderObject::SelectionStart:
            textRenderer->selectionStartEnd(startPos, endPos);
            endPos = textRenderer->textLength();
            break;
        case RenderObject::SelectionEnd:
            textRenderer->selectionStartEnd(startPos, endPos);
            startPos = 0;
            break;
        case RenderObject::SelectionBoth:
            textRenderer->selectionStartEnd(startPos, endPos);
            break;
        default:
            ASSERT_NOT_REACHED();
            return;
        }
        Vector<FloatQuad> quads;
        textRenderer->absoluteQuadsForRange(quads, startPos, endPos);
        appendQuadsToSubtargetList(quads, textNode, subtargets);
    }
}

static inline void appendZoomableSubtargets(Node* node, SubtargetGeometryList& subtargets)
{
    RenderBox* renderer = toRenderBox(node->renderer());
    ASSERT(renderer);

    Vector<FloatQuad> quads;
    FloatRect borderBoxRect = renderer->borderBoxRect();
    FloatRect contentBoxRect = renderer->contentBoxRect();
    quads.append(renderer->localToAbsoluteQuad(borderBoxRect));
    if (borderBoxRect != contentBoxRect)
        quads.append(renderer->localToAbsoluteQuad(contentBoxRect));
    // FIXME: For RenderBlocks, add column boxes and content boxes cleared for floats.

    Vector<FloatQuad>::const_iterator it = quads.begin();
    const Vector<FloatQuad>::const_iterator end = quads.end();
    for (; it != end; ++it)
        subtargets.append(SubtargetGeometry(node, *it));
}

static inline Node* parentShadowHostOrOwner(const Node* node)
{
    if (Node* ancestor = node->parentOrShadowHostNode())
        return ancestor;
    return 0;
}

// Compiles a list of subtargets of all the relevant target nodes.
void compileSubtargetList(const WillBeHeapVector<RefPtrWillBeMember<Node> >& intersectedNodes, SubtargetGeometryList& subtargets, NodeFilter nodeFilter, AppendSubtargetsForNode appendSubtargetsForNode)
{
    // Find candidates responding to tap gesture events in O(n) time.
    WillBeHeapHashMap<RawPtrWillBeMember<Node>, RawPtrWillBeMember<Node> > responderMap;
    WillBeHeapHashSet<RawPtrWillBeMember<Node> > ancestorsToRespondersSet;
    WillBeHeapVector<RawPtrWillBeMember<Node> > candidates;
    WillBeHeapHashSet<RawPtrWillBeMember<Node> > editableAncestors;

    // A node matching the NodeFilter is called a responder. Candidate nodes must either be a
    // responder or have an ancestor that is a responder.
    // This iteration tests all ancestors at most once by caching earlier results.
    for (unsigned i = 0; i < intersectedNodes.size(); ++i) {
        Node* node = intersectedNodes[i].get();
        WillBeHeapVector<RawPtrWillBeMember<Node> > visitedNodes;
        Node* respondingNode = 0;
        for (Node* visitedNode = node; visitedNode; visitedNode = visitedNode->parentOrShadowHostNode()) {
            // Check if we already have a result for a common ancestor from another candidate.
            respondingNode = responderMap.get(visitedNode);
            if (respondingNode)
                break;
            visitedNodes.append(visitedNode);
            // Check if the node filter applies, which would mean we have found a responding node.
            if (nodeFilter(visitedNode)) {
                respondingNode = visitedNode;
                // Continue the iteration to collect the ancestors of the responder, which we will need later.
                for (visitedNode = parentShadowHostOrOwner(visitedNode); visitedNode; visitedNode = parentShadowHostOrOwner(visitedNode)) {
                    WillBeHeapHashSet<RawPtrWillBeMember<Node> >::AddResult addResult = ancestorsToRespondersSet.add(visitedNode);
                    if (!addResult.isNewEntry)
                        break;
                }
                break;
            }
        }
        // Insert the detected responder for all the visited nodes.
        for (unsigned j = 0; j < visitedNodes.size(); j++)
            responderMap.add(visitedNodes[j], respondingNode);

        if (respondingNode)
            candidates.append(node);
    }

    // We compile the list of component absolute quads instead of using the bounding rect
    // to be able to perform better hit-testing on inline links on line-breaks.
    for (unsigned i = 0; i < candidates.size(); i++) {
        Node* candidate = candidates[i];
        // Skip nodes who's responders are ancestors of other responders. This gives preference to
        // the inner-most event-handlers. So that a link is always preferred even when contained
        // in an element that monitors all click-events.
        Node* respondingNode = responderMap.get(candidate);
        ASSERT(respondingNode);
        if (ancestorsToRespondersSet.contains(respondingNode))
            continue;
        // Consolidate bounds for editable content.
        if (editableAncestors.contains(candidate))
            continue;
        if (candidate->isContentEditable()) {
            Node* replacement = candidate;
            Node* parent = candidate->parentOrShadowHostNode();
            while (parent && parent->isContentEditable()) {
                replacement = parent;
                if (editableAncestors.contains(replacement)) {
                    replacement = 0;
                    break;
                }
                editableAncestors.add(replacement);
                parent = parent->parentOrShadowHostNode();
            }
            candidate = replacement;
        }
        if (candidate)
            appendSubtargetsForNode(candidate, subtargets);
    }
}

// Compiles a list of zoomable subtargets.
void compileZoomableSubtargets(const WillBeHeapVector<RefPtrWillBeMember<Node> >& intersectedNodes, SubtargetGeometryList& subtargets)
{
    for (unsigned i = 0; i < intersectedNodes.size(); ++i) {
        Node* candidate = intersectedNodes[i].get();
        if (nodeIsZoomTarget(candidate))
            appendZoomableSubtargets(candidate, subtargets);
    }
}

// This returns quotient of the target area and its intersection with the touch area.
// This will prioritize largest intersection and smallest area, while balancing the two against each other.
float zoomableIntersectionQuotient(const IntPoint& touchHotspot, const IntRect& touchArea, const SubtargetGeometry& subtarget)
{
    IntRect rect = subtarget.boundingBox();

    // Convert from frame coordinates to window coordinates.
    rect = subtarget.node()->document().view()->contentsToWindow(rect);

    // Check the rectangle is meaningful zoom target. It should at least contain the hotspot.
    if (!rect.contains(touchHotspot))
        return std::numeric_limits<float>::infinity();
    IntRect intersection = rect;
    intersection.intersect(touchArea);

    // Return the quotient of the intersection.
    return rect.size().area() / (float)intersection.size().area();
}

// Uses a hybrid of distance to adjust and intersect ratio, normalizing each score between 0 and 1
// and combining them. The distance to adjust works best for disambiguating clicks on targets such
// as links, where the width may be significantly larger than the touch width. Using area of overlap
// in such cases can lead to a bias towards shorter links. Conversely, percentage of overlap can
// provide strong confidence in tapping on a small target, where the overlap is often quite high,
// and works well for tightly packed controls.
float hybridDistanceFunction(const IntPoint& touchHotspot, const IntRect& touchRect, const SubtargetGeometry& subtarget)
{
    IntRect rect = subtarget.boundingBox();

    // Convert from frame coordinates to window coordinates.
    rect = subtarget.node()->document().view()->contentsToWindow(rect);

    float radiusSquared = 0.25f * (touchRect.size().diagonalLengthSquared());
    float distanceToAdjustScore = rect.distanceSquaredToPoint(touchHotspot) / radiusSquared;

    int maxOverlapWidth = std::min(touchRect.width(), rect.width());
    int maxOverlapHeight = std::min(touchRect.height(), rect.height());
    float maxOverlapArea = std::max(maxOverlapWidth * maxOverlapHeight, 1);
    rect.intersect(touchRect);
    float intersectArea = rect.size().area();
    float intersectionScore = 1 - intersectArea / maxOverlapArea;

    float hybridScore = intersectionScore + distanceToAdjustScore;

    return hybridScore;
}

FloatPoint contentsToWindow(FrameView *view, FloatPoint pt)
{
    int x = static_cast<int>(pt.x() + 0.5f);
    int y = static_cast<int>(pt.y() + 0.5f);
    IntPoint adjusted = view->contentsToWindow(IntPoint(x, y));
    return FloatPoint(adjusted.x(), adjusted.y());
}

// Adjusts 'point' to the nearest point inside rect, and leaves it unchanged if already inside.
void adjustPointToRect(FloatPoint& point, const FloatRect& rect)
{
    if (point.x() < rect.x())
        point.setX(rect.x());
    else if (point.x() > rect.maxX())
        point.setX(rect.maxX());

    if (point.y() < rect.y())
        point.setY(rect.y());
    else if (point.y() > rect.maxY())
        point.setY(rect.maxY());
}

bool snapTo(const SubtargetGeometry& geom, const IntPoint& touchPoint, const IntRect& touchArea, IntPoint& adjustedPoint)
{
    FrameView* view = geom.node()->document().view();
    FloatQuad quad = geom.quad();

    if (quad.isRectilinear()) {
        IntRect contentBounds = geom.boundingBox();
        // Convert from frame coordinates to window coordinates.
        IntRect bounds = view->contentsToWindow(contentBounds);
        if (bounds.contains(touchPoint)) {
            adjustedPoint = touchPoint;
            return true;
        }
        if (bounds.intersects(touchArea)) {
            bounds.intersect(touchArea);
            adjustedPoint = bounds.center();
            return true;
        }
        return false;
    }

    // The following code tries to adjust the point to place inside a both the touchArea and the non-rectilinear quad.
    // FIXME: This will return the point inside the touch area that is the closest to the quad center, but does not
    // guarantee that the point will be inside the quad. Corner-cases exist where the quad will intersect but this
    // will fail to adjust the point to somewhere in the intersection.

    // Convert quad from content to window coordinates.
    FloatPoint p1 = contentsToWindow(view, quad.p1());
    FloatPoint p2 = contentsToWindow(view, quad.p2());
    FloatPoint p3 = contentsToWindow(view, quad.p3());
    FloatPoint p4 = contentsToWindow(view, quad.p4());
    quad = FloatQuad(p1, p2, p3, p4);

    if (quad.containsPoint(touchPoint)) {
        adjustedPoint = touchPoint;
        return true;
    }

    // Pull point towards the center of the element.
    FloatPoint center = quad.center();

    adjustPointToRect(center, touchArea);
    adjustedPoint = roundedIntPoint(center);

    return quad.containsPoint(adjustedPoint);
}

// A generic function for finding the target node with the lowest distance metric. A distance metric here is the result
// of a distance-like function, that computes how well the touch hits the node.
// Distance functions could for instance be distance squared or area of intersection.
bool findNodeWithLowestDistanceMetric(Node*& targetNode, IntPoint& targetPoint, IntRect& targetArea, const IntPoint& touchHotspot, const IntRect& touchArea, SubtargetGeometryList& subtargets, DistanceFunction distanceFunction)
{
    targetNode = 0;
    float bestDistanceMetric = std::numeric_limits<float>::infinity();
    SubtargetGeometryList::const_iterator it = subtargets.begin();
    const SubtargetGeometryList::const_iterator end = subtargets.end();
    IntPoint adjustedPoint;

    for (; it != end; ++it) {
        Node* node = it->node();
        float distanceMetric = distanceFunction(touchHotspot, touchArea, *it);
        if (distanceMetric < bestDistanceMetric) {
            if (snapTo(*it, touchHotspot, touchArea, adjustedPoint)) {
                targetPoint = adjustedPoint;
                targetArea = it->boundingBox();
                targetNode = node;
                bestDistanceMetric = distanceMetric;
            }
        } else if (distanceMetric - bestDistanceMetric < zeroTolerance) {
            if (snapTo(*it, touchHotspot, touchArea, adjustedPoint)) {
                if (node->isDescendantOf(targetNode)) {
                    // Try to always return the inner-most element.
                    targetPoint = adjustedPoint;
                    targetNode = node;
                    targetArea = it->boundingBox();
                }
            }
        }
    }

    if (targetNode) {
        targetArea = targetNode->document().view()->contentsToWindow(targetArea);
    }
    return (targetNode);
}

} // namespace TouchAdjustment

bool findBestClickableCandidate(Node*& targetNode, IntPoint& targetPoint, const IntPoint& touchHotspot, const IntRect& touchArea, const WillBeHeapVector<RefPtrWillBeMember<Node> >& nodes)
{
    IntRect targetArea;
    TouchAdjustment::SubtargetGeometryList subtargets;
    TouchAdjustment::compileSubtargetList(nodes, subtargets, TouchAdjustment::nodeRespondsToTapGesture, TouchAdjustment::appendBasicSubtargetsForNode);
    return TouchAdjustment::findNodeWithLowestDistanceMetric(targetNode, targetPoint, targetArea, touchHotspot, touchArea, subtargets, TouchAdjustment::hybridDistanceFunction);
}

bool findBestContextMenuCandidate(Node*& targetNode, IntPoint& targetPoint, const IntPoint& touchHotspot, const IntRect& touchArea, const WillBeHeapVector<RefPtrWillBeMember<Node> >& nodes)
{
    IntRect targetArea;
    TouchAdjustment::SubtargetGeometryList subtargets;
    TouchAdjustment::compileSubtargetList(nodes, subtargets, TouchAdjustment::providesContextMenuItems, TouchAdjustment::appendContextSubtargetsForNode);
    return TouchAdjustment::findNodeWithLowestDistanceMetric(targetNode, targetPoint, targetArea, touchHotspot, touchArea, subtargets, TouchAdjustment::hybridDistanceFunction);
}

bool findBestZoomableArea(Node*& targetNode, IntRect& targetArea, const IntPoint& touchHotspot, const IntRect& touchArea, const WillBeHeapVector<RefPtrWillBeMember<Node> >& nodes)
{
    IntPoint targetPoint;
    TouchAdjustment::SubtargetGeometryList subtargets;
    TouchAdjustment::compileZoomableSubtargets(nodes, subtargets);
    return TouchAdjustment::findNodeWithLowestDistanceMetric(targetNode, targetPoint, targetArea, touchHotspot, touchArea, subtargets, TouchAdjustment::zoomableIntersectionQuotient);
}

} // namespace blink
