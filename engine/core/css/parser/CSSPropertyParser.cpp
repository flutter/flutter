/*
 * Copyright (C) 2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2005 Allan Sandfeld Jensen (kde@carewolf.com)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2007 Nicholas Shanks <webkit@nickshanks.com>
 * Copyright (C) 2008 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (C) 2012 Adobe Systems Incorporated. All rights reserved.
 * Copyright (C) 2012 Intel Corporation. All rights reserved.
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
#include "sky/engine/core/css/parser/CSSPropertyParser.h"

// FIXME: Way too many!
#include <limits.h>
#include "gen/sky/core/CSSValueKeywords.h"
#include "gen/sky/core/StylePropertyShorthand.h"
#include "gen/sky/platform/RuntimeEnabledFeatures.h"
#include "sky/engine/core/css/CSSAspectRatioValue.h"
#include "sky/engine/core/css/CSSBasicShapes.h"
#include "sky/engine/core/css/CSSBorderImage.h"
#include "sky/engine/core/css/CSSCrossfadeValue.h"
#include "sky/engine/core/css/CSSCursorImageValue.h"
#include "sky/engine/core/css/CSSFontFaceSrcValue.h"
#include "sky/engine/core/css/CSSFontFeatureValue.h"
#include "sky/engine/core/css/CSSFunctionValue.h"
#include "sky/engine/core/css/CSSGradientValue.h"
#include "sky/engine/core/css/CSSImageSetValue.h"
#include "sky/engine/core/css/CSSImageValue.h"
#include "sky/engine/core/css/CSSInheritedValue.h"
#include "sky/engine/core/css/CSSInitialValue.h"
#include "sky/engine/core/css/CSSLineBoxContainValue.h"
#include "sky/engine/core/css/CSSPrimitiveValue.h"
#include "sky/engine/core/css/CSSPropertyMetadata.h"
#include "sky/engine/core/css/CSSPropertySourceData.h"
#include "sky/engine/core/css/CSSSelector.h"
#include "sky/engine/core/css/CSSShadowValue.h"
#include "sky/engine/core/css/CSSTimingFunctionValue.h"
#include "sky/engine/core/css/CSSTransformValue.h"
#include "sky/engine/core/css/CSSUnicodeRangeValue.h"
#include "sky/engine/core/css/CSSValueList.h"
#include "sky/engine/core/css/CSSValuePool.h"
#include "sky/engine/core/css/HashTools.h"
#include "sky/engine/core/css/Pair.h"
#include "sky/engine/core/css/Rect.h"
#include "sky/engine/core/css/parser/BisonCSSParser.h"
#include "sky/engine/core/css/parser/CSSParserIdioms.h"
#include "sky/engine/core/css/parser/CSSParserValues.h"
#include "sky/engine/core/html/parser/HTMLParserIdioms.h"
#include "sky/engine/platform/FloatConversion.h"
#include "sky/engine/wtf/BitArray.h"
#include "sky/engine/wtf/HexNumber.h"
#include "sky/engine/wtf/text/StringBuffer.h"
#include "sky/engine/wtf/text/StringBuilder.h"
#include "sky/engine/wtf/text/StringImpl.h"
#include "sky/engine/wtf/text/TextEncoding.h"

namespace blink {

static const double MAX_SCALE = 1000000;

template <unsigned N>
static bool equalIgnoringCase(const CSSParserString& a, const char (&b)[N])
{
    unsigned length = N - 1; // Ignore the trailing null character
    if (a.length() != length)
        return false;

    return a.is8Bit() ? WTF::equalIgnoringCase(b, a.characters8(), length) : WTF::equalIgnoringCase(b, a.characters16(), length);
}

template <unsigned N>
static bool equalIgnoringCase(CSSParserValue* value, const char (&b)[N])
{
    ASSERT(value->unit == CSSPrimitiveValue::CSS_IDENT || value->unit == CSSPrimitiveValue::CSS_STRING);
    return equalIgnoringCase(value->string, b);
}

static PassRefPtr<CSSPrimitiveValue> createPrimitiveValuePair(PassRefPtr<CSSPrimitiveValue> first, PassRefPtr<CSSPrimitiveValue> second, Pair::IdenticalValuesPolicy identicalValuesPolicy = Pair::DropIdenticalValues)
{
    return cssValuePool().createValue(Pair::create(first, second, identicalValuesPolicy));
}

CSSPropertyParser::CSSPropertyParser(CSSParserValueList* valueList,
    const CSSParserContext& context, bool inViewport,
    Vector<CSSProperty, 256>& parsedProperties,
    CSSRuleSourceData::Type ruleType)
    : m_valueList(valueList)
    , m_context(context)
    , m_inViewport(inViewport)
    , m_parsedProperties(parsedProperties)
    , m_ruleType(ruleType)
    , m_inParseShorthand(0)
    , m_currentShorthand(CSSPropertyInvalid)
    , m_implicitShorthand(false)
{
}

bool CSSPropertyParser::parseValue(CSSPropertyID property,
    CSSParserValueList* valueList, const CSSParserContext& context, bool inViewport,
    Vector<CSSProperty, 256>& parsedProperties, CSSRuleSourceData::Type ruleType)
{
    CSSPropertyParser parser(valueList, context, inViewport, parsedProperties, ruleType);
    return parser.parseValue(property);
}

void CSSPropertyParser::addProperty(CSSPropertyID propId, PassRefPtr<CSSValue> value, bool implicit)
{
    int shorthandIndex = 0;
    bool setFromShorthand = false;

    if (m_currentShorthand) {
        Vector<StylePropertyShorthand, 4> shorthands;
        getMatchingShorthandsForLonghand(propId, &shorthands);
        // Viewport descriptors have width and height as shorthands, but it doesn't
        // make sense for CSSProperties.in to consider them as such. The shorthand
        // index is only used by the inspector and doesn't affect viewport
        // descriptors.
        if (shorthands.isEmpty())
            ASSERT(m_currentShorthand == CSSPropertyWidth || m_currentShorthand == CSSPropertyHeight);
        else
            setFromShorthand = true;

        if (shorthands.size() > 1)
            shorthandIndex = indexOfShorthandForLonghand(m_currentShorthand, shorthands);
    }

    m_parsedProperties.append(CSSProperty(propId, value, setFromShorthand, shorthandIndex, m_implicitShorthand || implicit));
}

void CSSPropertyParser::rollbackLastProperties(int num)
{
    ASSERT(num >= 0);
    ASSERT(m_parsedProperties.size() >= static_cast<unsigned>(num));
    m_parsedProperties.shrink(m_parsedProperties.size() - num);
}

KURL CSSPropertyParser::completeURL(const String& url) const
{
    return m_context.completeURL(url);
}

bool CSSPropertyParser::validCalculationUnit(CSSParserValue* value, Units unitflags, ReleaseParsedCalcValueCondition releaseCalc)
{
    bool mustBeNonNegative = unitflags & (FNonNeg | FPositiveInteger);

    if (!parseCalculation(value, mustBeNonNegative ? ValueRangeNonNegative : ValueRangeAll))
        return false;

    bool b = false;
    switch (m_parsedCalculation->category()) {
    case CalcLength:
        b = (unitflags & FLength);
        break;
    case CalcNumber:
        b = (unitflags & FNumber);
        if (!b && (unitflags & (FInteger | FPositiveInteger)) && m_parsedCalculation->isInt())
            b = true;
        if (b && mustBeNonNegative && m_parsedCalculation->isNegative())
            b = false;
        // Always resolve calc() to a CSS_NUMBER in the CSSParserValue if there are no non-numbers specified in the unitflags.
        if (b && !(unitflags & ~(FInteger | FNumber | FPositiveInteger | FNonNeg))) {
            double number = m_parsedCalculation->doubleValue();
            if ((unitflags & FPositiveInteger) && number <= 0) {
                b = false;
            } else {
                delete value->function;
                value->unit = CSSPrimitiveValue::CSS_NUMBER;
                value->fValue = number;
                value->isInt = m_parsedCalculation->isInt();
            }
            m_parsedCalculation.release();
            return b;
        }
        break;
    case CalcPercent:
        b = (unitflags & FPercent);
        if (b && mustBeNonNegative && m_parsedCalculation->isNegative())
            b = false;
        break;
    case CalcPercentLength:
        b = (unitflags & FPercent) && (unitflags & FLength);
        break;
    case CalcPercentNumber:
        b = (unitflags & FPercent) && (unitflags & FNumber);
        break;
    case CalcAngle:
        b = (unitflags & FAngle);
        break;
    case CalcTime:
        b = (unitflags & FTime);
        break;
    case CalcFrequency:
        b = (unitflags & FFrequency);
        break;
    case CalcOther:
        break;
    }
    if (!b || releaseCalc == ReleaseParsedCalcValue)
        m_parsedCalculation.release();
    return b;
}

inline bool CSSPropertyParser::shouldAcceptUnitLessValues(CSSParserValue* value, Units unitflags, CSSParserMode cssParserMode)
{
    // Quirks mode and presentation attributes accept unit less values.
    return (unitflags & (FLength | FAngle | FTime)) && (!value->fValue || isUnitLessLengthParsingEnabledForMode(cssParserMode));
}

bool CSSPropertyParser::validUnit(CSSParserValue* value, Units unitflags, CSSParserMode cssParserMode, ReleaseParsedCalcValueCondition releaseCalc)
{
    if (isCalculation(value))
        return validCalculationUnit(value, unitflags, releaseCalc);

    bool b = false;
    switch (value->unit) {
    case CSSPrimitiveValue::CSS_NUMBER:
        b = (unitflags & FNumber);
        if (!b && shouldAcceptUnitLessValues(value, unitflags, cssParserMode)) {
            value->unit = (unitflags & FLength) ? CSSPrimitiveValue::CSS_PX :
                          ((unitflags & FAngle) ? CSSPrimitiveValue::CSS_DEG : CSSPrimitiveValue::CSS_MS);
            b = true;
        }
        if (!b && (unitflags & FInteger) && value->isInt)
            b = true;
        if (!b && (unitflags & FPositiveInteger) && value->isInt && value->fValue > 0)
            b = true;
        break;
    case CSSPrimitiveValue::CSS_PERCENTAGE:
        b = (unitflags & FPercent);
        break;
    case CSSPrimitiveValue::CSS_EMS:
    case CSSPrimitiveValue::CSS_CHS:
    case CSSPrimitiveValue::CSS_EXS:
    case CSSPrimitiveValue::CSS_PX:
    case CSSPrimitiveValue::CSS_CM:
    case CSSPrimitiveValue::CSS_MM:
    case CSSPrimitiveValue::CSS_IN:
    case CSSPrimitiveValue::CSS_PT:
    case CSSPrimitiveValue::CSS_PC:
    case CSSPrimitiveValue::CSS_VW:
    case CSSPrimitiveValue::CSS_VH:
    case CSSPrimitiveValue::CSS_VMIN:
    case CSSPrimitiveValue::CSS_VMAX:
        b = (unitflags & FLength);
        break;
    case CSSPrimitiveValue::CSS_MS:
    case CSSPrimitiveValue::CSS_S:
        b = (unitflags & FTime);
        break;
    case CSSPrimitiveValue::CSS_DEG:
    case CSSPrimitiveValue::CSS_RAD:
    case CSSPrimitiveValue::CSS_GRAD:
    case CSSPrimitiveValue::CSS_TURN:
        b = (unitflags & FAngle);
        break;
    case CSSPrimitiveValue::CSS_DPPX:
    case CSSPrimitiveValue::CSS_DPI:
    case CSSPrimitiveValue::CSS_DPCM:
        b = (unitflags & FResolution);
        break;
    case CSSPrimitiveValue::CSS_HZ:
    case CSSPrimitiveValue::CSS_KHZ:
    case CSSPrimitiveValue::CSS_DIMENSION:
    default:
        break;
    }
    if (b && unitflags & FNonNeg && value->fValue < 0)
        b = false;
    return b;
}

PassRefPtr<CSSPrimitiveValue> CSSPropertyParser::createPrimitiveNumericValue(CSSParserValue* value)
{
    if (m_parsedCalculation) {
        ASSERT(isCalculation(value));
        return CSSPrimitiveValue::create(m_parsedCalculation.release());
    }

    ASSERT((value->unit >= CSSPrimitiveValue::CSS_NUMBER && value->unit <= CSSPrimitiveValue::CSS_KHZ)
        || (value->unit >= CSSPrimitiveValue::CSS_TURN && value->unit <= CSSPrimitiveValue::CSS_CHS)
        || (value->unit >= CSSPrimitiveValue::CSS_VW && value->unit <= CSSPrimitiveValue::CSS_VMAX)
        || (value->unit >= CSSPrimitiveValue::CSS_DPPX && value->unit <= CSSPrimitiveValue::CSS_DPCM));
    return cssValuePool().createValue(value->fValue, static_cast<CSSPrimitiveValue::UnitType>(value->unit));
}

inline PassRefPtr<CSSPrimitiveValue> CSSPropertyParser::createPrimitiveStringValue(CSSParserValue* value)
{
    ASSERT(value->unit == CSSPrimitiveValue::CSS_STRING || value->unit == CSSPrimitiveValue::CSS_IDENT);
    return cssValuePool().createValue(value->string, CSSPrimitiveValue::CSS_STRING);
}

inline PassRefPtr<CSSValue> CSSPropertyParser::createCSSImageValueWithReferrer(const String& rawValue, const KURL& url)
{
    RefPtr<CSSValue> imageValue = CSSImageValue::create(rawValue, url);
    toCSSImageValue(imageValue.get())->setReferrer(m_context.referrer());
    return imageValue;
}

static inline bool isComma(CSSParserValue* value)
{
    return value && value->unit == CSSParserValue::Operator && value->iValue == ',';
}

static bool consumeComma(CSSParserValueList* valueList)
{
    if (!isComma(valueList->current()))
        return false;
    valueList->next();
    return true;
}

static inline bool isForwardSlashOperator(CSSParserValue* value)
{
    ASSERT(value);
    return value->unit == CSSParserValue::Operator && value->iValue == '/';
}

static bool isGeneratedImageValue(CSSParserValue* val)
{
    if (val->unit != CSSParserValue::Function)
        return false;

    return equalIgnoringCase(val->function->name, "-webkit-gradient(")
        || equalIgnoringCase(val->function->name, "-webkit-linear-gradient(")
        || equalIgnoringCase(val->function->name, "linear-gradient(")
        || equalIgnoringCase(val->function->name, "-webkit-repeating-linear-gradient(")
        || equalIgnoringCase(val->function->name, "repeating-linear-gradient(")
        || equalIgnoringCase(val->function->name, "-webkit-radial-gradient(")
        || equalIgnoringCase(val->function->name, "radial-gradient(")
        || equalIgnoringCase(val->function->name, "-webkit-repeating-radial-gradient(")
        || equalIgnoringCase(val->function->name, "repeating-radial-gradient(")
        || equalIgnoringCase(val->function->name, "-webkit-canvas(")
        || equalIgnoringCase(val->function->name, "-webkit-cross-fade(");
}

bool CSSPropertyParser::validWidthOrHeight(CSSParserValue* value)
{
    int id = value->id;
    if (id == CSSValueIntrinsic || id == CSSValueMinIntrinsic || id == CSSValueWebkitMinContent || id == CSSValueWebkitMaxContent || id == CSSValueWebkitFillAvailable || id == CSSValueWebkitFitContent)
        return true;
    return !id && validUnit(value, FLength | FPercent | FNonNeg);
}

inline PassRefPtr<CSSPrimitiveValue> CSSPropertyParser::parseValidPrimitive(CSSValueID identifier, CSSParserValue* value)
{
    if (identifier)
        return cssValuePool().createIdentifierValue(identifier);
    if (value->unit == CSSPrimitiveValue::CSS_STRING)
        return createPrimitiveStringValue(value);
    if (value->unit >= CSSPrimitiveValue::CSS_NUMBER && value->unit <= CSSPrimitiveValue::CSS_KHZ)
        return createPrimitiveNumericValue(value);
    if (value->unit >= CSSPrimitiveValue::CSS_TURN && value->unit <= CSSPrimitiveValue::CSS_CHS)
        return createPrimitiveNumericValue(value);
    if (value->unit >= CSSPrimitiveValue::CSS_VW && value->unit <= CSSPrimitiveValue::CSS_VMAX)
        return createPrimitiveNumericValue(value);
    if (value->unit >= CSSPrimitiveValue::CSS_DPPX && value->unit <= CSSPrimitiveValue::CSS_DPCM)
        return createPrimitiveNumericValue(value);
    if (isCalculation(value))
        return CSSPrimitiveValue::create(m_parsedCalculation.release());

    return nullptr;
}

void CSSPropertyParser::addExpandedPropertyForValue(CSSPropertyID propId, PassRefPtr<CSSValue> prpValue)
{
    const StylePropertyShorthand& shorthand = shorthandForProperty(propId);
    unsigned shorthandLength = shorthand.length();
    if (!shorthandLength) {
        addProperty(propId, prpValue);
        return;
    }

    RefPtr<CSSValue> value = prpValue;
    ShorthandScope scope(this, propId);
    const CSSPropertyID* longhands = shorthand.properties();
    for (unsigned i = 0; i < shorthandLength; ++i)
        addProperty(longhands[i], value);
}

bool CSSPropertyParser::parseValue(CSSPropertyID propId)
{
    if (!isInternalPropertyAndValueParsingEnabledForMode(m_context.mode()) && isInternalProperty(propId))
        return false;

    if (!m_valueList)
        return false;

    CSSParserValue* value = m_valueList->current();

    if (!value)
        return false;

    if (inViewport()) {
        // Allow @viewport rules from UA stylesheets even if the feature is disabled.
        if (!RuntimeEnabledFeatures::cssViewportEnabled() && !isUASheetBehavior(m_context.mode()))
            return false;

        return parseViewportProperty(propId);
    }

    // Note: m_parsedCalculation is used to pass the calc value to validUnit and then cleared at the end of this function.
    // FIXME: This is to avoid having to pass parsedCalc to all validUnit callers.
    ASSERT(!m_parsedCalculation);

    CSSValueID id = value->id;

    int num = inShorthand() ? 1 : m_valueList->size();

    if (id == CSSValueInherit) {
        if (num != 1)
            return false;
        addExpandedPropertyForValue(propId, cssValuePool().createInheritedValue());
        return true;
    }
    else if (id == CSSValueInitial) {
        if (num != 1)
            return false;
        addExpandedPropertyForValue(propId, cssValuePool().createExplicitInitialValue());
        return true;
    }

    if (isKeywordPropertyID(propId)) {
        if (!isValidKeywordPropertyAndValue(propId, id, m_context))
            return false;
        if (m_valueList->next() && !inShorthand())
            return false;
        addProperty(propId, cssValuePool().createIdentifierValue(id));
        return true;
    }

    bool validPrimitive = false;
    RefPtr<CSSValue> parsedValue = nullptr;

    switch (propId) {
    case CSSPropertySize:                 // <length>{1,2} | auto | [ <page-size> || [ portrait | landscape] ]
        return parseSize(propId);

    case CSSPropertyQuotes: // [<string> <string>]+ | none
        if (id == CSSValueNone)
            validPrimitive = true;
        else
            parsedValue = parseQuotes();
        break;

    case CSSPropertyClip:                 // <shape> | auto | inherit
        if (id == CSSValueAuto)
            validPrimitive = true;
        else if (value->unit == CSSParserValue::Function)
            return parseClipShape(propId);
        break;

    /* Start of supported CSS properties with validation. This is needed for parseShorthand to work
     * correctly and allows optimization in blink::applyRule(..)
     */
    case CSSPropertyOverflow: {
        ShorthandScope scope(this, propId);
        if (num != 1 || !parseValue(CSSPropertyOverflowY))
            return false;

        RefPtr<CSSValue> overflowXValue = nullptr;

        // FIXME: -webkit-paged-x or -webkit-paged-y only apply to overflow-y. If this value has been
        // set using the shorthand, then for now overflow-x will default to auto, but once we implement
        // pagination controls, it should default to hidden. If the overflow-y value is anything but
        // paged-x or paged-y, then overflow-x and overflow-y should have the same value.
        if (id == CSSValueWebkitPagedX || id == CSSValueWebkitPagedY)
            overflowXValue = cssValuePool().createIdentifierValue(CSSValueAuto);
        else
            overflowXValue = m_parsedProperties.last().value();
        addProperty(CSSPropertyOverflowX, overflowXValue.release());
        return true;
    }

    case CSSPropertyTextAlign:
        // left | right | center | justify | -webkit-match-parent
        // | start | end | <string> | inherit
        if ((id >= CSSValueLeft && id <= CSSValueWebkitMatchParent) || id == CSSValueStart || id == CSSValueEnd
            || value->unit == CSSPrimitiveValue::CSS_STRING)
            validPrimitive = true;
        break;

    case CSSPropertyFontWeight:  { // normal | bold | bolder | lighter | 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 | inherit
        if (m_valueList->size() != 1)
            return false;
        return parseFontWeight();
    }

    case CSSPropertyBorderSpacing: {
        if (num == 1) {
            ShorthandScope scope(this, CSSPropertyBorderSpacing);
            if (!parseValue(CSSPropertyWebkitBorderHorizontalSpacing))
                return false;
            CSSValue* value = m_parsedProperties.last().value();
            addProperty(CSSPropertyWebkitBorderVerticalSpacing, value);
            return true;
        }
        else if (num == 2) {
            ShorthandScope scope(this, CSSPropertyBorderSpacing);
            if (!parseValue(CSSPropertyWebkitBorderHorizontalSpacing) || !parseValue(CSSPropertyWebkitBorderVerticalSpacing))
                return false;
            return true;
        }
        return false;
    }
    case CSSPropertyWebkitBorderHorizontalSpacing:
    case CSSPropertyWebkitBorderVerticalSpacing:
        validPrimitive = validUnit(value, FLength | FNonNeg);
        break;
    case CSSPropertyOutlineColor:        // <color> | invert | inherit
        // Outline color has "invert" as additional keyword.
        if (id == CSSValueInvert) {
            validPrimitive = true;
            break;
        }
        /* nobreak */
    case CSSPropertyBackgroundColor: // <color> | inherit
    case CSSPropertyBorderTopColor: // <color> | inherit
    case CSSPropertyBorderRightColor:
    case CSSPropertyBorderBottomColor:
    case CSSPropertyBorderLeftColor:
    case CSSPropertyWebkitBorderStartColor:
    case CSSPropertyWebkitBorderEndColor:
    case CSSPropertyWebkitBorderBeforeColor:
    case CSSPropertyWebkitBorderAfterColor:
    case CSSPropertyColor: // <color> | inherit
    case CSSPropertyTextDecorationColor: // CSS3 text decoration colors
    case CSSPropertyWebkitTextEmphasisColor:
    case CSSPropertyWebkitTextFillColor:
    case CSSPropertyWebkitTextStrokeColor:
        parsedValue = parseColor();
        if (parsedValue)
            m_valueList->next();
        break;

    case CSSPropertyCursor: {
        // Grammar defined by CSS3 UI and modified by CSS4 images:
        // [ [<image> [<x> <y>]?,]*
        // [ auto | crosshair | default | pointer | progress | move | e-resize | ne-resize |
        // nw-resize | n-resize | se-resize | sw-resize | s-resize | w-resize | ew-resize |
        // ns-resize | nesw-resize | nwse-resize | col-resize | row-resize | text | wait | help |
        // vertical-text | cell | context-menu | alias | copy | no-drop | not-allowed | all-scroll |
        // zoom-in | zoom-out | -webkit-grab | -webkit-grabbing | -webkit-zoom-in | -webkit-zoom-out ] ] | inherit
        RefPtr<CSSValueList> list = nullptr;
        while (value) {
            RefPtr<CSSValue> image = nullptr;
            if (value->unit == CSSPrimitiveValue::CSS_URI) {
                String uri = value->string;
                if (!uri.isNull())
                    image = createCSSImageValueWithReferrer(uri, completeURL(uri));
            } else if (value->unit == CSSParserValue::Function && equalIgnoringCase(value->function->name, "-webkit-image-set(")) {
                image = parseImageSet(m_valueList);
                if (!image)
                    break;
            } else
                break;

            Vector<int> coords;
            value = m_valueList->next();
            while (value && validUnit(value, FNumber)) {
                coords.append(int(value->fValue));
                value = m_valueList->next();
            }
            bool hasHotSpot = false;
            IntPoint hotSpot(-1, -1);
            int nrcoords = coords.size();
            if (nrcoords > 0 && nrcoords != 2)
                return false;
            if (nrcoords == 2) {
                hasHotSpot = true;
                hotSpot = IntPoint(coords[0], coords[1]);
            }

            if (!list)
                list = CSSValueList::createCommaSeparated();

            if (image)
                list->append(CSSCursorImageValue::create(image, hasHotSpot, hotSpot));

            if (!consumeComma(m_valueList))
                return false;
            value = m_valueList->current();
        }
        if (list) {
            if (!value)
                return false;
            if (inQuirksMode() && value->id == CSSValueHand) // MSIE 5 compatibility :/
                list->append(cssValuePool().createIdentifierValue(CSSValuePointer));
            else if ((value->id >= CSSValueAuto && value->id <= CSSValueWebkitZoomOut) || value->id == CSSValueCopy || value->id == CSSValueNone)
                list->append(cssValuePool().createIdentifierValue(value->id));
            m_valueList->next();
            parsedValue = list.release();
            break;
        } else if (value) {
            id = value->id;
            if (inQuirksMode() && value->id == CSSValueHand) { // MSIE 5 compatibility :/
                id = CSSValuePointer;
                validPrimitive = true;
            } else if ((value->id >= CSSValueAuto && value->id <= CSSValueWebkitZoomOut) || value->id == CSSValueCopy || value->id == CSSValueNone)
                validPrimitive = true;
        } else {
            ASSERT_NOT_REACHED();
            return false;
        }
        break;
    }

    case CSSPropertyBackgroundAttachment:
    case CSSPropertyBackgroundClip:
    case CSSPropertyWebkitBackgroundClip:
    case CSSPropertyWebkitBackgroundComposite:
    case CSSPropertyBackgroundImage:
    case CSSPropertyBackgroundOrigin:
    case CSSPropertyWebkitBackgroundOrigin:
    case CSSPropertyBackgroundPosition:
    case CSSPropertyBackgroundPositionX:
    case CSSPropertyBackgroundPositionY:
    case CSSPropertyBackgroundSize:
    case CSSPropertyWebkitBackgroundSize:
    case CSSPropertyBackgroundRepeat:
    {
        RefPtr<CSSValue> val1 = nullptr;
        RefPtr<CSSValue> val2 = nullptr;
        CSSPropertyID propId1, propId2;
        bool result = false;
        if (parseFillProperty(propId, propId1, propId2, val1, val2)) {
            if (propId == CSSPropertyBackgroundPosition ||
                propId == CSSPropertyBackgroundRepeat) {
                ShorthandScope scope(this, propId);
                addProperty(propId1, val1.release());
                if (val2)
                    addProperty(propId2, val2.release());
            } else {
                addProperty(propId1, val1.release());
                if (val2)
                    addProperty(propId2, val2.release());
            }
            result = true;
        }
        m_implicitShorthand = false;
        return result;
    }
    case CSSPropertyObjectPosition:
        ASSERT(RuntimeEnabledFeatures::objectFitPositionEnabled());
        parsedValue = parseObjectPosition();
        break;
    case CSSPropertyListStyleImage:     // <uri> | none | inherit
    case CSSPropertyBorderImageSource:
        if (id == CSSValueNone) {
            parsedValue = cssValuePool().createIdentifierValue(CSSValueNone);
            m_valueList->next();
        } else if (value->unit == CSSPrimitiveValue::CSS_URI) {
            parsedValue = createCSSImageValueWithReferrer(value->string, completeURL(value->string));
            m_valueList->next();
        } else if (isGeneratedImageValue(value)) {
            if (parseGeneratedImage(m_valueList, parsedValue))
                m_valueList->next();
            else
                return false;
        }
        else if (value->unit == CSSParserValue::Function && equalIgnoringCase(value->function->name, "-webkit-image-set(")) {
            parsedValue = parseImageSet(m_valueList);
            if (!parsedValue)
                return false;
            m_valueList->next();
        }
        break;

    case CSSPropertyWebkitTextStrokeWidth:
    case CSSPropertyOutlineWidth:        // <border-width> | inherit
    case CSSPropertyBorderTopWidth:     //// <border-width> | inherit
    case CSSPropertyBorderRightWidth:   //   Which is defined as
    case CSSPropertyBorderBottomWidth:  //   thin | medium | thick | <length>
    case CSSPropertyBorderLeftWidth:
    case CSSPropertyWebkitBorderStartWidth:
    case CSSPropertyWebkitBorderEndWidth:
    case CSSPropertyWebkitBorderBeforeWidth:
    case CSSPropertyWebkitBorderAfterWidth:
        if (id == CSSValueThin || id == CSSValueMedium || id == CSSValueThick)
            validPrimitive = true;
        else
            validPrimitive = validUnit(value, FLength | FNonNeg);
        break;

    case CSSPropertyLetterSpacing:       // normal | <length> | inherit
    case CSSPropertyWordSpacing:         // normal | <length> | inherit
        if (id == CSSValueNormal)
            validPrimitive = true;
        else
            validPrimitive = validUnit(value, FLength);
        break;

    case CSSPropertyTextIndent:
        parsedValue = parseTextIndent();
        break;

    case CSSPropertyPaddingTop:          //// <padding-width> | inherit
    case CSSPropertyPaddingRight:        //   Which is defined as
    case CSSPropertyPaddingBottom:       //   <length> | <percentage>
    case CSSPropertyPaddingLeft:         ////
    case CSSPropertyWebkitPaddingStart:
    case CSSPropertyWebkitPaddingEnd:
    case CSSPropertyWebkitPaddingBefore:
    case CSSPropertyWebkitPaddingAfter:
        validPrimitive = (!id && validUnit(value, FLength | FPercent | FNonNeg));
        break;

    case CSSPropertyMaxWidth:
    case CSSPropertyWebkitMaxLogicalWidth:
    case CSSPropertyMaxHeight:
    case CSSPropertyWebkitMaxLogicalHeight:
        validPrimitive = (id == CSSValueNone || validWidthOrHeight(value));
        break;

    case CSSPropertyMinWidth:
    case CSSPropertyWebkitMinLogicalWidth:
    case CSSPropertyMinHeight:
    case CSSPropertyWebkitMinLogicalHeight:
        validPrimitive = validWidthOrHeight(value);
        break;

    case CSSPropertyWidth:
    case CSSPropertyWebkitLogicalWidth:
    case CSSPropertyHeight:
    case CSSPropertyWebkitLogicalHeight:
        validPrimitive = (id == CSSValueAuto || validWidthOrHeight(value));
        break;

    case CSSPropertyFontSize:
        return parseFontSize();

    case CSSPropertyFontVariant:         // normal | small-caps | inherit
        return parseFontVariant();

    case CSSPropertyVerticalAlign:
        // baseline | sub | super | top | text-top | middle | bottom | text-bottom |
        // <percentage> | <length> | inherit

        if (id >= CSSValueBaseline && id <= CSSValueWebkitBaselineMiddle)
            validPrimitive = true;
        else
            validPrimitive = (!id && validUnit(value, FLength | FPercent));
        break;

    case CSSPropertyBottom:               // <length> | <percentage> | auto | inherit
    case CSSPropertyLeft:                 // <length> | <percentage> | auto | inherit
    case CSSPropertyRight:                // <length> | <percentage> | auto | inherit
    case CSSPropertyTop:                  // <length> | <percentage> | auto | inherit
    case CSSPropertyMarginTop:           //// <margin-width> | inherit
    case CSSPropertyMarginRight:         //   Which is defined as
    case CSSPropertyMarginBottom:        //   <length> | <percentage> | auto | inherit
    case CSSPropertyMarginLeft:          ////
    case CSSPropertyWebkitMarginStart:
    case CSSPropertyWebkitMarginEnd:
    case CSSPropertyWebkitMarginBefore:
    case CSSPropertyWebkitMarginAfter:
        if (id == CSSValueAuto)
            validPrimitive = true;
        else
            validPrimitive = (!id && validUnit(value, FLength | FPercent));
        break;

    case CSSPropertyOrphans: // <integer> | inherit | auto (We've added support for auto for backwards compatibility)
    case CSSPropertyWidows: // <integer> | inherit | auto (Ditto)
        if (id == CSSValueAuto)
            validPrimitive = true;
        else
            validPrimitive = (!id && validUnit(value, FPositiveInteger));
        break;

    case CSSPropertyZIndex: // auto | <integer> | inherit
        if (id == CSSValueAuto)
            validPrimitive = true;
        else
            validPrimitive = (!id && validUnit(value, FInteger));
        break;

    case CSSPropertyLineHeight:
        return parseLineHeight();
    case CSSPropertyFontFamily:
        // [[ <family-name> | <generic-family> ],]* [<family-name> | <generic-family>] | inherit
    {
        parsedValue = parseFontFamily();
        break;
    }

    case CSSPropertyTextDecoration:
        // Fall through 'text-decoration-line' parsing if CSS 3 Text Decoration
        // is disabled to match CSS 2.1 rules for parsing 'text-decoration'.
        if (RuntimeEnabledFeatures::css3TextDecorationsEnabled()) {
            // [ <text-decoration-line> || <text-decoration-style> || <text-decoration-color> ] | inherit
            return parseShorthand(CSSPropertyTextDecoration, textDecorationShorthand());
        }
    case CSSPropertyWebkitTextDecorationsInEffect:
    case CSSPropertyTextDecorationLine:
        // none | [ underline || overline || line-through || blink ] | inherit
        return parseTextDecoration(propId);

    case CSSPropertyTextUnderlinePosition:
        // auto | under | inherit
        ASSERT(RuntimeEnabledFeatures::css3TextDecorationsEnabled());
        return parseTextUnderlinePosition();

    case CSSPropertySrc: // Only used within @font-face and @-webkit-filter, so cannot use inherit | initial. This is a list of urls or local references.
        parsedValue = parseFontFaceSrc();
        break;

    case CSSPropertyUnicodeRange:
        parsedValue = parseFontFaceUnicodeRange();
        break;

    /* CSS3 properties */

    case CSSPropertyBorderImage:
        return parseBorderImageShorthand(propId);
    case CSSPropertyWebkitBorderImage: {
        if (RefPtr<CSSValue> result = parseBorderImage(propId)) {
            addProperty(propId, result);
            return true;
        }
        return false;
    }

    case CSSPropertyBorderImageOutset: {
        RefPtr<CSSPrimitiveValue> result = nullptr;
        if (parseBorderImageOutset(result)) {
            addProperty(propId, result);
            return true;
        }
        break;
    }
    case CSSPropertyBorderImageRepeat: {
        RefPtr<CSSValue> result = nullptr;
        if (parseBorderImageRepeat(result)) {
            addProperty(propId, result);
            return true;
        }
        break;
    }
    case CSSPropertyBorderImageSlice: {
        RefPtr<CSSBorderImageSliceValue> result = nullptr;
        if (parseBorderImageSlice(propId, result)) {
            addProperty(propId, result);
            return true;
        }
        break;
    }
    case CSSPropertyBorderImageWidth: {
        RefPtr<CSSPrimitiveValue> result = nullptr;
        if (parseBorderImageWidth(result)) {
            addProperty(propId, result);
            return true;
        }
        break;
    }
    case CSSPropertyBorderTopRightRadius:
    case CSSPropertyBorderTopLeftRadius:
    case CSSPropertyBorderBottomLeftRadius:
    case CSSPropertyBorderBottomRightRadius: {
        if (num != 1 && num != 2)
            return false;
        validPrimitive = validUnit(value, FLength | FPercent | FNonNeg);
        if (!validPrimitive)
            return false;
        RefPtr<CSSPrimitiveValue> parsedValue1 = createPrimitiveNumericValue(value);
        RefPtr<CSSPrimitiveValue> parsedValue2 = nullptr;
        if (num == 2) {
            value = m_valueList->next();
            validPrimitive = validUnit(value, FLength | FPercent | FNonNeg);
            if (!validPrimitive)
                return false;
            parsedValue2 = createPrimitiveNumericValue(value);
        } else
            parsedValue2 = parsedValue1;

        addProperty(propId, createPrimitiveValuePair(parsedValue1.release(), parsedValue2.release()));
        return true;
    }
    case CSSPropertyTabSize:
        validPrimitive = validUnit(value, FInteger | FNonNeg);
        break;
    case CSSPropertyWebkitAspectRatio:
        parsedValue = parseAspectRatio();
        break;
    case CSSPropertyBorderRadius:
    case CSSPropertyWebkitBorderRadius:
        return parseBorderRadius(propId);
    case CSSPropertyOutlineOffset:
        validPrimitive = validUnit(value, FLength);
        break;
    case CSSPropertyTextShadow: // CSS2 property, dropped in CSS2.1, back in CSS3, so treat as CSS3
    case CSSPropertyBoxShadow:
    case CSSPropertyWebkitBoxShadow:
        if (id == CSSValueNone)
            validPrimitive = true;
        else {
            RefPtr<CSSValueList> shadowValueList = parseShadow(m_valueList, propId);
            if (shadowValueList) {
                addProperty(propId, shadowValueList.release());
                m_valueList->next();
                return true;
            }
            return false;
        }
        break;
    case CSSPropertyOpacity:
        validPrimitive = validUnit(value, FNumber);
        break;
    case CSSPropertyFilter:
        if (id == CSSValueNone)
            validPrimitive = true;
        else {
            RefPtr<CSSValue> val = parseFilter();
            if (val) {
                addProperty(propId, val);
                return true;
            }
            return false;
        }
        break;
    case CSSPropertyFlex: {
        ShorthandScope scope(this, propId);
        if (id == CSSValueNone) {
            addProperty(CSSPropertyFlexGrow, cssValuePool().createValue(0, CSSPrimitiveValue::CSS_NUMBER));
            addProperty(CSSPropertyFlexShrink, cssValuePool().createValue(0, CSSPrimitiveValue::CSS_NUMBER));
            addProperty(CSSPropertyFlexBasis, cssValuePool().createIdentifierValue(CSSValueAuto));
            return true;
        }
        return parseFlex(m_valueList);
    }
    case CSSPropertyFlexBasis:
        // FIXME: Support intrinsic dimensions too.
        if (id == CSSValueAuto)
            validPrimitive = true;
        else
            validPrimitive = (!id && validUnit(value, FLength | FPercent | FNonNeg));
        break;
    case CSSPropertyFlexGrow:
    case CSSPropertyFlexShrink:
        validPrimitive = validUnit(value, FNumber | FNonNeg);
        break;
    case CSSPropertyOrder:
        validPrimitive = validUnit(value, FInteger);
        break;
    case CSSPropertyTransform:
    case CSSPropertyWebkitTransform:
        if (id == CSSValueNone)
            validPrimitive = true;
        else {
            RefPtr<CSSValue> transformValue = parseTransform(propId);
            if (transformValue) {
                addProperty(propId, transformValue.release());
                return true;
            }
            return false;
        }
        break;
    case CSSPropertyTransformOrigin: {
        RefPtr<CSSValueList> list = parseTransformOrigin();
        if (!list)
            return false;
        // These values are added to match gecko serialization.
        if (list->length() == 1)
            list->append(cssValuePool().createValue(50, CSSPrimitiveValue::CSS_PERCENTAGE));
        if (list->length() == 2)
            list->append(cssValuePool().createValue(0, CSSPrimitiveValue::CSS_PX));
        addProperty(propId, list.release());
        return true;
    }
    case CSSPropertyWebkitPerspectiveOriginX:
    case CSSPropertyWebkitTransformOriginX:
        parsedValue = parseFillPositionX(m_valueList);
        if (parsedValue)
            m_valueList->next();
        break;
    case CSSPropertyWebkitPerspectiveOriginY:
    case CSSPropertyWebkitTransformOriginY:
        parsedValue = parseFillPositionY(m_valueList);
        if (parsedValue)
            m_valueList->next();
        break;
    case CSSPropertyWebkitTransformOriginZ:
        validPrimitive = validUnit(value, FLength);
        break;
    case CSSPropertyWebkitTransformOrigin:
        return parseWebkitTransformOriginShorthand();
    case CSSPropertyPerspective:
        if (id == CSSValueNone) {
            validPrimitive = true;
        } else if (validUnit(value, FLength | FNonNeg)) {
            addProperty(propId, createPrimitiveNumericValue(value));
            return true;
        }
        break;
    case CSSPropertyWebkitPerspective:
        if (id == CSSValueNone) {
            validPrimitive = true;
        } else if (validUnit(value, FNumber | FLength | FNonNeg)) {
            // Accepting valueless numbers is a quirk of the -webkit prefixed version of the property.
            addProperty(propId, createPrimitiveNumericValue(value));
            return true;
        }
        break;
    case CSSPropertyPerspectiveOrigin: {
        RefPtr<CSSValueList> list = parseTransformOrigin();
        if (!list || list->length() == 3)
            return false;
        // This values are added to match gecko serialization.
        if (list->length() == 1)
            list->append(cssValuePool().createValue(50, CSSPrimitiveValue::CSS_PERCENTAGE));
        addProperty(propId, list.release());
        return true;
    }
    case CSSPropertyWebkitPerspectiveOrigin: {
        if (m_valueList->size() > 2)
            return false;
        RefPtr<CSSValue> originX = nullptr;
        RefPtr<CSSValue> originY = nullptr;
        parse2ValuesFillPosition(m_valueList, originX, originY);
        if (!originX)
            return false;
        addProperty(CSSPropertyWebkitPerspectiveOriginX, originX.release());
        addProperty(CSSPropertyWebkitPerspectiveOriginY, originY.release());
        return true;
    }
    case CSSPropertyAnimationDelay:
    case CSSPropertyAnimationDirection:
    case CSSPropertyAnimationDuration:
    case CSSPropertyAnimationFillMode:
    case CSSPropertyAnimationName:
    case CSSPropertyAnimationPlayState:
    case CSSPropertyAnimationIterationCount:
    case CSSPropertyAnimationTimingFunction:
    case CSSPropertyTransitionDelay:
    case CSSPropertyTransitionDuration:
    case CSSPropertyTransitionTimingFunction:
    case CSSPropertyTransitionProperty: {
        if (RefPtr<CSSValueList> val = parseAnimationPropertyList(propId)) {
            addProperty(propId, val.release());
            return true;
        }
        return false;
    }

    case CSSPropertyWillChange:
        parsedValue = parseWillChange();
        break;
    // End of CSS3 properties

    // Apple specific properties.  These will never be standardized and are purely to
    // support custom WebKit-based Apple applications.
    case CSSPropertyWebkitFontSizeDelta:           // <length>
        validPrimitive = validUnit(value, FLength);
        break;

    case CSSPropertyWebkitHighlight:
        if (id == CSSValueNone || value->unit == CSSPrimitiveValue::CSS_STRING)
            validPrimitive = true;
        break;

    case CSSPropertyWebkitHyphenateCharacter:
        if (id == CSSValueAuto || value->unit == CSSPrimitiveValue::CSS_STRING)
            validPrimitive = true;
        break;

    case CSSPropertyWebkitLocale:
        if (id == CSSValueAuto || value->unit == CSSPrimitiveValue::CSS_STRING)
            validPrimitive = true;
        break;

    // End Apple-specific properties

    case CSSPropertyWebkitTapHighlightColor:
        parsedValue = parseColor();
        if (parsedValue)
            m_valueList->next();
        break;

        /* shorthand properties */
    case CSSPropertyBackground: {
        // Position must come before color in this array because a plain old "0" is a legal color
        // in quirks mode but it's usually the X coordinate of a position.
        const CSSPropertyID properties[] = { CSSPropertyBackgroundImage, CSSPropertyBackgroundRepeat,
                                   CSSPropertyBackgroundAttachment, CSSPropertyBackgroundPosition, CSSPropertyBackgroundOrigin,
                                   CSSPropertyBackgroundClip, CSSPropertyBackgroundColor, CSSPropertyBackgroundSize };
        return parseFillShorthand(propId, properties, WTF_ARRAY_LENGTH(properties));
    }
    case CSSPropertyBorder:
        // [ 'border-width' || 'border-style' || <color> ] | inherit
    {
        if (parseShorthand(propId, parsingShorthandForProperty(CSSPropertyBorder))) {
            // The CSS3 Borders and Backgrounds specification says that border also resets border-image. It's as
            // though a value of none was specified for the image.
            addExpandedPropertyForValue(CSSPropertyBorderImage, cssValuePool().createImplicitInitialValue());
            return true;
        }
        return false;
    }
    case CSSPropertyBorderTop:
        // [ 'border-top-width' || 'border-style' || <color> ] | inherit
        return parseShorthand(propId, borderTopShorthand());
    case CSSPropertyBorderRight:
        // [ 'border-right-width' || 'border-style' || <color> ] | inherit
        return parseShorthand(propId, borderRightShorthand());
    case CSSPropertyBorderBottom:
        // [ 'border-bottom-width' || 'border-style' || <color> ] | inherit
        return parseShorthand(propId, borderBottomShorthand());
    case CSSPropertyBorderLeft:
        // [ 'border-left-width' || 'border-style' || <color> ] | inherit
        return parseShorthand(propId, borderLeftShorthand());
    case CSSPropertyWebkitBorderStart:
        return parseShorthand(propId, webkitBorderStartShorthand());
    case CSSPropertyWebkitBorderEnd:
        return parseShorthand(propId, webkitBorderEndShorthand());
    case CSSPropertyWebkitBorderBefore:
        return parseShorthand(propId, webkitBorderBeforeShorthand());
    case CSSPropertyWebkitBorderAfter:
        return parseShorthand(propId, webkitBorderAfterShorthand());
    case CSSPropertyOutline:
        // [ 'outline-color' || 'outline-style' || 'outline-width' ] | inherit
        return parseShorthand(propId, outlineShorthand());
    case CSSPropertyBorderColor:
        // <color>{1,4} | inherit
        return parse4Values(propId, borderColorShorthand().properties());
    case CSSPropertyBorderWidth:
        // <border-width>{1,4} | inherit
        return parse4Values(propId, borderWidthShorthand().properties());
    case CSSPropertyBorderStyle:
        // <border-style>{1,4} | inherit
        return parse4Values(propId, borderStyleShorthand().properties());
    case CSSPropertyMargin:
        // <margin-width>{1,4} | inherit
        return parse4Values(propId, marginShorthand().properties());
    case CSSPropertyPadding:
        // <padding-width>{1,4} | inherit
        return parse4Values(propId, paddingShorthand().properties());
    case CSSPropertyFlexFlow:
        return parseShorthand(propId, flexFlowShorthand());
    case CSSPropertyFont:
        // [ [ 'font-style' || 'font-variant' || 'font-weight' ]? 'font-size' [ / 'line-height' ]?
        // 'font-family' ] | inherit
        return parseFont();
    case CSSPropertyListStyle:
        return parseShorthand(propId, listStyleShorthand());
    case CSSPropertyWebkitTextStroke:
        return parseShorthand(propId, webkitTextStrokeShorthand());
    case CSSPropertyAnimation:
        return parseAnimationShorthand(propId);
    case CSSPropertyTransition:
        return parseTransitionShorthand(propId);
    case CSSPropertyInvalid:
        return false;
    case CSSPropertyPage:
        return parsePage(propId);
    // CSS Text Layout Module Level 3: Vertical writing support
    case CSSPropertyWebkitTextEmphasis:
        return parseShorthand(propId, webkitTextEmphasisShorthand());

    case CSSPropertyWebkitTextEmphasisStyle:
        return parseTextEmphasisStyle();

    case CSSPropertyWebkitTextOrientation:
        // FIXME: For now just support sideways, sideways-right, upright and vertical-right.
        if (id == CSSValueSideways || id == CSSValueSidewaysRight || id == CSSValueVerticalRight || id == CSSValueUpright)
            validPrimitive = true;
        break;

    case CSSPropertyWebkitLineBoxContain:
        if (id == CSSValueNone)
            validPrimitive = true;
        else
            return parseLineBoxContain();
        break;
    case CSSPropertyWebkitFontFeatureSettings:
        if (id == CSSValueNormal)
            validPrimitive = true;
        else
            return parseFontFeatureSettings();
        break;

    case CSSPropertyFontVariantLigatures:
        if (id == CSSValueNormal)
            validPrimitive = true;
        else
            return parseFontVariantLigatures();
        break;
    case CSSPropertyWebkitClipPath:
        if (id == CSSValueNone) {
            validPrimitive = true;
        } else if (value->unit == CSSParserValue::Function) {
            parsedValue = parseBasicShape();
        } else if (value->unit == CSSPrimitiveValue::CSS_URI) {
            parsedValue = CSSPrimitiveValue::create(value->string, CSSPrimitiveValue::CSS_URI);
            addProperty(propId, parsedValue.release());
            return true;
        }
        break;
    case CSSPropertyTouchAction:
        parsedValue = parseTouchAction();
        break;

    // Properties below are validated inside parseViewportProperty, because we
    // check for parser state. We need to invalidate if someone adds them outside
    // a @viewport rule.
    case CSSPropertyOrientation:
        validPrimitive = false;
        break;

    default:
        return false;
    }

    if (validPrimitive) {
        parsedValue = parseValidPrimitive(id, value);
        m_valueList->next();
    }
    ASSERT(!m_parsedCalculation);
    if (parsedValue) {
        if (!m_valueList->current() || inShorthand()) {
            addProperty(propId, parsedValue.release());
            return true;
        }
    }
    return false;
}

