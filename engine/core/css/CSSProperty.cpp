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
#include "core/css/CSSProperty.h"

#include "core/StylePropertyShorthand.h"
#include "core/css/CSSValueList.h"
#include "core/rendering/style/RenderStyleConstants.h"

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
    RefPtrWillBeRawPtr<CSSValue> value = m_value.release();
    m_value = CSSValueList::createCommaSeparated();
    toCSSValueList(m_value.get())->append(value.release());
}

enum LogicalBoxSide { BeforeSide, EndSide, AfterSide, StartSide };
enum PhysicalBoxSide { TopSide, RightSide, BottomSide, LeftSide };

static CSSPropertyID resolveToPhysicalProperty(TextDirection direction, WritingMode writingMode, LogicalBoxSide logicalSide, const StylePropertyShorthand& shorthand)
{
    if (direction == LTR) {
        if (writingMode == TopToBottomWritingMode) {
            // The common case. The logical and physical box sides match.
            // Left = Start, Right = End, Before = Top, After = Bottom
            return shorthand.properties()[logicalSide];
        }

        if (writingMode == BottomToTopWritingMode) {
            // Start = Left, End = Right, Before = Bottom, After = Top.
            switch (logicalSide) {
            case StartSide:
                return shorthand.properties()[LeftSide];
            case EndSide:
                return shorthand.properties()[RightSide];
            case BeforeSide:
                return shorthand.properties()[BottomSide];
            default:
                return shorthand.properties()[TopSide];
            }
        }

        if (writingMode == LeftToRightWritingMode) {
            // Start = Top, End = Bottom, Before = Left, After = Right.
            switch (logicalSide) {
            case StartSide:
                return shorthand.properties()[TopSide];
            case EndSide:
                return shorthand.properties()[BottomSide];
            case BeforeSide:
                return shorthand.properties()[LeftSide];
            default:
                return shorthand.properties()[RightSide];
            }
        }

        // Start = Top, End = Bottom, Before = Right, After = Left
        switch (logicalSide) {
        case StartSide:
            return shorthand.properties()[TopSide];
        case EndSide:
            return shorthand.properties()[BottomSide];
        case BeforeSide:
            return shorthand.properties()[RightSide];
        default:
            return shorthand.properties()[LeftSide];
        }
    }

    if (writingMode == TopToBottomWritingMode) {
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

    if (writingMode == BottomToTopWritingMode) {
        // Start = Right, End = Left, Before = Bottom, After = Top
        switch (logicalSide) {
        case StartSide:
            return shorthand.properties()[RightSide];
        case EndSide:
            return shorthand.properties()[LeftSide];
        case BeforeSide:
            return shorthand.properties()[BottomSide];
        default:
            return shorthand.properties()[TopSide];
        }
    }

    if (writingMode == LeftToRightWritingMode) {
        // Start = Bottom, End = Top, Before = Left, After = Right
        switch (logicalSide) {
        case StartSide:
            return shorthand.properties()[BottomSide];
        case EndSide:
            return shorthand.properties()[TopSide];
        case BeforeSide:
            return shorthand.properties()[LeftSide];
        default:
            return shorthand.properties()[RightSide];
        }
    }

    // Start = Bottom, End = Top, Before = Right, After = Left
    switch (logicalSide) {
    case StartSide:
        return shorthand.properties()[BottomSide];
    case EndSide:
        return shorthand.properties()[TopSide];
    case BeforeSide:
        return shorthand.properties()[RightSide];
    default:
        return shorthand.properties()[LeftSide];
    }
}

enum LogicalExtent { LogicalWidth, LogicalHeight };

static CSSPropertyID resolveToPhysicalProperty(WritingMode writingMode, LogicalExtent logicalSide, const CSSPropertyID* properties)
{
    if (writingMode == TopToBottomWritingMode || writingMode == BottomToTopWritingMode)
        return properties[logicalSide];
    return logicalSide == LogicalWidth ? properties[1] : properties[0];
}

static const StylePropertyShorthand& borderDirections()
{
    static const CSSPropertyID properties[4] = { CSSPropertyBorderTop, CSSPropertyBorderRight, CSSPropertyBorderBottom, CSSPropertyBorderLeft };
    DEFINE_STATIC_LOCAL(StylePropertyShorthand, borderDirections, (CSSPropertyBorder, properties, WTF_ARRAY_LENGTH(properties)));
    return borderDirections;
}

CSSPropertyID CSSProperty::resolveDirectionAwareProperty(CSSPropertyID propertyID, TextDirection direction, WritingMode writingMode)
{
    switch (propertyID) {
    case CSSPropertyWebkitMarginEnd:
        return resolveToPhysicalProperty(direction, writingMode, EndSide, marginShorthand());
    case CSSPropertyWebkitMarginStart:
        return resolveToPhysicalProperty(direction, writingMode, StartSide, marginShorthand());
    case CSSPropertyWebkitMarginBefore:
        return resolveToPhysicalProperty(direction, writingMode, BeforeSide, marginShorthand());
    case CSSPropertyWebkitMarginAfter:
        return resolveToPhysicalProperty(direction, writingMode, AfterSide, marginShorthand());
    case CSSPropertyWebkitPaddingEnd:
        return resolveToPhysicalProperty(direction, writingMode, EndSide, paddingShorthand());
    case CSSPropertyWebkitPaddingStart:
        return resolveToPhysicalProperty(direction, writingMode, StartSide, paddingShorthand());
    case CSSPropertyWebkitPaddingBefore:
        return resolveToPhysicalProperty(direction, writingMode, BeforeSide, paddingShorthand());
    case CSSPropertyWebkitPaddingAfter:
        return resolveToPhysicalProperty(direction, writingMode, AfterSide, paddingShorthand());
    case CSSPropertyWebkitBorderEnd:
        return resolveToPhysicalProperty(direction, writingMode, EndSide, borderDirections());
    case CSSPropertyWebkitBorderStart:
        return resolveToPhysicalProperty(direction, writingMode, StartSide, borderDirections());
    case CSSPropertyWebkitBorderBefore:
        return resolveToPhysicalProperty(direction, writingMode, BeforeSide, borderDirections());
    case CSSPropertyWebkitBorderAfter:
        return resolveToPhysicalProperty(direction, writingMode, AfterSide, borderDirections());
    case CSSPropertyWebkitBorderEndColor:
        return resolveToPhysicalProperty(direction, writingMode, EndSide, borderColorShorthand());
    case CSSPropertyWebkitBorderStartColor:
        return resolveToPhysicalProperty(direction, writingMode, StartSide, borderColorShorthand());
    case CSSPropertyWebkitBorderBeforeColor:
        return resolveToPhysicalProperty(direction, writingMode, BeforeSide, borderColorShorthand());
    case CSSPropertyWebkitBorderAfterColor:
        return resolveToPhysicalProperty(direction, writingMode, AfterSide, borderColorShorthand());
    case CSSPropertyWebkitBorderEndStyle:
        return resolveToPhysicalProperty(direction, writingMode, EndSide, borderStyleShorthand());
    case CSSPropertyWebkitBorderStartStyle:
        return resolveToPhysicalProperty(direction, writingMode, StartSide, borderStyleShorthand());
    case CSSPropertyWebkitBorderBeforeStyle:
        return resolveToPhysicalProperty(direction, writingMode, BeforeSide, borderStyleShorthand());
    case CSSPropertyWebkitBorderAfterStyle:
        return resolveToPhysicalProperty(direction, writingMode, AfterSide, borderStyleShorthand());
    case CSSPropertyWebkitBorderEndWidth:
        return resolveToPhysicalProperty(direction, writingMode, EndSide, borderWidthShorthand());
    case CSSPropertyWebkitBorderStartWidth:
        return resolveToPhysicalProperty(direction, writingMode, StartSide, borderWidthShorthand());
    case CSSPropertyWebkitBorderBeforeWidth:
        return resolveToPhysicalProperty(direction, writingMode, BeforeSide, borderWidthShorthand());
    case CSSPropertyWebkitBorderAfterWidth:
        return resolveToPhysicalProperty(direction, writingMode, AfterSide, borderWidthShorthand());
    case CSSPropertyWebkitLogicalWidth: {
        const CSSPropertyID properties[2] = { CSSPropertyWidth, CSSPropertyHeight };
        return resolveToPhysicalProperty(writingMode, LogicalWidth, properties);
    }
    case CSSPropertyWebkitLogicalHeight: {
        const CSSPropertyID properties[2] = { CSSPropertyWidth, CSSPropertyHeight };
        return resolveToPhysicalProperty(writingMode, LogicalHeight, properties);
    }
    case CSSPropertyWebkitMinLogicalWidth: {
        const CSSPropertyID properties[2] = { CSSPropertyMinWidth, CSSPropertyMinHeight };
        return resolveToPhysicalProperty(writingMode, LogicalWidth, properties);
    }
    case CSSPropertyWebkitMinLogicalHeight: {
        const CSSPropertyID properties[2] = { CSSPropertyMinWidth, CSSPropertyMinHeight };
        return resolveToPhysicalProperty(writingMode, LogicalHeight, properties);
    }
    case CSSPropertyWebkitMaxLogicalWidth: {
        const CSSPropertyID properties[2] = { CSSPropertyMaxWidth, CSSPropertyMaxHeight };
        return resolveToPhysicalProperty(writingMode, LogicalWidth, properties);
    }
    case CSSPropertyWebkitMaxLogicalHeight: {
        const CSSPropertyID properties[2] = { CSSPropertyMaxWidth, CSSPropertyMaxHeight };
        return resolveToPhysicalProperty(writingMode, LogicalHeight, properties);
    }
    default:
        return propertyID;
    }
}

bool CSSProperty::isAffectedByAllProperty(CSSPropertyID propertyID)
{
    if (propertyID == CSSPropertyAll)
        return false;

    // all shorthand spec says:
    // The all property is a shorthand that resets all CSS properties except
    // direction and unicode-bidi. It only accepts the CSS-wide keywords.
    // c.f. http://dev.w3.org/csswg/css-cascade/#all-shorthand
    // So CSSPropertyUnicodeBidi and CSSPropertyDirection are not
    // affected by all property.
    return propertyID != CSSPropertyUnicodeBidi && propertyID != CSSPropertyDirection;
}

} // namespace blink
