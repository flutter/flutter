/*
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2013 Intel Corporation. All rights reserved.
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
#include "gen/sky/core/StylePropertyShorthand.h"

namespace blink {

const StylePropertyShorthand& borderShorthandForParsing()
{
    static const CSSPropertyID borderShorthandProperties[] = { CSSPropertyBorderWidth, CSSPropertyBorderStyle, CSSPropertyBorderColor };
    static const StylePropertyShorthand* propertiesForInitialization[] = {
        &borderWidthShorthand(),
        &borderStyleShorthand(),
        &borderColorShorthand(),
    };
    DEFINE_STATIC_LOCAL(StylePropertyShorthand, borderForParsingLonghands, (CSSPropertyBorder, borderShorthandProperties, propertiesForInitialization, WTF_ARRAY_LENGTH(borderShorthandProperties)));
    return borderForParsingLonghands;
}

const StylePropertyShorthand& animationShorthandForParsing()
{
    // When we parse the animation shorthand we need to look for animation-name
    // last because otherwise it might match against the keywords for fill mode,
    // timing functions and infinite iteration. This means that animation names
    // that are the same as keywords (e.g. 'forwards') won't always match in the
    // shorthand. In that case the authors should be using longhands (or
    // reconsidering their approach). This is covered by the animations spec
    // bug: https://www.w3.org/Bugs/Public/show_bug.cgi?id=14790
    // And in the spec (editor's draft) at:
    // http://dev.w3.org/csswg/css3-animations/#animation-shorthand-property
    static const CSSPropertyID animationPropertiesForParsing[] = {
        CSSPropertyAnimationDuration,
        CSSPropertyAnimationTimingFunction,
        CSSPropertyAnimationDelay,
        CSSPropertyAnimationIterationCount,
        CSSPropertyAnimationDirection,
        CSSPropertyAnimationFillMode,
        CSSPropertyAnimationPlayState,
        CSSPropertyAnimationName
    };
    DEFINE_STATIC_LOCAL(StylePropertyShorthand, webkitAnimationLonghandsForParsing, (CSSPropertyAnimation, animationPropertiesForParsing, WTF_ARRAY_LENGTH(animationPropertiesForParsing)));
    return webkitAnimationLonghandsForParsing;
}

const StylePropertyShorthand& webkitAnimationShorthandForParsing()
{
    // When we parse the animation shorthand we need to look for animation-name
    // last because otherwise it might match against the keywords for fill mode,
    // timing functions and infinite iteration. This means that animation names
    // that are the same as keywords (e.g. 'forwards') won't always match in the
    // shorthand. In that case the authors should be using longhands (or
    // reconsidering their approach). This is covered by the animations spec
    // bug: https://www.w3.org/Bugs/Public/show_bug.cgi?id=14790
    // And in the spec (editor's draft) at:
    // http://dev.w3.org/csswg/css3-animations/#animation-shorthand-property
    static const CSSPropertyID animationPropertiesForParsing[] = {
        CSSPropertyWebkitAnimationDuration,
        CSSPropertyWebkitAnimationTimingFunction,
        CSSPropertyWebkitAnimationDelay,
        CSSPropertyWebkitAnimationIterationCount,
        CSSPropertyWebkitAnimationDirection,
        CSSPropertyWebkitAnimationFillMode,
        CSSPropertyWebkitAnimationPlayState,
        CSSPropertyWebkitAnimationName
    };
    DEFINE_STATIC_LOCAL(StylePropertyShorthand, webkitAnimationLonghandsForParsing, (CSSPropertyWebkitAnimation, animationPropertiesForParsing, WTF_ARRAY_LENGTH(animationPropertiesForParsing)));
    return webkitAnimationLonghandsForParsing;
}

// Similar to animations, we have property after timing-function and delay after duration
const StylePropertyShorthand& transitionShorthandForParsing()
{
    static const CSSPropertyID transitionProperties[] = {
        CSSPropertyTransitionDuration,
        CSSPropertyTransitionTimingFunction,
        CSSPropertyTransitionDelay,
        CSSPropertyTransitionProperty
    };
    DEFINE_STATIC_LOCAL(StylePropertyShorthand, transitionLonghands, (CSSPropertyTransition, transitionProperties, WTF_ARRAY_LENGTH(transitionProperties)));
    return transitionLonghands;
}

const StylePropertyShorthand& webkitTransitionShorthandForParsing()
{
    static const CSSPropertyID webkitTransitionProperties[] = {
        CSSPropertyWebkitTransitionDuration,
        CSSPropertyWebkitTransitionTimingFunction,
        CSSPropertyWebkitTransitionDelay,
        CSSPropertyWebkitTransitionProperty
    };
    DEFINE_STATIC_LOCAL(StylePropertyShorthand, webkitTransitionLonghands, (CSSPropertyWebkitTransition, webkitTransitionProperties, WTF_ARRAY_LENGTH(webkitTransitionProperties)));
    return webkitTransitionLonghands;
}

// Returns an empty list if the property is not a shorthand, otherwise the list of longhands for parsing.
const StylePropertyShorthand& parsingShorthandForProperty(CSSPropertyID propertyID)
{
    switch (propertyID) {
    case CSSPropertyAnimation:
        return animationShorthandForParsing();
    case CSSPropertyBorder:
        return borderShorthandForParsing();
    case CSSPropertyWebkitAnimation:
        return webkitAnimationShorthandForParsing();
    case CSSPropertyTransition:
        return transitionShorthandForParsing();
    case CSSPropertyWebkitTransition:
        return webkitTransitionShorthandForParsing();
    default:
        return shorthandForProperty(propertyID);
    }
}

bool isExpandedShorthand(CSSPropertyID id)
{
    // The system fonts bypass the normal style resolution by using RenderTheme,
    // thus we need to special case it here. FIXME: This is a violation of CSS 3 Fonts
    // as we should still be able to change the longhands.
    // DON'T ADD ANY SHORTHAND HERE UNLESS IT ISN'T ALWAYS EXPANDED AT PARSE TIME (which is wrong).
    if (id == CSSPropertyFont)
        return false;

    return shorthandForProperty(id).length();
}

bool isExpandedShorthandForAll(CSSPropertyID propertyId)
{
    // FIXME: isExpandedShorthand says "font" is not an expanded shorthand,
    // but font is expanded to font-family, font-size, and so on.
    // StylePropertySerializer::asText should not generate css text like
    // "font: initial; font-family: initial;...". To avoid this, we need to
    // treat "font" as an expanded shorthand.
    // And while applying "all" property, we cannot apply "font" property
    // directly. This causes ASSERT crash, because StyleBuilder assume that
    // all given properties are not expanded shorthands.
    // "marker" has the same issue.
    if (propertyId == CSSPropertyFont)
        return true;
    return shorthandForProperty(propertyId).length();
}

unsigned indexOfShorthandForLonghand(CSSPropertyID shorthandID, const Vector<StylePropertyShorthand, 4>& shorthands)
{
    for (unsigned i = 0; i < shorthands.size(); ++i) {
        if (shorthands.at(i).id() == shorthandID)
            return i;
    }
    ASSERT_NOT_REACHED();
    return 0;
}

} // namespace blink
