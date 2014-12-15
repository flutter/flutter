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

StyleSheetContents::StyleSheetContents(const CSSParserContext& context)
    : m_usesRemUnits(false)
    , m_hasMediaQueries(false)
    , m_parserContext(context)
{
}

StyleSheetContents::~StyleSheetContents()
{
    // TODO(esprehn): Why is this here? The rules will be cleared immediately
    // after this destructor runs anyway.
    m_childRules.clear();
}

void StyleSheetContents::parserAppendRule(PassRefPtr<StyleRuleBase> rule)
{
    if (rule->isMediaRule())
        setHasMediaQueries();
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

bool StyleSheetContents::parseString(const String& sheetText)
{
    CSSParserContext context(parserContext(), UseCounter::getFrom(this));
    BisonCSSParser p(context);
    p.parseSheet(this, sheetText);
    return true;
}

void StyleSheetContents::registerClient(CSSStyleSheet* sheet)
{
    ASSERT(!m_clients.contains(sheet));

    // InspectorCSSAgent::buildObjectForRule creates CSSStyleSheet without any owner node.
    if (!sheet->ownerDocument())
        return;
    m_clients.add(sheet);
}

void StyleSheetContents::unregisterClient(CSSStyleSheet* sheet)
{
    m_clients.remove(sheet);

    if (!sheet->ownerDocument() || !m_clients.isEmpty())
        return;
    sheet->ownerDocument()->styleEngine()->removeSheet(this);
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

void StyleSheetContents::clearRuleSet()
{
    // Don't want to clear the StyleResolver if the RuleSet hasn't been created
    // since we only clear the StyleResolver so that it's members are properly
    // updated in ScopedStyleResolver::addRulesFromSheet.
    if (!m_ruleSet)
        return;

    // Clearing the ruleSet means we need to recreate the styleResolver data structures.
    // See the StyleResolver calls in ScopedStyleResolver::addRulesFromSheet.
    for (RawPtr<CSSStyleSheet> client : m_clients) {
        if (Document* document = client->ownerDocument())
            document->styleEngine()->clearResolver();
    }
    m_ruleSet.clear();
}

}
