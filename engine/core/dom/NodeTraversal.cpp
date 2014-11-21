/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012 Apple Inc. All rights reserved.
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

#include "sky/engine/config.h"
#include "sky/engine/core/dom/NodeTraversal.h"

#include "sky/engine/core/dom/ContainerNode.h"

namespace blink {

Node* NodeTraversal::nextAncestorSibling(const Node& current)
{
    ASSERT(!current.nextSibling());
    for (Node* parent = current.parentNode(); parent; parent = parent->parentNode()) {
        if (parent->nextSibling())
            return parent->nextSibling();
    }
    return 0;
}

Node* NodeTraversal::nextAncestorSibling(const Node& current, const Node* stayWithin)
{
    ASSERT(!current.nextSibling());
    ASSERT(current != stayWithin);
    for (Node* parent = current.parentNode(); parent; parent = parent->parentNode()) {
        if (parent == stayWithin)
            return 0;
        if (parent->nextSibling())
            return parent->nextSibling();
    }
    return 0;
}

Node* NodeTraversal::lastWithin(const ContainerNode& current)
{
    Node* descendant = current.lastChild();
    for (Node* child = descendant; child; child = child->lastChild())
        descendant = child;
    return descendant;
}

Node& NodeTraversal::lastWithinOrSelf(Node& current)
{
    Node* lastDescendant = current.isContainerNode() ? NodeTraversal::lastWithin(toContainerNode(current)) : 0;
    return lastDescendant ? *lastDescendant : current;
}

Node* NodeTraversal::previous(const Node& current, const Node* stayWithin)
{
    if (current == stayWithin)
        return 0;
    if (current.previousSibling()) {
        Node* previous = current.previousSibling();
        while (Node* child = previous->lastChild())
            previous = child;
        return previous;
    }
    return current.parentNode();
}

Node* NodeTraversal::previousSkippingChildren(const Node& current, const Node* stayWithin)
{
    if (current == stayWithin)
        return 0;
    if (current.previousSibling())
        return current.previousSibling();
    for (Node* parent = current.parentNode(); parent; parent = parent->parentNode()) {
        if (parent == stayWithin)
            return 0;
        if (parent->previousSibling())
            return parent->previousSibling();
    }
    return 0;
}

Node* NodeTraversal::nextPostOrder(const Node& current, const Node* stayWithin)
{
    if (current == stayWithin)
        return 0;
    if (!current.nextSibling())
        return current.parentNode();
    Node* next = current.nextSibling();
    while (Node* child = next->firstChild())
        next = child;
    return next;
}

static Node* previousAncestorSiblingPostOrder(const Node& current, const Node* stayWithin)
{
    ASSERT(!current.previousSibling());
    for (Node* parent = current.parentNode(); parent; parent = parent->parentNode()) {
        if (parent == stayWithin)
            return 0;
        if (parent->previousSibling())
            return parent->previousSibling();
    }
    return 0;
}

Node* NodeTraversal::previousPostOrder(const Node& current, const Node* stayWithin)
{
    if (Node* lastChild = current.lastChild())
        return lastChild;
    if (current == stayWithin)
        return 0;
    if (current.previousSibling())
        return current.previousSibling();
    return previousAncestorSiblingPostOrder(current, stayWithin);
}

} // namespace blink
