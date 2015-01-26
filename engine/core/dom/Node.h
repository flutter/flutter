/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004-2011, 2014 Apple Inc. All rights reserved.
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
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

#ifndef SKY_ENGINE_CORE_DOM_NODE_H_
#define SKY_ENGINE_CORE_DOM_NODE_H_

#include "sky/engine/bindings/core/v8/ExceptionStatePlaceholder.h"
#include "sky/engine/core/dom/MutationObserver.h"
#include "sky/engine/core/dom/TreeScope.h"
#include "sky/engine/core/dom/TreeShared.h"
#include "sky/engine/core/editing/EditingBoundary.h"
#include "sky/engine/core/events/EventTarget.h"
#include "sky/engine/core/inspector/InspectorCounters.h"
#include "sky/engine/core/rendering/style/RenderStyleConstants.h"
#include "sky/engine/platform/geometry/LayoutRect.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/platform/weborigin/KURLHash.h"
#include "sky/engine/wtf/Forward.h"

// This needs to be here because Document.h also depends on it.
#define DUMP_NODE_STATISTICS 0

namespace blink {

class Attribute;
class ContainerNode;
class Document;
class Element;
class Event;
class EventDispatchMediator;
class EventListener;
class ExceptionState;
class FloatPoint;
class LocalFrame;
class HTMLQualifiedName;
class IntRect;
class KeyboardEvent;
class NSResolver;
class NodeEventContext;
class NodeList;
class NodeRareData;
class QualifiedName;
class RegisteredEventListener;
class RenderBox;
class RenderBoxModelObject;
class RenderObject;
class RenderStyle;
class ShadowRoot;
template <typename NodeType> class StaticNodeTypeList;
typedef StaticNodeTypeList<Node> StaticNodeList;
class Text;
class WeakNodeMap;

const int nodeStyleChangeShift = 19;

enum StyleChangeType {
    NoStyleChange = 0,
    LocalStyleChange = 1 << nodeStyleChangeShift,
    SubtreeStyleChange = 2 << nodeStyleChangeShift,
    NeedsReattachStyleChange = 3 << nodeStyleChangeShift,
};

class NodeRareDataBase {
public:
    RenderObject* renderer() const { return m_renderer; }
    void setRenderer(RenderObject* renderer) { m_renderer = renderer; }

protected:
    NodeRareDataBase(RenderObject* renderer)
        : m_renderer(renderer)
    { }

private:
    RenderObject* m_renderer;
};

// TreeShared should be the last to pack TreeShared::m_refCount and
// Node::m_nodeFlags on 64bit platforms.
class Node : public EventTarget, public TreeShared<Node> {
    DEFINE_EVENT_TARGET_REFCOUNTING_WILL_BE_REMOVED(TreeShared<Node>);
    DEFINE_WRAPPERTYPEINFO();
    friend class Document;
    friend class TreeScope;
    friend class TreeScopeAdopter;
public:
    enum NodeType {
        ELEMENT_NODE = 1,
        TEXT_NODE = 3,
        DOCUMENT_NODE = 9,
        DOCUMENT_FRAGMENT_NODE = 11,
    };

    enum DocumentPosition {
        DOCUMENT_POSITION_EQUIVALENT = 0x00,
        DOCUMENT_POSITION_DISCONNECTED = 0x01,
        DOCUMENT_POSITION_PRECEDING = 0x02,
        DOCUMENT_POSITION_FOLLOWING = 0x04,
        DOCUMENT_POSITION_CONTAINS = 0x08,
        DOCUMENT_POSITION_CONTAINED_BY = 0x10,
        DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC = 0x20,
    };

#if !ENABLE(OILPAN)
    // All Nodes are placed in their own heap partition for security.
    // See http://crbug.com/246860 for detail.
    void* operator new(size_t);
    void operator delete(void*);
#endif

    static void dumpStatistics();

    virtual ~Node();

    // DOM methods & attributes for Node

