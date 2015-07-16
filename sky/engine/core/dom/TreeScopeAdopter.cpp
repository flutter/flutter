/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2008 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (C) 2011 Google Inc. All rights reserved.
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
#include "sky/engine/core/dom/TreeScopeAdopter.h"

#include "sky/engine/core/dom/Attr.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/NodeTraversal.h"
#include "sky/engine/core/dom/shadow/ElementShadow.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"

namespace blink {

void TreeScopeAdopter::moveTreeToNewScope(Node& root) const
{
    ASSERT(needsScopeChange());

    oldScope().guardRef();

    Document& oldDocument = oldScope().document();
    Document& newDocument = newScope().document();
    bool willMoveToNewDocument = oldDocument != newDocument;

    for (Node* node = &root; node; node = NodeTraversal::next(*node, &root)) {
        updateTreeScope(*node);

        if (willMoveToNewDocument)
            moveNodeToNewDocument(*node, oldDocument, newDocument);

        if (!node->isElementNode())
            continue;

        if (ShadowRoot* shadow = node->shadowRoot()) {
            shadow->setParentTreeScope(newScope());
            if (willMoveToNewDocument)
                moveTreeToNewDocument(*shadow, oldDocument, newDocument);
        }
    }

    oldScope().guardDeref();
}

void TreeScopeAdopter::moveTreeToNewDocument(Node& root, Document& oldDocument, Document& newDocument) const
{
    ASSERT(oldDocument != newDocument);
    for (Node* node = &root; node; node = NodeTraversal::next(*node, &root)) {
        moveNodeToNewDocument(*node, oldDocument, newDocument);

        if (ShadowRoot* shadow = node->shadowRoot())
            moveTreeToNewDocument(*shadow, oldDocument, newDocument);
    }
}

#if ENABLE(ASSERT)
static bool didMoveToNewDocumentWasCalled = false;
static Document* oldDocumentDidMoveToNewDocumentWasCalledWith = 0;

void TreeScopeAdopter::ensureDidMoveToNewDocumentWasCalled(Document& oldDocument)
{
    ASSERT(!didMoveToNewDocumentWasCalled);
    ASSERT_UNUSED(oldDocument, oldDocument == oldDocumentDidMoveToNewDocumentWasCalledWith);
    didMoveToNewDocumentWasCalled = true;
}
#endif

inline void TreeScopeAdopter::updateTreeScope(Node& node) const
{
    ASSERT(!node.isTreeScope());
    ASSERT(node.treeScope() == oldScope());
#if !ENABLE(OILPAN)
    newScope().guardRef();
    oldScope().guardDeref();
#endif
    node.setTreeScope(m_newScope);
}

inline void TreeScopeAdopter::moveNodeToNewDocument(Node& node, Document& oldDocument, Document& newDocument) const
{
    ASSERT(oldDocument != newDocument);

    if (node.isShadowRoot())
        toShadowRoot(node).setDocument(newDocument);

#if ENABLE(ASSERT)
    didMoveToNewDocumentWasCalled = false;
    oldDocumentDidMoveToNewDocumentWasCalledWith = &oldDocument;
#endif

    node.didMoveToNewDocument(oldDocument);
    ASSERT(didMoveToNewDocumentWasCalled);
}

}
