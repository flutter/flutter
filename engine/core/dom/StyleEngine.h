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

#ifndef SKY_ENGINE_CORE_DOM_STYLEENGINE_H_
#define SKY_ENGINE_CORE_DOM_STYLEENGINE_H_

#include "sky/engine/core/css/CSSFontSelectorClient.h"
#include "sky/engine/core/css/resolver/StyleResolver.h"
#include "sky/engine/wtf/FastAllocBase.h"
#include "sky/engine/wtf/ListHashSet.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/engine/wtf/TemporaryChange.h"
#include "sky/engine/wtf/Vector.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

class CSSFontSelector;
class CSSStyleSheet;
class Document;
class Node;
class RuleFeatureSet;
class StyleRuleFontFace;
class StyleSheetContents;

class StyleEngine final : public CSSFontSelectorClient  {
    WTF_MAKE_FAST_ALLOCATED;
public:

    class IgnoringPendingStylesheet : public TemporaryChange<bool> {
    public:
        IgnoringPendingStylesheet(StyleEngine* engine)
            : TemporaryChange<bool>(engine->m_ignorePendingStylesheets, true)
        {
        }
    };

    friend class IgnoringPendingStylesheet;

    static PassOwnPtr<StyleEngine> create(Document& document) { return adoptPtr(new StyleEngine(document)); }

    ~StyleEngine();

    void detachFromDocument();

    void addStyleSheetCandidateNode(Node*, bool createdByParser);
    void removeStyleSheetCandidateNode(Node*, ContainerNode* scopingNode, TreeScope&);

    void updateActiveStyleSheets();

    bool ignoringPendingStylesheets() const { return m_ignorePendingStylesheets; }

    // FIXME(sky): Remove this and ::first-line.
    bool usesFirstLineRules() const { return false; }

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

    CSSFontSelector* fontSelector() { return m_fontSelector.get(); }
    void removeFontFaceRules(const Vector<RawPtr<const StyleRuleFontFace> >&);
    void clearFontCache();
    // updateGenericFontFamilySettings is used from WebSettingsImpl.
    void updateGenericFontFamilySettings();

    void didDetach();
    void resolverChanged();
    unsigned resolverAccessCount() const;

    PassRefPtr<CSSStyleSheet> createSheet(Element*, const String& text);
    void removeSheet(StyleSheetContents*);

    void collectScopedStyleFeaturesTo(RuleFeatureSet&) const;

private:
    // CSSFontSelectorClient implementation.
    virtual void fontsNeedUpdate(CSSFontSelector*) override;

private:
    explicit StyleEngine(Document&);

    void createResolver();

    RawPtr<Document> m_document;

    typedef ListHashSet<TreeScope*, 16> TreeScopeSet;
    TreeScopeSet m_activeTreeScopes;

    bool m_ignorePendingStylesheets;
    OwnPtr<StyleResolver> m_resolver;

    RefPtr<CSSFontSelector> m_fontSelector;

    HashMap<AtomicString, StyleSheetContents*> m_textToSheetCache;
    HashMap<StyleSheetContents*, AtomicString> m_sheetToTextCache;
};

}

#endif  // SKY_ENGINE_CORE_DOM_STYLEENGINE_H_
