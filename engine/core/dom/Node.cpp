/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2008 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
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

#include "sky/engine/config.h"
#include "sky/engine/core/dom/Node.h"

#include "gen/sky/core/HTMLNames.h"
#include "sky/engine/bindings/core/v8/DOMDataStore.h"
#include "sky/engine/bindings/core/v8/ExceptionState.h"
#include "sky/engine/bindings/core/v8/ScriptCallStackFactory.h"
#include "sky/engine/bindings/core/v8/V8DOMWrapper.h"
#include "sky/engine/core/css/resolver/StyleResolver.h"
#include "sky/engine/core/dom/Attr.h"
#include "sky/engine/core/dom/Attribute.h"
#include "sky/engine/core/dom/ChildListMutationScope.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/DocumentFragment.h"
#include "sky/engine/core/dom/DocumentMarkerController.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/ElementRareData.h"
#include "sky/engine/core/dom/ElementTraversal.h"
#include "sky/engine/core/dom/ExceptionCode.h"
#include "sky/engine/core/dom/NodeRareData.h"
#include "sky/engine/core/dom/NodeRenderingTraversal.h"
#include "sky/engine/core/dom/NodeTraversal.h"
#include "sky/engine/core/dom/Range.h"
#include "sky/engine/core/dom/StaticNodeList.h"
#include "sky/engine/core/dom/TemplateContentDocumentFragment.h"
#include "sky/engine/core/dom/Text.h"
#include "sky/engine/core/dom/TreeScopeAdopter.h"
#include "sky/engine/core/dom/UserActionElementSet.h"
#include "sky/engine/core/dom/WeakNodeMap.h"
#include "sky/engine/core/dom/shadow/ElementShadow.h"
#include "sky/engine/core/dom/shadow/InsertionPoint.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/editing/htmlediting.h"
#include "sky/engine/core/events/Event.h"
#include "sky/engine/core/events/EventDispatchMediator.h"
#include "sky/engine/core/events/EventDispatcher.h"
#include "sky/engine/core/events/EventListener.h"
#include "sky/engine/core/events/GestureEvent.h"
#include "sky/engine/core/events/KeyboardEvent.h"
#include "sky/engine/core/events/MouseEvent.h"
#include "sky/engine/core/events/TextEvent.h"
#include "sky/engine/core/events/TouchEvent.h"
#include "sky/engine/core/events/UIEvent.h"
#include "sky/engine/core/events/WheelEvent.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/core/html/HTMLAnchorElement.h"
#include "sky/engine/core/html/HTMLStyleElement.h"
#include "sky/engine/core/page/EventHandler.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/core/rendering/RenderBox.h"
#include "sky/engine/platform/EventDispatchForbiddenScope.h"
#include "sky/engine/platform/Partitions.h"
#include "sky/engine/platform/TraceEvent.h"
#include "sky/engine/platform/TracedValue.h"
#include "sky/engine/wtf/HashSet.h"
#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/RefCountedLeakCounter.h"
#include "sky/engine/wtf/Vector.h"
#include "sky/engine/wtf/text/CString.h"
#include "sky/engine/wtf/text/StringBuilder.h"