void CSSPropertyParser::addFillValue(RefPtr<CSSValue>& lval, PassRefPtr<CSSValue> rval)
{
    if (lval) {
        if (lval->isBaseValueList())
            toCSSValueList(lval.get())->append(rval);
        else {
            PassRefPtr<CSSValue> oldlVal(lval.release());
            PassRefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
            list->append(oldlVal);
            list->append(rval);
            lval = list;
        }
    }
    else
        lval = rval;
}

static bool parseBackgroundClip(CSSParserValue* parserValue, RefPtr<CSSValue>& cssValue)
{
    if (parserValue->id == CSSValueBorderBox || parserValue->id == CSSValuePaddingBox
        || parserValue->id == CSSValueContentBox) {
        cssValue = cssValuePool().createIdentifierValue(parserValue->id);
        return true;
    }
    return false;
}

const int cMaxFillProperties = 9;

bool CSSPropertyParser::parseFillShorthand(CSSPropertyID propId, const CSSPropertyID* properties, int numProperties)
{
    ASSERT(numProperties <= cMaxFillProperties);
    if (numProperties > cMaxFillProperties)
        return false;

    ShorthandScope scope(this, propId);

    bool parsedProperty[cMaxFillProperties] = { false };
    RefPtr<CSSValue> values[cMaxFillProperties];
#if ENABLE(OILPAN)
    // Zero initialize the array of raw pointers.
    memset(&values, 0, sizeof(values));
#endif
    RefPtr<CSSValue> clipValue = nullptr;
    RefPtr<CSSValue> positionYValue = nullptr;
    RefPtr<CSSValue> repeatYValue = nullptr;
    bool foundClip = false;
    int i;
    bool foundPositionCSSProperty = false;

    while (m_valueList->current()) {
        CSSParserValue* val = m_valueList->current();
        if (val->unit == CSSParserValue::Operator && val->iValue == ',') {
            // We hit the end.  Fill in all remaining values with the initial value.
            m_valueList->next();
            for (i = 0; i < numProperties; ++i) {
                if (properties[i] == CSSPropertyBackgroundColor && parsedProperty[i])
                    // Color is not allowed except as the last item in a list for backgrounds.
                    // Reject the entire property.
                    return false;

                if (!parsedProperty[i] && properties[i] != CSSPropertyBackgroundColor) {
                    addFillValue(values[i], cssValuePool().createImplicitInitialValue());
                    if (properties[i] == CSSPropertyBackgroundPosition)
                        addFillValue(positionYValue, cssValuePool().createImplicitInitialValue());
                    if (properties[i] == CSSPropertyBackgroundRepeat)
                        addFillValue(repeatYValue, cssValuePool().createImplicitInitialValue());
                    if (properties[i] == CSSPropertyBackgroundOrigin && !parsedProperty[i]) {
                        // If background-origin wasn't present, then reset background-clip also.
                        addFillValue(clipValue, cssValuePool().createImplicitInitialValue());
                    }
                }
                parsedProperty[i] = false;
            }
            if (!m_valueList->current())
                break;
        }

        bool sizeCSSPropertyExpected = false;
        if (isForwardSlashOperator(val) && foundPositionCSSProperty) {
            sizeCSSPropertyExpected = true;
            m_valueList->next();
        }

        foundPositionCSSProperty = false;
        bool found = false;
        for (i = 0; !found && i < numProperties; ++i) {

            if (sizeCSSPropertyExpected && properties[i] != CSSPropertyBackgroundSize)
                continue;
            if (!sizeCSSPropertyExpected && properties[i] == CSSPropertyBackgroundSize)
                continue;

            if (!parsedProperty[i]) {
                RefPtr<CSSValue> val1 = nullptr;
                RefPtr<CSSValue> val2 = nullptr;
                CSSPropertyID propId1, propId2;
                CSSParserValue* parserValue = m_valueList->current();
                // parseFillProperty() may modify m_implicitShorthand, so we MUST reset it
                // before EACH return below.
                if (parseFillProperty(properties[i], propId1, propId2, val1, val2)) {
                    parsedProperty[i] = found = true;
                    addFillValue(values[i], val1.release());
                    if (properties[i] == CSSPropertyBackgroundPosition)
                        addFillValue(positionYValue, val2.release());
                    if (properties[i] == CSSPropertyBackgroundRepeat)
                        addFillValue(repeatYValue, val2.release());
                    if (properties[i] == CSSPropertyBackgroundOrigin) {
                        // Reparse the value as a clip, and see if we succeed.
                        if (parseBackgroundClip(parserValue, val1))
                            addFillValue(clipValue, val1.release()); // The property parsed successfully.
                        else
                            addFillValue(clipValue, cssValuePool().createImplicitInitialValue()); // Some value was used for origin that is not supported by clip. Just reset clip instead.
                    }
                    if (properties[i] == CSSPropertyBackgroundClip) {
                        // Update clipValue
                        addFillValue(clipValue, val1.release());
                        foundClip = true;
                    }
                    if (properties[i] == CSSPropertyBackgroundPosition)
                        foundPositionCSSProperty = true;
                }
            }
        }

        // if we didn't find at least one match, this is an
        // invalid shorthand and we have to ignore it
        if (!found) {
            m_implicitShorthand = false;
            return false;
        }
    }

    // Now add all of the properties we found.
    for (i = 0; i < numProperties; i++) {
        // Fill in any remaining properties with the initial value.
        if (!parsedProperty[i]) {
            addFillValue(values[i], cssValuePool().createImplicitInitialValue());
            if (properties[i] == CSSPropertyBackgroundPosition)
                addFillValue(positionYValue, cssValuePool().createImplicitInitialValue());
            if (properties[i] == CSSPropertyBackgroundRepeat)
                addFillValue(repeatYValue, cssValuePool().createImplicitInitialValue());
            if (properties[i] == CSSPropertyBackgroundOrigin) {
                // If background-origin wasn't present, then reset background-clip also.
                addFillValue(clipValue, cssValuePool().createImplicitInitialValue());
            }
        }
        if (properties[i] == CSSPropertyBackgroundPosition) {
            addProperty(CSSPropertyBackgroundPositionX, values[i].release());
            // it's OK to call positionYValue.release() since we only see CSSPropertyBackgroundPosition once
            addProperty(CSSPropertyBackgroundPositionY, positionYValue.release());
        } else if (properties[i] == CSSPropertyBackgroundRepeat) {
            addProperty(CSSPropertyBackgroundRepeatX, values[i].release());
            // it's OK to call repeatYValue.release() since we only see CSSPropertyBackgroundPosition once
            addProperty(CSSPropertyBackgroundRepeatY, repeatYValue.release());
        } else if (properties[i] == CSSPropertyBackgroundClip && !foundClip)
            // Value is already set while updating origin
            continue;
        else
            addProperty(properties[i], values[i].release());

        // Add in clip values when we hit the corresponding origin property.
        if (properties[i] == CSSPropertyBackgroundOrigin && !foundClip)
            addProperty(CSSPropertyBackgroundClip, clipValue.release());
    }

    m_implicitShorthand = false;
    return true;
}

