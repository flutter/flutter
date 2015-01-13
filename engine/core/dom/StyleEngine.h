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
    static PassOwnPtr<StyleEngine> create(Document& document) { return adoptPtr(new StyleEngine(document)); }

    ~StyleEngine();

    void detachFromDocument();

    void addTreeScope(TreeScope&);
    void removeTreeScope(TreeScope&);

    StyleResolver& resolver() { return *m_resolver; }

    CSSFontSelector* fontSelector() { return m_fontSelector.get(); }
    void clearFontCache();
    // updateGenericFontFamilySettings is used from WebSettingsImpl.
    void updateGenericFontFamilySettings();

    void resolverChanged();
    unsigned resolverAccessCount() const;

    PassRefPtr<CSSStyleSheet> createSheet(Element*, const String& text);
    void removeSheet(StyleSheetContents*);

private:
    // CSSFontSelectorClient implementation.
    virtual void fontsNeedUpdate(CSSFontSelector*) override;

private:
    explicit StyleEngine(Document&);

    void updateActiveStyleSheets();

    RawPtr<Document> m_document;

    typedef ListHashSet<TreeScope*, 16> TreeScopeSet;
    TreeScopeSet m_activeTreeScopes;

    OwnPtr<StyleResolver> m_resolver;

    RefPtr<CSSFontSelector> m_fontSelector;

    HashMap<AtomicString, StyleSheetContents*> m_textToSheetCache;
    HashMap<StyleSheetContents*, AtomicString> m_sheetToTextCache;
};

}

#endif  // SKY_ENGINE_CORE_DOM_STYLEENGINE_H_
