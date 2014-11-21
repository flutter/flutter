/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#include "sky/engine/config.h"

#include "sky/engine/core/page/TouchDisambiguation.h"

#include <algorithm>
#include <cmath>
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/NodeTraversal.h"
#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/page/EventHandler.h"
#include "sky/engine/core/rendering/HitTestResult.h"
#include "sky/engine/core/rendering/RenderBlock.h"

namespace blink {

static IntRect boundingBoxForEventNodes(Node* eventNode)
{
    if (!eventNode->document().view())
        return IntRect();

    IntRect result;
    Node* node = eventNode;
    while (node) {
        // Skip the whole sub-tree if the node doesn't propagate events.
        if (node != eventNode && node->willRespondToMouseClickEvents()) {
            node = NodeTraversal::nextSkippingChildren(*node, eventNode);
            continue;
        }
        result.unite(node->pixelSnappedBoundingBox());
        node = NodeTraversal::next(*node, eventNode);
    }
    return eventNode->document().view()->contentsToWindow(result);
}

static float scoreTouchTarget(IntPoint touchPoint, int padding, IntRect boundingBox)
{
    if (boundingBox.isEmpty())
        return 0;

    float reciprocalPadding = 1.f / padding;
    float score = 1;

    IntSize distance = boundingBox.differenceToPoint(touchPoint);
    score *= std::max((padding - abs(distance.width())) * reciprocalPadding, 0.f);
    score *= std::max((padding - abs(distance.height())) * reciprocalPadding, 0.f);

    return score;
}

struct TouchTargetData {
    IntRect windowBoundingBox;
    float score;
};

void findGoodTouchTargets(const IntRect& touchBox, LocalFrame* mainFrame, Vector<IntRect>& goodTargets, Vector<RawPtr<Node> >& highlightNodes)
{
    goodTargets.clear();

    int touchPointPadding = ceil(std::max(touchBox.width(), touchBox.height()) * 0.5);

    IntPoint touchPoint = touchBox.center();
    IntPoint contentsPoint = mainFrame->view()->windowToContents(touchPoint);

    HitTestResult result = mainFrame->eventHandler().hitTestResultAtPoint(contentsPoint, HitTestRequest::ReadOnly | HitTestRequest::Active, IntSize(touchPointPadding, touchPointPadding));
    const ListHashSet<RefPtr<Node> >& hitResults = result.rectBasedTestResult();

    // Blacklist nodes that are container of disambiguated nodes.
    // It is not uncommon to have a clickable <div> that contains other clickable objects.
    // This heuristic avoids excessive disambiguation in that case.
    HashSet<RawPtr<Node> > blackList;
    for (ListHashSet<RefPtr<Node> >::const_iterator it = hitResults.begin(); it != hitResults.end(); ++it) {
        // Ignore any Nodes that can't be clicked on.
        RenderObject* renderer = it->get()->renderer();
        if (!renderer || !it->get()->willRespondToMouseClickEvents())
            continue;

        // Blacklist all of the Node's containers.
        for (RenderBlock* container = renderer->containingBlock(); container; container = container->containingBlock()) {
            Node* containerNode = container->node();
            if (!containerNode)
                continue;
            if (!blackList.add(containerNode).isNewEntry)
                break;
        }
    }

    HashMap<RawPtr<Node>, TouchTargetData> touchTargets;
    float bestScore = 0;
    for (ListHashSet<RefPtr<Node> >::const_iterator it = hitResults.begin(); it != hitResults.end(); ++it) {
        for (Node* node = it->get(); node; node = node->parentNode()) {
            if (blackList.contains(node))
                continue;
            if (node->isDocumentNode())
                break;
            if (node->willRespondToMouseClickEvents()) {
                TouchTargetData& targetData = touchTargets.add(node, TouchTargetData()).storedValue->value;
                targetData.windowBoundingBox = boundingBoxForEventNodes(node);
                targetData.score = scoreTouchTarget(touchPoint, touchPointPadding, targetData.windowBoundingBox);
                bestScore = std::max(bestScore, targetData.score);
                break;
            }
        }
    }

    for (HashMap<RawPtr<Node>, TouchTargetData>::iterator it = touchTargets.begin(); it != touchTargets.end(); ++it) {
        // Currently the scoring function uses the overlap area with the fat point as the score.
        // We ignore the candidates that has less than 1/2 overlap (we consider not really ambiguous enough) than the best candidate to avoid excessive popups.
        if (it->value.score < bestScore * 0.5)
            continue;
        goodTargets.append(it->value.windowBoundingBox);
        highlightNodes.append(it->key);
    }
}

} // namespace blink
