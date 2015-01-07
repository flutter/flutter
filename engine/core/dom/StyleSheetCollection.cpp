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
#include "sky/engine/core/dom/StyleEngine.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/dom/TreeScope.h"
#include "sky/engine/core/html/HTMLStyleElement.h"

namespace blink {

StyleSheetCollection::StyleSheetCollection(TreeScope& treeScope)
    : m_treeScope(treeScope)
{
}

StyleSheetCollection::~StyleSheetCollection()
{
}

void StyleSheetCollection::addStyleSheetCandidateNode(Node* node, bool)
{
    if (!node->inDocument())
        return;

    // Until the <body> exists, we have no choice but to compare document positions,
    // since styles outside of the body and head continue to be shunted into the head
    // (and thus can shift to end up before dynamically added DOM content that is also
    // outside the body).
    m_styleSheetCandidateNodes.add(node);
}

void StyleSheetCollection::removeStyleSheetCandidateNode(Node* node, ContainerNode* scopingNode)
{
    m_styleSheetCandidateNodes.remove(node);
}

void StyleSheetCollection::collectStyleSheets(Vector<RefPtr<CSSStyleSheet>>& sheets)
{
    DocumentOrderedList::iterator begin = m_styleSheetCandidateNodes.begin();
    DocumentOrderedList::iterator end = m_styleSheetCandidateNodes.end();
    for (DocumentOrderedList::iterator it = begin; it != end; ++it) {
        Node* node = *it;
        if (!isHTMLStyleElement(*node))
            continue;
        if (CSSStyleSheet* sheet = toHTMLStyleElement(node)->sheet())
            sheets.append(sheet);
    }
}

void StyleSheetCollection::updateActiveStyleSheets(StyleEngine* engine)
{
    Vector<RefPtr<CSSStyleSheet>> candidateSheets;
    collectStyleSheets(candidateSheets);

    Node& root = m_treeScope.rootNode();

    // TODO(esprehn): Remove special casing for Document.
    if (root.isDocumentNode()) {
        engine->clearResolver();
        // FIMXE: The following depends on whether StyleRuleFontFace was modified or not.
        // No need to always-clear font cache.
        engine->clearFontCache();
    } else if (StyleResolver* styleResolver = engine->resolver()) {
        // We should not destroy StyleResolver when we find any stylesheet update in a shadow tree.
        // In this case, we will reset rulesets created from style elements in the shadow tree.
        m_treeScope.scopedStyleResolver().resetAuthorStyle();
        styleResolver->removePendingAuthorStyleSheets(m_activeAuthorStyleSheets);
        styleResolver->lazyAppendAuthorStyleSheets(0, candidateSheets);
    }

    // TODO(esprehn): We should avoid subtree recalcs in sky when rules change
    // and only recalc specific tree scopes.
    root.setNeedsStyleRecalc(SubtreeStyleChange);

    // TODO(esprehn): We should use LocalStyleChange, :host rule changes
    // can only impact the host directly as Sky has no descendant selectors.
    if (root.isShadowRoot())
        toShadowRoot(root).host()->setNeedsStyleRecalc(SubtreeStyleChange);

    m_activeAuthorStyleSheets.swap(candidateSheets);
}

}
