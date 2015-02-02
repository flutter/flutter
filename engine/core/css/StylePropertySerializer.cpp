/*
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2011 Research In Motion Limited. All rights reserved.
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

#include "sky/engine/config.h"
#include "sky/engine/core/css/StylePropertySerializer.h"

#include "gen/sky/core/CSSValueKeywords.h"
#include "gen/sky/core/StylePropertyShorthand.h"
#include "sky/engine/core/css/CSSPropertyMetadata.h"
#include "sky/engine/wtf/BitArray.h"
#include "sky/engine/wtf/text/StringBuilder.h"

namespace blink {

static bool isInitialOrInherit(const String& value)
{
    DEFINE_STATIC_LOCAL(String, initial, ("initial"));
    DEFINE_STATIC_LOCAL(String, inherit, ("inherit"));
    return value.length() == 7 && (value == initial || value == inherit);
}

StylePropertySerializer::StylePropertySerializer(const StylePropertySet& properties)
    : m_propertySet(properties)
{
}

String StylePropertySerializer::getPropertyText(CSSPropertyID propertyID, const String& value, bool isNotFirstDecl) const
{
    StringBuilder result;
    if (isNotFirstDecl)
        result.append(' ');
    result.append(getPropertyName(propertyID));
    result.appendLiteral(": ");
    result.append(value);
    result.append(';');
    return result.toString();
}

String StylePropertySerializer::asText() const
{
    StringBuilder result;

    BitArray<numCSSProperties> shorthandPropertyUsed;
    BitArray<numCSSProperties> shorthandPropertyAppeared;

    unsigned size = m_propertySet.propertyCount();
    unsigned numDecls = 0;
    for (unsigned n = 0; n < size; ++n) {
        StylePropertySet::PropertyReference property = m_propertySet.propertyAt(n);
        CSSPropertyID propertyID = property.id();
        // Only enabled or internal properties should be part of the style.
        ASSERT(CSSPropertyMetadata::isEnabledProperty(propertyID) || isInternalProperty(propertyID));
        CSSPropertyID shorthandPropertyID = CSSPropertyInvalid;
        CSSPropertyID borderFallbackShorthandProperty = CSSPropertyInvalid;
        String value;

        switch (propertyID) {
        case CSSPropertyAnimationName:
        case CSSPropertyAnimationDuration:
        case CSSPropertyAnimationTimingFunction:
        case CSSPropertyAnimationDelay:
        case CSSPropertyAnimationIterationCount:
        case CSSPropertyAnimationDirection:
        case CSSPropertyAnimationFillMode:
            shorthandPropertyID = CSSPropertyAnimation;
            break;
        case CSSPropertyBackgroundAttachment:
        case CSSPropertyBackgroundClip:
        case CSSPropertyBackgroundColor:
        case CSSPropertyBackgroundImage:
        case CSSPropertyBackgroundOrigin:
        case CSSPropertyBackgroundPositionX:
        case CSSPropertyBackgroundPositionY:
        case CSSPropertyBackgroundSize:
        case CSSPropertyBackgroundRepeatX:
        case CSSPropertyBackgroundRepeatY:
            shorthandPropertyAppeared.set(CSSPropertyBackground - firstCSSProperty);
            continue;
        case CSSPropertyBorderTopWidth:
        case CSSPropertyBorderRightWidth:
        case CSSPropertyBorderBottomWidth:
        case CSSPropertyBorderLeftWidth:
            if (!borderFallbackShorthandProperty)
                borderFallbackShorthandProperty = CSSPropertyBorderWidth;
        case CSSPropertyBorderTopStyle:
        case CSSPropertyBorderRightStyle:
        case CSSPropertyBorderBottomStyle:
        case CSSPropertyBorderLeftStyle:
            if (!borderFallbackShorthandProperty)
                borderFallbackShorthandProperty = CSSPropertyBorderStyle;
        case CSSPropertyBorderTopColor:
        case CSSPropertyBorderRightColor:
        case CSSPropertyBorderBottomColor:
        case CSSPropertyBorderLeftColor:
            if (!borderFallbackShorthandProperty)
                borderFallbackShorthandProperty = CSSPropertyBorderColor;

            // FIXME: Deal with cases where only some of border-(top|right|bottom|left) are specified.
            if (!shorthandPropertyAppeared.get(CSSPropertyBorder - firstCSSProperty)) {
                value = borderPropertyValue(ReturnNullOnUncommonValues);
                if (value.isNull())
                    shorthandPropertyAppeared.set(CSSPropertyBorder - firstCSSProperty);
                else
                    shorthandPropertyID = CSSPropertyBorder;
            } else if (shorthandPropertyUsed.get(CSSPropertyBorder - firstCSSProperty))
                shorthandPropertyID = CSSPropertyBorder;
            if (!shorthandPropertyID)
                shorthandPropertyID = borderFallbackShorthandProperty;
            break;
        case CSSPropertyWebkitBorderHorizontalSpacing:
        case CSSPropertyWebkitBorderVerticalSpacing:
            shorthandPropertyID = CSSPropertyBorderSpacing;
            break;
        case CSSPropertyFontFamily:
        case CSSPropertyLineHeight:
        case CSSPropertyFontSize:
        case CSSPropertyFontStretch:
        case CSSPropertyFontStyle:
        case CSSPropertyFontVariant:
        case CSSPropertyFontWeight:
            // Don't use CSSPropertyFont because old UAs can't recognize them but are important for editing.
            break;
        case CSSPropertyListStyleType:
        case CSSPropertyListStylePosition:
        case CSSPropertyListStyleImage:
            shorthandPropertyID = CSSPropertyListStyle;
            break;
        case CSSPropertyMarginTop:
        case CSSPropertyMarginRight:
        case CSSPropertyMarginBottom:
        case CSSPropertyMarginLeft:
            shorthandPropertyID = CSSPropertyMargin;
            break;
        case CSSPropertyOutlineWidth:
        case CSSPropertyOutlineStyle:
        case CSSPropertyOutlineColor:
            shorthandPropertyID = CSSPropertyOutline;
            break;
        case CSSPropertyOverflowX:
        case CSSPropertyOverflowY:
            shorthandPropertyID = CSSPropertyOverflow;
            break;
        case CSSPropertyPaddingTop:
        case CSSPropertyPaddingRight:
        case CSSPropertyPaddingBottom:
        case CSSPropertyPaddingLeft:
            shorthandPropertyID = CSSPropertyPadding;
            break;
        case CSSPropertyTransitionProperty:
        case CSSPropertyTransitionDuration:
        case CSSPropertyTransitionTimingFunction:
        case CSSPropertyTransitionDelay:
            shorthandPropertyID = CSSPropertyTransition;
            break;
        case CSSPropertyFlexDirection:
        case CSSPropertyFlexWrap:
            shorthandPropertyID = CSSPropertyFlexFlow;
            break;
        case CSSPropertyFlexBasis:
        case CSSPropertyFlexGrow:
        case CSSPropertyFlexShrink:
            shorthandPropertyID = CSSPropertyFlex;
            break;
        case CSSPropertyWebkitTransformOriginX:
        case CSSPropertyWebkitTransformOriginY:
        case CSSPropertyWebkitTransformOriginZ:
            shorthandPropertyID = CSSPropertyWebkitTransformOrigin;
            break;
        default:
            break;
        }

        unsigned shortPropertyIndex = shorthandPropertyID - firstCSSProperty;
        if (shorthandPropertyID) {
            if (shorthandPropertyUsed.get(shortPropertyIndex))
                continue;
            if (!shorthandPropertyAppeared.get(shortPropertyIndex) && value.isNull())
                value = m_propertySet.getPropertyValue(shorthandPropertyID);
            shorthandPropertyAppeared.set(shortPropertyIndex);
        }

        if (!value.isNull()) {
            if (shorthandPropertyID) {
                propertyID = shorthandPropertyID;
                shorthandPropertyUsed.set(shortPropertyIndex);
            }
        } else
            value = property.value()->cssText();

        if (value == "initial" && !CSSPropertyMetadata::isInheritedProperty(propertyID))
            continue;

        result.append(getPropertyText(propertyID, value, numDecls++));
    }

    if (shorthandPropertyAppeared.get(CSSPropertyBackground - firstCSSProperty))
        appendBackgroundPropertyAsText(result, numDecls);

    ASSERT(!numDecls ^ !result.isEmpty());
    return result.toString();
}

String StylePropertySerializer::getPropertyValue(CSSPropertyID propertyID) const
{
    // Shorthand and 4-values properties
    switch (propertyID) {
    case CSSPropertyAnimation:
        return getLayeredShorthandValue(animationShorthand());
    case CSSPropertyBorderSpacing:
        return borderSpacingValue(borderSpacingShorthand());
    case CSSPropertyBackgroundPosition:
        return getLayeredShorthandValue(backgroundPositionShorthand());
    case CSSPropertyBackgroundRepeat:
        return backgroundRepeatPropertyValue();
    case CSSPropertyBackground:
        return getLayeredShorthandValue(backgroundShorthand());
    case CSSPropertyBorder:
        return borderPropertyValue(OmitUncommonValues);
    case CSSPropertyBorderTop:
        return getShorthandValue(borderTopShorthand());
    case CSSPropertyBorderRight:
        return getShorthandValue(borderRightShorthand());
    case CSSPropertyBorderBottom:
        return getShorthandValue(borderBottomShorthand());
    case CSSPropertyBorderLeft:
        return getShorthandValue(borderLeftShorthand());
    case CSSPropertyOutline:
        return getShorthandValue(outlineShorthand());
    case CSSPropertyBorderColor:
        return get4Values(borderColorShorthand());
    case CSSPropertyBorderWidth:
        return get4Values(borderWidthShorthand());
    case CSSPropertyBorderStyle:
        return get4Values(borderStyleShorthand());
    case CSSPropertyFlex:
        return getShorthandValue(flexShorthand());
    case CSSPropertyFlexFlow:
        return getShorthandValue(flexFlowShorthand());
    case CSSPropertyFont:
        return fontValue();
    case CSSPropertyMargin:
        return get4Values(marginShorthand());
    case CSSPropertyOverflow:
        return getCommonValue(overflowShorthand());
    case CSSPropertyPadding:
        return get4Values(paddingShorthand());
    case CSSPropertyTransition:
        return getLayeredShorthandValue(transitionShorthand());
    case CSSPropertyListStyle:
        return getShorthandValue(listStyleShorthand());
    case CSSPropertyWebkitTextEmphasis:
        return getShorthandValue(webkitTextEmphasisShorthand());
    case CSSPropertyWebkitTextStroke:
        return getShorthandValue(webkitTextStrokeShorthand());
    case CSSPropertyTransformOrigin:
    case CSSPropertyWebkitTransformOrigin:
        return getShorthandValue(webkitTransformOriginShorthand());
    case CSSPropertyBorderRadius:
        return get4Values(borderRadiusShorthand());
    default:
        return String();
    }
}

String StylePropertySerializer::borderSpacingValue(const StylePropertyShorthand& shorthand) const
{
    RefPtr<CSSValue> horizontalValue = m_propertySet.getPropertyCSSValue(shorthand.properties()[0]);
    RefPtr<CSSValue> verticalValue = m_propertySet.getPropertyCSSValue(shorthand.properties()[1]);

    // While standard border-spacing property does not allow specifying border-spacing-vertical without
    // specifying border-spacing-horizontal <http://www.w3.org/TR/CSS21/tables.html#separated-borders>,
    // -webkit-border-spacing-vertical can be set without -webkit-border-spacing-horizontal.
    if (!horizontalValue || !verticalValue)
        return String();

    String horizontalValueCSSText = horizontalValue->cssText();
    String verticalValueCSSText = verticalValue->cssText();
    if (horizontalValueCSSText == verticalValueCSSText)
        return horizontalValueCSSText;
    return horizontalValueCSSText + ' ' + verticalValueCSSText;
}

void StylePropertySerializer::appendFontLonghandValueIfExplicit(CSSPropertyID propertyID, StringBuilder& result, String& commonValue) const
{
    int foundPropertyIndex = m_propertySet.findPropertyIndex(propertyID);
    if (foundPropertyIndex == -1)
        return; // All longhands must have at least implicit values if "font" is specified.

    if (m_propertySet.propertyAt(foundPropertyIndex).isImplicit()) {
        commonValue = String();
        return;
    }

    char prefix = '\0';
    switch (propertyID) {
    case CSSPropertyFontStyle:
        break; // No prefix.
    case CSSPropertyFontFamily:
    case CSSPropertyFontStretch:
    case CSSPropertyFontVariant:
    case CSSPropertyFontWeight:
        prefix = ' ';
        break;
    case CSSPropertyLineHeight:
        prefix = '/';
        break;
    default:
        ASSERT_NOT_REACHED();
    }

    if (prefix && !result.isEmpty())
        result.append(prefix);
    String value = m_propertySet.propertyAt(foundPropertyIndex).value()->cssText();
    result.append(value);
    if (!commonValue.isNull() && commonValue != value)
        commonValue = String();
}

String StylePropertySerializer::fontValue() const
{
    int fontSizePropertyIndex = m_propertySet.findPropertyIndex(CSSPropertyFontSize);
    int fontFamilyPropertyIndex = m_propertySet.findPropertyIndex(CSSPropertyFontFamily);
    if (fontSizePropertyIndex == -1 || fontFamilyPropertyIndex == -1)
        return emptyString();

    StylePropertySet::PropertyReference fontSizeProperty = m_propertySet.propertyAt(fontSizePropertyIndex);
    StylePropertySet::PropertyReference fontFamilyProperty = m_propertySet.propertyAt(fontFamilyPropertyIndex);
    if (fontSizeProperty.isImplicit() || fontFamilyProperty.isImplicit())
        return emptyString();

    String commonValue = fontSizeProperty.value()->cssText();
    StringBuilder result;
    appendFontLonghandValueIfExplicit(CSSPropertyFontStyle, result, commonValue);
    appendFontLonghandValueIfExplicit(CSSPropertyFontVariant, result, commonValue);
    appendFontLonghandValueIfExplicit(CSSPropertyFontWeight, result, commonValue);
    appendFontLonghandValueIfExplicit(CSSPropertyFontStretch, result, commonValue);
    if (!result.isEmpty())
        result.append(' ');
    result.append(fontSizeProperty.value()->cssText());
    appendFontLonghandValueIfExplicit(CSSPropertyLineHeight, result, commonValue);
    if (!result.isEmpty())
        result.append(' ');
    result.append(fontFamilyProperty.value()->cssText());
    if (isInitialOrInherit(commonValue))
        return commonValue;
    return result.toString();
}

String StylePropertySerializer::get4Values(const StylePropertyShorthand& shorthand) const
{
    // Assume the properties are in the usual order top, right, bottom, left.
    int topValueIndex = m_propertySet.findPropertyIndex(shorthand.properties()[0]);
    int rightValueIndex = m_propertySet.findPropertyIndex(shorthand.properties()[1]);
    int bottomValueIndex = m_propertySet.findPropertyIndex(shorthand.properties()[2]);
    int leftValueIndex = m_propertySet.findPropertyIndex(shorthand.properties()[3]);

    if (topValueIndex == -1 || rightValueIndex == -1 || bottomValueIndex == -1 || leftValueIndex == -1)
        return String();

    StylePropertySet::PropertyReference top = m_propertySet.propertyAt(topValueIndex);
    StylePropertySet::PropertyReference right = m_propertySet.propertyAt(rightValueIndex);
    StylePropertySet::PropertyReference bottom = m_propertySet.propertyAt(bottomValueIndex);
    StylePropertySet::PropertyReference left = m_propertySet.propertyAt(leftValueIndex);

        // All 4 properties must be specified.
    if (!top.value() || !right.value() || !bottom.value() || !left.value())
        return String();

    if (top.isInherited() && right.isInherited() && bottom.isInherited() && left.isInherited())
        return getValueName(CSSValueInherit);

    if (top.value()->isInitialValue() || right.value()->isInitialValue() || bottom.value()->isInitialValue() || left.value()->isInitialValue()) {
        if (top.value()->isInitialValue() && right.value()->isInitialValue() && bottom.value()->isInitialValue() && left.value()->isInitialValue() && !top.isImplicit()) {
            // All components are "initial" and "top" is not implicit.
            return getValueName(CSSValueInitial);
        }
        return String();
    }

    bool showLeft = !right.value()->equals(*left.value());
    bool showBottom = !top.value()->equals(*bottom.value()) || showLeft;
    bool showRight = !top.value()->equals(*right.value()) || showBottom;

    StringBuilder result;
    result.append(top.value()->cssText());
    if (showRight) {
        result.append(' ');
        result.append(right.value()->cssText());
    }
    if (showBottom) {
        result.append(' ');
        result.append(bottom.value()->cssText());
    }
    if (showLeft) {
        result.append(' ');
        result.append(left.value()->cssText());
    }
    return result.toString();
}

String StylePropertySerializer::getLayeredShorthandValue(const StylePropertyShorthand& shorthand) const
{
    StringBuilder result;

    const unsigned size = shorthand.length();
    // Begin by collecting the properties into an array.
    Vector<RefPtr<CSSValue> > values(size);
    size_t numLayers = 0;

    for (unsigned i = 0; i < size; ++i) {
        values[i] = m_propertySet.getPropertyCSSValue(shorthand.properties()[i]);
        if (values[i]) {
            if (values[i]->isBaseValueList()) {
                CSSValueList* valueList = toCSSValueList(values[i].get());
                numLayers = std::max(valueList->length(), numLayers);
            } else {
                numLayers = std::max<size_t>(1U, numLayers);
            }
        }
    }

    String commonValue;
    bool commonValueInitialized = false;

    // Now stitch the properties together. Implicit initial values are flagged as such and
    // can safely be omitted.
    for (size_t i = 0; i < numLayers; i++) {
        StringBuilder layerResult;
        bool useRepeatXShorthand = false;
        bool useRepeatYShorthand = false;
        bool useSingleWordShorthand = false;
        bool foundPositionYCSSProperty = false;
        for (unsigned j = 0; j < size; j++) {
            RefPtr<CSSValue> value = nullptr;
            if (values[j]) {
                if (values[j]->isBaseValueList()) {
                    value = toCSSValueList(values[j].get())->itemWithBoundsCheck(i);
                } else {
                    value = values[j];

                    // Color only belongs in the last layer.
                    if (shorthand.properties()[j] == CSSPropertyBackgroundColor) {
                        if (i != numLayers - 1)
                            value = nullptr;
                    } else if (i) {
                        // Other singletons only belong in the first layer.
                        value = nullptr;
                    }
                }
            }

            // We need to report background-repeat as it was written in the CSS. If the property is implicit,
            // then it was written with only one value. Here we figure out which value that was so we can
            // report back correctly.
            if (shorthand.properties()[j] == CSSPropertyBackgroundRepeatX && m_propertySet.isPropertyImplicit(shorthand.properties()[j])) {

                // BUG 49055: make sure the value was not reset in the layer check just above.
                if (j < size - 1 && shorthand.properties()[j + 1] == CSSPropertyBackgroundRepeatY && value) {
                    RefPtr<CSSValue> yValue = nullptr;
                    RefPtr<CSSValue> nextValue = values[j + 1];
                    if (nextValue->isValueList())
                        yValue = toCSSValueList(nextValue.get())->item(i);
                    else
                        yValue = nextValue;

                    // background-repeat-x(y) or mask-repeat-x(y) may be like this : "initial, repeat". We can omit the implicit initial values
                    // before starting to compare their values.
                    if (value->isImplicitInitialValue() || yValue->isImplicitInitialValue())
                        continue;

                    // FIXME: At some point we need to fix this code to avoid returning an invalid shorthand,
                    // since some longhand combinations are not serializable into a single shorthand.
                    if (!value->isPrimitiveValue() || !yValue->isPrimitiveValue())
                        continue;

                    CSSValueID xId = toCSSPrimitiveValue(value.get())->getValueID();
                    CSSValueID yId = toCSSPrimitiveValue(yValue.get())->getValueID();
                    if (xId != yId) {
                        if (xId == CSSValueRepeat && yId == CSSValueNoRepeat) {
                            useRepeatXShorthand = true;
                            ++j;
                        } else if (xId == CSSValueNoRepeat && yId == CSSValueRepeat) {
                            useRepeatYShorthand = true;
                            continue;
                        }
                    } else {
                        useSingleWordShorthand = true;
                        ++j;
                    }
                }
            }

            String valueText;
            if (value && !value->isImplicitInitialValue()) {
                if (!layerResult.isEmpty())
                    layerResult.append(' ');
                if (foundPositionYCSSProperty
                    && shorthand.properties()[j] == CSSPropertyBackgroundSize)
                    layerResult.appendLiteral("/ ");
                if (!foundPositionYCSSProperty
                    && shorthand.properties()[j] == CSSPropertyBackgroundSize)
                    continue;

                if (useRepeatXShorthand) {
                    useRepeatXShorthand = false;
                    layerResult.append(getValueName(CSSValueRepeatX));
                } else if (useRepeatYShorthand) {
                    useRepeatYShorthand = false;
                    layerResult.append(getValueName(CSSValueRepeatY));
                } else {
                    if (useSingleWordShorthand)
                        useSingleWordShorthand = false;
                    valueText = value->cssText();
                    layerResult.append(valueText);
                }

                if (shorthand.properties()[j] == CSSPropertyBackgroundPositionY) {
                    foundPositionYCSSProperty = true;

                    // background-position is a special case: if only the first offset is specified,
                    // the second one defaults to "center", not the same value.
                    if (commonValueInitialized && commonValue != "initial" && commonValue != "inherit")
                        commonValue = String();
                }
            }

            if (!commonValueInitialized) {
                commonValue = valueText;
                commonValueInitialized = true;
            } else if (!commonValue.isNull() && commonValue != valueText)
                commonValue = String();
        }

        if (!layerResult.isEmpty()) {
            if (!result.isEmpty())
                result.appendLiteral(", ");
            result.append(layerResult);
        }
    }

    if (isInitialOrInherit(commonValue))
        return commonValue;

    if (result.isEmpty())
        return String();
    return result.toString();
}

String StylePropertySerializer::getShorthandValue(const StylePropertyShorthand& shorthand) const
{
    String commonValue;
    StringBuilder result;
    for (unsigned i = 0; i < shorthand.length(); ++i) {
        if (!m_propertySet.isPropertyImplicit(shorthand.properties()[i])) {
            RefPtr<CSSValue> value = m_propertySet.getPropertyCSSValue(shorthand.properties()[i]);
            if (!value)
                return String();
            String valueText = value->cssText();
            if (!i)
                commonValue = valueText;
            else if (!commonValue.isNull() && commonValue != valueText)
                commonValue = String();
            if (value->isInitialValue())
                continue;
            if (!result.isEmpty())
                result.append(' ');
            result.append(valueText);
        } else
            commonValue = String();
    }
    if (isInitialOrInherit(commonValue))
        return commonValue;
    if (result.isEmpty())
        return String();
    return result.toString();
}

// only returns a non-null value if all properties have the same, non-null value
String StylePropertySerializer::getCommonValue(const StylePropertyShorthand& shorthand) const
{
    String res;
    for (unsigned i = 0; i < shorthand.length(); ++i) {
        RefPtr<CSSValue> value = m_propertySet.getPropertyCSSValue(shorthand.properties()[i]);
        // FIXME: CSSInitialValue::cssText should generate the right value.
        if (!value)
            return String();
        String text = value->cssText();
        if (text.isNull())
            return String();
        if (res.isNull())
            res = text;
        else if (res != text)
            return String();
    }
    return res;
}

String StylePropertySerializer::borderPropertyValue(CommonValueMode valueMode) const
{
    const StylePropertyShorthand properties[3] = { borderWidthShorthand(), borderStyleShorthand(), borderColorShorthand() };
    String commonValue;
    StringBuilder result;
    for (size_t i = 0; i < WTF_ARRAY_LENGTH(properties); ++i) {
        String value = getCommonValue(properties[i]);
        if (value.isNull()) {
            if (valueMode == ReturnNullOnUncommonValues)
                return String();
            ASSERT(valueMode == OmitUncommonValues);
            continue;
        }
        if (!i)
            commonValue = value;
        else if (!commonValue.isNull() && commonValue != value)
            commonValue = String();
        if (value == "initial")
            continue;
        if (!result.isEmpty())
            result.append(' ');
        result.append(value);
    }
    if (isInitialOrInherit(commonValue))
        return commonValue;
    return result.isEmpty() ? String() : result.toString();
}

static void appendBackgroundRepeatValue(StringBuilder& builder, const CSSValue& repeatXCSSValue, const CSSValue& repeatYCSSValue)
{
    // FIXME: Ensure initial values do not appear in CSS_VALUE_LISTS.
    DEFINE_STATIC_REF_WILL_BE_PERSISTENT(CSSPrimitiveValue, initialRepeatValue, (CSSPrimitiveValue::create(CSSValueRepeat)));
    const CSSPrimitiveValue& repeatX = repeatXCSSValue.isInitialValue() ? *initialRepeatValue : toCSSPrimitiveValue(repeatXCSSValue);
    const CSSPrimitiveValue& repeatY = repeatYCSSValue.isInitialValue() ? *initialRepeatValue : toCSSPrimitiveValue(repeatYCSSValue);
    CSSValueID repeatXValueId = repeatX.getValueID();
    CSSValueID repeatYValueId = repeatY.getValueID();
    if (repeatXValueId == repeatYValueId) {
        builder.append(repeatX.cssText());
    } else if (repeatXValueId == CSSValueNoRepeat && repeatYValueId == CSSValueRepeat) {
        builder.appendLiteral("repeat-y");
    } else if (repeatXValueId == CSSValueRepeat && repeatYValueId == CSSValueNoRepeat) {
        builder.appendLiteral("repeat-x");
    } else {
        builder.append(repeatX.cssText());
        builder.appendLiteral(" ");
        builder.append(repeatY.cssText());
    }
}

String StylePropertySerializer::backgroundRepeatPropertyValue() const
{
    RefPtr<CSSValue> repeatX = m_propertySet.getPropertyCSSValue(CSSPropertyBackgroundRepeatX);
    RefPtr<CSSValue> repeatY = m_propertySet.getPropertyCSSValue(CSSPropertyBackgroundRepeatY);
    if (!repeatX || !repeatY)
        return String();
    if (repeatX->cssValueType() == repeatY->cssValueType()
        && (repeatX->cssValueType() == CSSValue::CSS_INITIAL || repeatX->cssValueType() == CSSValue::CSS_INHERIT)) {
        return repeatX->cssText();
    }

    RefPtr<CSSValueList> repeatXList;
    if (repeatX->cssValueType() == CSSValue::CSS_PRIMITIVE_VALUE) {
        repeatXList = CSSValueList::createCommaSeparated();
        repeatXList->append(repeatX);
    } else if (repeatX->cssValueType() == CSSValue::CSS_VALUE_LIST) {
        repeatXList = toCSSValueList(repeatX.get());
    } else {
        return String();
    }

    RefPtr<CSSValueList> repeatYList;
    if (repeatY->cssValueType() == CSSValue::CSS_PRIMITIVE_VALUE) {
        repeatYList = CSSValueList::createCommaSeparated();
        repeatYList->append(repeatY);
    } else if (repeatY->cssValueType() == CSSValue::CSS_VALUE_LIST) {
        repeatYList = toCSSValueList(repeatY.get());
    } else {
        return String();
    }

    size_t shorthandLength = lowestCommonMultiple(repeatXList->length(), repeatYList->length());
    StringBuilder builder;
    for (size_t i = 0; i < shorthandLength; ++i) {
        if (i)
            builder.appendLiteral(", ");
        appendBackgroundRepeatValue(builder,
            *repeatXList->item(i % repeatXList->length()),
            *repeatYList->item(i % repeatYList->length()));
    }
    return builder.toString();
}

void StylePropertySerializer::appendBackgroundPropertyAsText(StringBuilder& result, unsigned& numDecls) const
{
    if (isPropertyShorthandAvailable(backgroundShorthand())) {
        String backgroundValue = getPropertyValue(CSSPropertyBackground);
        result.append(getPropertyText(CSSPropertyBackground, backgroundValue, numDecls++));
        return;
    }
    if (shorthandHasOnlyInitialOrInheritedValue(backgroundShorthand())) {
        RefPtr<CSSValue> value = m_propertySet.getPropertyCSSValue(CSSPropertyBackgroundImage);
        result.append(getPropertyText(CSSPropertyBackground, value->cssText(), numDecls++));
        return;
    }

    // backgroundShorthandProperty without layered shorhand properties
    const CSSPropertyID backgroundPropertyIds[] = {
        CSSPropertyBackgroundImage,
        CSSPropertyBackgroundAttachment,
        CSSPropertyBackgroundColor,
        CSSPropertyBackgroundSize,
        CSSPropertyBackgroundOrigin,
        CSSPropertyBackgroundClip
    };

    for (unsigned i = 0; i < WTF_ARRAY_LENGTH(backgroundPropertyIds); ++i) {
        CSSPropertyID propertyID = backgroundPropertyIds[i];
        RefPtr<CSSValue> value = m_propertySet.getPropertyCSSValue(propertyID);
        if (!value)
            continue;
        result.append(getPropertyText(propertyID, value->cssText(), numDecls++));
    }

    // FIXME: This is a not-so-nice way to turn x/y positions into single background-position in output.
    // It is required because background-position-x/y are non-standard properties and WebKit generated output
    // would not work in Firefox (<rdar://problem/5143183>)
    // It would be a better solution if background-position was CSS_PAIR.
    if (shorthandHasOnlyInitialOrInheritedValue(backgroundPositionShorthand())) {
        RefPtr<CSSValue> value = m_propertySet.getPropertyCSSValue(CSSPropertyBackgroundPositionX);
        result.append(getPropertyText(CSSPropertyBackgroundPosition, value->cssText(), numDecls++));
    } else if (isPropertyShorthandAvailable(backgroundPositionShorthand())) {
        String positionValue = m_propertySet.getPropertyValue(CSSPropertyBackgroundPosition);
        if (!positionValue.isNull())
            result.append(getPropertyText(CSSPropertyBackgroundPosition, positionValue, numDecls++));
    } else {
        // should check background-position-x or background-position-y.
        if (RefPtr<CSSValue> value = m_propertySet.getPropertyCSSValue(CSSPropertyBackgroundPositionX)) {
            if (!value->isImplicitInitialValue()) {
                result.append(getPropertyText(CSSPropertyBackgroundPositionX, value->cssText(), numDecls++));
            }
        }
        if (RefPtr<CSSValue> value = m_propertySet.getPropertyCSSValue(CSSPropertyBackgroundPositionY)) {
            if (!value->isImplicitInitialValue()) {
                result.append(getPropertyText(CSSPropertyBackgroundPositionY, value->cssText(), numDecls++));
            }
        }
    }

    String repeatValue = m_propertySet.getPropertyValue(CSSPropertyBackgroundRepeat);
    if (!repeatValue.isNull())
        result.append(getPropertyText(CSSPropertyBackgroundRepeat, repeatValue, numDecls++));
}

bool StylePropertySerializer::isPropertyShorthandAvailable(const StylePropertyShorthand& shorthand) const
{
    ASSERT(shorthand.length() > 0);

    for (unsigned i = 0; i < shorthand.length(); ++i) {
        RefPtr<CSSValue> value = m_propertySet.getPropertyCSSValue(shorthand.properties()[i]);
        if (!value || (value->isInitialValue() && !value->isImplicitInitialValue()) || value->isInheritedValue())
            return false;
    }
    return true;
}

bool StylePropertySerializer::shorthandHasOnlyInitialOrInheritedValue(const StylePropertyShorthand& shorthand) const
{
    ASSERT(shorthand.length() > 0);
    bool isInitialValue = true;
    bool isInheritedValue = true;
    for (unsigned i = 0; i < shorthand.length(); ++i) {
        RefPtr<CSSValue> value = m_propertySet.getPropertyCSSValue(shorthand.properties()[i]);
        if (!value)
            return false;
        if (!value->isInitialValue())
            isInitialValue = false;
        if (!value->isInheritedValue())
            isInheritedValue = false;
    }
    return isInitialValue || isInheritedValue;
}

}