namespace blink {

struct SameSizeAsNode : public EventTarget, public TreeShared<Node> {
    uint32_t m_nodeFlags;
    void* m_pointer[5];
};

COMPILE_ASSERT(sizeof(Node) <= sizeof(SameSizeAsNode), Node_should_stay_small);

#if !ENABLE(OILPAN)
void* Node::operator new(size_t size)
{
    ASSERT(isMainThread());
    return partitionAlloc(Partitions::getObjectModelPartition(), size);
}

void Node::operator delete(void* ptr)
{
    ASSERT(isMainThread());
    partitionFree(ptr);
}
#endif

#if DUMP_NODE_STATISTICS
typedef HashSet<RawPtr<Node> > WeakNodeSet;
static WeakNodeSet& liveNodeSet()
{
    DEFINE_STATIC_LOCAL(OwnPtr<WeakNodeSet>, set, (adoptPtr(new WeakNodeSet())));
    return *set;
}
#endif

void Node::dumpStatistics()
{
#if DUMP_NODE_STATISTICS
    size_t nodesWithRareData = 0;

    size_t elementNodes = 0;
    size_t textNodes = 0;
    size_t piNodes = 0;
    size_t documentNodes = 0;
    size_t docTypeNodes = 0;
    size_t fragmentNodes = 0;
    size_t shadowRootNodes = 0;

    HashMap<String, size_t> perTagCount;

    size_t attributes = 0;
    size_t elementsWithAttributeStorage = 0;
    size_t elementsWithRareData = 0;

    for (WeakNodeSet::iterator it = liveNodeSet().begin(); it != liveNodeSet().end(); ++it) {
        Node* node = *it;

        if (node->hasRareData()) {
            ++nodesWithRareData;
            if (node->isElementNode()) {
                ++elementsWithRareData;
            }
        }

        switch (node->nodeType()) {
            case ELEMENT_NODE: {
                ++elementNodes;

                // Tag stats
                Element* element = toElement(node);
                HashMap<String, size_t>::AddResult result = perTagCount.add(element->tagName(), 1);
                if (!result.isNewEntry)
                    result.storedValue->value++;

                if (const ElementData* elementData = element->elementData()) {
                    attributes += elementData->attributes().size();
                    ++elementsWithAttributeStorage;
                }
                break;
            }
            case TEXT_NODE: {
                ++textNodes;
                break;
            }
            case DOCUMENT_NODE: {
                ++documentNodes;
                break;
            }
            case DOCUMENT_FRAGMENT_NODE: {
                if (node->isShadowRoot())
                    ++shadowRootNodes;
                else
                    ++fragmentNodes;
                break;
            }
        }
    }

    printf("Number of Nodes: %d\n\n", liveNodeSet().size());
    printf("Number of Nodes with RareData: %zu\n\n", nodesWithRareData);

    printf("NodeType distribution:\n");
    printf("  Number of Element nodes: %zu\n", elementNodes);
    printf("  Number of Text nodes: %zu\n", textNodes);
    printf("  Number of Document nodes: %zu\n", documentNodes);
    printf("  Number of DocumentType nodes: %zu\n", docTypeNodes);
    printf("  Number of DocumentFragment nodes: %zu\n", fragmentNodes);
    printf("  Number of ShadowRoot nodes: %zu\n", shadowRootNodes);

    printf("Element tag name distibution:\n");
    for (HashMap<String, size_t>::iterator it = perTagCount.begin(); it != perTagCount.end(); ++it)
        printf("  Number of <%s> tags: %zu\n", it->key.utf8().data(), it->value);

    printf("Attributes:\n");
    printf("  Number of Attributes (non-Node and Node): %zu [%zu]\n", attributes, sizeof(Attribute));
    printf("  Number of Elements with attribute storage: %zu [%zu]\n", elementsWithAttributeStorage, sizeof(ElementData));
    printf("  Number of Elements with RareData: %zu\n", elementsWithRareData);
#endif
}

DEFINE_DEBUG_ONLY_GLOBAL(WTF::RefCountedLeakCounter, nodeCounter, ("WebCoreNode"));

void Node::trackForDebugging()
{
#ifndef NDEBUG
    nodeCounter.increment();
#endif

#if DUMP_NODE_STATISTICS
    liveNodeSet().add(this);
#endif
}

Node::Node(TreeScope* treeScope, ConstructionType type)
    : m_nodeFlags(type)
    , m_parentOrShadowHostNode(nullptr)
    , m_treeScope(treeScope)
    , m_previous(nullptr)
    , m_next(nullptr)
{
    ASSERT(m_treeScope || type == CreateDocument || type == CreateShadowRoot);
#if !ENABLE(OILPAN)
    if (m_treeScope)
        m_treeScope->guardRef();
#endif

#if !defined(NDEBUG) || (defined(DUMP_NODE_STATISTICS) && DUMP_NODE_STATISTICS)
    trackForDebugging();
#endif
    InspectorCounters::incrementCounter(InspectorCounters::NodeCounter);
}

Node::~Node()
{
#ifndef NDEBUG
    nodeCounter.decrement();
#endif

#if !ENABLE(OILPAN)
#if DUMP_NODE_STATISTICS
    liveNodeSet().remove(this);
#endif

    if (hasRareData())
        clearRareData();

    RELEASE_ASSERT(!renderer());

    if (!isContainerNode())
        willBeDeletedFromDocument();

    if (m_previous)
        m_previous->setNextSibling(0);
    if (m_next)
        m_next->setPreviousSibling(0);

    if (m_treeScope)
        m_treeScope->guardDeref();

    if (getFlag(HasWeakReferencesFlag))
        WeakNodeMap::notifyNodeDestroyed(this);
#else
    // With Oilpan, the rare data finalizer also asserts for
    // this condition (we cannot directly access it here.)
    RELEASE_ASSERT(hasRareData() || !renderer());
#endif

    InspectorCounters::decrementCounter(InspectorCounters::NodeCounter);
}

#if !ENABLE(OILPAN)
// With Oilpan all of this is handled with weak processing of the document.
void Node::willBeDeletedFromDocument()
{
    if (!isTreeScopeInitialized())
        return;

    Document& document = this->document();

    if (hasEventTargetData())
        clearEventTargetData();

    document.markers().removeMarkers(this);
}
#endif

NodeRareData* Node::rareData() const
{
    ASSERT_WITH_SECURITY_IMPLICATION(hasRareData());
    return static_cast<NodeRareData*>(m_data.m_rareData);
}

NodeRareData& Node::ensureRareData()
{
    if (hasRareData())
        return *rareData();

    if (isElementNode())
        m_data.m_rareData = ElementRareData::create(m_data.m_renderer);
    else
        m_data.m_rareData = NodeRareData::create(m_data.m_renderer);

    ASSERT(m_data.m_rareData);

    setFlag(HasRareDataFlag);
    return *rareData();
}

void Node::clearRareData()
{
    ASSERT(hasRareData());
    ASSERT(!transientMutationObserverRegistry() || transientMutationObserverRegistry()->isEmpty());

    RenderObject* renderer = m_data.m_rareData->renderer();
    if (isElementNode())
        delete static_cast<ElementRareData*>(m_data.m_rareData);
    else
        delete static_cast<NodeRareData*>(m_data.m_rareData);
    m_data.m_renderer = renderer;
    clearFlag(HasRareDataFlag);
}

Node* Node::toNode()
{
    return this;
}

short Node::tabIndex() const
{
    return 0;
}

PassRefPtr<Node> Node::insertBefore(PassRefPtr<Node> newChild, Node* refChild, ExceptionState& exceptionState)
{
    if (isContainerNode())
        return toContainerNode(this)->insertBefore(newChild, refChild, exceptionState);

    exceptionState.throwDOMException(HierarchyRequestError, "This node type does not support this method.");
    return nullptr;
}

PassRefPtr<Node> Node::replaceChild(PassRefPtr<Node> newChild, PassRefPtr<Node> oldChild, ExceptionState& exceptionState)
{
    if (isContainerNode())
        return toContainerNode(this)->replaceChild(newChild, oldChild, exceptionState);

    exceptionState.throwDOMException(HierarchyRequestError,  "This node type does not support this method.");
    return nullptr;
}

PassRefPtr<Node> Node::removeChild(PassRefPtr<Node> oldChild, ExceptionState& exceptionState)
{
    if (isContainerNode())
        return toContainerNode(this)->removeChild(oldChild, exceptionState);

    exceptionState.throwDOMException(NotFoundError, "This node type does not support this method.");
    return nullptr;
}

PassRefPtr<Node> Node::appendChild(PassRefPtr<Node> newChild, ExceptionState& exceptionState)
{
    if (isContainerNode())
        return toContainerNode(this)->appendChild(newChild, exceptionState);

    exceptionState.throwDOMException(HierarchyRequestError, "This node type does not support this method.");
    return nullptr;
}

void Node::remove(ExceptionState& exceptionState)
{
    if (ContainerNode* parent = parentNode())
        parent->removeChild(this, exceptionState);
}

const AtomicString& Node::localName() const
{
    return nullAtom;
}

bool Node::isContentEditable(UserSelectAllTreatment treatment)
{
    document().updateRenderTreeIfNeeded();
    return hasEditableStyle(Editable, treatment);
}

bool Node::isContentRichlyEditable()
{
    document().updateRenderTreeIfNeeded();
    return hasEditableStyle(RichlyEditable, UserSelectAllIsAlwaysNonEditable);
}

bool Node::hasEditableStyle(EditableLevel editableLevel, UserSelectAllTreatment treatment) const
{
    // Ideally we'd call ASSERT(!needsStyleRecalc()) here, but
    // ContainerNode::setFocus() calls setNeedsStyleRecalc(), so the assertion
    // would fire in the middle of Document::setFocusedNode().

    for (const Node* node = this; node; node = node->parentNode()) {
        if (node->isHTMLElement() && node->renderer()) {
            // Elements with user-select: all style are considered atomic
            // therefore non editable.
            if (Position::nodeIsUserSelectAll(node) && treatment == UserSelectAllIsAlwaysNonEditable)
                return false;
            if (static_cast<const Element*>(node)->hasAttribute(HTMLNames::contenteditableAttr))
                return editableLevel != RichlyEditable;
            return false;
        }
    }

    return false;
}

bool Node::isEditableToAccessibility(EditableLevel editableLevel) const
{
    return hasEditableStyle(editableLevel);
}

RenderBox* Node::renderBox() const
{
    RenderObject* renderer = this->renderer();
    return renderer && renderer->isBox() ? toRenderBox(renderer) : 0;
}

RenderBoxModelObject* Node::renderBoxModelObject() const
{
    RenderObject* renderer = this->renderer();
    return renderer && renderer->isBoxModelObject() ? toRenderBoxModelObject(renderer) : 0;
}

LayoutRect Node::boundingBox() const
{
    if (renderer())
        return renderer()->absoluteBoundingBoxRect();
    return LayoutRect();
}

bool Node::hasNonEmptyBoundingBox() const
{
    // Before calling absoluteRects, check for the common case where the renderer
    // is non-empty, since this is a faster check and almost always returns true.
    RenderBoxModelObject* box = renderBoxModelObject();
    if (!box)
        return false;
    if (!box->borderBoundingBox().isEmpty())
        return true;

    Vector<IntRect> rects;
    FloatPoint absPos = renderer()->localToAbsolute();
    renderer()->absoluteRects(rects, flooredLayoutPoint(absPos));
    size_t n = rects.size();
    for (size_t i = 0; i < n; ++i)
        if (!rects[i].isEmpty())
            return true;

    return false;
}

void Node::recalcDistribution()
{
    if (isElementNode()) {
        if (ElementShadow* shadow = toElement(this)->shadow())
            shadow->distributeIfNeeded();
    }

    for (Node* child = firstChild(); child; child = child->nextSibling()) {
        if (child->childNeedsDistributionRecalc())
            child->recalcDistribution();
    }

    if (ShadowRoot* root = shadowRoot()) {
        if (root->childNeedsDistributionRecalc())
            root->recalcDistribution();
    }

    clearChildNeedsDistributionRecalc();
}

void Node::setIsLink(bool isLink)
{
    setFlag(isLink, IsLinkFlag);
}

void Node::markAncestorsWithChildNeedsDistributionRecalc()
{
    for (Node* node = this; node && !node->childNeedsDistributionRecalc(); node = node->parentOrShadowHostNode())
        node->setChildNeedsDistributionRecalc();
    document().scheduleRenderTreeUpdateIfNeeded();
}

namespace {

void addJsStack(TracedValue* stackFrames)
{
    RefPtr<ScriptCallStack> stack = createScriptCallStack(10);
    if (!stack)
        return;
    for (size_t i = 0; i < stack->size(); i++)
        stackFrames->pushString(stack->at(i).functionName());
}

PassRefPtr<TraceEvent::ConvertableToTraceFormat> jsonObjectForStyleInvalidation(unsigned nodeCount, const Node* rootNode)
{
    RefPtr<TracedValue> value = TracedValue::create();
    value->setInteger("node_count", nodeCount);
    value->setString("root_node", rootNode->debugName());
    value->beginArray("js_stack");
    addJsStack(value.get());
    value->endArray();
    return value;
}

} // anonymous namespace'd functions supporting traceStyleChange

unsigned Node::styledSubtreeSize() const
{
    unsigned nodeCount = 0;

    for (const Node* node = this; node; node = NodeTraversal::next(*node, this)) {
        if (node->isTextNode() || node->isElementNode())
            nodeCount++;
        if (ShadowRoot* root = node->shadowRoot())
            nodeCount += root->styledSubtreeSize();
    }

    return nodeCount;
}

void Node::traceStyleChange(StyleChangeType changeType)
{
    static const unsigned kMinLoggedSize = 100;
    unsigned nodeCount = styledSubtreeSize();
    if (nodeCount < kMinLoggedSize)
        return;

    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("style.debug"),
        "Node::setNeedsStyleRecalc", TRACE_EVENT_SCOPE_PROCESS,
        "data", jsonObjectForStyleInvalidation(nodeCount, this)
    );
}