    bool hasTagName(const HTMLQualifiedName&) const;
    virtual String nodeName() const = 0;
    virtual NodeType nodeType() const = 0;
    ContainerNode* parentNode() const;
    Element* parentElement() const;
    Node* previousSibling() const { return m_previous; }
    Node* nextSibling() const { return m_next; }
    Node* firstChild() const;
    Node* lastChild() const;

    void remove(ExceptionState&);

    // These should all actually return a node, but this is only important for language bindings,
    // which will already know and hold a ref on the right node to return.
    PassRefPtr<Node> insertBefore(PassRefPtr<Node> newChild, Node* refChild, ExceptionState& = ASSERT_NO_EXCEPTION);
    PassRefPtr<Node> replaceChild(PassRefPtr<Node> newChild, PassRefPtr<Node> oldChild, ExceptionState& = ASSERT_NO_EXCEPTION);
    PassRefPtr<Node> removeChild(PassRefPtr<Node> child, ExceptionState& = ASSERT_NO_EXCEPTION);
    PassRefPtr<Node> appendChild(PassRefPtr<Node> newChild, ExceptionState& = ASSERT_NO_EXCEPTION);

    bool hasChildren() const { return firstChild(); }
    virtual PassRefPtr<Node> cloneNode(bool deep = false) = 0;
    virtual const AtomicString& localName() const;

    String textContent() const;
    void setTextContent(const String&);

    // Other methods (not part of DOM)

    bool isElementNode() const { return getFlag(IsElementFlag); }
    bool isContainerNode() const { return getFlag(IsContainerFlag); }
    bool isTextNode() const { return getFlag(IsTextFlag); }
    bool isHTMLElement() const { return getFlag(IsHTMLFlag); }

    bool isCustomElement() const { return getFlag(CustomElementFlag); }
    enum CustomElementState {
        NotCustomElement  = 0,
        WaitingForUpgrade = 1 << 0,
        Upgraded          = 1 << 1
    };
    CustomElementState customElementState() const
    {
        return isCustomElement()
            ? (getFlag(CustomElementUpgradedFlag) ? Upgraded : WaitingForUpgrade)
            : NotCustomElement;
    }
    void setCustomElementState(CustomElementState newState);

    // StyledElements allow inline style (style="border: 1px"), presentational attributes (ex. color),
    // class names (ex. class="foo bar") and other non-basic styling features. They and also control
    // if this element can participate in style sharing.
    //
    // FIXME: The only things that ever go through StyleResolver that aren't StyledElements are
    // PseudoElements and VTTElements. It's possible we can just eliminate all the checks
    // since those elements will never have class names, inline style, or other things that
    // this apparently guards against.
    bool isStyledElement() const { return isHTMLElement(); }

    bool isDocumentNode() const;
    bool isTreeScope() const;
    bool isDocumentFragment() const { return getFlag(IsDocumentFragmentFlag); }
    bool isShadowRoot() const { return isDocumentFragment() && isTreeScope(); }
    bool isInsertionPoint() const { return getFlag(IsInsertionPointFlag); }

    // If this node is in a shadow tree, returns its shadow host. Otherwise, returns 0.
    Element* shadowHost() const;
    ShadowRoot* containingShadowRoot() const;
    ShadowRoot* shadowRoot() const;

    // Returns 0, a child of ShadowRoot, or a legacy shadow root.
    Node* nonBoundaryShadowTreeRootNode();

    // Node's parent, shadow tree host.
    ContainerNode* parentOrShadowHostNode() const;
    Element* parentOrShadowHostElement() const;
    void setParentOrShadowHostNode(ContainerNode*);

    // Knows about all kinds of hosts.
    ContainerNode* parentOrShadowHostOrTemplateHostNode() const;

    // Returns the parent node, but 0 if the parent node is a ShadowRoot.
    ContainerNode* nonShadowBoundaryParentNode() const;

