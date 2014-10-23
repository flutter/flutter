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

#include "config.h"
#include "core/dom/RenderTreeBuilder.h"

#include "core/css/resolver/StyleResolver.h"
#include "core/dom/Node.h"
#include "core/dom/Text.h"
#include "core/rendering/RenderObject.h"
#include "core/rendering/RenderText.h"
#include "core/rendering/RenderView.h"
#include "platform/RuntimeEnabledFeatures.h"

namespace blink {

RenderObject* RenderTreeBuilder::nextRenderer() const
{
    ASSERT(m_renderingParent);

    // Avoid an O(N^2) walk over the children when reattaching all children of a node.
    if (m_renderingParent->needsAttach())
        return 0;

    return NodeRenderingTraversal::nextSiblingRenderer(m_node);
}

RenderObject* RenderTreeBuilder::parentRenderer() const
{
    ASSERT(m_renderingParent);
    return m_renderingParent->renderer();
}

bool RenderTreeBuilder::shouldCreateRenderer() const
{
    if (!m_renderingParent)
        return false;
    RenderObject* parentRenderer = this->parentRenderer();
    if (!parentRenderer)
        return false;
    if (!parentRenderer->canHaveChildren())
        return false;
    return true;
}

RenderStyle& RenderTreeBuilder::style() const
{
    if (!m_style)
        m_style = toElement(m_node)->styleForRenderer();
    return *m_style;
}

void RenderTreeBuilder::createRendererForElementIfNeeded()
{
    ASSERT(!m_node->renderer());

    if (!shouldCreateRenderer())
        return;

    Element* element = toElement(m_node);
    RenderStyle& style = this->style();

    if (!element->rendererIsNeeded(style))
        return;

    RenderObject* newRenderer = element->createRenderer(&style);
    if (!newRenderer)
        return;

    RenderObject* parentRenderer = this->parentRenderer();

    if (!parentRenderer->isChildAllowed(newRenderer, &style)) {
        newRenderer->destroy();
        return;
    }

    RenderObject* nextRenderer = this->nextRenderer();
    element->setRenderer(newRenderer);
    newRenderer->setStyle(&style); // setStyle() can depend on renderer() already being set.

    // Note: Adding newRenderer instead of renderer(). renderer() may be a child of newRenderer.
    parentRenderer->addChild(newRenderer, nextRenderer);
}

void RenderTreeBuilder::createRendererForTextIfNeeded()
{
    ASSERT(!m_node->renderer());

    if (!shouldCreateRenderer())
        return;

    Text* textNode = toText(m_node);
    RenderObject* parentRenderer = this->parentRenderer();

    m_style = parentRenderer->style();

    if (!textNode->textRendererIsNeeded(*m_style, *parentRenderer))
        return;

    RenderText* newRenderer = textNode->createTextRenderer(m_style.get());
    if (!parentRenderer->isChildAllowed(newRenderer, m_style.get())) {
        newRenderer->destroy();
        return;
    }

    RenderObject* nextRenderer = this->nextRenderer();
    textNode->setRenderer(newRenderer);
    // Parent takes care of the animations, no need to call setAnimatableStyle.
    newRenderer->setStyle(m_style.release());
    parentRenderer->addChild(newRenderer, nextRenderer);
}

}
