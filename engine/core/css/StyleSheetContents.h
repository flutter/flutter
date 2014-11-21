/*
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2006, 2007, 2008, 2009, 2010, 2012 Apple Inc. All rights reserved.
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

#ifndef StyleSheetContents_h
#define StyleSheetContents_h

#include "sky/engine/core/css/RuleSet.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/platform/weborigin/KURL.h"
#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/ListHashSet.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/Vector.h"
#include "sky/engine/wtf/text/AtomicStringHash.h"
#include "sky/engine/wtf/text/StringHash.h"
#include "sky/engine/wtf/text/TextPosition.h"


namespace blink {

class CSSStyleSheet;
class Document;
class Node;
class StyleRuleBase;
class StyleRuleFontFace;

class StyleSheetContents : public RefCounted<StyleSheetContents> {
public:
    static PassRefPtr<StyleSheetContents> create(const CSSParserContext& context)
    {
        return adoptRef(new StyleSheetContents(String(), context));
    }
    static PassRefPtr<StyleSheetContents> create(const String& originalURL, const CSSParserContext& context)
    {
        return adoptRef(new StyleSheetContents(originalURL, context));
    }

    ~StyleSheetContents();

    const CSSParserContext& parserContext() const { return m_parserContext; }

    bool parseString(const String&);
    bool parseStringAtPosition(const String&, const TextPosition&, bool);

    bool isCacheable() const;

    bool hasSingleOwnerNode() const;
    Node* singleOwnerNode() const;
    Document* singleOwnerDocument() const;

    bool hasFailedOrCanceledSubresources() const;

    KURL completeURL(const String& url) const;

    void setHasSyntacticallyValidCSSHeader(bool isValidCss);
    bool hasSyntacticallyValidCSSHeader() const { return m_hasSyntacticallyValidCSSHeader; }

    void setHasFontFaceRule(bool b) { m_hasFontFaceRule = b; }
    bool hasFontFaceRule() const { return m_hasFontFaceRule; }
    void findFontFaceRules(Vector<RawPtr<const StyleRuleFontFace> >& fontFaceRules);

    void parserAppendRule(PassRefPtr<StyleRuleBase>);
    void parserSetUsesRemUnits(bool b) { m_usesRemUnits = b; }

    void clearRules();

    // Rules other than @charset and @import.
    const Vector<RefPtr<StyleRuleBase> >& childRules() const { return m_childRules; }

    // Note that href is the URL that started the redirect chain that led to
    // this style sheet. This property probably isn't useful for much except
    // the JavaScript binding (which needs to use this value for security).
    String originalURL() const { return m_originalURL; }
    const KURL& baseURL() const { return m_parserContext.baseURL(); }

    unsigned ruleCount() const;
    StyleRuleBase* ruleAt(unsigned index) const;

    bool usesRemUnits() const { return m_usesRemUnits; }

    unsigned estimatedSizeInBytes() const;

    bool wrapperInsertRule(PassRefPtr<StyleRuleBase>, unsigned index);
    void wrapperDeleteRule(unsigned index);

    PassRefPtr<StyleSheetContents> copy() const
    {
        return adoptRef(new StyleSheetContents(*this));
    }

    void registerClient(CSSStyleSheet*);
    void unregisterClient(CSSStyleSheet*);
    size_t clientSize() const { return m_loadingClients.size() + m_completedClients.size(); }
    bool hasOneClient() const { return clientSize() == 1; }

    bool isMutable() const { return m_isMutable; }
    void setMutable() { m_isMutable = true; }

    void removeSheetFromCache(Document*);

    bool isInMemoryCache() const { return m_isInMemoryCache; }
    void addedToMemoryCache();
    void removedFromMemoryCache();

    void setHasMediaQueries();
    bool hasMediaQueries() const { return m_hasMediaQueries; }

    bool didLoadErrorOccur() const { return m_didLoadErrorOccur; }

    void shrinkToFit();
    RuleSet& ruleSet() { ASSERT(m_ruleSet); return *m_ruleSet.get(); }
    RuleSet& ensureRuleSet(const MediaQueryEvaluator&, AddRuleFlags);
    void clearRuleSet();

private:
    StyleSheetContents(const String& originalURL, const CSSParserContext&);
    StyleSheetContents(const StyleSheetContents&);
    void notifyRemoveFontFaceRule(const StyleRuleFontFace*);

    Document* clientSingleOwnerDocument() const;

    String m_originalURL;

    Vector<RefPtr<StyleRuleBase> > m_childRules;
    typedef HashMap<AtomicString, AtomicString> PrefixNamespaceURIMap;
    PrefixNamespaceURIMap m_namespaces;

    bool m_hasSyntacticallyValidCSSHeader : 1;
    bool m_didLoadErrorOccur : 1;
    bool m_usesRemUnits : 1;
    bool m_isMutable : 1;
    bool m_isInMemoryCache : 1;
    bool m_hasFontFaceRule : 1;
    bool m_hasMediaQueries : 1;
    bool m_hasSingleOwnerDocument : 1;

    CSSParserContext m_parserContext;

    HashSet<RawPtr<CSSStyleSheet> > m_loadingClients;
    HashSet<RawPtr<CSSStyleSheet> > m_completedClients;
    typedef HashSet<RawPtr<CSSStyleSheet> >::iterator ClientsIterator;

    OwnPtr<RuleSet> m_ruleSet;
};

} // namespace

#endif
