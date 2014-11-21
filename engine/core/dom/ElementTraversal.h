/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013 Apple Inc. All rights reserved.
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (C) 2014 Samsung Electronics. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_DOM_ELEMENTTRAVERSAL_H_
#define SKY_ENGINE_CORE_DOM_ELEMENTTRAVERSAL_H_

#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/NodeTraversal.h"

namespace blink {

template <class ElementType>
class Traversal {
public:
    // First or last ElementType child of the node.
    static ElementType* firstChild(const ContainerNode& current) { return firstChildTemplate(current); }
    static ElementType* firstChild(const Node& current) { return firstChildTemplate(current); }
    template <class MatchFunc>
    static ElementType* firstChild(const ContainerNode&, MatchFunc);
    static ElementType* lastChild(const ContainerNode& current) { return lastChildTemplate(current); }
    static ElementType* lastChild(const Node& current) { return lastChildTemplate(current); }
    template <class MatchFunc>
    static ElementType* lastChild(const ContainerNode&, MatchFunc);

    // First ElementType ancestor of the node.
    static ElementType* firstAncestor(const Node& current);
    static ElementType* firstAncestorOrSelf(Node& current) { return firstAncestorOrSelfTemplate(current); }
    static ElementType* firstAncestorOrSelf(Element& current) { return firstAncestorOrSelfTemplate(current); }
    static const ElementType* firstAncestorOrSelf(const Node& current) { return firstAncestorOrSelfTemplate(const_cast<Node&>(current)); }
    static const ElementType* firstAncestorOrSelf(const Element& current) { return firstAncestorOrSelfTemplate(const_cast<Element&>(current)); }

    // First or last ElementType descendant of the node.
    // For Elements firstWithin() is always the same as firstChild().
    static ElementType* firstWithin(const ContainerNode& current) { return firstWithinTemplate(current); }
    static ElementType* firstWithin(const Node& current) { return firstWithinTemplate(current); }
    template <typename MatchFunc>
    static ElementType* firstWithin(const ContainerNode&, MatchFunc);
    static ElementType* lastWithin(const ContainerNode& current) { return lastWithinTemplate(current); }
    static ElementType* lastWithin(const Node& current) { return lastWithinTemplate(current); }
    template <class MatchFunc>
    static ElementType* lastWithin(const ContainerNode&, MatchFunc);

    // Pre-order traversal skipping non-element nodes.
    static ElementType* next(const ContainerNode& current) { return nextTemplate(current); }
    static ElementType* next(const Node& current) { return nextTemplate(current); }
    static ElementType* next(const ContainerNode& current, const Node* stayWithin) { return nextTemplate(current, stayWithin); }
    static ElementType* next(const Node& current, const Node* stayWithin) { return nextTemplate(current, stayWithin); }
    template <class MatchFunc>
    static ElementType* next(const ContainerNode& current, const Node* stayWithin, MatchFunc);
    static ElementType* previous(const Node&);
    static ElementType* previous(const Node&, const Node* stayWithin);
    template <class MatchFunc>
    static ElementType* previous(const ContainerNode& current, const Node* stayWithin, MatchFunc);

    // Like next, but skips children.
    static ElementType* nextSkippingChildren(const Node&);
    static ElementType* nextSkippingChildren(const Node&, const Node* stayWithin);