    // Returns the enclosing event parent Element (or self) that, when clicked, would trigger a navigation.
    Element* enclosingLinkEventParentOrSelf();

    // These low-level calls give the caller responsibility for maintaining the integrity of the tree.
    void setPreviousSibling(Node* previous) { m_previous = previous; }
    void setNextSibling(Node* next) { m_next = next; }

    virtual bool canContainRangeEndPoint() const { return false; }

    // FIXME: These two functions belong in editing -- "atomic node" is an editing concept.
    Node* previousNodeConsideringAtomicNodes() const;
    Node* nextNodeConsideringAtomicNodes() const;

    // Returns the next leaf node or 0 if there are no more.
    // Delivers leaf nodes as if the whole DOM tree were a linear chain of its leaf nodes.
    // Uses an editing-specific concept of what a leaf node is, and should probably be moved
    // out of the Node class into an editing-specific source file.
    Node* nextLeafNode() const;

    // Returns the previous leaf node or 0 if there are no more.
    // Delivers leaf nodes as if the whole DOM tree were a linear chain of its leaf nodes.
    // Uses an editing-specific concept of what a leaf node is, and should probably be moved
    // out of the Node class into an editing-specific source file.
    Node* previousLeafNode() const;

    bool isRootEditableElement() const;
    Element* rootEditableElement() const;
    Element* rootEditableElement(EditableType) const;

    bool isUserActionElement() const { return getFlag(IsUserActionElementFlag); }
    void setUserActionElement(bool flag) { setFlag(flag, IsUserActionElementFlag); }

    bool active() const { return isUserActionElement() && isUserActionElementActive(); }
    bool inActiveChain() const { return isUserActionElement() && isUserActionElementInActiveChain(); }
    bool hovered() const { return isUserActionElement() && isUserActionElementHovered(); }
    bool focused() const { return isUserActionElement() && isUserActionElementFocused(); }

    bool needsAttach() const { return styleChangeType() == NeedsReattachStyleChange; }
    bool needsStyleRecalc() const { return styleChangeType() != NoStyleChange; }
    StyleChangeType styleChangeType() const { return static_cast<StyleChangeType>(m_nodeFlags & StyleChangeMask); }
    bool childNeedsStyleRecalc() const { return getFlag(ChildNeedsStyleRecalcFlag); }
    bool isLink() const { return getFlag(IsLinkFlag); }
    bool isEditingText() const { return isTextNode() && getFlag(IsEditingTextFlag); }

    void setChildNeedsStyleRecalc() { setFlag(ChildNeedsStyleRecalcFlag); }
    void clearChildNeedsStyleRecalc() { clearFlag(ChildNeedsStyleRecalcFlag); }

    void setNeedsStyleRecalc(StyleChangeType);
    void clearNeedsStyleRecalc();

    bool childNeedsDistributionRecalc() const { return getFlag(ChildNeedsDistributionRecalcFlag); }
    void setChildNeedsDistributionRecalc()  { setFlag(ChildNeedsDistributionRecalcFlag); }
    void clearChildNeedsDistributionRecalc()  { clearFlag(ChildNeedsDistributionRecalcFlag); }
    void markAncestorsWithChildNeedsDistributionRecalc();

    void recalcDistribution();

    void setIsLink(bool f);

    bool hasEventTargetData() const { return getFlag(HasEventTargetDataFlag); }
    void setHasEventTargetData(bool flag) { setFlag(flag, HasEventTargetDataFlag); }

    bool isV8CollectableDuringMinorGC() const { return getFlag(V8CollectableDuringMinorGCFlag); }
    void markV8CollectableDuringMinorGC() { setFlag(true, V8CollectableDuringMinorGCFlag); }
    void clearV8CollectableDuringMinorGC() { setFlag(false, V8CollectableDuringMinorGCFlag); }

    virtual void setFocus(bool flag);
    virtual void setActive(bool flag = true);
    virtual void setHovered(bool flag = true);

