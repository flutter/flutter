/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 2004-2005 Allan Sandfeld Jensen (kde@carewolf.com)
 * Copyright (C) 2006, 2007 Nicholas Shanks (webkit@nickshanks.com)
 * Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2007 Alexey Proskuryakov <ap@webkit.org>
 * Copyright (C) 2007, 2008 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (c) 2011, Code Aurora Forum. All rights reserved.
 * Copyright (C) Research In Motion Limited 2011. All rights reserved.
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
#include "core/css/resolver/CSSToStyleMap.h"

#include "core/CSSValueKeywords.h"
#include "core/animation/css/CSSAnimationData.h"
#include "core/css/CSSBorderImageSliceValue.h"
#include "core/css/CSSPrimitiveValue.h"
#include "core/css/CSSPrimitiveValueMappings.h"
#include "core/css/CSSTimingFunctionValue.h"
#include "core/css/Pair.h"
#include "core/css/Rect.h"
#include "core/css/resolver/StyleResolverState.h"
#include "core/rendering/style/BorderImageLengthBox.h"
#include "core/rendering/style/FillLayer.h"

namespace blink {

const CSSToLengthConversionData& CSSToStyleMap::cssToLengthConversionData() const
{
    return m_state.cssToLengthConversionData();
}

PassRefPtr<StyleImage> CSSToStyleMap::styleImage(CSSPropertyID propertyId, CSSValue* value)
{
    return m_elementStyleResources.styleImage(m_state.document(), m_state.document().textLinkColors(), m_state.style()->color(), propertyId, value);
}

void CSSToStyleMap::mapFillAttachment(FillLayer* layer, CSSValue* value) const
{
    if (value->isInitialValue()) {
        layer->setAttachment(FillLayer::initialFillAttachment(layer->type()));
        return;
    }

    if (!value->isPrimitiveValue())
        return;

    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    switch (primitiveValue->getValueID()) {
    case CSSValueFixed:
        layer->setAttachment(FixedBackgroundAttachment);
        break;
    case CSSValueScroll:
        layer->setAttachment(ScrollBackgroundAttachment);
        break;
    case CSSValueLocal:
        layer->setAttachment(LocalBackgroundAttachment);
        break;
    default:
        return;
    }
}

void CSSToStyleMap::mapFillClip(FillLayer* layer, CSSValue* value) const
{
    if (value->isInitialValue()) {
        layer->setClip(FillLayer::initialFillClip(layer->type()));
        return;
    }

    if (!value->isPrimitiveValue())
        return;

    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    layer->setClip(*primitiveValue);
}

void CSSToStyleMap::mapFillComposite(FillLayer* layer, CSSValue* value) const
{
    if (value->isInitialValue()) {
        layer->setComposite(FillLayer::initialFillComposite(layer->type()));
        return;
    }

    if (!value->isPrimitiveValue())
        return;

    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    layer->setComposite(*primitiveValue);
}

void CSSToStyleMap::mapFillBlendMode(FillLayer* layer, CSSValue* value) const
{
    if (value->isInitialValue()) {
        layer->setBlendMode(FillLayer::initialFillBlendMode(layer->type()));
        return;
    }

    if (!value->isPrimitiveValue())
        return;

    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    layer->setBlendMode(*primitiveValue);
}

void CSSToStyleMap::mapFillOrigin(FillLayer* layer, CSSValue* value) const
{
    if (value->isInitialValue()) {
        layer->setOrigin(FillLayer::initialFillOrigin(layer->type()));
        return;
    }

    if (!value->isPrimitiveValue())
        return;

    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    layer->setOrigin(*primitiveValue);
}


void CSSToStyleMap::mapFillImage(FillLayer* layer, CSSValue* value)
{
    if (value->isInitialValue()) {
        layer->setImage(FillLayer::initialFillImage(layer->type()));
        return;
    }

    CSSPropertyID property = layer->type() == BackgroundFillLayer ? CSSPropertyBackgroundImage : CSSPropertyWebkitMaskImage;
    layer->setImage(styleImage(property, value));
}

void CSSToStyleMap::mapFillRepeatX(FillLayer* layer, CSSValue* value) const
{
    if (value->isInitialValue()) {
        layer->setRepeatX(FillLayer::initialFillRepeatX(layer->type()));
        return;
    }

    if (!value->isPrimitiveValue())
        return;

    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    layer->setRepeatX(*primitiveValue);
}

void CSSToStyleMap::mapFillRepeatY(FillLayer* layer, CSSValue* value) const
{
    if (value->isInitialValue()) {
        layer->setRepeatY(FillLayer::initialFillRepeatY(layer->type()));
        return;
    }

    if (!value->isPrimitiveValue())
        return;

    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    layer->setRepeatY(*primitiveValue);
}

void CSSToStyleMap::mapFillSize(FillLayer* layer, CSSValue* value) const
{
    if (value->isInitialValue()) {
        layer->setSizeType(FillLayer::initialFillSizeType(layer->type()));
        layer->setSizeLength(FillLayer::initialFillSizeLength(layer->type()));
        return;
    }

    if (!value->isPrimitiveValue())
        return;

    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    if (primitiveValue->getValueID() == CSSValueContain)
        layer->setSizeType(Contain);
    else if (primitiveValue->getValueID() == CSSValueCover)
        layer->setSizeType(Cover);
    else
        layer->setSizeType(SizeLength);

    LengthSize b = FillLayer::initialFillSizeLength(layer->type());

    if (primitiveValue->getValueID() == CSSValueContain || primitiveValue->getValueID() == CSSValueCover) {
        layer->setSizeLength(b);
        return;
    }

    Length firstLength;
    Length secondLength;

    if (Pair* pair = primitiveValue->getPairValue()) {
        firstLength = pair->first()->convertToLength<AnyConversion>(cssToLengthConversionData());
        secondLength = pair->second()->convertToLength<AnyConversion>(cssToLengthConversionData());
    } else {
        firstLength = primitiveValue->convertToLength<AnyConversion>(cssToLengthConversionData());
        secondLength = Length();
    }

    b.setWidth(firstLength);
    b.setHeight(secondLength);
    layer->setSizeLength(b);
}

void CSSToStyleMap::mapFillXPosition(FillLayer* layer, CSSValue* value) const
{
    if (value->isInitialValue()) {
        layer->setXPosition(FillLayer::initialFillXPosition(layer->type()));
        return;
    }

    if (!value->isPrimitiveValue())
        return;

    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    Pair* pair = primitiveValue->getPairValue();
    if (pair)
        primitiveValue = pair->second();

    Length length = primitiveValue->convertToLength<FixedConversion | PercentConversion>(cssToLengthConversionData());

    layer->setXPosition(length);
    if (pair)
        layer->setBackgroundXOrigin(*(pair->first()));
}

void CSSToStyleMap::mapFillYPosition(FillLayer* layer, CSSValue* value) const
{
    if (value->isInitialValue()) {
        layer->setYPosition(FillLayer::initialFillYPosition(layer->type()));
        return;
    }

    if (!value->isPrimitiveValue())
        return;

    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    Pair* pair = primitiveValue->getPairValue();
    if (pair)
        primitiveValue = pair->second();

    Length length = primitiveValue->convertToLength<FixedConversion | PercentConversion>(cssToLengthConversionData());

    layer->setYPosition(length);
    if (pair)
        layer->setBackgroundYOrigin(*(pair->first()));
}

void CSSToStyleMap::mapFillMaskSourceType(FillLayer* layer, CSSValue* value) const
{
    EMaskSourceType type = FillLayer::initialFillMaskSourceType(layer->type());
    if (value->isInitialValue()) {
        layer->setMaskSourceType(type);
        return;
    }

    if (!value->isPrimitiveValue())
        return;

    switch (toCSSPrimitiveValue(value)->getValueID()) {
    case CSSValueAlpha:
        type = MaskAlpha;
        break;
    case CSSValueLuminance:
        type = MaskLuminance;
        break;
    case CSSValueAuto:
        break;
    default:
        ASSERT_NOT_REACHED();
    }

    layer->setMaskSourceType(type);
}

double CSSToStyleMap::mapAnimationDelay(CSSValue* value)
{
    if (value->isInitialValue())
        return CSSTimingData::initialDelay();
    return toCSSPrimitiveValue(value)->computeSeconds();
}

Timing::PlaybackDirection CSSToStyleMap::mapAnimationDirection(CSSValue* value)
{
    if (value->isInitialValue())
        return CSSAnimationData::initialDirection();

    switch (toCSSPrimitiveValue(value)->getValueID()) {
    case CSSValueNormal:
        return Timing::PlaybackDirectionNormal;
    case CSSValueAlternate:
        return Timing::PlaybackDirectionAlternate;
    case CSSValueReverse:
        return Timing::PlaybackDirectionReverse;
    case CSSValueAlternateReverse:
        return Timing::PlaybackDirectionAlternateReverse;
    default:
        ASSERT_NOT_REACHED();
        return CSSAnimationData::initialDirection();
    }
}

double CSSToStyleMap::mapAnimationDuration(CSSValue* value)
{
    if (value->isInitialValue())
        return CSSTimingData::initialDuration();
    return toCSSPrimitiveValue(value)->computeSeconds();
}

Timing::FillMode CSSToStyleMap::mapAnimationFillMode(CSSValue* value)
{
    if (value->isInitialValue())
        return CSSAnimationData::initialFillMode();

    switch (toCSSPrimitiveValue(value)->getValueID()) {
    case CSSValueNone:
        return Timing::FillModeNone;
    case CSSValueForwards:
        return Timing::FillModeForwards;
    case CSSValueBackwards:
        return Timing::FillModeBackwards;
    case CSSValueBoth:
        return Timing::FillModeBoth;
    default:
        ASSERT_NOT_REACHED();
        return CSSAnimationData::initialFillMode();
    }
}

double CSSToStyleMap::mapAnimationIterationCount(CSSValue* value)
{
    if (value->isInitialValue())
        return CSSAnimationData::initialIterationCount();
    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    if (primitiveValue->getValueID() == CSSValueInfinite)
        return std::numeric_limits<double>::infinity();
    return primitiveValue->getFloatValue();
}

AtomicString CSSToStyleMap::mapAnimationName(CSSValue* value)
{
    if (value->isInitialValue())
        return CSSAnimationData::initialName();
    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    if (primitiveValue->getValueID() == CSSValueNone)
        return CSSAnimationData::initialName();
    return AtomicString(primitiveValue->getStringValue());
}

EAnimPlayState CSSToStyleMap::mapAnimationPlayState(CSSValue* value)
{
    if (value->isInitialValue())
        return CSSAnimationData::initialPlayState();
    if (toCSSPrimitiveValue(value)->getValueID() == CSSValuePaused)
        return AnimPlayStatePaused;
    ASSERT(toCSSPrimitiveValue(value)->getValueID() == CSSValueRunning);
    return AnimPlayStatePlaying;
}

CSSTransitionData::TransitionProperty CSSToStyleMap::mapAnimationProperty(CSSValue* value)
{
    if (value->isInitialValue())
        return CSSTransitionData::initialProperty();
    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    if (primitiveValue->isString())
        return CSSTransitionData::TransitionProperty(primitiveValue->getStringValue());
    if (primitiveValue->getValueID() == CSSValueAll)
        return CSSTransitionData::TransitionProperty(CSSTransitionData::TransitionAll);
    if (primitiveValue->getValueID() == CSSValueNone)
        return CSSTransitionData::TransitionProperty(CSSTransitionData::TransitionNone);
    return CSSTransitionData::TransitionProperty(primitiveValue->getPropertyID());
}

PassRefPtr<TimingFunction> CSSToStyleMap::mapAnimationTimingFunction(CSSValue* value, bool allowStepMiddle)
{
    // FIXME: We should probably only call into this function with a valid
    // single timing function value which isn't initial or inherit. We can
    // currently get into here with initial since the parser expands unset
    // properties in shorthands to initial.

    if (value->isPrimitiveValue()) {
        CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
        switch (primitiveValue->getValueID()) {
        case CSSValueLinear:
            return LinearTimingFunction::shared();
        case CSSValueEase:
            return CubicBezierTimingFunction::preset(CubicBezierTimingFunction::Ease);
        case CSSValueEaseIn:
            return CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseIn);
        case CSSValueEaseOut:
            return CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseOut);
        case CSSValueEaseInOut:
            return CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseInOut);
        case CSSValueStepStart:
            return StepsTimingFunction::preset(StepsTimingFunction::Start);
        case CSSValueStepMiddle:
            if (allowStepMiddle)
                return StepsTimingFunction::preset(StepsTimingFunction::Middle);
            return CSSTimingData::initialTimingFunction();
        case CSSValueStepEnd:
            return StepsTimingFunction::preset(StepsTimingFunction::End);
        default:
            ASSERT_NOT_REACHED();
            return CSSTimingData::initialTimingFunction();
        }
    }

    if (value->isCubicBezierTimingFunctionValue()) {
        CSSCubicBezierTimingFunctionValue* cubicTimingFunction = toCSSCubicBezierTimingFunctionValue(value);
        return CubicBezierTimingFunction::create(cubicTimingFunction->x1(), cubicTimingFunction->y1(), cubicTimingFunction->x2(), cubicTimingFunction->y2());
    }

    if (value->isInitialValue())
        return CSSTimingData::initialTimingFunction();

    CSSStepsTimingFunctionValue* stepsTimingFunction = toCSSStepsTimingFunctionValue(value);
    if (stepsTimingFunction->stepAtPosition() == StepsTimingFunction::StepAtMiddle && !allowStepMiddle)
        return CSSTimingData::initialTimingFunction();
    return StepsTimingFunction::create(stepsTimingFunction->numberOfSteps(), stepsTimingFunction->stepAtPosition());
}

