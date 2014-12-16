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
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/StyleSheetCollection.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/core/html/HTMLStyleElement.h"
#include "sky/engine/core/html/imports/HTMLImportsController.h"
#include "sky/engine/core/page/Page.h"

namespace blink {

StyleEngine::StyleEngine(Document& document)
    : m_document(&document)
    , m_documentStyleSheetCollection(StyleSheetCollection::create(document))
    , m_ignorePendingStylesheets(false)
    // We don't need to create CSSFontSelector for imported document or
    // HTMLTemplateElement's document, because those documents have no frame.
    , m_fontSelector(document.frame() ? CSSFontSelector::create(&document) : nullptr)
{
    if (m_fontSelector)
        m_fontSelector->registerForInvalidationCallbacks(this);
}

StyleEngine::~StyleEngine()
{
}

void StyleEngine::detachFromDocument()
{
    // Cleanup is performed eagerly when the StyleEngine is removed from the
    // document. The StyleEngine is unreachable after this, since only the
    // document has a reference to it.

    if (m_fontSelector) {
        m_fontSelector->clearDocument();
        m_fontSelector->unregisterForInvalidationCallbacks(this);
    }

    // Decrement reference counts for things we could be keeping alive.
    m_fontSelector.clear();
    m_resolver.clear();
    m_styleSheetCollectionMap.clear();
    for (ScopedStyleResolverSet::iterator it = m_scopedStyleResolvers.begin(); it != m_scopedStyleResolvers.end(); ++it)
        const_cast<TreeScope&>((*it)->treeScope()).clearScopedStyleResolver();
    m_scopedStyleResolvers.clear();
}

const Vector<RefPtr<CSSStyleSheet>>& StyleEngine::activeAuthorStyleSheetsFor(TreeScope& treeScope)
{
    if (treeScope == m_document)
        return documentStyleSheetCollection()->activeAuthorStyleSheets();
    return ensureStyleSheetCollectionFor(treeScope)->activeAuthorStyleSheets();
}

void StyleEngine::insertTreeScopeInDocumentOrder(TreeScopeSet& treeScopes, TreeScope* treeScope)
{
    if (treeScopes.isEmpty()) {
        treeScopes.add(treeScope);
        return;
    }
    if (treeScopes.contains(treeScope))
        return;

    TreeScopeSet::iterator begin = treeScopes.begin();
    TreeScopeSet::iterator end = treeScopes.end();
    TreeScopeSet::iterator it = end;
    TreeScope* followingTreeScope = 0;
    do {
        --it;
        TreeScope* n = *it;
        unsigned short position = n->comparePosition(*treeScope);
        if (position & Node::DOCUMENT_POSITION_FOLLOWING) {
            treeScopes.insertBefore(followingTreeScope, treeScope);
            return;
        }
        followingTreeScope = n;
    } while (it != begin);

    treeScopes.insertBefore(followingTreeScope, treeScope);
}

StyleSheetCollection* StyleEngine::ensureStyleSheetCollectionFor(TreeScope& treeScope)
{
    if (treeScope == m_document)
        return documentStyleSheetCollection();

    StyleSheetCollectionMap::AddResult result = m_styleSheetCollectionMap.add(&treeScope, nullptr);
    if (result.isNewEntry)
        result.storedValue->value = StyleSheetCollection::create(treeScope);
    return result.storedValue->value.get();
}

StyleSheetCollection* StyleEngine::styleSheetCollectionFor(TreeScope& treeScope)
{
    if (treeScope == m_document)
        return documentStyleSheetCollection();

    StyleSheetCollectionMap::iterator it = m_styleSheetCollectionMap.find(&treeScope);
    if (it == m_styleSheetCollectionMap.end())
        return 0;
    return it->value.get();
}

void StyleEngine::modifiedStyleSheet(CSSStyleSheet* sheet)
{
    if (!sheet)
        return;

    Node* node = sheet->ownerNode();
    if (!node || !node->inDocument())
        return;

    TreeScope& treeScope = isHTMLStyleElement(*node) ? node->treeScope() : *m_document;
    ASSERT(isHTMLStyleElement(node) || treeScope == m_document);

    markTreeScopeDirty(treeScope);
}

void StyleEngine::addStyleSheetCandidateNode(Node* node, bool createdByParser)
{
    if (!node->inDocument())
        return;

    TreeScope& treeScope = isHTMLStyleElement(*node) ? node->treeScope() : *m_document;
    ASSERT(isHTMLStyleElement(node) || treeScope == m_document);
    StyleSheetCollection* collection = ensureStyleSheetCollectionFor(treeScope);
    ASSERT(collection);
    collection->addStyleSheetCandidateNode(node, createdByParser);

    markTreeScopeDirty(treeScope);
    if (treeScope != m_document)
        insertTreeScopeInDocumentOrder(m_activeTreeScopes, &treeScope);
}

void StyleEngine::removeStyleSheetCandidateNode(Node* node, ContainerNode* scopingNode, TreeScope& treeScope)
{
    ASSERT(isHTMLStyleElement(node) || treeScope == m_document);

    StyleSheetCollection* collection = styleSheetCollectionFor(treeScope);
    ASSERT(collection);
    collection->removeStyleSheetCandidateNode(node, scopingNode);

    markTreeScopeDirty(treeScope);
    m_activeTreeScopes.remove(&treeScope);
}

void StyleEngine::updateActiveStyleSheets()
{
    ASSERT(!m_document->inStyleRecalc());

    if (!m_document->isActive())
        return;

    documentStyleSheetCollection()->updateActiveStyleSheets(this);

    TreeScopeSet treeScopes = m_activeTreeScopes;
    HashSet<TreeScope*> treeScopesRemoved;

    for (TreeScopeSet::iterator it = treeScopes.begin(); it != treeScopes.end(); ++it) {
        TreeScope* treeScope = *it;
        ASSERT(treeScope != m_document);
        StyleSheetCollection* collection = styleSheetCollectionFor(*treeScope);
        ASSERT(collection);
        collection->updateActiveStyleSheets(this);
        if (!collection->hasStyleSheetCandidateNodes())
            treeScopesRemoved.add(treeScope);
    }
    m_activeTreeScopes.removeAll(treeScopesRemoved);

    m_dirtyTreeScopes.clear();
}

void StyleEngine::didRemoveShadowRoot(ShadowRoot* shadowRoot)
{
    if (shadowRoot->scopedStyleResolver())
        removeScopedStyleResolver(shadowRoot->scopedStyleResolver());
    m_styleSheetCollectionMap.remove(shadowRoot);
}

void StyleEngine::appendActiveAuthorStyleSheets()
{
    m_resolver->appendAuthorStyleSheets(documentStyleSheetCollection()->activeAuthorStyleSheets());

    TreeScopeSet::iterator begin = m_activeTreeScopes.begin();
    TreeScopeSet::iterator end = m_activeTreeScopes.end();
    for (TreeScopeSet::iterator it = begin; it != end; ++it) {
        if (StyleSheetCollection* collection = m_styleSheetCollectionMap.get(*it))
            m_resolver->appendAuthorStyleSheets(collection->activeAuthorStyleSheets());
    }
    m_resolver->finishAppendAuthorStyleSheets();
}

void StyleEngine::createResolver()
{
    // It is a programming error to attempt to resolve style on a Document
    // which is not in a frame. Code which hits this should have checked
    // Document::isActive() before calling into code which could get here.

    ASSERT(m_document->frame());

    m_resolver = adoptPtr(new StyleResolver(*m_document));
    addScopedStyleResolver(&m_document->ensureScopedStyleResolver());

    appendActiveAuthorStyleSheets();
}

void StyleEngine::clearResolver()
{
    ASSERT(!m_document->inStyleRecalc());

    for (ScopedStyleResolverSet::iterator it = m_scopedStyleResolvers.begin(); it != m_scopedStyleResolvers.end(); ++it)
        const_cast<TreeScope&>((*it)->treeScope()).clearScopedStyleResolver();
    m_scopedStyleResolvers.clear();
    m_resolver.clear();
}

unsigned StyleEngine::resolverAccessCount() const
{
    return m_resolver ? m_resolver->accessCount() : 0;
}

void StyleEngine::didDetach()
{
    clearResolver();
}

void StyleEngine::resolverChanged()
{
    // Don't bother updating, since we haven't loaded all our style info yet
    // and haven't calculated the style selector for the first time.
    if (!m_document->isActive()) {
        clearResolver();
        return;
    }

    updateActiveStyleSheets();
}

void StyleEngine::clearFontCache()
{
    if (m_fontSelector)
        m_fontSelector->fontFaceCache()->clearCSSConnected();
    if (m_resolver)
        m_resolver->invalidateMatchedPropertiesCache();
}

void StyleEngine::updateGenericFontFamilySettings()
{
    // FIXME: we should not update generic font family settings when
    // document is inactive.
    ASSERT(m_document->isActive());

    if (!m_fontSelector)
        return;

    m_fontSelector->updateGenericFontFamilySettings(*m_document);
    if (m_resolver)
        m_resolver->invalidateMatchedPropertiesCache();
}

void StyleEngine::removeFontFaceRules(const Vector<RawPtr<const StyleRuleFontFace> >& fontFaceRules)
{
    if (!m_fontSelector)
        return;

    FontFaceCache* cache = m_fontSelector->fontFaceCache();
    for (unsigned i = 0; i < fontFaceRules.size(); ++i)
        cache->remove(fontFaceRules[i]);
    if (m_resolver)
        m_resolver->invalidateMatchedPropertiesCache();
}

void StyleEngine::markTreeScopeDirty(TreeScope& scope)
{
    // TODO(esprehn): Make document not special.
    if (scope == m_document)
        return;
    m_dirtyTreeScopes.add(&scope);
}

PassRefPtr<CSSStyleSheet> StyleEngine::createSheet(Element* e, const String& text)
{
    RefPtr<CSSStyleSheet> styleSheet;
    AtomicString textContent(text);

    HashMap<AtomicString, RawPtr<StyleSheetContents> >::AddResult result = m_textToSheetCache.add(textContent, nullptr);
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
    HashMap<RawPtr<StyleSheetContents>, AtomicString>::iterator it = m_sheetToTextCache.find(contents);
    if (it == m_sheetToTextCache.end())
        return;

    m_textToSheetCache.remove(it->value);
    m_sheetToTextCache.remove(contents);
}

void StyleEngine::collectScopedStyleFeaturesTo(RuleFeatureSet& features) const
{
    HashSet<const StyleSheetContents*> visitedSharedStyleSheetContents;
    for (ScopedStyleResolverSet::iterator it = m_scopedStyleResolvers.begin(); it != m_scopedStyleResolvers.end(); ++it)
        (*it)->collectFeaturesTo(features, visitedSharedStyleSheetContents);
}

void StyleEngine::fontsNeedUpdate(CSSFontSelector*)
{
    if (m_resolver)
        m_resolver->invalidateMatchedPropertiesCache();
    m_document->setNeedsStyleRecalc(SubtreeStyleChange);
}

}
