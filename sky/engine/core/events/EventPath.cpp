/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#include "sky/engine/core/events/EventPath.h"

#include "gen/sky/core/EventNames.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/shadow/InsertionPoint.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/events/Event.h"

namespace blink {

EventTarget* EventPath::eventTargetRespectingTargetRules(Node* referenceNode)
{
    ASSERT(referenceNode);
    return referenceNode;
}

static inline bool shouldStopAtShadowRoot(Event& event, ShadowRoot& shadowRoot, EventTarget& target)
{
    // WebKit never allowed selectstart event to cross the the shadow DOM boundary.
    // Changing this breaks existing sites.
    // See https://bugs.webkit.org/show_bug.cgi?id=52195 for details.
    const AtomicString eventType = event.type();
    return target.toNode() && target.toNode()->shadowHost() == shadowRoot.host()
        && (eventType == EventTypeNames::abort
            || eventType == EventTypeNames::change
            || eventType == EventTypeNames::error
            || eventType == EventTypeNames::load
            || eventType == EventTypeNames::reset
            || eventType == EventTypeNames::resize
            || eventType == EventTypeNames::scroll
            || eventType == EventTypeNames::select
            || eventType == EventTypeNames::selectstart);
}

EventPath::EventPath(Event* event)
    : m_node(nullptr)
    , m_event(event)
{
}

EventPath::EventPath(Node* node)
    : m_node(node)
    , m_event(nullptr)
{
    resetWith(node);
}

void EventPath::resetWith(Node* node)
{
    ASSERT(node);
    m_node = node;
    m_nodeEventContexts.clear();
    m_treeScopeEventContexts.clear();
    calculatePath();
    calculateAdjustedTargets();
    calculateTreeScopePrePostOrderNumbers();
}

void EventPath::addNodeEventContext(Node* node)
{
    m_nodeEventContexts.append(NodeEventContext(node, eventTargetRespectingTargetRules(node)));
}

void EventPath::calculatePath()
{
    ASSERT(m_node);
    ASSERT(m_nodeEventContexts.isEmpty());
    m_node->document().updateDistributionForNodeIfNeeded(const_cast<Node*>(m_node.get()));

    Node* current = m_node;
    addNodeEventContext(current);
    if (!m_node->inDocument())
        return;
    while (current) {
        if (m_event && current->keepEventInNode(m_event))
            break;
        Vector<RawPtr<InsertionPoint>, 8> insertionPoints;
        collectDestinationInsertionPoints(*current, insertionPoints);
        if (!insertionPoints.isEmpty()) {
            for (size_t i = 0; i < insertionPoints.size(); ++i) {
                InsertionPoint* insertionPoint = insertionPoints[i];
                addNodeEventContext(insertionPoint);
            }
            current = insertionPoints.last();
            continue;
        }
        if (current->isShadowRoot()) {
            if (m_event && shouldStopAtShadowRoot(*m_event, *toShadowRoot(current), *m_node))
                break;
            current = current->shadowHost();
            addNodeEventContext(current);
        } else {
            current = current->parentNode();
            if (current)
                addNodeEventContext(current);
        }
    }
}

void EventPath::calculateTreeScopePrePostOrderNumbers()
{
    // Precondition:
    //   - TreeScopes in m_treeScopeEventContexts must be *connected* in the same tree of trees.
    //   - The root tree must be included.
    HashMap<RawPtr<const TreeScope>, RawPtr<TreeScopeEventContext> > treeScopeEventContextMap;
    for (size_t i = 0; i < m_treeScopeEventContexts.size(); ++i)
        treeScopeEventContextMap.add(&m_treeScopeEventContexts[i]->treeScope(), m_treeScopeEventContexts[i].get());
    TreeScopeEventContext* rootTree = 0;
    for (size_t i = 0; i < m_treeScopeEventContexts.size(); ++i) {
        TreeScopeEventContext* treeScopeEventContext = m_treeScopeEventContexts[i].get();
        // Use parentTreeScope here for parent-child relationships.
        // See the definition of trees of trees in the Shado DOM spec: http://w3c.github.io/webcomponents/spec/shadow/
        TreeScope* parent = treeScopeEventContext->treeScope().parentTreeScope();
        if (!parent) {
            ASSERT(!rootTree);
            rootTree = treeScopeEventContext;
            continue;
        }
        ASSERT(treeScopeEventContextMap.find(parent) != treeScopeEventContextMap.end());
        treeScopeEventContextMap.find(parent)->value->addChild(*treeScopeEventContext);
    }
    ASSERT(rootTree);
    rootTree->calculatePrePostOrderNumber(0);
}

TreeScopeEventContext* EventPath::ensureTreeScopeEventContext(Node* currentTarget, TreeScope* treeScope, TreeScopeEventContextMap& treeScopeEventContextMap)
{
    if (!treeScope)
        return 0;
    TreeScopeEventContext* treeScopeEventContext;
    bool isNewEntry;
    {
        TreeScopeEventContextMap::AddResult addResult = treeScopeEventContextMap.add(treeScope, nullptr);
        isNewEntry = addResult.isNewEntry;
        if (isNewEntry)
            addResult.storedValue->value = TreeScopeEventContext::create(*treeScope);
        treeScopeEventContext = addResult.storedValue->value.get();
    }
    if (isNewEntry) {
        TreeScopeEventContext* parentTreeScopeEventContext = ensureTreeScopeEventContext(0, treeScope->parentTreeScope(), treeScopeEventContextMap);
        if (parentTreeScopeEventContext && parentTreeScopeEventContext->target()) {
            treeScopeEventContext->setTarget(parentTreeScopeEventContext->target());
        } else if (currentTarget) {
            treeScopeEventContext->setTarget(eventTargetRespectingTargetRules(currentTarget));
        }
    } else if (!treeScopeEventContext->target() && currentTarget) {
        treeScopeEventContext->setTarget(eventTargetRespectingTargetRules(currentTarget));
    }
    return treeScopeEventContext;
}

void EventPath::calculateAdjustedTargets()
{
    const TreeScope* lastTreeScope = 0;

    TreeScopeEventContextMap treeScopeEventContextMap;
    TreeScopeEventContext* lastTreeScopeEventContext = 0;

    for (size_t i = 0; i < size(); ++i) {
        Node* currentNode = at(i).node();
        TreeScope& currentTreeScope = currentNode->treeScope();
        if (lastTreeScope != &currentTreeScope) {
            lastTreeScopeEventContext = ensureTreeScopeEventContext(currentNode, &currentTreeScope, treeScopeEventContextMap);
        }
        ASSERT(lastTreeScopeEventContext);
        at(i).setTreeScopeEventContext(lastTreeScopeEventContext);
        lastTreeScope = &currentTreeScope;
    }
    m_treeScopeEventContexts.appendRange(treeScopeEventContextMap.values().begin(), treeScopeEventContextMap.values().end());
}

void EventPath::buildRelatedNodeMap(const Node* relatedNode, RelatedTargetMap& relatedTargetMap)
{
    EventPath relatedTargetEventPath(const_cast<Node*>(relatedNode));
    for (size_t i = 0; i < relatedTargetEventPath.m_treeScopeEventContexts.size(); ++i) {
        TreeScopeEventContext* treeScopeEventContext = relatedTargetEventPath.m_treeScopeEventContexts[i].get();
        relatedTargetMap.add(&treeScopeEventContext->treeScope(), treeScopeEventContext->target());
    }
}

EventTarget* EventPath::findRelatedNode(TreeScope* scope, RelatedTargetMap& relatedTargetMap)
{
    Vector<RawPtr<TreeScope>, 32> parentTreeScopes;
    EventTarget* relatedNode = 0;
    while (scope) {
        parentTreeScopes.append(scope);
        RelatedTargetMap::const_iterator iter = relatedTargetMap.find(scope);
        if (iter != relatedTargetMap.end() && iter->value) {
            relatedNode = iter->value;
            break;
        }
        scope = scope->parentTreeScope();
    }
    ASSERT(relatedNode);
    for (Vector<RawPtr<TreeScope>, 32>::iterator iter = parentTreeScopes.begin(); iter < parentTreeScopes.end(); ++iter)
        relatedTargetMap.add(*iter, relatedNode);
    return relatedNode;
}

void EventPath::adjustForRelatedTarget(Node* target, EventTarget* relatedTarget)
{
    if (!target)
        return;
    if (!relatedTarget)
        return;
    Node* relatedNode = relatedTarget->toNode();
    if (!relatedNode)
        return;
    if (target->document() != relatedNode->document())
        return;
    if (!target->inDocument() || !relatedNode->inDocument())
        return;

    RelatedTargetMap relatedNodeMap;
    buildRelatedNodeMap(relatedNode, relatedNodeMap);

    for (size_t i = 0; i < m_treeScopeEventContexts.size(); ++i) {
        TreeScopeEventContext* treeScopeEventContext = m_treeScopeEventContexts[i].get();
        EventTarget* adjustedRelatedTarget = findRelatedNode(&treeScopeEventContext->treeScope(), relatedNodeMap);
        ASSERT(adjustedRelatedTarget);
        treeScopeEventContext->setRelatedTarget(adjustedRelatedTarget);
    }

    shrinkIfNeeded(target, relatedTarget);
}

void EventPath::shrinkIfNeeded(const Node* target, const EventTarget* relatedTarget)
{
    // Synthetic mouse events can have a relatedTarget which is identical to the target.
    bool targetIsIdenticalToToRelatedTarget = (target == relatedTarget);

    for (size_t i = 0; i < size(); ++i) {
        if (targetIsIdenticalToToRelatedTarget) {
            if (target->treeScope().rootNode() == at(i).node()) {
                shrink(i + 1);
                break;
            }
        } else if (at(i).target() == at(i).relatedTarget()) {
            // Event dispatching should be stopped here.
            shrink(i);
            break;
        }
    }
}

} // namespace
