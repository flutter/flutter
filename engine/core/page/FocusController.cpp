/*
 * Copyright (C) 2006, 2007 Apple Inc. All rights reserved.
 * Copyright (C) 2008 Nuanti Ltd.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "sky/engine/core/page/FocusController.h"

#include <limits>
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/ElementTraversal.h"
#include "sky/engine/core/dom/NodeTraversal.h"
#include "sky/engine/core/dom/Range.h"
#include "sky/engine/core/dom/shadow/ElementShadow.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/editing/Editor.h"
#include "sky/engine/core/editing/FrameSelection.h"
#include "sky/engine/core/editing/htmlediting.h"
#include "sky/engine/core/events/Event.h"
#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/frame/LocalDOMWindow.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/core/html/HTMLImageElement.h"
#include "sky/engine/core/page/ChromeClient.h"
#include "sky/engine/core/page/EventHandler.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/core/rendering/HitTestResult.h"
#include "sky/engine/core/rendering/RenderLayer.h"

namespace blink {

// FIXME: Some of Node* return values and Node* arguments should be Element*.

FocusNavigationScope::FocusNavigationScope(TreeScope* treeScope)
    : m_rootTreeScope(treeScope)
{
    ASSERT(treeScope);
}

Node* FocusNavigationScope::rootNode() const
{
    return &m_rootTreeScope->rootNode();
}

Element* FocusNavigationScope::owner() const
{
    Node* root = rootNode();
    if (root->isShadowRoot()) {
        ShadowRoot* shadowRoot = toShadowRoot(root);
        return shadowRoot->host();
    }
    return 0;
}

FocusNavigationScope FocusNavigationScope::focusNavigationScopeOf(Node* node)
{
    ASSERT(node);
    Node* root = node;
    for (Node* n = node; n; n = n->parentNode())
        root = n;
    // The result is not always a ShadowRoot nor a DocumentNode since
    // a starting node is in an orphaned tree in composed shadow tree.
    return FocusNavigationScope(&root->treeScope());
}

FocusNavigationScope FocusNavigationScope::ownedByNonFocusableFocusScopeOwner(Node* node)
{
    ASSERT(node);
    return FocusNavigationScope::ownedByShadowHost(node);
}

FocusNavigationScope FocusNavigationScope::ownedByShadowHost(Node* node)
{
    ASSERT(isShadowHost(node));
    return FocusNavigationScope(toElement(node)->shadow()->shadowRoot());
}

static inline void dispatchEventsOnWindowAndFocusedNode(Document* document, bool focused)
{
    // If we have a focused node we should dispatch blur on it before we blur the window.
    // If we have a focused node we should dispatch focus on it after we focus the window.
    // https://bugs.webkit.org/show_bug.cgi?id=27105

    if (!focused && document->focusedElement()) {
        RefPtr<Element> focusedElement(document->focusedElement());
        focusedElement->setFocus(false);
        focusedElement->dispatchBlurEvent(0);
        if (focusedElement == document->focusedElement()) {
            focusedElement->dispatchFocusOutEvent(EventTypeNames::focusout, 0);
            if (focusedElement == document->focusedElement())
                focusedElement->dispatchFocusOutEvent(EventTypeNames::DOMFocusOut, 0);
        }
    }

    if (LocalDOMWindow* window = document->domWindow())
        window->dispatchEvent(Event::create(focused ? EventTypeNames::focus : EventTypeNames::blur));
    if (focused && document->focusedElement()) {
        RefPtr<Element> focusedElement(document->focusedElement());
        focusedElement->setFocus(true);
        focusedElement->dispatchFocusEvent(0, FocusTypePage);
        if (focusedElement == document->focusedElement()) {
            document->focusedElement()->dispatchFocusInEvent(EventTypeNames::focusin, 0);
            if (focusedElement == document->focusedElement())
                document->focusedElement()->dispatchFocusInEvent(EventTypeNames::DOMFocusIn, 0);
        }
    }
}

#if ENABLE(ASSERT)
static inline bool isNonFocusableShadowHost(Node* node)
{
    ASSERT(node);
    if (!node->isElementNode())
        return false;
    Element* element = toElement(node);
    return !element->isFocusable() && isShadowHost(element);
}
#endif

static inline bool isNonKeyboardFocusableShadowHost(Node* node)
{
    ASSERT(node);
    if (!node->isElementNode())
        return false;
    Element* element = toElement(node);
    return !element->isKeyboardFocusable() && isShadowHost(element);
}

static inline bool isKeyboardFocusableShadowHost(Node* node)
{
    ASSERT(node);
    if (!node->isElementNode())
        return false;
    Element* element = toElement(node);
    return element->isKeyboardFocusable() && isShadowHost(element);
}

static inline bool isNonFocusableFocusScopeOwner(Node* node)
{
    ASSERT(node);
    return isNonKeyboardFocusableShadowHost(node);
}

static inline int adjustedTabIndex(Node* node)
{
    ASSERT(node);
    return isNonFocusableFocusScopeOwner(node) ? 0 : node->tabIndex();
}

static inline bool shouldVisit(Node* node)
{
    ASSERT(node);
    return (node->isElementNode() && toElement(node)->isKeyboardFocusable()) || isNonFocusableFocusScopeOwner(node);
}

FocusController::FocusController(Page* page)
    : m_page(page)
    , m_isActive(false)
    , m_isFocused(false)
    , m_isChangingFocusedFrame(false)
{
}

PassOwnPtr<FocusController> FocusController::create(Page* page)
{
    return adoptPtr(new FocusController(page));
}

void FocusController::setFocusedFrame(PassRefPtr<LocalFrame> frame)
{
    ASSERT(!frame || frame->page() == m_page);
    if (m_focusedFrame == frame || m_isChangingFocusedFrame)
        return;

    m_isChangingFocusedFrame = true;

    RefPtr<LocalFrame> oldFrame = m_focusedFrame.get();
    RefPtr<LocalFrame> newFrame = frame.get();

    m_focusedFrame = frame.get();

    // Now that the frame is updated, fire events and update the selection focused states of both frames.
    if (oldFrame && oldFrame->view()) {
        oldFrame->selection().setFocused(false);
        oldFrame->domWindow()->dispatchEvent(Event::create(EventTypeNames::blur));
    }

    if (newFrame && newFrame->view() && isFocused()) {
        newFrame->selection().setFocused(true);
        newFrame->domWindow()->dispatchEvent(Event::create(EventTypeNames::focus));
    }

    m_isChangingFocusedFrame = false;

    m_page->focusedFrameChanged(newFrame.get());
}

void FocusController::focusDocumentView(PassRefPtr<LocalFrame> frame)
{
    ASSERT(!frame || frame->page() == m_page);
    if (m_focusedFrame == frame)
        return;

    RefPtr<LocalFrame> focusedFrame = m_focusedFrame.get();
    if (focusedFrame && focusedFrame->view()) {
        RefPtr<Document> document = focusedFrame->document();
        Element* focusedElement = document ? document->focusedElement() : 0;
        if (focusedElement) {
            focusedElement->dispatchBlurEvent(0);
            if (focusedElement == document->focusedElement()) {
                focusedElement->dispatchFocusOutEvent(EventTypeNames::focusout, 0);
                if (focusedElement == document->focusedElement())
                    focusedElement->dispatchFocusOutEvent(EventTypeNames::DOMFocusOut, 0);
            }
        }
    }

    RefPtr<LocalFrame> newFocusedFrame = frame.get();
    if (newFocusedFrame && newFocusedFrame->view()) {
        RefPtr<Document> document = newFocusedFrame->document();
        Element* focusedElement = document ? document->focusedElement() : 0;
        if (focusedElement) {
            focusedElement->dispatchFocusEvent(0, FocusTypePage);
            if (focusedElement == document->focusedElement()) {
                document->focusedElement()->dispatchFocusInEvent(EventTypeNames::focusin, 0);
                if (focusedElement == document->focusedElement())
                    document->focusedElement()->dispatchFocusInEvent(EventTypeNames::DOMFocusIn, 0);
            }
        }
    }

    setFocusedFrame(frame);
}

LocalFrame* FocusController::focusedOrMainFrame() const
{
    // FIXME(sky): this method makes no sense.
    return m_page->mainFrame();
}

void FocusController::setFocused(bool focused)
{
    if (isFocused() == focused)
        return;

    m_isFocused = focused;

    if (!m_focusedFrame)
        setFocusedFrame(m_page->mainFrame());

    // setFocusedFrame above might reject to update m_focusedFrame, or
    // m_focusedFrame might be changed by blur/focus event handlers.
    if (m_focusedFrame->view()) {
        m_focusedFrame->selection().setFocused(focused);
        dispatchEventsOnWindowAndFocusedNode(m_focusedFrame->document(), focused);
    }
}

Node* FocusController::findFocusableNodeDecendingDownIntoFrameDocument(FocusType type, Node* node)
{
    return 0;
}

bool FocusController::setInitialFocus(FocusType type)
{
    return advanceFocus(type, true);
}

bool FocusController::advanceFocus(FocusType type, bool initialFocus)
{
    switch (type) {
    case FocusTypeForward:
    case FocusTypeBackward:
        return advanceFocusInDocumentOrder(type, initialFocus);
    case FocusTypeLeft:
    case FocusTypeRight:
    case FocusTypeUp:
    case FocusTypeDown:
        // FIXME(sky): Remove directional focus.
        return false;
    default:
        ASSERT_NOT_REACHED();
    }

    return false;
}

bool FocusController::advanceFocusInDocumentOrder(FocusType type, bool initialFocus)
{
    LocalFrame* frame = focusedOrMainFrame();
    ASSERT(frame);
    Document* document = frame->document();

    Node* currentNode = document->focusedElement();

    document->updateLayout();

    RefPtr<Node> node = findFocusableNodeAcrossFocusScope(type, FocusNavigationScope::focusNavigationScopeOf(currentNode ? currentNode : document), currentNode);

    if (!node) {
        // We didn't find a node to focus, so we should try to pass focus to Chrome.
        if (!initialFocus && m_page->canTakeFocus(type)) {
            document->setFocusedElement(nullptr);
            setFocusedFrame(nullptr);
            m_page->takeFocus(type);
            return true;
        }

        // Chrome doesn't want focus, so we should wrap focus.
        node = findFocusableNodeRecursively(type, FocusNavigationScope::focusNavigationScopeOf(m_page->mainFrame()->document()), 0);
        node = findFocusableNodeDecendingDownIntoFrameDocument(type, node.get());

        if (!node)
            return false;
    }

    ASSERT(node);

    if (node == document->focusedElement())
        // Focus wrapped around to the same node.
        return true;

    if (!node->isElementNode())
        // FIXME: May need a way to focus a document here.
        return false;

    Element* element = toElement(node);

    // FIXME: It would be nice to just be able to call setFocusedElement(node)
    // here, but we can't do that because some elements (e.g. HTMLInputElement
    // and HTMLTextAreaElement) do extra work in their focus() methods.
    Document& newDocument = element->document();

    if (&newDocument != document) {
        // Focus is going away from this document, so clear the focused node.
        document->setFocusedElement(nullptr);
    }

    setFocusedFrame(newDocument.frame());

    element->focus(false, type);
    return true;
}

Node* FocusController::findFocusableNodeAcrossFocusScope(FocusType type, FocusNavigationScope scope, Node* currentNode)
{
    ASSERT(!currentNode || !isNonFocusableShadowHost(currentNode));
    Node* found;
    if (currentNode && type == FocusTypeForward && isKeyboardFocusableShadowHost(currentNode)) {
        Node* foundInInnerFocusScope = findFocusableNodeRecursively(type, FocusNavigationScope::ownedByShadowHost(currentNode), 0);
        found = foundInInnerFocusScope ? foundInInnerFocusScope : findFocusableNodeRecursively(type, scope, currentNode);
    } else {
        found = findFocusableNodeRecursively(type, scope, currentNode);
    }

    // If there's no focusable node to advance to, move up the focus scopes until we find one.
    while (!found) {
        Node* owner = scope.owner();
        if (!owner)
            break;
        scope = FocusNavigationScope::focusNavigationScopeOf(owner);
        if (type == FocusTypeBackward && isKeyboardFocusableShadowHost(owner)) {
            found = owner;
            break;
        }
        found = findFocusableNodeRecursively(type, scope, owner);
    }
    found = findFocusableNodeDecendingDownIntoFrameDocument(type, found);
    return found;
}

Node* FocusController::findFocusableNodeRecursively(FocusType type, FocusNavigationScope scope, Node* start)
{
    // Starting node is exclusive.
    Node* found = findFocusableNode(type, scope, start);
    if (!found)
        return 0;
    if (type == FocusTypeForward) {
        if (!isNonFocusableFocusScopeOwner(found))
            return found;
        Node* foundInInnerFocusScope = findFocusableNodeRecursively(type, FocusNavigationScope::ownedByNonFocusableFocusScopeOwner(found), 0);
        return foundInInnerFocusScope ? foundInInnerFocusScope : findFocusableNodeRecursively(type, scope, found);
    }
    ASSERT(type == FocusTypeBackward);
    if (isKeyboardFocusableShadowHost(found)) {
        Node* foundInInnerFocusScope = findFocusableNodeRecursively(type, FocusNavigationScope::ownedByShadowHost(found), 0);
        return foundInInnerFocusScope ? foundInInnerFocusScope : found;
    }
    if (isNonFocusableFocusScopeOwner(found)) {
        Node* foundInInnerFocusScope = findFocusableNodeRecursively(type, FocusNavigationScope::ownedByNonFocusableFocusScopeOwner(found), 0);
        return foundInInnerFocusScope ? foundInInnerFocusScope :findFocusableNodeRecursively(type, scope, found);
    }
    return found;
}

Node* FocusController::findFocusableNode(FocusType type, FocusNavigationScope scope, Node* node)
{
    return type == FocusTypeForward ? nextFocusableNode(scope, node) : previousFocusableNode(scope, node);
}

Node* FocusController::findNodeWithExactTabIndex(Node* start, int tabIndex, FocusType type)
{
    // Search is inclusive of start
    for (Node* node = start; node; node = type == FocusTypeForward ? NodeTraversal::next(*node) : NodeTraversal::previous(*node)) {
        if (shouldVisit(node) && adjustedTabIndex(node) == tabIndex)
            return node;
    }
    return 0;
}

static Node* nextNodeWithGreaterTabIndex(Node* start, int tabIndex)
{
    // Search is inclusive of start
    int winningTabIndex = std::numeric_limits<short>::max() + 1;
    Node* winner = 0;
    for (Node* node = start; node; node = NodeTraversal::next(*node)) {
        if (shouldVisit(node) && node->tabIndex() > tabIndex && node->tabIndex() < winningTabIndex) {
            winner = node;
            winningTabIndex = node->tabIndex();
        }
    }

    return winner;
}

static Node* previousNodeWithLowerTabIndex(Node* start, int tabIndex)
{
    // Search is inclusive of start
    int winningTabIndex = 0;
    Node* winner = 0;
    for (Node* node = start; node; node = NodeTraversal::previous(*node)) {
        int currentTabIndex = adjustedTabIndex(node);
        if ((shouldVisit(node) || isNonKeyboardFocusableShadowHost(node)) && currentTabIndex < tabIndex && currentTabIndex > winningTabIndex) {
            winner = node;
            winningTabIndex = currentTabIndex;
        }
    }
    return winner;
}

Node* FocusController::nextFocusableNode(FocusNavigationScope scope, Node* start)
{
    if (start) {
        int tabIndex = adjustedTabIndex(start);
        // If a node is excluded from the normal tabbing cycle, the next focusable node is determined by tree order
        if (tabIndex < 0) {
            for (Node* node = NodeTraversal::next(*start); node; node = NodeTraversal::next(*node)) {
                if (shouldVisit(node) && adjustedTabIndex(node) >= 0)
                    return node;
            }
        }

        // First try to find a node with the same tabindex as start that comes after start in the scope.
        if (Node* winner = findNodeWithExactTabIndex(NodeTraversal::next(*start), tabIndex, FocusTypeForward))
            return winner;

        if (!tabIndex)
            // We've reached the last node in the document with a tabindex of 0. This is the end of the tabbing order.
            return 0;
    }

    // Look for the first node in the scope that:
    // 1) has the lowest tabindex that is higher than start's tabindex (or 0, if start is null), and
    // 2) comes first in the scope, if there's a tie.
    if (Node* winner = nextNodeWithGreaterTabIndex(scope.rootNode(), start ? adjustedTabIndex(start) : 0))
        return winner;

    // There are no nodes with a tabindex greater than start's tabindex,
    // so find the first node with a tabindex of 0.
    return findNodeWithExactTabIndex(scope.rootNode(), 0, FocusTypeForward);
}

Node* FocusController::previousFocusableNode(FocusNavigationScope scope, Node* start)
{
    Node* last = 0;
    for (Node* node = scope.rootNode(); node; node = node->lastChild())
        last = node;
    ASSERT(last);

    // First try to find the last node in the scope that comes before start and has the same tabindex as start.
    // If start is null, find the last node in the scope with a tabindex of 0.
    Node* startingNode;
    int startingTabIndex;
    if (start) {
        startingNode = NodeTraversal::previous(*start);
        startingTabIndex = adjustedTabIndex(start);
    } else {
        startingNode = last;
        startingTabIndex = 0;
    }

    // However, if a node is excluded from the normal tabbing cycle, the previous focusable node is determined by tree order
    if (startingTabIndex < 0) {
        for (Node* node = startingNode; node; node = NodeTraversal::previous(*node)) {
            if (shouldVisit(node) && adjustedTabIndex(node) >= 0)
                return node;
        }
    }

    if (Node* winner = findNodeWithExactTabIndex(startingNode, startingTabIndex, FocusTypeBackward))
        return winner;

    // There are no nodes before start with the same tabindex as start, so look for a node that:
    // 1) has the highest non-zero tabindex (that is less than start's tabindex), and
    // 2) comes last in the scope, if there's a tie.
    startingTabIndex = (start && startingTabIndex) ? startingTabIndex : std::numeric_limits<short>::max();
    return previousNodeWithLowerTabIndex(last, startingTabIndex);
}

static bool relinquishesEditingFocus(Node *node)
{
    ASSERT(node);
    ASSERT(node->hasEditableStyle());
    return node->document().frame() && node->rootEditableElement();
}

bool FocusController::setFocusedElement(Element* element, PassRefPtr<LocalFrame> newFocusedFrame, FocusType type)
{
    RefPtr<LocalFrame> oldFocusedFrame = focusedFrame();
    RefPtr<Document> oldDocument = oldFocusedFrame ? oldFocusedFrame->document() : 0;

    Element* oldFocusedElement = oldDocument ? oldDocument->focusedElement() : 0;
    if (element && oldFocusedElement == element)
        return true;

    // FIXME: Might want to disable this check for caretBrowsing
    if (oldFocusedElement && oldFocusedElement->isRootEditableElement() && !relinquishesEditingFocus(oldFocusedElement))
        return false;

    RefPtr<Document> newDocument = nullptr;
    if (element)
        newDocument = &element->document();
    else if (newFocusedFrame)
        newDocument = newFocusedFrame->document();

    if (newDocument && oldDocument == newDocument && newDocument->focusedElement() == element)
        return true;

    if (oldDocument && oldDocument != newDocument)
        oldDocument->setFocusedElement(nullptr);

    if (newFocusedFrame && !newFocusedFrame->page()) {
        setFocusedFrame(nullptr);
        return false;
    }
    setFocusedFrame(newFocusedFrame);

    // Setting the focused node can result in losing our last reft to node when JS event handlers fire.
    RefPtr<Element> protect ALLOW_UNUSED = element;
    if (newDocument) {
        bool successfullyFocused = newDocument->setFocusedElement(element, type);
        if (!successfullyFocused)
            return false;
    }

    return true;
}

void FocusController::setActive(bool active)
{
    if (m_isActive == active)
        return;

    m_isActive = active;

    focusedOrMainFrame()->selection().pageActivationChanged();
}

} // namespace blink
