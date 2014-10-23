/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
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
 *
 */

#ifndef RenderTreeBuilder_h
#define RenderTreeBuilder_h

#include "core/dom/Document.h"
#include "core/dom/Node.h"
#include "core/dom/NodeRenderingTraversal.h"
#include "wtf/RefPtr.h"

namespace blink {

class ContainerNode;
class RenderObject;
class RenderStyle;

class RenderTreeBuilder {
    STACK_ALLOCATED();
public:
    RenderTreeBuilder(Node* node, RenderStyle* style)
        : m_node(node)
        , m_renderingParent(nullptr)
        , m_style(style)
    {
        ASSERT(!node->renderer());
        ASSERT(node->needsAttach());
        ASSERT(node->document().inStyleRecalc());

        // FIXME: We should be able to ASSERT(node->inActiveDocument()) but childrenChanged is called
        // before ChildNodeInsertionNotifier in ContainerNode's methods and some implementations
        // will trigger a layout inside childrenChanged.
        // Mainly HTMLTextAreaElement::childrenChanged calls HTMLTextFormControlElement::setSelectionRange
        // which does an updateLayoutIgnorePendingStylesheets.

        m_renderingParent = NodeRenderingTraversal::parent(node, &m_parentDetails);
    }

    void createRendererForTextIfNeeded();
    void createRendererForElementIfNeeded();

private:
    RenderObject* parentRenderer() const;
    RenderObject* nextRenderer() const;
    bool shouldCreateRenderer() const;
    RenderStyle& style() const;

    RawPtrWillBeMember<Node> m_node;
    RawPtrWillBeMember<ContainerNode> m_renderingParent;
    NodeRenderingTraversal::ParentDetails m_parentDetails;
    mutable RefPtr<RenderStyle> m_style;
};

} // namespace blink

#endif