static bool isValidTransitionPropertyList(CSSValueList* value)
{
    if (value->length() < 2)
        return true;
    for (CSSValueListIterator i = value; i.hasMore(); i.advance()) {
        // FIXME: Shorthand parsing shouldn't add initial to the list since it won't round-trip
        if (i.value()->isInitialValue())
            continue;
        CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(i.value());
        if (primitiveValue->isValueID() && primitiveValue->getValueID() == CSSValueNone)
            return false;
    }
    return true;
}

bool CSSPropertyParser::parseAnimationShorthand(CSSPropertyID propId)
{
    const StylePropertyShorthand& animationProperties = parsingShorthandForProperty(propId);
    const unsigned numProperties = 8;

    // The list of properties in the shorthand should be the same
    // length as the list with animation name in last position, even though they are
    // in a different order.
    ASSERT(numProperties == animationProperties.length());
    ASSERT(numProperties == shorthandForProperty(propId).length());

    ShorthandScope scope(this, propId);

    bool parsedProperty[numProperties] = { false };
    RefPtr<CSSValueList> values[numProperties];
    for (size_t i = 0; i < numProperties; ++i)
        values[i] = CSSValueList::createCommaSeparated();

    while (m_valueList->current()) {
        if (consumeComma(m_valueList)) {
            // We hit the end. Fill in all remaining values with the initial value.
            for (size_t i = 0; i < numProperties; ++i) {
                if (!parsedProperty[i])
                    values[i]->append(cssValuePool().createImplicitInitialValue());
                parsedProperty[i] = false;
            }
            if (!m_valueList->current())
                break;
        }

        bool found = false;
        for (size_t i = 0; i < numProperties; ++i) {
            if (parsedProperty[i])
                continue;
            if (RefPtr<CSSValue> val = parseAnimationProperty(animationProperties.properties()[i])) {
                parsedProperty[i] = found = true;
                values[i]->append(val.release());
                break;
            }
        }

        // if we didn't find at least one match, this is an
        // invalid shorthand and we have to ignore it
        if (!found)
            return false;
    }

    for (size_t i = 0; i < numProperties; ++i) {
        // If we didn't find the property, set an intial value.
        if (!parsedProperty[i])
            values[i]->append(cssValuePool().createImplicitInitialValue());

        addProperty(animationProperties.properties()[i], values[i].release());
    }

    return true;
}

bool CSSPropertyParser::parseTransitionShorthand(CSSPropertyID propId)
{
    const unsigned numProperties = 4;
    const StylePropertyShorthand& shorthand = parsingShorthandForProperty(propId);
    ASSERT(numProperties == shorthand.length());

    ShorthandScope scope(this, propId);

    bool parsedProperty[numProperties] = { false };
    RefPtr<CSSValueList> values[numProperties];
    for (size_t i = 0; i < numProperties; ++i)
        values[i] = CSSValueList::createCommaSeparated();

    while (m_valueList->current()) {
        if (consumeComma(m_valueList)) {
            // We hit the end. Fill in all remaining values with the initial value.
            for (size_t i = 0; i < numProperties; ++i) {
                if (!parsedProperty[i])
                    values[i]->append(cssValuePool().createImplicitInitialValue());
                parsedProperty[i] = false;
            }
            if (!m_valueList->current())
                break;
        }

        bool found = false;
        for (size_t i = 0; i < numProperties; ++i) {
            if (parsedProperty[i])
                continue;
            if (RefPtr<CSSValue> val = parseAnimationProperty(shorthand.properties()[i])) {
                parsedProperty[i] = found = true;
                values[i]->append(val.release());
                break;
            }
        }

        // if we didn't find at least one match, this is an
        // invalid shorthand and we have to ignore it
        if (!found)
            return false;
    }

    ASSERT(shorthand.properties()[3] == CSSPropertyTransitionProperty);
    if (!isValidTransitionPropertyList(values[3].get()))
        return false;

    // Fill in any remaining properties with the initial value and add
    for (size_t i = 0; i < numProperties; ++i) {
        if (!parsedProperty[i])
            values[i]->append(cssValuePool().createImplicitInitialValue());
        addProperty(shorthand.properties()[i], values[i].release());
    }

    return true;
}

bool CSSPropertyParser::parseShorthand(CSSPropertyID propId, const StylePropertyShorthand& shorthand)
{
    // We try to match as many properties as possible
    // We set up an array of booleans to mark which property has been found,
    // and we try to search for properties until it makes no longer any sense.
    ShorthandScope scope(this, propId);

    bool found = false;
    unsigned propertiesParsed = 0;
    bool propertyFound[6] = { false, false, false, false, false, false }; // 6 is enough size.

    while (m_valueList->current()) {
        found = false;
        for (unsigned propIndex = 0; !found && propIndex < shorthand.length(); ++propIndex) {
            if (!propertyFound[propIndex] && parseValue(shorthand.properties()[propIndex])) {
                propertyFound[propIndex] = found = true;
                propertiesParsed++;
            }
        }

        // if we didn't find at least one match, this is an
        // invalid shorthand and we have to ignore it
        if (!found)
            return false;
    }

    if (propertiesParsed == shorthand.length())
        return true;

    // Fill in any remaining properties with the initial value.
    ImplicitScope implicitScope(this);
    const StylePropertyShorthand* const* const propertiesForInitialization = shorthand.propertiesForInitialization();
    for (unsigned i = 0; i < shorthand.length(); ++i) {
        if (propertyFound[i])
            continue;

        if (propertiesForInitialization) {
            const StylePropertyShorthand& initProperties = *(propertiesForInitialization[i]);
            for (unsigned propIndex = 0; propIndex < initProperties.length(); ++propIndex)
                addProperty(initProperties.properties()[propIndex], cssValuePool().createImplicitInitialValue());
        } else
            addProperty(shorthand.properties()[i], cssValuePool().createImplicitInitialValue());
    }

    return true;
}

bool CSSPropertyParser::parse4Values(CSSPropertyID propId, const CSSPropertyID *properties)
{
    /* From the CSS 2 specs, 8.3
     * If there is only one value, it applies to all sides. If there are two values, the top and
     * bottom margins are set to the first value and the right and left margins are set to the second.
     * If there are three values, the top is set to the first value, the left and right are set to the
     * second, and the bottom is set to the third. If there are four values, they apply to the top,
     * right, bottom, and left, respectively.
     */

    int num = inShorthand() ? 1 : m_valueList->size();

    ShorthandScope scope(this, propId);

    // the order is top, right, bottom, left
    switch (num) {
        case 1: {
            if (!parseValue(properties[0]))
                return false;
            CSSValue* value = m_parsedProperties.last().value();
            ImplicitScope implicitScope(this);
            addProperty(properties[1], value);
            addProperty(properties[2], value);
            addProperty(properties[3], value);
            break;
        }
        case 2: {
            if (!parseValue(properties[0]) || !parseValue(properties[1]))
                return false;
            CSSValue* value = m_parsedProperties[m_parsedProperties.size() - 2].value();
            ImplicitScope implicitScope(this);
            addProperty(properties[2], value);
            value = m_parsedProperties[m_parsedProperties.size() - 2].value();
            addProperty(properties[3], value);
            break;
        }
        case 3: {
            if (!parseValue(properties[0]) || !parseValue(properties[1]) || !parseValue(properties[2]))
                return false;
            CSSValue* value = m_parsedProperties[m_parsedProperties.size() - 2].value();
            ImplicitScope implicitScope(this);
            addProperty(properties[3], value);
            break;
        }
        case 4: {
            if (!parseValue(properties[0]) || !parseValue(properties[1]) ||
                !parseValue(properties[2]) || !parseValue(properties[3]))
                return false;
            break;
        }
        default: {
            return false;
        }
    }

    return true;
}

// auto | <identifier>
bool CSSPropertyParser::parsePage(CSSPropertyID propId)
{
    ASSERT(propId == CSSPropertyPage);

    if (m_valueList->size() != 1)
        return false;

    CSSParserValue* value = m_valueList->current();
    if (!value)
        return false;

    if (value->id == CSSValueAuto) {
        addProperty(propId, cssValuePool().createIdentifierValue(value->id));
        return true;
    } else if (value->id == 0 && value->unit == CSSPrimitiveValue::CSS_IDENT) {
        addProperty(propId, createPrimitiveStringValue(value));
        return true;
    }
    return false;
}

// <length>{1,2} | auto | [ <page-size> || [ portrait | landscape] ]
bool CSSPropertyParser::parseSize(CSSPropertyID propId)
{
    ASSERT(propId == CSSPropertySize);

    if (m_valueList->size() > 2)
        return false;

    CSSParserValue* value = m_valueList->current();
    if (!value)
        return false;

    RefPtr<CSSValueList> parsedValues = CSSValueList::createSpaceSeparated();

    // First parameter.
    SizeParameterType paramType = parseSizeParameter(parsedValues.get(), value, None);
    if (paramType == None)
        return false;

    // Second parameter, if any.
    value = m_valueList->next();
    if (value) {
        paramType = parseSizeParameter(parsedValues.get(), value, paramType);
        if (paramType == None)
            return false;
    }

    addProperty(propId, parsedValues.release());
    return true;
}

CSSPropertyParser::SizeParameterType CSSPropertyParser::parseSizeParameter(CSSValueList* parsedValues, CSSParserValue* value, SizeParameterType prevParamType)
{
    switch (value->id) {
    case CSSValueAuto:
        if (prevParamType == None) {
            parsedValues->append(cssValuePool().createIdentifierValue(value->id));
            return Auto;
        }
        return None;
    case CSSValueLandscape:
    case CSSValuePortrait:
        if (prevParamType == None || prevParamType == PageSize) {
            parsedValues->append(cssValuePool().createIdentifierValue(value->id));
            return Orientation;
        }
        return None;
    case CSSValueA3:
    case CSSValueA4:
    case CSSValueA5:
    case CSSValueB4:
    case CSSValueB5:
    case CSSValueLedger:
    case CSSValueLegal:
    case CSSValueLetter:
        if (prevParamType == None || prevParamType == Orientation) {
            // Normalize to Page Size then Orientation order by prepending.
            // This is not specified by the CSS3 Paged Media specification, but for simpler processing later (StyleResolver::applyPageSizeProperty).
            parsedValues->prepend(cssValuePool().createIdentifierValue(value->id));
            return PageSize;
        }
        return None;
    case 0:
        if (validUnit(value, FLength | FNonNeg) && (prevParamType == None || prevParamType == Length)) {
            parsedValues->append(createPrimitiveNumericValue(value));
            return Length;
        }
        return None;
    default:
        return None;
    }
}

// [ <string> <string> ]+ | none, but none is handled in parseValue
PassRefPtr<CSSValue> CSSPropertyParser::parseQuotes()
{
    RefPtr<CSSValueList> values = CSSValueList::createCommaSeparated();
    while (CSSParserValue* val = m_valueList->current()) {
        RefPtr<CSSValue> parsedValue = nullptr;
        if (val->unit != CSSPrimitiveValue::CSS_STRING)
            return nullptr;
        parsedValue = CSSPrimitiveValue::create(val->string, CSSPrimitiveValue::CSS_STRING);
        values->append(parsedValue.release());
        m_valueList->next();
    }
    if (values->length() && values->length() % 2 == 0)
        return values.release();
    return nullptr;
}

PassRefPtr<CSSValue> CSSPropertyParser::parseAttr(CSSParserValueList* args)
{
    if (args->size() != 1)
        return nullptr;

    CSSParserValue* a = args->current();

    if (a->unit != CSSPrimitiveValue::CSS_IDENT)
        return nullptr;

    String attrName = a->string;
    // CSS allows identifiers with "-" at the start, like "-webkit-foo".
    // But HTML attribute names can't have those characters, and we should not
    // even parse them inside attr().
    if (attrName[0] == '-')
        return nullptr;

    return cssValuePool().createValue(attrName, CSSPrimitiveValue::CSS_ATTR);
}

PassRefPtr<CSSValue> CSSPropertyParser::parseBackgroundColor()
{
    CSSValueID id = m_valueList->current()->id;
    if (id == CSSValueCurrentcolor)
        return cssValuePool().createIdentifierValue(id);
    return parseColor();
}

bool CSSPropertyParser::parseFillImage(CSSParserValueList* valueList, RefPtr<CSSValue>& value)
{
    if (valueList->current()->id == CSSValueNone) {
        value = cssValuePool().createIdentifierValue(CSSValueNone);
        return true;
    }
    if (valueList->current()->unit == CSSPrimitiveValue::CSS_URI) {
        value = createCSSImageValueWithReferrer(valueList->current()->string, completeURL(valueList->current()->string));
        return true;
    }

    if (isGeneratedImageValue(valueList->current()))
        return parseGeneratedImage(valueList, value);

    if (valueList->current()->unit == CSSParserValue::Function && equalIgnoringCase(valueList->current()->function->name, "-webkit-image-set(")) {
        value = parseImageSet(m_valueList);
        if (value)
            return true;
    }

    return false;
}

PassRefPtr<CSSValue> CSSPropertyParser::parseFillPositionX(CSSParserValueList* valueList)
{
    int id = valueList->current()->id;
    if (id == CSSValueLeft || id == CSSValueRight || id == CSSValueCenter) {
        int percent = 0;
        if (id == CSSValueRight)
            percent = 100;
        else if (id == CSSValueCenter)
            percent = 50;
        return cssValuePool().createValue(percent, CSSPrimitiveValue::CSS_PERCENTAGE);
    }
    if (validUnit(valueList->current(), FPercent | FLength))
        return createPrimitiveNumericValue(valueList->current());
    return nullptr;
}

PassRefPtr<CSSValue> CSSPropertyParser::parseFillPositionY(CSSParserValueList* valueList)
{
    int id = valueList->current()->id;
    if (id == CSSValueTop || id == CSSValueBottom || id == CSSValueCenter) {
        int percent = 0;
        if (id == CSSValueBottom)
            percent = 100;
        else if (id == CSSValueCenter)
            percent = 50;
        return cssValuePool().createValue(percent, CSSPrimitiveValue::CSS_PERCENTAGE);
    }
    if (validUnit(valueList->current(), FPercent | FLength))
        return createPrimitiveNumericValue(valueList->current());
    return nullptr;
}

PassRefPtr<CSSPrimitiveValue> CSSPropertyParser::parseFillPositionComponent(CSSParserValueList* valueList, unsigned& cumulativeFlags, FillPositionFlag& individualFlag, FillPositionParsingMode parsingMode)
{
    CSSValueID id = valueList->current()->id;
    if (id == CSSValueLeft || id == CSSValueTop || id == CSSValueRight || id == CSSValueBottom || id == CSSValueCenter) {
        int percent = 0;
        if (id == CSSValueLeft || id == CSSValueRight) {
            if (cumulativeFlags & XFillPosition)
                return nullptr;
            cumulativeFlags |= XFillPosition;
            individualFlag = XFillPosition;
            if (id == CSSValueRight)
                percent = 100;
        }
        else if (id == CSSValueTop || id == CSSValueBottom) {
            if (cumulativeFlags & YFillPosition)
                return nullptr;
            cumulativeFlags |= YFillPosition;
            individualFlag = YFillPosition;
            if (id == CSSValueBottom)
                percent = 100;
        } else if (id == CSSValueCenter) {
            // Center is ambiguous, so we're not sure which position we've found yet, an x or a y.
            percent = 50;
            cumulativeFlags |= AmbiguousFillPosition;
            individualFlag = AmbiguousFillPosition;
        }

        if (parsingMode == ResolveValuesAsKeyword)
            return cssValuePool().createIdentifierValue(id);

        return cssValuePool().createValue(percent, CSSPrimitiveValue::CSS_PERCENTAGE);
    }
    if (validUnit(valueList->current(), FPercent | FLength)) {
        if (!cumulativeFlags) {
            cumulativeFlags |= XFillPosition;
            individualFlag = XFillPosition;
        } else if (cumulativeFlags & (XFillPosition | AmbiguousFillPosition)) {
            cumulativeFlags |= YFillPosition;
            individualFlag = YFillPosition;
        } else {
            if (m_parsedCalculation)
                m_parsedCalculation.release();
            return nullptr;
        }
        return createPrimitiveNumericValue(valueList->current());
    }
    return nullptr;
}

static bool isValueConflictingWithCurrentEdge(int value1, int value2)
{
    if ((value1 == CSSValueLeft || value1 == CSSValueRight) && (value2 == CSSValueLeft || value2 == CSSValueRight))
        return true;

    if ((value1 == CSSValueTop || value1 == CSSValueBottom) && (value2 == CSSValueTop || value2 == CSSValueBottom))
        return true;

    return false;
}

static bool isFillPositionKeyword(CSSValueID value)
{
    return value == CSSValueLeft || value == CSSValueTop || value == CSSValueBottom || value == CSSValueRight || value == CSSValueCenter;
}

void CSSPropertyParser::parse4ValuesFillPosition(CSSParserValueList* valueList, RefPtr<CSSValue>& value1, RefPtr<CSSValue>& value2, PassRefPtr<CSSPrimitiveValue> parsedValue1, PassRefPtr<CSSPrimitiveValue> parsedValue2)
{
    // [ left | right ] [ <percentage] | <length> ] && [ top | bottom ] [ <percentage> | <length> ]
    // In the case of 4 values <position> requires the second value to be a length or a percentage.
    if (isFillPositionKeyword(parsedValue2->getValueID()))
        return;

    unsigned cumulativeFlags = 0;
    FillPositionFlag value3Flag = InvalidFillPosition;
    RefPtr<CSSPrimitiveValue> value3 = parseFillPositionComponent(valueList, cumulativeFlags, value3Flag, ResolveValuesAsKeyword);
    if (!value3)
        return;

    CSSValueID ident1 = parsedValue1->getValueID();
    CSSValueID ident3 = value3->getValueID();

    if (ident1 == CSSValueCenter)
        return;

    if (!isFillPositionKeyword(ident3) || ident3 == CSSValueCenter)
        return;

    // We need to check if the values are not conflicting, e.g. they are not on the same edge. It is
    // needed as the second call to parseFillPositionComponent was on purpose not checking it. In the
    // case of two values top 20px is invalid but in the case of 4 values it becomes valid.
    if (isValueConflictingWithCurrentEdge(ident1, ident3))
        return;

    valueList->next();

    cumulativeFlags = 0;
    FillPositionFlag value4Flag = InvalidFillPosition;
    RefPtr<CSSPrimitiveValue> value4 = parseFillPositionComponent(valueList, cumulativeFlags, value4Flag, ResolveValuesAsKeyword);
    if (!value4)
        return;

    // 4th value must be a length or a percentage.
    if (isFillPositionKeyword(value4->getValueID()))
        return;

    value1 = createPrimitiveValuePair(parsedValue1, parsedValue2);
    value2 = createPrimitiveValuePair(value3, value4);

    if (ident1 == CSSValueTop || ident1 == CSSValueBottom)
        value1.swap(value2);

    valueList->next();
}
void CSSPropertyParser::parse3ValuesFillPosition(CSSParserValueList* valueList, RefPtr<CSSValue>& value1, RefPtr<CSSValue>& value2, PassRefPtr<CSSPrimitiveValue> parsedValue1, PassRefPtr<CSSPrimitiveValue> parsedValue2)
{
    unsigned cumulativeFlags = 0;
    FillPositionFlag value3Flag = InvalidFillPosition;
    RefPtr<CSSPrimitiveValue> value3 = parseFillPositionComponent(valueList, cumulativeFlags, value3Flag, ResolveValuesAsKeyword);

    // value3 is not an expected value, we return.
    if (!value3)
        return;

    valueList->next();

    bool swapNeeded = false;
    CSSValueID ident1 = parsedValue1->getValueID();
    CSSValueID ident2 = parsedValue2->getValueID();
    CSSValueID ident3 = value3->getValueID();

    CSSValueID firstPositionKeyword;
    CSSValueID secondPositionKeyword;

    if (ident1 == CSSValueCenter) {
        // <position> requires the first 'center' to be followed by a keyword.
        if (!isFillPositionKeyword(ident2))
            return;

        // If 'center' is the first keyword then the last one needs to be a length.
        if (isFillPositionKeyword(ident3))
            return;

        firstPositionKeyword = CSSValueLeft;
        if (ident2 == CSSValueLeft || ident2 == CSSValueRight) {
            firstPositionKeyword = CSSValueTop;
            swapNeeded = true;
        }
        value1 = createPrimitiveValuePair(cssValuePool().createIdentifierValue(firstPositionKeyword), cssValuePool().createValue(50, CSSPrimitiveValue::CSS_PERCENTAGE));
        value2 = createPrimitiveValuePair(parsedValue2, value3);
    } else if (ident3 == CSSValueCenter) {
        if (isFillPositionKeyword(ident2))
            return;

        secondPositionKeyword = CSSValueTop;
        if (ident1 == CSSValueTop || ident1 == CSSValueBottom) {
            secondPositionKeyword = CSSValueLeft;
            swapNeeded = true;
        }
        value1 = createPrimitiveValuePair(parsedValue1, parsedValue2);
        value2 = createPrimitiveValuePair(cssValuePool().createIdentifierValue(secondPositionKeyword), cssValuePool().createValue(50, CSSPrimitiveValue::CSS_PERCENTAGE));
    } else {
        RefPtr<CSSPrimitiveValue> firstPositionValue = nullptr;
        RefPtr<CSSPrimitiveValue> secondPositionValue = nullptr;

        if (isFillPositionKeyword(ident2)) {
            // To match CSS grammar, we should only accept: [ center | left | right | bottom | top ] [ left | right | top | bottom ] [ <percentage> | <length> ].
            ASSERT(ident2 != CSSValueCenter);

            if (isFillPositionKeyword(ident3))
                return;

            secondPositionValue = value3;
            secondPositionKeyword = ident2;
            firstPositionValue = cssValuePool().createValue(0, CSSPrimitiveValue::CSS_PERCENTAGE);
        } else {
            // Per CSS, we should only accept: [ right | left | top | bottom ] [ <percentage> | <length> ] [ center | left | right | bottom | top ].
            if (!isFillPositionKeyword(ident3))
                return;

            firstPositionValue = parsedValue2;
            secondPositionKeyword = ident3;
            secondPositionValue = cssValuePool().createValue(0, CSSPrimitiveValue::CSS_PERCENTAGE);
        }

        if (isValueConflictingWithCurrentEdge(ident1, secondPositionKeyword))
            return;

        value1 = createPrimitiveValuePair(parsedValue1, firstPositionValue);
        value2 = createPrimitiveValuePair(cssValuePool().createIdentifierValue(secondPositionKeyword), secondPositionValue);
    }

    if (ident1 == CSSValueTop || ident1 == CSSValueBottom || swapNeeded)
        value1.swap(value2);

#if ENABLE(ASSERT)
    CSSPrimitiveValue* first = toCSSPrimitiveValue(value1.get());
    CSSPrimitiveValue* second = toCSSPrimitiveValue(value2.get());
    ident1 = first->getPairValue()->first()->getValueID();
    ident2 = second->getPairValue()->first()->getValueID();
    ASSERT(ident1 == CSSValueLeft || ident1 == CSSValueRight);
    ASSERT(ident2 == CSSValueBottom || ident2 == CSSValueTop);
#endif
}

inline bool CSSPropertyParser::isPotentialPositionValue(CSSParserValue* value)
{
    return isFillPositionKeyword(value->id) || validUnit(value, FPercent | FLength, ReleaseParsedCalcValue);
}

