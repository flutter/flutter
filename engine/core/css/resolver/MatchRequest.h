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

#ifndef MatchRequest_h
#define MatchRequest_h

#include "core/css/CSSStyleSheet.h"
#include "core/css/RuleSet.h"

namespace blink {

class ContainerNode;

class MatchRequest {
    STACK_ALLOCATED();
public:
    MatchRequest(RuleSet* ruleSet, bool includeEmptyRules = false, const ContainerNode* scope = 0, const CSSStyleSheet* cssSheet = 0, bool elementApplyAuthorStyles = true, unsigned styleSheetIndex = 0)
        : ruleSet(ruleSet)
        , includeEmptyRules(includeEmptyRules)
        , scope(scope)
        , styleSheet(cssSheet)
        , elementApplyAuthorStyles(elementApplyAuthorStyles)
        , styleSheetIndex(styleSheetIndex)
    {
        // Now that we're about to read from the RuleSet, we're done adding more
        // rules to the set and we should make sure it's compacted.
        ruleSet->compactRulesIfNeeded();
    }

    RawPtrWillBeMember<const RuleSet> ruleSet;
    const bool includeEmptyRules;
    RawPtrWillBeMember<const ContainerNode> scope;
    RawPtrWillBeMember<const CSSStyleSheet> styleSheet;
    const bool elementApplyAuthorStyles;
    const unsigned styleSheetIndex;
};

} // namespace blink

#endif // MatchRequest_h
