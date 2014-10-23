/*
 * CSS Media Query
 *
 * Copyright (C) 2006 Kimmo Kinnunen <kimmo.t.kinnunen@nokia.com>.
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
 * Copyright (C) 2013 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/css/MediaQueryExp.h"

#include "core/css/CSSAspectRatioValue.h"
#include "core/css/CSSPrimitiveValue.h"
#include "core/css/parser/CSSParserValues.h"
#include "core/html/parser/HTMLParserIdioms.h"
#include "platform/Decimal.h"
#include "platform/RuntimeEnabledFeatures.h"
#include "wtf/text/StringBuffer.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

using namespace MediaFeatureNames;

static inline bool featureWithCSSValueID(const String& mediaFeature, const CSSParserValue* value)
{
    if (!value->id)
        return false;

    return mediaFeature == orientationMediaFeature
        || mediaFeature == pointerMediaFeature
        || mediaFeature == anyPointerMediaFeature
        || (mediaFeature == hoverMediaFeature && RuntimeEnabledFeatures::hoverMediaQueryKeywordsEnabled())
        || mediaFeature == anyHoverMediaFeature
        || mediaFeature == scanMediaFeature;
}

static inline bool featureWithValidIdent(const String& mediaFeature, CSSValueID ident)
{
    if (mediaFeature == orientationMediaFeature)
        return ident == CSSValuePortrait || ident == CSSValueLandscape;

    if (mediaFeature == pointerMediaFeature || mediaFeature == anyPointerMediaFeature)
        return ident == CSSValueNone || ident == CSSValueCoarse || ident == CSSValueFine;

    if ((mediaFeature == hoverMediaFeature && RuntimeEnabledFeatures::hoverMediaQueryKeywordsEnabled())
        || mediaFeature == anyHoverMediaFeature)
        return ident == CSSValueNone || ident == CSSValueOnDemand || ident == CSSValueHover;

    if (mediaFeature == scanMediaFeature)
        return ident == CSSValueInterlace || ident == CSSValueProgressive;

    ASSERT_NOT_REACHED();
    return false;
}

static bool positiveLengthUnit(const int unit)
{
    switch (unit) {
    case CSSPrimitiveValue::CSS_EMS:
    case CSSPrimitiveValue::CSS_EXS:
    case CSSPrimitiveValue::CSS_PX:
    case CSSPrimitiveValue::CSS_CM:
    case CSSPrimitiveValue::CSS_MM:
    case CSSPrimitiveValue::CSS_IN:
    case CSSPrimitiveValue::CSS_PT:
    case CSSPrimitiveValue::CSS_PC:
    case CSSPrimitiveValue::CSS_REMS:
    case CSSPrimitiveValue::CSS_CHS:
        return true;
    }
    return false;
}

static inline bool featureWithValidPositiveLength(const String& mediaFeature, const CSSParserValue* value)
{
    if (!(positiveLengthUnit(value->unit) || (value->unit == CSSPrimitiveValue::CSS_NUMBER && value->fValue == 0)) || value->fValue < 0)
        return false;


    return mediaFeature == heightMediaFeature
        || mediaFeature == maxHeightMediaFeature
        || mediaFeature == minHeightMediaFeature
        || mediaFeature == widthMediaFeature
        || mediaFeature == maxWidthMediaFeature
        || mediaFeature == minWidthMediaFeature
        || mediaFeature == deviceHeightMediaFeature
        || mediaFeature == maxDeviceHeightMediaFeature
        || mediaFeature == minDeviceHeightMediaFeature
        || mediaFeature == deviceWidthMediaFeature
        || mediaFeature == minDeviceWidthMediaFeature
        || mediaFeature == maxDeviceWidthMediaFeature;
}

static inline bool featureWithValidDensity(const String& mediaFeature, const CSSParserValue* value)
{
    if ((value->unit != CSSPrimitiveValue::CSS_DPPX && value->unit != CSSPrimitiveValue::CSS_DPI && value->unit != CSSPrimitiveValue::CSS_DPCM) || value->fValue <= 0)
        return false;

    return mediaFeature == resolutionMediaFeature
        || mediaFeature == minResolutionMediaFeature
        || mediaFeature == maxResolutionMediaFeature;
}

static inline bool featureWithPositiveInteger(const String& mediaFeature, const CSSParserValue* value)
{
    if (!value->isInt || value->fValue < 0)
        return false;

    return mediaFeature == colorMediaFeature
        || mediaFeature == maxColorMediaFeature
        || mediaFeature == minColorMediaFeature
        || mediaFeature == colorIndexMediaFeature
        || mediaFeature == maxColorIndexMediaFeature
        || mediaFeature == minColorIndexMediaFeature
        || mediaFeature == monochromeMediaFeature
        || mediaFeature == maxMonochromeMediaFeature
        || mediaFeature == minMonochromeMediaFeature;
}

static inline bool featureWithPositiveNumber(const String& mediaFeature, const CSSParserValue* value)
{
    if (value->unit != CSSPrimitiveValue::CSS_NUMBER || value->fValue < 0)
        return false;

    return mediaFeature == transform3dMediaFeature
        || mediaFeature == devicePixelRatioMediaFeature
        || mediaFeature == maxDevicePixelRatioMediaFeature
        || mediaFeature == minDevicePixelRatioMediaFeature;
}

static inline bool featureWithZeroOrOne(const String& mediaFeature, const CSSParserValue* value)
{
    if (!value->isInt || !(value->fValue == 1 || !value->fValue))
        return false;

    return mediaFeature == gridMediaFeature
        || (mediaFeature == hoverMediaFeature && !RuntimeEnabledFeatures::hoverMediaQueryKeywordsEnabled());
}

static inline bool featureWithAspectRatio(const String& mediaFeature)
{
    return mediaFeature == aspectRatioMediaFeature
        || mediaFeature == deviceAspectRatioMediaFeature
        || mediaFeature == minAspectRatioMediaFeature
        || mediaFeature == maxAspectRatioMediaFeature
        || mediaFeature == minDeviceAspectRatioMediaFeature
        || mediaFeature == maxDeviceAspectRatioMediaFeature;
}

static inline bool featureWithoutValue(const String& mediaFeature)
{
    // Media features that are prefixed by min/max cannot be used without a value.
    return mediaFeature == monochromeMediaFeature
        || mediaFeature == colorMediaFeature
        || mediaFeature == colorIndexMediaFeature
        || mediaFeature == gridMediaFeature
        || mediaFeature == heightMediaFeature
        || mediaFeature == widthMediaFeature
        || mediaFeature == deviceHeightMediaFeature
        || mediaFeature == deviceWidthMediaFeature
        || mediaFeature == orientationMediaFeature
        || mediaFeature == aspectRatioMediaFeature
        || mediaFeature == deviceAspectRatioMediaFeature
        || mediaFeature == hoverMediaFeature
        || mediaFeature == anyHoverMediaFeature
        || mediaFeature == transform3dMediaFeature
        || mediaFeature == pointerMediaFeature
        || mediaFeature == anyPointerMediaFeature
        || mediaFeature == devicePixelRatioMediaFeature
        || mediaFeature == resolutionMediaFeature
        || mediaFeature == scanMediaFeature;
}

bool MediaQueryExp::isViewportDependent() const
{
    return m_mediaFeature == widthMediaFeature
        || m_mediaFeature == heightMediaFeature
        || m_mediaFeature == minWidthMediaFeature
        || m_mediaFeature == minHeightMediaFeature
        || m_mediaFeature == maxWidthMediaFeature
        || m_mediaFeature == maxHeightMediaFeature
        || m_mediaFeature == orientationMediaFeature
        || m_mediaFeature == aspectRatioMediaFeature
        || m_mediaFeature == minAspectRatioMediaFeature
        || m_mediaFeature == devicePixelRatioMediaFeature
        || m_mediaFeature == resolutionMediaFeature
        || m_mediaFeature == maxAspectRatioMediaFeature;
}

MediaQueryExp::MediaQueryExp(const MediaQueryExp& other)
    : m_mediaFeature(other.mediaFeature())
    , m_expValue(other.expValue())
{
}

MediaQueryExp::MediaQueryExp(const String& mediaFeature, const MediaQueryExpValue& expValue)
    : m_mediaFeature(mediaFeature)
    , m_expValue(expValue)
{
}

PassOwnPtrWillBeRawPtr<MediaQueryExp> MediaQueryExp::createIfValid(const String& mediaFeature, CSSParserValueList* valueList)
{
    ASSERT(!mediaFeature.isNull());

    MediaQueryExpValue expValue;
    bool isValid = false;
    String lowerMediaFeature = attemptStaticStringCreation(mediaFeature.lower());

    // Create value for media query expression that must have 1 or more values.
    if (valueList && valueList->size() > 0) {
        if (valueList->size() == 1) {
            CSSParserValue* value = valueList->current();
            ASSERT(value);

            if (featureWithCSSValueID(lowerMediaFeature, value) && featureWithValidIdent(lowerMediaFeature, value->id)) {
                // Media features that use CSSValueIDs.
                expValue.id = value->id;
                expValue.unit = CSSPrimitiveValue::CSS_VALUE_ID;
                expValue.isID = true;
            } else if (featureWithValidDensity(lowerMediaFeature, value)
                || featureWithValidPositiveLength(lowerMediaFeature, value)) {
                // Media features that must have non-negative <density>, ie. dppx, dpi or dpcm,
                // or Media features that must have non-negative <length> or number value.
                expValue.value = value->fValue;
                expValue.unit = (CSSPrimitiveValue::UnitType)value->unit;
                expValue.isValue = true;
            } else if (featureWithPositiveInteger(lowerMediaFeature, value)
                || featureWithPositiveNumber(lowerMediaFeature, value)
                || featureWithZeroOrOne(lowerMediaFeature, value)) {
                // Media features that must have non-negative integer value,
                // or media features that must have non-negative number value,
                // or media features that must have (0|1) value.
                expValue.value = value->fValue;
                expValue.unit = CSSPrimitiveValue::CSS_NUMBER;
                expValue.isValue = true;
            }

            isValid = (expValue.isID || expValue.isValue);

        } else if (valueList->size() == 3 && featureWithAspectRatio(lowerMediaFeature)) {
            // Create list of values.
            // Currently accepts only <integer>/<integer>.
            // Applicable to device-aspect-ratio and aspec-ratio.
            isValid = true;
            float numeratorValue = 0;
            float denominatorValue = 0;
            // The aspect-ratio must be <integer> (whitespace)? / (whitespace)? <integer>.
            for (unsigned i = 0; i < 3; ++i, valueList->next()) {
                const CSSParserValue* value = valueList->current();
                if (i != 1 && value->unit == CSSPrimitiveValue::CSS_NUMBER && value->fValue > 0 && value->isInt) {
                    if (!i)
                        numeratorValue = value->fValue;
                    else
                        denominatorValue = value->fValue;
                } else if (i == 1 && value->unit == CSSParserValue::Operator && value->iValue == '/') {
                    continue;
                } else {
                    isValid = false;
                    break;
                }
            }

            if (isValid) {
                expValue.numerator = (unsigned)numeratorValue;
                expValue.denominator = (unsigned)denominatorValue;
                expValue.isRatio = true;
            }
        }
    } else if (featureWithoutValue(lowerMediaFeature)) {
        isValid = true;
    }

    if (!isValid)
        return nullptr;

    return adoptPtrWillBeNoop(new MediaQueryExp(lowerMediaFeature, expValue));
}

MediaQueryExp::~MediaQueryExp()
{
}

bool MediaQueryExp::operator==(const MediaQueryExp& other) const
{
    return (other.m_mediaFeature == m_mediaFeature)
        && ((!other.m_expValue.isValid() && !m_expValue.isValid())
            || (other.m_expValue.isValid() && m_expValue.isValid() && other.m_expValue.equals(m_expValue)));
}

String MediaQueryExp::serialize() const
{
    StringBuilder result;
    result.append('(');
    result.append(m_mediaFeature.lower());
    if (m_expValue.isValid()) {
        result.appendLiteral(": ");
        result.append(m_expValue.cssText());
    }
    result.append(')');

    return result.toString();
}

static inline String printNumber(double number)
{
    return Decimal::fromDouble(number).toString();
}

String MediaQueryExpValue::cssText() const
{
    StringBuilder output;
    if (isValue) {
        output.append(printNumber(value));
        output.append(CSSPrimitiveValue::unitTypeToString(unit));
    } else if (isRatio) {
        output.append(printNumber(numerator));
        output.append('/');
        output.append(printNumber(denominator));
    } else if (isID) {
        output.append(getValueName(id));
    }

    return output.toString();
}

} // namespace