void Node::traceStyleChangeIfNeeded(StyleChangeType changeType)
{
    // TRACE_EVENT_CATEGORY_GROUP_ENABLED macro loads a global static bool into our local bool.
    bool styleTracingEnabled;
    TRACE_EVENT_CATEGORY_GROUP_ENABLED(TRACE_DISABLED_BY_DEFAULT("style.debug"), &styleTracingEnabled);
    if (UNLIKELY(styleTracingEnabled))
        traceStyleChange(changeType);
}

inline void Node::setStyleChange(StyleChangeType changeType)
{
    m_nodeFlags = (m_nodeFlags & ~StyleChangeMask) | changeType;
}

void Node::markAncestorsWithChildNeedsStyleRecalc()
{
    for (ContainerNode* p = parentOrShadowHostNode(); p && !p->childNeedsStyleRecalc(); p = p->parentOrShadowHostNode())
        p->setChildNeedsStyleRecalc();
    document().scheduleRenderTreeUpdateIfNeeded();
}

void Node::setNeedsStyleRecalc(StyleChangeType changeType)
{
    ASSERT(changeType != NoStyleChange);
    if (!inActiveDocument())
        return;

    StyleChangeType existingChangeType = styleChangeType();
    if (changeType > existingChangeType) {
        setStyleChange(changeType);
        if (changeType >= SubtreeStyleChange)
            traceStyleChangeIfNeeded(changeType);
    }

    if (existingChangeType == NoStyleChange)
        markAncestorsWithChildNeedsStyleRecalc();

    if (isElementNode() && hasRareData())
        toElement(*this).setAnimationStyleChange(false);
}

void Node::clearNeedsStyleRecalc()
{
    m_nodeFlags &= ~StyleChangeMask;

    if (isElementNode() && hasRareData())
        toElement(*this).setAnimationStyleChange(false);
}

bool Node::inActiveDocument() const
{
    return inDocument() && document().isActive();
}

unsigned Node::nodeIndex() const
{
    Node *_tempNode = previousSibling();
    unsigned count=0;
    for ( count=0; _tempNode; count++ )
        _tempNode = _tempNode->previousSibling();
    return count;
}

bool Node::isDescendantOf(const Node *other) const
{
    // Return true if other is an ancestor of this, otherwise false
    if (!other || !other->hasChildren() || inDocument() != other->inDocument())
        return false;
    if (other->treeScope() != treeScope())
        return false;
    if (other->isTreeScope())
        return !isTreeScope();
    for (const ContainerNode* n = parentNode(); n; n = n->parentNode()) {
        if (n == other)
            return true;
    }
    return false;
}

bool Node::contains(const Node* node) const
{
    if (!node)
        return false;
    return this == node || node->isDescendantOf(this);
}

bool Node::containsIncludingShadowDOM(const Node* node) const
{
    if (!node)
        return false;

    if (this == node)
        return true;

    if (document() != node->document())
        return false;

    if (inDocument() != node->inDocument())
        return false;

    bool hasChildren = isContainerNode() && toContainerNode(this)->hasChildren();
    bool hasShadow = isElementNode() && toElement(this)->shadow();
    if (!hasChildren && !hasShadow)
        return false;

    for (; node; node = node->shadowHost()) {
        if (treeScope() == node->treeScope())
            return contains(node);
    }

    return false;
}

bool Node::containsIncludingHostElements(const Node& node) const
{
    const Node* current = &node;
    do {
        if (current == this)
            return true;
        if (current->isDocumentFragment() && toDocumentFragment(current)->isTemplateContent())
            current = static_cast<const TemplateContentDocumentFragment*>(current)->host();
        else
            current = current->parentOrShadowHostNode();
    } while (current);
    return false;
}

void Node::reattach(const AttachContext& context)
{
    AttachContext reattachContext(context);
    reattachContext.performingReattach = true;

    // We only need to detach if the node has already been through attach().
    if (styleChangeType() < NeedsReattachStyleChange)
        detach(reattachContext);
    attach(reattachContext);
}

void Node::attach(const AttachContext&)
{
    ASSERT(document().inStyleRecalc() || isDocumentNode());
    ASSERT(needsAttach());
    ASSERT(!renderer() || (renderer()->style() && (renderer()->parent() || renderer()->isRenderView())));

    clearNeedsStyleRecalc();
}

