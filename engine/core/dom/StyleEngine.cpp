/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 *           (C) 2006 Alexey Proskuryakov (ap@webkit.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2011, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (C) 2008, 2009, 2011, 2012 Google Inc. All rights reserved.
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) Research In Motion Limited 2010-2011. All rights reserved.
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
#include "sky/engine/core/dom/StyleEngine.h"

#include "sky/engine/core/css/CSSFontSelector.h"
#include "sky/engine/core/css/CSSStyleSheet.h"
#include "sky/engine/core/css/FontFaceCache.h"
#include "sky/engine/core/css/StyleSheetContents.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/ElementTraversal.h"
#include "sky/engine/core/dom/StyleSheetCollection.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/core/html/HTMLStyleElement.h"
#include "sky/engine/core/html/imports/HTMLImportsController.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/core/rendering/RenderView.h"

namespace blink {

StyleEngine::StyleEngine(Document& document)
    : m_document(&document)
    , m_resolver(adoptPtr(new StyleResolver(*m_document)))
    , m_fontSelector(CSSFontSelector::create(&document))
{
    m_fontSelector->registerForInvalidationCallbacks(this);
    m_activeTreeScopes.add(&document);
}

StyleEngine::~StyleEngine()
{
    m_fontSelector->clearDocument();
    m_fontSelector->unregisterForInvalidationCallbacks(this);
}

void StyleEngine::addTreeScope(TreeScope& scope)
{
    m_activeTreeScopes.add(&scope);
}

void StyleEngine::removeTreeScope(TreeScope& scope)
{
    m_activeTreeScopes.remove(&scope);
}

void StyleEngine::updateActiveStyleSheets()
{
    ASSERT(!m_document->inStyleRecalc());
    ASSERT(m_resolver);

    for (TreeScope* treeScope : m_activeTreeScopes)
        treeScope->styleSheets().updateActiveStyleSheets(*m_resolver);

    m_document->renderView()->style()->font().update(fontSelector());
}

unsigned StyleEngine::resolverAccessCount() const
{
    return m_resolver->accessCount();
}

void StyleEngine::resolverChanged()
{
    if (!m_document->isActive())
        return;
    updateActiveStyleSheets();
}

void StyleEngine::clearFontCache()
{
    m_fontSelector->fontFaceCache()->clearCSSConnected();
    m_resolver->invalidateMatchedPropertiesCache();
}

void StyleEngine::updateGenericFontFamilySettings()
{
    // FIXME: we should not update generic font family settings when
    // document is inactive.
    ASSERT(m_document->isActive());

    m_fontSelector->updateGenericFontFamilySettings(*m_document);
    m_resolver->invalidateMatchedPropertiesCache();
}

PassRefPtr<CSSStyleSheet> StyleEngine::createSheet(Element* e, const String& text)
{
    RefPtr<CSSStyleSheet> styleSheet;
    AtomicString textContent(text);

    HashMap<AtomicString, StyleSheetContents*>::AddResult result = m_textToSheetCache.add(textContent, nullptr);
    if (result.isNewEntry || !result.storedValue->value) {
        styleSheet = CSSStyleSheet::create(e, KURL());
        styleSheet->contents()->parseString(text);
        if (result.isNewEntry) {
            result.storedValue->value = styleSheet->contents();
            m_sheetToTextCache.add(styleSheet->contents(), textContent);
        }
    } else {
        StyleSheetContents* contents = result.storedValue->value;
        ASSERT(contents);
        styleSheet = CSSStyleSheet::create(contents, e);
    }

    ASSERT(styleSheet);
    return styleSheet;
}

void StyleEngine::removeSheet(StyleSheetContents* contents)
{
    HashMap<StyleSheetContents*, AtomicString>::iterator it = m_sheetToTextCache.find(contents);
    if (it == m_sheetToTextCache.end())
        return;

    m_textToSheetCache.remove(it->value);
    m_sheetToTextCache.remove(contents);
}

void StyleEngine::fontsNeedUpdate(CSSFontSelector*)
{
    m_resolver->invalidateMatchedPropertiesCache();
    m_document->setNeedsStyleRecalc(SubtreeStyleChange);
}

}