void CSSPropertyParser::parseFillPosition(CSSParserValueList* valueList, RefPtr<CSSValue>& value1, RefPtr<CSSValue>& value2)
{
    unsigned numberOfValues = 0;
    for (unsigned i = valueList->currentIndex(); i < valueList->size(); ++i, ++numberOfValues) {
        CSSParserValue* current = valueList->valueAt(i);
        if (isComma(current) || !current || isForwardSlashOperator(current) || !isPotentialPositionValue(current))
            break;
    }

    if (numberOfValues > 4)
        return;

    // If we are parsing two values, we can safely call the CSS 2.1 parsing function and return.
    if (numberOfValues <= 2) {
        parse2ValuesFillPosition(valueList, value1, value2);
        return;
    }

    ASSERT(numberOfValues > 2 && numberOfValues <= 4);

    CSSParserValue* value = valueList->current();

    // <position> requires the first value to be a background keyword.
    if (!isFillPositionKeyword(value->id))
        return;

    // Parse the first value. We're just making sure that it is one of the valid keywords or a percentage/length.
    unsigned cumulativeFlags = 0;
    FillPositionFlag value1Flag = InvalidFillPosition;
    FillPositionFlag value2Flag = InvalidFillPosition;
    value1 = parseFillPositionComponent(valueList, cumulativeFlags, value1Flag, ResolveValuesAsKeyword);
    if (!value1)
        return;

    valueList->next();

    // In case we are parsing more than two values, relax the check inside of parseFillPositionComponent. top 20px is
    // a valid start for <position>.
    cumulativeFlags = AmbiguousFillPosition;
    value2 = parseFillPositionComponent(valueList, cumulativeFlags, value2Flag, ResolveValuesAsKeyword);
    if (value2)
        valueList->next();
    else {
        value1.clear();
        return;
    }

    RefPtr<CSSPrimitiveValue> parsedValue1 = toCSSPrimitiveValue(value1.get());
    RefPtr<CSSPrimitiveValue> parsedValue2 = toCSSPrimitiveValue(value2.get());

    value1.clear();
    value2.clear();

    // Per CSS3 syntax, <position> can't have 'center' as its second keyword as we have more arguments to follow.
    if (parsedValue2->getValueID() == CSSValueCenter)
        return;

    if (numberOfValues == 3)
        parse3ValuesFillPosition(valueList, value1, value2, parsedValue1.release(), parsedValue2.release());
    else
        parse4ValuesFillPosition(valueList, value1, value2, parsedValue1.release(), parsedValue2.release());
}

void CSSPropertyParser::parse2ValuesFillPosition(CSSParserValueList* valueList, RefPtr<CSSValue>& value1, RefPtr<CSSValue>& value2)
{
    // Parse the first value.  We're just making sure that it is one of the valid keywords or a percentage/length.
    unsigned cumulativeFlags = 0;
    FillPositionFlag value1Flag = InvalidFillPosition;
    FillPositionFlag value2Flag = InvalidFillPosition;
    value1 = parseFillPositionComponent(valueList, cumulativeFlags, value1Flag);
    if (!value1)
        return;

    // It only takes one value for background-position to be correctly parsed if it was specified in a shorthand (since we
    // can assume that any other values belong to the rest of the shorthand).  If we're not parsing a shorthand, though, the
    // value was explicitly specified for our property.
    CSSParserValue* value = valueList->next();

    // First check for the comma.  If so, we are finished parsing this value or value pair.
    if (isComma(value))
        value = 0;

    if (value) {
        value2 = parseFillPositionComponent(valueList, cumulativeFlags, value2Flag);
        if (value2)
            valueList->next();
        else {
            if (!inShorthand()) {
                value1.clear();
                return;
            }
        }
    }

    if (!value2)
        // Only one value was specified. If that value was not a keyword, then it sets the x position, and the y position
        // is simply 50%. This is our default.
        // For keywords, the keyword was either an x-keyword (left/right), a y-keyword (top/bottom), or an ambiguous keyword (center).
        // For left/right/center, the default of 50% in the y is still correct.
        value2 = cssValuePool().createValue(50, CSSPrimitiveValue::CSS_PERCENTAGE);

    if (value1Flag == YFillPosition || value2Flag == XFillPosition)
        value1.swap(value2);
}

void CSSPropertyParser::parseFillRepeat(RefPtr<CSSValue>& value1, RefPtr<CSSValue>& value2)
{
    CSSValueID id = m_valueList->current()->id;
    if (id == CSSValueRepeatX) {
        m_implicitShorthand = true;
        value1 = cssValuePool().createIdentifierValue(CSSValueRepeat);
        value2 = cssValuePool().createIdentifierValue(CSSValueNoRepeat);
        m_valueList->next();
        return;
    }
    if (id == CSSValueRepeatY) {
        m_implicitShorthand = true;
        value1 = cssValuePool().createIdentifierValue(CSSValueNoRepeat);
        value2 = cssValuePool().createIdentifierValue(CSSValueRepeat);
        m_valueList->next();
        return;
    }
    if (id == CSSValueRepeat || id == CSSValueNoRepeat || id == CSSValueRound || id == CSSValueSpace)
        value1 = cssValuePool().createIdentifierValue(id);
    else {
        value1 = nullptr;
        return;
    }

    CSSParserValue* value = m_valueList->next();

    // Parse the second value if one is available
    if (value && !isComma(value)) {
        id = value->id;
        if (id == CSSValueRepeat || id == CSSValueNoRepeat || id == CSSValueRound || id == CSSValueSpace) {
            value2 = cssValuePool().createIdentifierValue(id);
            m_valueList->next();
            return;
        }
    }

    // If only one value was specified, value2 is the same as value1.
    m_implicitShorthand = true;
    value2 = cssValuePool().createIdentifierValue(toCSSPrimitiveValue(value1.get())->getValueID());
}

PassRefPtr<CSSValue> CSSPropertyParser::parseFillSize(CSSPropertyID propId, bool& allowComma)
{
    allowComma = true;
    CSSParserValue* value = m_valueList->current();

    if (value->id == CSSValueContain || value->id == CSSValueCover)
        return cssValuePool().createIdentifierValue(value->id);

    RefPtr<CSSPrimitiveValue> parsedValue1 = nullptr;

    if (value->id == CSSValueAuto)
        parsedValue1 = cssValuePool().createIdentifierValue(CSSValueAuto);
    else {
        if (!validUnit(value, FLength | FPercent))
            return nullptr;
        parsedValue1 = createPrimitiveNumericValue(value);
    }

    RefPtr<CSSPrimitiveValue> parsedValue2 = nullptr;
    value = m_valueList->next();
    if (value) {
        if (value->unit == CSSParserValue::Operator && value->iValue == ',')
            allowComma = false;
        else if (value->id != CSSValueAuto) {
            if (!validUnit(value, FLength | FPercent)) {
                if (!inShorthand())
                    return nullptr;
                // We need to rewind the value list, so that when it is advanced we'll end up back at this value.
                m_valueList->previous();
            } else
                parsedValue2 = createPrimitiveNumericValue(value);
        }
    } else if (!parsedValue2 && propId == CSSPropertyWebkitBackgroundSize) {
        // FIXME(sky): Remove webkit-background-size.
        // For backwards compatibility we set the second value to the first if it is omitted.
        // We only need to do this for -webkit-background-size.
        parsedValue2 = parsedValue1;
    }

    if (!parsedValue2)
        return parsedValue1;

    Pair::IdenticalValuesPolicy policy = propId == CSSPropertyWebkitBackgroundSize ?
        Pair::DropIdenticalValues : Pair::KeepIdenticalValues;

    return createPrimitiveValuePair(parsedValue1.release(), parsedValue2.release(), policy);
}

bool CSSPropertyParser::parseFillProperty(CSSPropertyID propId, CSSPropertyID& propId1, CSSPropertyID& propId2,
    RefPtr<CSSValue>& retValue1, RefPtr<CSSValue>& retValue2)
{
    RefPtr<CSSValueList> values = nullptr;
    RefPtr<CSSValueList> values2 = nullptr;
    RefPtr<CSSValue> value = nullptr;
    RefPtr<CSSValue> value2 = nullptr;

    bool allowComma = false;

    retValue1 = retValue2 = nullptr;
    propId1 = propId;
    propId2 = propId;
    if (propId == CSSPropertyBackgroundPosition) {
        propId1 = CSSPropertyBackgroundPositionX;
        propId2 = CSSPropertyBackgroundPositionY;
    } else if (propId == CSSPropertyBackgroundRepeat) {
        propId1 = CSSPropertyBackgroundRepeatX;
        propId2 = CSSPropertyBackgroundRepeatY;
    }

    for (CSSParserValue* val = m_valueList->current(); val; val = m_valueList->current()) {
        RefPtr<CSSValue> currValue = nullptr;
        RefPtr<CSSValue> currValue2 = nullptr;

        if (allowComma) {
            if (!isComma(val))
                return false;
            m_valueList->next();
            allowComma = false;
        } else {
            allowComma = true;
            switch (propId) {
                case CSSPropertyBackgroundColor:
                    currValue = parseBackgroundColor();
                    if (currValue)
                        m_valueList->next();
                    break;
                case CSSPropertyBackgroundAttachment:
                    if (val->id == CSSValueFixed || val->id == CSSValueLocal) {
                        currValue = cssValuePool().createIdentifierValue(val->id);
                        m_valueList->next();
                    }
                    break;
                case CSSPropertyBackgroundImage:
                    if (parseFillImage(m_valueList, currValue))
                        m_valueList->next();
                    break;
                case CSSPropertyWebkitBackgroundClip:
                case CSSPropertyWebkitBackgroundOrigin:
                    // The first three values here are deprecated and do not apply to the version of the property that has
                    // the -webkit- prefix removed.
                    if (val->id == CSSValueBorder || val->id == CSSValuePadding || val->id == CSSValueContent ||
                        val->id == CSSValueBorderBox || val->id == CSSValuePaddingBox || val->id == CSSValueContentBox ||
                        (propId == CSSPropertyWebkitBackgroundClip &&
                         (val->id == CSSValueText))) {
                        currValue = cssValuePool().createIdentifierValue(val->id);
                        m_valueList->next();
                    }
                    break;
                case CSSPropertyBackgroundClip:
                    if (parseBackgroundClip(val, currValue))
                        m_valueList->next();
                    break;
                case CSSPropertyBackgroundOrigin:
                    if (val->id == CSSValueBorderBox || val->id == CSSValuePaddingBox || val->id == CSSValueContentBox) {
                        currValue = cssValuePool().createIdentifierValue(val->id);
                        m_valueList->next();
                    }
                    break;
                case CSSPropertyBackgroundPosition:
                    parseFillPosition(m_valueList, currValue, currValue2);
                    // parseFillPosition advances the m_valueList pointer.
                    break;
                case CSSPropertyBackgroundPositionX: {
                    currValue = parseFillPositionX(m_valueList);
                    if (currValue)
                        m_valueList->next();
                    break;
                }
                case CSSPropertyBackgroundPositionY: {
                    currValue = parseFillPositionY(m_valueList);
                    if (currValue)
                        m_valueList->next();
                    break;
                }
                case CSSPropertyWebkitBackgroundComposite:
                    if (val->id >= CSSValueClear && val->id <= CSSValuePlusLighter) {
                        currValue = cssValuePool().createIdentifierValue(val->id);
                        m_valueList->next();
                    }
                    break;
                case CSSPropertyBackgroundRepeat:
                    parseFillRepeat(currValue, currValue2);
                    // parseFillRepeat advances the m_valueList pointer
                    break;
                case CSSPropertyBackgroundSize:
                case CSSPropertyWebkitBackgroundSize: {
                    currValue = parseFillSize(propId, allowComma);
                    if (currValue)
                        m_valueList->next();
                    break;
                }
                default:
                    break;
            }
            if (!currValue)
                return false;

            if (value && !values) {
                values = CSSValueList::createCommaSeparated();
                values->append(value.release());
            }

            if (value2 && !values2) {
                values2 = CSSValueList::createCommaSeparated();
                values2->append(value2.release());
            }

            if (values)
                values->append(currValue.release());
            else
                value = currValue.release();
            if (currValue2) {
                if (values2)
                    values2->append(currValue2.release());
                else
                    value2 = currValue2.release();
            }
        }

        // When parsing any fill shorthand property, we let it handle building up the lists for all
        // properties.
        if (inShorthand())
            break;
    }

    if (values && values->length()) {
        retValue1 = values.release();
        if (values2 && values2->length())
            retValue2 = values2.release();
        return true;
    }
    if (value) {
        retValue1 = value.release();
        retValue2 = value2.release();
        return true;
    }
    return false;
}

PassRefPtr<CSSValue> CSSPropertyParser::parseAnimationDelay()
{
    CSSParserValue* value = m_valueList->current();
    if (validUnit(value, FTime))
        return createPrimitiveNumericValue(value);
    return nullptr;
}

PassRefPtr<CSSValue> CSSPropertyParser::parseAnimationDirection()
{
    CSSParserValue* value = m_valueList->current();
    if (value->id == CSSValueNormal || value->id == CSSValueAlternate || value->id == CSSValueReverse || value->id == CSSValueAlternateReverse)
        return cssValuePool().createIdentifierValue(value->id);
    return nullptr;
}

PassRefPtr<CSSValue> CSSPropertyParser::parseAnimationDuration()
{
    CSSParserValue* value = m_valueList->current();
    if (validUnit(value, FTime | FNonNeg))
        return createPrimitiveNumericValue(value);
    return nullptr;
}

PassRefPtr<CSSValue> CSSPropertyParser::parseAnimationFillMode()
{
    CSSParserValue* value = m_valueList->current();
    if (value->id == CSSValueNone || value->id == CSSValueForwards || value->id == CSSValueBackwards || value->id == CSSValueBoth)
        return cssValuePool().createIdentifierValue(value->id);
    return nullptr;
}

PassRefPtr<CSSValue> CSSPropertyParser::parseAnimationIterationCount()
{
    CSSParserValue* value = m_valueList->current();
    if (value->id == CSSValueInfinite)
        return cssValuePool().createIdentifierValue(value->id);
    if (validUnit(value, FNumber | FNonNeg))
        return createPrimitiveNumericValue(value);
    return nullptr;
}

PassRefPtr<CSSValue> CSSPropertyParser::parseAnimationName()
{
    CSSParserValue* value = m_valueList->current();
    if (value->unit == CSSPrimitiveValue::CSS_STRING || value->unit == CSSPrimitiveValue::CSS_IDENT) {
        if (value->id == CSSValueNone || (value->unit == CSSPrimitiveValue::CSS_STRING && equalIgnoringCase(value, "none"))) {
            return cssValuePool().createIdentifierValue(CSSValueNone);
        } else {
            return createPrimitiveStringValue(value);
        }
    }
    return nullptr;
}

PassRefPtr<CSSValue> CSSPropertyParser::parseAnimationPlayState()
{
    CSSParserValue* value = m_valueList->current();
    if (value->id == CSSValueRunning || value->id == CSSValuePaused)
        return cssValuePool().createIdentifierValue(value->id);
    return nullptr;
}

PassRefPtr<CSSValue> CSSPropertyParser::parseAnimationProperty()
{
    CSSParserValue* value = m_valueList->current();
    if (value->unit != CSSPrimitiveValue::CSS_IDENT)
        return nullptr;
    // Since all is valid css property keyword, cssPropertyID for all
    // returns non-null value. We need to check "all" before
    // cssPropertyID check.
    if (value->id == CSSValueAll)
        return cssValuePool().createIdentifierValue(CSSValueAll);
    CSSPropertyID property = cssPropertyID(value->string);
    if (property) {
        ASSERT(CSSPropertyMetadata::isEnabledProperty(property));
        return cssValuePool().createIdentifierValue(property);
    }
    if (value->id == CSSValueNone)
        return cssValuePool().createIdentifierValue(CSSValueNone);
    if (value->id == CSSValueInitial || value->id == CSSValueInherit)
        return nullptr;
    return createPrimitiveStringValue(value);
}

bool CSSPropertyParser::parseWebkitTransformOriginShorthand()
{
    RefPtr<CSSValue> originX = nullptr;
    RefPtr<CSSValue> originY = nullptr;
    RefPtr<CSSValue> originZ = nullptr;

    parse2ValuesFillPosition(m_valueList, originX, originY);

    if (m_valueList->current()) {
        if (!validUnit(m_valueList->current(), FLength))
            return false;
        originZ = createPrimitiveNumericValue(m_valueList->current());
        m_valueList->next();
    } else {
        originZ = cssValuePool().createImplicitInitialValue();
    }

    addProperty(CSSPropertyWebkitTransformOriginX, originX.release());
    addProperty(CSSPropertyWebkitTransformOriginY, originY.release());
    addProperty(CSSPropertyWebkitTransformOriginZ, originZ.release());

    return true;
}

bool CSSPropertyParser::parseCubicBezierTimingFunctionValue(CSSParserValueList*& args, double& result)
{
    CSSParserValue* v = args->current();
    if (!validUnit(v, FNumber))
        return false;
    result = v->fValue;
    v = args->next();
    if (!v)
        // The last number in the function has no comma after it, so we're done.
        return true;
    return consumeComma(args);
}

PassRefPtr<CSSValue> CSSPropertyParser::parseAnimationTimingFunction()
{
    CSSParserValue* value = m_valueList->current();
    if (value->id == CSSValueEase || value->id == CSSValueLinear || value->id == CSSValueEaseIn || value->id == CSSValueEaseOut
        || value->id == CSSValueEaseInOut || value->id == CSSValueStepStart || value->id == CSSValueStepEnd
        || value->id == CSSValueStepMiddle)
        return cssValuePool().createIdentifierValue(value->id);

    // We must be a function.
    if (value->unit != CSSParserValue::Function)
        return nullptr;

    CSSParserValueList* args = value->function->args.get();

    if (equalIgnoringCase(value->function->name, "steps(")) {
        // For steps, 1 or 2 params must be specified (comma-separated)
        if (!args || (args->size() != 1 && args->size() != 3))
            return nullptr;

        // There are two values.
        int numSteps;
        StepsTimingFunction::StepAtPosition stepAtPosition = StepsTimingFunction::StepAtEnd;

        CSSParserValue* v = args->current();
        if (!validUnit(v, FInteger))
            return nullptr;
        numSteps = clampToInteger(v->fValue);
        if (numSteps < 1)
            return nullptr;

        if (args->next()) {
            // There is a comma so we need to parse the second value
            if (!consumeComma(args))
                return nullptr;
            switch (args->current()->id) {
            case CSSValueMiddle:
                stepAtPosition = StepsTimingFunction::StepAtMiddle;
                break;
            case CSSValueStart:
                stepAtPosition = StepsTimingFunction::StepAtStart;
                break;
            case CSSValueEnd:
                stepAtPosition = StepsTimingFunction::StepAtEnd;
                break;
            default:
                return nullptr;
            }
        }

        return CSSStepsTimingFunctionValue::create(numSteps, stepAtPosition);
    }

    if (equalIgnoringCase(value->function->name, "cubic-bezier(")) {
        // For cubic bezier, 4 values must be specified.
        if (!args || args->size() != 7)
            return nullptr;

        // There are two points specified. The x values must be between 0 and 1 but the y values can exceed this range.
        double x1, y1, x2, y2;

        if (!parseCubicBezierTimingFunctionValue(args, x1))
            return nullptr;
        if (x1 < 0 || x1 > 1)
            return nullptr;
        if (!parseCubicBezierTimingFunctionValue(args, y1))
            return nullptr;
        if (!parseCubicBezierTimingFunctionValue(args, x2))
            return nullptr;
        if (x2 < 0 || x2 > 1)
            return nullptr;
        if (!parseCubicBezierTimingFunctionValue(args, y2))
            return nullptr;

        return CSSCubicBezierTimingFunctionValue::create(x1, y1, x2, y2);
    }

    return nullptr;
}

PassRefPtr<CSSValue> CSSPropertyParser::parseAnimationProperty(CSSPropertyID propId)
{
    RefPtr<CSSValue> value = nullptr;
    switch (propId) {
    case CSSPropertyAnimationDelay:
    case CSSPropertyTransitionDelay:
        value = parseAnimationDelay();
        break;
    case CSSPropertyAnimationDirection:
        value = parseAnimationDirection();
        break;
    case CSSPropertyAnimationDuration:
    case CSSPropertyTransitionDuration:
        value = parseAnimationDuration();
        break;
    case CSSPropertyAnimationFillMode:
        value = parseAnimationFillMode();
        break;
    case CSSPropertyAnimationIterationCount:
        value = parseAnimationIterationCount();
        break;
    case CSSPropertyAnimationName:
        value = parseAnimationName();
        break;
    case CSSPropertyAnimationPlayState:
        value = parseAnimationPlayState();
        break;
    case CSSPropertyTransitionProperty:
        value = parseAnimationProperty();
        break;
    case CSSPropertyAnimationTimingFunction:
    case CSSPropertyTransitionTimingFunction:
        value = parseAnimationTimingFunction();
        break;
    default:
        ASSERT_NOT_REACHED();
        return nullptr;
    }

    if (value)
        m_valueList->next();
    return value.release();
}

PassRefPtr<CSSValueList> CSSPropertyParser::parseAnimationPropertyList(CSSPropertyID propId)
{
    RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
    while (m_valueList->current()) {
        RefPtr<CSSValue> value = parseAnimationProperty(propId);
        if (!value)
            return nullptr;
        list->append(value.release());
        if (CSSParserValue* parserValue = m_valueList->current()) {
            if (!isComma(parserValue))
                return nullptr;
            m_valueList->next();
            ASSERT(m_valueList->current());
        }
    }
    if (propId == CSSPropertyTransitionProperty && !isValidTransitionPropertyList(list.get()))
        return nullptr;
    ASSERT(list->length());
    return list.release();
}

static inline bool isCSSWideKeyword(CSSParserValue& value)
{
    return value.id == CSSValueInitial || value.id == CSSValueInherit || value.id == CSSValueDefault;
}

bool CSSPropertyParser::parseClipShape(CSSPropertyID propId)
{
    CSSParserValue* value = m_valueList->current();
    CSSParserValueList* args = value->function->args.get();

    if (!equalIgnoringCase(value->function->name, "rect(") || !args)
        return false;

    // rect(t, r, b, l) || rect(t r b l)
    if (args->size() != 4 && args->size() != 7)
        return false;
    RefPtr<Rect> rect = Rect::create();
    int i = 0;
    CSSParserValue* a = args->current();
    while (a) {
        if (a->id != CSSValueAuto && !validUnit(a, FLength))
            return false;
        RefPtr<CSSPrimitiveValue> length = a->id == CSSValueAuto ?
            cssValuePool().createIdentifierValue(CSSValueAuto) :
            createPrimitiveNumericValue(a);
        if (i == 0)
            rect->setTop(length);
        else if (i == 1)
            rect->setRight(length);
        else if (i == 2)
            rect->setBottom(length);
        else
            rect->setLeft(length);
        a = args->next();
        if (a && args->size() == 7) {
            if (!consumeComma(args))
                return false;
            a = args->current();
        }
        i++;
    }
    addProperty(propId, cssValuePool().createValue(rect.release()));
    m_valueList->next();
    return true;
}

static void completeBorderRadii(RefPtr<CSSPrimitiveValue> radii[4])
{
    if (radii[3])
        return;
    if (!radii[2]) {
        if (!radii[1])
            radii[1] = radii[0];
        radii[2] = radii[0];
    }
    radii[3] = radii[1];
}

// FIXME: This should be refactored with CSSParser::parseBorderRadius.
// CSSParser::parseBorderRadius contains support for some legacy radius construction.
PassRefPtr<CSSBasicShape> CSSPropertyParser::parseInsetRoundedCorners(PassRefPtr<CSSBasicShapeInset> shape, CSSParserValueList* args)
{
    CSSParserValue* argument = args->next();

    if (!argument)
        return nullptr;

    Vector<CSSParserValue*> radiusArguments;
    while (argument) {
        radiusArguments.append(argument);
        argument = args->next();
    }

    unsigned num = radiusArguments.size();
    if (!num || num > 9)
        return nullptr;

    // FIXME: Refactor completeBorderRadii and the array
    RefPtr<CSSPrimitiveValue> radii[2][4];
#if ENABLE(OILPAN)
    // Zero initialize the array of raw pointers.
    memset(&radii, 0, sizeof(radii));
#endif

    unsigned indexAfterSlash = 0;
    for (unsigned i = 0; i < num; ++i) {
        CSSParserValue* value = radiusArguments.at(i);
        if (value->unit == CSSParserValue::Operator) {
            if (value->iValue != '/')
                return nullptr;

            if (!i || indexAfterSlash || i + 1 == num)
                return nullptr;

            indexAfterSlash = i + 1;
            completeBorderRadii(radii[0]);
            continue;
        }

        if (i - indexAfterSlash >= 4)
            return nullptr;

        if (!validUnit(value, FLength | FPercent | FNonNeg))
            return nullptr;

        RefPtr<CSSPrimitiveValue> radius = createPrimitiveNumericValue(value);

        if (!indexAfterSlash)
            radii[0][i] = radius;
        else
            radii[1][i - indexAfterSlash] = radius.release();
    }

    if (!indexAfterSlash) {
        completeBorderRadii(radii[0]);
        for (unsigned i = 0; i < 4; ++i)
            radii[1][i] = radii[0][i];
    } else {
        completeBorderRadii(radii[1]);
    }
    shape->setTopLeftRadius(createPrimitiveValuePair(radii[0][0].release(), radii[1][0].release()));
    shape->setTopRightRadius(createPrimitiveValuePair(radii[0][1].release(), radii[1][1].release()));
    shape->setBottomRightRadius(createPrimitiveValuePair(radii[0][2].release(), radii[1][2].release()));
    shape->setBottomLeftRadius(createPrimitiveValuePair(radii[0][3].release(), radii[1][3].release()));

    return shape;
}

PassRefPtr<CSSBasicShape> CSSPropertyParser::parseBasicShapeInset(CSSParserValueList* args)
{
    ASSERT(args);

    RefPtr<CSSBasicShapeInset> shape = CSSBasicShapeInset::create();

    CSSParserValue* argument = args->current();
    Vector<RefPtr<CSSPrimitiveValue> > widthArguments;
    bool hasRoundedInset = false;

    while (argument) {
        if (argument->unit == CSSPrimitiveValue::CSS_IDENT && argument->id == CSSValueRound) {
            hasRoundedInset = true;
            break;
        }

        Units unitFlags = FLength | FPercent;
        if (!validUnit(argument, unitFlags) || widthArguments.size() > 4)
            return nullptr;

        widthArguments.append(createPrimitiveNumericValue(argument));
        argument = args->next();
    }

    switch (widthArguments.size()) {
    case 1: {
        shape->updateShapeSize1Value(widthArguments[0].get());
        break;
    }
    case 2: {
        shape->updateShapeSize2Values(widthArguments[0].get(), widthArguments[1].get());
        break;
        }
    case 3: {
        shape->updateShapeSize3Values(widthArguments[0].get(), widthArguments[1].get(), widthArguments[2].get());
        break;
    }
    case 4: {
        shape->updateShapeSize4Values(widthArguments[0].get(), widthArguments[1].get(), widthArguments[2].get(), widthArguments[3].get());
        break;
    }
    default:
        return nullptr;
    }

    if (hasRoundedInset)
        return parseInsetRoundedCorners(shape, args);
    return shape;
}

