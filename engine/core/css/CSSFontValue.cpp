/**
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2005, 2006 Apple Computer, Inc.
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
#include "core/css/CSSFontValue.h"

#include "core/css/CSSPrimitiveValue.h"
#include "core/css/CSSValueList.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

String CSSFontValue::customCSSText() const
{
    // font variant weight size / line-height family

    StringBuilder result;

    if (style)
        result.append(style->cssText());
    if (variant) {
        if (!result.isEmpty())
            result.append(' ');
        result.append(variant->cssText());
    }
    if (weight) {
        if (!result.isEmpty())
            result.append(' ');
        result.append(weight->cssText());
    }
    if (stretch) {
        if (!result.isEmpty())
            result.append(' ');
        result.append(stretch->cssText());
    }
    if (size) {
        if (!result.isEmpty())
            result.append(' ');
        result.append(size->cssText());
    }
    if (lineHeight) {
        if (!size)
            result.append(' ');
        result.append('/');
        result.append(lineHeight->cssText());
    }
    if (family) {
        if (!result.isEmpty())
            result.append(' ');
        result.append(family->cssText());
    }

    return result.toString();
}

bool CSSFontValue::equals(const CSSFontValue& other) const
{
    return compareCSSValuePtr(style, other.style)
        && compareCSSValuePtr(variant, other.variant)
        && compareCSSValuePtr(weight, other.weight)
        && compareCSSValuePtr(stretch, other.stretch)
        && compareCSSValuePtr(size, other.size)
        && compareCSSValuePtr(lineHeight, other.lineHeight)
        && compareCSSValuePtr(family, other.family);
}

void CSSFontValue::traceAfterDispatch(Visitor* visitor)
{
    visitor->trace(style);
    visitor->trace(variant);
    visitor->trace(weight);
    visitor->trace(stretch);
    visitor->trace(size);
    visitor->trace(lineHeight);
    visitor->trace(family);
    CSSValue::traceAfterDispatch(visitor);
}

}
