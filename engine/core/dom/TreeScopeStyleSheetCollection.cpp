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
#include "sky/engine/core/dom/TreeScopeStyleSheetCollection.h"

#include "sky/engine/core/css/CSSStyleSheet.h"
#include "sky/engine/core/css/StyleSheetContents.h"
#include "sky/engine/core/css/resolver/StyleResolver.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/StyleEngine.h"
#include "sky/engine/core/html/HTMLStyleElement.h"

namespace blink {

TreeScopeStyleSheetCollection::TreeScopeStyleSheetCollection(TreeScope& treeScope)
    : m_treeScope(treeScope)
    , m_usesRemUnits(false)
{
}

void TreeScopeStyleSheetCollection::addStyleSheetCandidateNode(Node* node, bool)
{
    if (!node->inDocument())
        return;

    // Until the <body> exists, we have no choice but to compare document positions,
    // since styles outside of the body and head continue to be shunted into the head
    // (and thus can shift to end up before dynamically added DOM content that is also
    // outside the body).
    m_styleSheetCandidateNodes.add(node);
}

void TreeScopeStyleSheetCollection::removeStyleSheetCandidateNode(Node* node, ContainerNode* scopingNode)
{
    m_styleSheetCandidateNodes.remove(node);
}

void TreeScopeStyleSheetCollection::clearMediaQueryRuleSetStyleSheets()
{
    for (size_t i = 0; i < m_activeAuthorStyleSheets.size(); ++i) {
        StyleSheetContents* contents = m_activeAuthorStyleSheets[i]->contents();
        if (contents->hasMediaQueries())
            contents->clearRuleSet();
    }
}

static bool styleSheetsUseRemUnits(const Vector<RefPtr<CSSStyleSheet> >& sheets)
{
    for (unsigned i = 0; i < sheets.size(); ++i) {
        if (sheets[i]->contents()->usesRemUnits())
            return true;
    }
    return false;
}

void TreeScopeStyleSheetCollection::updateUsesRemUnits()
{
    m_usesRemUnits = styleSheetsUseRemUnits(m_activeAuthorStyleSheets);
}

}