void CSSToStyleMap::mapNinePieceImage(RenderStyle* mutableStyle, CSSPropertyID property, CSSValue* value, NinePieceImage& image)
{
    // If we're not a value list, then we are "none" and don't need to alter the empty image at all.
    if (!value || !value->isValueList())
        return;

    // Retrieve the border image value.
    CSSValueList* borderImage = toCSSValueList(value);

    // Set the image (this kicks off the load).
    CSSPropertyID imageProperty;
    if (property == CSSPropertyWebkitBorderImage)
        imageProperty = CSSPropertyBorderImageSource;
    else if (property == CSSPropertyWebkitMaskBoxImage)
        imageProperty = CSSPropertyWebkitMaskBoxImageSource;
    else
        imageProperty = property;

    for (unsigned i = 0 ; i < borderImage->length() ; ++i) {
        CSSValue* current = borderImage->item(i);

        if (current->isImageValue() || current->isImageGeneratorValue() || current->isImageSetValue())
            image.setImage(styleImage(imageProperty, current));
        else if (current->isBorderImageSliceValue())
            mapNinePieceImageSlice(current, image);
        else if (current->isValueList()) {
            CSSValueList* slashList = toCSSValueList(current);
            size_t length = slashList->length();
            // Map in the image slices.
            if (length && slashList->item(0)->isBorderImageSliceValue())
                mapNinePieceImageSlice(slashList->item(0), image);

            // Map in the border slices.
            if (length > 1)
                image.setBorderSlices(mapNinePieceImageQuad(slashList->item(1)));

            // Map in the outset.
            if (length > 2)
                image.setOutset(mapNinePieceImageQuad(slashList->item(2)));
        } else if (current->isPrimitiveValue()) {
            // Set the appropriate rules for stretch/round/repeat of the slices.
            mapNinePieceImageRepeat(current, image);
        }
    }

    if (property == CSSPropertyWebkitBorderImage) {
        // We have to preserve the legacy behavior of -webkit-border-image and make the border slices
        // also set the border widths. We don't need to worry about percentages, since we don't even support
        // those on real borders yet.
        if (image.borderSlices().top().isLength() && image.borderSlices().top().length().isFixed())
            mutableStyle->setBorderTopWidth(image.borderSlices().top().length().value());
        if (image.borderSlices().right().isLength() && image.borderSlices().right().length().isFixed())
            mutableStyle->setBorderRightWidth(image.borderSlices().right().length().value());
        if (image.borderSlices().bottom().isLength() && image.borderSlices().bottom().length().isFixed())
            mutableStyle->setBorderBottomWidth(image.borderSlices().bottom().length().value());
        if (image.borderSlices().left().isLength() && image.borderSlices().left().length().isFixed())
            mutableStyle->setBorderLeftWidth(image.borderSlices().left().length().value());
    }
}