void Node::detach(const AttachContext& context)
{
    ASSERT(document().lifecycle().stateAllowsDetach());
    DocumentLifecycle::DetachScope willDetach(document().lifecycle());

    if (renderer())
        renderer()->destroyAndCleanupAnonymousWrappers();
    setRenderer(0);

    // Do not remove the element's hovered and active status
    // if performing a reattach.
    if (!context.performingReattach) {
        Document& doc = document();
        if (isUserActionElement()) {
            if (hovered())
                doc.hoveredNodeDetached(this);
            if (inActiveChain())
                doc.activeChainNodeDetached(this);
            doc.userActionElements().didDetach(this);
        }
    }

    setStyleChange(NeedsReattachStyleChange);
    setChildNeedsStyleRecalc();
}

void Node::reattachWhitespaceSiblings(Text* start)
{
    for (Node* sibling = start; sibling; sibling = sibling->nextSibling()) {
        if (sibling->isTextNode() && toText(sibling)->containsOnlyWhitespace()) {
            bool hadRenderer = !!sibling->renderer();
            sibling->reattach();
            // If the reattach didn't toggle the visibility of the whitespace we don't
            // need to continue reattaching siblings since they won't toggle visibility
            // either.
            if (hadRenderer == !!sibling->renderer())
                return;
        } else if (sibling->renderer()) {
            return;
        }
    }
}

// FIXME: This code is used by editing.  Seems like it could move over there and not pollute Node.
Node *Node::previousNodeConsideringAtomicNodes() const
{
    if (previousSibling()) {
        Node *n = previousSibling();
        while (!isAtomicNode(n) && n->lastChild())
            n = n->lastChild();
        return n;
    }
    else if (parentNode()) {
        return parentNode();
    }
    else {
        return 0;
    }
}

Node *Node::nextNodeConsideringAtomicNodes() const
{
    if (!isAtomicNode(this) && hasChildren())
        return firstChild();
    if (nextSibling())
        return nextSibling();
    const Node *n = this;
    while (n && !n->nextSibling())
        n = n->parentNode();
    if (n)
        return n->nextSibling();
    return 0;
}

Node *Node::previousLeafNode() const
{
    Node *node = previousNodeConsideringAtomicNodes();
    while (node) {
        if (isAtomicNode(node))
            return node;
        node = node->previousNodeConsideringAtomicNodes();
    }
    return 0;
}

Node *Node::nextLeafNode() const
{
    Node *node = nextNodeConsideringAtomicNodes();
    while (node) {
        if (isAtomicNode(node))
            return node;
        node = node->nextNodeConsideringAtomicNodes();
    }
    return 0;
}

RenderStyle* Node::virtualComputedStyle(PseudoId pseudoElementSpecifier)
{
    return parentOrShadowHostNode() ? parentOrShadowHostNode()->computedStyle(pseudoElementSpecifier) : 0;
}

int Node::maxCharacterOffset() const
{
    ASSERT_NOT_REACHED();
    return 0;
}

// FIXME: Shouldn't these functions be in the editing code?  Code that asks questions about HTML in the core DOM class
// is obviously misplaced.
bool Node::canStartSelection() const
{
    if (hasEditableStyle())
        return true;

    if (renderer()) {
        RenderStyle* style = renderer()->style();
        // We allow selections to begin within an element that has -webkit-user-select: none set,
        // but if the element is draggable then dragging should take priority over selection.
        if (style->userDrag() == DRAG_ELEMENT && style->userSelect() == SELECT_NONE)
            return false;
    }
    return parentOrShadowHostNode() ? parentOrShadowHostNode()->canStartSelection() : true;
}

Element* Node::shadowHost() const
{
    if (ShadowRoot* root = containingShadowRoot())
        return root->host();
    return 0;
}

ShadowRoot* Node::containingShadowRoot() const
{
    Node& root = treeScope().rootNode();
    return root.isShadowRoot() ? toShadowRoot(&root) : 0;
}

Node* Node::nonBoundaryShadowTreeRootNode()
{
    ASSERT(!isShadowRoot());
    Node* root = this;
    while (root) {
        if (root->isShadowRoot())
            return root;
        Node* parent = root->parentOrShadowHostNode();
        if (parent && parent->isShadowRoot())
            return root;
        root = parent;
    }
    return 0;
}

ContainerNode* Node::nonShadowBoundaryParentNode() const
{
    ContainerNode* parent = parentNode();
    return parent && !parent->isShadowRoot() ? parent : 0;
}

Element* Node::parentOrShadowHostElement() const
{
    ContainerNode* parent = parentOrShadowHostNode();
    if (!parent)
        return 0;

    if (parent->isShadowRoot())
        return toShadowRoot(parent)->host();

    if (!parent->isElementNode())
        return 0;

    return toElement(parent);
}

ContainerNode* Node::parentOrShadowHostOrTemplateHostNode() const
{
    if (isDocumentFragment() && toDocumentFragment(this)->isTemplateContent())
        return static_cast<const TemplateContentDocumentFragment*>(this)->host();
    return parentOrShadowHostNode();
}

bool Node::isRootEditableElement() const
{
    return hasEditableStyle() && isElementNode() && (!parentNode() || !parentNode()->hasEditableStyle()
        || !parentNode()->isElementNode());
}

Element* Node::rootEditableElement(EditableType editableType) const
{
    return rootEditableElement();
}

Element* Node::rootEditableElement() const
{
    Element* result = 0;
    for (Node* n = const_cast<Node*>(this); n && n->hasEditableStyle(); n = n->parentNode()) {
        if (n->isElementNode())
            result = toElement(n);
    }
    return result;
}

// FIXME: End of obviously misplaced HTML editing functions.  Try to move these out of Node.

Document* Node::ownerDocument() const
{
    Document* doc = &document();
    return doc == this ? 0 : doc;
}

static void appendTextContent(const Node* node, bool convertBRsToNewlines, StringBuilder& content)
{
    if (node->nodeType() == Node::TEXT_NODE) {
        content.append(toCharacterData(node)->data());
        return;
    }

    for (Node* child = toContainerNode(node)->firstChild(); child; child = child->nextSibling()) {
        appendTextContent(child, convertBRsToNewlines, content);
    }
}

String Node::textContent(bool convertBRsToNewlines) const
{
    StringBuilder content;
    appendTextContent(this, convertBRsToNewlines, content);
    return content.toString();
}

void Node::setTextContent(const String& text)
{
    switch (nodeType()) {
        case TEXT_NODE:
            toText(this)->setData(text);
            return;
        case ELEMENT_NODE:
        case DOCUMENT_FRAGMENT_NODE: {
            // FIXME: Merge this logic into replaceChildrenWithText.
            RefPtr<ContainerNode> container = toContainerNode(this);

            // Note: This is an intentional optimization.
            // See crbug.com/352836 also.
            // No need to do anything if the text is identical.
            if (container->hasOneTextChild() && toText(container->firstChild())->data() == text)
                return;

            ChildListMutationScope mutation(*this);
            container->removeChildren();
            // Note: This API will not insert empty text nodes:
            // http://dom.spec.whatwg.org/#dom-node-textcontent
            if (!text.isEmpty())
                container->appendChild(document().createTextNode(text), ASSERT_NO_EXCEPTION);
            return;
        }
        case DOCUMENT_NODE:
            // FIXME(sky): When we get rid of the Document being special, go down the ELEMENT_NODE codepath.
            // Do nothing.
            return;
    }
}

bool Node::offsetInCharacters() const
{
    return false;
}

