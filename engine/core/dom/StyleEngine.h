/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 *           (C) 2006 Alexey Proskuryakov (ap@webkit.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies)
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

#ifndef StyleEngine_h
#define StyleEngine_h

#include "core/css/CSSFontSelectorClient.h"
#include "core/css/resolver/StyleResolver.h"
#include "core/dom/Document.h"
#include "core/dom/DocumentOrderedList.h"
#include "core/dom/DocumentStyleSheetCollection.h"
#include "platform/heap/Handle.h"
#include "wtf/FastAllocBase.h"
#include "wtf/ListHashSet.h"
#include "wtf/RefPtr.h"
#include "wtf/TemporaryChange.h"
#include "wtf/Vector.h"
#include "wtf/text/WTFString.h"

namespace blink {

class CSSFontSelector;
class CSSStyleSheet;
class Node;
class RuleFeatureSet;
class ShadowTreeStyleSheetCollection;
class StyleRuleFontFace;
class StyleSheet;
class StyleSheetContents;

class StyleEngine final : public CSSFontSelectorClient  {
    WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
public:

    class IgnoringPendingStylesheet : public TemporaryChange<bool> {
    public:
        IgnoringPendingStylesheet(StyleEngine* engine)
            : TemporaryChange<bool>(engine->m_ignorePendingStylesheets, true)
        {
        }
    };

    friend class IgnoringPendingStylesheet;

    static PassOwnPtrWillBeRawPtr<StyleEngine> create(Document& document) { return adoptPtrWillBeNoop(new StyleEngine(document)); }

    ~StyleEngine();

#if !ENABLE(OILPAN)
    void detachFromDocument();
#endif

    const WillBeHeapVector<RefPtrWillBeMember<StyleSheet> >& styleSheetsForStyleSheetList(TreeScope&);
    const WillBeHeapVector<RefPtrWillBeMember<CSSStyleSheet> >& activeAuthorStyleSheets() const;

    const WillBeHeapVector<RefPtrWillBeMember<CSSStyleSheet> >& documentAuthorStyleSheets() const { return m_authorStyleSheets; }

    const WillBeHeapVector<RefPtrWillBeMember<CSSStyleSheet> > activeStyleSheetsForInspector() const;

    void modifiedStyleSheet(StyleSheet*);
    void addStyleSheetCandidateNode(Node*, bool createdByParser);
    void removeStyleSheetCandidateNode(Node*);
    void removeStyleSheetCandidateNode(Node*, ContainerNode* scopingNode, TreeScope&);
    void modifiedStyleSheetCandidateNode(Node*);

    void clearMediaQueryRuleSetStyleSheets();
    void updateStyleSheetsInImport(DocumentStyleSheetCollector& parentCollector);
    void updateActiveStyleSheets(StyleResolverUpdateMode);

    bool ignoringPendingStylesheets() const { return m_ignorePendingStylesheets; }

    // FIXME(sky): Remove this and ::first-line.
    bool usesFirstLineRules() const { return false; }

    bool usesRemUnits() const { return m_usesRemUnits; }
    void setUsesRemUnit(bool b) { m_usesRemUnits = b; }

    void didRemoveShadowRoot(ShadowRoot*);
    void appendActiveAuthorStyleSheets();

    StyleResolver* resolver() const
    {
        return m_resolver.get();
    }

    StyleResolver& ensureResolver()
    {
        if (!m_resolver) {
            createResolver();
        } else if (m_resolver->hasPendingAuthorStyleSheets()) {
            m_resolver->appendPendingAuthorStyleSheets();
        }
        return *m_resolver.get();
    }

    bool hasResolver() const { return m_resolver.get(); }
    void clearResolver();
    void clearMasterResolver();

    CSSFontSelector* fontSelector() { return m_fontSelector.get(); }
    void removeFontFaceRules(const WillBeHeapVector<RawPtrWillBeMember<const StyleRuleFontFace> >&);
    void clearFontCache();
    // updateGenericFontFamilySettings is used from WebSettingsImpl.
    void updateGenericFontFamilySettings();