static bool isBaselinePositionKeyword(CSSValueID id)
{
    return id == CSSValueBaseline || id == CSSValueLastBaseline;
}

static bool isItemPositionKeyword(CSSValueID id)
{
    return id == CSSValueStart || id == CSSValueEnd || id == CSSValueCenter
        || id == CSSValueSelfStart || id == CSSValueSelfEnd || id == CSSValueFlexStart
        || id == CSSValueFlexEnd || id == CSSValueLeft || id == CSSValueRight;
}

bool CSSPropertyParser::parseItemPositionOverflowPosition(CSSPropertyID propId)
{
    // auto | stretch | <baseline-position> | [<item-position> && <overflow-position>? ]
    // <baseline-position> = baseline | last-baseline;
    // <item-position> = center | start | end | self-start | self-end | flex-start | flex-end | left | right;
    // <overflow-position> = true | safe

    CSSParserValue* value = m_valueList->current();
    if (!value)
        return false;

    if (value->id == CSSValueAuto || value->id == CSSValueStretch || isBaselinePositionKeyword(value->id)) {
        if (m_valueList->next())
            return false;

        addProperty(propId, cssValuePool().createIdentifierValue(value->id));
        return true;
    }

    RefPtr<CSSPrimitiveValue> position = nullptr;
    RefPtr<CSSPrimitiveValue> overflowAlignmentKeyword = nullptr;
    if (isItemPositionKeyword(value->id)) {
        position = cssValuePool().createIdentifierValue(value->id);
        value = m_valueList->next();
        if (value) {
            if (value->id == CSSValueTrue || value->id == CSSValueSafe)
                overflowAlignmentKeyword = cssValuePool().createIdentifierValue(value->id);
            else
                return false;
        }
    } else if (value->id == CSSValueTrue || value->id == CSSValueSafe) {
        overflowAlignmentKeyword = cssValuePool().createIdentifierValue(value->id);
        value = m_valueList->next();
        if (value && isItemPositionKeyword(value->id))
            position = cssValuePool().createIdentifierValue(value->id);
        else
            return false;
    } else {
        return false;
    }

    if (m_valueList->next())
        return false;

    ASSERT(position);
    if (overflowAlignmentKeyword)
        addProperty(propId, createPrimitiveValuePair(position, overflowAlignmentKeyword));
    else
        addProperty(propId, position.release());

    return true;
}

PassRefPtr<CSSPrimitiveValue> CSSPropertyParser::parseShapeRadius(CSSParserValue* value)
{
    if (value->id == CSSValueClosestSide || value->id == CSSValueFarthestSide)
        return cssValuePool().createIdentifierValue(value->id);

    if (!validUnit(value, FLength | FPercent | FNonNeg))
        return nullptr;

    return createPrimitiveNumericValue(value);
}

PassRefPtr<CSSBasicShape> CSSPropertyParser::parseBasicShapeCircle(CSSParserValueList* args)
{
    ASSERT(args);

    // circle(radius)
    // circle(radius at <position>)
    // circle(at <position>)
    // where position defines centerX and centerY using a CSS <position> data type.
    RefPtr<CSSBasicShapeCircle> shape = CSSBasicShapeCircle::create();

    for (CSSParserValue* argument = args->current(); argument; argument = args->next()) {
        // The call to parseFillPosition below should consume all of the
        // arguments except the first two. Thus, and index greater than one
        // indicates an invalid production.
        if (args->currentIndex() > 1)
            return nullptr;

        if (!args->currentIndex() && argument->id != CSSValueAt) {
            if (RefPtr<CSSPrimitiveValue> radius = parseShapeRadius(argument)) {
                shape->setRadius(radius);
                continue;
            }

            return nullptr;
        }

        if (argument->id == CSSValueAt && args->next()) {
            RefPtr<CSSValue> centerX = nullptr;
            RefPtr<CSSValue> centerY = nullptr;
            parseFillPosition(args, centerX, centerY);
            if (centerX && centerY && !args->current()) {
                ASSERT(centerX->isPrimitiveValue());
                ASSERT(centerY->isPrimitiveValue());
                shape->setCenterX(toCSSPrimitiveValue(centerX.get()));
                shape->setCenterY(toCSSPrimitiveValue(centerY.get()));
            } else {
                return nullptr;
            }
        } else {
            return nullptr;
        }
    }

    return shape;
}

PassRefPtr<CSSBasicShape> CSSPropertyParser::parseBasicShapeEllipse(CSSParserValueList* args)
{
    ASSERT(args);

    // ellipse(radiusX)
    // ellipse(radiusX at <position>)
    // ellipse(radiusX radiusY)
    // ellipse(radiusX radiusY at <position>)
    // ellipse(at <position>)
    // where position defines centerX and centerY using a CSS <position> data type.
    RefPtr<CSSBasicShapeEllipse> shape = CSSBasicShapeEllipse::create();

    for (CSSParserValue* argument = args->current(); argument; argument = args->next()) {
        // The call to parseFillPosition below should consume all of the
        // arguments except the first three. Thus, an index greater than two
        // indicates an invalid production.
        if (args->currentIndex() > 2)
            return nullptr;

        if (args->currentIndex() < 2 && argument->id != CSSValueAt) {
            if (RefPtr<CSSPrimitiveValue> radius = parseShapeRadius(argument)) {
                if (!shape->radiusX())
                    shape->setRadiusX(radius);
                else
                    shape->setRadiusY(radius);
                continue;
            }

            return nullptr;
        }

        if (argument->id != CSSValueAt || !args->next()) // expecting ellipse(.. at <position>)
            return nullptr;
        RefPtr<CSSValue> centerX = nullptr;
        RefPtr<CSSValue> centerY = nullptr;
        parseFillPosition(args, centerX, centerY);
        if (!centerX || !centerY || args->current())
            return nullptr;

        ASSERT(centerX->isPrimitiveValue());
        ASSERT(centerY->isPrimitiveValue());
        shape->setCenterX(toCSSPrimitiveValue(centerX.get()));
        shape->setCenterY(toCSSPrimitiveValue(centerY.get()));
    }

    return shape;
}

PassRefPtr<CSSBasicShape> CSSPropertyParser::parseBasicShapePolygon(CSSParserValueList* args)
{
    ASSERT(args);

    unsigned size = args->size();
    if (!size)
        return nullptr;

    RefPtr<CSSBasicShapePolygon> shape = CSSBasicShapePolygon::create();

    CSSParserValue* argument = args->current();
    if (argument->id == CSSValueEvenodd || argument->id == CSSValueNonzero) {
        shape->setWindRule(argument->id == CSSValueEvenodd ? RULE_EVENODD : RULE_NONZERO);
        args->next();

        if (!consumeComma(args))
            return nullptr;

        size -= 2;
    }

    // <length> <length>, ... <length> <length> -> each pair has 3 elements except the last one
    if (!size || (size % 3) - 2)
        return nullptr;

    while (true) {
        CSSParserValue* argumentX = args->current();
        if (!argumentX || !validUnit(argumentX, FLength | FPercent))
            return nullptr;
        RefPtr<CSSPrimitiveValue> xLength = createPrimitiveNumericValue(argumentX);

        CSSParserValue* argumentY = args->next();
        if (!argumentY || !validUnit(argumentY, FLength | FPercent))
            return nullptr;
        RefPtr<CSSPrimitiveValue> yLength = createPrimitiveNumericValue(argumentY);

        shape->appendPoint(xLength.release(), yLength.release());

        if (!args->next())
            break;
        if (!consumeComma(args))
            return nullptr;
    }

    return shape;
}

static bool isBoxValue(CSSValueID valueId)
{
    switch (valueId) {
    case CSSValueContentBox:
    case CSSValuePaddingBox:
    case CSSValueBorderBox:
    case CSSValueMarginBox:
        return true;
    default:
        break;
    }

    return false;
}

PassRefPtr<CSSValue> CSSPropertyParser::parseShapeProperty(CSSPropertyID propId)
{
    CSSParserValue* value = m_valueList->current();
    CSSValueID valueId = value->id;

    if (valueId == CSSValueNone) {
        RefPtr<CSSPrimitiveValue> keywordValue = parseValidPrimitive(valueId, value);
        m_valueList->next();
        return keywordValue.release();
    }

    RefPtr<CSSValue> imageValue = nullptr;
    if (valueId != CSSValueNone && parseFillImage(m_valueList, imageValue)) {
        m_valueList->next();
        return imageValue.release();
    }

    return parseBasicShapeAndOrBox();
}

PassRefPtr<CSSValue> CSSPropertyParser::parseBasicShapeAndOrBox()
{
    CSSParserValue* value = m_valueList->current();

    bool shapeFound = false;
    bool boxFound = false;
    CSSValueID valueId;

    RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
    for (unsigned i = 0; i < 2; ++i) {
        if (!value)
            break;
        valueId = value->id;
        if (value->unit == CSSParserValue::Function && !shapeFound) {
            // parseBasicShape already asks for the next value list item.
            RefPtr<CSSPrimitiveValue> shapeValue = parseBasicShape();
            if (!shapeValue)
                return nullptr;
            list->append(shapeValue.release());
            shapeFound = true;
        } else if (isBoxValue(valueId) && !boxFound) {
            list->append(parseValidPrimitive(valueId, value));
            boxFound = true;
            m_valueList->next();
        } else {
            return nullptr;
        }

        value = m_valueList->current();
    }

    if (m_valueList->current())
        return nullptr;
    return list.release();
}

PassRefPtr<CSSPrimitiveValue> CSSPropertyParser::parseBasicShape()
{
    CSSParserValue* value = m_valueList->current();
    ASSERT(value->unit == CSSParserValue::Function);
    CSSParserValueList* args = value->function->args.get();

    if (!args)
        return nullptr;

    RefPtr<CSSBasicShape> shape = nullptr;
    if (equalIgnoringCase(value->function->name, "circle("))
        shape = parseBasicShapeCircle(args);
    else if (equalIgnoringCase(value->function->name, "ellipse("))
        shape = parseBasicShapeEllipse(args);
    else if (equalIgnoringCase(value->function->name, "polygon("))
        shape = parseBasicShapePolygon(args);
    else if (equalIgnoringCase(value->function->name, "inset("))
        shape = parseBasicShapeInset(args);

    if (!shape)
        return nullptr;

    m_valueList->next();

    return cssValuePool().createValue(shape.release());
}

// [ 'font-style' || 'font-variant' || 'font-weight' ]? 'font-size' [ / 'line-height' ]? 'font-family'
bool CSSPropertyParser::parseFont()
{
    // Let's check if there is an inherit or initial somewhere in the shorthand.
    for (unsigned i = 0; i < m_valueList->size(); ++i) {
        if (m_valueList->valueAt(i)->id == CSSValueInherit || m_valueList->valueAt(i)->id == CSSValueInitial)
            return false;
    }

    ShorthandScope scope(this, CSSPropertyFont);
    // Optional font-style, font-variant and font-weight.
    bool fontStyleParsed = false;
    bool fontVariantParsed = false;
    bool fontWeightParsed = false;
    bool fontStretchParsed = false;
    CSSParserValue* value = m_valueList->current();
    for (; value; value = m_valueList->next()) {
        if (!fontStyleParsed && isValidKeywordPropertyAndValue(CSSPropertyFontStyle, value->id, m_context)) {
            addProperty(CSSPropertyFontStyle, cssValuePool().createIdentifierValue(value->id));
            fontStyleParsed = true;
        } else if (!fontVariantParsed && (value->id == CSSValueNormal || value->id == CSSValueSmallCaps)) {
            // Font variant in the shorthand is particular, it only accepts normal or small-caps.
            addProperty(CSSPropertyFontVariant, cssValuePool().createIdentifierValue(value->id));
            fontVariantParsed = true;
        } else if (!fontWeightParsed && parseFontWeight()) {
            fontWeightParsed = true;
        } else if (!fontStretchParsed && isValidKeywordPropertyAndValue(CSSPropertyFontStretch, value->id, m_context)) {
            addProperty(CSSPropertyFontStretch, cssValuePool().createIdentifierValue(value->id));
            fontStretchParsed = true;
        } else {
            break;
        }
    }

    if (!value)
        return false;

    if (!fontStyleParsed)
        addProperty(CSSPropertyFontStyle, cssValuePool().createIdentifierValue(CSSValueNormal), true);
    if (!fontVariantParsed)
        addProperty(CSSPropertyFontVariant, cssValuePool().createIdentifierValue(CSSValueNormal), true);
    if (!fontWeightParsed)
        addProperty(CSSPropertyFontWeight, cssValuePool().createIdentifierValue(CSSValueNormal), true);
    if (!fontStretchParsed)
        addProperty(CSSPropertyFontStretch, cssValuePool().createIdentifierValue(CSSValueNormal), true);

    // Now a font size _must_ come.
    // <absolute-size> | <relative-size> | <length> | <percentage> | inherit
    if (!parseFontSize())
        return false;

    value = m_valueList->current();
    if (!value)
        return false;

    if (isForwardSlashOperator(value)) {
        // The line-height property.
        value = m_valueList->next();
        if (!value)
            return false;
        if (!parseLineHeight())
            return false;
    } else
        addProperty(CSSPropertyLineHeight, cssValuePool().createIdentifierValue(CSSValueNormal), true);

    // Font family must come now.
    RefPtr<CSSValue> parsedFamilyValue = parseFontFamily();
    if (!parsedFamilyValue)
        return false;

    addProperty(CSSPropertyFontFamily, parsedFamilyValue.release());

    // FIXME: http://www.w3.org/TR/2011/WD-css3-fonts-20110324/#font-prop requires that
    // "font-stretch", "font-size-adjust", and "font-kerning" be reset to their initial values
    // but we don't seem to support them at the moment. They should also be added here once implemented.
    if (m_valueList->current())
        return false;

    return true;
}

class FontFamilyValueBuilder {
    DISALLOW_ALLOCATION();
public:
    FontFamilyValueBuilder(CSSValueList* list)
        : m_list(list)
    {
    }

    void add(const CSSParserString& string)
    {
        if (!m_builder.isEmpty())
            m_builder.append(' ');

        if (string.is8Bit()) {
            m_builder.append(string.characters8(), string.length());
            return;
        }

        m_builder.append(string.characters16(), string.length());
    }

    void commit()
    {
        if (m_builder.isEmpty())
            return;
        m_list->append(cssValuePool().createFontFamilyValue(m_builder.toString()));
        m_builder.clear();
    }

private:
    StringBuilder m_builder;
    CSSValueList* m_list;
};

PassRefPtr<CSSValueList> CSSPropertyParser::parseFontFamily()
{
    RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
    CSSParserValue* value = m_valueList->current();

    FontFamilyValueBuilder familyBuilder(list.get());
    bool inFamily = false;

    while (value) {
        CSSParserValue* nextValue = m_valueList->next();
        bool nextValBreaksFont = !nextValue ||
                                 (nextValue->unit == CSSParserValue::Operator && nextValue->iValue == ',');
        bool nextValIsFontName = nextValue &&
            ((nextValue->id >= CSSValueSerif && nextValue->id <= CSSValueWebkitBody) ||
            (nextValue->unit == CSSPrimitiveValue::CSS_STRING || nextValue->unit == CSSPrimitiveValue::CSS_IDENT));

        if (isCSSWideKeyword(*value) && !inFamily) {
            if (nextValBreaksFont)
                value = m_valueList->next();
            else if (nextValIsFontName)
                value = nextValue;
            continue;
        }

        if (value->id >= CSSValueSerif && value->id <= CSSValueWebkitBody) {
            if (inFamily)
                familyBuilder.add(value->string);
            else if (nextValBreaksFont || !nextValIsFontName)
                list->append(cssValuePool().createIdentifierValue(value->id));
            else {
                familyBuilder.commit();
                familyBuilder.add(value->string);
                inFamily = true;
            }
        } else if (value->unit == CSSPrimitiveValue::CSS_STRING) {
            // Strings never share in a family name.
            inFamily = false;
            familyBuilder.commit();
            list->append(cssValuePool().createFontFamilyValue(value->string));
        } else if (value->unit == CSSPrimitiveValue::CSS_IDENT) {
            if (inFamily)
                familyBuilder.add(value->string);
            else if (nextValBreaksFont || !nextValIsFontName)
                list->append(cssValuePool().createFontFamilyValue(value->string));
            else {
                familyBuilder.commit();
                familyBuilder.add(value->string);
                inFamily = true;
            }
        } else {
            break;
        }

        if (!nextValue)
            break;

        if (nextValBreaksFont) {
            value = m_valueList->next();
            familyBuilder.commit();
            inFamily = false;
        }
        else if (nextValIsFontName)
            value = nextValue;
        else
            break;
    }
    familyBuilder.commit();

    if (!list->length())
        list = nullptr;
    return list.release();
}

bool CSSPropertyParser::parseLineHeight()
{
    CSSParserValue* value = m_valueList->current();
    CSSValueID id = value->id;
    bool validPrimitive = false;
    // normal | <number> | <length> | <percentage> | inherit
    if (id == CSSValueNormal)
        validPrimitive = true;
    else
        validPrimitive = (!id && validUnit(value, FNumber | FLength | FPercent | FNonNeg));
    if (validPrimitive && (!m_valueList->next() || inShorthand()))
        addProperty(CSSPropertyLineHeight, parseValidPrimitive(id, value));
    return validPrimitive;
}

bool CSSPropertyParser::parseFontSize()
{
    CSSParserValue* value = m_valueList->current();
    CSSValueID id = value->id;
    bool validPrimitive = false;
    // <absolute-size> | <relative-size> | <length> | <percentage> | inherit
    if (id >= CSSValueXxSmall && id <= CSSValueLarger)
        validPrimitive = true;
    else
        validPrimitive = validUnit(value, FLength | FPercent | FNonNeg);
    if (validPrimitive && (!m_valueList->next() || inShorthand()))
        addProperty(CSSPropertyFontSize, parseValidPrimitive(id, value));
    return validPrimitive;
}

bool CSSPropertyParser::parseFontVariant()
{
    RefPtr<CSSValueList> values = nullptr;
    if (m_valueList->size() > 1)
        values = CSSValueList::createCommaSeparated();
    bool expectComma = false;
    for (CSSParserValue* val = m_valueList->current(); val; val = m_valueList->current()) {
        RefPtr<CSSPrimitiveValue> parsedValue = nullptr;
        if (!expectComma) {
            expectComma = true;
            if (val->id == CSSValueNormal || val->id == CSSValueSmallCaps)
                parsedValue = cssValuePool().createIdentifierValue(val->id);
            else if (val->id == CSSValueAll && !values) {
                // FIXME: CSSPropertyParser::parseFontVariant() implements
                // the old css3 draft:
                // http://www.w3.org/TR/2002/WD-css3-webfonts-20020802/#font-variant
                // 'all' is only allowed in @font-face and with no other values. Make a value list to
                // indicate that we are in the @font-face case.
                values = CSSValueList::createCommaSeparated();
                parsedValue = cssValuePool().createIdentifierValue(val->id);
            }
        } else if (consumeComma(m_valueList)) {
            expectComma = false;
            continue;
        }

        if (!parsedValue)
            return false;

        m_valueList->next();

        if (values)
            values->append(parsedValue.release());
        else {
            addProperty(CSSPropertyFontVariant, parsedValue.release());
            return true;
        }
    }

    if (values && values->length()) {
        if (m_ruleType != CSSRuleSourceData::FONT_FACE_RULE)
            return false;
        addProperty(CSSPropertyFontVariant, values.release());
        return true;
    }

    return false;
}

bool CSSPropertyParser::parseFontWeight()
{
    CSSParserValue* value = m_valueList->current();
    if (value->id >= CSSValueNormal && value->id <= CSSValueLighter) {
        addProperty(CSSPropertyFontWeight, cssValuePool().createIdentifierValue(value->id));
        return true;
    }
    if (value->unit == CSSPrimitiveValue::CSS_NUMBER) {
        int weight = static_cast<int>(value->fValue);
        if (!(weight % 100) && weight >= 100 && weight <= 900) {
            addProperty(CSSPropertyFontWeight, cssValuePool().createIdentifierValue(static_cast<CSSValueID>(CSSValue100 + weight / 100 - 1)));
            return true;
        }
    }
    return false;
}

bool CSSPropertyParser::parseFontFaceSrcURI(CSSValueList* valueList)
{
    RefPtr<CSSFontFaceSrcValue> uriValue(CSSFontFaceSrcValue::create(completeURL(m_valueList->current()->string)));
    uriValue->setReferrer(m_context.referrer());

    CSSParserValue* value = m_valueList->next();
    if (!value) {
        valueList->append(uriValue.release());
        return true;
    }
    if (value->unit == CSSParserValue::Operator && value->iValue == ',') {
        m_valueList->next();
        valueList->append(uriValue.release());
        return true;
    }

    if (value->unit != CSSParserValue::Function || !equalIgnoringCase(value->function->name, "format("))
        return false;

    // FIXME: http://www.w3.org/TR/2011/WD-css3-fonts-20111004/ says that format() contains a comma-separated list of strings,
    // but CSSFontFaceSrcValue stores only one format. Allowing one format for now.
    CSSParserValueList* args = value->function->args.get();
    if (!args || args->size() != 1 || (args->current()->unit != CSSPrimitiveValue::CSS_STRING && args->current()->unit != CSSPrimitiveValue::CSS_IDENT))
        return false;
    uriValue->setFormat(args->current()->string);
    valueList->append(uriValue.release());
    value = m_valueList->next();
    if (value && value->unit == CSSParserValue::Operator && value->iValue == ',')
        m_valueList->next();
    return true;
}

bool CSSPropertyParser::parseFontFaceSrcLocal(CSSValueList* valueList)
{
    CSSParserValueList* args = m_valueList->current()->function->args.get();
    if (!args || !args->size())
        return false;

    if (args->size() == 1 && args->current()->unit == CSSPrimitiveValue::CSS_STRING)
        valueList->append(CSSFontFaceSrcValue::createLocal(args->current()->string));
    else if (args->current()->unit == CSSPrimitiveValue::CSS_IDENT) {
        StringBuilder builder;
        for (CSSParserValue* localValue = args->current(); localValue; localValue = args->next()) {
            if (localValue->unit != CSSPrimitiveValue::CSS_IDENT)
                return false;
            if (!builder.isEmpty())
                builder.append(' ');
            builder.append(localValue->string);
        }
        valueList->append(CSSFontFaceSrcValue::createLocal(builder.toString()));
    } else
        return false;

    if (CSSParserValue* value = m_valueList->next()) {
        if (value->unit == CSSParserValue::Operator && value->iValue == ',')
            m_valueList->next();
    }
    return true;
}

PassRefPtr<CSSValueList> CSSPropertyParser::parseFontFaceSrc()
{
    RefPtr<CSSValueList> values(CSSValueList::createCommaSeparated());

    while (CSSParserValue* value = m_valueList->current()) {
        if (value->unit == CSSPrimitiveValue::CSS_URI) {
            if (!parseFontFaceSrcURI(values.get()))
                return nullptr;
        } else if (value->unit == CSSParserValue::Function && equalIgnoringCase(value->function->name, "local(")) {
            if (!parseFontFaceSrcLocal(values.get()))
                return nullptr;
        } else {
            return nullptr;
        }
    }
    if (!values->length())
        return nullptr;

    m_valueList->next();
    return values.release();
}

PassRefPtr<CSSValueList> CSSPropertyParser::parseFontFaceUnicodeRange()
{
    RefPtr<CSSValueList> values = CSSValueList::createCommaSeparated();

    do {
        CSSParserValue* current = m_valueList->current();
        if (!current || current->unit != CSSPrimitiveValue::CSS_UNICODE_RANGE)
            return nullptr;

        String rangeString = current->string;
        UChar32 from = 0;
        UChar32 to = 0;
        unsigned length = rangeString.length();

        if (length < 3)
            return nullptr;

        unsigned i = 2;
        while (i < length) {
            UChar c = rangeString[i];
            if (c == '-' || c == '?')
                break;
            from *= 16;
            if (c >= '0' && c <= '9')
                from += c - '0';
            else if (c >= 'A' && c <= 'F')
                from += 10 + c - 'A';
            else if (c >= 'a' && c <= 'f')
                from += 10 + c - 'a';
            else
                return nullptr;
            i++;
        }

        if (i == length)
            to = from;
        else if (rangeString[i] == '?') {
            unsigned span = 1;
            while (i < length && rangeString[i] == '?') {
                span *= 16;
                from *= 16;
                i++;
            }
            if (i < length)
                return nullptr;
            to = from + span - 1;
        } else {
            if (length < i + 2)
                return nullptr;
            i++;
            while (i < length) {
                UChar c = rangeString[i];
                to *= 16;
                if (c >= '0' && c <= '9')
                    to += c - '0';
                else if (c >= 'A' && c <= 'F')
                    to += 10 + c - 'A';
                else if (c >= 'a' && c <= 'f')
                    to += 10 + c - 'a';
                else
                    return nullptr;
                i++;
            }
        }
        if (from <= to)
            values->append(CSSUnicodeRangeValue::create(from, to));
        m_valueList->next();
    } while (consumeComma(m_valueList));

    return values.release();
}

// Returns the number of characters which form a valid double
// and are terminated by the given terminator character
template <typename CharacterType>
static int checkForValidDouble(const CharacterType* string, const CharacterType* end, const char terminator)
{
    int length = end - string;
    if (length < 1)
        return 0;

    bool decimalMarkSeen = false;
    int processedLength = 0;

    for (int i = 0; i < length; ++i) {
        if (string[i] == terminator) {
            processedLength = i;
            break;
        }
        if (!isASCIIDigit(string[i])) {
            if (!decimalMarkSeen && string[i] == '.')
                decimalMarkSeen = true;
            else
                return 0;
        }
    }

    if (decimalMarkSeen && processedLength == 1)
        return 0;

    return processedLength;
}