    virtual short tabIndex() const;

    enum UserSelectAllTreatment {
        UserSelectAllDoesNotAffectEditability,
        UserSelectAllIsAlwaysNonEditable
    };
    bool isContentEditable(UserSelectAllTreatment = UserSelectAllDoesNotAffectEditability);
    bool isContentRichlyEditable();

    bool hasEditableStyle(EditableType editableType = ContentIsEditable, UserSelectAllTreatment treatment = UserSelectAllIsAlwaysNonEditable) const
    {
        switch (editableType) {
        case ContentIsEditable:
            return hasEditableStyle(Editable, treatment);
        case HasEditableAXRole:
            return isEditableToAccessibility(Editable);
        }
        ASSERT_NOT_REACHED();
        return false;
    }

    bool rendererIsRichlyEditable(EditableType editableType = ContentIsEditable) const
    {
        switch (editableType) {
        case ContentIsEditable:
            return hasEditableStyle(RichlyEditable, UserSelectAllIsAlwaysNonEditable);
        case HasEditableAXRole:
            return isEditableToAccessibility(RichlyEditable);
        }
        ASSERT_NOT_REACHED();
        return false;
    }

    virtual LayoutRect boundingBox() const;
    IntRect pixelSnappedBoundingBox() const { return pixelSnappedIntRect(boundingBox()); }

    // Returns true if the node has a non-empty bounding box in layout.
    // This does not 100% guarantee the user can see it, but is pretty close.
    // Note: This method only works properly after layout has occurred.
    bool hasNonEmptyBoundingBox() const;

    unsigned nodeIndex() const;

    // Returns the DOM ownerDocument attribute. This method never returns NULL, except in the case
    // of a Document node.
    Document* ownerDocument() const;

    // Returns the document associated with this node. A Document node returns itself.
    Document& document() const
    {
        return treeScope().document();
    }

    TreeScope& treeScope() const
    {
        ASSERT(m_treeScope);
        return *m_treeScope;
    }

    ContainerNode* ownerScope() const;

    bool inActiveDocument() const;

    // Returns true if this node is associated with a document and is in its associated document's
    // node tree, false otherwise.
    bool inDocument() const
    {
        return getFlag(InDocumentFlag);
    }
    bool isInShadowTree() const { return getFlag(IsInShadowTreeFlag); }
    bool isInTreeScope() const { return getFlag(static_cast<NodeFlags>(InDocumentFlag | IsInShadowTreeFlag)); }

    unsigned countChildren() const;

    bool isDescendantOf(const Node*) const;
    bool contains(const Node*) const;
    bool containsIncludingShadowDOM(const Node*) const;
    bool containsIncludingHostElements(const Node&) const;

    // Used to determine whether range offsets use characters or node indices.
    virtual bool offsetInCharacters() const;
    // Number of DOM 16-bit units contained in node. Note that rendered text length can be different - e.g. because of
    // css-transform:capitalize breaking up precomposed characters and ligatures.
    virtual int maxCharacterOffset() const;

    // Whether or not a selection can be started in this object
    virtual bool canStartSelection() const;

    // -----------------------------------------------------------------------------
    // Integration with rendering tree

    // As renderer() includes a branch you should avoid calling it repeatedly in hot code paths.
    // Note that if a Node has a renderer, it's parentNode is guaranteed to have one as well.
    RenderObject* renderer() const { return hasRareData() ? m_data.m_rareData->renderer() : m_data.m_renderer; };
    void setRenderer(RenderObject* renderer)
    {
        if (hasRareData())
            m_data.m_rareData->setRenderer(renderer);
        else
            m_data.m_renderer = renderer;
    }

    // Use these two methods with caution.
    RenderBox* renderBox() const;
    RenderBoxModelObject* renderBoxModelObject() const;

    struct AttachContext {
        RenderStyle* resolvedStyle;
        bool performingReattach;

