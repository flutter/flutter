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
#include "sky/engine/core/dom/DocumentStyleSheetCollector.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/ShadowTreeStyleSheetCollection.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/core/html/HTMLStyleElement.h"
#include "sky/engine/core/html/imports/HTMLImportsController.h"
#include "sky/engine/core/page/Page.h"

namespace blink {

StyleEngine::StyleEngine(Document& document)
    : m_document(&document)
    , m_isMaster(!document.importsController() || document.importsController()->master() == &document)
    , m_documentStyleSheetCollection(DocumentStyleSheetCollection::create(document))
    , m_documentScopeDirty(true)
    , m_usesRemUnits(false)
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

#if !ENABLE(OILPAN)
void StyleEngine::detachFromDocument()
{
    // Cleanup is performed eagerly when the StyleEngine is removed from the
    // document. The StyleEngine is unreachable after this, since only the
    // document has a reference to it.
    for (unsigned i = 0; i < m_authorStyleSheets.size(); ++i)
        m_authorStyleSheets[i]->clearOwnerNode();

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
#endif

inline Document* StyleEngine::master()
{
    if (isMaster())
        return m_document;
    HTMLImportsController* import = document().importsController();
    if (!import) // Document::import() can return null while executing its destructor.
        return 0;
    return import->master();
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

TreeScopeStyleSheetCollection* StyleEngine::ensureStyleSheetCollectionFor(TreeScope& treeScope)
{
    if (treeScope == m_document)
        return documentStyleSheetCollection();

    StyleSheetCollectionMap::AddResult result = m_styleSheetCollectionMap.add(&treeScope, nullptr);
    if (result.isNewEntry)
        result.storedValue->value = adoptPtr(new ShadowTreeStyleSheetCollection(toShadowRoot(treeScope)));
    return result.storedValue->value.get();
}

TreeScopeStyleSheetCollection* StyleEngine::styleSheetCollectionFor(TreeScope& treeScope)
{
    if (treeScope == m_document)
        return documentStyleSheetCollection();

    StyleSheetCollectionMap::iterator it = m_styleSheetCollectionMap.find(&treeScope);
    if (it == m_styleSheetCollectionMap.end())
        return 0;
    return it->value.get();
}

const Vector<RefPtr<StyleSheet> >& StyleEngine::styleSheetsForStyleSheetList(TreeScope& treeScope)
{
    if (treeScope == m_document)
        return documentStyleSheetCollection()->styleSheetsForStyleSheetList();

    return ensureStyleSheetCollectionFor(treeScope)->styleSheetsForStyleSheetList();
}

const Vector<RefPtr<CSSStyleSheet> >& StyleEngine::activeAuthorStyleSheets() const
{
    return documentStyleSheetCollection()->activeAuthorStyleSheets();
}

void StyleEngine::modifiedStyleSheet(StyleSheet* sheet)
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
    TreeScopeStyleSheetCollection* collection = ensureStyleSheetCollectionFor(treeScope);
    ASSERT(collection);
    collection->addStyleSheetCandidateNode(node, createdByParser);

    markTreeScopeDirty(treeScope);
    if (treeScope != m_document)
        insertTreeScopeInDocumentOrder(m_activeTreeScopes, &treeScope);
}

void StyleEngine::removeStyleSheetCandidateNode(Node* node)
{
    removeStyleSheetCandidateNode(node, 0, *m_document);
}

void StyleEngine::removeStyleSheetCandidateNode(Node* node, ContainerNode* scopingNode, TreeScope& treeScope)
{
    ASSERT(isHTMLStyleElement(node) || treeScope == m_document);

    TreeScopeStyleSheetCollection* collection = styleSheetCollectionFor(treeScope);
    ASSERT(collection);
    collection->removeStyleSheetCandidateNode(node, scopingNode);

    markTreeScopeDirty(treeScope);
    m_activeTreeScopes.remove(&treeScope);
}

void StyleEngine::modifiedStyleSheetCandidateNode(Node* node)
{
    if (!node->inDocument())
        return;

    TreeScope& treeScope = isHTMLStyleElement(*node) ? node->treeScope() : *m_document;
    ASSERT(isHTMLStyleElement(node) || treeScope == m_document);
    markTreeScopeDirty(treeScope);
}

bool StyleEngine::shouldUpdateDocumentStyleSheetCollection(StyleResolverUpdateMode updateMode) const
{
    return m_documentScopeDirty || updateMode == FullStyleUpdate;
}

bool StyleEngine::shouldUpdateShadowTreeStyleSheetCollection(StyleResolverUpdateMode updateMode) const
{
    return !m_dirtyTreeScopes.isEmpty() || updateMode == FullStyleUpdate;
}

void StyleEngine::clearMediaQueryRuleSetOnTreeScopeStyleSheets(TreeScopeSet treeScopes)
{
    for (TreeScopeSet::iterator it = treeScopes.begin(); it != treeScopes.end(); ++it) {
        TreeScope& treeScope = **it;
        ASSERT(treeScope != m_document);
        ShadowTreeStyleSheetCollection* collection = static_cast<ShadowTreeStyleSheetCollection*>(styleSheetCollectionFor(treeScope));
        ASSERT(collection);
        collection->clearMediaQueryRuleSetStyleSheets();
    }
}

void StyleEngine::clearMediaQueryRuleSetStyleSheets()
{
    documentStyleSheetCollection()->clearMediaQueryRuleSetStyleSheets();
    clearMediaQueryRuleSetOnTreeScopeStyleSheets(m_activeTreeScopes);
    clearMediaQueryRuleSetOnTreeScopeStyleSheets(m_dirtyTreeScopes);
}

void StyleEngine::updateStyleSheetsInImport(DocumentStyleSheetCollector& parentCollector)
{
    ASSERT(!isMaster());
    Vector<RefPtr<StyleSheet> > sheetsForList;
    ImportedDocumentStyleSheetCollector subcollector(parentCollector, sheetsForList);
    documentStyleSheetCollection()->collectStyleSheets(this, subcollector);
    documentStyleSheetCollection()->swapSheetsForSheetList(sheetsForList);
}

void StyleEngine::updateActiveStyleSheets(StyleResolverUpdateMode updateMode)
{
    ASSERT(isMaster());
    ASSERT(!document().inStyleRecalc());

    if (!document().isActive())
        return;

    if (shouldUpdateDocumentStyleSheetCollection(updateMode))
        documentStyleSheetCollection()->updateActiveStyleSheets(this, updateMode);

    if (shouldUpdateShadowTreeStyleSheetCollection(updateMode)) {
        TreeScopeSet treeScopes = updateMode == FullStyleUpdate ? m_activeTreeScopes : m_dirtyTreeScopes;
        HashSet<TreeScope*> treeScopesRemoved;

        for (TreeScopeSet::iterator it = treeScopes.begin(); it != treeScopes.end(); ++it) {
            TreeScope* treeScope = *it;
            ASSERT(treeScope != m_document);
            ShadowTreeStyleSheetCollection* collection = static_cast<ShadowTreeStyleSheetCollection*>(styleSheetCollectionFor(*treeScope));
            ASSERT(collection);
            collection->updateActiveStyleSheets(this, updateMode);
            if (!collection->hasStyleSheetCandidateNodes())
                treeScopesRemoved.add(treeScope);
        }
        m_activeTreeScopes.removeAll(treeScopesRemoved);
    }

    m_usesRemUnits = documentStyleSheetCollection()->usesRemUnits();

    m_dirtyTreeScopes.clear();
    m_documentScopeDirty = false;
}

const Vector<RefPtr<CSSStyleSheet> > StyleEngine::activeStyleSheetsForInspector() const
{
    if (m_activeTreeScopes.isEmpty())
        return documentStyleSheetCollection()->activeAuthorStyleSheets();

    Vector<RefPtr<CSSStyleSheet> > activeStyleSheets;

    activeStyleSheets.appendVector(documentStyleSheetCollection()->activeAuthorStyleSheets());

    TreeScopeSet::const_iterator begin = m_activeTreeScopes.begin();
    TreeScopeSet::const_iterator end = m_activeTreeScopes.end();
    for (TreeScopeSet::const_iterator it = begin; it != end; ++it) {
        if (TreeScopeStyleSheetCollection* collection = m_styleSheetCollectionMap.get(*it))
            activeStyleSheets.appendVector(collection->activeAuthorStyleSheets());
    }

    // FIXME: Inspector needs a vector which has all active stylesheets.
    // However, creating such a large vector might cause performance regression.
    // Need to implement some smarter solution.
    return activeStyleSheets;
}

void StyleEngine::didRemoveShadowRoot(ShadowRoot* shadowRoot)
{
    if (shadowRoot->scopedStyleResolver())
        removeScopedStyleResolver(shadowRoot->scopedStyleResolver());
    m_styleSheetCollectionMap.remove(shadowRoot);
}

void StyleEngine::appendActiveAuthorStyleSheets()
{
    ASSERT(isMaster());

    m_resolver->appendAuthorStyleSheets(documentStyleSheetCollection()->activeAuthorStyleSheets());

    TreeScopeSet::iterator begin = m_activeTreeScopes.begin();
    TreeScopeSet::iterator end = m_activeTreeScopes.end();
    for (TreeScopeSet::iterator it = begin; it != end; ++it) {
        if (TreeScopeStyleSheetCollection* collection = m_styleSheetCollectionMap.get(*it))
            m_resolver->appendAuthorStyleSheets(collection->activeAuthorStyleSheets());
    }
    m_resolver->finishAppendAuthorStyleSheets();
}

void StyleEngine::createResolver()
{
    // It is a programming error to attempt to resolve style on a Document
    // which is not in a frame. Code which hits this should have checked
    // Document::isActive() before calling into code which could get here.

    ASSERT(document().frame());

    m_resolver = adoptPtr(new StyleResolver(*m_document));
    addScopedStyleResolver(&m_document->ensureScopedStyleResolver());

    appendActiveAuthorStyleSheets();
}

void StyleEngine::clearResolver()
{
    ASSERT(!document().inStyleRecalc());
    ASSERT(isMaster() || !m_resolver);

    for (ScopedStyleResolverSet::iterator it = m_scopedStyleResolvers.begin(); it != m_scopedStyleResolvers.end(); ++it)
        const_cast<TreeScope&>((*it)->treeScope()).clearScopedStyleResolver();
    m_scopedStyleResolvers.clear();
    m_resolver.clear();
}

void StyleEngine::clearMasterResolver()
{
    if (Document* master = this->master())
        master->styleEngine()->clearResolver();
}

unsigned StyleEngine::resolverAccessCount() const
{
    return m_resolver ? m_resolver->accessCount() : 0;
}

void StyleEngine::didDetach()
{
    clearResolver();
}

void StyleEngine::resolverChanged(StyleResolverUpdateMode mode)
{
    if (!isMaster()) {
        if (Document* master = this->master())
            master->styleResolverChanged(mode);
        return;
    }

    // Don't bother updating, since we haven't loaded all our style info yet
    // and haven't calculated the style selector for the first time.
    if (!document().isActive()) {
        clearResolver();
        return;
    }

    updateActiveStyleSheets(mode);
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
    ASSERT(document().isActive());

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
    if (scope == m_document) {
        markDocumentDirty();
        return;
    }

    m_dirtyTreeScopes.add(&scope);
}

void StyleEngine::markDocumentDirty()
{
    m_documentScopeDirty = true;
    if (document().importLoader())
        document().importsController()->master()->styleEngine()->markDocumentDirty();
}

static bool isCacheableForStyleElement(const StyleSheetContents& contents)
{
    // Until import rules are supported in cached sheets it's not possible for loading to fail.
    ASSERT(!contents.didLoadErrorOccur());
    // It is not the original sheet anymore.
    if (contents.isMutable())
        return false;
    if (!contents.hasSyntacticallyValidCSSHeader())
        return false;
    return true;
}

PassRefPtr<CSSStyleSheet> StyleEngine::createSheet(Element* e, const String& text, TextPosition startPosition, bool createdByParser)
{
    RefPtr<CSSStyleSheet> styleSheet = nullptr;

    AtomicString textContent(text);

    HashMap<AtomicString, RawPtr<StyleSheetContents> >::AddResult result = m_textToSheetCache.add(textContent, nullptr);
    if (result.isNewEntry || !result.storedValue->value) {
        styleSheet = StyleEngine::parseSheet(e, text, startPosition, createdByParser);
        if (result.isNewEntry && isCacheableForStyleElement(*styleSheet->contents())) {
            result.storedValue->value = styleSheet->contents();
            m_sheetToTextCache.add(styleSheet->contents(), textContent);
        }
    } else {
        StyleSheetContents* contents = result.storedValue->value;
        ASSERT(contents);
        ASSERT(isCacheableForStyleElement(*contents));
        ASSERT(contents->singleOwnerDocument() == e->document());
        styleSheet = CSSStyleSheet::createInline(contents, e, startPosition);
    }

    ASSERT(styleSheet);
    return styleSheet;
}

PassRefPtr<CSSStyleSheet> StyleEngine::parseSheet(Element* e, const String& text, TextPosition startPosition, bool createdByParser)
{
    RefPtr<CSSStyleSheet> styleSheet = nullptr;
    styleSheet = CSSStyleSheet::createInline(e, KURL(), startPosition);
    styleSheet->contents()->parseStringAtPosition(text, startPosition, createdByParser);
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
    if (!document().isActive())
        return;

    if (m_resolver)
        m_resolver->invalidateMatchedPropertiesCache();
    document().setNeedsStyleRecalc(SubtreeStyleChange);
}

}