    // Previous / Next sibling.
    static ElementType* previousSibling(const Node&);
    template <class MatchFunc>
    static ElementType* previousSibling(const Node&, MatchFunc);
    static ElementType* nextSibling(const Node&);
    template <class MatchFunc>
    static ElementType* nextSibling(const Node&, MatchFunc);

private:
    template <class NodeType>
    static ElementType* firstChildTemplate(NodeType&);
    template <class NodeType>
    static ElementType* lastChildTemplate(NodeType&);
    template <class NodeType>
    static ElementType* firstAncestorOrSelfTemplate(NodeType&);
    template <class NodeType>
    static ElementType* firstWithinTemplate(NodeType&);
    template <class NodeType>
    static ElementType* lastWithinTemplate(NodeType&);
    template <class NodeType>
    static ElementType* nextTemplate(NodeType&);
    template <class NodeType>
    static ElementType* nextTemplate(NodeType&, const Node* stayWithin);
};

typedef Traversal<Element> ElementTraversal;

// Specialized for pure Element to exploit the fact that Elements parent is always either another Element or the root.
template <>
template <class NodeType>
inline Element* Traversal<Element>::firstWithinTemplate(NodeType& current)
{
    return firstChildTemplate(current);
}

template <>
template <class NodeType>
inline Element* Traversal<Element>::nextTemplate(NodeType& current)
{
    Node* node = NodeTraversal::next(current);
    while (node && !node->isElementNode())
        node = NodeTraversal::nextSkippingChildren(*node);
    return toElement(node);
}

template <>
template <class NodeType>
inline Element* Traversal<Element>::nextTemplate(NodeType& current, const Node* stayWithin)
{
    Node* node = NodeTraversal::next(current, stayWithin);
    while (node && !node->isElementNode())
        node = NodeTraversal::nextSkippingChildren(*node, stayWithin);
    return toElement(node);
}

// Generic versions.
template <class ElementType>
template <class NodeType>
inline ElementType* Traversal<ElementType>::firstChildTemplate(NodeType& current)
{
    Node* node = current.firstChild();
    while (node && !isElementOfType<const ElementType>(*node))
        node = node->nextSibling();
    return toElement<ElementType>(node);
}

template <class ElementType>
template <class MatchFunc>
inline ElementType* Traversal<ElementType>::firstChild(const ContainerNode& current, MatchFunc isMatch)
{
    ElementType* element = Traversal<ElementType>::firstChild(current);
    while (element && !isMatch(*element))
        element = Traversal<ElementType>::nextSibling(*element);
    return element;
}

template <class ElementType>
inline ElementType* Traversal<ElementType>::firstAncestor(const Node& current)
{
    ContainerNode* ancestor = current.parentNode();
    while (ancestor && !isElementOfType<const ElementType>(*ancestor))
        ancestor = ancestor->parentNode();
    return toElement<ElementType>(ancestor);
}

template <class ElementType>
template <class NodeType>
inline ElementType* Traversal<ElementType>::firstAncestorOrSelfTemplate(NodeType& current)
{
    if (isElementOfType<const ElementType>(current))
        return &toElement<ElementType>(current);
    return firstAncestor(current);
}

template <class ElementType>
template <class NodeType>
inline ElementType* Traversal<ElementType>::lastChildTemplate(NodeType& current)
{
    Node* node = current.lastChild();
    while (node && !isElementOfType<const ElementType>(*node))
        node = node->previousSibling();
    return toElement<ElementType>(node);
}

template <class ElementType>
template <class MatchFunc>
inline ElementType* Traversal<ElementType>::lastChild(const ContainerNode& current, MatchFunc isMatch)
{
    ElementType* element = Traversal<ElementType>::lastChild(current);
    while (element && !isMatch(*element))
        element = Traversal<ElementType>::previousSibling(*element);
    return element;
}

template <class ElementType>
template <class NodeType>
inline ElementType* Traversal<ElementType>::firstWithinTemplate(NodeType& current)
{
    Node* node = current.firstChild();
    while (node && !isElementOfType<const ElementType>(*node))
        node = NodeTraversal::next(*node, &current);
    return toElement<ElementType>(node);
}

template <class ElementType>
template <typename MatchFunc>
inline ElementType* Traversal<ElementType>::firstWithin(const ContainerNode& current, MatchFunc isMatch)
{
    ElementType* element = Traversal<ElementType>::firstWithin(current);
    while (element && !isMatch(*element))
        element = Traversal<ElementType>::next(*element, &current, isMatch);
    return element;
}

template <class ElementType>
template <class NodeType>
inline ElementType* Traversal<ElementType>::lastWithinTemplate(NodeType& current)
{
    Node* node = NodeTraversal::lastWithin(current);
    while (node && !isElementOfType<const ElementType>(*node))
        node = NodeTraversal::previous(*node, &current);
    return toElement<ElementType>(node);
}

template <class ElementType>
template <class MatchFunc>
inline ElementType* Traversal<ElementType>::lastWithin(const ContainerNode& current, MatchFunc isMatch)
{
    ElementType* element = Traversal<ElementType>::lastWithin(current);
    while (element && !isMatch(*element))
        element = Traversal<ElementType>::previous(*element, &current, isMatch);
    return element;
}

template <class ElementType>
template <class NodeType>
inline ElementType* Traversal<ElementType>::nextTemplate(NodeType& current)
{
    Node* node = NodeTraversal::next(current);
    while (node && !isElementOfType<const ElementType>(*node))
        node = NodeTraversal::next(*node);
    return toElement<ElementType>(node);
}

template <class ElementType>
template <class NodeType>
inline ElementType* Traversal<ElementType>::nextTemplate(NodeType& current, const Node* stayWithin)
{
    Node* node = NodeTraversal::next(current, stayWithin);
    while (node && !isElementOfType<const ElementType>(*node))
        node = NodeTraversal::next(*node, stayWithin);
    return toElement<ElementType>(node);
}

template <class ElementType>
template <class MatchFunc>
inline ElementType* Traversal<ElementType>::next(const ContainerNode& current, const Node* stayWithin, MatchFunc isMatch)
{
    ElementType* element = Traversal<ElementType>::next(current, stayWithin);
    while (element && !isMatch(*element))
        element = Traversal<ElementType>::next(*element, stayWithin);
    return element;
}

template <class ElementType>
inline ElementType* Traversal<ElementType>::previous(const Node& current)
{
    Node* node = NodeTraversal::previous(current);
    while (node && !isElementOfType<const ElementType>(*node))
        node = NodeTraversal::previous(*node);
    return toElement<ElementType>(node);
}

template <class ElementType>
inline ElementType* Traversal<ElementType>::previous(const Node& current, const Node* stayWithin)
{
    Node* node = NodeTraversal::previous(current, stayWithin);
    while (node && !isElementOfType<const ElementType>(*node))
        node = NodeTraversal::previous(*node, stayWithin);
    return toElement<ElementType>(node);
}

template <class ElementType>
template <class MatchFunc>
inline ElementType* Traversal<ElementType>::previous(const ContainerNode& current, const Node* stayWithin, MatchFunc isMatch)
{
    ElementType* element = Traversal<ElementType>::previous(current, stayWithin);
    while (element && !isMatch(*element))
        element = Traversal<ElementType>::previous(*element, stayWithin);
    return element;
}

template <class ElementType>
inline ElementType* Traversal<ElementType>::nextSkippingChildren(const Node& current)
{
    Node* node = NodeTraversal::nextSkippingChildren(current);
    while (node && !isElementOfType<const ElementType>(*node))
        node = NodeTraversal::nextSkippingChildren(*node);
    return toElement<ElementType>(node);
}

template <class ElementType>
inline ElementType* Traversal<ElementType>::nextSkippingChildren(const Node& current, const Node* stayWithin)
{
    Node* node = NodeTraversal::nextSkippingChildren(current, stayWithin);
    while (node && !isElementOfType<const ElementType>(*node))
        node = NodeTraversal::nextSkippingChildren(*node, stayWithin);
    return toElement<ElementType>(node);
}

template <class ElementType>
inline ElementType* Traversal<ElementType>::previousSibling(const Node& current)
{
    Node* node = current.previousSibling();
    while (node && !isElementOfType<const ElementType>(*node))
        node = node->previousSibling();
    return toElement<ElementType>(node);
}

template <class ElementType>
template <class MatchFunc>
inline ElementType* Traversal<ElementType>::previousSibling(const Node& current, MatchFunc isMatch)
{
    ElementType* element = Traversal<ElementType>::previousSibling(current);
    while (element && !isMatch(*element))
        element = Traversal<ElementType>::previousSibling(*element);
    return element;
}

template <class ElementType>
inline ElementType* Traversal<ElementType>::nextSibling(const Node& current)
{
    Node* node = current.nextSibling();
    while (node && !isElementOfType<const ElementType>(*node))
        node = node->nextSibling();
    return toElement<ElementType>(node);
}

template <class ElementType>
template <class MatchFunc>
inline ElementType* Traversal<ElementType>::nextSibling(const Node& current, MatchFunc isMatch)
{
    ElementType* element = Traversal<ElementType>::nextSibling(current);
    while (element && !isMatch(*element))
        element = Traversal<ElementType>::nextSibling(*element);
    return element;
}

} // namespace blink

#endif  // SKY_ENGINE_CORE_DOM_ELEMENTTRAVERSAL_H_