        AttachContext() : resolvedStyle(0), performingReattach(false) { }
    };

    // Attaches this node to the rendering tree. This calculates the style to be applied to the node and creates an
    // appropriate RenderObject which will be inserted into the tree (except when the style has display: none). This
    // makes the node visible in the FrameView.
    virtual void attach(const AttachContext& = AttachContext());

    // Detaches the node from the rendering tree, making it invisible in the rendered view. This method will remove
    // the node's rendering object from the rendering tree and delete it.
    virtual void detach(const AttachContext& = AttachContext());

#if ENABLE(ASSERT)
    bool inDetach() const;
#endif

    void reattach(const AttachContext& = AttachContext());
    void lazyReattachIfAttached();

    // Returns true if recalcStyle should be called on the object, if there is such a method (on Document and Element).
    bool shouldCallRecalcStyle(StyleRecalcChange);

    // Wrapper for nodes that don't have a renderer, but still cache the style (like HTMLOptionElement).
    RenderStyle* renderStyle() const;
    RenderStyle* parentRenderStyle() const;

    RenderStyle* computedStyle() { return virtualComputedStyle(); }

    virtual void insertedInto(ContainerNode* insertionPoint);
    virtual void removedFrom(ContainerNode* insertionPoint);

    String debugName() const;

#ifndef NDEBUG
    virtual void formatForDebugger(char* buffer, unsigned length) const;

    void showNode(const char* prefix = "") const;
    void showTreeForThis() const;
    void showNodePathForThis() const;
    void showTreeAndMark(const Node* markedNode1, const char* markedLabel1, const Node* markedNode2 = 0, const char* markedLabel2 = 0) const;
#endif

    enum ShadowTreesTreatment {
        TreatShadowTreesAsDisconnected,
        TreatShadowTreesAsComposed
    };

    unsigned short compareDocumentPosition(const Node*, ShadowTreesTreatment = TreatShadowTreesAsDisconnected) const;

    virtual Node* toNode() override final;

    virtual const AtomicString& interfaceName() const override;
    virtual ExecutionContext* executionContext() const override final;

    virtual bool addEventListener(const AtomicString& eventType, PassRefPtr<EventListener>, bool useCapture = false) override;
    void removeAllEventListenersRecursively();

    using EventTarget::dispatchEvent;
    virtual bool dispatchEvent(PassRefPtr<Event>) override;

    void dispatchScopedEvent(PassRefPtr<Event>);
    void dispatchScopedEventDispatchMediator(PassRefPtr<EventDispatchMediator>);

    virtual void handleLocalEvents(Event*);

    bool dispatchDOMActivateEvent(int detail, PassRefPtr<Event> underlyingEvent);
    void dispatchInputEvent();

    // Perform the default action for an event.
    virtual void defaultEventHandler(Event*);

    virtual EventTargetData* eventTargetData() override;
    virtual EventTargetData& ensureEventTargetData() override;

    void getRegisteredMutationObserversOfType(HashMap<RawPtr<MutationObserver>, MutationRecordDeliveryOptions>&, MutationObserver::MutationType, const QualifiedName* attributeName);
    void registerMutationObserver(MutationObserver&, MutationObserverOptions, const HashSet<AtomicString>& attributeFilter);
    void unregisterMutationObserver(MutationObserverRegistration*);
    void registerTransientMutationObserver(MutationObserverRegistration*);
    void unregisterTransientMutationObserver(MutationObserverRegistration*);
    void notifyMutationObserversNodeWillDetach();

    PassRefPtr<StaticNodeList> getDestinationInsertionPoints();

    void setAlreadySpellChecked(bool flag) { setFlag(flag, AlreadySpellCheckedFlag); }
    bool isAlreadySpellChecked() { return getFlag(AlreadySpellCheckedFlag); }

    unsigned lengthOfContents() const;

