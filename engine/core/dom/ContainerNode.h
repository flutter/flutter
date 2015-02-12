/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2009, 2010, 2011, 2013 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_DOM_CONTAINERNODE_H_
#define SKY_ENGINE_CORE_DOM_CONTAINERNODE_H_

#include "sky/engine/bindings2/exception_state_placeholder.h"
#include "sky/engine/core/dom/Node.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

class ExceptionState;
class FloatPoint;
template <typename NodeType> class StaticNodeTypeList;
typedef StaticNodeTypeList<Element> StaticElementList;

// This constant controls how much buffer is initially allocated
// for a Node Vector that is used to store child Nodes of a given Node.
// FIXME: Optimize the value.
const int initialNodeVectorSize = 11;
typedef Vector<RefPtr<Node>, initialNodeVectorSize> NodeVector;

class ContainerNode : public Node {
public:
    virtual ~ContainerNode();

    Node* firstChild() const { return m_firstChild; }
    Node* lastChild() const { return m_lastChild; }
    bool hasChildren() const { return m_firstChild; }

    bool hasOneChild() const { return m_firstChild && !m_firstChild->nextSibling(); }
    bool hasOneTextChild() const { return hasOneChild() && m_firstChild->isTextNode(); }

    unsigned countChildren() const;

    PassRefPtr<Element> querySelector(const AtomicString& selectors, ExceptionState&);
    PassRefPtr<StaticElementList> querySelectorAll(const AtomicString& selectors, ExceptionState&);

    PassRefPtr<Node> insertBefore(PassRefPtr<Node> newChild, Node* refChild, ExceptionState& = ASSERT_NO_EXCEPTION);
    PassRefPtr<Node> replaceChild(PassRefPtr<Node> newChild, PassRefPtr<Node> oldChild, ExceptionState& = ASSERT_NO_EXCEPTION);
    PassRefPtr<Node> removeChild(PassRefPtr<Node> child, ExceptionState& = ASSERT_NO_EXCEPTION);
    PassRefPtr<Node> appendChild(PassRefPtr<Node> newChild, ExceptionState& = ASSERT_NO_EXCEPTION);

    Element* getElementById(const AtomicString& id) const;

    // These methods are only used during parsing.
    // They don't send DOM mutation events or handle reparenting.
    void parserAppendChild(PassRefPtr<Node>);

    void removeChildren();

    void cloneChildNodes(ContainerNode* clone);

    virtual void attach(const AttachContext& = AttachContext()) override;
    virtual void detach(const AttachContext& = AttachContext()) override;
    virtual LayoutRect boundingBox() const override final;
    virtual void setFocus(bool) override;
    void focusStateChanged();
    virtual void setActive(bool = true) override;
    virtual void setHovered(bool = true) override;

    // -----------------------------------------------------------------------------
    // Notification of document structure changes (see core/dom/Node.h for more notification methods)

    enum ChildrenChangeType { ElementInserted, NonElementInserted, ElementRemoved, NonElementRemoved, AllChildrenRemoved, TextChanged };
    enum ChildrenChangeSource { ChildrenChangeSourceAPI, ChildrenChangeSourceParser };
    struct ChildrenChange {
        STACK_ALLOCATED();
    public:
        static ChildrenChange forInsertion(Node& node, ChildrenChangeSource byParser)
        {
            ChildrenChange change = {
                node.isElementNode() ? ElementInserted : NonElementInserted,
                byParser
            };
            return change;
        }

        static ChildrenChange forRemoval(Node& node, ChildrenChangeSource byParser)
        {
            ChildrenChange change = {
                node.isElementNode() ? ElementRemoved : NonElementRemoved,
                byParser
            };
            return change;
        }

        bool isChildInsertion() const { return type == ElementInserted || type == NonElementInserted; }

        ChildrenChangeType type;
        ChildrenChangeSource byParser;
    };

    // Notifies the node that it's list of children have changed (either by adding or removing child nodes), or a child
    // node that is of the type TEXT_NODE has changed its value.
    virtual void childrenChanged(const ChildrenChange&);

protected:
    ContainerNode(TreeScope*, ConstructionType = CreateContainer);

    void removeDetachedChildren();

    void setFirstChild(Node* child) { m_firstChild = child; }
    void setLastChild(Node* child) { m_lastChild = child; }

private:
    bool isContainerNode() const = delete; // This will catch anyone doing an unnecessary check.
    bool isTextNode() const = delete; // This will catch anyone doing an unnecessary check.

    void removeBetween(Node* previousChild, Node* nextChild, Node& oldChild);
    void insertBeforeCommon(Node& nextChild, Node& oldChild);
    void appendChildCommon(Node& child);
    void updateTreeAfterInsertion(Node& child);
    void willRemoveChildren();
    void willRemoveChild(Node& child);
    void removeDetachedChildrenInContainer(ContainerNode&);
    void addChildNodesToDeletionQueue(Node*&, Node*&, ContainerNode&);

    void notifyNodeInserted(Node&, ChildrenChangeSource = ChildrenChangeSourceAPI);
    void notifyNodeInsertedInternal(Node&);
    void notifyNodeRemoved(Node&);

    inline void checkAcceptChildType(const Node* newChild, ExceptionState&) const;
    inline void checkAcceptChildHierarchy(const Node& newChild, const Node* oldChild, ExceptionState&) const;
    inline bool containsConsideringHostElements(const Node&) const;

    void attachChildren(const AttachContext& = AttachContext());
    void detachChildren(const AttachContext& = AttachContext());

    bool getUpperLeftCorner(FloatPoint&) const;
    bool getLowerRightCorner(FloatPoint&) const;

    RawPtr<Node> m_firstChild;
    RawPtr<Node> m_lastChild;
};

#if ENABLE(ASSERT)
bool childAttachedAllowedWhenAttachingChildren(ContainerNode*);
#endif

DEFINE_NODE_TYPE_CASTS(ContainerNode, isContainerNode());

inline ContainerNode::ContainerNode(TreeScope* treeScope, ConstructionType type)
    : Node(treeScope, type)
    , m_firstChild(nullptr)
    , m_lastChild(nullptr)
{
}

inline void ContainerNode::attachChildren(const AttachContext& context)
{
    AttachContext childrenContext(context);
    childrenContext.resolvedStyle = 0;

    for (Node* child = firstChild(); child; child = child->nextSibling()) {
        ASSERT(child->needsAttach() || childAttachedAllowedWhenAttachingChildren(this));
        if (child->needsAttach())
            child->attach(childrenContext);
    }
}

inline void ContainerNode::detachChildren(const AttachContext& context)
{
    AttachContext childrenContext(context);
    childrenContext.resolvedStyle = 0;

    for (Node* child = firstChild(); child; child = child->nextSibling())
        child->detach(childrenContext);
}

inline unsigned Node::countChildren() const
{
    if (!isContainerNode())
        return 0;
    return toContainerNode(this)->countChildren();
}

inline Node* Node::firstChild() const
{
    if (!isContainerNode())
        return 0;
    return toContainerNode(this)->firstChild();
}

inline Node* Node::lastChild() const
{
    if (!isContainerNode())
        return 0;
    return toContainerNode(this)->lastChild();
}

inline bool Node::isTreeScope() const
{
    return &treeScope().rootNode() == this;
}

inline void getChildNodes(ContainerNode& node, NodeVector& nodes)
{
    ASSERT(!nodes.size());
    for (Node* child = node.firstChild(); child; child = child->nextSibling())
        nodes.append(child);
}

} // namespace blink

#endif  // SKY_ENGINE_CORE_DOM_CONTAINERNODE_H_