void CSSToStyleMap::mapNinePieceImageSlice(CSSValue* value, NinePieceImage& image) const
{
    if (!value || !value->isBorderImageSliceValue())
        return;

    // Retrieve the border image value.
    CSSBorderImageSliceValue* borderImageSlice = toCSSBorderImageSliceValue(value);

    // Set up a length box to represent our image slices.
    LengthBox box;
    Quad* slices = borderImageSlice->slices();
    if (slices->top()->isPercentage())
        box.m_top = Length(slices->top()->getDoubleValue(), Percent);
    else
        box.m_top = Length(slices->top()->getIntValue(CSSPrimitiveValue::CSS_NUMBER), Fixed);
    if (slices->bottom()->isPercentage())
        box.m_bottom = Length(slices->bottom()->getDoubleValue(), Percent);
    else
        box.m_bottom = Length((int)slices->bottom()->getFloatValue(CSSPrimitiveValue::CSS_NUMBER), Fixed);
    if (slices->left()->isPercentage())
        box.m_left = Length(slices->left()->getDoubleValue(), Percent);
    else
        box.m_left = Length(slices->left()->getIntValue(CSSPrimitiveValue::CSS_NUMBER), Fixed);
    if (slices->right()->isPercentage())
        box.m_right = Length(slices->right()->getDoubleValue(), Percent);
    else
        box.m_right = Length(slices->right()->getIntValue(CSSPrimitiveValue::CSS_NUMBER), Fixed);
    image.setImageSlices(box);

    // Set our fill mode.
    image.setFill(borderImageSlice->m_fill);
}