    virtual v8::Handle<v8::Object> wrap(v8::Handle<v8::Object> creationContext, v8::Isolate*) override;

private:
    enum NodeFlags {
        HasRareDataFlag = 1,

        // Node type flags. These never change once created.
        IsTextFlag = 1 << 1,
        IsContainerFlag = 1 << 2,
        IsElementFlag = 1 << 3,
        IsHTMLFlag = 1 << 4,
        IsSVGFlag = 1 << 5,
        IsDocumentFragmentFlag = 1 << 6,
        IsInsertionPointFlag = 1 << 7,

        // Changes based on if the element should be treated like a link,
        // ex. When setting the href attribute on an <a>.
        IsLinkFlag = 1 << 8,

        // Changes based on :hover, :active and :focus state.
        IsUserActionElementFlag = 1 << 9,

        // Tree state flags. These change when the element is added/removed
        // from a DOM tree.
        InDocumentFlag = 1 << 10,
        IsInShadowTreeFlag = 1 << 11,

        // Flags related to recalcStyle.

        // FIXME(sky): Flags 12-16 are free.

        ChildNeedsDistributionRecalcFlag = 1 << 17,
        ChildNeedsStyleRecalcFlag = 1 << 18,
        StyleChangeMask = 1 << nodeStyleChangeShift | 1 << (nodeStyleChangeShift + 1),

        CustomElementFlag = 1 << 21,
        CustomElementUpgradedFlag = 1 << 22,

        IsEditingTextFlag = 1 << 23,
        HasWeakReferencesFlag = 1 << 24,
        V8CollectableDuringMinorGCFlag = 1 << 25,
        HasEventTargetDataFlag = 1 << 26,
        AlreadySpellCheckedFlag = 1 << 27,

        DefaultNodeFlags = ChildNeedsStyleRecalcFlag | NeedsReattachStyleChange
    };

    // 9 bits remaining.

    bool getFlag(NodeFlags mask) const { return m_nodeFlags & mask; }
    void setFlag(bool f, NodeFlags mask) { m_nodeFlags = (m_nodeFlags & ~mask) | (-(int32_t)f & mask); }
    void setFlag(NodeFlags mask) { m_nodeFlags |= mask; }
    void clearFlag(NodeFlags mask) { m_nodeFlags &= ~mask; }

protected:
    enum ConstructionType {
        CreateOther = DefaultNodeFlags,
        CreateText = DefaultNodeFlags | IsTextFlag,
        CreateContainer = DefaultNodeFlags | IsContainerFlag,
        CreateElement = CreateContainer | IsElementFlag,
        CreateShadowRoot = CreateContainer | IsDocumentFragmentFlag | IsInShadowTreeFlag,
        CreateDocumentFragment = CreateContainer | IsDocumentFragmentFlag,
        CreateHTMLElement = CreateElement | IsHTMLFlag,
        CreateDocument = CreateContainer | InDocumentFlag,
        CreateInsertionPoint = CreateHTMLElement | IsInsertionPointFlag,
        CreateEditingText = CreateText | IsEditingTextFlag,
    };

    Node(TreeScope*, ConstructionType);

    virtual void didMoveToNewDocument(Document& oldDocument);

#if !ENABLE(OILPAN)
    void willBeDeletedFromDocument();
#endif

    bool hasRareData() const { return getFlag(HasRareDataFlag); }

    NodeRareData* rareData() const;
    NodeRareData& ensureRareData();
#if !ENABLE(OILPAN)
    void clearRareData();

    void clearEventTargetData();
#endif

    void setTreeScope(TreeScope* scope) { m_treeScope = scope; }

    // isTreeScopeInitialized() can be false
    // - in the destruction of Document or ShadowRoot where m_treeScope is set to null or
    // - in the Node constructor called by these two classes where m_treeScope is set by TreeScope ctor.
    bool isTreeScopeInitialized() const { return m_treeScope; }

    void markAncestorsWithChildNeedsStyleRecalc();

private:
    friend class TreeShared<Node>;
    friend class WeakNodeMap;

