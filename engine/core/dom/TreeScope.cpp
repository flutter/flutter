/*
 * Copyright (C) 2011 Google Inc. All Rights Reserved.
 * Copyright (C) 2012 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "sky/engine/config.h"
#include "sky/engine/core/dom/TreeScope.h"

#include "gen/sky/core/HTMLNames.h"
#include "sky/engine/core/css/StyleSheetList.h"
#include "sky/engine/core/css/resolver/ScopedStyleResolver.h"
#include "sky/engine/core/dom/ContainerNode.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/ElementTraversal.h"
#include "sky/engine/core/dom/NodeRenderStyle.h"
#include "sky/engine/core/dom/TreeScopeAdopter.h"
#include "sky/engine/core/dom/shadow/ElementShadow.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/editing/DOMSelection.h"
#include "sky/engine/core/events/EventPath.h"
#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/html/HTMLAnchorElement.h"
#include "sky/engine/core/page/FocusController.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/core/rendering/HitTestResult.h"
#include "sky/engine/core/rendering/RenderView.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

TreeScope::TreeScope(ContainerNode& rootNode, Document& document)
    : m_rootNode(&rootNode)
    , m_document(&document)
    , m_parentTreeScope(&document)
#if !ENABLE(OILPAN)
    , m_guardRefCount(0)
#endif
{
    ASSERT(rootNode != document);
#if !ENABLE(OILPAN)
    m_parentTreeScope->guardRef();
#endif
    m_rootNode->setTreeScope(this);
}

TreeScope::TreeScope(Document& document)
    : m_rootNode(document)
    , m_document(&document)
    , m_parentTreeScope(nullptr)
#if !ENABLE(OILPAN)
    , m_guardRefCount(0)
#endif
{
    m_rootNode->setTreeScope(this);
}

TreeScope::~TreeScope()
{
#if !ENABLE(OILPAN)
    ASSERT(!m_guardRefCount);
    m_rootNode->setTreeScope(0);

    if (m_selection) {
        m_selection->clearTreeScope();
        m_selection = nullptr;
    }

    if (m_parentTreeScope)
        m_parentTreeScope->guardDeref();
#endif
}

bool TreeScope::isInclusiveOlderSiblingShadowRootOrAncestorTreeScopeOf(const TreeScope& scope) const
{
    for (const TreeScope* current = &scope; current; current = current->parentTreeScope()) {
        if (current == this)
            return true;
    }
    return false;
}

bool TreeScope::rootNodeHasTreeSharedParent() const
{
    return rootNode().hasTreeSharedParent();
}

#if !ENABLE(OILPAN)
void TreeScope::destroyTreeScopeData()
{
    m_elementsById.clear();
    m_imageMapsByName.clear();
    m_labelsByForAttribute.clear();
}
#endif

void TreeScope::setParentTreeScope(TreeScope& newParentScope)
{
    // A document node cannot be re-parented.
    ASSERT(!rootNode().isDocumentNode());

#if !ENABLE(OILPAN)
    newParentScope.guardRef();
    if (m_parentTreeScope)
        m_parentTreeScope->guardDeref();
#endif
    m_parentTreeScope = &newParentScope;
    setDocument(newParentScope.document());
}

ScopedStyleResolver& TreeScope::ensureScopedStyleResolver()
{
    RELEASE_ASSERT(this);
    if (!m_scopedStyleResolver)
        m_scopedStyleResolver = ScopedStyleResolver::create(*this);
    return *m_scopedStyleResolver;
}

void TreeScope::clearScopedStyleResolver()
{
    m_scopedStyleResolver.clear();
}

Element* TreeScope::getElementById(const AtomicString& elementId) const
{
    if (elementId.isEmpty())
        return 0;
    if (!m_elementsById)
        return 0;
    return m_elementsById->getElementById(elementId, this);
}

void TreeScope::addElementById(const AtomicString& elementId, Element* element)
{
    if (!m_elementsById)
        m_elementsById = DocumentOrderedMap::create();
    m_elementsById->add(elementId, element);
}

void TreeScope::removeElementById(const AtomicString& elementId, Element* element)
{
    if (!m_elementsById)
        return;
    m_elementsById->remove(elementId, element);
}

Node* TreeScope::ancestorInThisScope(Node* node) const
{
    while (node) {
        if (node->treeScope() == this)
            return node;
        if (!node->isInShadowTree())
            return 0;

        node = node->shadowHost();
    }

    return 0;
}

HitTestResult hitTestInDocument(const Document* document, int x, int y)
{
    LocalFrame* frame = document->frame();

    if (!frame)
        return HitTestResult();
    FrameView* frameView = frame->view();
    if (!frameView)
        return HitTestResult();

    IntPoint point(x, y);
    if (!frameView->visibleContentRect().contains(point))
        return HitTestResult();

    HitTestRequest request(HitTestRequest::ReadOnly | HitTestRequest::Active);
    HitTestResult result(point);
    document->renderView()->hitTest(request, result);
    return result;
}

Element* TreeScope::elementFromPoint(int x, int y) const
{
    HitTestResult result = hitTestInDocument(&rootNode().document(), x, y);
    Node* node = result.innerNode();
    if (!node || node->isDocumentNode())
        return 0;
    if (node->isTextNode())
        node = node->parentOrShadowHostNode();
    ASSERT(!node || node->isElementNode() || node->isShadowRoot());
    node = ancestorInThisScope(node);
    if (!node || !node->isElementNode())
        return 0;
    return toElement(node);
}

DOMSelection* TreeScope::getSelection() const
{
    if (!rootNode().document().frame())
        return 0;

    if (m_selection)
        return m_selection.get();

    // FIXME: The correct selection in Shadow DOM requires that Position can have a ShadowRoot
    // as a container.
    // See https://bugs.webkit.org/show_bug.cgi?id=82697
    m_selection = DOMSelection::create(this);
    return m_selection.get();
}

bool TreeScope::applyAuthorStyles() const
{
    return rootNode().isDocumentNode();
}

void TreeScope::adoptIfNeeded(Node& node)
{
    ASSERT(this);
    ASSERT(!node.isDocumentNode());
#if !ENABLE(OILPAN)
    ASSERT_WITH_SECURITY_IMPLICATION(!node.m_deletionHasBegun);
#endif
    TreeScopeAdopter adopter(node, *this);
    if (adopter.needsScopeChange())
        adopter.execute();
}

Element* TreeScope::adjustedFocusedElement() const
{
    Document& document = rootNode().document();
    Element* element = document.focusedElement();
    if (!element)
        return 0;

    EventPath eventPath(element);
    for (size_t i = 0; i < eventPath.size(); ++i) {
        if (eventPath[i].node() == rootNode()) {
            // eventPath.at(i).target() is one of the followings:
            // - InsertionPoint
            // - shadow host
            // - Document::focusedElement()
            // So, it's safe to do toElement().
            return toElement(eventPath[i].target()->toNode());
        }
    }
    return 0;
}

unsigned short TreeScope::comparePosition(const TreeScope& otherScope) const
{
    if (otherScope == this)
        return Node::DOCUMENT_POSITION_EQUIVALENT;

    Vector<const TreeScope*, 16> chain1;
    Vector<const TreeScope*, 16> chain2;
    const TreeScope* current;
    for (current = this; current; current = current->parentTreeScope())
        chain1.append(current);
    for (current = &otherScope; current; current = current->parentTreeScope())
        chain2.append(current);

    unsigned index1 = chain1.size();
    unsigned index2 = chain2.size();
    if (chain1[index1 - 1] != chain2[index2 - 1])
        return Node::DOCUMENT_POSITION_DISCONNECTED | Node::DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC;

    for (unsigned i = std::min(index1, index2); i; --i) {
        const TreeScope* child1 = chain1[--index1];
        const TreeScope* child2 = chain2[--index2];
        if (child1 != child2) {
            Node* shadowHost1 = child1->rootNode().parentOrShadowHostNode();
            Node* shadowHost2 = child2->rootNode().parentOrShadowHostNode();
            if (shadowHost1 != shadowHost2)
                return shadowHost1->compareDocumentPosition(shadowHost2, Node::TreatShadowTreesAsDisconnected);

            return Node::DOCUMENT_POSITION_PRECEDING;
        }
    }

    // There was no difference between the two parent chains, i.e., one was a subset of the other. The shorter
    // chain is the ancestor.
    return index1 < index2 ?
        Node::DOCUMENT_POSITION_FOLLOWING | Node::DOCUMENT_POSITION_CONTAINED_BY :
        Node::DOCUMENT_POSITION_PRECEDING | Node::DOCUMENT_POSITION_CONTAINS;
}

const TreeScope* TreeScope::commonAncestorTreeScope(const TreeScope& other) const
{
    Vector<const TreeScope*, 16> thisChain;
    for (const TreeScope* tree = this; tree; tree = tree->parentTreeScope())
        thisChain.append(tree);

    Vector<const TreeScope*, 16> otherChain;
    for (const TreeScope* tree = &other; tree; tree = tree->parentTreeScope())
        otherChain.append(tree);

    // Keep popping out the last elements of these chains until a mismatched pair is found. If |this| and |other|
    // belong to different documents, null will be returned.
    const TreeScope* lastAncestor = 0;
    while (!thisChain.isEmpty() && !otherChain.isEmpty() && thisChain.last() == otherChain.last()) {
        lastAncestor = thisChain.last();
        thisChain.removeLast();
        otherChain.removeLast();
    }
    return lastAncestor;
}

TreeScope* TreeScope::commonAncestorTreeScope(TreeScope& other)
{
    return const_cast<TreeScope*>(static_cast<const TreeScope&>(*this).commonAncestorTreeScope(other));
}

static void listTreeScopes(Node* node, Vector<TreeScope*, 5>& treeScopes)
{
    while (true) {
        treeScopes.append(&node->treeScope());
        Element* ancestor = node->shadowHost();
        if (!ancestor)
            break;
        node = ancestor;
    }
}

TreeScope* commonTreeScope(Node* nodeA, Node* nodeB)
{
    if (!nodeA || !nodeB)
        return 0;

    if (nodeA->treeScope() == nodeB->treeScope())
        return &nodeA->treeScope();

    Vector<TreeScope*, 5> treeScopesA;
    listTreeScopes(nodeA, treeScopesA);

    Vector<TreeScope*, 5> treeScopesB;
    listTreeScopes(nodeB, treeScopesB);

    size_t indexA = treeScopesA.size();
    size_t indexB = treeScopesB.size();

    for (; indexA > 0 && indexB > 0 && treeScopesA[indexA - 1] == treeScopesB[indexB - 1]; --indexA, --indexB) { }

    return treeScopesA[indexA] == treeScopesB[indexB] ? treeScopesA[indexA] : 0;
}

#if ENABLE(SECURITY_ASSERT) && !ENABLE(OILPAN)
bool TreeScope::deletionHasBegun()
{
    return rootNode().m_deletionHasBegun;
}

void TreeScope::beginDeletion()
{
    rootNode().m_deletionHasBegun = true;
}
#endif

#if !ENABLE(OILPAN)
int TreeScope::refCount() const
{
    return rootNode().refCount();
}
#endif

bool TreeScope::isInclusiveAncestorOf(const TreeScope& scope) const
{
    for (const TreeScope* current = &scope; current; current = current->parentTreeScope()) {
        if (current == this)
            return true;
    }
    return false;
}

Element* TreeScope::getElementByAccessKey(const String& key) const
{
    if (key.isEmpty())
        return 0;
    Element* result = 0;
    Node& root = rootNode();
    for (Element* element = ElementTraversal::firstWithin(root); element; element = ElementTraversal::next(*element, &root)) {
        if (equalIgnoringCase(element->getAttribute(HTMLNames::accesskeyAttr), key))
            result = element;
        if (ShadowRoot* shadowRoot = element->shadowRoot()) {
            if (Element* shadowResult = shadowRoot->getElementByAccessKey(key))
                result = shadowResult;
        }
    }
    return result;
}

void TreeScope::setNeedsStyleRecalcForViewportUnits()
{
    for (Element* element = ElementTraversal::firstWithin(rootNode()); element; element = ElementTraversal::next(*element)) {
        if (ShadowRoot* root = element->shadowRoot())
            root->setNeedsStyleRecalcForViewportUnits();
        RenderStyle* style = element->renderStyle();
        if (style && style->hasViewportUnits())
            element->setNeedsStyleRecalc(LocalStyleChange);
    }
}

bool TreeScope::hasSameStyles(TreeScope& other)
{
    if (this == &other)
        return true;
    const Vector<RefPtr<blink::CSSStyleSheet> >& list = document().styleEngine()->styleSheetsForStyleSheetList(*this);
    const Vector<RefPtr<blink::CSSStyleSheet> >& otherList = document().styleEngine()->styleSheetsForStyleSheetList(other);

    if (list.size() != otherList.size())
        return false;

    for (size_t i = 0; i < list.size(); i++) {
        if (list[i]->contents() != otherList[i]->contents())
            return false;
    }

    return true;
}

} // namespace blink