    void didDetach();
    void resolverChanged(StyleResolverUpdateMode);
    unsigned resolverAccessCount() const;

    void markDocumentDirty();

    PassRefPtrWillBeRawPtr<CSSStyleSheet> createSheet(Element*, const String& text, TextPosition startPosition, bool createdByParser);
    void removeSheet(StyleSheetContents*);

    void addScopedStyleResolver(const ScopedStyleResolver* resolver) { m_scopedStyleResolvers.add(resolver); }
    void removeScopedStyleResolver(const ScopedStyleResolver* resolver) { m_scopedStyleResolvers.remove(resolver); }
    bool hasOnlyScopedResolverForDocument() const { return m_scopedStyleResolvers.size() == 1; }
    void collectScopedStyleFeaturesTo(RuleFeatureSet&) const;

    virtual void trace(Visitor*) override;

private:
    // CSSFontSelectorClient implementation.
    virtual void fontsNeedUpdate(CSSFontSelector*) override;

private:
    StyleEngine(Document&);

    TreeScopeStyleSheetCollection* ensureStyleSheetCollectionFor(TreeScope&);
    TreeScopeStyleSheetCollection* styleSheetCollectionFor(TreeScope&);
    bool shouldUpdateDocumentStyleSheetCollection(StyleResolverUpdateMode) const;
    bool shouldUpdateShadowTreeStyleSheetCollection(StyleResolverUpdateMode) const;

    void markTreeScopeDirty(TreeScope&);

    bool isMaster() const { return m_isMaster; }
    Document* master();
    Document& document() const { return *m_document; }

    typedef ListHashSet<TreeScope*, 16> TreeScopeSet;
    static void insertTreeScopeInDocumentOrder(TreeScopeSet&, TreeScope*);
    void clearMediaQueryRuleSetOnTreeScopeStyleSheets(TreeScopeSet treeScopes);

    void createResolver();

    static PassRefPtrWillBeRawPtr<CSSStyleSheet> parseSheet(Element*, const String& text, TextPosition startPosition, bool createdByParser);

    const DocumentStyleSheetCollection* documentStyleSheetCollection() const
    {
        return m_documentStyleSheetCollection.get();
    }

    DocumentStyleSheetCollection* documentStyleSheetCollection()
    {
        return m_documentStyleSheetCollection.get();
    }

    RawPtrWillBeMember<Document> m_document;
    bool m_isMaster;

    WillBeHeapVector<RefPtrWillBeMember<CSSStyleSheet> > m_authorStyleSheets;

    OwnPtrWillBeMember<DocumentStyleSheetCollection> m_documentStyleSheetCollection;

    typedef WillBeHeapHashMap<RawPtrWillBeWeakMember<TreeScope>, OwnPtrWillBeMember<ShadowTreeStyleSheetCollection> > StyleSheetCollectionMap;
    StyleSheetCollectionMap m_styleSheetCollectionMap;
    typedef WillBeHeapHashSet<RawPtrWillBeMember<const ScopedStyleResolver> > ScopedStyleResolverSet;
    ScopedStyleResolverSet m_scopedStyleResolvers;

    bool m_documentScopeDirty;
    TreeScopeSet m_dirtyTreeScopes;
    TreeScopeSet m_activeTreeScopes;

    bool m_usesRemUnits;

    bool m_ignorePendingStylesheets;
    OwnPtrWillBeMember<StyleResolver> m_resolver;

    RefPtrWillBeMember<CSSFontSelector> m_fontSelector;

    WillBeHeapHashMap<AtomicString, RawPtrWillBeMember<StyleSheetContents> > m_textToSheetCache;
    WillBeHeapHashMap<RawPtrWillBeMember<StyleSheetContents>, AtomicString> m_sheetToTextCache;
};

}

#endif
