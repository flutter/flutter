/*
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * (C) 2002-2003 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2002, 2005, 2006, 2007, 2012 Apple Inc. All rights reserved.
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
#include "core/css/CSSRule.h"

#include "core/css/CSSStyleSheet.h"
#include "core/css/StyleRule.h"
#include "core/css/StyleSheetContents.h"
#include "platform/NotImplemented.h"

namespace blink {

// VC++ 2013 doesn't support EBCO (Empty Base Class Optimization), and having
// multiple empty base classes makes the size of CSSRule bloat (Note that both
// of GarbageCollectedFinalized and ScriptWrappableBase are empty classes).
// See the following article for details.
// http://social.msdn.microsoft.com/forums/vstudio/en-US/504c6598-6076-4acf-96b6-e6acb475d302/vc-multiple-inheritance-empty-base-classes-bloats-object-size
//
// FIXME: Remove ScriptWrappableBase from the base class list once VC++'s issue
// gets fixed.
// Note that we're going to split CSSRule class into two classes; CSSOMRule
// (assumed name) which derives ScriptWrappable and CSSRule (new one) which
// doesn't derive ScriptWrappable or ScriptWrappableBase. Then, we can safely
// remove ScriptWrappableBase from the base class list.
struct SameSizeAsCSSRule : public RefCountedWillBeGarbageCollectedFinalized<SameSizeAsCSSRule>, public ScriptWrappableBase {
    virtual ~SameSizeAsCSSRule();
    unsigned char bitfields;
    void* pointerUnion;
};

COMPILE_ASSERT(sizeof(CSSRule) == sizeof(SameSizeAsCSSRule), CSSRule_should_stay_small);

COMPILE_ASSERT(StyleRuleBase::Viewport == static_cast<StyleRuleBase::Type>(CSSRule::VIEWPORT_RULE), enums_should_match);

void CSSRule::setCSSText(const String&)
{
    notImplemented();
}

const CSSParserContext& CSSRule::parserContext() const
{
    CSSStyleSheet* styleSheet = parentStyleSheet();
    return styleSheet ? styleSheet->contents()->parserContext() : strictCSSParserContext();
}

void CSSRule::trace(Visitor* visitor)
{
#if ENABLE(OILPAN)
    // This makes the parent link strong, which is different from the
    // pre-oilpan world, where the parent link is mysteriously zeroed under
    // some circumstances.
    if (m_parentIsRule)
        visitor->trace(m_parentRule);
    else
        visitor->trace(m_parentStyleSheet);
#endif
}

} // namespace blink
