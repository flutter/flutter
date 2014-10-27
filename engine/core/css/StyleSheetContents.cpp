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

#include "config.h"
#include "core/css/StyleSheetContents.h"

#include "core/css/parser/BisonCSSParser.h"
#include "core/css/CSSStyleSheet.h"
#include "core/css/MediaList.h"
#include "core/css/StylePropertySet.h"
#include "core/css/StyleRule.h"
#include "core/dom/Document.h"
#include "core/dom/Node.h"
#include "core/dom/StyleEngine.h"
#include "core/frame/UseCounter.h"
#include "platform/TraceEvent.h"
#include "wtf/Deque.h"

namespace blink {

// Rough size estimate for the memory cache.
unsigned StyleSheetContents::estimatedSizeInBytes() const
{
    // Note that this does not take into account size of the strings hanging from various objects.
    // The assumption is that nearly all of of them are atomic and would exist anyway.
    unsigned size = sizeof(*this);

    // FIXME: This ignores the children of media rules.
    // Most rules are StyleRules.
    size += ruleCount() * StyleRule::averageSizeInBytes();
    return size;
}

StyleSheetContents::StyleSheetContents(const String& originalURL, const CSSParserContext& context)
    : m_originalURL(originalURL)
    , m_hasSyntacticallyValidCSSHeader(true)
    , m_didLoadErrorOccur(false)
    , m_usesRemUnits(false)
    , m_isMutable(false)
    , m_isInMemoryCache(false)
    , m_hasFontFaceRule(false)
    , m_hasMediaQueries(false)
    , m_hasSingleOwnerDocument(true)
    , m_parserContext(context)
{
}

StyleSheetContents::StyleSheetContents(const StyleSheetContents& o)
    : m_originalURL(o.m_originalURL)
    , m_childRules(o.m_childRules.size())
    , m_namespaces(o.m_namespaces)
    , m_hasSyntacticallyValidCSSHeader(o.m_hasSyntacticallyValidCSSHeader)
    , m_didLoadErrorOccur(false)
    , m_usesRemUnits(o.m_usesRemUnits)
    , m_isMutable(false)
    , m_isInMemoryCache(false)
    , m_hasFontFaceRule(o.m_hasFontFaceRule)
    , m_hasMediaQueries(o.m_hasMediaQueries)
    , m_hasSingleOwnerDocument(true)
    , m_parserContext(o.m_parserContext)
{
    ASSERT(o.isCacheable());

    for (unsigned i = 0; i < m_childRules.size(); ++i)
        m_childRules[i] = o.m_childRules[i]->copy();
}

StyleSheetContents::~StyleSheetContents()
{
#if !ENABLE(OILPAN)
    clearRules();
#endif
}

void StyleSheetContents::setHasSyntacticallyValidCSSHeader(bool isValidCss)
{
    if (!isValidCss) {
        if (Document* document = clientSingleOwnerDocument())
            removeSheetFromCache(document);
    }
    m_hasSyntacticallyValidCSSHeader = isValidCss;
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
    if (m_didLoadErrorOccur)
        return false;
    // It is not the original sheet anymore.
    if (m_isMutable)
        return false;
    // If the header is valid we are not going to need to check the SecurityOrigin.
    // FIXME: Valid mime type avoids the check too.
    if (!m_hasSyntacticallyValidCSSHeader)
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

bool StyleSheetContents::wrapperInsertRule(PassRefPtr<StyleRuleBase> rule, unsigned index)
{
    ASSERT(m_isMutable);
    ASSERT_WITH_SECURITY_IMPLICATION(index <= ruleCount());

    if (rule->isMediaRule())
        setHasMediaQueries();

    if (rule->isFontFaceRule())
        setHasFontFaceRule(true);
    m_childRules.insert(index, rule);
    return true;
}

void StyleSheetContents::wrapperDeleteRule(unsigned index)
{
    ASSERT(m_isMutable);
    ASSERT_WITH_SECURITY_IMPLICATION(index < ruleCount());

    if (m_childRules[index]->isFontFaceRule())
        notifyRemoveFontFaceRule(toStyleRuleFontFace(m_childRules[index].get()));
    m_childRules.remove(index);
}

bool StyleSheetContents::parseString(const String& sheetText)
{
    return parseStringAtPosition(sheetText, TextPosition::minimumPosition(), false);
}

bool StyleSheetContents::parseStringAtPosition(const String& sheetText, const TextPosition& startPosition, bool createdByParser)
{
    CSSParserContext context(parserContext(), UseCounter::getFrom(this));
    BisonCSSParser p(context);
    p.parseSheet(this, sheetText, startPosition, 0, createdByParser);

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

static bool childRulesHaveFailedOrCanceledSubresources(const Vector<RefPtr<StyleRuleBase> >& rules)
{
    for (unsigned i = 0; i < rules.size(); ++i) {
        const StyleRuleBase* rule = rules[i].get();
        switch (rule->type()) {
        case StyleRuleBase::Style:
            if (toStyleRule(rule)->properties().hasFailedOrCanceledSubresources())
                return true;
            break;
        case StyleRuleBase::FontFace:
            if (toStyleRuleFontFace(rule)->properties().hasFailedOrCanceledSubresources())
                return true;
            break;
        case StyleRuleBase::Media:
            if (childRulesHaveFailedOrCanceledSubresources(toStyleRuleMedia(rule)->childRules()))
                return true;
            break;
        case StyleRuleBase::Keyframes:
        case StyleRuleBase::Unknown:
        case StyleRuleBase::Keyframe:
        case StyleRuleBase::Supports:
        case StyleRuleBase::Filter:
            break;
        }
    }
    return false;
}

bool StyleSheetContents::hasFailedOrCanceledSubresources() const
{
    ASSERT(isCacheable());
    return childRulesHaveFailedOrCanceledSubresources(m_childRules);
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

void StyleSheetContents::addedToMemoryCache()
{
    ASSERT(!m_isInMemoryCache);
    ASSERT(isCacheable());
    m_isInMemoryCache = true;
}

void StyleSheetContents::removedFromMemoryCache()
{
    ASSERT(m_isInMemoryCache);
    ASSERT(isCacheable());
    m_isInMemoryCache = false;
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

static void findFontFaceRulesFromRules(const Vector<RefPtr<StyleRuleBase> >& rules, Vector<RawPtr<const StyleRuleFontFace> >& fontFaceRules)
{
    for (unsigned i = 0; i < rules.size(); ++i) {
        StyleRuleBase* rule = rules[i].get();

        if (rule->isFontFaceRule()) {
            fontFaceRules.append(toStyleRuleFontFace(rule));
        } else if (rule->isMediaRule()) {
            StyleRuleMedia* mediaRule = toStyleRuleMedia(rule);
            // We cannot know whether the media rule matches or not, but
            // for safety, remove @font-face in the media rule (if exists).
            findFontFaceRulesFromRules(mediaRule->childRules(), fontFaceRules);
        }
    }
}

void StyleSheetContents::findFontFaceRules(Vector<RawPtr<const StyleRuleFontFace> >& fontFaceRules)
{
    findFontFaceRulesFromRules(childRules(), fontFaceRules);
}

void StyleSheetContents::trace(Visitor* visitor)
{
#if ENABLE(OILPAN)
    visitor->trace(m_childRules);
    visitor->trace(m_loadingClients);
    visitor->trace(m_completedClients);
    visitor->trace(m_ruleSet);
#endif
}

}