// Returns the number of characters consumed for parsing a valid double
// terminated by the given terminator character
template <typename CharacterType>
static int parseDouble(const CharacterType* string, const CharacterType* end, const char terminator, double& value)
{
    int length = checkForValidDouble(string, end, terminator);
    if (!length)
        return 0;

    int position = 0;
    double localValue = 0;

    // The consumed characters here are guaranteed to be
    // ASCII digits with or without a decimal mark
    for (; position < length; ++position) {
        if (string[position] == '.')
            break;
        localValue = localValue * 10 + string[position] - '0';
    }

    if (++position == length) {
        value = localValue;
        return length;
    }

    double fraction = 0;
    double scale = 1;

    while (position < length && scale < MAX_SCALE) {
        fraction = fraction * 10 + string[position++] - '0';
        scale *= 10;
    }

    value = localValue + fraction / scale;
    return length;
}

template <typename CharacterType>
static bool parseColorIntOrPercentage(const CharacterType*& string, const CharacterType* end, const char terminator, CSSPrimitiveValue::UnitType& expect, int& value)
{
    const CharacterType* current = string;
    double localValue = 0;
    bool negative = false;
    while (current != end && isHTMLSpace<CharacterType>(*current))
        current++;
    if (current != end && *current == '-') {
        negative = true;
        current++;
    }
    if (current == end || !isASCIIDigit(*current))
        return false;
    while (current != end && isASCIIDigit(*current)) {
        double newValue = localValue * 10 + *current++ - '0';
        if (newValue >= 255) {
            // Clamp values at 255.
            localValue = 255;
            while (current != end && isASCIIDigit(*current))
                ++current;
            break;
        }
        localValue = newValue;
    }

    if (current == end)
        return false;

    if (expect == CSSPrimitiveValue::CSS_NUMBER && (*current == '.' || *current == '%'))
        return false;

    if (*current == '.') {
        // We already parsed the integral part, try to parse
        // the fraction part of the percentage value.
        double percentage = 0;
        int numCharactersParsed = parseDouble(current, end, '%', percentage);
        if (!numCharactersParsed)
            return false;
        current += numCharactersParsed;
        if (*current != '%')
            return false;
        localValue += percentage;
    }

    if (expect == CSSPrimitiveValue::CSS_PERCENTAGE && *current != '%')
        return false;

    if (*current == '%') {
        expect = CSSPrimitiveValue::CSS_PERCENTAGE;
        localValue = localValue / 100.0 * 256.0;
        // Clamp values at 255 for percentages over 100%
        if (localValue > 255)
            localValue = 255;
        current++;
    } else
        expect = CSSPrimitiveValue::CSS_NUMBER;

    while (current != end && isHTMLSpace<CharacterType>(*current))
        current++;
    if (current == end || *current++ != terminator)
        return false;
    // Clamp negative values at zero.
    value = negative ? 0 : static_cast<int>(localValue);
    string = current;
    return true;
}

template <typename CharacterType>
static inline bool isTenthAlpha(const CharacterType* string, const int length)
{
    // "0.X"
    if (length == 3 && string[0] == '0' && string[1] == '.' && isASCIIDigit(string[2]))
        return true;

    // ".X"
    if (length == 2 && string[0] == '.' && isASCIIDigit(string[1]))
        return true;

    return false;
}

template <typename CharacterType>
static inline bool parseAlphaValue(const CharacterType*& string, const CharacterType* end, const char terminator, int& value)
{
    while (string != end && isHTMLSpace<CharacterType>(*string))
        string++;

    bool negative = false;

    if (string != end && *string == '-') {
        negative = true;
        string++;
    }

    value = 0;

    int length = end - string;
    if (length < 2)
        return false;

    if (string[length - 1] != terminator || !isASCIIDigit(string[length - 2]))
        return false;

    if (string[0] != '0' && string[0] != '1' && string[0] != '.') {
        if (checkForValidDouble(string, end, terminator)) {
            value = negative ? 0 : 255;
            string = end;
            return true;
        }
        return false;
    }

    if (length == 2 && string[0] != '.') {
        value = !negative && string[0] == '1' ? 255 : 0;
        string = end;
        return true;
    }

    if (isTenthAlpha(string, length - 1)) {
        static const int tenthAlphaValues[] = { 0, 25, 51, 76, 102, 127, 153, 179, 204, 230 };
        value = negative ? 0 : tenthAlphaValues[string[length - 2] - '0'];
        string = end;
        return true;
    }

    double alpha = 0;
    if (!parseDouble(string, end, terminator, alpha))
        return false;
    value = negative ? 0 : static_cast<int>(alpha * nextafter(256.0, 0.0));
    string = end;
    return true;
}

template <typename CharacterType>
static inline bool mightBeRGBA(const CharacterType* characters, unsigned length)
{
    if (length < 5)
        return false;
    return characters[4] == '('
        && isASCIIAlphaCaselessEqual(characters[0], 'r')
        && isASCIIAlphaCaselessEqual(characters[1], 'g')
        && isASCIIAlphaCaselessEqual(characters[2], 'b')
        && isASCIIAlphaCaselessEqual(characters[3], 'a');
}

template <typename CharacterType>
static inline bool mightBeRGB(const CharacterType* characters, unsigned length)
{
    if (length < 4)
        return false;
    return characters[3] == '('
        && isASCIIAlphaCaselessEqual(characters[0], 'r')
        && isASCIIAlphaCaselessEqual(characters[1], 'g')
        && isASCIIAlphaCaselessEqual(characters[2], 'b');
}

template <typename CharacterType>
static inline bool fastParseColorInternal(RGBA32& rgb, const CharacterType* characters, unsigned length , bool strict)
{
    CSSPrimitiveValue::UnitType expect = CSSPrimitiveValue::CSS_UNKNOWN;

    if (length >= 4 && characters[0] == '#')
        return Color::parseHexColor(characters + 1, length - 1, rgb);

    if (!strict && length >= 3) {
        if (Color::parseHexColor(characters, length, rgb))
            return true;
    }

    // Try rgba() syntax.
    if (mightBeRGBA(characters, length)) {
        const CharacterType* current = characters + 5;
        const CharacterType* end = characters + length;
        int red;
        int green;
        int blue;
        int alpha;

        if (!parseColorIntOrPercentage(current, end, ',', expect, red))
            return false;
        if (!parseColorIntOrPercentage(current, end, ',', expect, green))
            return false;
        if (!parseColorIntOrPercentage(current, end, ',', expect, blue))
            return false;
        if (!parseAlphaValue(current, end, ')', alpha))
            return false;
        if (current != end)
            return false;
        rgb = makeRGBA(red, green, blue, alpha);
        return true;
    }

    // Try rgb() syntax.
    if (mightBeRGB(characters, length)) {
        const CharacterType* current = characters + 4;
        const CharacterType* end = characters + length;
        int red;
        int green;
        int blue;
        if (!parseColorIntOrPercentage(current, end, ',', expect, red))
            return false;
        if (!parseColorIntOrPercentage(current, end, ',', expect, green))
            return false;
        if (!parseColorIntOrPercentage(current, end, ')', expect, blue))
            return false;
        if (current != end)
            return false;
        rgb = makeRGB(red, green, blue);
        return true;
    }

    return false;
}

template<typename StringType>
bool CSSPropertyParser::fastParseColor(RGBA32& rgb, const StringType& name, bool strict)
{
    unsigned length = name.length();
    bool parseResult;

    if (!length)
        return false;

    if (name.is8Bit())
        parseResult = fastParseColorInternal(rgb, name.characters8(), length, strict);
    else
        parseResult = fastParseColorInternal(rgb, name.characters16(), length, strict);

    if (parseResult)
        return true;

    // Try named colors.
    Color tc;
    if (!tc.setNamedColor(name))
        return false;
    rgb = tc.rgb();
    return true;
}

template bool CSSPropertyParser::fastParseColor(RGBA32&, const String&, bool strict);

bool CSSPropertyParser::isCalculation(CSSParserValue* value)
{
    return (value->unit == CSSParserValue::Function)
        && (equalIgnoringCase(value->function->name, "calc(")
            || equalIgnoringCase(value->function->name, "-webkit-calc("));
}

inline int CSSPropertyParser::colorIntFromValue(CSSParserValue* v)
{
    bool isPercent;
    double value;

    if (m_parsedCalculation) {
        isPercent = m_parsedCalculation->category() == CalcPercent;
        value = m_parsedCalculation->doubleValue();
        m_parsedCalculation.release();
    } else {
        isPercent = v->unit == CSSPrimitiveValue::CSS_PERCENTAGE;
        value = v->fValue;
    }

    if (value <= 0.0)
        return 0;

    if (isPercent) {
        if (value >= 100.0)
            return 255;
        return static_cast<int>(value * 256.0 / 100.0);
    }

    if (value >= 255.0)
        return 255;

    return static_cast<int>(value);
}

bool CSSPropertyParser::parseColorParameters(CSSParserValue* value, int* colorArray, bool parseAlpha)
{
    CSSParserValueList* args = value->function->args.get();
    CSSParserValue* v = args->current();
    Units unitType = FUnknown;
    // Get the first value and its type
    if (validUnit(v, FInteger))
        unitType = FInteger;
    else if (validUnit(v, FPercent))
        unitType = FPercent;
    else
        return false;

    colorArray[0] = colorIntFromValue(v);
    for (int i = 1; i < 3; i++) {
        args->next();
        if (!consumeComma(args))
            return false;
        v = args->current();
        if (!validUnit(v, unitType))
            return false;
        colorArray[i] = colorIntFromValue(v);
    }
    if (parseAlpha) {
        args->next();
        if (!consumeComma(args))
            return false;
        v = args->current();
        if (!validUnit(v, FNumber))
            return false;
        // Convert the floating pointer number of alpha to an integer in the range [0, 256),
        // with an equal distribution across all 256 values.
        colorArray[3] = static_cast<int>(std::max(0.0, std::min(1.0, v->fValue)) * nextafter(256.0, 0.0));
    }
    return true;
}

// The CSS3 specification defines the format of a HSL color as
// hsl(<number>, <percent>, <percent>)
// and with alpha, the format is
// hsla(<number>, <percent>, <percent>, <number>)
// The first value, HUE, is in an angle with a value between 0 and 360
bool CSSPropertyParser::parseHSLParameters(CSSParserValue* value, double* colorArray, bool parseAlpha)
{
    CSSParserValueList* args = value->function->args.get();
    CSSParserValue* v = args->current();
    // Get the first value
    if (!validUnit(v, FNumber))
        return false;
    // normalize the Hue value and change it to be between 0 and 1.0
    colorArray[0] = (((static_cast<int>(v->fValue) % 360) + 360) % 360) / 360.0;
    for (int i = 1; i < 3; i++) {
        args->next();
        if (!consumeComma(args))
            return false;
        v = args->current();
        if (!validUnit(v, FPercent))
            return false;
        double percentValue = m_parsedCalculation ? m_parsedCalculation.release()->doubleValue() : v->fValue;
        colorArray[i] = std::max(0.0, std::min(100.0, percentValue)) / 100.0; // needs to be value between 0 and 1.0
    }
    if (parseAlpha) {
        args->next();
        if (!consumeComma(args))
            return false;
        v = args->current();
        if (!validUnit(v, FNumber))
            return false;
        colorArray[3] = std::max(0.0, std::min(1.0, v->fValue));
    }
    return true;
}

PassRefPtr<CSSPrimitiveValue> CSSPropertyParser::parseColor(CSSParserValue* value, bool acceptQuirkyColors)
{
    RGBA32 c = Color::transparent;
    if (!parseColorFromValue(value ? value : m_valueList->current(), c, acceptQuirkyColors))
        return nullptr;
    return cssValuePool().createColorValue(c);
}

bool CSSPropertyParser::parseColorFromValue(CSSParserValue* value, RGBA32& c, bool acceptQuirkyColors)
{
    if (acceptQuirkyColors && value->unit == CSSPrimitiveValue::CSS_NUMBER
        && value->fValue >= 0. && value->fValue < 1000000.) {
        String str = String::format("%06d", static_cast<int>((value->fValue+.5)));
        // FIXME: This should be strict parsing for SVG as well.
        if (!fastParseColor(c, str, !acceptQuirkyColors))
            return false;
    } else if (value->unit == CSSPrimitiveValue::CSS_PARSER_HEXCOLOR
        || value->unit == CSSPrimitiveValue::CSS_IDENT
        || (acceptQuirkyColors && value->unit == CSSPrimitiveValue::CSS_DIMENSION)) {
        if (!fastParseColor(c, value->string, !acceptQuirkyColors && value->unit == CSSPrimitiveValue::CSS_IDENT))
            return false;
    } else if (value->unit == CSSParserValue::Function &&
                value->function->args != 0 &&
                value->function->args->size() == 5 /* rgb + two commas */ &&
                equalIgnoringCase(value->function->name, "rgb(")) {
        int colorValues[3];
        if (!parseColorParameters(value, colorValues, false))
            return false;
        c = makeRGB(colorValues[0], colorValues[1], colorValues[2]);
    } else {
        if (value->unit == CSSParserValue::Function &&
                value->function->args != 0 &&
                value->function->args->size() == 7 /* rgba + three commas */ &&
                equalIgnoringCase(value->function->name, "rgba(")) {
            int colorValues[4];
            if (!parseColorParameters(value, colorValues, true))
                return false;
            c = makeRGBA(colorValues[0], colorValues[1], colorValues[2], colorValues[3]);
        } else if (value->unit == CSSParserValue::Function &&
                    value->function->args != 0 &&
                    value->function->args->size() == 5 /* hsl + two commas */ &&
                    equalIgnoringCase(value->function->name, "hsl(")) {
            double colorValues[3];
            if (!parseHSLParameters(value, colorValues, false))
                return false;
            c = makeRGBAFromHSLA(colorValues[0], colorValues[1], colorValues[2], 1.0);
        } else if (value->unit == CSSParserValue::Function &&
                    value->function->args != 0 &&
                    value->function->args->size() == 7 /* hsla + three commas */ &&
                    equalIgnoringCase(value->function->name, "hsla(")) {
            double colorValues[4];
            if (!parseHSLParameters(value, colorValues, true))
                return false;
            c = makeRGBAFromHSLA(colorValues[0], colorValues[1], colorValues[2], colorValues[3]);
        } else
            return false;
    }

    return true;
}

// This class tracks parsing state for shadow values.  If it goes out of scope (e.g., due to an early return)
// without the allowBreak bit being set, then it will clean up all of the objects and destroy them.
class ShadowParseContext {
    STACK_ALLOCATED();
public:
    ShadowParseContext(CSSPropertyID prop, CSSPropertyParser* parser)
        : property(prop)
        , m_parser(parser)
        , allowX(true)
        , allowY(false)
        , allowBlur(false)
        , allowSpread(false)
        , allowColor(true)
        , allowStyle(prop == CSSPropertyWebkitBoxShadow || prop == CSSPropertyBoxShadow)
        , allowBreak(true)
    {
    }

    bool allowLength() { return allowX || allowY || allowBlur || allowSpread; }

    void commitValue()
    {
        // Handle the ,, case gracefully by doing nothing.
        if (x || y || blur || spread || color || style) {
            if (!values)
                values = CSSValueList::createCommaSeparated();

            // Construct the current shadow value and add it to the list.
            values->append(CSSShadowValue::create(x.release(), y.release(), blur.release(), spread.release(), style.release(), color.release()));
        }

        // Now reset for the next shadow value.
        x = nullptr;
        y = nullptr;
        blur = nullptr;
        spread = nullptr;
        style = nullptr;
        color = nullptr;

        allowX = true;
        allowColor = true;
        allowBreak = true;
        allowY = false;
        allowBlur = false;
        allowSpread = false;
        allowStyle = property == CSSPropertyWebkitBoxShadow || property == CSSPropertyBoxShadow;
    }

    void commitLength(CSSParserValue* v)
    {
        RefPtr<CSSPrimitiveValue> val = m_parser->createPrimitiveNumericValue(v);

        if (allowX) {
            x = val.release();
            allowX = false;
            allowY = true;
            allowColor = false;
            allowStyle = false;
            allowBreak = false;
        } else if (allowY) {
            y = val.release();
            allowY = false;
            allowBlur = true;
            allowColor = true;
            allowStyle = property == CSSPropertyWebkitBoxShadow || property == CSSPropertyBoxShadow;
            allowBreak = true;
        } else if (allowBlur) {
            blur = val.release();
            allowBlur = false;
            allowSpread = property == CSSPropertyWebkitBoxShadow || property == CSSPropertyBoxShadow;
        } else if (allowSpread) {
            spread = val.release();
            allowSpread = false;
        }
    }

    void commitColor(PassRefPtr<CSSPrimitiveValue> val)
    {
        color = val;
        allowColor = false;
        if (allowX) {
            allowStyle = false;
            allowBreak = false;
        } else {
            allowBlur = false;
            allowSpread = false;
            allowStyle = property == CSSPropertyWebkitBoxShadow || property == CSSPropertyBoxShadow;
        }
    }

    void commitStyle(CSSParserValue* v)
    {
        style = cssValuePool().createIdentifierValue(v->id);
        allowStyle = false;
        if (allowX)
            allowBreak = false;
        else {
            allowBlur = false;
            allowSpread = false;
            allowColor = false;
        }
    }

    CSSPropertyID property;
    CSSPropertyParser* m_parser;

    RefPtr<CSSValueList> values;
    RefPtr<CSSPrimitiveValue> x;
    RefPtr<CSSPrimitiveValue> y;
    RefPtr<CSSPrimitiveValue> blur;
    RefPtr<CSSPrimitiveValue> spread;
    RefPtr<CSSPrimitiveValue> style;
    RefPtr<CSSPrimitiveValue> color;

    bool allowX;
    bool allowY;
    bool allowBlur;
    bool allowSpread;
    bool allowColor;
    bool allowStyle; // inset or not.
    bool allowBreak;
};

PassRefPtr<CSSValueList> CSSPropertyParser::parseShadow(CSSParserValueList* valueList, CSSPropertyID propId)
{
    ShadowParseContext context(propId, this);
    for (CSSParserValue* val = valueList->current(); val; val = valueList->next()) {
        // Check for a comma break first.
        if (val->unit == CSSParserValue::Operator) {
            if (val->iValue != ',' || !context.allowBreak) {
                // Other operators aren't legal or we aren't done with the current shadow
                // value.  Treat as invalid.
                return nullptr;
            }
            // The value is good.  Commit it.
            context.commitValue();
        } else if (validUnit(val, FLength, HTMLStandardMode)) {
            // We required a length and didn't get one. Invalid.
            if (!context.allowLength())
                return nullptr;

            // Blur radius must be non-negative.
            if (context.allowBlur && !validUnit(val, FLength | FNonNeg, HTMLStandardMode))
                return nullptr;

            // A length is allowed here.  Construct the value and add it.
            context.commitLength(val);
        } else if (val->id == CSSValueInset) {
            if (!context.allowStyle)
                return nullptr;

            context.commitStyle(val);
        } else {
            // The only other type of value that's ok is a color value.
            RefPtr<CSSPrimitiveValue> parsedColor = nullptr;
            if (val->id == CSSValueCurrentcolor) {
                if (!context.allowColor)
                    return nullptr;
                parsedColor = cssValuePool().createIdentifierValue(val->id);
            }

            if (!parsedColor)
                // It's not built-in. Try to parse it as a color.
                parsedColor = parseColor(val);

            if (!parsedColor || !context.allowColor)
                return nullptr; // This value is not a color or length and is invalid or
                          // it is a color, but a color isn't allowed at this point.

            context.commitColor(parsedColor.release());
        }
    }

    if (context.allowBreak) {
        context.commitValue();
        if (context.values && context.values->length())
            return context.values.release();
    }

    return nullptr;
}

static bool isFlexBasisMiddleArg(double flexGrow, double flexShrink, double unsetValue, int argSize)
{
    return flexGrow != unsetValue && flexShrink == unsetValue &&  argSize == 3;
}

// TODO(ojan): Make this have reasonable defaults.
bool CSSPropertyParser::parseFlex(CSSParserValueList* args)
{
    if (!args || !args->size() || args->size() > 3)
        return false;
    static const double unsetValue = -1;
    double flexGrow = unsetValue;
    double flexShrink = unsetValue;
    RefPtr<CSSPrimitiveValue> flexBasis = nullptr;

    while (CSSParserValue* arg = args->current()) {
        if (validUnit(arg, FNumber | FNonNeg)) {
            if (flexGrow == unsetValue)
                flexGrow = arg->fValue;
            else if (flexShrink == unsetValue)
                flexShrink = arg->fValue;
            else if (!arg->fValue) {
                // flex only allows a basis of 0 (sans units) if flex-grow and flex-shrink values have already been set.
                flexBasis = cssValuePool().createValue(0, CSSPrimitiveValue::CSS_PX);
            } else {
                // We only allow 3 numbers without units if the last value is 0. E.g., flex:1 1 1 is invalid.
                return false;
            }
        } else if (!flexBasis && (arg->id == CSSValueAuto || validUnit(arg, FLength | FPercent | FNonNeg)) && !isFlexBasisMiddleArg(flexGrow, flexShrink, unsetValue, args->size()))
            flexBasis = parseValidPrimitive(arg->id, arg);
        else {
            // Not a valid arg for flex.
            return false;
        }
        args->next();
    }

    if (flexGrow == unsetValue)
        flexGrow = 1;
    if (flexShrink == unsetValue)
        flexShrink = 1;
    if (!flexBasis)
        flexBasis = cssValuePool().createValue(0, CSSPrimitiveValue::CSS_PERCENTAGE);

    addProperty(CSSPropertyFlexGrow, cssValuePool().createValue(clampToFloat(flexGrow), CSSPrimitiveValue::CSS_NUMBER));
    addProperty(CSSPropertyFlexShrink, cssValuePool().createValue(clampToFloat(flexShrink), CSSPrimitiveValue::CSS_NUMBER));
    addProperty(CSSPropertyFlexBasis, flexBasis);
    return true;
}

PassRefPtr<CSSValue> CSSPropertyParser::parseObjectPosition()
{
    RefPtr<CSSValue> xValue = nullptr;
    RefPtr<CSSValue> yValue = nullptr;
    parseFillPosition(m_valueList, xValue, yValue);
    if (!xValue || !yValue)
        return nullptr;
    return createPrimitiveValuePair(toCSSPrimitiveValue(xValue.get()), toCSSPrimitiveValue(yValue.get()), Pair::KeepIdenticalValues);
}

class BorderImageParseContext {
    STACK_ALLOCATED();
public:
    BorderImageParseContext()
    : m_canAdvance(false)
    , m_allowCommit(true)
    , m_allowImage(true)
    , m_allowImageSlice(true)
    , m_allowRepeat(true)
    , m_allowForwardSlashOperator(false)
    , m_requireWidth(false)
    , m_requireOutset(false)
    {}

    bool canAdvance() const { return m_canAdvance; }
    void setCanAdvance(bool canAdvance) { m_canAdvance = canAdvance; }

    bool allowCommit() const { return m_allowCommit; }
    bool allowImage() const { return m_allowImage; }
    bool allowImageSlice() const { return m_allowImageSlice; }
    bool allowRepeat() const { return m_allowRepeat; }
    bool allowForwardSlashOperator() const { return m_allowForwardSlashOperator; }

    bool requireWidth() const { return m_requireWidth; }
    bool requireOutset() const { return m_requireOutset; }

    void commitImage(PassRefPtr<CSSValue> image)
    {
        m_image = image;
        m_canAdvance = true;
        m_allowCommit = true;
        m_allowImage = m_allowForwardSlashOperator = m_requireWidth = m_requireOutset = false;
        m_allowImageSlice = !m_imageSlice;
        m_allowRepeat = !m_repeat;
    }
    void commitImageSlice(PassRefPtr<CSSBorderImageSliceValue> slice)
    {
        m_imageSlice = slice;
        m_canAdvance = true;
        m_allowCommit = m_allowForwardSlashOperator = true;
        m_allowImageSlice = m_requireWidth = m_requireOutset = false;
        m_allowImage = !m_image;
        m_allowRepeat = !m_repeat;
    }
    void commitForwardSlashOperator()
    {
        m_canAdvance = true;
        m_allowCommit = m_allowImage = m_allowImageSlice = m_allowRepeat = m_allowForwardSlashOperator = false;
        if (!m_borderWidth) {
            m_requireWidth = true;
            m_requireOutset = false;
        } else {
            m_requireOutset = true;
            m_requireWidth = false;
        }
    }
    void commitBorderWidth(PassRefPtr<CSSPrimitiveValue> width)
    {
        m_borderWidth = width;
        m_canAdvance = true;
        m_allowCommit = m_allowForwardSlashOperator = true;
        m_allowImageSlice = m_requireWidth = m_requireOutset = false;
        m_allowImage = !m_image;
        m_allowRepeat = !m_repeat;
    }
    void commitBorderOutset(PassRefPtr<CSSPrimitiveValue> outset)
    {
        m_outset = outset;
        m_canAdvance = true;
        m_allowCommit = true;
        m_allowImageSlice = m_allowForwardSlashOperator = m_requireWidth = m_requireOutset = false;
        m_allowImage = !m_image;
        m_allowRepeat = !m_repeat;
    }
    void commitRepeat(PassRefPtr<CSSValue> repeat)
    {
        m_repeat = repeat;
        m_canAdvance = true;
        m_allowCommit = true;
        m_allowRepeat = m_allowForwardSlashOperator = m_requireWidth = m_requireOutset = false;
        m_allowImageSlice = !m_imageSlice;
        m_allowImage = !m_image;
    }

    PassRefPtr<CSSValue> commitCSSValue()
    {
        return createBorderImageValue(m_image, m_imageSlice.get(), m_borderWidth.get(), m_outset.get(), m_repeat.get());
    }

    void commitBorderImage(CSSPropertyParser* parser)
    {
        commitBorderImageProperty(CSSPropertyBorderImageSource, parser, m_image);
        commitBorderImageProperty(CSSPropertyBorderImageSlice, parser, m_imageSlice.get());
        commitBorderImageProperty(CSSPropertyBorderImageWidth, parser, m_borderWidth.get());
        commitBorderImageProperty(CSSPropertyBorderImageOutset, parser, m_outset.get());
        commitBorderImageProperty(CSSPropertyBorderImageRepeat, parser, m_repeat);
    }

    void commitBorderImageProperty(CSSPropertyID propId, CSSPropertyParser* parser, PassRefPtr<CSSValue> value)
    {
        if (value)
            parser->addProperty(propId, value);
        else
            parser->addProperty(propId, cssValuePool().createImplicitInitialValue(), true);
    }

    static bool buildFromParser(CSSPropertyParser&, CSSPropertyID, BorderImageParseContext&);

    bool m_canAdvance;

    bool m_allowCommit;
    bool m_allowImage;
    bool m_allowImageSlice;
    bool m_allowRepeat;
    bool m_allowForwardSlashOperator;

    bool m_requireWidth;
    bool m_requireOutset;

