/**
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * (C) 2002-2003 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2002, 2005, 2006, 2012 Apple Computer, Inc.
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
#include "core/css/CSSRuleList.h"

#include "core/css/CSSRule.h"

namespace blink {

CSSRuleList::CSSRuleList()
{
    ScriptWrappable::init(this);
}

CSSRuleList::~CSSRuleList()
{
}

StaticCSSRuleList::StaticCSSRuleList()
#if !ENABLE(OILPAN)
    : m_refCount(1)
#endif
{
}

StaticCSSRuleList::~StaticCSSRuleList()
{
}

#if !ENABLE(OILPAN)
void StaticCSSRuleList::deref()
{
    ASSERT(m_refCount);
    if (!--m_refCount)
        delete this;
}
#endif

void StaticCSSRuleList::trace(Visitor* visitor)
{
    visitor->trace(m_rules);
    CSSRuleList::trace(visitor);
}


} // namespace blink
