/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
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
#include "sky/engine/core/dom/shadow/ElementShadow.h"

#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/ElementTraversal.h"
#include "sky/engine/core/dom/NodeTraversal.h"
#include "sky/engine/core/dom/shadow/ContentDistribution.h"
#include "sky/engine/core/html/HTMLContentElement.h"
#include "sky/engine/platform/EventDispatchForbiddenScope.h"
#include "sky/engine/platform/ScriptForbiddenScope.h"

namespace blink {

class DistributionPool final {
    STACK_ALLOCATED();
public:
    explicit DistributionPool(const ContainerNode&);
    void clear();
    ~DistributionPool();
    void distributeTo(InsertionPoint*, ElementShadow*);
    void populateChildren(const ContainerNode&);

private:
    void detachNonDistributedNodes();
    Vector<RawPtr<Node>, 32> m_nodes;
    Vector<bool, 32> m_distributed;
};

inline DistributionPool::DistributionPool(const ContainerNode& parent)
{
    populateChildren(parent);
}

inline void DistributionPool::clear()
{
    detachNonDistributedNodes();
    m_nodes.clear();
    m_distributed.clear();
}

inline void DistributionPool::populateChildren(const ContainerNode& parent)
{
    clear();
    for (Node* child = parent.firstChild(); child; child = child->nextSibling()) {
        if (isActiveInsertionPoint(*child)) {
            InsertionPoint* insertionPoint = toInsertionPoint(child);
            for (size_t i = 0; i < insertionPoint->size(); ++i)
                m_nodes.append(insertionPoint->at(i));
        } else {
            m_nodes.append(child);
        }
    }
    m_distributed.resize(m_nodes.size());
    m_distributed.fill(false);
}

void DistributionPool::distributeTo(InsertionPoint* insertionPoint, ElementShadow* elementShadow)
{
    ContentDistribution distribution;

    for (size_t i = 0; i < m_nodes.size(); ++i) {
        if (m_distributed[i])
            continue;

        if (isHTMLContentElement(*insertionPoint) && !toHTMLContentElement(insertionPoint)->canSelectNode(m_nodes, i))
            continue;

        Node* node = m_nodes[i];
        distribution.append(node);
        elementShadow->didDistributeNode(node, insertionPoint);
        m_distributed[i] = true;
    }

    // Distributes fallback elements
    if (insertionPoint->isContentInsertionPoint() && distribution.isEmpty()) {
        for (Node* fallbackNode = insertionPoint->firstChild(); fallbackNode; fallbackNode = fallbackNode->nextSibling()) {
            distribution.append(fallbackNode);
            elementShadow->didDistributeNode(fallbackNode, insertionPoint);
        }
    }
    insertionPoint->setDistribution(distribution);
}

inline DistributionPool::~DistributionPool()
{
    detachNonDistributedNodes();
}

inline void DistributionPool::detachNonDistributedNodes()
{
    for (size_t i = 0; i < m_nodes.size(); ++i) {
        if (m_distributed[i])
            continue;
        if (m_nodes[i]->renderer())
            m_nodes[i]->lazyReattachIfAttached();
    }
}

PassOwnPtr<ElementShadow> ElementShadow::create()
{
    return adoptPtr(new ElementShadow());
}

ElementShadow::ElementShadow()
    : m_shadowRoot(0)
    , m_needsDistributionRecalc(false)
    , m_needsSelectFeatureSet(false)
{
}

ElementShadow::~ElementShadow()
{
    removeDetachedShadowRoot();
}

ShadowRoot& ElementShadow::addShadowRoot(Element& shadowHost)
{
    EventDispatchForbiddenScope assertNoEventDispatch;
    ScriptForbiddenScope forbidScript;

    ASSERT(!m_shadowRoot);

    RefPtr<ShadowRoot> shadowRoot = ShadowRoot::create(shadowHost.document());
    shadowRoot->setParentOrShadowHostNode(&shadowHost);
    shadowRoot->setParentTreeScope(shadowHost.treeScope());
    m_shadowRoot = shadowRoot.get();

    setNeedsDistributionRecalc();

    shadowRoot->insertedInto(&shadowHost);

    return *shadowRoot;
}

void ElementShadow::removeDetachedShadowRoot()
{
    // Dont protect this ref count.
    Element* shadowHost = host();
    ASSERT(shadowHost);

    if (RefPtr<ShadowRoot> oldRoot = m_shadowRoot) {
        shadowHost->document().removeFocusedElementOfSubtree(oldRoot.get());
        m_shadowRoot = 0;
        oldRoot->setParentOrShadowHostNode(0);
        oldRoot->setParentTreeScope(shadowHost->document());
    }
}

void ElementShadow::attach(const Node::AttachContext& context)
{
    if (!m_shadowRoot)
        return;

    ASSERT(m_shadowRoot->needsAttach());

    Node::AttachContext childrenContext(context);
    childrenContext.resolvedStyle = 0;
    m_shadowRoot->attach(childrenContext);
}

void ElementShadow::detach(const Node::AttachContext& context)
{
    if (!m_shadowRoot)
        return;

    Node::AttachContext childrenContext(context);
    childrenContext.resolvedStyle = 0;
    m_shadowRoot->detach(childrenContext);
}

void ElementShadow::setNeedsDistributionRecalc()
{
    if (m_needsDistributionRecalc)
        return;
    m_needsDistributionRecalc = true;
    host()->markAncestorsWithChildNeedsDistributionRecalc();
    clearDistribution();
}

bool ElementShadow::hasSameStyles(const ElementShadow* other) const
{
    ShadowRoot* root = m_shadowRoot;
    ShadowRoot* otherRoot = other->shadowRoot();
    if (!root && !otherRoot)
        return true;
    if (root && otherRoot)
        return root->hasSameStyles(*otherRoot);
    return false;
}

const InsertionPoint* ElementShadow::finalDestinationInsertionPointFor(const Node* key) const
{
    ASSERT(key && !key->document().childNeedsDistributionRecalc());
    NodeToDestinationInsertionPoints::const_iterator it = m_nodeToInsertionPoints.find(key);
    return it == m_nodeToInsertionPoints.end() ? 0: it->value.last().get();
}

const DestinationInsertionPoints* ElementShadow::destinationInsertionPointsFor(const Node* key) const
{
    ASSERT(key && !key->document().childNeedsDistributionRecalc());
    NodeToDestinationInsertionPoints::const_iterator it = m_nodeToInsertionPoints.find(key);
    return it == m_nodeToInsertionPoints.end() ? 0: &it->value;
}

void ElementShadow::distribute()
{
    host()->setNeedsStyleRecalc(SubtreeStyleChange);
    DistributionPool pool(*host());

    if (ShadowRoot* root = shadowRoot()) {
        const Vector<RefPtr<InsertionPoint> >& insertionPoints = root->descendantInsertionPoints();
        for (size_t i = 0; i < insertionPoints.size(); ++i) {
            InsertionPoint* point = insertionPoints[i].get();
            if (!point->isActive())
                continue;
            pool.distributeTo(point, this);
            if (ElementShadow* shadow = shadowWhereNodeCanBeDistributed(*point))
                shadow->setNeedsDistributionRecalc();
        }
    }
}

void ElementShadow::didDistributeNode(const Node* node, InsertionPoint* insertionPoint)
{
    NodeToDestinationInsertionPoints::AddResult result = m_nodeToInsertionPoints.add(node, DestinationInsertionPoints());
    result.storedValue->value.append(insertionPoint);
}

const SelectRuleFeatureSet& ElementShadow::ensureSelectFeatureSet()
{
    if (!m_needsSelectFeatureSet)
        return m_selectFeatures;

    m_selectFeatures.clear();
    if (ShadowRoot* root = shadowRoot())
        collectSelectFeatureSetFrom(*root);
    m_needsSelectFeatureSet = false;
    return m_selectFeatures;
}

void ElementShadow::collectSelectFeatureSetFrom(ShadowRoot& root)
{
    if (!root.containsShadowRoots() && !root.containsContentElements())
        return;

    for (Element* element = ElementTraversal::firstWithin(root); element; element = ElementTraversal::next(*element, &root)) {
        if (ElementShadow* shadow = element->shadow())
            m_selectFeatures.add(shadow->ensureSelectFeatureSet());
        if (!isHTMLContentElement(*element))
            continue;
        const CSSSelectorList& list = toHTMLContentElement(*element).selectorList();
        for (const CSSSelector* selector = list.first(); selector; selector = CSSSelectorList::next(*selector)) {
            for (const CSSSelector* component = selector; component; component = component->tagHistory())
                m_selectFeatures.collectFeaturesFromSelector(*component);
        }
    }
}

void ElementShadow::willAffectSelector()
{
    for (ElementShadow* shadow = this; shadow; shadow = shadow->containingShadow()) {
        if (shadow->needsSelectFeatureSet())
            break;
        shadow->setNeedsSelectFeatureSet();
    }
    setNeedsDistributionRecalc();
}

void ElementShadow::clearDistribution()
{
    m_nodeToInsertionPoints.clear();
}

} // namespace
