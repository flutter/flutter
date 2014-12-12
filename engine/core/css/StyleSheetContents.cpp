/*
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2006, 2007, 2012 Apple Inc. All rights reserved.
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
#include "sky/engine/core/css/StyleSheetContents.h"

#include "sky/engine/core/css/CSSStyleSheet.h"
#include "sky/engine/core/css/MediaList.h"
#include "sky/engine/core/css/StylePropertySet.h"
#include "sky/engine/core/css/StyleRule.h"
#include "sky/engine/core/css/parser/BisonCSSParser.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Node.h"
#include "sky/engine/core/dom/StyleEngine.h"
#include "sky/engine/core/frame/UseCounter.h"
#include "sky/engine/platform/TraceEvent.h"
#include "sky/engine/wtf/Deque.h"

namespace blink {

StyleSheetContents::StyleSheetContents(const String& originalURL, const CSSParserContext& context)
    : m_usesRemUnits(false)
    , m_hasMediaQueries(false)
    , m_hasSingleOwnerDocument(true)
    , m_originalURL(originalURL)
    , m_parserContext(context)
{
}

StyleSheetContents::~StyleSheetContents()
{
#if !ENABLE(OILPAN)
    clearRules();
#endif
}

bool StyleSheetContents::isCacheable() const
{
    // FIXME: StyleSheets with media queries can't be cached because their RuleSet
    // is processed differently based off the media queries, which might resolve
    // differently depending on the context of the parent CSSStyleSheet (e.g.
    // if they are in differently sized iframes). Once RuleSets are media query
    // agnostic, we can restore sharing of StyleSheetContents with medea queries.
    if (m_hasMediaQueries)
        return false;
    return true;
}

void StyleSheetContents::parserAppendRule(PassRefPtr<StyleRuleBase> rule)
{
    // Add warning message to inspector if dpi/dpcm values are used for screen media.
    if (rule->isMediaRule()) {
        setHasMediaQueries();
        reportMediaQueryWarningIfNeeded(singleOwnerDocument(), toStyleRuleMedia(rule.get())->mediaQueries());
    }

    m_childRules.append(rule);
}

void StyleSheetContents::setHasMediaQueries()
{
    m_hasMediaQueries = true;
}

StyleRuleBase* StyleSheetContents::ruleAt(unsigned index) const
{
    ASSERT_WITH_SECURITY_IMPLICATION(index < ruleCount());
    return m_childRules[index].get();
}

unsigned StyleSheetContents::ruleCount() const
{
    return m_childRules.size();
}

void StyleSheetContents::clearRules()
{
    m_childRules.clear();
}

bool StyleSheetContents::parseString(const String& sheetText)
{
    CSSParserContext context(parserContext(), UseCounter::getFrom(this));
    BisonCSSParser p(context);
    p.parseSheet(this, sheetText);
    return true;
}

bool StyleSheetContents::hasSingleOwnerNode() const
{
    return hasOneClient();
}

Node* StyleSheetContents::singleOwnerNode() const
{
    if (!hasOneClient())
        return 0;
    if (m_loadingClients.size())
        return (*m_loadingClients.begin())->ownerNode();
    return (*m_completedClients.begin())->ownerNode();
}

Document* StyleSheetContents::singleOwnerDocument() const
{
    return clientSingleOwnerDocument();
}

KURL StyleSheetContents::completeURL(const String& url) const
{
    // FIXME: This is only OK when we have a singleOwnerNode, right?
    return m_parserContext.completeURL(url);
}

Document* StyleSheetContents::clientSingleOwnerDocument() const
{
    if (!m_hasSingleOwnerDocument || clientSize() <= 0)
        return 0;

    if (m_loadingClients.size())
        return (*m_loadingClients.begin())->ownerDocument();
    return (*m_completedClients.begin())->ownerDocument();
}

void StyleSheetContents::registerClient(CSSStyleSheet* sheet)
{
    ASSERT(!m_loadingClients.contains(sheet) && !m_completedClients.contains(sheet));

    // InspectorCSSAgent::buildObjectForRule creates CSSStyleSheet without any owner node.
    if (!sheet->ownerDocument())
        return;

    if (Document* document = clientSingleOwnerDocument()) {
        if (sheet->ownerDocument() != document)
            m_hasSingleOwnerDocument = false;
    }
    m_loadingClients.add(sheet);
}

void StyleSheetContents::unregisterClient(CSSStyleSheet* sheet)
{
    m_loadingClients.remove(sheet);
    m_completedClients.remove(sheet);

    if (!sheet->ownerDocument() || !m_loadingClients.isEmpty() || !m_completedClients.isEmpty())
        return;

    if (m_hasSingleOwnerDocument)
        removeSheetFromCache(sheet->ownerDocument());
    m_hasSingleOwnerDocument = true;
}

void StyleSheetContents::removeSheetFromCache(Document* document)
{
    ASSERT(document);
    document->styleEngine()->removeSheet(this);
}

void StyleSheetContents::shrinkToFit()
{
    m_childRules.shrinkToFit();
}

RuleSet& StyleSheetContents::ensureRuleSet(const MediaQueryEvaluator& medium, AddRuleFlags addRuleFlags)
{
    if (!m_ruleSet) {
        m_ruleSet = RuleSet::create();
        m_ruleSet->addRulesFromSheet(this, medium, addRuleFlags);
    }
    return *m_ruleSet.get();
}

static void clearResolvers(HashSet<RawPtr<CSSStyleSheet> >& clients)
{
    for (HashSet<RawPtr<CSSStyleSheet> >::iterator it = clients.begin(); it != clients.end(); ++it) {
        if (Document* document = (*it)->ownerDocument())
            document->styleEngine()->clearResolver();
    }
}

void StyleSheetContents::clearRuleSet()
{
    // Don't want to clear the StyleResolver if the RuleSet hasn't been created
    // since we only clear the StyleResolver so that it's members are properly
    // updated in ScopedStyleResolver::addRulesFromSheet.
    if (!m_ruleSet)
        return;

    // Clearing the ruleSet means we need to recreate the styleResolver data structures.
    // See the StyleResolver calls in ScopedStyleResolver::addRulesFromSheet.
    clearResolvers(m_loadingClients);
    clearResolvers(m_completedClients);
    m_ruleSet.clear();
}

static void removeFontFaceRules(HashSet<RawPtr<CSSStyleSheet> >& clients, const StyleRuleFontFace* fontFaceRule)
{
    for (HashSet<RawPtr<CSSStyleSheet> >::iterator it = clients.begin(); it != clients.end(); ++it) {
        if (Node* ownerNode = (*it)->ownerNode())
            ownerNode->document().styleEngine()->removeFontFaceRules(Vector<RawPtr<const StyleRuleFontFace> >(1, fontFaceRule));
    }
}

void StyleSheetContents::notifyRemoveFontFaceRule(const StyleRuleFontFace* fontFaceRule)
{
    removeFontFaceRules(m_loadingClients, fontFaceRule);
    removeFontFaceRules(m_completedClients, fontFaceRule);
}

}