unsigned short Node::compareDocumentPosition(const Node* otherNode, ShadowTreesTreatment treatment) const
{
    // It is not clear what should be done if |otherNode| is 0.
    if (!otherNode)
        return DOCUMENT_POSITION_DISCONNECTED;

    if (otherNode == this)
        return DOCUMENT_POSITION_EQUIVALENT;

    const Node* start1 = this;
    const Node* start2 = otherNode;

    // If either of start1 or start2 is null, then we are disconnected, since one of the nodes is
    // an orphaned attribute node.
    if (!start1 || !start2) {
        unsigned short direction = (this > otherNode) ? DOCUMENT_POSITION_PRECEDING : DOCUMENT_POSITION_FOLLOWING;
        return DOCUMENT_POSITION_DISCONNECTED | DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC | direction;
    }

    Vector<const Node*, 16> chain1;
    Vector<const Node*, 16> chain2;

    // If one node is in the document and the other is not, we must be disconnected.
    // If the nodes have different owning documents, they must be disconnected.  Note that we avoid
    // comparing Attr nodes here, since they return false from inDocument() all the time (which seems like a bug).
    if (start1->inDocument() != start2->inDocument() || (treatment == TreatShadowTreesAsDisconnected && start1->treeScope() != start2->treeScope())) {
        unsigned short direction = (this > otherNode) ? DOCUMENT_POSITION_PRECEDING : DOCUMENT_POSITION_FOLLOWING;
        return DOCUMENT_POSITION_DISCONNECTED | DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC | direction;
    }

    // We need to find a common ancestor container, and then compare the indices of the two immediate children.
    const Node* current;
    for (current = start1; current; current = current->parentOrShadowHostNode())
        chain1.append(current);
    for (current = start2; current; current = current->parentOrShadowHostNode())
        chain2.append(current);

    unsigned index1 = chain1.size();
    unsigned index2 = chain2.size();

    // If the two elements don't have a common root, they're not in the same tree.
    if (chain1[index1 - 1] != chain2[index2 - 1]) {
        unsigned short direction = (this > otherNode) ? DOCUMENT_POSITION_PRECEDING : DOCUMENT_POSITION_FOLLOWING;
        return DOCUMENT_POSITION_DISCONNECTED | DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC | direction;
    }

    unsigned connection = start1->treeScope() != start2->treeScope() ? DOCUMENT_POSITION_DISCONNECTED | DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC : 0;

    // Walk the two chains backwards and look for the first difference.
    for (unsigned i = std::min(index1, index2); i; --i) {
        const Node* child1 = chain1[--index1];
        const Node* child2 = chain2[--index2];
        if (child1 != child2) {
            // If one of the children is a shadow root,
            if (child1->isShadowRoot() || child2->isShadowRoot()) {
                if (!child2->isShadowRoot())
                    return Node::DOCUMENT_POSITION_FOLLOWING | connection;
                if (!child1->isShadowRoot())
                    return Node::DOCUMENT_POSITION_PRECEDING | connection;

                return Node::DOCUMENT_POSITION_PRECEDING | connection;
            }

            if (!child2->nextSibling())
                return DOCUMENT_POSITION_FOLLOWING | connection;
            if (!child1->nextSibling())
                return DOCUMENT_POSITION_PRECEDING | connection;

            // Otherwise we need to see which node occurs first.  Crawl backwards from child2 looking for child1.
            for (Node* child = child2->previousSibling(); child; child = child->previousSibling()) {
                if (child == child1)
                    return DOCUMENT_POSITION_FOLLOWING | connection;
            }
            return DOCUMENT_POSITION_PRECEDING | connection;
        }
    }

    // There was no difference between the two parent chains, i.e., one was a subset of the other.  The shorter
    // chain is the ancestor.
    return index1 < index2 ?
               DOCUMENT_POSITION_FOLLOWING | DOCUMENT_POSITION_CONTAINED_BY | connection :
               DOCUMENT_POSITION_PRECEDING | DOCUMENT_POSITION_CONTAINS | connection;
}

String Node::debugName() const
{
    StringBuilder name;
    name.append(nodeName());

    if (isElementNode()) {
        const Element& thisElement = toElement(*this);
        if (thisElement.hasID()) {
            name.appendLiteral(" id=\'");
            name.append(thisElement.getIdAttribute());
            name.append('\'');
        }

        if (thisElement.hasClass()) {
            name.appendLiteral(" class=\'");
            for (size_t i = 0; i < thisElement.classNames().size(); ++i) {
                if (i > 0)
                    name.append(' ');
                name.append(thisElement.classNames()[i]);
            }
            name.append('\'');
        }
    }

    return name.toString();
}

#ifndef NDEBUG

static void appendAttributeDesc(const Node* node, StringBuilder& stringBuilder, const QualifiedName& name, const char* attrDesc)
{
    if (!node->isElementNode())
        return;

    String attr = toElement(node)->getAttribute(name);
    if (attr.isEmpty())
        return;

    stringBuilder.append(attrDesc);
    stringBuilder.appendLiteral("=\"");
    stringBuilder.append(attr);
    stringBuilder.appendLiteral("\"");
}

void Node::showNode(const char* prefix) const
{
    if (!prefix)
        prefix = "";
    if (isTextNode()) {
        String value = toText(this)->data();
        value.replaceWithLiteral('\\', "\\\\");
        value.replaceWithLiteral('\n', "\\n");
        fprintf(stderr, "%s%s\t%p \"%s\"\n", prefix, nodeName().utf8().data(), this, value.utf8().data());
    } else {
        StringBuilder attrs;
        appendAttributeDesc(this, attrs, HTMLNames::idAttr, " ID");
        appendAttributeDesc(this, attrs, HTMLNames::classAttr, " CLASS");
        appendAttributeDesc(this, attrs, HTMLNames::styleAttr, " STYLE");
        fprintf(stderr, "%s%s\t%p%s\n", prefix, nodeName().utf8().data(), this, attrs.toString().utf8().data());
    }
}

void Node::showTreeForThis() const
{
    showTreeAndMark(this, "*");
}

void Node::showNodePathForThis() const
{
    Vector<const Node*, 16> chain;
    const Node* node = this;
    while (node->parentOrShadowHostNode()) {
        chain.append(node);
        node = node->parentOrShadowHostNode();
    }
    for (unsigned index = chain.size(); index > 0; --index) {
        const Node* node = chain[index - 1];
        if (node->isShadowRoot()) {
            fprintf(stderr, "/#shadow-root");
            continue;
        }

        switch (node->nodeType()) {
        case ELEMENT_NODE: {
            fprintf(stderr, "/%s", node->nodeName().utf8().data());

            const Element* element = toElement(node);
            const AtomicString& idattr = element->getIdAttribute();
            bool hasIdAttr = !idattr.isNull() && !idattr.isEmpty();
            if (node->previousSibling() || node->nextSibling()) {
                int count = 0;
                for (Node* previous = node->previousSibling(); previous; previous = previous->previousSibling())
                    if (previous->nodeName() == node->nodeName())
                        ++count;
                if (hasIdAttr)
                    fprintf(stderr, "[@id=\"%s\" and position()=%d]", idattr.utf8().data(), count);
                else
                    fprintf(stderr, "[%d]", count);
            } else if (hasIdAttr) {
                fprintf(stderr, "[@id=\"%s\"]", idattr.utf8().data());
            }
            break;
        }
        case TEXT_NODE:
            fprintf(stderr, "/text()");
            break;
        default:
            break;
        }
    }
    fprintf(stderr, "\n");
}