    RefPtr<CSSValue> m_image;
    RefPtr<CSSBorderImageSliceValue> m_imageSlice;
    RefPtr<CSSPrimitiveValue> m_borderWidth;
    RefPtr<CSSPrimitiveValue> m_outset;

    RefPtr<CSSValue> m_repeat;
};

bool BorderImageParseContext::buildFromParser(CSSPropertyParser& parser, CSSPropertyID propId, BorderImageParseContext& context)
{
    CSSPropertyParser::ShorthandScope scope(&parser, propId);
    while (CSSParserValue* val = parser.m_valueList->current()) {
        context.setCanAdvance(false);

        if (!context.canAdvance() && context.allowForwardSlashOperator() && isForwardSlashOperator(val))
            context.commitForwardSlashOperator();

        if (!context.canAdvance() && context.allowImage()) {
            if (val->unit == CSSPrimitiveValue::CSS_URI) {
                context.commitImage(parser.createCSSImageValueWithReferrer(val->string, parser.m_context.completeURL(val->string)));
            } else if (isGeneratedImageValue(val)) {
                RefPtr<CSSValue> value = nullptr;
                if (parser.parseGeneratedImage(parser.m_valueList, value))
                    context.commitImage(value.release());
                else
                    return false;
            } else if (val->unit == CSSParserValue::Function && equalIgnoringCase(val->function->name, "-webkit-image-set(")) {
                RefPtr<CSSValue> value = parser.parseImageSet(parser.m_valueList);
                if (value)
                    context.commitImage(value.release());
                else
                    return false;
            } else if (val->id == CSSValueNone)
                context.commitImage(cssValuePool().createIdentifierValue(CSSValueNone));
        }

        if (!context.canAdvance() && context.allowImageSlice()) {
            RefPtr<CSSBorderImageSliceValue> imageSlice = nullptr;
            if (parser.parseBorderImageSlice(propId, imageSlice))
                context.commitImageSlice(imageSlice.release());
        }

        if (!context.canAdvance() && context.allowRepeat()) {
            RefPtr<CSSValue> repeat = nullptr;
            if (parser.parseBorderImageRepeat(repeat))
                context.commitRepeat(repeat.release());
        }

        if (!context.canAdvance() && context.requireWidth()) {
            RefPtr<CSSPrimitiveValue> borderWidth = nullptr;
            if (parser.parseBorderImageWidth(borderWidth))
                context.commitBorderWidth(borderWidth.release());
        }

        if (!context.canAdvance() && context.requireOutset()) {
            RefPtr<CSSPrimitiveValue> borderOutset = nullptr;
            if (parser.parseBorderImageOutset(borderOutset))
                context.commitBorderOutset(borderOutset.release());
        }

        if (!context.canAdvance())
            return false;

        parser.m_valueList->next();
    }

    return context.allowCommit();
}

bool CSSPropertyParser::parseBorderImageShorthand(CSSPropertyID propId)
{
    BorderImageParseContext context;
    if (BorderImageParseContext::buildFromParser(*this, propId, context)) {
        ASSERT(propId == CSSPropertyBorderImage);
        context.commitBorderImage(this);
        return true;
    }
    return false;
}

PassRefPtr<CSSValue> CSSPropertyParser::parseBorderImage(CSSPropertyID propId)
{
    BorderImageParseContext context;
    if (BorderImageParseContext::buildFromParser(*this, propId, context)) {
        return context.commitCSSValue();
    }
    return nullptr;
}

static bool isBorderImageRepeatKeyword(int id)
{
    return id == CSSValueStretch || id == CSSValueRepeat || id == CSSValueSpace || id == CSSValueRound;
}

bool CSSPropertyParser::parseBorderImageRepeat(RefPtr<CSSValue>& result)
{
    RefPtr<CSSPrimitiveValue> firstValue = nullptr;
    RefPtr<CSSPrimitiveValue> secondValue = nullptr;
    CSSParserValue* val = m_valueList->current();
    if (!val)
        return false;
    if (isBorderImageRepeatKeyword(val->id))
        firstValue = cssValuePool().createIdentifierValue(val->id);
    else
        return false;

    val = m_valueList->next();
    if (val) {
        if (isBorderImageRepeatKeyword(val->id))
            secondValue = cssValuePool().createIdentifierValue(val->id);
        else if (!inShorthand()) {
            // If we're not parsing a shorthand then we are invalid.
            return false;
        } else {
            // We need to rewind the value list, so that when its advanced we'll
            // end up back at this value.
            m_valueList->previous();
            secondValue = firstValue;
        }
    } else
        secondValue = firstValue;

    result = createPrimitiveValuePair(firstValue, secondValue);
    return true;
}

class BorderImageSliceParseContext {
    STACK_ALLOCATED();
public:
    BorderImageSliceParseContext(CSSPropertyParser* parser)
    : m_parser(parser)
    , m_allowNumber(true)
    , m_allowFill(true)
    , m_allowFinalCommit(false)
    , m_fill(false)
    { }

    bool allowNumber() const { return m_allowNumber; }
    bool allowFill() const { return m_allowFill; }
    bool allowFinalCommit() const { return m_allowFinalCommit; }
    CSSPrimitiveValue* top() const { return m_top.get(); }

    void commitNumber(CSSParserValue* v)
    {
        RefPtr<CSSPrimitiveValue> val = m_parser->createPrimitiveNumericValue(v);
        if (!m_top)
            m_top = val;
        else if (!m_right)
            m_right = val;
        else if (!m_bottom)
            m_bottom = val;
        else {
            ASSERT(!m_left);
            m_left = val;
        }

        m_allowNumber = !m_left;
        m_allowFinalCommit = true;
    }

    void commitFill() { m_fill = true; m_allowFill = false; m_allowNumber = !m_top; }

    PassRefPtr<CSSBorderImageSliceValue> commitBorderImageSlice()
    {
        // We need to clone and repeat values for any omissions.
        ASSERT(m_top);
        if (!m_right) {
            m_right = m_top;
            m_bottom = m_top;
            m_left = m_top;
        }
        if (!m_bottom) {
            m_bottom = m_top;
            m_left = m_right;
        }
        if (!m_left)
            m_left = m_right;

        // Now build a rect value to hold all four of our primitive values.
        RefPtr<Quad> quad = Quad::create();
        quad->setTop(m_top);
        quad->setRight(m_right);
        quad->setBottom(m_bottom);
        quad->setLeft(m_left);

        // Make our new border image value now.
        return CSSBorderImageSliceValue::create(cssValuePool().createValue(quad.release()), m_fill);
    }

private:
    CSSPropertyParser* m_parser;

    bool m_allowNumber;
    bool m_allowFill;
    bool m_allowFinalCommit;

    RefPtr<CSSPrimitiveValue> m_top;
    RefPtr<CSSPrimitiveValue> m_right;
    RefPtr<CSSPrimitiveValue> m_bottom;
    RefPtr<CSSPrimitiveValue> m_left;

    bool m_fill;
};

bool CSSPropertyParser::parseBorderImageSlice(CSSPropertyID propId, RefPtr<CSSBorderImageSliceValue>& result)
{
    BorderImageSliceParseContext context(this);
    for (CSSParserValue* val = m_valueList->current(); val; val = m_valueList->next()) {
        // FIXME calc() http://webkit.org/b/16662 : calc is parsed but values are not created yet.
        if (context.allowNumber() && !isCalculation(val) && validUnit(val, FInteger | FNonNeg | FPercent)) {
            context.commitNumber(val);
        } else if (context.allowFill() && val->id == CSSValueFill) {
            context.commitFill();
        } else if (!inShorthand()) {
            // If we're not parsing a shorthand then we are invalid.
            return false;
        } else {
            if (context.allowFinalCommit()) {
                // We're going to successfully parse, but we don't want to consume this token.
                m_valueList->previous();
            }
            break;
        }
    }

    if (context.allowFinalCommit()) {
        // FIXME(sky): Remove this.
        // FIXME: For backwards compatibility, -webkit-border-image has to do a fill by default.
        if (propId == CSSPropertyWebkitBorderImage)
            context.commitFill();

        // Need to fully commit as a single value.
        result = context.commitBorderImageSlice();
        return true;
    }

    return false;
}

class BorderImageQuadParseContext {
    STACK_ALLOCATED();
public:
    BorderImageQuadParseContext(CSSPropertyParser* parser)
    : m_parser(parser)
    , m_allowNumber(true)
    , m_allowFinalCommit(false)
    { }

    bool allowNumber() const { return m_allowNumber; }
    bool allowFinalCommit() const { return m_allowFinalCommit; }
    CSSPrimitiveValue* top() const { return m_top.get(); }

    void commitNumber(CSSParserValue* v)
    {
        RefPtr<CSSPrimitiveValue> val = nullptr;
        if (v->id == CSSValueAuto)
            val = cssValuePool().createIdentifierValue(v->id);
        else
            val = m_parser->createPrimitiveNumericValue(v);

        if (!m_top)
            m_top = val;
        else if (!m_right)
            m_right = val;
        else if (!m_bottom)
            m_bottom = val;
        else {
            ASSERT(!m_left);
            m_left = val;
        }

        m_allowNumber = !m_left;
        m_allowFinalCommit = true;
    }

    void setTop(PassRefPtr<CSSPrimitiveValue> val) { m_top = val; }

    PassRefPtr<CSSPrimitiveValue> commitBorderImageQuad()
    {
        // We need to clone and repeat values for any omissions.
        ASSERT(m_top);
        if (!m_right) {
            m_right = m_top;
            m_bottom = m_top;
            m_left = m_top;
        }
        if (!m_bottom) {
            m_bottom = m_top;
            m_left = m_right;
        }
        if (!m_left)
            m_left = m_right;

        // Now build a quad value to hold all four of our primitive values.
        RefPtr<Quad> quad = Quad::create();
        quad->setTop(m_top);
        quad->setRight(m_right);
        quad->setBottom(m_bottom);
        quad->setLeft(m_left);

        // Make our new value now.
        return cssValuePool().createValue(quad.release());
    }

private:
    CSSPropertyParser* m_parser;

    bool m_allowNumber;
    bool m_allowFinalCommit;

    RefPtr<CSSPrimitiveValue> m_top;
    RefPtr<CSSPrimitiveValue> m_right;
    RefPtr<CSSPrimitiveValue> m_bottom;
    RefPtr<CSSPrimitiveValue> m_left;
};

bool CSSPropertyParser::parseBorderImageQuad(Units validUnits, RefPtr<CSSPrimitiveValue>& result)
{
    BorderImageQuadParseContext context(this);
    for (CSSParserValue* val = m_valueList->current(); val; val = m_valueList->next()) {
        if (context.allowNumber() && (validUnit(val, validUnits, HTMLStandardMode) || val->id == CSSValueAuto)) {
            context.commitNumber(val);
        } else if (!inShorthand()) {
            // If we're not parsing a shorthand then we are invalid.
            return false;
        } else {
            if (context.allowFinalCommit())
                m_valueList->previous(); // The shorthand loop will advance back to this point.
            break;
        }
    }

    if (context.allowFinalCommit()) {
        // Need to fully commit as a single value.
        result = context.commitBorderImageQuad();
        return true;
    }
    return false;
}

bool CSSPropertyParser::parseBorderImageWidth(RefPtr<CSSPrimitiveValue>& result)
{
    return parseBorderImageQuad(FLength | FNumber | FNonNeg | FPercent, result);
}

bool CSSPropertyParser::parseBorderImageOutset(RefPtr<CSSPrimitiveValue>& result)
{
    return parseBorderImageQuad(FLength | FNumber | FNonNeg, result);
}

bool CSSPropertyParser::parseBorderRadius(CSSPropertyID propId)
{
    unsigned num = m_valueList->size();
    if (num > 9)
        return false;

    ShorthandScope scope(this, propId);
    RefPtr<CSSPrimitiveValue> radii[2][4];
#if ENABLE(OILPAN)
    // Zero initialize the array of raw pointers.
    memset(&radii, 0, sizeof(radii));
#endif

    unsigned indexAfterSlash = 0;
    for (unsigned i = 0; i < num; ++i) {
        CSSParserValue* value = m_valueList->valueAt(i);
        if (value->unit == CSSParserValue::Operator) {
            if (value->iValue != '/')
                return false;

            if (!i || indexAfterSlash || i + 1 == num || num > i + 5)
                return false;

            indexAfterSlash = i + 1;
            completeBorderRadii(radii[0]);
            continue;
        }

        if (i - indexAfterSlash >= 4)
            return false;

        if (!validUnit(value, FLength | FPercent | FNonNeg))
            return false;

        RefPtr<CSSPrimitiveValue> radius = createPrimitiveNumericValue(value);

        if (!indexAfterSlash) {
            radii[0][i] = radius;

            // Legacy syntax: -webkit-border-radius: l1 l2; is equivalent to border-radius: l1 / l2;
            if (num == 2 && propId == CSSPropertyWebkitBorderRadius) {
                indexAfterSlash = 1;
                completeBorderRadii(radii[0]);
            }
        } else
            radii[1][i - indexAfterSlash] = radius.release();
    }

    if (!indexAfterSlash) {
        completeBorderRadii(radii[0]);
        for (unsigned i = 0; i < 4; ++i)
            radii[1][i] = radii[0][i];
    } else
        completeBorderRadii(radii[1]);

    ImplicitScope implicitScope(this);
    addProperty(CSSPropertyBorderTopLeftRadius, createPrimitiveValuePair(radii[0][0].release(), radii[1][0].release()));
    addProperty(CSSPropertyBorderTopRightRadius, createPrimitiveValuePair(radii[0][1].release(), radii[1][1].release()));
    addProperty(CSSPropertyBorderBottomRightRadius, createPrimitiveValuePair(radii[0][2].release(), radii[1][2].release()));
    addProperty(CSSPropertyBorderBottomLeftRadius, createPrimitiveValuePair(radii[0][3].release(), radii[1][3].release()));
    return true;
}

PassRefPtr<CSSValue> CSSPropertyParser::parseAspectRatio()
{
    unsigned num = m_valueList->size();
    if (num == 1 && m_valueList->valueAt(0)->id == CSSValueNone) {
        m_valueList->next();
        return cssValuePool().createIdentifierValue(CSSValueNone);
    }

    if (num != 3)
        return nullptr;

    CSSParserValue* lvalue = m_valueList->current();
    CSSParserValue* op = m_valueList->next();
    CSSParserValue* rvalue = m_valueList->next();
    m_valueList->next();

    if (!isForwardSlashOperator(op))
        return nullptr;

    if (!validUnit(lvalue, FNumber | FNonNeg) || !validUnit(rvalue, FNumber | FNonNeg))
        return nullptr;

    if (!lvalue->fValue || !rvalue->fValue)
        return nullptr;

    return CSSAspectRatioValue::create(narrowPrecisionToFloat(lvalue->fValue), narrowPrecisionToFloat(rvalue->fValue));
}

static PassRefPtr<CSSPrimitiveValue> valueFromSideKeyword(CSSParserValue* a, bool& isHorizontal)
{
    if (a->unit != CSSPrimitiveValue::CSS_IDENT)
        return nullptr;

    switch (a->id) {
        case CSSValueLeft:
        case CSSValueRight:
            isHorizontal = true;
            break;
        case CSSValueTop:
        case CSSValueBottom:
            isHorizontal = false;
            break;
        default:
            return nullptr;
    }
    return cssValuePool().createIdentifierValue(a->id);
}

PassRefPtr<CSSPrimitiveValue> parseGradientColorOrKeyword(CSSPropertyParser* p, CSSParserValue* value)
{
    CSSValueID id = value->id;
    if (id == CSSValueCurrentcolor)
        return cssValuePool().createIdentifierValue(id);

    return p->parseColor(value);
}

bool CSSPropertyParser::parseLinearGradient(CSSParserValueList* valueList, RefPtr<CSSValue>& gradient, CSSGradientRepeat repeating)
{
    RefPtr<CSSLinearGradientValue> result = CSSLinearGradientValue::create(repeating, CSSLinearGradient);

    CSSParserValueList* args = valueList->current()->function->args.get();
    if (!args || !args->size())
        return false;

    CSSParserValue* a = args->current();
    if (!a)
        return false;

    bool expectComma = false;
    // Look for angle.
    if (validUnit(a, FAngle, HTMLStandardMode)) {
        result->setAngle(createPrimitiveNumericValue(a));

        args->next();
        expectComma = true;
    } else if (a->unit == CSSPrimitiveValue::CSS_IDENT && equalIgnoringCase(a, "to")) {
        // to [ [left | right] || [top | bottom] ]
        a = args->next();
        if (!a)
            return false;

        RefPtr<CSSPrimitiveValue> endX = nullptr;
        RefPtr<CSSPrimitiveValue> endY = nullptr;
        RefPtr<CSSPrimitiveValue> location = nullptr;
        bool isHorizontal = false;

        location = valueFromSideKeyword(a, isHorizontal);
        if (!location)
            return false;

        if (isHorizontal)
            endX = location;
        else
            endY = location;

        a = args->next();
        if (!a)
            return false;

        location = valueFromSideKeyword(a, isHorizontal);
        if (location) {
            if (isHorizontal) {
                if (endX)
                    return false;
                endX = location;
            } else {
                if (endY)
                    return false;
                endY = location;
            }

            args->next();
        }

        expectComma = true;
        result->setFirstX(endX.release());
        result->setFirstY(endY.release());
    }

    if (!parseGradientColorStops(args, result.get(), expectComma))
        return false;

    if (!result->stopCount())
        return false;

    gradient = result.release();
    return true;
}

bool CSSPropertyParser::parseRadialGradient(CSSParserValueList* valueList, RefPtr<CSSValue>& gradient, CSSGradientRepeat repeating)
{
    RefPtr<CSSRadialGradientValue> result = CSSRadialGradientValue::create(repeating, CSSRadialGradient);

    CSSParserValueList* args = valueList->current()->function->args.get();
    if (!args || !args->size())
        return false;

    CSSParserValue* a = args->current();
    if (!a)
        return false;

    bool expectComma = false;

    RefPtr<CSSPrimitiveValue> shapeValue = nullptr;
    RefPtr<CSSPrimitiveValue> sizeValue = nullptr;
    RefPtr<CSSPrimitiveValue> horizontalSize = nullptr;
    RefPtr<CSSPrimitiveValue> verticalSize = nullptr;

    // First part of grammar, the size/shape clause:
    // [ circle || <length> ] |
    // [ ellipse || [ <length> | <percentage> ]{2} ] |
    // [ [ circle | ellipse] || <size-keyword> ]
    for (int i = 0; i < 3; ++i) {
        if (a->unit == CSSPrimitiveValue::CSS_IDENT) {
            bool badIdent = false;
            switch (a->id) {
            case CSSValueCircle:
            case CSSValueEllipse:
                if (shapeValue)
                    return false;
                shapeValue = cssValuePool().createIdentifierValue(a->id);
                break;
            case CSSValueClosestSide:
            case CSSValueClosestCorner:
            case CSSValueFarthestSide:
            case CSSValueFarthestCorner:
                if (sizeValue || horizontalSize)
                    return false;
                sizeValue = cssValuePool().createIdentifierValue(a->id);
                break;
            default:
                badIdent = true;
            }

            if (badIdent)
                break;

            a = args->next();
            if (!a)
                return false;
        } else if (validUnit(a, FLength | FPercent)) {

            if (sizeValue || horizontalSize)
                return false;
            horizontalSize = createPrimitiveNumericValue(a);

            a = args->next();
            if (!a)
                return false;

            if (validUnit(a, FLength | FPercent)) {
                verticalSize = createPrimitiveNumericValue(a);
                ++i;
                a = args->next();
                if (!a)
                    return false;
            }
        } else
            break;
    }

    // You can specify size as a keyword or a length/percentage, not both.
    if (sizeValue && horizontalSize)
        return false;
    // Circles must have 0 or 1 lengths.
    if (shapeValue && shapeValue->getValueID() == CSSValueCircle && verticalSize)
        return false;
    // Ellipses must have 0 or 2 length/percentages.
    if (shapeValue && shapeValue->getValueID() == CSSValueEllipse && horizontalSize && !verticalSize)
        return false;
    // If there's only one size, it must be a length.
    if (!verticalSize && horizontalSize && horizontalSize->isPercentage())
        return false;

    result->setShape(shapeValue);
    result->setSizingBehavior(sizeValue);
    result->setEndHorizontalSize(horizontalSize);
    result->setEndVerticalSize(verticalSize);

    // Second part of grammar, the center-position clause:
    // at <position>
    RefPtr<CSSValue> centerX = nullptr;
    RefPtr<CSSValue> centerY = nullptr;
    if (a->unit == CSSPrimitiveValue::CSS_IDENT && a->id == CSSValueAt) {
        a = args->next();
        if (!a)
            return false;

        parseFillPosition(args, centerX, centerY);
        if (!(centerX && centerY))
            return false;

        a = args->current();
        if (!a)
            return false;
        result->setFirstX(toCSSPrimitiveValue(centerX.get()));
        result->setFirstY(toCSSPrimitiveValue(centerY.get()));
        // Right now, CSS radial gradients have the same start and end centers.
        result->setSecondX(toCSSPrimitiveValue(centerX.get()));
        result->setSecondY(toCSSPrimitiveValue(centerY.get()));
    }

    if (shapeValue || sizeValue || horizontalSize || centerX || centerY)
        expectComma = true;

    if (!parseGradientColorStops(args, result.get(), expectComma))
        return false;

    gradient = result.release();
    return true;
}

bool CSSPropertyParser::parseGradientColorStops(CSSParserValueList* valueList, CSSGradientValue* gradient, bool expectComma)
{
    CSSParserValue* a = valueList->current();

    // Now look for color stops.
    while (a) {
        // Look for the comma before the next stop.
        if (expectComma) {
            if (!isComma(a))
                return false;

            a = valueList->next();
            if (!a)
                return false;
        }

        // <color-stop> = <color> [ <percentage> | <length> ]?
        CSSGradientColorStop stop;
        stop.m_color = parseGradientColorOrKeyword(this, a);
        if (!stop.m_color)
            return false;

        a = valueList->next();
        if (a) {
            if (validUnit(a, FLength | FPercent)) {
                stop.m_position = createPrimitiveNumericValue(a);
                a = valueList->next();
            }
        }

        gradient->addStop(stop);
        expectComma = true;
    }

    // Must have 2 or more stops to be valid.
    return gradient->stopCount() >= 2;
}

bool CSSPropertyParser::parseGeneratedImage(CSSParserValueList* valueList, RefPtr<CSSValue>& value)
{
    CSSParserValue* val = valueList->current();

    if (val->unit != CSSParserValue::Function)
        return false;

    if (equalIgnoringCase(val->function->name, "linear-gradient("))
        return parseLinearGradient(valueList, value, NonRepeating);

    if (equalIgnoringCase(val->function->name, "repeating-linear-gradient("))
        return parseLinearGradient(valueList, value, Repeating);

    if (equalIgnoringCase(val->function->name, "radial-gradient("))
        return parseRadialGradient(valueList, value, NonRepeating);

    if (equalIgnoringCase(val->function->name, "repeating-radial-gradient("))
        return parseRadialGradient(valueList, value, Repeating);

    if (equalIgnoringCase(val->function->name, "-webkit-cross-fade("))
        return parseCrossfade(valueList, value);

    return false;
}

bool CSSPropertyParser::parseCrossfade(CSSParserValueList* valueList, RefPtr<CSSValue>& crossfade)
{
    // Walk the arguments.
    CSSParserValueList* args = valueList->current()->function->args.get();
    if (!args || args->size() != 5)
        return false;
    RefPtr<CSSValue> fromImageValue = nullptr;
    RefPtr<CSSValue> toImageValue = nullptr;

    // The first argument is the "from" image. It is a fill image.
    if (!args->current() || !parseFillImage(args, fromImageValue))
        return false;
    args->next();

    if (!consumeComma(args))
        return false;

    // The second argument is the "to" image. It is a fill image.
    if (!args->current() || !parseFillImage(args, toImageValue))
        return false;
    args->next();

    if (!consumeComma(args))
        return false;

    // The third argument is the crossfade value. It is a percentage or a fractional number.
    RefPtr<CSSPrimitiveValue> percentage = nullptr;
    CSSParserValue* value = args->current();
    if (!value)
        return false;

    if (value->unit == CSSPrimitiveValue::CSS_PERCENTAGE)
        percentage = cssValuePool().createValue(clampTo<double>(value->fValue / 100, 0, 1), CSSPrimitiveValue::CSS_NUMBER);
    else if (value->unit == CSSPrimitiveValue::CSS_NUMBER)
        percentage = cssValuePool().createValue(clampTo<double>(value->fValue, 0, 1), CSSPrimitiveValue::CSS_NUMBER);
    else
        return false;

    RefPtr<CSSCrossfadeValue> result = CSSCrossfadeValue::create(fromImageValue, toImageValue);
    result->setPercentage(percentage);

    crossfade = result;

    return true;
}

PassRefPtr<CSSValue> CSSPropertyParser::parseImageSet(CSSParserValueList* valueList)
{
    CSSParserValue* function = valueList->current();

    if (function->unit != CSSParserValue::Function)
        return nullptr;

    CSSParserValueList* functionArgs = valueList->current()->function->args.get();
    if (!functionArgs || !functionArgs->size() || !functionArgs->current())
        return nullptr;

    RefPtr<CSSImageSetValue> imageSet = CSSImageSetValue::create();

    while (functionArgs->current()) {
        CSSParserValue* arg = functionArgs->current();
        if (arg->unit != CSSPrimitiveValue::CSS_URI)
            return nullptr;

        RefPtr<CSSValue> image = createCSSImageValueWithReferrer(arg->string, completeURL(arg->string));
        imageSet->append(image);

        arg = functionArgs->next();
        if (!arg || arg->unit != CSSPrimitiveValue::CSS_DIMENSION)
            return nullptr;

        double imageScaleFactor = 0;
        const String& string = arg->string;
        unsigned length = string.length();
        if (!length)
            return nullptr;
        if (string.is8Bit()) {
            const LChar* start = string.characters8();
            parseDouble(start, start + length, 'x', imageScaleFactor);
        } else {
            const UChar* start = string.characters16();
            parseDouble(start, start + length, 'x', imageScaleFactor);
        }
        if (imageScaleFactor <= 0)
            return nullptr;
        imageSet->append(cssValuePool().createValue(imageScaleFactor, CSSPrimitiveValue::CSS_NUMBER));
        functionArgs->next();

        // If there are no more arguments, we're done.
        if (!functionArgs->current())
            break;

        // If there are more arguments, they should be after a comma.
        if (!consumeComma(functionArgs))
            return nullptr;
    }

    return imageSet.release();
}

