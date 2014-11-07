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

#include "config.h"
#include "core/dom/shadow/InsertionPoint.h"

#include "core/dom/Document.h"
#include "core/dom/ElementTraversal.h"
#include "core/dom/QualifiedName.h"
#include "core/dom/StaticNodeList.h"
#include "core/dom/shadow/ElementShadow.h"

namespace blink {

InsertionPoint::InsertionPoint(const QualifiedName& tagName, Document& document)
    : HTMLElement(tagName, document, CreateInsertionPoint)
    , m_registeredWithShadowRoot(false)
{
}

InsertionPoint::~InsertionPoint()
{
}

void InsertionPoint::setDistribution(ContentDistribution& distribution)
{
    if (shouldUseFallbackElements()) {
        for (Node* child = firstChild(); child; child = child->nextSibling())
            child->lazyReattachIfAttached();
    }

    // Attempt not to reattach nodes that would be distributed to the exact same
    // location by comparing the old and new distributions.

    size_t i = 0;
    size_t j = 0;

    for ( ; i < m_distribution.size() && j < distribution.size(); ++i, ++j) {
        if (m_distribution.size() < distribution.size()) {
            // If the new distribution is larger than the old one, reattach all nodes in
            // the new distribution that were inserted.
            for ( ; j < distribution.size() && m_distribution.at(i) != distribution.at(j); ++j)
                distribution.at(j)->lazyReattachIfAttached();
        } else if (m_distribution.size() > distribution.size()) {
            // If the old distribution is larger than the new one, reattach all nodes in
            // the old distribution that were removed.
            for ( ; i < m_distribution.size() && m_distribution.at(i) != distribution.at(j); ++i)
                m_distribution.at(i)->lazyReattachIfAttached();
        } else if (m_distribution.at(i) != distribution.at(j)) {
            // If both distributions are the same length reattach both old and new.
            m_distribution.at(i)->lazyReattachIfAttached();
            distribution.at(j)->lazyReattachIfAttached();
        }
    }

    // If we hit the end of either list above we need to reattach all remaining nodes.

    for ( ; i < m_distribution.size(); ++i)
        m_distribution.at(i)->lazyReattachIfAttached();

    for ( ; j < distribution.size(); ++j)
        distribution.at(j)->lazyReattachIfAttached();

    m_distribution.swap(distribution);
    m_distribution.shrinkToFit();
}

void InsertionPoint::attach(const AttachContext& context)
{
    // We need to attach the distribution here so that they're inserted in the right order
    // otherwise the n^2 protection inside RenderTreeBuilder will cause them to be
    // inserted in the wrong place later. This also lets distributed nodes benefit from
    // the n^2 protection.
    for (size_t i = 0; i < m_distribution.size(); ++i) {
        if (m_distribution.at(i)->needsAttach())
            m_distribution.at(i)->attach(context);
    }

    HTMLElement::attach(context);
}

void InsertionPoint::detach(const AttachContext& context)
{
    for (size_t i = 0; i < m_distribution.size(); ++i)
        m_distribution.at(i)->lazyReattachIfAttached();

    HTMLElement::detach(context);
}

void InsertionPoint::willRecalcStyle(StyleRecalcChange change)
{
    if (change < Inherit)
        return;
    for (size_t i = 0; i < m_distribution.size(); ++i)
        m_distribution.at(i)->setNeedsStyleRecalc(SubtreeStyleChange);
}

bool InsertionPoint::shouldUseFallbackElements() const
{
    return isActive() && !hasDistribution();
}

bool InsertionPoint::canBeActive() const
{
    if (!isInShadowTree())
        return false;
    return !Traversal<InsertionPoint>::firstAncestor(*this);
}

bool InsertionPoint::isActive() const
{
    if (!canBeActive())
        return false;
    ShadowRoot* shadowRoot = containingShadowRoot();
    if (!shadowRoot)
        return false;
    if (!isHTMLShadowElement(*this) || shadowRoot->descendantShadowElementCount() <= 1)
        return true;

    // Slow path only when there are more than one shadow elements in a shadow tree. That should be a rare case.
    const Vector<RefPtr<InsertionPoint> >& insertionPoints = shadowRoot->descendantInsertionPoints();
    for (size_t i = 0; i < insertionPoints.size(); ++i) {
        InsertionPoint* point = insertionPoints[i].get();
        if (isHTMLShadowElement(*point))
            return point == this;
    }
    return true;
}

bool InsertionPoint::isShadowInsertionPoint() const
{
    return isHTMLShadowElement(*this) && isActive();
}

bool InsertionPoint::isContentInsertionPoint() const
{
    return isHTMLContentElement(*this) && isActive();
}

PassRefPtr<StaticNodeList> InsertionPoint::getDistributedNodes()
{
    document().updateDistributionForNodeIfNeeded(this);

    Vector<RefPtr<Node> > nodes;
    nodes.reserveInitialCapacity(m_distribution.size());
    for (size_t i = 0; i < m_distribution.size(); ++i)
        nodes.uncheckedAppend(m_distribution.at(i));

    return StaticNodeList::adopt(nodes);
}

void InsertionPoint::childrenChanged(const ChildrenChange& change)
{
    HTMLElement::childrenChanged(change);
    if (ShadowRoot* root = containingShadowRoot()) {
        if (ElementShadow* rootOwner = root->owner())
            rootOwner->setNeedsDistributionRecalc();
    }
}

Node::InsertionNotificationRequest InsertionPoint::insertedInto(ContainerNode* insertionPoint)
{
    HTMLElement::insertedInto(insertionPoint);
    if (ShadowRoot* root = containingShadowRoot()) {
        if (ElementShadow* rootOwner = root->owner()) {
            rootOwner->setNeedsDistributionRecalc();
            if (canBeActive() && !m_registeredWithShadowRoot && insertionPoint->treeScope().rootNode() == root) {
                m_registeredWithShadowRoot = true;
                root->didAddInsertionPoint(this);
                if (canAffectSelector())
                    rootOwner->willAffectSelector();
            }
        }
    }

    return InsertionDone;
}

void InsertionPoint::removedFrom(ContainerNode* insertionPoint)
{
    ShadowRoot* root = containingShadowRoot();
    if (!root)
        root = insertionPoint->containingShadowRoot();

    if (root) {
        if (ElementShadow* rootOwner = root->owner())
            rootOwner->setNeedsDistributionRecalc();
    }

    // host can be null when removedFrom() is called from ElementShadow destructor.
    ElementShadow* rootOwner = root ? root->owner() : 0;

    // Since this insertion point is no longer visible from the shadow subtree, it need to clean itself up.
    clearDistribution();

    if (m_registeredWithShadowRoot && insertionPoint->treeScope().rootNode() == root) {
        ASSERT(root);
        m_registeredWithShadowRoot = false;
        root->didRemoveInsertionPoint(this);
        if (rootOwner) {
            if (canAffectSelector())
                rootOwner->willAffectSelector();
        }
    }

    HTMLElement::removedFrom(insertionPoint);
}

const InsertionPoint* resolveReprojection(const Node* projectedNode)
{
    ASSERT(projectedNode);
    const InsertionPoint* insertionPoint = 0;
    const Node* current = projectedNode;
    ElementShadow* lastElementShadow = 0;
    while (true) {
        ElementShadow* shadow = shadowWhereNodeCanBeDistributed(*current);
        if (!shadow || shadow == lastElementShadow)
            break;
        lastElementShadow = shadow;
        const InsertionPoint* insertedTo = shadow->finalDestinationInsertionPointFor(projectedNode);
        if (!insertedTo)
            break;
        ASSERT(current != insertedTo);
        current = insertedTo;
        insertionPoint = insertedTo;
    }
    return insertionPoint;
}

void collectDestinationInsertionPoints(const Node& node, Vector<RawPtr<InsertionPoint>, 8>& results)
{
    const Node* current = &node;
    ElementShadow* lastElementShadow = 0;
    while (true) {
        ElementShadow* shadow = shadowWhereNodeCanBeDistributed(*current);
        if (!shadow || shadow == lastElementShadow)
            return;
        lastElementShadow = shadow;
        const DestinationInsertionPoints* insertionPoints = shadow->destinationInsertionPointsFor(&node);
        if (!insertionPoints)
            return;
        for (size_t i = 0; i < insertionPoints->size(); ++i)
            results.append(insertionPoints->at(i).get());
        ASSERT(current != insertionPoints->last().get());
        current = insertionPoints->last().get();
    }
}

} // namespace blink