static void traverseTreeAndMark(const String& baseIndent, const Node* rootNode, const Node* markedNode1, const char* markedLabel1, const Node* markedNode2, const char* markedLabel2)
{
    for (const Node* node = rootNode; node; node = NodeTraversal::next(*node)) {
        if (node == markedNode1)
            fprintf(stderr, "%s", markedLabel1);
        if (node == markedNode2)
            fprintf(stderr, "%s", markedLabel2);

        StringBuilder indent;
        indent.append(baseIndent);
        for (const Node* tmpNode = node; tmpNode && tmpNode != rootNode; tmpNode = tmpNode->parentOrShadowHostNode())
            indent.append('\t');
        fprintf(stderr, "%s", indent.toString().utf8().data());
        node->showNode();
        indent.append('\t');
        if (ShadowRoot* shadowRoot = node->shadowRoot())
            traverseTreeAndMark(indent.toString(), shadowRoot, markedNode1, markedLabel1, markedNode2, markedLabel2);
    }
}

void Node::showTreeAndMark(const Node* markedNode1, const char* markedLabel1, const Node* markedNode2, const char* markedLabel2) const
{
    const Node* rootNode;
    const Node* node = this;
    while (node->parentOrShadowHostNode())
        node = node->parentOrShadowHostNode();
    rootNode = node;

    String startingIndent;
    traverseTreeAndMark(startingIndent, rootNode, markedNode1, markedLabel1, markedNode2, markedLabel2);
}

void Node::formatForDebugger(char* buffer, unsigned length) const
{
    String result;
    String s;

    s = nodeName();
    if (s.isEmpty())
        result = "<none>";
    else
        result = s;

    strncpy(buffer, result.utf8().data(), length - 1);
}

static void showSubTreeAcrossFrame(const Node* node, const Node* markedNode, const String& indent)
{
    if (node == markedNode)
        fputs("*", stderr);
    fputs(indent.utf8().data(), stderr);
    node->showNode();
    if (ShadowRoot* shadowRoot = node->shadowRoot())
        showSubTreeAcrossFrame(shadowRoot, markedNode, indent + "\t");
    for (Node* child = node->firstChild(); child; child = child->nextSibling())
        showSubTreeAcrossFrame(child, markedNode, indent + "\t");
}

#endif

// --------

Element* Node::enclosingLinkEventParentOrSelf()
{
    for (Node* node = this; node; node = NodeRenderingTraversal::parent(node)) {
        // For imagemaps, the enclosing link node is the associated area element not the image itself.
        // So we don't let images be the enclosingLinkNode, even though isLink sometimes returns true
        // for them.
        if (node->isLink() && !isHTMLImageElement(*node)) {
            // Casting to Element is safe because only HTMLAnchorElement, HTMLImageElement and
            // SVGAElement can return true for isLink().
            return toElement(node);
        }
    }

    return 0;
}

const AtomicString& Node::interfaceName() const
{
    return EventTargetNames::Node;
}

ExecutionContext* Node::executionContext() const
{
    return document().contextDocument().get();
}

void Node::didMoveToNewDocument(Document& oldDocument)
{
    TreeScopeAdopter::ensureDidMoveToNewDocumentWasCalled(oldDocument);

    if (const EventTargetData* eventTargetData = this->eventTargetData()) {
        const EventListenerMap& listenerMap = eventTargetData->eventListenerMap;
        if (!listenerMap.isEmpty()) {
            Vector<AtomicString> types = listenerMap.eventTypes();
            for (unsigned i = 0; i < types.size(); ++i)
                document().addListenerTypeIfNeeded(types[i]);
        }
    }

    oldDocument.markers().removeMarkers(this);
    oldDocument.updateRangesAfterNodeMovedToAnotherDocument(*this);

    if (Vector<OwnPtr<MutationObserverRegistration> >* registry = mutationObserverRegistry()) {
        for (size_t i = 0; i < registry->size(); ++i) {
            document().addMutationObserverTypes(registry->at(i)->mutationTypes());
        }
    }

    if (HashSet<RawPtr<MutationObserverRegistration> >* transientRegistry = transientMutationObserverRegistry()) {
        for (HashSet<RawPtr<MutationObserverRegistration> >::iterator iter = transientRegistry->begin(); iter != transientRegistry->end(); ++iter) {
            document().addMutationObserverTypes((*iter)->mutationTypes());
        }
    }
}

bool Node::addEventListener(const AtomicString& eventType, PassRefPtr<EventListener> listener, bool useCapture)
{
    if (!EventTarget::addEventListener(eventType, listener, useCapture))
        return false;

    document().addListenerTypeIfNeeded(eventType);

    return true;
}

void Node::removeAllEventListenersRecursively()
{
    for (Node* node = this; node; node = NodeTraversal::next(*node)) {
        node->removeAllEventListeners();
        if (ShadowRoot* root = node->shadowRoot())
            root->removeAllEventListenersRecursively();
    }
}

typedef HashMap<RawPtr<Node>, OwnPtr<EventTargetData> > EventTargetDataMap;

static EventTargetDataMap& eventTargetDataMap()
{
    DEFINE_STATIC_LOCAL(OwnPtr<EventTargetDataMap>, map, (adoptPtr(new EventTargetDataMap())));
    return *map;
}

EventTargetData* Node::eventTargetData()
{
    return hasEventTargetData() ? eventTargetDataMap().get(this) : 0;
}

EventTargetData& Node::ensureEventTargetData()
{
    if (hasEventTargetData())
        return *eventTargetDataMap().get(this);
    setHasEventTargetData(true);
    EventTargetData* data = new EventTargetData;
    eventTargetDataMap().set(this, adoptPtr(data));
    return *data;
}

void Node::clearEventTargetData()
{
    eventTargetDataMap().remove(this);
}

Vector<OwnPtr<MutationObserverRegistration> >* Node::mutationObserverRegistry()
{
    if (!hasRareData())
        return 0;
    NodeMutationObserverData* data = rareData()->mutationObserverData();
    if (!data)
        return 0;
    return &data->registry;
}

HashSet<RawPtr<MutationObserverRegistration> >* Node::transientMutationObserverRegistry()
{
    if (!hasRareData())
        return 0;
    NodeMutationObserverData* data = rareData()->mutationObserverData();
    if (!data)
        return 0;
    return &data->transientRegistry;
}

template<typename Registry>
static inline void collectMatchingObserversForMutation(HashMap<RawPtr<MutationObserver>, MutationRecordDeliveryOptions>& observers, Registry* registry, Node& target, MutationObserver::MutationType type, const QualifiedName* attributeName)
{
    if (!registry)
        return;
    for (typename Registry::iterator iter = registry->begin(); iter != registry->end(); ++iter) {
        const MutationObserverRegistration& registration = **iter;
        if (registration.shouldReceiveMutationFrom(target, type, attributeName)) {
            MutationRecordDeliveryOptions deliveryOptions = registration.deliveryOptions();
            HashMap<RawPtr<MutationObserver>, MutationRecordDeliveryOptions>::AddResult result = observers.add(&registration.observer(), deliveryOptions);
            if (!result.isNewEntry)
                result.storedValue->value |= deliveryOptions;
        }
    }
}

