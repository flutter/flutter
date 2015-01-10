/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_CSS_RESOLVER_MATCHREQUEST_H_
#define SKY_ENGINE_CORE_CSS_RESOLVER_MATCHREQUEST_H_

#include "sky/engine/core/css/CSSStyleSheet.h"
#include "sky/engine/core/css/RuleSet.h"

namespace blink {

class MatchRequest {
    STACK_ALLOCATED();
public:
    MatchRequest(RuleSet* ruleSet, const CSSStyleSheet* cssSheet = 0, unsigned styleSheetIndex = 0)
        : ruleSet(ruleSet)
        , styleSheet(cssSheet)
        , styleSheetIndex(styleSheetIndex)
    {
        // Now that we're about to read from the RuleSet, we're done adding more
        // rules to the set and we should make sure it's compacted.
        ruleSet->compactRulesIfNeeded();
    }

    RawPtr<const RuleSet> ruleSet;
    RawPtr<const CSSStyleSheet> styleSheet;
    const unsigned styleSheetIndex;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_RESOLVER_MATCHREQUEST_H_
