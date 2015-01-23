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
#include "sky/engine/platform/TraceEvent.h"
#include "sky/engine/wtf/Deque.h"

namespace blink {

StyleSheetContents::StyleSheetContents(Document* document, const CSSParserContext& context)
    : m_parserContext(context)
    , m_document(document)
{
}

StyleSheetContents::~StyleSheetContents()
{
    // TODO(esprehn): Why is this here? The rules will be cleared immediately
    // after this destructor runs anyway.
    m_childRules.clear();

    if (m_document && m_document->isActive())
        m_document->styleEngine()->removeSheet(this);
}

void StyleSheetContents::parserAppendRule(PassRefPtr<StyleRuleBase> rule)
{
    m_childRules.append(rule);
}

bool StyleSheetContents::parseString(const String& sheetText)
{
    CSSParserContext context(parserContext());
    BisonCSSParser p(context);
    p.parseSheet(this, sheetText);
    return true;
}

void StyleSheetContents::shrinkToFit()
{
    m_childRules.shrinkToFit();
}

RuleSet& StyleSheetContents::ensureRuleSet()
{
    if (!m_ruleSet) {
        m_ruleSet = RuleSet::create();
        m_ruleSet->addRulesFromSheet(this);
    }
    return *m_ruleSet.get();
}

}