void Node::getRegisteredMutationObserversOfType(HashMap<RawPtr<MutationObserver>, MutationRecordDeliveryOptions>& observers, MutationObserver::MutationType type, const QualifiedName* attributeName)
{
    ASSERT((type == MutationObserver::Attributes && attributeName) || !attributeName);
    collectMatchingObserversForMutation(observers, mutationObserverRegistry(), *this, type, attributeName);
    collectMatchingObserversForMutation(observers, transientMutationObserverRegistry(), *this, type, attributeName);
    for (Node* node = parentNode(); node; node = node->parentNode()) {
        collectMatchingObserversForMutation(observers, node->mutationObserverRegistry(), *this, type, attributeName);
        collectMatchingObserversForMutation(observers, node->transientMutationObserverRegistry(), *this, type, attributeName);
    }
}

void Node::registerMutationObserver(MutationObserver& observer, MutationObserverOptions options, const HashSet<AtomicString>& attributeFilter)
{
    MutationObserverRegistration* registration = 0;
    Vector<OwnPtr<MutationObserverRegistration> >& registry = ensureRareData().ensureMutationObserverData().registry;
    for (size_t i = 0; i < registry.size(); ++i) {
        if (&registry[i]->observer() == &observer) {
            registration = registry[i].get();
            registration->resetObservation(options, attributeFilter);
        }
    }

    if (!registration) {
        registry.append(MutationObserverRegistration::create(observer, this, options, attributeFilter));
        registration = registry.last().get();
    }

    document().addMutationObserverTypes(registration->mutationTypes());
}

void Node::unregisterMutationObserver(MutationObserverRegistration* registration)
{
    Vector<OwnPtr<MutationObserverRegistration> >* registry = mutationObserverRegistry();
    ASSERT(registry);
    if (!registry)
        return;

    size_t index = registry->find(registration);
    ASSERT(index != kNotFound);
    if (index == kNotFound)
        return;

    // Deleting the registration may cause this node to be derefed, so we must make sure the Vector operation completes
    // before that, in case |this| is destroyed (see MutationObserverRegistration::m_registrationNodeKeepAlive).
    // FIXME: Simplify the registration/transient registration logic to make this understandable by humans.
    RefPtr<Node> protect(this);
    registry->remove(index);
}

void Node::registerTransientMutationObserver(MutationObserverRegistration* registration)
{
    ensureRareData().ensureMutationObserverData().transientRegistry.add(registration);
}

void Node::unregisterTransientMutationObserver(MutationObserverRegistration* registration)
{
    HashSet<RawPtr<MutationObserverRegistration> >* transientRegistry = transientMutationObserverRegistry();
    ASSERT(transientRegistry);
    if (!transientRegistry)
        return;

    ASSERT(transientRegistry->contains(registration));
    transientRegistry->remove(registration);
}

void Node::notifyMutationObserversNodeWillDetach()
{
    if (!document().hasMutationObservers())
        return;

    for (Node* node = parentNode(); node; node = node->parentNode()) {
        if (Vector<OwnPtr<MutationObserverRegistration> >* registry = node->mutationObserverRegistry()) {
            const size_t size = registry->size();
            for (size_t i = 0; i < size; ++i)
                registry->at(i)->observedSubtreeNodeWillDetach(*this);
        }

        if (HashSet<RawPtr<MutationObserverRegistration> >* transientRegistry = node->transientMutationObserverRegistry()) {
            for (HashSet<RawPtr<MutationObserverRegistration> >::iterator iter = transientRegistry->begin(); iter != transientRegistry->end(); ++iter)
                (*iter)->observedSubtreeNodeWillDetach(*this);
        }
    }
}

void Node::handleLocalEvents(Event* event)
{
    if (!hasEventTargetData())
        return;
    fireEventListeners(event);
}

void Node::dispatchScopedEvent(PassRefPtr<Event> event)
{
    dispatchScopedEventDispatchMediator(EventDispatchMediator::create(event));
}

void Node::dispatchScopedEventDispatchMediator(PassRefPtr<EventDispatchMediator> eventDispatchMediator)
{
    EventDispatcher::dispatchScopedEvent(this, eventDispatchMediator);
}

bool Node::dispatchEvent(PassRefPtr<Event> event)
{
    if (event->isMouseEvent())
        return EventDispatcher::dispatchEvent(this, MouseEventDispatchMediator::create(static_pointer_cast<MouseEvent>(event), MouseEventDispatchMediator::SyntheticMouseEvent));
    if (event->isTouchEvent())
        return dispatchTouchEvent(static_pointer_cast<TouchEvent>(event));
    return EventDispatcher::dispatchEvent(this, EventDispatchMediator::create(event));
}

bool Node::dispatchDOMActivateEvent(int detail, PassRefPtr<Event> underlyingEvent)
{
    ASSERT(!EventDispatchForbiddenScope::isEventDispatchForbidden());
    RefPtr<UIEvent> event = UIEvent::create(EventTypeNames::DOMActivate, true, true, document().domWindow(), detail);
    event->setUnderlyingEvent(underlyingEvent);
    dispatchScopedEvent(event);
    return event->defaultHandled();
}

bool Node::dispatchKeyEvent(const PlatformKeyboardEvent& event)
{
    return EventDispatcher::dispatchEvent(this, KeyboardEventDispatchMediator::create(KeyboardEvent::create(event, document().domWindow())));
}

bool Node::dispatchMouseEvent(const PlatformMouseEvent& event, const AtomicString& eventType,
    int detail, Node* relatedTarget)
{
    return EventDispatcher::dispatchEvent(this, MouseEventDispatchMediator::create(MouseEvent::create(eventType, document().domWindow(), event, detail, relatedTarget)));
}

bool Node::dispatchGestureEvent(const PlatformGestureEvent& event)
{
    RefPtr<GestureEvent> gestureEvent = GestureEvent::create(document().domWindow(), event);
    if (!gestureEvent.get())
        return false;
    return EventDispatcher::dispatchEvent(this, GestureEventDispatchMediator::create(gestureEvent));
}

bool Node::dispatchTouchEvent(PassRefPtr<TouchEvent> event)
{
    return EventDispatcher::dispatchEvent(this, TouchEventDispatchMediator::create(event));
}

void Node::dispatchSimulatedClick(Event* underlyingEvent, SimulatedClickMouseEventOptions eventOptions)
{
    EventDispatcher::dispatchSimulatedClick(this, underlyingEvent, eventOptions);
}

bool Node::dispatchWheelEvent(const PlatformWheelEvent& event)
{
    return EventDispatcher::dispatchEvent(this, WheelEventDispatchMediator::create(event, document().domWindow()));
}

void Node::dispatchInputEvent()
{
    dispatchScopedEvent(Event::createBubble(EventTypeNames::input));
}

