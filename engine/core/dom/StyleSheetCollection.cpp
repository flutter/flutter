/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 *           (C) 2006 Alexey Proskuryakov (ap@webkit.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2013 Google Inc. All rights reserved.
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
#include "sky/engine/core/dom/StyleSheetCollection.h"

#include "sky/engine/core/css/CSSStyleSheet.h"
#include "sky/engine/core/css/resolver/StyleResolver.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/dom/TreeScope.h"
#include "sky/engine/core/html/HTMLStyleElement.h"

namespace blink {

StyleSheetCollection::StyleSheetCollection(TreeScope& treeScope)
    : m_treeScope(treeScope)
    , m_needsUpdate(true)
{
}

StyleSheetCollection::~StyleSheetCollection()
{
}

void StyleSheetCollection::addStyleSheetCandidateNode(HTMLStyleElement& element)
{
    ASSERT(element.inActiveDocument());
    m_styleSheetCandidateNodes.add(&element);
    m_needsUpdate = true;
}

void StyleSheetCollection::removeStyleSheetCandidateNode(HTMLStyleElement& element)
{
    m_styleSheetCandidateNodes.remove(&element);
    m_needsUpdate = true;
}

void StyleSheetCollection::collectStyleSheets(Vector<RefPtr<CSSStyleSheet>>& sheets)
{
    for (Node* node : m_styleSheetCandidateNodes) {
        ASSERT(isHTMLStyleElement(*node));
        if (CSSStyleSheet* sheet = toHTMLStyleElement(node)->sheet())
            sheets.append(sheet);
    }
}

void StyleSheetCollection::updateActiveStyleSheets(StyleResolver& resolver)
{
    if (!m_needsUpdate)
        return;

    Vector<RefPtr<CSSStyleSheet>> candidateSheets;
    collectStyleSheets(candidateSheets);

    m_treeScope.scopedStyleResolver().resetAuthorStyle();
    resolver.removePendingAuthorStyleSheets(m_activeAuthorStyleSheets);
    resolver.lazyAppendAuthorStyleSheets(0, candidateSheets);

    Node& root = m_treeScope.rootNode();

    // TODO(esprehn): We should avoid subtree recalcs in sky when rules change
    // and only recalc specific tree scopes.
    root.setNeedsStyleRecalc(SubtreeStyleChange);

    // TODO(esprehn): We should use LocalStyleChange, :host rule changes
    // can only impact the host directly as Sky has no descendant selectors.
    if (root.isShadowRoot())
        toShadowRoot(root).host()->setNeedsStyleRecalc(SubtreeStyleChange);

    m_activeAuthorStyleSheets.swap(candidateSheets);
    m_needsUpdate = false;
}

}