static BorderImageLength toBorderImageLength(CSSPrimitiveValue& value, const CSSToLengthConversionData& conversionData)
{
    if (value.isNumber())
        return value.getDoubleValue();
    if (value.isPercentage())
        return Length(value.getDoubleValue(CSSPrimitiveValue::CSS_PERCENTAGE), Percent);
    if (value.getValueID() != CSSValueAuto)
        return value.computeLength<Length>(conversionData);
    return Length(Auto);
}

BorderImageLengthBox CSSToStyleMap::mapNinePieceImageQuad(CSSValue* value) const
{
    if (!value || !value->isPrimitiveValue())
        return BorderImageLengthBox(Length(Auto));

    Quad* slices = toCSSPrimitiveValue(value)->getQuadValue();

    // Set up a border image length box to represent our image slices.
    return BorderImageLengthBox(
        toBorderImageLength(*slices->top(), cssToLengthConversionData()),
        toBorderImageLength(*slices->right(), cssToLengthConversionData()),
        toBorderImageLength(*slices->bottom(), cssToLengthConversionData()),
        toBorderImageLength(*slices->left(), cssToLengthConversionData()));
}

void CSSToStyleMap::mapNinePieceImageRepeat(CSSValue* value, NinePieceImage& image) const
{
    if (!value || !value->isPrimitiveValue())
        return;

    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    Pair* pair = primitiveValue->getPairValue();
    if (!pair || !pair->first() || !pair->second())
        return;

    CSSValueID firstIdentifier = pair->first()->getValueID();
    CSSValueID secondIdentifier = pair->second()->getValueID();

    ENinePieceImageRule horizontalRule;
    switch (firstIdentifier) {
    case CSSValueStretch:
        horizontalRule = StretchImageRule;
        break;
    case CSSValueRound:
        horizontalRule = RoundImageRule;
        break;
    case CSSValueSpace:
        horizontalRule = SpaceImageRule;
        break;
    default: // CSSValueRepeat
        horizontalRule = RepeatImageRule;
        break;
    }
    image.setHorizontalRule(horizontalRule);

    ENinePieceImageRule verticalRule;
    switch (secondIdentifier) {
    case CSSValueStretch:
        verticalRule = StretchImageRule;
        break;
    case CSSValueRound:
        verticalRule = RoundImageRule;
        break;
    case CSSValueSpace:
        verticalRule = SpaceImageRule;
        break;
    default: // CSSValueRepeat
        verticalRule = RepeatImageRule;
        break;
    }
    image.setVerticalRule(verticalRule);
}

};