void Node::defaultEventHandler(Event* event)
{
    if (event->target() != this)
        return;
    const AtomicString& eventType = event->type();
    if (eventType == EventTypeNames::keydown || eventType == EventTypeNames::keypress) {
        if (event->isKeyboardEvent()) {
            if (LocalFrame* frame = document().frame())
                frame->eventHandler().defaultKeyboardEventHandler(toKeyboardEvent(event));
        }
    } else if (eventType == EventTypeNames::click) {
        int detail = event->isUIEvent() ? static_cast<UIEvent*>(event)->detail() : 0;
        if (dispatchDOMActivateEvent(detail, event))
            event->setDefaultHandled();
    } else if (eventType == EventTypeNames::textInput) {
        if (event->hasInterface(EventNames::TextEvent)) {
            if (LocalFrame* frame = document().frame())
                frame->eventHandler().defaultTextInputEventHandler(toTextEvent(event));
        }
    } else if ((eventType == EventTypeNames::wheel || eventType == EventTypeNames::mousewheel) && event->hasInterface(EventNames::WheelEvent)) {
        WheelEvent* wheelEvent = toWheelEvent(event);

        // If we don't have a renderer, send the wheel event to the first node we find with a renderer.
        // This is needed for <option> and <optgroup> elements so that <select>s get a wheel scroll.
        Node* startNode = this;
        while (startNode && !startNode->renderer())
            startNode = startNode->parentOrShadowHostNode();

        if (startNode && startNode->renderer()) {
            if (LocalFrame* frame = document().frame())
                frame->eventHandler().defaultWheelEventHandler(startNode, wheelEvent);
        }
    } else if (event->type() == EventTypeNames::webkitEditableContentChanged) {
        dispatchInputEvent();
    }
}

void Node::willCallDefaultEventHandler(const Event&)
{
}

bool Node::willRespondToMouseMoveEvents()
{
    return hasEventListeners(EventTypeNames::mousemove) || hasEventListeners(EventTypeNames::mouseover) || hasEventListeners(EventTypeNames::mouseout);
}

bool Node::willRespondToMouseClickEvents()
{
    return isContentEditable(UserSelectAllIsAlwaysNonEditable) || hasEventListeners(EventTypeNames::mouseup) || hasEventListeners(EventTypeNames::mousedown) || hasEventListeners(EventTypeNames::click) || hasEventListeners(EventTypeNames::DOMActivate);
}

bool Node::willRespondToTouchEvents()
{
    return hasEventListeners(EventTypeNames::touchstart) || hasEventListeners(EventTypeNames::touchmove) || hasEventListeners(EventTypeNames::touchcancel) || hasEventListeners(EventTypeNames::touchend);
}

#if !ENABLE(OILPAN)
// This is here for inlining
inline void TreeScope::removedLastRefToScope()
{
    ASSERT_WITH_SECURITY_IMPLICATION(!deletionHasBegun());
    if (m_guardRefCount) {
        // If removing a child removes the last self-only ref, we don't
        // want the scope to be destructed until after
        // removeDetachedChildren returns, so we guard ourselves with an
        // extra self-only ref.
        guardRef();
        dispose();
#if ENABLE(ASSERT)
        // We need to do this right now since guardDeref() can delete this.
        rootNode().m_inRemovedLastRefFunction = false;
#endif
        guardDeref();
    } else {
#if ENABLE(ASSERT)
        rootNode().m_inRemovedLastRefFunction = false;
#endif
#if ENABLE(SECURITY_ASSERT)
        beginDeletion();
#endif
        delete this;
    }
}

// It's important not to inline removedLastRef, because we don't want to inline the code to
// delete a Node at each deref call site.
void Node::removedLastRef()
{
    // An explicit check for Document here is better than a virtual function since it is
    // faster for non-Document nodes, and because the call to removedLastRef that is inlined
    // at all deref call sites is smaller if it's a non-virtual function.
    if (isTreeScope()) {
        treeScope().removedLastRefToScope();
        return;
    }

#if ENABLE(SECURITY_ASSERT)
    m_deletionHasBegun = true;
#endif
    delete this;
}
#endif

PassRefPtr<StaticNodeList> Node::getDestinationInsertionPoints()
{
    document().updateDistributionForNodeIfNeeded(this);
    Vector<RawPtr<InsertionPoint>, 8> insertionPoints;
    collectDestinationInsertionPoints(*this, insertionPoints);
    // FIXME(sky): Is there an easier way to get this into a Vector<Node>?
    Vector<RefPtr<Node> > nodes(insertionPoints.size());
    copyToVector(insertionPoints, nodes);
    return StaticNodeList::adopt(nodes);
}

void Node::setFocus(bool flag)
{
    document().userActionElements().setFocused(this, flag);
}

void Node::setActive(bool flag)
{
    document().userActionElements().setActive(this, flag);
}

void Node::setHovered(bool flag)
{
    document().userActionElements().setHovered(this, flag);
}

bool Node::isUserActionElementActive() const
{
    ASSERT(isUserActionElement());
    return document().userActionElements().isActive(this);
}

bool Node::isUserActionElementInActiveChain() const
{
    ASSERT(isUserActionElement());
    return document().userActionElements().isInActiveChain(this);
}

bool Node::isUserActionElementHovered() const
{
    ASSERT(isUserActionElement());
    return document().userActionElements().isHovered(this);
}

bool Node::isUserActionElementFocused() const
{
    ASSERT(isUserActionElement());
    return document().userActionElements().isFocused(this);
}

void Node::setCustomElementState(CustomElementState newState)
{
    CustomElementState oldState = customElementState();

    switch (newState) {
    case NotCustomElement:
        ASSERT_NOT_REACHED(); // Everything starts in this state
        return;

    case WaitingForUpgrade:
        ASSERT(NotCustomElement == oldState);
        break;

    case Upgraded:
        ASSERT(WaitingForUpgrade == oldState);
        break;
    }

    ASSERT(isHTMLElement());
    setFlag(CustomElementFlag);
    setFlag(newState == Upgraded, CustomElementUpgradedFlag);

    if (oldState == NotCustomElement || newState == Upgraded)
        setNeedsStyleRecalc(SubtreeStyleChange); // :unresolved has changed
}

unsigned Node::lengthOfContents() const
{
    // This switch statement must be consistent with that of Range::processContentsBetweenOffsets.
    switch (nodeType()) {
    case Node::TEXT_NODE:
        return toCharacterData(this)->length();
    case Node::ELEMENT_NODE:
    case Node::DOCUMENT_NODE:
    case Node::DOCUMENT_FRAGMENT_NODE:
        return toContainerNode(this)->countChildren();
    }
    ASSERT_NOT_REACHED();
    return 0;
}

v8::Handle<v8::Object> Node::wrap(v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    ASSERT(!DOMDataStore::containsWrapperNonTemplate(this, isolate));

    const WrapperTypeInfo* wrapperType = wrapperTypeInfo();

    v8::Handle<v8::Object> wrapper = V8DOMWrapper::createWrapper(creationContext, wrapperType, toScriptWrappableBase(), isolate);
    if (UNLIKELY(wrapper.IsEmpty()))
        return wrapper;

    wrapperType->installConditionallyEnabledProperties(wrapper, isolate);
    V8DOMWrapper::associateObjectWithWrapperNonTemplate(this, wrapperType, wrapper, isolate);
    return wrapper;
}

} // namespace blink

#ifndef NDEBUG

void showNode(const blink::Node* node)
{
    if (node)
        node->showNode("");
}

void showTree(const blink::Node* node)
{
    if (node)
        node->showTreeForThis();
}

void showNodePath(const blink::Node* node)
{
    if (node)
        node->showNodePathForThis();
}

#endif