PassRefPtr<CSSValue> CSSPropertyParser::parseWillChange()
{
    RefPtr<CSSValueList> values = CSSValueList::createCommaSeparated();
    if (m_valueList->current()->id == CSSValueAuto) {
        // FIXME: This will be read back as an empty string instead of auto
        return values.release();
    }

    // Every comma-separated list of CSS_IDENTs is a valid will-change value,
    // unless the list includes an explicitly disallowed CSS_IDENT.
    while (true) {
        CSSParserValue* currentValue = m_valueList->current();
        if (!currentValue || currentValue->unit != CSSPrimitiveValue::CSS_IDENT)
            return nullptr;

        CSSPropertyID property = cssPropertyID(currentValue->string);
        if (property) {
            ASSERT(CSSPropertyMetadata::isEnabledProperty(property));
            // Now "all" is used by both CSSValue and CSSPropertyValue.
            // Need to return nullptr when currentValue is CSSPropertyAll.
            if (property == CSSPropertyWillChange || property == CSSPropertyAll)
                return nullptr;
            values->append(cssValuePool().createIdentifierValue(property));
        } else {
            switch (currentValue->id) {
            case CSSValueNone:
            case CSSValueAll:
            case CSSValueAuto:
            case CSSValueDefault:
            case CSSValueInitial:
            case CSSValueInherit:
                return nullptr;
            case CSSValueContents:
                values->append(cssValuePool().createIdentifierValue(currentValue->id));
                break;
            default:
                break;
            }
        }

        if (!m_valueList->next())
            break;
        if (!consumeComma(m_valueList))
            return nullptr;
    }

    return values.release();
}

static void filterInfoForName(const CSSParserString& name, CSSFilterValue::FilterOperationType& filterType, unsigned& maximumArgumentCount)
{
    if (equalIgnoringCase(name, "grayscale("))
        filterType = CSSFilterValue::GrayscaleFilterOperation;
    else if (equalIgnoringCase(name, "sepia("))
        filterType = CSSFilterValue::SepiaFilterOperation;
    else if (equalIgnoringCase(name, "saturate("))
        filterType = CSSFilterValue::SaturateFilterOperation;
    else if (equalIgnoringCase(name, "hue-rotate("))
        filterType = CSSFilterValue::HueRotateFilterOperation;
    else if (equalIgnoringCase(name, "invert("))
        filterType = CSSFilterValue::InvertFilterOperation;
    else if (equalIgnoringCase(name, "opacity("))
        filterType = CSSFilterValue::OpacityFilterOperation;
    else if (equalIgnoringCase(name, "brightness("))
        filterType = CSSFilterValue::BrightnessFilterOperation;
    else if (equalIgnoringCase(name, "contrast("))
        filterType = CSSFilterValue::ContrastFilterOperation;
    else if (equalIgnoringCase(name, "blur("))
        filterType = CSSFilterValue::BlurFilterOperation;
    else if (equalIgnoringCase(name, "drop-shadow(")) {
        filterType = CSSFilterValue::DropShadowFilterOperation;
        maximumArgumentCount = 4;  // x-offset, y-offset, blur-radius, color -- spread and inset style not allowed.
    }
}

PassRefPtr<CSSFilterValue> CSSPropertyParser::parseBuiltinFilterArguments(CSSParserValueList* args, CSSFilterValue::FilterOperationType filterType)
{
    RefPtr<CSSFilterValue> filterValue = CSSFilterValue::create(filterType);
    ASSERT(args);

    switch (filterType) {
    case CSSFilterValue::GrayscaleFilterOperation:
    case CSSFilterValue::SepiaFilterOperation:
    case CSSFilterValue::SaturateFilterOperation:
    case CSSFilterValue::InvertFilterOperation:
    case CSSFilterValue::OpacityFilterOperation:
    case CSSFilterValue::ContrastFilterOperation: {
        // One optional argument, 0-1 or 0%-100%, if missing use 100%.
        if (args->size()) {
            CSSParserValue* value = args->current();
            // FIXME (crbug.com/397061): Support calc expressions like calc(10% + 0.5)
            if (value->unit != CSSPrimitiveValue::CSS_PERCENTAGE && !validUnit(value, FNumber | FNonNeg))
                return nullptr;

            double amount = value->fValue;
            if (amount < 0)
                return nullptr;

            // Saturate and Contrast allow values over 100%.
            if (filterType != CSSFilterValue::SaturateFilterOperation
                && filterType != CSSFilterValue::ContrastFilterOperation) {
                double maxAllowed = value->unit == CSSPrimitiveValue::CSS_PERCENTAGE ? 100.0 : 1.0;
                if (amount > maxAllowed)
                    return nullptr;
            }

            filterValue->append(cssValuePool().createValue(amount, static_cast<CSSPrimitiveValue::UnitType>(value->unit)));
        }
        break;
    }
    case CSSFilterValue::BrightnessFilterOperation: {
        // One optional argument, if missing use 100%.
        if (args->size()) {
            CSSParserValue* value = args->current();
            // FIXME (crbug.com/397061): Support calc expressions like calc(10% + 0.5)
            if (value->unit != CSSPrimitiveValue::CSS_PERCENTAGE && !validUnit(value, FNumber))
                return nullptr;

            filterValue->append(cssValuePool().createValue(value->fValue, static_cast<CSSPrimitiveValue::UnitType>(value->unit)));
        }
        break;
    }
    case CSSFilterValue::HueRotateFilterOperation: {
        // hue-rotate() takes one optional angle.
        if (args->size()) {
            CSSParserValue* argument = args->current();
            if (!validUnit(argument, FAngle, HTMLStandardMode))
                return nullptr;

            filterValue->append(createPrimitiveNumericValue(argument));
        }
        break;
    }
    case CSSFilterValue::BlurFilterOperation: {
        // Blur takes a single length. Zero parameters are allowed.
        if (args->size()) {
            CSSParserValue* argument = args->current();
            if (!validUnit(argument, FLength | FNonNeg, HTMLStandardMode))
                return nullptr;

            filterValue->append(createPrimitiveNumericValue(argument));
        }
        break;
    }
    case CSSFilterValue::DropShadowFilterOperation: {
        // drop-shadow() takes a single shadow.
        RefPtr<CSSValueList> shadowValueList = parseShadow(args, CSSPropertyFilter);
        if (!shadowValueList || shadowValueList->length() != 1)
            return nullptr;

        filterValue->append((shadowValueList.release())->item(0));
        break;
    }
    default:
        ASSERT_NOT_REACHED();
    }
    return filterValue.release();
}

PassRefPtr<CSSValueList> CSSPropertyParser::parseFilter()
{
    if (!m_valueList)
        return nullptr;

    // The filter is a list of functional primitives that specify individual operations.
    RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
    for (CSSParserValue* value = m_valueList->current(); value; value = m_valueList->next()) {
        if (value->unit != CSSPrimitiveValue::CSS_URI && (value->unit != CSSParserValue::Function || !value->function))
            return nullptr;

        CSSFilterValue::FilterOperationType filterType = CSSFilterValue::UnknownFilterOperation;

        const CSSParserString name = value->function->name;
        unsigned maximumArgumentCount = 1;

        filterInfoForName(name, filterType, maximumArgumentCount);

        if (filterType == CSSFilterValue::UnknownFilterOperation)
            return nullptr;

        CSSParserValueList* args = value->function->args.get();
        if (!args || args->size() > maximumArgumentCount)
            return nullptr;

        RefPtr<CSSFilterValue> filterValue = parseBuiltinFilterArguments(args, filterType);
        if (!filterValue)
            return nullptr;

        list->append(filterValue);
    }

    return list.release();
}
PassRefPtr<CSSValueList> CSSPropertyParser::parseTransformOrigin()
{
    CSSParserValue* value = m_valueList->current();
    CSSValueID id = value->id;
    RefPtr<CSSValue> xValue = nullptr;
    RefPtr<CSSValue> yValue = nullptr;
    RefPtr<CSSValue> zValue = nullptr;
    if (id == CSSValueLeft || id == CSSValueRight) {
        xValue = cssValuePool().createIdentifierValue(id);
    } else if (id == CSSValueTop || id == CSSValueBottom) {
        yValue = cssValuePool().createIdentifierValue(id);
    } else if (id == CSSValueCenter) {
        // Unresolved as to whether this is X or Y.
    } else if (validUnit(value, FPercent | FLength)) {
        xValue = createPrimitiveNumericValue(value);
    } else {
        return nullptr;
    }

    value = m_valueList->next();
    if (value) {
        id = value->id;
        if (!xValue && (id == CSSValueLeft || id == CSSValueRight)) {
            xValue = cssValuePool().createIdentifierValue(id);
        } else if (!yValue && (id == CSSValueTop || id == CSSValueBottom)) {
            yValue = cssValuePool().createIdentifierValue(id);
        } else if (id == CSSValueCenter) {
            // Resolved below.
        } else if (!yValue && validUnit(value, FPercent | FLength)) {
            yValue = createPrimitiveNumericValue(value);
        } else {
            return nullptr;
        }

        // If X or Y have not been resolved, they must be center.
        if (!xValue)
            xValue = cssValuePool().createIdentifierValue(CSSValueCenter);
        if (!yValue)
            yValue = cssValuePool().createIdentifierValue(CSSValueCenter);

        value = m_valueList->next();
        if (value) {
            if (!validUnit(value, FLength))
                return nullptr;
            zValue = createPrimitiveNumericValue(value);

            value = m_valueList->next();
            if (value)
                return nullptr;
        }
    } else if (!xValue) {
        if (yValue) {
            xValue = cssValuePool().createValue(50, CSSPrimitiveValue::CSS_PERCENTAGE);
        } else {
            xValue = cssValuePool().createIdentifierValue(CSSValueCenter);
        }
    }

    RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
    list->append(xValue.release());
    if (yValue)
        list->append(yValue.release());
    if (zValue)
        list->append(zValue.release());
    return list.release();
}

PassRefPtr<CSSValue> CSSPropertyParser::parseTouchAction()
{
    CSSParserValue* value = m_valueList->current();
    RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
    if (m_valueList->size() == 1 && value && (value->id == CSSValueAuto || value->id == CSSValueNone || value->id == CSSValueManipulation)) {
        list->append(cssValuePool().createIdentifierValue(value->id));
        m_valueList->next();
        return list.release();
    }

    while (value) {
        switch (value->id) {
        case CSSValuePanX:
        case CSSValuePanY: {
            RefPtr<CSSValue> panValue = cssValuePool().createIdentifierValue(value->id);
            if (list->hasValue(panValue.get()))
                return nullptr;
            list->append(panValue.release());
            break;
        }
        default:
            return nullptr;
        }
        value = m_valueList->next();
    }

    if (list->length())
        return list.release();

    return nullptr;
}

void CSSPropertyParser::addTextDecorationProperty(CSSPropertyID propId, PassRefPtr<CSSValue> value)
{
    // The text-decoration-line property takes priority over text-decoration.
    if (propId == CSSPropertyTextDecoration && !inShorthand()) {
        for (unsigned i = 0; i < m_parsedProperties.size(); ++i) {
            if (m_parsedProperties[i].id() == CSSPropertyTextDecorationLine)
                return;
        }
    }
    addProperty(propId, value);
}

bool CSSPropertyParser::parseTextDecoration(CSSPropertyID propId)
{
    ASSERT(propId != CSSPropertyTextDecorationLine || RuntimeEnabledFeatures::css3TextDecorationsEnabled());

    CSSParserValue* value = m_valueList->current();
    if (value && value->id == CSSValueNone) {
        addTextDecorationProperty(propId, cssValuePool().createIdentifierValue(CSSValueNone));
        m_valueList->next();
        return true;
    }

    RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
    bool isValid = true;
    while (isValid && value) {
        switch (value->id) {
        case CSSValueUnderline:
        case CSSValueOverline:
        case CSSValueLineThrough:
        case CSSValueBlink:
            list->append(cssValuePool().createIdentifierValue(value->id));
            break;
        default:
            isValid = false;
            break;
        }
        if (isValid)
            value = m_valueList->next();
    }

    // Values are either valid or in shorthand scope.
    if (list->length() && (isValid || inShorthand())) {
        addTextDecorationProperty(propId, list.release());
        return true;
    }

    return false;
}

bool CSSPropertyParser::parseTextUnderlinePosition()
{
    // The text-underline-position property has syntax "auto | [ under || [ left | right ] ]".
    // However, values 'left' and 'right' are not implemented yet, so we will parse syntax
    // "auto | under" for now.
    CSSParserValue* value = m_valueList->current();
    switch (value->id) {
    case CSSValueAuto:
    case CSSValueUnder:
        if (m_valueList->next())
            return false;
        addProperty(CSSPropertyTextUnderlinePosition, cssValuePool().createIdentifierValue(value->id));
        return true;
    default:
        return false;
    }
}

bool CSSPropertyParser::parseTextEmphasisStyle()
{
    unsigned valueListSize = m_valueList->size();

    RefPtr<CSSPrimitiveValue> fill = nullptr;
    RefPtr<CSSPrimitiveValue> shape = nullptr;

    for (CSSParserValue* value = m_valueList->current(); value; value = m_valueList->next()) {
        if (value->unit == CSSPrimitiveValue::CSS_STRING) {
            if (fill || shape || (valueListSize != 1 && !inShorthand()))
                return false;
            addProperty(CSSPropertyWebkitTextEmphasisStyle, createPrimitiveStringValue(value));
            m_valueList->next();
            return true;
        }

        if (value->id == CSSValueNone) {
            if (fill || shape || (valueListSize != 1 && !inShorthand()))
                return false;
            addProperty(CSSPropertyWebkitTextEmphasisStyle, cssValuePool().createIdentifierValue(CSSValueNone));
            m_valueList->next();
            return true;
        }

        if (value->id == CSSValueOpen || value->id == CSSValueFilled) {
            if (fill)
                return false;
            fill = cssValuePool().createIdentifierValue(value->id);
        } else if (value->id == CSSValueDot || value->id == CSSValueCircle || value->id == CSSValueDoubleCircle || value->id == CSSValueTriangle || value->id == CSSValueSesame) {
            if (shape)
                return false;
            shape = cssValuePool().createIdentifierValue(value->id);
        } else if (!inShorthand())
            return false;
        else
            break;
    }

    if (fill && shape) {
        RefPtr<CSSValueList> parsedValues = CSSValueList::createSpaceSeparated();
        parsedValues->append(fill.release());
        parsedValues->append(shape.release());
        addProperty(CSSPropertyWebkitTextEmphasisStyle, parsedValues.release());
        return true;
    }
    if (fill) {
        addProperty(CSSPropertyWebkitTextEmphasisStyle, fill.release());
        return true;
    }
    if (shape) {
        addProperty(CSSPropertyWebkitTextEmphasisStyle, shape.release());
        return true;
    }

    return false;
}

PassRefPtr<CSSValue> CSSPropertyParser::parseTextIndent()
{
    RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();

    bool hasLengthOrPercentage = false;
    bool hasEachLine = false;
    bool hasHanging = false;

    for (CSSParserValue* value = m_valueList->current(); value; value = m_valueList->next()) {
        // <length> | <percentage> | inherit when RuntimeEnabledFeatures::css3TextEnabled() returns false
        if (!hasLengthOrPercentage && validUnit(value, FLength | FPercent)) {
            list->append(createPrimitiveNumericValue(value));
            hasLengthOrPercentage = true;
            continue;
        }

        // [ <length> | <percentage> ] && hanging? && each-line? | inherit
        // when RuntimeEnabledFeatures::css3TextEnabled() returns true
        if (RuntimeEnabledFeatures::css3TextEnabled()) {
            if (!hasEachLine && value->id == CSSValueEachLine) {
                list->append(cssValuePool().createIdentifierValue(CSSValueEachLine));
                hasEachLine = true;
                continue;
            }
            if (!hasHanging && value->id == CSSValueHanging) {
                list->append(cssValuePool().createIdentifierValue(CSSValueHanging));
                hasHanging = true;
                continue;
            }
        }
        return nullptr;
    }

    if (!hasLengthOrPercentage)
        return nullptr;

    return list.release();
}

bool CSSPropertyParser::parseLineBoxContain()
{
    LineBoxContain lineBoxContain = LineBoxContainNone;

    for (CSSParserValue* value = m_valueList->current(); value; value = m_valueList->next()) {
        LineBoxContainFlags flag;
        if (value->id == CSSValueBlock) {
            flag = LineBoxContainBlock;
        } else if (value->id == CSSValueInline) {
            flag = LineBoxContainInline;
        } else if (value->id == CSSValueFont) {
            flag = LineBoxContainFont;
        } else if (value->id == CSSValueGlyphs) {
            flag = LineBoxContainGlyphs;
        } else if (value->id == CSSValueReplaced) {
            flag = LineBoxContainReplaced;
        } else if (value->id == CSSValueInlineBox) {
            flag = LineBoxContainInlineBox;
        } else {
            return false;
        }
        if (lineBoxContain & flag)
            return false;
        lineBoxContain |= flag;
    }

    if (!lineBoxContain)
        return false;

    addProperty(CSSPropertyWebkitLineBoxContain, CSSLineBoxContainValue::create(lineBoxContain));
    return true;
}

bool CSSPropertyParser::parseFontFeatureTag(CSSValueList* settings)
{
    // Feature tag name consists of 4-letter characters.
    static const unsigned tagNameLength = 4;

    CSSParserValue* value = m_valueList->current();
    // Feature tag name comes first
    if (value->unit != CSSPrimitiveValue::CSS_STRING)
        return false;
    if (value->string.length() != tagNameLength)
        return false;
    for (unsigned i = 0; i < tagNameLength; ++i) {
        // Limits the range of characters to 0x20-0x7E, following the tag name rules defiend in the OpenType specification.
        UChar character = value->string[i];
        if (character < 0x20 || character > 0x7E)
            return false;
    }

    AtomicString tag = value->string;
    int tagValue = 1;
    // Feature tag values could follow: <integer> | on | off
    value = m_valueList->next();
    if (value) {
        if (value->unit == CSSPrimitiveValue::CSS_NUMBER && value->isInt && value->fValue >= 0) {
            tagValue = clampToInteger(value->fValue);
            if (tagValue < 0)
                return false;
            m_valueList->next();
        } else if (value->id == CSSValueOn || value->id == CSSValueOff) {
            tagValue = value->id == CSSValueOn;
            m_valueList->next();
        }
    }
    settings->append(CSSFontFeatureValue::create(tag, tagValue));
    return true;
}

bool CSSPropertyParser::parseFontFeatureSettings()
{
    if (m_valueList->size() == 1 && m_valueList->current()->id == CSSValueNormal) {
        RefPtr<CSSPrimitiveValue> normalValue = cssValuePool().createIdentifierValue(CSSValueNormal);
        m_valueList->next();
        addProperty(CSSPropertyWebkitFontFeatureSettings, normalValue.release());
        return true;
    }

    RefPtr<CSSValueList> settings = CSSValueList::createCommaSeparated();
    while (true) {
        if (!m_valueList->current() || !parseFontFeatureTag(settings.get()))
            return false;
        if (!m_valueList->current())
            break;
        if (!consumeComma(m_valueList))
            return false;
    }
    addProperty(CSSPropertyWebkitFontFeatureSettings, settings.release());
    return true;
}

bool CSSPropertyParser::parseFontVariantLigatures()
{
    RefPtr<CSSValueList> ligatureValues = CSSValueList::createSpaceSeparated();
    bool sawCommonLigaturesValue = false;
    bool sawDiscretionaryLigaturesValue = false;
    bool sawHistoricalLigaturesValue = false;
    bool sawContextualLigaturesValue = false;

    for (CSSParserValue* value = m_valueList->current(); value; value = m_valueList->next()) {
        if (value->unit != CSSPrimitiveValue::CSS_IDENT)
            return false;

        switch (value->id) {
        case CSSValueNoCommonLigatures:
        case CSSValueCommonLigatures:
            if (sawCommonLigaturesValue)
                return false;
            sawCommonLigaturesValue = true;
            ligatureValues->append(cssValuePool().createIdentifierValue(value->id));
            break;
        case CSSValueNoDiscretionaryLigatures:
        case CSSValueDiscretionaryLigatures:
            if (sawDiscretionaryLigaturesValue)
                return false;
            sawDiscretionaryLigaturesValue = true;
            ligatureValues->append(cssValuePool().createIdentifierValue(value->id));
            break;
        case CSSValueNoHistoricalLigatures:
        case CSSValueHistoricalLigatures:
            if (sawHistoricalLigaturesValue)
                return false;
            sawHistoricalLigaturesValue = true;
            ligatureValues->append(cssValuePool().createIdentifierValue(value->id));
            break;
        case CSSValueNoContextual:
        case CSSValueContextual:
            if (sawContextualLigaturesValue)
                return false;
            sawContextualLigaturesValue = true;
            ligatureValues->append(cssValuePool().createIdentifierValue(value->id));
            break;
        default:
            return false;
        }
    }

    if (!ligatureValues->length())
        return false;

    addProperty(CSSPropertyFontVariantLigatures, ligatureValues.release());
    return true;
}

bool CSSPropertyParser::parseCalculation(CSSParserValue* value, ValueRange range)
{
    ASSERT(isCalculation(value));

    CSSParserValueList* args = value->function->args.get();
    if (!args || !args->size())
        return false;

    ASSERT(!m_parsedCalculation);
    m_parsedCalculation = CSSCalcValue::create(value->function->name, args, range);

    if (!m_parsedCalculation)
        return false;

    return true;
}

bool CSSPropertyParser::parseViewportProperty(CSSPropertyID propId)
{
    ASSERT(RuntimeEnabledFeatures::cssViewportEnabled() || isUASheetBehavior(m_context.mode()));

    CSSParserValue* value = m_valueList->current();
    if (!value)
        return false;

    CSSValueID id = value->id;
    bool validPrimitive = false;

    switch (propId) {
    case CSSPropertyMinWidth: // auto | <length> | <percentage>
    case CSSPropertyMaxWidth:
    case CSSPropertyMinHeight:
    case CSSPropertyMaxHeight:
        if (id == CSSValueAuto)
            validPrimitive = true;
        else
            validPrimitive = (!id && validUnit(value, FLength | FPercent | FNonNeg));
        break;
    case CSSPropertyWidth: // shorthand
        return parseViewportShorthand(propId, CSSPropertyMinWidth, CSSPropertyMaxWidth);
    case CSSPropertyHeight:
        return parseViewportShorthand(propId, CSSPropertyMinHeight, CSSPropertyMaxHeight);
    case CSSPropertyOrientation: // auto | portrait | landscape
        if (id == CSSValueAuto || id == CSSValuePortrait || id == CSSValueLandscape)
            validPrimitive = true;
    default:
        break;
    }

    RefPtr<CSSValue> parsedValue = nullptr;
    if (validPrimitive) {
        parsedValue = parseValidPrimitive(id, value);
        m_valueList->next();
    }

    if (parsedValue) {
        if (!m_valueList->current() || inShorthand()) {
            addProperty(propId, parsedValue.release());
            return true;
        }
    }

    return false;
}

bool CSSPropertyParser::parseViewportShorthand(CSSPropertyID propId, CSSPropertyID first, CSSPropertyID second)
{
    ASSERT(RuntimeEnabledFeatures::cssViewportEnabled() || isUASheetBehavior(m_context.mode()));
    unsigned numValues = m_valueList->size();

    if (numValues > 2)
        return false;

    ShorthandScope scope(this, propId);

    if (!parseViewportProperty(first))
        return false;

    // If just one value is supplied, the second value
    // is implicitly initialized with the first value.
    if (numValues == 1)
        m_valueList->previous();

    return parseViewportProperty(second);
}

template <typename CharacterType>
static CSSPropertyID cssPropertyID(const CharacterType* propertyName, unsigned length)
{
    char buffer[maxCSSPropertyNameLength + 1]; // 1 for null character

    for (unsigned i = 0; i != length; ++i) {
        CharacterType c = propertyName[i];
        if (c == 0 || c >= 0x7F)
            return CSSPropertyInvalid; // illegal character
        buffer[i] = toASCIILower(c);
    }
    buffer[length] = '\0';

    const char* name = buffer;
    const Property* hashTableEntry = findProperty(name, length);
    if (!hashTableEntry)
        return CSSPropertyInvalid;
    CSSPropertyID property = static_cast<CSSPropertyID>(hashTableEntry->id);
    if (!CSSPropertyMetadata::isEnabledProperty(property))
        return CSSPropertyInvalid;
    return property;
}

CSSPropertyID cssPropertyID(const String& string)
{
    unsigned length = string.length();

    if (!length)
        return CSSPropertyInvalid;
    if (length > maxCSSPropertyNameLength)
        return CSSPropertyInvalid;

    return string.is8Bit() ? cssPropertyID(string.characters8(), length) : cssPropertyID(string.characters16(), length);
}

CSSPropertyID cssPropertyID(const CSSParserString& string)
{
    unsigned length = string.length();

    if (!length)
        return CSSPropertyInvalid;
    if (length > maxCSSPropertyNameLength)
        return CSSPropertyInvalid;

    return string.is8Bit() ? cssPropertyID(string.characters8(), length) : cssPropertyID(string.characters16(), length);
}

template <typename CharacterType>
static CSSValueID cssValueKeywordID(const CharacterType* valueKeyword, unsigned length)
{
    char buffer[maxCSSValueKeywordLength + 1]; // 1 for null character

    for (unsigned i = 0; i != length; ++i) {
        CharacterType c = valueKeyword[i];
        if (c == 0 || c >= 0x7F)
            return CSSValueInvalid; // illegal character
        buffer[i] = WTF::toASCIILower(c);
    }
    buffer[length] = '\0';

    const Value* hashTableEntry = findValue(buffer, length);
    return hashTableEntry ? static_cast<CSSValueID>(hashTableEntry->id) : CSSValueInvalid;
}

CSSValueID cssValueKeywordID(const CSSParserString& string)
{
    unsigned length = string.length();
    if (!length)
        return CSSValueInvalid;
    if (length > maxCSSValueKeywordLength)
        return CSSValueInvalid;

    return string.is8Bit() ? cssValueKeywordID(string.characters8(), length) : cssValueKeywordID(string.characters16(), length);
}

bool isValidNthToken(const CSSParserString& token)
{
    // The tokenizer checks for the construct of an+b.
    // However, since the {ident} rule precedes the {nth} rule, some of those
    // tokens are identified as string literal. Furthermore we need to accept
    // "odd" and "even" which does not match to an+b.
    return equalIgnoringCase(token, "odd") || equalIgnoringCase(token, "even")
        || equalIgnoringCase(token, "n") || equalIgnoringCase(token, "-n");
}

bool CSSPropertyParser::isSystemColor(int id)
{
    // FIXME(sky): remove
    return false;
}

} // namespace blink
