/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "sky/engine/config.h"
#include "sky/engine/core/css/resolver/StyleBuilderConverter.h"

#include "sky/engine/core/css/CSSFontFeatureValue.h"
#include "sky/engine/core/css/CSSFunctionValue.h"
#include "sky/engine/core/css/CSSPrimitiveValueMappings.h"
#include "sky/engine/core/css/CSSShadowValue.h"
#include "sky/engine/core/css/Pair.h"
#include "sky/engine/core/css/Rect.h"

namespace blink {

Color StyleBuilderConverter::convertColor(StyleResolverState& state, CSSValue* value)
{
    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    return state.document().textLinkColors().colorFromPrimitiveValue(primitiveValue, state.style()->color());
}

AtomicString StyleBuilderConverter::convertFragmentIdentifier(StyleResolverState& state, CSSValue* value)
{
    return nullAtom;
}

LengthBox StyleBuilderConverter::convertClip(StyleResolverState& state, CSSValue* value)
{
    Rect* rect = toCSSPrimitiveValue(value)->getRectValue();

    return LengthBox(convertLengthOrAuto(state, rect->top()),
        convertLengthOrAuto(state, rect->right()),
        convertLengthOrAuto(state, rect->bottom()),
        convertLengthOrAuto(state, rect->left()));
}

PassRefPtr<FontFeatureSettings> StyleBuilderConverter::convertFontFeatureSettings(StyleResolverState& state, CSSValue* value)
{
    if (value->isPrimitiveValue() && toCSSPrimitiveValue(value)->getValueID() == CSSValueNormal)
        return FontBuilder::initialFeatureSettings();

    CSSValueList* list = toCSSValueList(value);
    RefPtr<FontFeatureSettings> settings = FontFeatureSettings::create();
    int len = list->length();
    for (int i = 0; i < len; ++i) {
        CSSFontFeatureValue* feature = toCSSFontFeatureValue(list->item(i));
        settings->append(FontFeature(feature->tag(), feature->value()));
    }
    return settings;
}

FontWeight StyleBuilderConverter::convertFontWeight(StyleResolverState& state, CSSValue* value)
{
    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    switch (primitiveValue->getValueID()) {
    case CSSValueBolder:
        return FontDescription::bolderWeight(state.parentStyle()->fontDescription().weight());
    case CSSValueLighter:
        return FontDescription::lighterWeight(state.parentStyle()->fontDescription().weight());
    default:
        return *primitiveValue;
    }
}

FontDescription::VariantLigatures StyleBuilderConverter::convertFontVariantLigatures(StyleResolverState&, CSSValue* value)
{
    if (value->isValueList()) {
        FontDescription::VariantLigatures ligatures;
        CSSValueList* valueList = toCSSValueList(value);
        for (size_t i = 0; i < valueList->length(); ++i) {
            CSSValue* item = valueList->item(i);
            CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(item);
            switch (primitiveValue->getValueID()) {
            case CSSValueNoCommonLigatures:
                ligatures.common = FontDescription::DisabledLigaturesState;
                break;
            case CSSValueCommonLigatures:
                ligatures.common = FontDescription::EnabledLigaturesState;
                break;
            case CSSValueNoDiscretionaryLigatures:
                ligatures.discretionary = FontDescription::DisabledLigaturesState;
                break;
            case CSSValueDiscretionaryLigatures:
                ligatures.discretionary = FontDescription::EnabledLigaturesState;
                break;
            case CSSValueNoHistoricalLigatures:
                ligatures.historical = FontDescription::DisabledLigaturesState;
                break;
            case CSSValueHistoricalLigatures:
                ligatures.historical = FontDescription::EnabledLigaturesState;
                break;
            case CSSValueNoContextual:
                ligatures.contextual = FontDescription::DisabledLigaturesState;
                break;
            case CSSValueContextual:
                ligatures.contextual = FontDescription::EnabledLigaturesState;
                break;
            default:
                ASSERT_NOT_REACHED();
                break;
            }
        }
        return ligatures;
    }

    ASSERT_WITH_SECURITY_IMPLICATION(value->isPrimitiveValue());
    ASSERT(toCSSPrimitiveValue(value)->getValueID() == CSSValueNormal);
    return FontDescription::VariantLigatures();
}

Length StyleBuilderConverter::convertLength(StyleResolverState& state, CSSValue* value)
{
    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    Length result = primitiveValue->convertToLength<FixedConversion | PercentConversion>(state.cssToLengthConversionData());
    result.setQuirk(primitiveValue->isQuirkValue());
    return result;
}

Length StyleBuilderConverter::convertLengthOrAuto(StyleResolverState& state, CSSValue* value)
{
    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    Length result = primitiveValue->convertToLength<FixedConversion | PercentConversion | AutoConversion>(state.cssToLengthConversionData());
    result.setQuirk(primitiveValue->isQuirkValue());
    return result;
}

Length StyleBuilderConverter::convertLengthSizing(StyleResolverState& state, CSSValue* value)
{
    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    switch (primitiveValue->getValueID()) {
    case CSSValueInvalid:
        return convertLength(state, value);
    case CSSValueIntrinsic:
        return Length(Intrinsic);
    case CSSValueMinIntrinsic:
        return Length(MinIntrinsic);
    case CSSValueWebkitMinContent:
        return Length(MinContent);
    case CSSValueWebkitMaxContent:
        return Length(MaxContent);
    case CSSValueWebkitFillAvailable:
        return Length(FillAvailable);
    case CSSValueWebkitFitContent:
        return Length(FitContent);
    case CSSValueAuto:
        return Length(Auto);
    default:
        ASSERT_NOT_REACHED();
        return Length();
    }
}

Length StyleBuilderConverter::convertLengthMaxSizing(StyleResolverState& state, CSSValue* value)
{
    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    if (primitiveValue->getValueID() == CSSValueNone)
        return Length(MaxSizeNone);
    return convertLengthSizing(state, value);
}

LengthPoint StyleBuilderConverter::convertLengthPoint(StyleResolverState& state, CSSValue* value)
{
    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    Pair* pair = primitiveValue->getPairValue();
    Length x = pair->first()->convertToLength<FixedConversion | PercentConversion>(state.cssToLengthConversionData());
    Length y = pair->second()->convertToLength<FixedConversion | PercentConversion>(state.cssToLengthConversionData());
    return LengthPoint(x, y);
}

LineBoxContain StyleBuilderConverter::convertLineBoxContain(StyleResolverState&, CSSValue* value)
{
    if (value->isPrimitiveValue()) {
        ASSERT(toCSSPrimitiveValue(value)->getValueID() == CSSValueNone);
        return LineBoxContainNone;
    }

    return toCSSLineBoxContainValue(value)->value();
}

float StyleBuilderConverter::convertNumberOrPercentage(StyleResolverState& state, CSSValue* value)
{
    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    ASSERT(primitiveValue->isNumber() || primitiveValue->isPercentage());
    if (primitiveValue->isNumber())
        return primitiveValue->getFloatValue();
    return primitiveValue->getFloatValue() / 100.0f;
}

PassRefPtr<QuotesData> StyleBuilderConverter::convertQuotes(StyleResolverState&, CSSValue* value)
{
    if (value->isValueList()) {
        CSSValueList* list = toCSSValueList(value);
        RefPtr<QuotesData> quotes = QuotesData::create();
        for (size_t i = 0; i < list->length(); i += 2) {
            CSSValue* first = list->item(i);
            CSSValue* second = list->item(i + 1);
            String startQuote = toCSSPrimitiveValue(first)->getStringValue();
            String endQuote = toCSSPrimitiveValue(second)->getStringValue();
            quotes->addPair(std::make_pair(startQuote, endQuote));
        }
        return quotes.release();
    }
    // FIXME: We should assert we're a primitive value with valueID = CSSValueNone
    return QuotesData::create();
}

LengthSize StyleBuilderConverter::convertRadius(StyleResolverState& state, CSSValue* value)
{
    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    Pair* pair = primitiveValue->getPairValue();
    Length radiusWidth = pair->first()->convertToLength<FixedConversion | PercentConversion>(state.cssToLengthConversionData());
    Length radiusHeight = pair->second()->convertToLength<FixedConversion | PercentConversion>(state.cssToLengthConversionData());
    float width = radiusWidth.value();
    float height = radiusHeight.value();
    ASSERT(width >= 0 && height >= 0);
    if (width <= 0 || height <= 0)
        return LengthSize(Length(0, Fixed), Length(0, Fixed));
    return LengthSize(radiusWidth, radiusHeight);
}

PassRefPtr<ShadowList> StyleBuilderConverter::convertShadow(StyleResolverState& state, CSSValue* value)
{
    if (value->isPrimitiveValue()) {
        ASSERT(toCSSPrimitiveValue(value)->getValueID() == CSSValueNone);
        return PassRefPtr<ShadowList>();
    }

    const CSSValueList* valueList = toCSSValueList(value);
    size_t shadowCount = valueList->length();
    ShadowDataVector shadows;
    for (size_t i = 0; i < shadowCount; ++i) {
        const CSSShadowValue* item = toCSSShadowValue(valueList->item(i));
        float x = item->x->computeLength<float>(state.cssToLengthConversionData());
        float y = item->y->computeLength<float>(state.cssToLengthConversionData());
        float blur = item->blur ? item->blur->computeLength<float>(state.cssToLengthConversionData()) : 0;
        float spread = item->spread ? item->spread->computeLength<float>(state.cssToLengthConversionData()) : 0;
        ShadowStyle shadowStyle = item->style && item->style->getValueID() == CSSValueInset ? Inset : Normal;
        Color color;
        if (item->color)
            color = convertColor(state, item->color.get());
        else
            color = state.style()->color();
        shadows.append(ShadowData(FloatPoint(x, y), blur, spread, shadowStyle, color));
    }
    return ShadowList::adopt(shadows);
}

float StyleBuilderConverter::convertSpacing(StyleResolverState& state, CSSValue* value)
{
    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    if (primitiveValue->getValueID() == CSSValueNormal)
        return 0;
    return primitiveValue->computeLength<float>(state.cssToLengthConversionData());
}

float StyleBuilderConverter::convertTextStrokeWidth(StyleResolverState& state, CSSValue* value)
{
    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    if (primitiveValue->getValueID()) {
        float multiplier = convertLineWidth<float>(state, value);
        return CSSPrimitiveValue::create(multiplier / 48, CSSPrimitiveValue::CSS_EMS)->computeLength<float>(state.cssToLengthConversionData());
    }
    return primitiveValue->computeLength<float>(state.cssToLengthConversionData());
}

} // namespace blink
