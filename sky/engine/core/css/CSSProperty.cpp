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

#include "sky/engine/core/css/CSSProperty.h"

#include "gen/sky/core/StylePropertyShorthand.h"
#include "sky/engine/core/css/CSSValueList.h"
#include "sky/engine/core/rendering/style/RenderStyleConstants.h"

namespace blink {

struct SameSizeAsCSSProperty {
    uint32_t bitfields;
    void* value;
};

COMPILE_ASSERT(sizeof(CSSProperty) == sizeof(SameSizeAsCSSProperty), CSSProperty_should_stay_small);

CSSPropertyID StylePropertyMetadata::shorthandID() const
{
    if (!m_isSetFromShorthand)
        return CSSPropertyInvalid;

    Vector<StylePropertyShorthand, 4> shorthands;
    getMatchingShorthandsForLonghand(static_cast<CSSPropertyID>(m_propertyID), &shorthands);
    ASSERT(shorthands.size() && m_indexInShorthandsVector >= 0 && m_indexInShorthandsVector < shorthands.size());
    return shorthands.at(m_indexInShorthandsVector).id();
}

void CSSProperty::wrapValueInCommaSeparatedList()
{
    RefPtr<CSSValue> value = m_value.release();
    m_value = CSSValueList::createCommaSeparated();
    toCSSValueList(m_value.get())->append(value.release());
}

enum LogicalBoxSide { BeforeSide, EndSide, AfterSide, StartSide };
enum PhysicalBoxSide { TopSide, RightSide, BottomSide, LeftSide };

static CSSPropertyID resolveToPhysicalProperty(TextDirection direction, LogicalBoxSide logicalSide, const StylePropertyShorthand& shorthand)
{
    if (direction == LTR) {
        // The common case. The logical and physical box sides match.
        // Left = Start, Right = End, Before = Top, After = Bottom
        return shorthand.properties()[logicalSide];
    }

    // FIXME(sky): Remove this. We no longer have logical properties beyond RTL.
    // Start = Right, End = Left, Before = Top, After = Bottom
    switch (logicalSide) {
    case StartSide:
        return shorthand.properties()[RightSide];
    case EndSide:
        return shorthand.properties()[LeftSide];
    case BeforeSide:
        return shorthand.properties()[TopSide];
    default:
        return shorthand.properties()[BottomSide];
    }
}

enum LogicalExtent { LogicalWidth, LogicalHeight };

static CSSPropertyID resolveToPhysicalProperty(LogicalExtent logicalSide, const CSSPropertyID* properties)
{
    // FIXME(sky): Remove
    return properties[logicalSide];
}

static const StylePropertyShorthand& borderDirections()
{
    static const CSSPropertyID properties[4] = { CSSPropertyBorderTop, CSSPropertyBorderRight, CSSPropertyBorderBottom, CSSPropertyBorderLeft };
    DEFINE_STATIC_LOCAL(StylePropertyShorthand, borderDirections, (CSSPropertyBorder, properties, WTF_ARRAY_LENGTH(properties)));
    return borderDirections;
}

CSSPropertyID CSSProperty::resolveDirectionAwareProperty(CSSPropertyID propertyID, TextDirection direction)
{
    switch (propertyID) {
    case CSSPropertyWebkitMarginEnd:
        return resolveToPhysicalProperty(direction, EndSide, marginShorthand());
    case CSSPropertyWebkitMarginStart:
        return resolveToPhysicalProperty(direction, StartSide, marginShorthand());
    case CSSPropertyWebkitMarginBefore:
        return resolveToPhysicalProperty(direction, BeforeSide, marginShorthand());
    case CSSPropertyWebkitMarginAfter:
        return resolveToPhysicalProperty(direction, AfterSide, marginShorthand());
    case CSSPropertyWebkitPaddingEnd:
        return resolveToPhysicalProperty(direction, EndSide, paddingShorthand());
    case CSSPropertyWebkitPaddingStart:
        return resolveToPhysicalProperty(direction, StartSide, paddingShorthand());
    case CSSPropertyWebkitPaddingBefore:
        return resolveToPhysicalProperty(direction, BeforeSide, paddingShorthand());
    case CSSPropertyWebkitPaddingAfter:
        return resolveToPhysicalProperty(direction, AfterSide, paddingShorthand());
    case CSSPropertyWebkitBorderEnd:
        return resolveToPhysicalProperty(direction, EndSide, borderDirections());
    case CSSPropertyWebkitBorderStart:
        return resolveToPhysicalProperty(direction, StartSide, borderDirections());
    case CSSPropertyWebkitBorderBefore:
        return resolveToPhysicalProperty(direction, BeforeSide, borderDirections());
    case CSSPropertyWebkitBorderAfter:
        return resolveToPhysicalProperty(direction, AfterSide, borderDirections());
    case CSSPropertyWebkitBorderEndColor:
        return resolveToPhysicalProperty(direction, EndSide, borderColorShorthand());
    case CSSPropertyWebkitBorderStartColor:
        return resolveToPhysicalProperty(direction, StartSide, borderColorShorthand());
    case CSSPropertyWebkitBorderBeforeColor:
        return resolveToPhysicalProperty(direction, BeforeSide, borderColorShorthand());
    case CSSPropertyWebkitBorderAfterColor:
        return resolveToPhysicalProperty(direction, AfterSide, borderColorShorthand());
    case CSSPropertyWebkitBorderEndStyle:
        return resolveToPhysicalProperty(direction, EndSide, borderStyleShorthand());
    case CSSPropertyWebkitBorderStartStyle:
        return resolveToPhysicalProperty(direction, StartSide, borderStyleShorthand());
    case CSSPropertyWebkitBorderBeforeStyle:
        return resolveToPhysicalProperty(direction, BeforeSide, borderStyleShorthand());
    case CSSPropertyWebkitBorderAfterStyle:
        return resolveToPhysicalProperty(direction, AfterSide, borderStyleShorthand());
    case CSSPropertyWebkitBorderEndWidth:
        return resolveToPhysicalProperty(direction, EndSide, borderWidthShorthand());
    case CSSPropertyWebkitBorderStartWidth:
        return resolveToPhysicalProperty(direction, StartSide, borderWidthShorthand());
    case CSSPropertyWebkitBorderBeforeWidth:
        return resolveToPhysicalProperty(direction, BeforeSide, borderWidthShorthand());
    case CSSPropertyWebkitBorderAfterWidth:
        return resolveToPhysicalProperty(direction, AfterSide, borderWidthShorthand());
    case CSSPropertyWebkitLogicalWidth: {
        const CSSPropertyID properties[2] = { CSSPropertyWidth, CSSPropertyHeight };
        return resolveToPhysicalProperty(LogicalWidth, properties);
    }
    case CSSPropertyWebkitLogicalHeight: {
        const CSSPropertyID properties[2] = { CSSPropertyWidth, CSSPropertyHeight };
        return resolveToPhysicalProperty(LogicalHeight, properties);
    }
    case CSSPropertyWebkitMinLogicalWidth: {
        const CSSPropertyID properties[2] = { CSSPropertyMinWidth, CSSPropertyMinHeight };
        return resolveToPhysicalProperty(LogicalWidth, properties);
    }
    case CSSPropertyWebkitMinLogicalHeight: {
        const CSSPropertyID properties[2] = { CSSPropertyMinWidth, CSSPropertyMinHeight };
        return resolveToPhysicalProperty(LogicalHeight, properties);
    }
    case CSSPropertyWebkitMaxLogicalWidth: {
        const CSSPropertyID properties[2] = { CSSPropertyMaxWidth, CSSPropertyMaxHeight };
        return resolveToPhysicalProperty(LogicalWidth, properties);
    }
    case CSSPropertyWebkitMaxLogicalHeight: {
        const CSSPropertyID properties[2] = { CSSPropertyMaxWidth, CSSPropertyMaxHeight };
        return resolveToPhysicalProperty(LogicalHeight, properties);
    }
    default:
        return propertyID;
    }
}

} // namespace blink