    unsigned styledSubtreeSize() const;

#if !ENABLE(OILPAN)
    void removedLastRef();
#endif
    bool hasTreeSharedParent() const { return !!parentOrShadowHostNode(); }

    enum EditableLevel { Editable, RichlyEditable };
    bool hasEditableStyle(EditableLevel, UserSelectAllTreatment = UserSelectAllIsAlwaysNonEditable) const;
    bool isEditableToAccessibility(EditableLevel) const;

    bool isUserActionElementActive() const;
    bool isUserActionElementInActiveChain() const;
    bool isUserActionElementHovered() const;
    bool isUserActionElementFocused() const;

    void traceStyleChange(StyleChangeType);
    void traceStyleChangeIfNeeded(StyleChangeType);
    void setStyleChange(StyleChangeType);

    virtual RenderStyle* virtualComputedStyle();

    void trackForDebugging();

    Vector<OwnPtr<MutationObserverRegistration> >* mutationObserverRegistry();
    HashSet<RawPtr<MutationObserverRegistration> >* transientMutationObserverRegistry();

    uint32_t m_nodeFlags;
    ContainerNode* m_parentOrShadowHostNode;
    TreeScope* m_treeScope;
    Node* m_previous;
    Node* m_next;
    // When a node has rare data we move the renderer into the rare data.
    union DataUnion {
        DataUnion() : m_renderer(0) { }
        RenderObject* m_renderer;
        NodeRareDataBase* m_rareData;
    } m_data;
};

inline void Node::setParentOrShadowHostNode(ContainerNode* parent)
{
    ASSERT(isMainThread());
    m_parentOrShadowHostNode = parent;
}

inline ContainerNode* Node::parentOrShadowHostNode() const
{
    ASSERT(isMainThread());
    return m_parentOrShadowHostNode;
}

inline ContainerNode* Node::parentNode() const
{
    return isShadowRoot() ? 0 : parentOrShadowHostNode();
}

inline void Node::lazyReattachIfAttached()
{
    if (styleChangeType() == NeedsReattachStyleChange)
        return;
    if (!inActiveDocument())
        return;

    AttachContext context;
    context.performingReattach = true;

    detach(context);
    markAncestorsWithChildNeedsStyleRecalc();
}

inline bool Node::shouldCallRecalcStyle(StyleRecalcChange change)
{
    return change >= Inherit || needsStyleRecalc() || childNeedsStyleRecalc();
}

// Allow equality comparisons of Nodes by reference or pointer, interchangeably.
DEFINE_COMPARISON_OPERATORS_WITH_REFERENCES_REFCOUNTED(Node)


#define DEFINE_NODE_TYPE_CASTS(thisType, predicate) \
    template<typename T> inline thisType* to##thisType(const RefPtr<T>& node) { return to##thisType(node.get()); } \
    DEFINE_TYPE_CASTS(thisType, Node, node, node->predicate, node.predicate)

// This requires isClassName(const Node&).
#define DEFINE_NODE_TYPE_CASTS_WITH_FUNCTION(thisType) \
    template<typename T> inline thisType* to##thisType(const RefPtr<T>& node) { return to##thisType(node.get()); } \
    DEFINE_TYPE_CASTS(thisType, Node, node, is##thisType(*node), is##thisType(node))

#define DECLARE_NODE_FACTORY(T) \
    static PassRefPtr<T> create(Document&)
#define DEFINE_NODE_FACTORY(T) \
PassRefPtr<T> T::create(Document& document) \
{ \
    return adoptRef(new T(document)); \
}

} // namespace blink

#ifndef NDEBUG
// Outside the WebCore namespace for ease of invocation from gdb.
void showNode(const blink::Node*);
void showTree(const blink::Node*);
void showNodePath(const blink::Node*);
#endif

#endif  // SKY_ENGINE_CORE_DOM_NODE_H_
